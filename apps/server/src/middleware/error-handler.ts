import { Elysia } from 'elysia';

interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number = 400,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

function toErrorResponse(
  code: string,
  message: string,
  details?: unknown,
): ErrorResponse {
  return {
    error: {
      code,
      message,
      ...(details !== undefined && { details }),
    },
  };
}

export const errorHandler = new Elysia({ name: 'error-handler' })
  .onError(({ error, set, code: elysiaCode }) => {
    if (error instanceof AppError) {
      set.status = error.statusCode;
      return toErrorResponse(error.code, error.message, error.details);
    }

    if (elysiaCode === 'NOT_FOUND') {
      set.status = 404;
      return toErrorResponse('NOT_FOUND', 'Resource not found');
    }

    if (elysiaCode === 'VALIDATION') {
      set.status = 400;
      return toErrorResponse('VALIDATION_ERROR', 'Invalid request data');
    }

    console.error('Unhandled error:', error);
    set.status = 500;
    return toErrorResponse('INTERNAL_ERROR', 'An unexpected error occurred');
  })
  .as('global');
