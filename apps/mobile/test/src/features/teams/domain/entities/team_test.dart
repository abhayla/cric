import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/teams/domain/entities/team.dart';
import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';

void main() {
  group('Team', () {
    test('creates with required fields', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 11,
        role: TeamMemberRole.owner,
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.id, 'team-1');
      expect(team.name, 'Mumbai Warriors');
      expect(team.createdBy, 'user-1');
      expect(team.isActive, true);
      expect(team.playerCount, 11);
      expect(team.role, TeamMemberRole.owner);
      expect(team.location, isNull);
      expect(team.logoUrl, isNull);
    });

    test('creates with all optional fields', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 11,
        role: TeamMemberRole.captain,
        location: 'Mumbai',
        logoUrl: 'https://example.com/logo.png',
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.location, 'Mumbai');
      expect(team.logoUrl, 'https://example.com/logo.png');
      expect(team.role, TeamMemberRole.captain);
    });

    test('initials returns first letter of team name', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 0,
        role: TeamMemberRole.owner,
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.initial, 'M');
    });

    test('subtitle shows player count and location', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 11,
        role: TeamMemberRole.owner,
        location: 'Mumbai',
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.subtitle, '11 players · Mumbai');
    });

    test('subtitle shows only player count when no location', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 5,
        role: TeamMemberRole.owner,
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.subtitle, '5 players');
    });

    test('singular player text for 1 player', () {
      final team = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 1,
        role: TeamMemberRole.owner,
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );

      expect(team.subtitle, '1 player');
    });
  });

  group('TeamMemberRole', () {
    test('has exactly 3 values', () {
      expect(TeamMemberRole.values.length, 3);
    });

    test('contains expected values', () {
      expect(TeamMemberRole.values, contains(TeamMemberRole.owner));
      expect(TeamMemberRole.values, contains(TeamMemberRole.captain));
      expect(TeamMemberRole.values, contains(TeamMemberRole.member));
    });

    test('labels are correct', () {
      expect(TeamMemberRole.owner.label, 'Owner');
      expect(TeamMemberRole.captain.label, 'Captain');
      expect(TeamMemberRole.member.label, 'Member');
    });
  });

  group('RosterRole', () {
    test('has exactly 3 values', () {
      expect(RosterRole.values.length, 3);
    });

    test('contains expected values', () {
      expect(RosterRole.values, contains(RosterRole.captain));
      expect(RosterRole.values, contains(RosterRole.viceCaptain));
      expect(RosterRole.values, contains(RosterRole.player));
    });

    test('labels are correct', () {
      expect(RosterRole.captain.label, 'Captain');
      expect(RosterRole.viceCaptain.label, 'Vice Captain');
      expect(RosterRole.player.label, 'Player');
    });

    test('apiValue maps to snake_case', () {
      expect(RosterRole.captain.apiValue, 'captain');
      expect(RosterRole.viceCaptain.apiValue, 'vice_captain');
      expect(RosterRole.player.apiValue, 'player');
    });

    test('fromApiValue parses correctly', () {
      expect(RosterRole.fromApiValue('captain'), RosterRole.captain);
      expect(RosterRole.fromApiValue('vice_captain'), RosterRole.viceCaptain);
      expect(RosterRole.fromApiValue('player'), RosterRole.player);
    });

    test('fromApiValue defaults to player for unknown value', () {
      expect(RosterRole.fromApiValue('unknown'), RosterRole.player);
    });
  });

  group('RosterEntry', () {
    test('creates with required fields', () {
      final entry = RosterEntry(
        id: 'roster-1',
        playerId: 'player-1',
        displayName: 'Virat Kohli',
        rosterRole: RosterRole.captain,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );

      expect(entry.id, 'roster-1');
      expect(entry.playerId, 'player-1');
      expect(entry.displayName, 'Virat Kohli');
      expect(entry.rosterRole, RosterRole.captain);
      expect(entry.isActive, true);
      expect(entry.jerseyNumber, isNull);
      expect(entry.playerRole, isNull);
      expect(entry.battingStyle, isNull);
      expect(entry.bowlingStyle, isNull);
    });

    test('creates with all optional fields', () {
      final entry = RosterEntry(
        id: 'roster-1',
        playerId: 'player-1',
        displayName: 'Virat Kohli',
        rosterRole: RosterRole.captain,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
        jerseyNumber: 18,
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmMedium,
        phone: '+919876543210',
        avatarUrl: 'https://example.com/virat.png',
      );

      expect(entry.jerseyNumber, 18);
      expect(entry.playerRole, PlayerRole.batter);
      expect(entry.battingStyle, BattingStyle.rightHand);
      expect(entry.bowlingStyle, BowlingStyle.rightArmMedium);
      expect(entry.phone, '+919876543210');
      expect(entry.avatarUrl, 'https://example.com/virat.png');
    });

    test('initials returns player initials', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Virat Kohli',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );

      expect(entry.initials, 'VK');
    });

    test('initials handles single word name', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Virat',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );

      expect(entry.initials, 'V');
    });

    test('styleDescription shows both styles for all-rounder', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Hardik Pandya',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
        playerRole: PlayerRole.allRounder,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmMedium,
      );

      expect(entry.styleDescription, 'Right Hand · Right Arm Medium');
    });

    test('styleDescription shows batting style for batter', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Rohit Sharma',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmOffSpin,
      );

      expect(entry.styleDescription, 'Right Hand');
    });

    test('styleDescription shows bowling style for bowler', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Jasprit Bumrah',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
        playerRole: PlayerRole.bowler,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmFast,
      );

      expect(entry.styleDescription, 'Right Arm Fast');
    });

    test('styleDescription shows both for WK-batter', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'MS Dhoni',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
        playerRole: PlayerRole.wkBatter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.none,
      );

      expect(entry.styleDescription, 'Right Hand');
    });

    test('styleDescription returns empty when no styles set', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Unknown Player',
        rosterRole: RosterRole.player,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );

      expect(entry.styleDescription, '');
    });

    test('isCaptain returns true for captain role', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Test',
        rosterRole: RosterRole.captain,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );
      expect(entry.isCaptain, true);
    });

    test('isKeeper returns true for wk_batter role', () {
      final entry = RosterEntry(
        id: 'r1',
        playerId: 'p1',
        displayName: 'Test',
        rosterRole: RosterRole.player,
        playerRole: PlayerRole.wkBatter,
        isActive: true,
        joinedAt: DateTime(2025, 3, 15),
      );
      expect(entry.isKeeper, true);
    });
  });
}
