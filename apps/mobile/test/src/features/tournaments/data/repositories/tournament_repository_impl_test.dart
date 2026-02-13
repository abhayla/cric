import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/features/tournaments/data/datasources/tournament_remote_datasource.dart';
import 'package:cricapp/src/features/tournaments/data/repositories/tournament_repository_impl.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/fixture.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/standing.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/tournament_request.dart';
import 'package:cricapp/src/features/tournaments/domain/repositories/tournament_repository.dart';

class MockTournamentRemoteDatasource extends Mock
    implements TournamentRemoteDatasource {}

void main() {
  late MockTournamentRemoteDatasource mockDatasource;
  late TournamentRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockTournamentRemoteDatasource();
    repository = TournamentRepositoryImpl(remoteDatasource: mockDatasource);
  });

  final tournamentJson = {
    'id': 'tour-1',
    'name': 'Summer League',
    'format': 'round_robin',
    'oversPerMatch': 20,
    'ballTypeId': 1,
    'status': 'draft',
    'pointsWin': 2,
    'pointsTie': 1,
    'pointsNoResult': 1,
    'pointsLoss': 0,
    'numGroups': 1,
    'qualifyPerGroup': 2,
    'hasThirdPlaceMatch': false,
    'playersPerSide': 11,
    'wideRuns': 1,
    'noBallRuns': 1,
    'createdBy': 'user-1',
    'createdAt': '2026-01-15T10:00:00.000Z',
    'updatedAt': '2026-01-15T10:00:00.000Z',
  };

  group('createTournament', () {
    test('calls datasource and returns Tournament entity', () async {
      when(() => mockDatasource.createTournament(
            name: any(named: 'name'),
            format: any(named: 'format'),
            oversPerMatch: any(named: 'oversPerMatch'),
            ballTypeId: any(named: 'ballTypeId'),
            pointsWin: any(named: 'pointsWin'),
            pointsTie: any(named: 'pointsTie'),
            pointsNoResult: any(named: 'pointsNoResult'),
            pointsLoss: any(named: 'pointsLoss'),
            numGroups: any(named: 'numGroups'),
            qualifyPerGroup: any(named: 'qualifyPerGroup'),
            hasThirdPlaceMatch: any(named: 'hasThirdPlaceMatch'),
            playersPerSide: any(named: 'playersPerSide'),
            maxOversPerBowler: any(named: 'maxOversPerBowler'),
            wideRuns: any(named: 'wideRuns'),
            noBallRuns: any(named: 'noBallRuns'),
            powerplayOvers: any(named: 'powerplayOvers'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => tournamentJson);

      final input = CreateTournamentInput(
        name: 'Summer League',
        format: TournamentFormat.roundRobin,
        oversPerMatch: 20,
        ballTypeId: 1,
      );

      final result = await repository.createTournament(input);

      expect(result, isA<Tournament>());
      expect(result.id, 'tour-1');
      expect(result.name, 'Summer League');
      expect(result.format, TournamentFormat.roundRobin);
      expect(result.status, TournamentStatus.draft);
      verify(() => mockDatasource.createTournament(
            name: 'Summer League',
            format: 'round_robin',
            oversPerMatch: 20,
            ballTypeId: 1,
            pointsWin: 2,
            pointsTie: 1,
            pointsNoResult: 1,
            pointsLoss: 0,
            numGroups: 1,
            qualifyPerGroup: 2,
            hasThirdPlaceMatch: false,
            playersPerSide: 11,
            maxOversPerBowler: null,
            wideRuns: 1,
            noBallRuns: 1,
            powerplayOvers: null,
            startDate: null,
            endDate: null,
          )).called(1);
    });
  });

  group('getTournaments', () {
    test('calls datasource and returns TournamentListResult', () async {
      when(() => mockDatasource.getTournaments(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => {
            'tournaments': [tournamentJson],
            'total': 1,
            'page': 1,
          });

      final result = await repository.getTournaments();

      expect(result, isA<TournamentListResult>());
      expect(result.tournaments.length, 1);
      expect(result.tournaments.first.id, 'tour-1');
      expect(result.total, 1);
      expect(result.page, 1);
    });

    test('passes status filter to datasource', () async {
      when(() => mockDatasource.getTournaments(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => {
            'tournaments': <Map<String, dynamic>>[],
            'total': 0,
            'page': 1,
          });

      await repository.getTournaments(status: TournamentStatus.live);

      verify(() => mockDatasource.getTournaments(
            page: 1,
            limit: 20,
            status: 'live',
          )).called(1);
    });
  });

  group('getTournament', () {
    test('calls datasource and returns Tournament entity', () async {
      when(() => mockDatasource.getTournament(any()))
          .thenAnswer((_) async => tournamentJson);

      final result = await repository.getTournament('tour-1');

      expect(result, isA<Tournament>());
      expect(result.id, 'tour-1');
      verify(() => mockDatasource.getTournament('tour-1')).called(1);
    });
  });

  group('updateTournament', () {
    test('calls datasource with only non-null fields', () async {
      when(() => mockDatasource.updateTournament(any(), any()))
          .thenAnswer((_) async => {
        ...tournamentJson,
        'name': 'Updated League',
      });

      final input = UpdateTournamentInput(name: 'Updated League');
      final result = await repository.updateTournament('tour-1', input);

      expect(result, isA<Tournament>());
      expect(result.name, 'Updated League');
      verify(() => mockDatasource.updateTournament(
            'tour-1',
            {'name': 'Updated League'},
          )).called(1);
    });

    test('includes all provided fields in update data', () async {
      when(() => mockDatasource.updateTournament(any(), any()))
          .thenAnswer((_) async => tournamentJson);

      final input = UpdateTournamentInput(
        name: 'New Name',
        oversPerMatch: 10,
        pointsWin: 3,
      );
      await repository.updateTournament('tour-1', input);

      verify(() => mockDatasource.updateTournament(
            'tour-1',
            {
              'name': 'New Name',
              'oversPerMatch': 10,
              'pointsWin': 3,
            },
          )).called(1);
    });
  });

  group('transitionStatus', () {
    test('calls datasource with status apiValue', () async {
      when(() => mockDatasource.transitionStatus(any(), any()))
          .thenAnswer((_) async => {
        ...tournamentJson,
        'status': 'registration',
      });

      final result = await repository.transitionStatus(
        'tour-1',
        TournamentStatus.registration,
      );

      expect(result, isA<Tournament>());
      expect(result.status, TournamentStatus.registration);
      verify(() => mockDatasource.transitionStatus(
            'tour-1',
            'registration',
          )).called(1);
    });
  });

  group('addTeam', () {
    test('calls datasource and returns TournamentTeam', () async {
      when(() => mockDatasource.addTeam(
            any(),
            teamId: any(named: 'teamId'),
            groupName: any(named: 'groupName'),
            seedNumber: any(named: 'seedNumber'),
          )).thenAnswer((_) async => {
            'id': 'tt-1',
            'tournamentId': 'tour-1',
            'teamId': 'team-1',
            'joinedAt': '2026-01-16T10:00:00.000Z',
            'updatedAt': '2026-01-16T10:00:00.000Z',
            'groupName': 'A',
            'seedNumber': 1,
            'teamName': 'Warriors',
          });

      final result = await repository.addTeam(
        'tour-1',
        teamId: 'team-1',
        groupName: 'A',
        seedNumber: 1,
      );

      expect(result, isA<TournamentTeam>());
      expect(result.teamId, 'team-1');
      expect(result.groupName, 'A');
      expect(result.seedNumber, 1);
    });
  });

  group('registerTeam', () {
    test('calls datasource and returns TournamentRequest', () async {
      when(() => mockDatasource.registerTeam(
            any(),
            teamId: any(named: 'teamId'),
          )).thenAnswer((_) async => {
            'id': 'req-1',
            'tournamentId': 'tour-1',
            'teamId': 'team-1',
            'requestedBy': 'user-1',
            'status': 'pending',
            'requestedAt': '2026-01-16T10:00:00.000Z',
            'updatedAt': '2026-01-16T10:00:00.000Z',
          });

      final result = await repository.registerTeam(
        'tour-1',
        teamId: 'team-1',
      );

      expect(result, isA<TournamentRequest>());
      expect(result.id, 'req-1');
      expect(result.status, RequestStatus.pending);
    });
  });

  group('getRequests', () {
    test('calls datasource and returns list of requests', () async {
      when(() => mockDatasource.getRequests(
            any(),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [
            {
              'id': 'req-1',
              'tournamentId': 'tour-1',
              'teamId': 'team-1',
              'requestedBy': 'user-1',
              'status': 'pending',
              'requestedAt': '2026-01-16T10:00:00.000Z',
              'updatedAt': '2026-01-16T10:00:00.000Z',
              'teamName': 'Warriors',
            },
          ]);

      final result = await repository.getRequests('tour-1');

      expect(result.length, 1);
      expect(result.first.id, 'req-1');
      expect(result.first.teamName, 'Warriors');
    });

    test('passes status filter to datasource', () async {
      when(() => mockDatasource.getRequests(
            any(),
            status: any(named: 'status'),
          )).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await repository.getRequests(
        'tour-1',
        status: RequestStatus.pending,
      );

      verify(() => mockDatasource.getRequests(
            'tour-1',
            status: 'pending',
          )).called(1);
    });
  });

  group('resolveRequest', () {
    test('calls datasource and returns resolved request', () async {
      when(() => mockDatasource.resolveRequest(
            any(),
            any(),
            status: any(named: 'status'),
            groupName: any(named: 'groupName'),
            seedNumber: any(named: 'seedNumber'),
            rejectionReason: any(named: 'rejectionReason'),
          )).thenAnswer((_) async => {
            'id': 'req-1',
            'tournamentId': 'tour-1',
            'teamId': 'team-1',
            'requestedBy': 'user-1',
            'status': 'approved',
            'requestedAt': '2026-01-16T10:00:00.000Z',
            'updatedAt': '2026-01-16T11:00:00.000Z',
            'resolvedAt': '2026-01-16T11:00:00.000Z',
          });

      final result = await repository.resolveRequest(
        'tour-1',
        'req-1',
        status: RequestStatus.approved,
        groupName: 'A',
        seedNumber: 3,
      );

      expect(result, isA<TournamentRequest>());
      expect(result.status, RequestStatus.approved);
    });
  });

  group('removeTeam', () {
    test('calls datasource removeTeam', () async {
      when(() => mockDatasource.removeTeam(any(), any()))
          .thenAnswer((_) async {});

      await repository.removeTeam('tour-1', 'team-1');

      verify(() => mockDatasource.removeTeam('tour-1', 'team-1')).called(1);
    });
  });

  group('generateFixtures', () {
    test('calls datasource and returns GenerateFixturesResult', () async {
      when(() => mockDatasource.generateFixtures(any()))
          .thenAnswer((_) async => {
                'fixtures': [
                  {
                    'id': 'fix-1',
                    'tournamentId': 'tour-1',
                    'roundNumber': 1,
                    'roundType': 'group',
                    'fixtureOrder': 1,
                    'homeTeamId': 'team-1',
                    'awayTeamId': 'team-2',
                  },
                ],
                'totalFixtures': 1,
              });

      final result = await repository.generateFixtures('tour-1');

      expect(result, isA<GenerateFixturesResult>());
      expect(result.fixtures.length, 1);
      expect(result.fixtures.first.id, 'fix-1');
      expect(result.totalFixtures, 1);
    });
  });

  group('getFixtures', () {
    test('calls datasource and returns list of fixtures', () async {
      when(() => mockDatasource.getFixtures(
            any(),
            roundType: any(named: 'roundType'),
            groupName: any(named: 'groupName'),
          )).thenAnswer((_) async => {
            'fixtures': [
              {
                'id': 'fix-1',
                'tournamentId': 'tour-1',
                'roundNumber': 1,
                'roundType': 'group',
                'fixtureOrder': 1,
                'homeTeamId': 'team-1',
                'awayTeamId': 'team-2',
              },
            ],
          });

      final result = await repository.getFixtures('tour-1');

      expect(result.length, 1);
      expect(result.first, isA<Fixture>());
    });

    test('passes filters to datasource', () async {
      when(() => mockDatasource.getFixtures(
            any(),
            roundType: any(named: 'roundType'),
            groupName: any(named: 'groupName'),
          )).thenAnswer((_) async => {
            'fixtures': <Map<String, dynamic>>[],
          });

      await repository.getFixtures(
        'tour-1',
        roundType: RoundType.semiFinal,
        groupName: 'A',
      );

      verify(() => mockDatasource.getFixtures(
            'tour-1',
            roundType: 'semi_final',
            groupName: 'A',
          )).called(1);
    });
  });

  group('editFixture', () {
    test('calls datasource and returns updated Fixture', () async {
      when(() => mockDatasource.editFixture(any(), any(), any()))
          .thenAnswer((_) async => {
                'fixture': {
                  'id': 'fix-1',
                  'tournamentId': 'tour-1',
                  'roundNumber': 1,
                  'roundType': 'group',
                  'fixtureOrder': 1,
                  'homeTeamId': 'team-1',
                  'awayTeamId': 'team-2',
                  'venue': 'Wankhede',
                  'scheduledDate': '2026-03-15',
                },
              });

      final result = await repository.editFixture(
        'tour-1',
        'fix-1',
        venue: 'Wankhede',
        scheduledDate: '2026-03-15',
      );

      expect(result, isA<Fixture>());
      expect(result.venue, 'Wankhede');
    });
  });

  group('getStandings', () {
    test('calls datasource and returns StandingsResult', () async {
      when(() => mockDatasource.getStandings(
            any(),
            groupName: any(named: 'groupName'),
          )).thenAnswer((_) async => {
            'standings': [
              {
                'tournamentId': 'tour-1',
                'teamId': 'team-1',
                'played': 5,
                'won': 3,
                'lost': 1,
                'tied': 1,
                'noResult': 0,
                'points': 7,
                'nrr': '0.625',
                'totalRunsScored': 850,
                'totalOversFaced': '100.0',
                'totalRunsConceded': 780,
                'totalOversBowled': '96.3',
                'teamName': 'Warriors',
              },
            ],
            'groups': ['A', 'B'],
          });

      final result = await repository.getStandings('tour-1');

      expect(result, isA<StandingsResult>());
      expect(result.standings.length, 1);
      expect(result.standings.first, isA<Standing>());
      expect(result.standings.first.teamName, 'Warriors');
      expect(result.groups, ['A', 'B']);
    });
  });

  group('getLeaderboard', () {
    test('calls datasource and returns LeaderboardResult', () async {
      when(() => mockDatasource.getLeaderboard(
            any(),
            category: any(named: 'category'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => {
            'category': 'runs',
            'leaderboard': [
              {
                'rank': 1,
                'playerId': 'p1',
                'playerName': 'Virat Kohli',
                'teamName': 'Warriors',
                'value': 320,
                'matches': 5,
                'details': {'innings': 5, 'strikeRate': 142.4},
              },
            ],
          });

      final result = await repository.getLeaderboard(
        'tour-1',
        category: LeaderboardCategory.runs,
      );

      expect(result, isA<LeaderboardResult>());
      expect(result.category, LeaderboardCategory.runs);
      expect(result.leaderboard.length, 1);
      expect(result.leaderboard.first.rank, 1);
      expect(result.leaderboard.first.playerName, 'Virat Kohli');
      expect(result.leaderboard.first.value, 320.0);
      expect(result.leaderboard.first.details, isNotNull);
    });
  });
}
