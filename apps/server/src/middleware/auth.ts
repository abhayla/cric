import { Elysia } from 'elysia';
import { getFirebaseAuth } from '../config/firebase.ts';
import { AppError } from './error-handler.ts';
import type { FirebaseUser } from '../types/auth.ts';

const TEST_USER: FirebaseUser = {
  uid: 'test-user-e2e-001',
  phone: '+919999900001',
  email: null,
};

export const authMiddleware = new Elysia({ name: 'auth' }).resolve(
  { as: 'scoped' },
  async ({ request }): Promise<{ firebaseUser: FirebaseUser }> => {
    // In test mode, bypass Firebase auth and use a test user
    if (process.env.NODE_ENV === 'test') {
      return { firebaseUser: TEST_USER };
    }

    const authorization = request.headers.get('authorization');

    if (!authorization?.startsWith('Bearer ')) {
      throw new AppError(
        'UNAUTHORIZED',
        'Missing or invalid authorization header',
        401,
      );
    }

    const token = authorization.slice(7);

    try {
      const decodedToken = await getFirebaseAuth().verifyIdToken(token);
      return {
        firebaseUser: {
          uid: decodedToken.uid,
          phone: decodedToken.phone_number ?? null,
          email: decodedToken.email ?? null,
        },
      };
    } catch (error) {
      console.error('Token verification failed:', error);
      throw new AppError('UNAUTHORIZED', 'Invalid or expired token', 401);
    }
  },
);
