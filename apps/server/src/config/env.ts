function getEnvVar(key: string, defaultValue?: string): string {
  const value = process.env[key] ?? defaultValue;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export const env = {
  DATABASE_URL: getEnvVar('DATABASE_URL'),
  FIREBASE_SERVICE_ACCOUNT_PATH: getEnvVar(
    'FIREBASE_SERVICE_ACCOUNT_PATH',
    './firebase-service-account.json',
  ),
  PORT: Number(getEnvVar('PORT', '3000')),
  CORS_ORIGIN: getEnvVar('CORS_ORIGIN', '*'),
  NODE_ENV: getEnvVar('NODE_ENV', 'development'),
  LOG_LEVEL: getEnvVar('LOG_LEVEL', 'debug'),
  UPLOADS_DIR: getEnvVar('UPLOADS_DIR', './uploads'),
  MAX_UPLOAD_SIZE_MB: Number(getEnvVar('MAX_UPLOAD_SIZE_MB', '1')),
  SYNC_BATCH_SIZE: Number(getEnvVar('SYNC_BATCH_SIZE', '50')),
  WS_HEARTBEAT_INTERVAL_MS: Number(
    getEnvVar('WS_HEARTBEAT_INTERVAL_MS', '30000'),
  ),
} as const;

// Production safety: wildcard CORS is not allowed
if (env.NODE_ENV === 'production' && env.CORS_ORIGIN === '*') {
  console.error('FATAL: CORS_ORIGIN=* is not allowed in production.');
  process.exit(1);
}
