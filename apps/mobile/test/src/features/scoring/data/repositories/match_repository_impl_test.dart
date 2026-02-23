import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/features/scoring/data/datasources/match_remote_datasource.dart';
import 'package:cricapp/src/features/scoring/data/repositories/match_repository_impl.dart';
import 'package:cricapp/src/features/scoring/domain/entities/match.dart';
import 'package:cricapp/src/features/scoring/domain/repositories/match_repository.dart';

class MockMatchRemoteDatasource extends Mock implements MatchRemoteDatasource {}

void main() {
  late MockMatchRemoteDatasource mockDatasource;
  late MatchRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockMatchRemoteDatasource();
    repository = MatchRepositoryImpl(remoteDatasource: mockDatasource);
  });

  final matchJson = {
    'id': 'match-1',
    'homeTeamId': 'team-home',
    'awayTeamId': 'team-away',
    'format': 'T20',
    'totalOvers': 20,
    'ballTypeId': 1,
    'status': 'setup',
    'playersPerSide': 11,
    'wideRuns': 1,
    'noBallRuns': 1,
    'scorerId': 'user-1',
    'createdBy': 'user-1',
    'matchDate': '2026-01-15',
    'createdAt': '2026-01-15T10:00:00.000Z',
    'updatedAt': '2026-01-15T10:00:00.000Z',
  };

  group('createMatch', () {
    test('calls datasource and returns Match entity', () async {
      when(() => mockDatasource.createMatch(
            homeTeamId: any(named: 'homeTeamId'),
            awayTeamId: any(named: 'awayTeamId'),
            format: any(named: 'format'),
            totalOvers: any(named: 'totalOvers'),
            ballTypeId: any(named: 'ballTypeId'),
            matchDate: any(named: 'matchDate'),
            venue: any(named: 'venue'),
            playersPerSide: any(named: 'playersPerSide'),
            maxOversPerBowler: any(named: 'maxOversPerBowler'),
            wideRuns: any(named: 'wideRuns'),
            noBallRuns: any(named: 'noBallRuns'),
            powerplayOvers: any(named: 'powerplayOvers'),
          )).thenAnswer((_) async => matchJson);

      const input = CreateMatchInput(
        homeTeamId: 'team-home',
        awayTeamId: 'team-away',
        format: MatchFormat.t20,
        totalOvers: 20,
        ballTypeId: 1,
        matchDate: '2026-01-15',
      );

      final result = await repository.createMatch(input);

      expect(result, isA<Match>());
      expect(result.id, 'match-1');
      expect(result.status, MatchStatus.setup);
      verify(() => mockDatasource.createMatch(
            homeTeamId: 'team-home',
            awayTeamId: 'team-away',
            format: 'T20',
            totalOvers: 20,
            ballTypeId: 1,
            matchDate: '2026-01-15',
            venue: null,
            playersPerSide: null,
            maxOversPerBowler: null,
            wideRuns: null,
            noBallRuns: null,
            powerplayOvers: null,
          )).called(1);
    });
  });

  group('getMatches', () {
    test('calls datasource and returns MatchListResult', () async {
      when(() => mockDatasource.getMatches(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => {
            'matches': [matchJson],
            'total': 1,
            'page': 1,
          });

      final result = await repository.getMatches();

      expect(result, isA<MatchListResult>());
      expect(result.matches.length, 1);
      expect(result.matches.first.id, 'match-1');
      expect(result.total, 1);
      expect(result.page, 1);
    });
  });

  group('getMatch', () {
    test('calls datasource and returns Match entity', () async {
      when(() => mockDatasource.getMatch(any()))
          .thenAnswer((_) async => matchJson);

      final result = await repository.getMatch('match-1');

      expect(result, isA<Match>());
      expect(result.id, 'match-1');
      verify(() => mockDatasource.getMatch('match-1')).called(1);
    });
  });

  group('setPlayingXI', () {
    test('calls datasource and returns list of PlayingXIEntry', () async {
      final playersJson = [
        {
          'id': 'mp-1',
          'matchId': 'match-1',
          'teamId': 'team-1',
          'playerId': 'p1',
          'battingOrder': 1,
          'isPlaying': true,
          'isCaptain': true,
          'isKeeper': false,
        },
        {
          'id': 'mp-2',
          'matchId': 'match-1',
          'teamId': 'team-1',
          'playerId': 'p2',
          'battingOrder': 2,
          'isPlaying': true,
          'isCaptain': false,
          'isKeeper': true,
        },
      ];

      when(() => mockDatasource.setPlayingXI(
            any(),
            teamId: any(named: 'teamId'),
            playerIds: any(named: 'playerIds'),
            captainId: any(named: 'captainId'),
            keeperId: any(named: 'keeperId'),
          )).thenAnswer((_) async => playersJson);

      const input = SetPlayingXIInput(
        teamId: 'team-1',
        playerIds: ['p1', 'p2'],
        captainId: 'p1',
        keeperId: 'p2',
      );

      final result = await repository.setPlayingXI('match-1', input);

      expect(result, isA<List<PlayingXIEntry>>());
      expect(result.length, 2);
      expect(result[0].isCaptain, true);
      expect(result[1].isKeeper, true);
    });
  });

  group('recordToss', () {
    test('calls datasource and returns Match entity', () async {
      final tossResponseJson = {
        ...matchJson,
        'status': 'live',
        'tossWinnerId': 'team-home',
        'tossDecision': 'bat',
      };

      when(() => mockDatasource.recordToss(
            any(),
            winnerId: any(named: 'winnerId'),
            decision: any(named: 'decision'),
            openingStrikerId: any(named: 'openingStrikerId'),
            openingNonStrikerId: any(named: 'openingNonStrikerId'),
            openingBowlerId: any(named: 'openingBowlerId'),
          )).thenAnswer((_) async => tossResponseJson);

      const input = RecordTossInput(
        winnerId: 'team-home',
        decision: TossDecision.bat,
        openingStrikerId: 'p1',
        openingNonStrikerId: 'p2',
        openingBowlerId: 'p3',
      );

      final result = await repository.recordToss('match-1', input);

      expect(result, isA<Match>());
      expect(result.status, MatchStatus.live);
      expect(result.tossDecision, TossDecision.bat);
    });
  });
}
