/// Input validation functions.
abstract final class Validators {
  /// Indian phone number: starts with 6-9, exactly 10 digits.
  static final RegExp _indianPhone = RegExp(r'^[6-9]\d{9}$');

  /// Validates an Indian phone number.
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number required';
    if (!_indianPhone.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  /// Validates a display name (2-50 characters).
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be 50 characters or less';
    return null;
  }

  /// Validates a team name (2-50 characters).
  static String? teamName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Team name required';
    if (value.trim().length < 2) return 'Must be at least 2 characters';
    if (value.trim().length > 50) return 'Must be 50 characters or less';
    return null;
  }

  /// Validates OTP (exactly 6 digits).
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP required';
    if (value.length != 6 || int.tryParse(value) == null) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }
}
