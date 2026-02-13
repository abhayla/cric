import 'package:flutter/material.dart';

import '../../domain/entities/playing_xi_player.dart';
import '../notifiers/scoring_notifier.dart';
import '../widgets/batter_card.dart';
import '../widgets/bowler_card.dart';
import '../widgets/extras_panel.dart';
import '../widgets/score_header.dart';
import '../widgets/scoring_controls.dart';
import '../widgets/select_batter_sheet.dart';
import '../widgets/select_bowler_sheet.dart';
import '../widgets/this_over_display.dart';

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
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
    required this.openingStrikerId,
    required this.openingStrikerName,
    required this.openingNonStrikerId,
    required this.openingNonStrikerName,
    required this.openingBowlerId,
    required this.openingBowlerName,
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
  final List<PlayingXIPlayer> battingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final String openingStrikerId;
  final String openingStrikerName;
  final String openingNonStrikerId;
  final String openingNonStrikerName;
  final String openingBowlerId;
  final String openingBowlerName;
}

/// Main scoring page where the scorer records deliveries ball-by-ball.
class ScoringPage extends StatefulWidget {
  const ScoringPage({super.key, required this.args});

  final ScoringPageArgs args;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  late ScoringNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
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
      battingTeamPlayers: args.battingTeamPlayers,
      bowlingTeamPlayers: args.bowlingTeamPlayers,
    );
    _notifier = ScoringNotifier(state);

    // Set up opening players
    _notifier.selectNewBatter(
      playerId: args.openingStrikerId,
      displayName: args.openingStrikerName,
    );
    _notifier.selectNewBatter(
      playerId: args.openingNonStrikerId,
      displayName: args.openingNonStrikerName,
    );
    _notifier.selectNewBowler(
      playerId: args.openingBowlerId,
      displayName: args.openingBowlerName,
    );
  }

  ScoringState get _state => _notifier.state;

  void _onRunTap(int runs) {
    final prevNeedsBowler = _state.needsNewBowler;
    final prevNeedsBatter = _state.needsNewBatter;

    _notifier.recordDelivery(
      runsFromBat: runs,
      isBoundaryFour: runs == 4,
      isBoundarySix: runs == 6,
    );
    setState(() {});

    _checkSideEffects(prevNeedsBatter, prevNeedsBowler);
  }

  void _onUndo() {
    _notifier.undoLastDelivery();
    setState(() {});
  }

  void _onSwapStrike() {
    _notifier.swapStrike();
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
        onConfirm: (runs) {
          Navigator.of(ctx).pop();
          _recordExtra(extraType, runs);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _recordExtra(ExtraType type, int runs) {
    final prevNeedsBowler = _state.needsNewBowler;
    final prevNeedsBatter = _state.needsNewBatter;
    switch (type) {
      case ExtraType.wide:
        _notifier.recordWide(additionalRuns: runs);
      case ExtraType.noBall:
        _notifier.recordNoBall(runsFromBat: runs);
      case ExtraType.bye:
        _notifier.recordBye(byeRuns: runs);
      case ExtraType.legBye:
        _notifier.recordLegBye(legByeRuns: runs);
    }
    setState(() {});
    _checkSideEffects(prevNeedsBatter, prevNeedsBowler);
  }

  void _checkSideEffects(bool prevNeedsBatter, bool prevNeedsBowler) {
    if (!prevNeedsBowler && _state.needsNewBowler) {
      _showSelectBowlerSheet();
    }
    if (!prevNeedsBatter && _state.needsNewBatter) {
      _showSelectBatterSheet();
    }
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
            _notifier.selectNewBatter(
              playerId: playerId,
              displayName: player.displayName,
            );
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
            _notifier.selectNewBowler(
              playerId: playerId,
              displayName: player.displayName,
            );
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
        _notifier.recordDelivery(runsFromBat: runs);
        setState(() {});
      }
    });
  }

  void _showExitDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Scoring?'),
        content: const Text(
          'Are you sure you want to exit? Unsaved progress will be lost.',
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

  void _showStubSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onWicketTap: () => _showStubSnackBar(
                  'Wicket dialog \u2014 coming in Issue #30'),
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
