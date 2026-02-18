import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

@freezed
abstract class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'homeTeamId') required String homeTeamId,
    @JsonKey(name: 'awayTeamId') required String awayTeamId,
    required String format,
    @JsonKey(name: 'totalOvers') required int totalOvers,
    @JsonKey(name: 'ballTypeId') required int ballTypeId,
    required String status,
    @JsonKey(name: 'playersPerSide') @Default(11) int playersPerSide,
    @JsonKey(name: 'wideRuns') @Default(1) int wideRuns,
    @JsonKey(name: 'noBallRuns') @Default(1) int noBallRuns,
    @JsonKey(name: 'scorerId') required String scorerId,
    @JsonKey(name: 'createdBy') required String createdBy,
    @JsonKey(name: 'matchDate') required String matchDate,
    @JsonKey(name: 'createdAt') String? createdAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
    @JsonKey(name: 'homeTeamName') String? homeTeamName,
    @JsonKey(name: 'awayTeamName') String? awayTeamName,
    String? venue,
    @JsonKey(name: 'tossWinnerId') String? tossWinnerId,
    @JsonKey(name: 'tossDecision') String? tossDecision,
    @JsonKey(name: 'maxOversPerBowler') int? maxOversPerBowler,
    @JsonKey(name: 'powerplayOvers') int? powerplayOvers,
    @JsonKey(name: 'tournamentId') String? tournamentId,
    @JsonKey(name: 'magicOverNumbers') List<int>? magicOverNumbers,
    @JsonKey(name: 'magicOverRunMultiplier') int? magicOverRunMultiplier,
    @JsonKey(name: 'magicOverWicketPenalty') int? magicOverWicketPenalty,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

extension MatchModelX on MatchModel {
  Match toEntity() => Match(
        id: id,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        format: MatchFormat.fromApiValue(format),
        totalOvers: totalOvers,
        ballTypeId: ballTypeId,
        status: MatchStatus.fromApiValue(status),
        playersPerSide: playersPerSide,
        wideRuns: wideRuns,
        noBallRuns: noBallRuns,
        scorerId: scorerId,
        createdBy: createdBy,
        matchDate: matchDate,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        venue: venue,
        tossWinnerId: tossWinnerId,
        tossDecision: tossDecision != null
            ? TossDecision.fromApiValue(tossDecision!)
            : null,
        maxOversPerBowler: maxOversPerBowler,
        powerplayOvers: powerplayOvers,
        tournamentId: tournamentId,
        magicOverNumbers: magicOverNumbers,
        magicOverRunMultiplier: magicOverRunMultiplier ?? 2,
        magicOverWicketPenalty: magicOverWicketPenalty ?? -5,
      );
}

@freezed
abstract class PlayingXIModel with _$PlayingXIModel {
  const factory PlayingXIModel({
    required String id,
    @JsonKey(name: 'matchId') required String matchId,
    @JsonKey(name: 'teamId') required String teamId,
    @JsonKey(name: 'playerId') required String playerId,
    @JsonKey(name: 'battingOrder') int? battingOrder,
    @JsonKey(name: 'isPlaying') @Default(true) bool isPlaying,
    @JsonKey(name: 'isCaptain') @Default(false) bool isCaptain,
    @JsonKey(name: 'isKeeper') @Default(false) bool isKeeper,
    @JsonKey(name: 'displayName') String? displayName,
    @JsonKey(name: 'playerRole') String? playerRole,
    @JsonKey(name: 'battingStyle') String? battingStyle,
    @JsonKey(name: 'bowlingStyle') String? bowlingStyle,
  }) = _PlayingXIModel;

  factory PlayingXIModel.fromJson(Map<String, dynamic> json) =>
      _$PlayingXIModelFromJson(json);
}

extension PlayingXIModelX on PlayingXIModel {
  PlayingXIEntry toEntity() => PlayingXIEntry(
        playerId: playerId,
        displayName: displayName ?? 'Player',
        isCaptain: isCaptain,
        isKeeper: isKeeper,
        playerRole: playerRole,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        battingOrder: battingOrder,
      );
}
