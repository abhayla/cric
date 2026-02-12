import 'package:flutter/material.dart';

/// App color constants.
///
/// M3 seed color generates the full tonal palette.
/// Semantic scoring colors are fixed for consistency.
abstract final class AppColors {
  /// M3 seed color — blue.
  static const Color seed = Color(0xFF1976D2);

  // Semantic scoring colors (fixed, not from M3 palette)
  static const Color four = Color(0xFF1565C0);
  static const Color six = Color(0xFF6A1B9A);
  static const Color wicket = Color(0xFFC62828);
  static const Color dot = Color(0xFF757575);
  static const Color wide = Color(0xFFEF6C00);
  static const Color noBall = Color(0xFFD84315);
  static const Color bye = Color(0xFF00838F);
  static const Color legBye = Color(0xFF2E7D32);
  static const Color maiden = Color(0xFF1565C0);
}
