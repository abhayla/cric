import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/match.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/toss_notifier.dart';

void main() {
  // -- Test data --
  const homeId = 'home-team-id';
  const awayId = 'away-team-id';
  const homeName = 'Mumbai Warriors';
  const awayName = 'Delhi Strikers';

  List<RosterPlayer> makeRoster(int count, {String prefix = 'p'}) {
    return List.generate(count, (i) {
      return RosterPlayer(
        playerId: '$prefix-$i',
        displayName: 'Player ${i + 1}',
        playerRole: i < 3 ? 'batter' : (i < 6 ? 'bowler' : 'all_rounder'),
        isCaptain: i == 0,
        isKeeper: i == 4,
      );
    });
  }

  TossState makeState({
    TossStep? currentStep,
    String? tossWinnerId,
    TossDecision? tossDecision,
    List<RosterPlayer>? homeRoster,
    List<RosterPlayer>? awayRoster,
    Set<String>? selectedHomePlayerIds,
    Set<String>? selectedAwayPlayerIds,
    List<String>? openingBatterIds,
    String? strikerId,
    String? openingBowlerId,
    int playersPerSide = 11,
  }) {
    final hRoster = homeRoster ?? makeRoster(11, prefix: 'h');
    final aRoster = awayRoster ?? makeRoster(11, prefix: 'a');
    return TossState(
      matchId: 'match-1',
      homeTeamId: homeId,
      homeTeamName: homeName,
      awayTeamId: awayId,
      awayTeamName: awayName,
      playersPerSide: playersPerSide,
      homeRoster: hRoster,
      awayRoster: aRoster,
      currentStep: currentStep ?? TossStep.tossWinner,
      tossWinnerId: tossWinnerId,
      tossDecision: tossDecision,
      selectedHomePlayerIds:
          selectedHomePlayerIds ?? hRoster.map((p) => p.playerId).toSet(),
      selectedAwayPlayerIds:
          selectedAwayPlayerIds ?? aRoster.map((p) => p.playerId).toSet(),
      openingBatterIds: openingBatterIds ?? const [],
      strikerId: strikerId,
      openingBowlerId: openingBowlerId,
    );
  }

  group('TossStep', () {
    test('has 5 values', () {
      expect(TossStep.values.length, 5);
    });

    test('values are in expected order', () {
      expect(TossStep.values, [
        TossStep.tossWinner,
        TossStep.decision,
        TossStep.xiTeamA,
        TossStep.xiTeamB,
        TossStep.openers,
      ]);
    });

    test('each step has a label', () {
      expect(TossStep.tossWinner.label, 'Toss');
      expect(TossStep.decision.label, 'Choice');
      expect(TossStep.xiTeamA.label, 'XI-A');
      expect(TossStep.xiTeamB.label, 'XI-B');
      expect(TossStep.openers.label, 'Openers');
    });

    test('stepNumber is 1-based index', () {
      expect(TossStep.tossWinner.stepNumber, 1);
      expect(TossStep.decision.stepNumber, 2);
      expect(TossStep.xiTeamA.stepNumber, 3);
      expect(TossStep.xiTeamB.stepNumber, 4);
      expect(TossStep.openers.stepNumber, 5);
    });
  });

  group('RosterPlayer', () {
    test('construction and field access', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun Mehta',
        playerRole: 'batter',
        isCaptain: true,
        isKeeper: false,
      );

      expect(player.playerId, 'p1');
      expect(player.displayName, 'Arjun Mehta');
      expect(player.playerRole, 'batter');
      expect(player.isCaptain, true);
      expect(player.isKeeper, false);
    });

    test('initials from two-word name', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun Mehta',
      );
      expect(player.initials, 'AM');
    });

    test('initials from single-word name', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun',
      );
      expect(player.initials, 'A');
    });

    test('badge for captain', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun',
        isCaptain: true,
      );
      expect(player.badge, '(C)');
    });

    test('badge for keeper', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun',
        isKeeper: true,
      );
      expect(player.badge, '(WK)');
    });

    test('badge for captain and keeper', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun',
        isCaptain: true,
        isKeeper: true,
      );
      expect(player.badge, '(C & WK)');
    });

    test('badge is null for regular player', () {
      const player = RosterPlayer(
        playerId: 'p1',
        displayName: 'Arjun',
      );
      expect(player.badge, isNull);
    });
  });

  group('TossState defaults', () {
    test('currentStep defaults to tossWinner', () {
      final state = makeState();
      expect(state.currentStep, TossStep.tossWinner);
    });

    test('tossWinnerId defaults to null', () {
      final state = makeState();
      expect(state.tossWinnerId, isNull);
    });

    test('tossDecision defaults to null', () {
      final state = makeState();
      expect(state.tossDecision, isNull);
    });

    test('openingBatterIds defaults to empty', () {
      final state = makeState();
      expect(state.openingBatterIds, isEmpty);
    });

    test('strikerId defaults to null', () {
      final state = makeState();
      expect(state.strikerId, isNull);
    });

    test('openingBowlerId defaults to null', () {
      final state = makeState();
      expect(state.openingBowlerId, isNull);
    });

    test('isSubmitting defaults to false', () {
      final state = makeState();
      expect(state.isSubmitting, false);
    });

    test('error defaults to null', () {
      final state = makeState();
      expect(state.error, isNull);
    });

    test('rosters pre-select all players when roster size == playersPerSide',
        () {
      final state = makeState(playersPerSide: 11);
      expect(state.selectedHomePlayerIds.length, 11);
      expect(state.selectedAwayPlayerIds.length, 11);
    });
  });

  group('TossState canProceed', () {
    test('Step 1: false without tossWinnerId', () {
      final state = makeState(
        currentStep: TossStep.tossWinner,
        tossWinnerId: null,
      );
      expect(state.canProceed, false);
    });

    test('Step 1: true with tossWinnerId', () {
      final state = makeState(
        currentStep: TossStep.tossWinner,
        tossWinnerId: homeId,
      );
      expect(state.canProceed, true);
    });

    test('Step 2: false without tossDecision', () {
      final state = makeState(
        currentStep: TossStep.decision,
        tossWinnerId: homeId,
        tossDecision: null,
      );
      expect(state.canProceed, false);
    });

    test('Step 2: true with tossDecision', () {
      final state = makeState(
        currentStep: TossStep.decision,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
      );
      expect(state.canProceed, true);
    });

    test('Step 3: false when selected count != playersPerSide', () {
      final state = makeState(
        currentStep: TossStep.xiTeamA,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        selectedHomePlayerIds: {'h-0', 'h-1', 'h-2'}, // only 3
      );
      expect(state.canProceed, false);
    });

    test('Step 3: true when selected count == playersPerSide', () {
      final roster = makeRoster(11, prefix: 'h');
      final state = makeState(
        currentStep: TossStep.xiTeamA,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        homeRoster: roster,
        selectedHomePlayerIds: roster.map((p) => p.playerId).toSet(),
      );
      expect(state.canProceed, true);
    });

    test('Step 4: false when selected count != playersPerSide', () {
      final state = makeState(
        currentStep: TossStep.xiTeamB,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        selectedAwayPlayerIds: {'a-0', 'a-1'}, // only 2
      );
      expect(state.canProceed, false);
    });

    test('Step 4: true when selected count == playersPerSide', () {
      final roster = makeRoster(11, prefix: 'a');
      final state = makeState(
        currentStep: TossStep.xiTeamB,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        awayRoster: roster,
        selectedAwayPlayerIds: roster.map((p) => p.playerId).toSet(),
      );
      expect(state.canProceed, true);
    });

    test('Step 5: false without 2 openers', () {
      final state = makeState(
        currentStep: TossStep.openers,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0'], // only 1
        strikerId: 'h-0',
        openingBowlerId: 'a-0',
      );
      expect(state.canProceed, false);
    });

    test('Step 5: false without strikerId', () {
      final state = makeState(
        currentStep: TossStep.openers,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0', 'h-1'],
        strikerId: null,
        openingBowlerId: 'a-0',
      );
      expect(state.canProceed, false);
    });

    test('Step 5: false without openingBowlerId', () {
      final state = makeState(
        currentStep: TossStep.openers,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0', 'h-1'],
        strikerId: 'h-0',
        openingBowlerId: null,
      );
      expect(state.canProceed, false);
    });

    test('Step 5: true when all openers and bowler selected', () {
      final state = makeState(
        currentStep: TossStep.openers,
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0', 'h-1'],
        strikerId: 'h-0',
        openingBowlerId: 'a-0',
      );
      expect(state.canProceed, true);
    });
  });

  group('TossState team derivation', () {
    test('home wins toss and bats: batting team is home', () {
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
      );
      expect(state.battingTeamId, homeId);
      expect(state.fieldingTeamId, awayId);
      expect(state.battingTeamName, homeName);
      expect(state.fieldingTeamName, awayName);
    });

    test('home wins toss and fields: batting team is away', () {
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.field,
      );
      expect(state.battingTeamId, awayId);
      expect(state.fieldingTeamId, homeId);
      expect(state.battingTeamName, awayName);
      expect(state.fieldingTeamName, homeName);
    });

    test('away wins toss and bats: batting team is away', () {
      final state = makeState(
        tossWinnerId: awayId,
        tossDecision: TossDecision.bat,
      );
      expect(state.battingTeamId, awayId);
      expect(state.fieldingTeamId, homeId);
    });

    test('away wins toss and fields: batting team is home', () {
      final state = makeState(
        tossWinnerId: awayId,
        tossDecision: TossDecision.field,
      );
      expect(state.battingTeamId, homeId);
      expect(state.fieldingTeamId, awayId);
    });

    test('returns null when toss not decided', () {
      final state = makeState(tossWinnerId: null, tossDecision: null);
      expect(state.battingTeamId, isNull);
      expect(state.fieldingTeamId, isNull);
      expect(state.battingTeamName, isNull);
      expect(state.fieldingTeamName, isNull);
    });

    test('returns null when decision not made', () {
      final state = makeState(tossWinnerId: homeId, tossDecision: null);
      expect(state.battingTeamId, isNull);
      expect(state.fieldingTeamId, isNull);
    });
  });

  group('TossState batting/fielding rosters', () {
    test('battingXI returns selected players from batting team roster', () {
      final homeRoster = makeRoster(11, prefix: 'h');
      final selected = homeRoster.take(6).map((p) => p.playerId).toSet();
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        homeRoster: homeRoster,
        selectedHomePlayerIds: selected,
        playersPerSide: 6,
      );
      expect(state.battingXI.length, 6);
      expect(
        state.battingXI.every((p) => selected.contains(p.playerId)),
        true,
      );
    });

    test('fieldingXI returns selected players from fielding team roster', () {
      final awayRoster = makeRoster(11, prefix: 'a');
      final selected = awayRoster.take(6).map((p) => p.playerId).toSet();
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        awayRoster: awayRoster,
        selectedAwayPlayerIds: selected,
        playersPerSide: 6,
      );
      expect(state.fieldingXI.length, 6);
    });
  });

  group('TossState toss winner name', () {
    test('returns home team name when home wins', () {
      final state = makeState(tossWinnerId: homeId);
      expect(state.tossWinnerName, homeName);
    });

    test('returns away team name when away wins', () {
      final state = makeState(tossWinnerId: awayId);
      expect(state.tossWinnerName, awayName);
    });

    test('returns null when no winner', () {
      final state = makeState(tossWinnerId: null);
      expect(state.tossWinnerName, isNull);
    });
  });

  group('TossState copyWith', () {
    test('preserves existing values when not overridden', () {
      final state = makeState(tossWinnerId: homeId);
      final copy = state.copyWith();
      expect(copy.tossWinnerId, homeId);
      expect(copy.matchId, state.matchId);
      expect(copy.homeTeamId, state.homeTeamId);
    });

    test('overrides specified values', () {
      final state = makeState(tossWinnerId: homeId);
      final copy = state.copyWith(
        tossWinnerId: awayId,
        tossDecision: TossDecision.bat,
        currentStep: TossStep.decision,
      );
      expect(copy.tossWinnerId, awayId);
      expect(copy.tossDecision, TossDecision.bat);
      expect(copy.currentStep, TossStep.decision);
    });

    test('can update openingBatterIds', () {
      final state = makeState();
      final copy = state.copyWith(openingBatterIds: ['h-0', 'h-1']);
      expect(copy.openingBatterIds, ['h-0', 'h-1']);
    });

    test('can update strikerId', () {
      final state = makeState();
      final copy = state.copyWith(strikerId: 'h-0');
      expect(copy.strikerId, 'h-0');
    });

    test('can clear strikerId to null', () {
      final state = makeState(strikerId: 'h-0');
      final copy = state.copyWith(strikerId: null);
      expect(copy.strikerId, isNull);
    });

    test('can update openingBowlerId', () {
      final state = makeState();
      final copy = state.copyWith(openingBowlerId: 'a-0');
      expect(copy.openingBowlerId, 'a-0');
    });

    test('can clear openingBowlerId to null', () {
      final state = makeState(openingBowlerId: 'a-0');
      final copy = state.copyWith(openingBowlerId: null);
      expect(copy.openingBowlerId, isNull);
    });

    test('can update isSubmitting', () {
      final state = makeState();
      final copy = state.copyWith(isSubmitting: true);
      expect(copy.isSubmitting, true);
    });

    test('can update error', () {
      final state = makeState();
      final copy = state.copyWith(error: 'Something went wrong');
      expect(copy.error, 'Something went wrong');
    });

    test('can update selectedHomePlayerIds', () {
      final state = makeState();
      final copy = state.copyWith(selectedHomePlayerIds: {'h-0', 'h-1'});
      expect(copy.selectedHomePlayerIds, {'h-0', 'h-1'});
    });

    test('can update selectedAwayPlayerIds', () {
      final state = makeState();
      final copy = state.copyWith(selectedAwayPlayerIds: {'a-0', 'a-1'});
      expect(copy.selectedAwayPlayerIds, {'a-0', 'a-1'});
    });
  });

  group('TossState step navigation', () {
    test('isFirstStep is true on tossWinner step', () {
      final state = makeState(currentStep: TossStep.tossWinner);
      expect(state.isFirstStep, true);
    });

    test('isFirstStep is false on other steps', () {
      final state = makeState(currentStep: TossStep.decision);
      expect(state.isFirstStep, false);
    });

    test('isLastStep is true on openers step', () {
      final state = makeState(currentStep: TossStep.openers);
      expect(state.isLastStep, true);
    });

    test('isLastStep is false on other steps', () {
      final state = makeState(currentStep: TossStep.xiTeamB);
      expect(state.isLastStep, false);
    });

    test('nextButtonLabel is "Next" for non-last steps', () {
      final state = makeState(currentStep: TossStep.tossWinner);
      expect(state.nextButtonLabel, 'Next');
    });

    test('nextButtonLabel is "Start Match" for last step', () {
      final state = makeState(currentStep: TossStep.openers);
      expect(state.nextButtonLabel, 'Start Match');
    });
  });

  group('TossState toRecordTossInput', () {
    test('creates valid input when all required fields are set', () {
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0', 'h-1'],
        strikerId: 'h-0',
        openingBowlerId: 'a-0',
      );
      final input = state.toRecordTossInput();
      expect(input.winnerId, homeId);
      expect(input.decision, TossDecision.bat);
      expect(input.openingStrikerId, 'h-0');
      expect(input.openingNonStrikerId, 'h-1');
      expect(input.openingBowlerId, 'a-0');
    });

    test('non-striker is the opener who is NOT the striker', () {
      final state = makeState(
        tossWinnerId: homeId,
        tossDecision: TossDecision.bat,
        openingBatterIds: ['h-0', 'h-1'],
        strikerId: 'h-1', // second opener is striker
        openingBowlerId: 'a-0',
      );
      final input = state.toRecordTossInput();
      expect(input.openingStrikerId, 'h-1');
      expect(input.openingNonStrikerId, 'h-0'); // other opener
    });
  });

  group('TossState toSetPlayingXIInputs', () {
    test('creates input for home team with selected players', () {
      final roster = makeRoster(11, prefix: 'h');
      final selectedIds = roster.map((p) => p.playerId).toSet();
      final state = makeState(
        homeRoster: roster,
        selectedHomePlayerIds: selectedIds,
      );
      final input = state.toHomePlayingXIInput();
      expect(input.teamId, homeId);
      expect(input.playerIds.length, 11);
      expect(input.captainId, 'h-0'); // isCaptain = true for index 0
      expect(input.keeperId, 'h-4'); // isKeeper = true for index 4
    });

    test('creates input for away team with selected players', () {
      final roster = makeRoster(11, prefix: 'a');
      final selectedIds = roster.map((p) => p.playerId).toSet();
      final state = makeState(
        awayRoster: roster,
        selectedAwayPlayerIds: selectedIds,
      );
      final input = state.toAwayPlayingXIInput();
      expect(input.teamId, awayId);
      expect(input.playerIds.length, 11);
      expect(input.captainId, 'a-0');
      expect(input.keeperId, 'a-4');
    });
  });

  group('TossState XI count display', () {
    test('homeXICount returns selected count', () {
      final state = makeState(
        selectedHomePlayerIds: {'h-0', 'h-1', 'h-2'},
      );
      expect(state.homeXICount, 3);
    });

    test('awayXICount returns selected count', () {
      final state = makeState(
        selectedAwayPlayerIds: {'a-0', 'a-1'},
      );
      expect(state.awayXICount, 2);
    });

    test('homeXICountLabel formats as "3 / 11 selected"', () {
      final state = makeState(
        selectedHomePlayerIds: {'h-0', 'h-1', 'h-2'},
        playersPerSide: 11,
      );
      expect(state.homeXICountLabel, '3 / 11 selected');
    });

    test('awayXICountLabel formats as "11 / 11 selected"', () {
      final roster = makeRoster(11, prefix: 'a');
      final state = makeState(
        awayRoster: roster,
        selectedAwayPlayerIds: roster.map((p) => p.playerId).toSet(),
        playersPerSide: 11,
      );
      expect(state.awayXICountLabel, '11 / 11 selected');
    });
  });
}
