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

// Console transport for all environments (silent in test to avoid noise)
if (config.env === 'development') {
  transports.push(
    new winston.transports.Console({
      format: developmentFormat,
    })
  );
} else if (config.env === 'test') {
  // In test environment, suppress console output (logs still go to files)
  transports.push(
    new winston.transports.Console({
      format: logFormat,
      silent: true, // Suppress console output during tests
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

// File transports for all environments
// Error logs with daily rotation
transports.push(
  new DailyRotateFile({
    filename: path.join(logsDir, config.env === 'test' ? 'test-error-%DATE%.log' : 'error-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    level: 'error',
    format: logFormat,
    maxSize: '20m',
    maxFiles: config.env === 'test' ? '7d' : '30d',
    zippedArchive: true,
    silent: false, // Always write errors to file
  })
);

// Combined logs with daily rotation (all levels)
transports.push(
  new DailyRotateFile({
    filename: path.join(logsDir, config.env === 'test' ? 'test-app-%DATE%.log' : 'app-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    format: logFormat,
    maxSize: '20m',
    maxFiles: config.env === 'test' ? '7d' : '14d',
    zippedArchive: true,
    silent: false, // Always write to file
  })
);

// Separate verbose debug logs for development and test
if (config.env === 'development' || config.env === 'test') {
  transports.push(
    new DailyRotateFile({
      filename: path.join(logsDir, config.env === 'test' ? 'test-debug-%DATE%.log' : 'debug-%DATE%.log'),
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
      silent: false,
    })
  );
}

// HTTP request logs (excluding test to reduce noise)
if (config.env !== 'test') {
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
  level: config.env === 'development' || config.env === 'test' ? 'debug' : 'info',
  format: logFormat,
  transports,
  exitOnError: false,
});