import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import { config } from './environment';
import path from 'path';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

const developmentFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.printf(
    ({ timestamp, level, message, stack }) =>
      `${String(timestamp)} [${String(level)}]: ${String(stack ?? message)}`
  )
);

const logsDir = path.join(process.cwd(), 'logs');

const transports: winston.transport[] = [];

// Console transport for all environments
if (config.env === 'development') {
  transports.push(
    new winston.transports.Console({
      format: developmentFormat,
    })
  );
} else {
  transports.push(
    new winston.transports.Console({
      format: logFormat,
      level: 'warn', // Only warnings and errors in production console
    })
  );
}

// File transports for all environments except test
if (config.env !== 'test') {
  // Error logs with daily rotation
  transports.push(
    new DailyRotateFile({
      filename: path.join(logsDir, 'error-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      level: 'error',
      format: logFormat,
      maxSize: '20m',
      maxFiles: '30d',
      zippedArchive: true,
    })
  );

  // Combined logs with daily rotation (all levels)
  transports.push(
    new DailyRotateFile({
      filename: path.join(logsDir, 'app-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      format: logFormat,
      maxSize: '20m',
      maxFiles: '14d',
      zippedArchive: true,
    })
  );

  // Separate verbose debug logs for development
  if (config.env === 'development') {
    transports.push(
      new DailyRotateFile({
        filename: path.join(logsDir, 'debug-%DATE%.log'),
        datePattern: 'YYYY-MM-DD',
        level: 'debug',
        format: winston.format.combine(
          winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
          winston.format.errors({ stack: true }),
          winston.format.json(),
          winston.format.prettyPrint()
        ),
        maxSize: '50m',
        maxFiles: '7d',
        zippedArchive: true,
      })
    );
  }

  // HTTP request logs
  transports.push(
    new DailyRotateFile({
      filename: path.join(logsDir, 'access-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.json()
      ),
      maxSize: '20m',
      maxFiles: '30d',
      zippedArchive: true,
    })
  );
}

export const logger = winston.createLogger({
  level: config.env === 'development' ? 'debug' : 'info',
  format: logFormat,
  transports,
  exitOnError: false,
});