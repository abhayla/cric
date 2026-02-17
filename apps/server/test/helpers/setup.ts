// Test setup — preloaded before all tests
// Increase default timeout for remote DB operations (default 5000ms is too short)
import { setDefaultTimeout } from 'bun:test';
setDefaultTimeout(60_000);
