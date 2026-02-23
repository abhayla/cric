import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerProfile', () {
    test('initials returns two letters for multi-word name', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Virat Kohli',
      );
      expect(profile.initials, 'VK');
    });

    test('initials returns one letter for single-word name', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Virat',
      );
      expect(profile.initials, 'V');
    });

    test('initials handles extra whitespace', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: '  Virat  Kohli  ',
      );
      expect(profile.initials, 'VK');
    });

    test('styleDescription returns batting style for batter', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.none,
      );
      expect(profile.styleDescription, 'Right Hand');
    });

    test('styleDescription returns bowling style for bowler', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
        playerRole: PlayerRole.bowler,
        bowlingStyle: BowlingStyle.rightArmFast,
      );
      expect(profile.styleDescription, 'Right Arm Fast');
    });

    test('styleDescription returns both styles for all-rounder', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
        playerRole: PlayerRole.allRounder,
        battingStyle: BattingStyle.leftHand,
        bowlingStyle: BowlingStyle.leftArmOrthodox,
      );
      expect(profile.styleDescription, 'Left Hand · Left Arm Orthodox');
    });

    test('styleDescription excludes None bowling for all-rounder', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
        playerRole: PlayerRole.allRounder,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.none,
      );
      expect(profile.styleDescription, 'Right Hand');
    });

    test('styleDescription returns empty when no styles set', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
      );
      expect(profile.styleDescription, '');
    });

    test('styleDescription returns both for wk-batter', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
        playerRole: PlayerRole.wkBatter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmOffSpin,
      );
      expect(profile.styleDescription, 'Right Hand · Right Arm Off Spin');
    });

    test('teams defaults to empty list', () {
      const profile = PlayerProfile(
        id: '1',
        displayName: 'Test',
      );
      expect(profile.teams, isEmpty);
    });
  });

  group('TeamAffiliation', () {
    test('initial returns first letter of team name', () {
      const affiliation = TeamAffiliation(
        teamId: '1',
        teamName: 'Mumbai Indians',
        role: 'player',
      );
      expect(affiliation.initial, 'M');
    });

    test('initial returns ? for empty team name', () {
      const affiliation = TeamAffiliation(
        teamId: '1',
        teamName: '',
        role: 'player',
      );
      expect(affiliation.initial, '?');
    });
  });
}
