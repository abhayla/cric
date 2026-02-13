import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';

/// Sentinel for [TossState.copyWith] to distinguish "not provided" from "set to null".
const _unset = Object();

/// Steps in the toss wizard.
enum TossStep {
  tossWinner(1, 'Toss'),
  decision(2, 'Choice'),
  xiTeamA(3, 'XI-A'),
  xiTeamB(4, 'XI-B'),
  openers(5, 'Openers');

  const TossStep(this.stepNumber, this.label);
  final int stepNumber;
  final String label;
}

/// Lightweight player data for the toss wizard roster selection.
class RosterPlayer {
  const RosterPlayer({
    required this.playerId,
    required this.displayName,
    this.playerRole,
    this.isCaptain = false,
    this.isKeeper = false,
  });

  final String playerId;
  final String displayName;
  final String? playerRole;
  final bool isCaptain;
  final bool isKeeper;

  /// Initials from display name.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Badge text: "(C)", "(WK)", "(C & WK)", or null.
  String? get badge {
    if (isCaptain && isKeeper) return '(C & WK)';
    if (isCaptain) return '(C)';
    if (isKeeper) return '(WK)';
    return null;
  }
}

/// Form state for the Toss wizard page.
class TossState {
  TossState({
    required this.matchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.playersPerSide,
    required this.homeRoster,
    required this.awayRoster,
    this.currentStep = TossStep.tossWinner,
    this.tossWinnerId,
    this.tossDecision,
    Set<String>? selectedHomePlayerIds,
    Set<String>? selectedAwayPlayerIds,
    this.openingBatterIds = const [],
    this.strikerId,
    this.openingBowlerId,
    this.isSubmitting = false,
    this.error,
  })  : selectedHomePlayerIds = selectedHomePlayerIds ??
            (homeRoster.length == playersPerSide
                ? homeRoster.map((p) => p.playerId).toSet()
                : <String>{}),
        selectedAwayPlayerIds = selectedAwayPlayerIds ??
            (awayRoster.length == playersPerSide
                ? awayRoster.map((p) => p.playerId).toSet()
                : <String>{});

  final String matchId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final int playersPerSide;
  final List<RosterPlayer> homeRoster;
  final List<RosterPlayer> awayRoster;

  final TossStep currentStep;
  final String? tossWinnerId;
  final TossDecision? tossDecision;
  final Set<String> selectedHomePlayerIds;
  final Set<String> selectedAwayPlayerIds;
  final List<String> openingBatterIds;
  final String? strikerId;
  final String? openingBowlerId;
  final bool isSubmitting;
  final String? error;

  // -- Step navigation --

  bool get isFirstStep => currentStep == TossStep.tossWinner;
  bool get isLastStep => currentStep == TossStep.openers;

  String get nextButtonLabel => isLastStep ? 'Start Match' : 'Next';

  // -- Validation per step --

  bool get canProceed {
    switch (currentStep) {
      case TossStep.tossWinner:
        return tossWinnerId != null;
      case TossStep.decision:
        return tossDecision != null;
      case TossStep.xiTeamA:
        return selectedHomePlayerIds.length == playersPerSide;
      case TossStep.xiTeamB:
        return selectedAwayPlayerIds.length == playersPerSide;
      case TossStep.openers:
        return openingBatterIds.length == 2 &&
            strikerId != null &&
            openingBowlerId != null;
    }
  }

  // -- Team derivation from toss --

  String? get tossWinnerName {
    if (tossWinnerId == homeTeamId) return homeTeamName;
    if (tossWinnerId == awayTeamId) return awayTeamName;
    return null;
  }

  String? get battingTeamId {
    if (tossWinnerId == null || tossDecision == null) return null;
    final winnerBats = tossDecision == TossDecision.bat;
    if (tossWinnerId == homeTeamId) {
      return winnerBats ? homeTeamId : awayTeamId;
    }
    return winnerBats ? awayTeamId : homeTeamId;
  }

  String? get fieldingTeamId {
    if (battingTeamId == null) return null;
    return battingTeamId == homeTeamId ? awayTeamId : homeTeamId;
  }

  String? get battingTeamName {
    if (battingTeamId == homeTeamId) return homeTeamName;
    if (battingTeamId == awayTeamId) return awayTeamName;
    return null;
  }

