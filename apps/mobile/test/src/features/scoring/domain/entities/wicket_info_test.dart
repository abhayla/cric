import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/wicket_info.dart';

void main() {
  group('WicketInfo', () {
    test('constructs with required fields', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.bowled,
        bowlerCredited: true,
      );
      expect(w.dismissedPlayerId, 'bat-1');
      expect(w.dismissalType, DismissalType.bowled);
      expect(w.bowlerCredited, true);
      expect(w.fielderId, isNull);
      expect(w.battersCrossed, isNull);
    });

    test('constructs with all fields for caught dismissal', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.caught,
        bowlerCredited: true,
        fielderId: 'fielder-1',
      );
      expect(w.dismissedPlayerId, 'bat-1');
      expect(w.dismissalType, DismissalType.caught);
      expect(w.bowlerCredited, true);
      expect(w.fielderId, 'fielder-1');
    });

    test('constructs with battersCrossed for run out', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-2',
        dismissalType: DismissalType.runOut,
        bowlerCredited: false,
        fielderId: 'fielder-1',
        battersCrossed: true,
      );
      expect(w.dismissedPlayerId, 'bat-2');
      expect(w.dismissalType, DismissalType.runOut);
      expect(w.bowlerCredited, false);
      expect(w.fielderId, 'fielder-1');
      expect(w.battersCrossed, true);
    });

    test('battersCrossed can be false for run out', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.runOut,
        bowlerCredited: false,
        fielderId: 'fielder-1',
        battersCrossed: false,
      );
      expect(w.battersCrossed, false);
    });

    test('requiresFielder delegates to dismissalType', () {
      expect(
        const WicketInfo(
          dismissedPlayerId: 'bat-1',
          dismissalType: DismissalType.bowled,
          bowlerCredited: true,
        ).requiresFielder,
        false,
      );
      expect(
        const WicketInfo(
          dismissedPlayerId: 'bat-1',
          dismissalType: DismissalType.caught,
          bowlerCredited: true,
          fielderId: 'f-1',
        ).requiresFielder,
        true,
      );
      expect(
        const WicketInfo(
          dismissedPlayerId: 'bat-1',
          dismissalType: DismissalType.runOut,
          bowlerCredited: false,
          fielderId: 'f-1',
        ).requiresFielder,
        true,
      );
      expect(
        const WicketInfo(
          dismissedPlayerId: 'bat-1',
          dismissalType: DismissalType.stumped,
          bowlerCredited: true,
          fielderId: 'f-1',
        ).requiresFielder,
        true,
      );
      expect(
        const WicketInfo(
          dismissedPlayerId: 'bat-1',
          dismissalType: DismissalType.lbw,
          bowlerCredited: true,
        ).requiresFielder,
        false,
      );
    });

    test('constructs for retired hurt (no fielder, no bowler credit)', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.retiredHurt,
        bowlerCredited: false,
      );
      expect(w.dismissalType, DismissalType.retiredHurt);
      expect(w.bowlerCredited, false);
      expect(w.fielderId, isNull);
      expect(w.requiresFielder, false);
    });

    test('constructs for stumped (fielder = keeper)', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.stumped,
        bowlerCredited: true,
        fielderId: 'keeper-1',
      );
      expect(w.fielderId, 'keeper-1');
      expect(w.bowlerCredited, true);
    });

    test('constructs for caught and bowled (no fielder needed)', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.caughtAndBowled,
        bowlerCredited: true,
      );
      expect(w.requiresFielder, false);
      expect(w.bowlerCredited, true);
    });

    test('constructs for hit wicket', () {
      const w = WicketInfo(
        dismissedPlayerId: 'bat-1',
        dismissalType: DismissalType.hitWicket,
        bowlerCredited: true,
      );
      expect(w.requiresFielder, false);
      expect(w.bowlerCredited, true);
    });
  });
}
