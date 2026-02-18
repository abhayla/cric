// Test setup — preloaded before all tests
import { setDefaultTimeout } from 'bun:test';

// Set default timeout for all tests and lifecycle hooks (60 seconds).
// This is also configured in bunfig.toml but setDefaultTimeout is more reliable
// for lifecycle hooks (beforeAll/afterAll) across Bun versions.
setDefaultTimeout(60_000);
