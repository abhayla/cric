import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/teams/data/models/team_model.dart';

void main() {
  group('RosterEntryModel', () {
    test('deserializes isVerified from JSON', () {
      final json = {
        'id': 'roster-1',
        'playerId': 'player-1',
        'displayName': 'Test Player',
        'role': 'player',
        'isActive': true,
        'isVerified': true,
      };

      final model = RosterEntryModel.fromJson(json);
      expect(model.isVerified, true);
    });

    test('isVerified defaults to false when missing from JSON', () {
      final json = {
        'id': 'roster-1',
        'playerId': 'player-1',
        'displayName': 'Test Player',
        'role': 'player',
        'isActive': true,
      };

      final model = RosterEntryModel.fromJson(json);
      expect(model.isVerified, false);
    });

    test('serializes isVerified to JSON', () {
      const model = RosterEntryModel(
        id: 'roster-1',
        playerId: 'player-1',
        displayName: 'Test Player',
        isVerified: true,
      );

      final json = model.toJson();
      expect(json['isVerified'], true);
    });

    test('toEntity maps isVerified correctly', () {
      const model = RosterEntryModel(
        id: 'roster-1',
        playerId: 'player-1',
        displayName: 'Test Player',
        isVerified: true,
      );

      final entity = model.toEntity();
      expect(entity.isVerified, true);
    });

    test('toEntity defaults isVerified to false', () {
      const model = RosterEntryModel(
        id: 'roster-1',
        playerId: 'player-1',
        displayName: 'Test Player',
      );

      final entity = model.toEntity();
      expect(entity.isVerified, false);
    });
  });
}
