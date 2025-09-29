import winston from 'winston';
import { config } from './environment';

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
      `${timestamp} [${level}]: ${stack || message}`
  )
);

const transports: winston.transport[] = [];

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
    })
  );
}

if (config.env === 'production') {
  transports.push(
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      format: logFormat,
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      format: logFormat,
    })
  );
}

export const logger = winston.createLogger({
  level: config.env === 'development' ? 'debug' : 'info',
  format: logFormat,
  transports,
  exitOnError: false,
});