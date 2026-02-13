import 'delivery.dart';

/// Wicket details for a delivery that resulted in a dismissal.
class WicketInfo {
  const WicketInfo({
    required this.dismissedPlayerId,
    required this.dismissalType,
    required this.bowlerCredited,
    this.fielderId,
    this.battersCrossed,
  });

  /// The player who was dismissed.
  final String dismissedPlayerId;

  /// Type of dismissal.
  final DismissalType dismissalType;

  /// Whether the bowler is credited with this wicket.
  final bool bowlerCredited;

  /// Fielder involved (for caught, run out, stumped).
  final String? fielderId;

  /// Whether batters had crossed when run out occurred.
  /// Only relevant for run out dismissals.
  final bool? battersCrossed;

  /// Whether this dismissal requires a fielder.
  bool get requiresFielder => dismissalType.requiresFielder;
}
