import { initializeApp, cert, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { env } from './env.ts';

let app: App;
let auth: Auth;

export function initFirebase(): void {
  const serviceAccountPath = env.FIREBASE_SERVICE_ACCOUNT_PATH;

  app = initializeApp({
    credential: cert(serviceAccountPath),
  });

  auth = getAuth(app);
}

export function getFirebaseAuth(): Auth {
  if (!auth) {
    throw new Error(
      'Firebase not initialized. Call initFirebase() before using auth.',
    );
  }
  return auth;
}
