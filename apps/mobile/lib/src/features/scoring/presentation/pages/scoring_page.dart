import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/data/sync/sync_service.dart';
import '../../../../shared/data/websocket/websocket_client.dart';
import '../../data/datasources/scoring_local_datasource.dart';
import '../../domain/entities/innings_data.dart';
import '../../domain/entities/playing_xi_player.dart';
import '../../domain/entities/scorecard_data.dart';
import '../notifiers/scoring_notifier.dart';
import '../notifiers/scoring_persistence_service.dart';
import 'scorecard_page.dart';
import '../widgets/batter_card.dart';
import '../widgets/bowler_card.dart';
import '../widgets/extras_panel.dart';
import '../widgets/score_header.dart';
import '../widgets/scoring_controls.dart';
import '../widgets/select_batter_sheet.dart';
import '../widgets/select_bowler_sheet.dart';
import '../widgets/this_over_display.dart';
import '../widgets/innings_transition_modal.dart';
import '../widgets/match_complete_modal.dart';
import '../widgets/super_over_setup_wizard.dart';
import '../widgets/wicket_dialog.dart';

/// Arguments for initializing the scoring page.
class ScoringPageArgs {
  const ScoringPageArgs({
    required this.matchId,
    required this.inningsId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.inningsNumber,
    required this.totalOvers,
    required this.playersPerSide,
    this.target,
    this.wideRunsPenalty = 1,
    this.noBallRunsPenalty = 1,
    this.magicOverNumbers,
    this.magicOverRunMultiplier = 2,
    this.magicOverWicketPenalty = -5,
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
    required this.openingStrikerId,
    required this.openingStrikerName,
    required this.openingNonStrikerId,
    required this.openingNonStrikerName,
    required this.openingBowlerId,
    required this.openingBowlerName,
    this.firstInningsSummary,
    this.isKnockoutMatch = false,
  });

  final String matchId;
  final String inningsId;
  final String battingTeamId;
  final String bowlingTeamId;
  final String battingTeamName;
  final String bowlingTeamName;
  final int inningsNumber;
  final int totalOvers;
  final int playersPerSide;
  final int? target;
  final int wideRunsPenalty;
  final int noBallRunsPenalty;
  final List<int>? magicOverNumbers;
  final int magicOverRunMultiplier;
  final int magicOverWicketPenalty;
  final List<PlayingXIPlayer> battingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final String openingStrikerId;
  final String openingStrikerName;
  final String openingNonStrikerId;
  final String openingNonStrikerName;
  final String openingBowlerId;
  final String openingBowlerName;
  final FirstInningsSummary? firstInningsSummary;
  final bool isKnockoutMatch;
}

/// Main scoring page where the scorer records deliveries ball-by-ball.
class ScoringPage extends StatefulWidget {
  const ScoringPage({
    super.key,
    required this.args,
    this.datasource,
    this.syncService,
    this.wsClient,
  });

  final ScoringPageArgs args;

  /// Optional local datasource for persistence. When provided, scoring state
  /// is automatically saved after every mutation and can be resumed.
  final ScoringLocalDatasource? datasource;

  /// Optional sync service for pushing deliveries to the server.
  final SyncService? syncService;

