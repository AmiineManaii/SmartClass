import pino from 'pino';

const isDev = process.env.NODE_ENV === 'development';
const logLevel = process.env.LOG_LEVEL || (isDev ? 'debug' : 'info');

export const logger = pino({
  level: logLevel,
  redact: {
    paths: [
      'authorization',
      'cookie',
      'password',
      'passwordHash',
      'refreshToken',
      'token',
      'joinToken',
      'livekitToken',
      'LIVEKIT_API_SECRET',
      'LIVEKIT_API_KEY',
      'req.headers.authorization',
      'req.headers.cookie',
      '*.password',
      '*.refreshToken',
      '*.token',
      '*.joinToken',
      '*.livekitToken',
      '*.apiSecret',
      '*.apiKey',
    ],
    censor: '[REDACTED]',
  },
  transport: isDev
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
});
