import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/features/player_profile/data/models/player_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerProfileModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'player-1',
        'displayName': 'Virat Kohli',
        'phone': '+919876543210',
        'email': 'virat@example.com',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'playerRole': 'batter',
        'battingStyle': 'right_hand',
        'bowlingStyle': 'right_arm_medium',
        'location': 'Mumbai',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'teams': [
          {
            'teamId': 'team-1',
            'teamName': 'Mumbai Indians',
            'role': 'captain',
            'teamLogoUrl': 'https://example.com/logo.png',
            'joinedAt': '2025-06-15T00:00:00.000Z',
          },
        ],
      };

      final model = PlayerProfileModel.fromJson(json);
      expect(model.id, 'player-1');
      expect(model.displayName, 'Virat Kohli');
      expect(model.phone, '+919876543210');
      expect(model.email, 'virat@example.com');
      expect(model.avatarUrl, 'https://example.com/avatar.jpg');
      expect(model.playerRole, 'batter');
      expect(model.battingStyle, 'right_hand');
      expect(model.bowlingStyle, 'right_arm_medium');
      expect(model.location, 'Mumbai');
      expect(model.teams.length, 1);
      expect(model.teams.first.teamName, 'Mumbai Indians');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'player-2',
        'displayName': 'Unknown Player',
      };

      final model = PlayerProfileModel.fromJson(json);
      expect(model.id, 'player-2');
      expect(model.phone, isNull);
      expect(model.playerRole, isNull);
      expect(model.teams, isEmpty);
    });

    test('toEntity converts correctly', () {
      const model = PlayerProfileModel(
        id: 'player-1',
        displayName: 'Virat Kohli',
        playerRole: 'batter',
        battingStyle: 'right_hand',
        bowlingStyle: 'none',
        teams: [
          TeamAffiliationModel(
            teamId: 'team-1',
            teamName: 'MI',
            role: 'player',
          ),
        ],
      );

      final entity = model.toEntity();
      expect(entity.id, 'player-1');
      expect(entity.displayName, 'Virat Kohli');
      expect(entity.playerRole, PlayerRole.batter);
      expect(entity.battingStyle, BattingStyle.rightHand);
      expect(entity.bowlingStyle, BowlingStyle.none);
      expect(entity.teams.length, 1);
      expect(entity.teams.first.teamName, 'MI');
    });

    test('toEntity handles null enums', () {
      const model = PlayerProfileModel(
        id: 'player-2',
        displayName: 'Test',
      );

      final entity = model.toEntity();
      expect(entity.playerRole, isNull);
      expect(entity.battingStyle, isNull);
      expect(entity.bowlingStyle, isNull);
    });
  });

  group('TeamAffiliationModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'teamId': 'team-1',
        'teamName': 'Test Team',
        'role': 'captain',
        'teamLogoUrl': 'logo.png',
        'joinedAt': '2025-06-15T00:00:00.000Z',
      };

      final model = TeamAffiliationModel.fromJson(json);
      expect(model.teamId, 'team-1');
      expect(model.teamName, 'Test Team');
      expect(model.role, 'captain');
    });

    test('toEntity converts joinedAt string to DateTime', () {
      const model = TeamAffiliationModel(
        teamId: 'team-1',
        teamName: 'Test',
        joinedAt: '2025-06-15T00:00:00.000Z',
      );

      final entity = model.toEntity();
      expect(entity.joinedAt, isNotNull);
      expect(entity.joinedAt!.year, 2025);
    });

    test('toEntity handles null joinedAt', () {
      const model = TeamAffiliationModel(
        teamId: 'team-1',
        teamName: 'Test',
      );

      final entity = model.toEntity();
      expect(entity.joinedAt, isNull);
    });
  });
}
