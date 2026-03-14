import mongoose from 'mongoose';
import { logger } from './logger';
import { config } from './environment';

const READY_STATE_MAP: Record<number, string> = {
  0: 'disconnected',
  1: 'connected',
  2: 'connecting',
  3: 'disconnecting',
};

class Database {
  private static instance: Database;
  private listenersRegistered = false;

  private constructor() {}

  public static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  public async connect(): Promise<void> {
    try {
      this.registerConnectionListeners();
      await mongoose.connect(config.mongoose.url);
    } catch (error) {
      logger.error('Failed to connect to MongoDB:', error);
      throw error;
    }
  }

  public async disconnect(): Promise<void> {
    await mongoose.disconnect();
  }

  public isHealthy(): boolean {
    return Number(mongoose.connection.readyState) === 1;
  }

  public getStatus(): string {
    return READY_STATE_MAP[mongoose.connection.readyState] ?? 'unknown';
  }

  private registerConnectionListeners(): void {
    if (this.listenersRegistered) {
      return;
    }

    mongoose.connection.on('connected', () => {
      logger.info('Connected to MongoDB');
    });

    mongoose.connection.on('error', error => {
      logger.error('MongoDB connection error:', error);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected');
    });

    this.listenersRegistered = true;
  }
}

export const database = Database.getInstance();
