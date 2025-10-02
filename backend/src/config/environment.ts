import dotenv from 'dotenv';
import Joi from 'joi';

dotenv.config();

const envVarsSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),
  MONGODB_URI: Joi.string().required(),
  JWT_SECRET: Joi.string().required(),
  JWT_EXPIRE: Joi.string().default('7d'),
  RATE_LIMIT_WINDOW_MS: Joi.number().default(15 * 60 * 1000),
  RATE_LIMIT_MAX_REQUESTS: Joi.number().default(100),
  ALLOWED_ORIGINS: Joi.string().default(
    'http://localhost:3000,http://localhost:3001'
  ),
  MESSAGE_EDIT_TIME_LIMIT_HOURS: Joi.number().default(24), // 24 hours
  MESSAGE_DELETE_TIME_LIMIT_HOURS: Joi.number().default(168), // 7 days (168 hours)
}).unknown();

const { error, value: envVars } = envVarsSchema.validate(process.env) as {
  error?: Joi.ValidationError;
  value: Record<string, string | number>;
};

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}

export const config = {
  env: envVars.NODE_ENV as string,
  port: envVars.PORT as number,
  mongoose: {
    url: envVars.MONGODB_URI as string,
  },
  jwt: {
    secret: envVars.JWT_SECRET as string,
    accessExpirationMinutes: envVars.JWT_EXPIRE as string,
  },
  rateLimit: {
    windowMs: envVars.RATE_LIMIT_WINDOW_MS as number,
    max: envVars.RATE_LIMIT_MAX_REQUESTS as number,
  },
  cors: {
    origins: (envVars.ALLOWED_ORIGINS as string)
      .split(',')
      .map((origin: string) => origin.trim()),
  },
  messages: {
    editTimeLimitMs:
      (envVars.MESSAGE_EDIT_TIME_LIMIT_HOURS as number) * 60 * 60 * 1000,
    deleteTimeLimitMs:
      (envVars.MESSAGE_DELETE_TIME_LIMIT_HOURS as number) * 60 * 60 * 1000,
    editTimeLimitHours: envVars.MESSAGE_EDIT_TIME_LIMIT_HOURS as number,
    deleteTimeLimitHours: envVars.MESSAGE_DELETE_TIME_LIMIT_HOURS as number,
  },
};