  String? get fieldingTeamName {
    if (fieldingTeamId == homeTeamId) return homeTeamName;
    if (fieldingTeamId == awayTeamId) return awayTeamName;
    return null;
  }

  // -- Playing XI derived lists --

  List<RosterPlayer> get battingXI {
    if (battingTeamId == homeTeamId) {
      return homeRoster
          .where((p) => selectedHomePlayerIds.contains(p.playerId))
          .toList();
    }
    return awayRoster
        .where((p) => selectedAwayPlayerIds.contains(p.playerId))
        .toList();
  }

  List<RosterPlayer> get fieldingXI {
    if (fieldingTeamId == homeTeamId) {
      return homeRoster
          .where((p) => selectedHomePlayerIds.contains(p.playerId))
          .toList();
    }
    return awayRoster
        .where((p) => selectedAwayPlayerIds.contains(p.playerId))
        .toList();
  }

  // -- XI count helpers --

  int get homeXICount => selectedHomePlayerIds.length;
  int get awayXICount => selectedAwayPlayerIds.length;

  String get homeXICountLabel => '$homeXICount / $playersPerSide selected';
  String get awayXICountLabel => '$awayXICount / $playersPerSide selected';

  // -- Conversion to API inputs --

  RecordTossInput toRecordTossInput() {
    final nonStrikerId =
        openingBatterIds.firstWhere((id) => id != strikerId);
    return RecordTossInput(
      winnerId: tossWinnerId!,
      decision: tossDecision!,
      openingStrikerId: strikerId!,
      openingNonStrikerId: nonStrikerId,
      openingBowlerId: openingBowlerId!,
    );
  }

  SetPlayingXIInput toHomePlayingXIInput() => _buildPlayingXIInput(
        teamId: homeTeamId,
        roster: homeRoster,
        selectedIds: selectedHomePlayerIds,
      );

  SetPlayingXIInput toAwayPlayingXIInput() => _buildPlayingXIInput(
        teamId: awayTeamId,
        roster: awayRoster,
        selectedIds: selectedAwayPlayerIds,
      );

  SetPlayingXIInput _buildPlayingXIInput({
    required String teamId,
    required List<RosterPlayer> roster,
    required Set<String> selectedIds,
  }) {
    final selectedPlayers =
        roster.where((p) => selectedIds.contains(p.playerId));
    final captain = selectedPlayers.firstWhere(
      (p) => p.isCaptain,
      orElse: () => selectedPlayers.first,
    );
    final keeper = selectedPlayers.firstWhere(
      (p) => p.isKeeper,
      orElse: () => selectedPlayers.first,
    );
    return SetPlayingXIInput(
      teamId: teamId,
      playerIds: selectedIds.toList(),
      captainId: captain.playerId,
      keeperId: keeper.playerId,
    );
  }

  // -- Copy --

  TossState copyWith({
    TossStep? currentStep,
    String? tossWinnerId,
    TossDecision? tossDecision,
    Set<String>? selectedHomePlayerIds,
    Set<String>? selectedAwayPlayerIds,
    List<String>? openingBatterIds,
    Object? strikerId = _unset,
    Object? openingBowlerId = _unset,
    bool? isSubmitting,
    String? error,
  }) {
    return TossState(
      matchId: matchId,
      homeTeamId: homeTeamId,
      homeTeamName: homeTeamName,
      awayTeamId: awayTeamId,
      awayTeamName: awayTeamName,
      playersPerSide: playersPerSide,
      homeRoster: homeRoster,
      awayRoster: awayRoster,
      currentStep: currentStep ?? this.currentStep,
      tossWinnerId: tossWinnerId ?? this.tossWinnerId,
      tossDecision: tossDecision ?? this.tossDecision,
      selectedHomePlayerIds:
          selectedHomePlayerIds ?? this.selectedHomePlayerIds,
      selectedAwayPlayerIds:
          selectedAwayPlayerIds ?? this.selectedAwayPlayerIds,
      openingBatterIds: openingBatterIds ?? this.openingBatterIds,
      strikerId:
          identical(strikerId, _unset) ? this.strikerId : strikerId as String?,
      openingBowlerId: identical(openingBowlerId, _unset)
          ? this.openingBowlerId
          : openingBowlerId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}
