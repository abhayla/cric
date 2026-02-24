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

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Throws 400 AppError if the string is not a valid UUID. */
export function validateUuid(id: string, label = 'id'): void {
  if (!UUID_REGEX.test(id)) {
    throw new AppError('VALIDATION_ERROR', `Invalid ${label}: must be a valid UUID`, 400);
  }
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
      console.error('Validation error:', JSON.stringify(error, null, 2));
      return toErrorResponse('VALIDATION_ERROR', 'Invalid request data', error.message);
    }

    // Catch PostgreSQL invalid UUID syntax errors (code 22P02) as 400
    if (
      error &&
      typeof error === 'object' &&
      'code' in error &&
      (error as { code: string }).code === '22P02'
    ) {
      set.status = 400;
      return toErrorResponse('VALIDATION_ERROR', 'Invalid ID format: must be a valid UUID');
    }

    console.error('Unhandled error:', error);
    set.status = 500;
    return toErrorResponse('INTERNAL_ERROR', 'An unexpected error occurred');
  })
  .as('global');
