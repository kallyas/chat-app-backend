import request from 'supertest';
import { createApp } from '@/app';
import { isAllowedCorsOrigin } from '@/config/environment';
import { runtimeState } from '@/config/runtime';

type PlatformResponse = {
  success: boolean;
  status: string;
  uptimeMs?: number;
  requestId?: string;
  services?: {
    database: {
      healthy: boolean;
      status: string;
    };
  };
  lifecycle?: {
    shuttingDown: boolean;
  };
};

describe('Platform Integration Tests', () => {
  const app = createApp();

  afterEach(() => {
    runtimeState.resetForTests();
  });

  it('should expose a liveness endpoint', async () => {
    const response = await request(app).get('/api/health/live').expect(200);
    const body = response.body as PlatformResponse;

    expect(body.success).toBe(true);
    expect(body.status).toBe('ok');
  });

  it('should expose health details with database status', async () => {
    const response = await request(app).get('/api/health').expect(200);
    const body = response.body as PlatformResponse;

    expect(body.success).toBe(true);
    expect(body.services?.database.healthy).toBe(true);
    expect(body.services?.database.status).toBe('connected');
    expect(body.lifecycle?.shuttingDown).toBe(false);
    expect(typeof body.uptimeMs).toBe('number');
  });

  it('should report ready when dependencies are healthy', async () => {
    const response = await request(app).get('/api/health/ready').expect(200);
    const body = response.body as PlatformResponse;

    expect(body.status).toBe('ready');
  });

  it('should report not ready while shutting down', async () => {
    runtimeState.markShuttingDown();

    const response = await request(app).get('/api/health/ready').expect(503);
    const body = response.body as PlatformResponse;

    expect(body.status).toBe('not_ready');
    expect(body.lifecycle?.shuttingDown).toBe(true);
  });

  it('should return a request ID header and include it in error responses', async () => {
    const response = await request(app).get('/api/does-not-exist').expect(404);
    const body = response.body as PlatformResponse;

    expect(response.headers['x-request-id']).toBeDefined();
    expect(body.requestId).toBe(response.headers['x-request-id']);
  });

  it('should allow localhost dev origins for CORS preflight requests', async () => {
    const origin = 'http://localhost:50982';

    expect(isAllowedCorsOrigin(origin)).toBe(true);

    const response = await request(app)
      .options('/api/auth/register')
      .set('Origin', origin)
      .set('Access-Control-Request-Method', 'POST')
      .expect(204);

    expect(response.headers['access-control-allow-origin']).toBe(origin);
    expect(response.headers['access-control-allow-credentials']).toBe('true');
  });
});
