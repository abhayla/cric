/// Test constants — phones, OTP, timeouts.
library;

/// Scorer phone number (Firebase test phone, emulator).
const scorerPhone = '9999999999';

/// Viewer phone number (Firebase test phone, real device or 2nd emulator).
const viewerPhone = '9999999998';

/// Fixed OTP code for all Firebase test phone numbers.
const testOtpCode = '123456';

/// Timeout for login flow (Firebase init + OTP on real devices can be slow).
const loginTimeoutSeconds = 180;

/// Timeout for match setup navigation + API calls.
const matchSetupTimeoutSeconds = 30;

/// Visual pause between UI taps for observability.
const defaultPauseMs = 300;

/// Pause after API-heavy operations (toss, match creation).
const apiWaitMs = 2000;

/// Pause between deliveries in multi-device scorer test.
const multiDeviceDeliveryPauseMs = 2000;

/// Debug verbosity flag — set to false for cleaner CI output.
///
/// When true, all `testLog()` calls print output. When false, only
/// warnings and errors (starting with WARNING/ERROR) are printed.
const verboseTestOutput = true;