  /// Optional WebSocket client for fast-path score broadcasting.
  final WebSocketClient? wsClient;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  ScoringNotifier? _notifier;
  ScoringPersistenceService? _service;
  bool _isReady = false;
  SyncStatus? _syncStatus;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _initScoring();
  }

  @override
  void dispose() {
    // Leave match room but don't disconnect — client is shared
    final wsClient = widget.wsClient;
    if (wsClient != null && wsClient.activeMatchId != null) {
      wsClient.leaveMatch(widget.args.matchId);
    }
    _service?.dispose();
    super.dispose();
  }

  Future<void> _initScoring() async {
    final args = widget.args;
    final datasource = widget.datasource;
    final syncService = widget.syncService;
    final wsClient = widget.wsClient;

    if (datasource != null) {
      // Try to resume from saved state first
      final resumed = await ScoringPersistenceService.resume(
        matchId: args.matchId,
        datasource: datasource,
        syncService: syncService,
        wsClient: wsClient,
      );

      if (resumed != null) {
        _service = resumed;
        _notifier = resumed.notifier;
      } else {
        // Create new session with persistence
        final notifier = _createNotifier(args);
        _service = await ScoringPersistenceService.createNew(
          notifier: notifier,
          datasource: datasource,
          syncService: syncService,
          wsClient: wsClient,
        );
        _notifier = notifier;
      }
    } else {
      // No persistence — direct notifier (backwards compatible)
      _notifier = _createNotifier(args);
    }

    // Listen to sync status changes
    final syncSvc = _service?.syncService;
    if (syncSvc != null) {
      _syncStatus = syncSvc.status;
      _pendingCount = syncSvc.unsyncedCount;
      syncSvc.onSyncStatusChanged = () {
        if (mounted) {
          setState(() {
            _syncStatus = syncSvc.status;
            _pendingCount = syncSvc.unsyncedCount;
          });
        }
      };
    }

    // Connect WS and join match room for fast-path broadcasting
    if (wsClient != null) {
      if (wsClient.status != ConnectionStatus.connected) {
        await wsClient.connect();
      }
      wsClient.joinMatch(args.matchId);
    }

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  ScoringNotifier _createNotifier(ScoringPageArgs args) {
    final state = ScoringState(
      matchId: args.matchId,
      inningsId: args.inningsId,
      battingTeamId: args.battingTeamId,
      bowlingTeamId: args.bowlingTeamId,
      battingTeamName: args.battingTeamName,
      bowlingTeamName: args.bowlingTeamName,
      inningsNumber: args.inningsNumber,
      totalOvers: args.totalOvers,
      playersPerSide: args.playersPerSide,
      target: args.target,
      wideRunsPenalty: args.wideRunsPenalty,
      noBallRunsPenalty: args.noBallRunsPenalty,
      magicOverNumbers: args.magicOverNumbers,
      magicOverRunMultiplier: args.magicOverRunMultiplier,
      magicOverWicketPenalty: args.magicOverWicketPenalty,
      battingTeamPlayers: args.battingTeamPlayers,
      bowlingTeamPlayers: args.bowlingTeamPlayers,
      firstInningsSummary: args.firstInningsSummary,
      isKnockoutMatch: args.isKnockoutMatch,
    );
    final notifier = ScoringNotifier(state);

    // Set up opening players
    notifier.selectNewBatter(
      playerId: args.openingStrikerId,
      displayName: args.openingStrikerName,
    );
    notifier.selectNewBatter(
      playerId: args.openingNonStrikerId,
      displayName: args.openingNonStrikerName,
    );
    notifier.selectNewBowler(
      playerId: args.openingBowlerId,
      displayName: args.openingBowlerName,
    );
    return notifier;
  }

  ScoringState get _state => _notifier!.state;

  bool get _hasPersistence => _service != null;

  void _onRunTap(int runs) {
    final prevNeedsBowler = _state.needsNewBowler;
    final prevNeedsBatter = _state.needsNewBatter;
    final prevIsInningsComplete = _state.isInningsComplete;

    if (_hasPersistence) {
      _service!.recordDelivery(
        runsFromBat: runs,
        isBoundaryFour: runs == 4,
        isBoundarySix: runs == 6,
      );
    } else {
      _notifier!.recordDelivery(
        runsFromBat: runs,
        isBoundaryFour: runs == 4,
        isBoundarySix: runs == 6,
      );
    }
    setState(() {});

    _checkSideEffects(prevNeedsBatter, prevNeedsBowler, prevIsInningsComplete);
  }

  void _onUndo() {
    if (_hasPersistence) {
      _service!.undoLastDelivery();
    } else {
      _notifier!.undoLastDelivery();
    }
    setState(() {});
  }

  void _onSwapStrike() {
    if (_hasPersistence) {
      _service!.swapStrike();
    } else {
      _notifier!.swapStrike();
    }
    setState(() {});
  }

  void _showExtrasPanel(ExtraType extraType) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ExtrasPanel(
        extraType: extraType,
        wideRunsPenalty: _state.wideRunsPenalty,
        noBallRunsPenalty: _state.noBallRunsPenalty,
        onConfirm: (runs, {bool withWicket = false, NoBallRunType? noBallRunType}) {
          Navigator.of(ctx).pop();
          if (withWicket) {
            _showExtraWicketDialog(extraType, runs, noBallRunType: noBallRunType);
          } else {
            _recordExtra(extraType, runs, noBallRunType: noBallRunType);
          }
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showExtraWicketDialog(ExtraType extraType, int runs, {NoBallRunType? noBallRunType}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WicketDialog(
        bowlingTeamPlayers: _state.bowlingTeamPlayers,
        strikerName: _state.striker?.displayName ?? '',
        strikerId: _state.strikerId ?? '',
        nonStrikerName: _state.nonStriker?.displayName ?? '',
        nonStrikerId: _state.nonStrikerId ?? '',
        isFreeHitPending: false,
        isWide: extraType == ExtraType.wide,
        isNoBall: extraType == ExtraType.noBall,
        onConfirm: (result) {
          Navigator.of(ctx).pop();
          if (extraType == ExtraType.wide) {
            _recordWicket(result, isWide: true, wideRuns: runs);
          } else if (extraType == ExtraType.noBall) {
            _recordNoBallWicket(result);
          }
        },
      ),
    );
  }

  void _recordNoBallWicket(WicketDialogResult result) {
    // NB + wicket (run out): the NB penalty is handled by recordWicket's
    // isNoBall flag. Runs from the result go as runsFromBat.
    _recordWicket(result, isNoBall: true, noBallRuns: 0);
  }

  void _recordExtra(ExtraType type, int runs, {NoBallRunType? noBallRunType}) {
    final prevNeedsBowler = _state.needsNewBowler;
    final prevNeedsBatter = _state.needsNewBatter;
    final prevIsInningsComplete = _state.isInningsComplete;
    if (_hasPersistence) {
      switch (type) {
        case ExtraType.wide:
          _service!.recordWide(additionalRuns: runs);
        case ExtraType.noBall:
          switch (noBallRunType ?? NoBallRunType.batRuns) {
            case NoBallRunType.batRuns:
              _service!.recordNoBall(runsFromBat: runs);
            case NoBallRunType.byes:
              _service!.recordNoBall(byeRuns: runs);
            case NoBallRunType.legByes:
              _service!.recordNoBall(legByeRuns: runs);
          }
        case ExtraType.bye:
          _service!.recordBye(byeRuns: runs);
        case ExtraType.legBye:
          _service!.recordLegBye(legByeRuns: runs);
      }
    } else {
      switch (type) {
        case ExtraType.wide:
          _notifier!.recordWide(additionalRuns: runs);
        case ExtraType.noBall:
          switch (noBallRunType ?? NoBallRunType.batRuns) {
            case NoBallRunType.batRuns:
              _notifier!.recordNoBall(runsFromBat: runs);
            case NoBallRunType.byes:
              _notifier!.recordNoBall(byeRuns: runs);
            case NoBallRunType.legByes:
              _notifier!.recordNoBall(legByeRuns: runs);
          }
        case ExtraType.bye:
          _notifier!.recordBye(byeRuns: runs);
        case ExtraType.legBye:
          _notifier!.recordLegBye(legByeRuns: runs);
      }
    }
    setState(() {});
    _checkSideEffects(prevNeedsBatter, prevNeedsBowler, prevIsInningsComplete);
  }

  void _checkSideEffects(
    bool prevNeedsBatter,
    bool prevNeedsBowler,
    bool prevIsInningsComplete,
  ) {
    // Super over needed — show setup wizard
    if (_state.needsSuperOver) {
      _showSuperOverSetupWizard();
      return;
    }

    // Innings just completed — show transition modal or match complete
    if (!prevIsInningsComplete && _state.isInningsComplete) {
      if (_state.inningsNumber == 1) {
        _showInningsTransitionModal();
      } else if (_state.isMatchComplete) {
        _showMatchCompleteModal();
      }
      return; // Skip batter/bowler sheets when innings is complete
    }

    if (!prevNeedsBowler && _state.needsNewBowler) {
      _showSelectBowlerSheet();
    }
    if (!prevNeedsBatter && _state.needsNewBatter) {
      _showSelectBatterSheet();
    }
  }

  void _showInningsTransitionModal() {
    // Compute top performers
    final allBatters = _state.batterStats.values.toList()
      ..sort((a, b) => b.runsScored.compareTo(a.runsScored));
    final topBatters = allBatters.take(2).toList();

    final allBowlers = _state.bowlerStats.values.toList()
      ..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken));
    final topBowler = allBowlers.isNotEmpty ? allBowlers.first : null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: InningsTransitionModal(
          battingTeamName: _state.battingTeamName,
          chasingTeamName: _state.bowlingTeamName,
          totalRuns: _state.totalRuns,
          totalWickets: _state.totalWickets,
          oversDisplay: _state.oversDisplay,
          totalExtras: _state.totalExtras,
          totalWides: _state.totalWides,
          totalNoBalls: _state.totalNoBalls,
          totalByes: _state.totalByes,
          totalLegByes: _state.totalLegByes,
          runRate: _state.runRate,
          target: _state.totalRuns + 1,
          totalOvers: _state.totalOvers,
          fallOfWickets: _state.fallOfWickets,
          topBatters: topBatters,
          topBowler: topBowler,
          chasingTeamPlayers: _state.bowlingTeamPlayers,
          bowlingTeamPlayers: _state.battingTeamPlayers,
          onConfirm: (result) {
            Navigator.of(ctx).pop();
            _handleInningsTransition(result);
          },
        ),
      ),
    );
  }

  void _handleInningsTransition(InningsTransitionResult result) {
    if (_hasPersistence) {
      _service!.startSecondInnings(
        strikerId: result.strikerId,
        strikerName: result.strikerName,
        nonStrikerId: result.nonStrikerId,
        nonStrikerName: result.nonStrikerName,
        bowlerId: result.bowlerId,
        bowlerName: result.bowlerName,
      );
    } else {
      _notifier!.startSecondInnings(
        strikerId: result.strikerId,
        strikerName: result.strikerName,
        nonStrikerId: result.nonStrikerId,
        nonStrikerName: result.nonStrikerName,
        bowlerId: result.bowlerId,
        bowlerName: result.bowlerName,
      );
    }
    setState(() {});
  }

  void _showMatchCompleteModal() {
    final summary = _state.firstInningsSummary;
    final result = _state.matchResult;
    if (summary == null || result == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: MatchCompleteModal(
          firstInnings: summary,
          secondTeamName: _state.battingTeamName,
          secondTotalRuns: _state.totalRuns,
          secondTotalWickets: _state.totalWickets,
          secondOversDisplay: _state.oversDisplay,
          matchResult: result,
          showSuperOverButton: result.resultType == MatchResultType.tie &&
              _state.isKnockoutMatch,
          onAction: (action) {
            Navigator.of(ctx).pop();
            _handleMatchCompleteAction(action);
          },
        ),
      ),
    );
  }

  void _handleMatchCompleteAction(MatchCompleteAction action) {
    if (_hasPersistence) {
      _service!.onMatchComplete();
    }

    switch (action) {
      case MatchCompleteAction.startSuperOver:
        _showSuperOverSetupWizard();
        return;
      case MatchCompleteAction.viewScorecard:
        final firstInnings = _state.firstInnings;
        final matchResult = _state.matchResult;
        if (firstInnings == null || matchResult == null) return;

        final scorecardData = ScorecardData(
          matchId: _state.matchId,
          totalOvers: _state.totalOvers,
          playersPerSide: _state.playersPerSide,
          firstInnings: firstInnings,
          secondInnings: InningsData.fromScoringState(_state),
          matchResult: matchResult,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ScorecardPage(data: scorecardData),
          ),
        );
      case MatchCompleteAction.backToHome:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) GoRouter.of(context).go('/home');
        });
    }
  }

  void _showSuperOverSetupWizard() {
    // The team that batted second bats first in the super over
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SuperOverSetupWizard(
        battingTeamName: _state.bowlingTeamName,
        bowlingTeamName: _state.battingTeamName,
        battingTeamPlayers: _state.bowlingTeamPlayers,
        bowlingTeamPlayers: _state.battingTeamPlayers,
        superOverNumber: _state.superOverNumber + 1,
        previousSuperOverBowlerIds: _state.previousSuperOverBowlerIds,
        onConfirm: (result) {
          Navigator.of(ctx).pop();
          if (_hasPersistence) {
            _service!.startSuperOver(
              strikerId: result.strikerId,
              strikerName: result.strikerName,
              nonStrikerId: result.nonStrikerId,
              nonStrikerName: result.nonStrikerName,
              bowlerId: result.bowlerId,
              bowlerName: result.bowlerName,
            );
          } else {
            _notifier!.startSuperOver(
              strikerId: result.strikerId,
              strikerName: result.strikerName,
              nonStrikerId: result.nonStrikerId,
              nonStrikerName: result.nonStrikerName,
              bowlerId: result.bowlerId,
              bowlerName: result.bowlerName,
            );
          }
          setState(() {});
        },
      ),
    );
  }

  void _showSelectBatterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: SelectBatterSheet(
          yetToBatPlayers: _state.yetToBatPlayers,
          retiredHurtBatters: _state.retiredHurtBatters,
          onSelect: (playerId) {
            final player = _state.battingTeamPlayers.firstWhere(
              (p) => p.playerId == playerId,
            );
            if (_hasPersistence) {
              _service!.selectNewBatter(
                playerId: playerId,
                displayName: player.displayName,
              );
            } else {
              _notifier!.selectNewBatter(
                playerId: playerId,
                displayName: player.displayName,
              );
            }
            setState(() {});
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _showSelectBowlerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: SelectBowlerSheet(
          bowlerOptions: _state.bowlerOptions,
          overNumber: _state.currentOverNumber,
          onSelect: (playerId) {
            final player = _state.bowlingTeamPlayers.firstWhere(
              (p) => p.playerId == playerId,
            );
            if (_hasPersistence) {
              _service!.selectNewBowler(
                playerId: playerId,
                displayName: player.displayName,
              );
            } else {
              _notifier!.selectNewBowler(
                playerId: playerId,
                displayName: player.displayName,
              );
            }
            setState(() {});
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _showOverthrowPicker() {
    showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overthrow Runs',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 6, 7, 8, 9, 10, 11, 12].map((n) {
                return ActionChip(
                  label: Text('$n'),
                  onPressed: () => Navigator.of(ctx).pop(n),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).then((runs) {
      if (runs != null) {
        if (_hasPersistence) {
          _service!.recordDelivery(runsFromBat: runs);
        } else {
          _notifier!.recordDelivery(runsFromBat: runs);
        }
        setState(() {});
      }
    });
  }

  void _showAbandonDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Match'),
        content: const Text(
          'Are you sure you want to abandon this match? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (_hasPersistence) {
          _service!.abandonMatch();
        } else {
          _notifier!.abandonMatch();
        }
        setState(() {});
        _showMatchCompleteModal();
      }
    });
  }

  void _showDeclareDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Declare Innings'),
        content: Text(
          '${_state.battingTeamName} will declare at ${_state.scoreDisplay} (${_state.oversDisplay} overs).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Declare'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (_hasPersistence) {
          _service!.declareInnings();
        } else {
          _notifier!.declareInnings();
        }
        setState(() {});
        _showInningsTransitionModal();
      }
    });
  }

  void _showExitDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Scoring?'),
        content: Text(
          _hasPersistence
              ? 'Your progress is saved locally. You can resume this match later.'
              : 'Are you sure you want to exit? Unsaved progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ).then((exit) {
      if (exit == true && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showWicketDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WicketDialog(
        bowlingTeamPlayers: _state.bowlingTeamPlayers,
        strikerName: _state.striker?.displayName ?? '',
        strikerId: _state.strikerId ?? '',
        nonStrikerName: _state.nonStriker?.displayName ?? '',
        nonStrikerId: _state.nonStrikerId ?? '',
        isFreeHitPending: _state.isFreeHitPending,
        onConfirm: (result) {
          Navigator.of(ctx).pop();
          _recordWicket(result);
        },
      ),
    );
  }

  void _recordWicket(
    WicketDialogResult result, {
    bool isWide = false,
    int wideRuns = 0,
    bool isNoBall = false,
    int noBallRuns = 0,
  }) {
    final prevNeedsBowler = _state.needsNewBowler;
    final prevNeedsBatter = _state.needsNewBatter;
    final prevIsInningsComplete = _state.isInningsComplete;

    if (_hasPersistence) {
      _service!.recordWicket(
        dismissalType: result.dismissalType,
        dismissedPlayerId: result.dismissedPlayerId,
        fielderId: result.fielderId,
        fielderName: result.fielderName,
        runsFromBat: result.runsFromBat,
        isWide: isWide,
        wideRuns: wideRuns,
        isNoBall: isNoBall,
        noBallRuns: noBallRuns,
        battersCrossed: result.battersCrossed,
        isDirectHit: result.isDirectHit,
      );
    } else {
      _notifier!.recordWicket(
        dismissalType: result.dismissalType,
        dismissedPlayerId: result.dismissedPlayerId,
        fielderId: result.fielderId,
        fielderName: result.fielderName,
        runsFromBat: result.runsFromBat,
        isWide: isWide,
        wideRuns: wideRuns,
        isNoBall: isNoBall,
        noBallRuns: noBallRuns,
        battersCrossed: result.battersCrossed,
        isDirectHit: result.isDirectHit,
      );
    }
    setState(() {});

    _checkSideEffects(prevNeedsBatter, prevNeedsBowler, prevIsInningsComplete);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        body: Column(
          children: [
            // Score header (fixed)
            ScoreHeader(
              battingTeamName: _state.battingTeamName,
              inningsNumber: _state.inningsNumber,
              totalRuns: _state.totalRuns,
              totalWickets: _state.totalWickets,
              oversDisplay: _state.oversDisplay,
              runRate: _state.runRate,
              requiredRunRate: _state.requiredRunRate,
              target: _state.target,
              runsNeeded: _state.runsNeeded,
              onBack: _showExitDialog,
              syncStatus: _syncStatus,
              pendingCount: _pendingCount,
              isMagicOver: _state.isMagicOver,
              magicOverMultiplier: _state.magicOverRunMultiplier,
              isFreeHitPending: _state.isFreeHitPending,
              onAbandon: _showAbandonDialog,
              onDeclare: _showDeclareDialog,
              showDeclare: _state.inningsNumber == 1 && !_state.isInningsComplete,
              isInningsComplete: _state.isInningsComplete,
            ),

            // Scrollable middle: batters + bowler + this over
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batter stat headers
                    _buildStatLabels(context),
                    // Striker card
                    if (_state.striker != null)
                      BatterCard(
                        batter: _state.striker!,
                        isStriker: true,
                      ),
                    // Non-striker card
                    if (_state.nonStriker != null)
                      BatterCard(
                        batter: _state.nonStriker!,
                        isStriker: false,
                      ),
                    const Divider(height: 16),
                    // Bowler stat headers
                    _buildBowlerLabels(context),
                    // Bowler card
                    if (_state.currentBowler != null)
                      BowlerCard(bowler: _state.currentBowler!),
                    const Divider(height: 16),
                    // This over display
                    ThisOverDisplay(
                      deliveries: _state.currentOverDeliveries,
                      isFreeHitPending: _state.isFreeHitPending,
                      overNumber: _state.currentOverNumber,
                      isMagicOver: _state.isMagicOver,
                      magicOverMultiplier: _state.magicOverRunMultiplier,
                    ),
                  ],
                ),
              ),
            ),

            // Scoring controls (fixed)
            ScoringControls(
              onRunTap: _onRunTap,
              onWideTap: () => _showExtrasPanel(ExtraType.wide),
              onNoBallTap: () => _showExtrasPanel(ExtraType.noBall),
              onByeTap: () => _showExtrasPanel(ExtraType.bye),
              onLegByeTap: () => _showExtrasPanel(ExtraType.legBye),
              onWicketTap: _showWicketDialog,
              onUndoTap: _onUndo,
              onSwapStrike: _onSwapStrike,
              onOverthrowTap: _showOverthrowPicker,
              canUndo: _state.canUndo,
              isInningsComplete: _state.isInningsComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLabels(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Batter', style: style)),
          SizedBox(width: 36, child: Text('R', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('B', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('4s', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('6s', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 64, child: Text('SR', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildBowlerLabels(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Bowler', style: style)),
          SizedBox(width: 36, child: Text('O', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('M', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('R', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('W', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 48, child: Text('Ec', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
