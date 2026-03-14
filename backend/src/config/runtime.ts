const startedAt = Date.now();
let shuttingDown = false;

export const runtimeState = {
  getStartedAt(): number {
    return startedAt;
  },
  getUptimeMs(): number {
    return Date.now() - startedAt;
  },
  isShuttingDown(): boolean {
    return shuttingDown;
  },
  markShuttingDown(): void {
    shuttingDown = true;
  },
  resetForTests(): void {
    shuttingDown = false;
  },
};
