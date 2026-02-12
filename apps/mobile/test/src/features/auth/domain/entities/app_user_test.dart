import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    test('creates with required fields', () {
      final user = AppUser(
        id: 'user-123',
        firebaseUid: 'fb-123',
        displayName: 'Virat Kohli',
      );

      expect(user.id, 'user-123');
      expect(user.firebaseUid, 'fb-123');
      expect(user.displayName, 'Virat Kohli');
      expect(user.phone, isNull);
      expect(user.playerRole, isNull);
      expect(user.battingStyle, isNull);
      expect(user.bowlingStyle, isNull);
      expect(user.location, isNull);
    });

    test('creates with all fields', () {
      final user = AppUser(
        id: 'user-123',
        firebaseUid: 'fb-123',
        displayName: 'Virat Kohli',
        phone: '+919876543210',
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmMedium,
        location: 'Delhi, India',
      );

      expect(user.playerRole, PlayerRole.batter);
      expect(user.battingStyle, BattingStyle.rightHand);
      expect(user.bowlingStyle, BowlingStyle.rightArmMedium);
      expect(user.location, 'Delhi, India');
    });

    test('initials returns first two letters of display name', () {
      final user = AppUser(
        id: 'u1',
        firebaseUid: 'fb1',
        displayName: 'Virat Kohli',
      );
      expect(user.initials, 'VK');
    });

    test('initials returns single letter for single-word name', () {
      final user = AppUser(
        id: 'u1',
        firebaseUid: 'fb1',
        displayName: 'Virat',
      );
      expect(user.initials, 'V');
    });
  });

  group('PlayerRole', () {
    test('has exactly 4 values', () {
      expect(PlayerRole.values.length, 4);
    });

    test('contains expected roles', () {
      expect(PlayerRole.values, contains(PlayerRole.batter));
      expect(PlayerRole.values, contains(PlayerRole.bowler));
      expect(PlayerRole.values, contains(PlayerRole.allRounder));
      expect(PlayerRole.values, contains(PlayerRole.wkBatter));
    });

    test('label returns display text', () {
      expect(PlayerRole.batter.label, 'Batter');
      expect(PlayerRole.bowler.label, 'Bowler');
      expect(PlayerRole.allRounder.label, 'All-Rounder');
      expect(PlayerRole.wkBatter.label, 'WK-Batter');
    });
  });

  group('BattingStyle', () {
    test('has exactly 2 values', () {
      expect(BattingStyle.values.length, 2);
    });

    test('label returns display text', () {
      expect(BattingStyle.rightHand.label, 'Right Hand');
      expect(BattingStyle.leftHand.label, 'Left Hand');
    });
  });

  group('BowlingStyle', () {
    test('has exactly 9 values', () {
      expect(BowlingStyle.values.length, 9);
    });

    test('label returns display text', () {
      expect(BowlingStyle.rightArmFast.label, 'Right Arm Fast');
      expect(BowlingStyle.leftArmChinaman.label, 'Left Arm Chinaman');
      expect(BowlingStyle.none.label, 'None');
    });
  });
}
