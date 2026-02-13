import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';

void main() {
  group('PlayingXIPlayer', () {
    test('constructs with required fields and defaults', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Virat Kohli',
      );

      expect(player.playerId, 'p-1');
      expect(player.displayName, 'Virat Kohli');
      expect(player.playerRole, isNull);
      expect(player.battingStyle, isNull);
      expect(player.bowlingStyle, isNull);
      expect(player.isCaptain, false);
      expect(player.isKeeper, false);
    });

    test('constructs with all fields', () {
      const player = PlayingXIPlayer(
        playerId: 'p-2',
        displayName: 'MS Dhoni',
        playerRole: 'wicketkeeper_batter',
        battingStyle: 'RHB',
        bowlingStyle: 'RM',
        isCaptain: true,
        isKeeper: true,
      );

      expect(player.playerRole, 'wicketkeeper_batter');
      expect(player.battingStyle, 'RHB');
      expect(player.bowlingStyle, 'RM');
      expect(player.isCaptain, true);
      expect(player.isKeeper, true);
    });

    // -- initials --

    test('initials from two-word name', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Virat Kohli',
      );
      expect(player.initials, 'VK');
    });

    test('initials from single-word name', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Sachin',
      );
      expect(player.initials, 'S');
    });

    test('initials from three-word name takes first two', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Suresh Kumar Raina',
      );
      expect(player.initials, 'SK');
    });

    // -- badge --

    test('badge is (C) for captain only', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Rohit Sharma',
        isCaptain: true,
      );
      expect(player.badge, '(C)');
    });

    test('badge is (WK) for keeper only', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'KL Rahul',
        isKeeper: true,
      );
      expect(player.badge, '(WK)');
    });

    test('badge is (C & WK) for captain-keeper', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'MS Dhoni',
        isCaptain: true,
        isKeeper: true,
      );
      expect(player.badge, '(C & WK)');
    });

    test('badge is null for regular player', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Bumrah',
      );
      expect(player.badge, isNull);
    });

    // -- battingStyleShort --

    test('battingStyleShort returns style when set', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Kohli',
        battingStyle: 'RHB',
      );
      expect(player.battingStyleShort, 'RHB');
    });

    test('battingStyleShort is null when not set', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Kohli',
      );
      expect(player.battingStyleShort, isNull);
    });

    // -- roleLabel --

    test('roleLabel formats player role', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Kohli',
        playerRole: 'batter',
      );
      expect(player.roleLabel, 'Batter');
    });

    test('roleLabel formats multi-word role with underscore', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Dhoni',
        playerRole: 'wicketkeeper_batter',
      );
      expect(player.roleLabel, 'WK Batter');
    });

    test('roleLabel for all_rounder', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Hardik',
        playerRole: 'all_rounder',
      );
      expect(player.roleLabel, 'All Rounder');
    });

    test('roleLabel is null when role not set', () {
      const player = PlayingXIPlayer(
        playerId: 'p-1',
        displayName: 'Player',
      );
      expect(player.roleLabel, isNull);
    });
  });
}
