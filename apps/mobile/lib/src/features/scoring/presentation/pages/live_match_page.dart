import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/websocket/websocket_client.dart';
import '../../../../shared/data/websocket/ws_message_model.dart';
import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../providers.dart';
import '../widgets/batter_card.dart';
import '../widgets/bowler_card.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/score_header.dart';

/// Live match page for viewers watching via WebSocket.
class LiveMatchPage extends ConsumerStatefulWidget {
  const LiveMatchPage({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveMatchPage> createState() => _LiveMatchPageState();
}

class _LiveMatchPageState extends ConsumerState<LiveMatchPage> {
  @override
  void initState() {
    super.initState();
    // Join the match room after first build.
    Future.microtask(() {
      ref.read(matchLiveNotifierProvider.notifier).joinMatch(widget.matchId);
    });
  }

  @override
  void dispose() {
    // Leave match when navigating away.
    // Use read since dispose happens after the widget is removed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchLiveNotifierProvider);
    final theme = Theme.of(context);

    // Show loading if no match state received yet.
    if (state.status == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Match')),
        body: Column(
          children: [
            ConnectionStatusBanner(
              status: state.connectionStatus,
              onRetry: state.connectionStatus == ConnectionStatus.disconnected
                  ? () => ref
                      .read(matchLiveNotifierProvider.notifier)
                      .joinMatch(widget.matchId)
                  : null,
            ),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(matchLiveNotifierProvider.notifier).leaveMatch();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Column(
        children: [
          ConnectionStatusBanner(
            status: state.connectionStatus,
            onRetry: state.connectionStatus == ConnectionStatus.disconnected
                ? () => ref
                    .read(matchLiveNotifierProvider.notifier)
                    .joinMatch(widget.matchId)
                : null,
          ),
          ScoreHeader(
            battingTeamName: '',
            inningsNumber: state.inningsNumber,
            totalRuns: state.totalRuns,
            totalWickets: state.totalWickets,
            oversDisplay: state.oversDisplay,
            runRate: state.currentRunRate ?? 0.0,
            requiredRunRate: state.requiredRunRate,
            target: state.target,
            runsNeeded: state.target != null
                ? state.target! - state.totalRuns
                : null,
            onBack: () {
              ref.read(matchLiveNotifierProvider.notifier).leaveMatch();
              Navigator.of(context).maybePop();
            },
          ),
          // Batters section.
          if (state.striker != null || state.nonStriker != null)
            _buildBattersSection(state, theme),
          // Bowler section.
          if (state.bowler != null) _buildBowlerSection(state, theme),
          // Current over display.
          if (state.currentOver.isNotEmpty)
            _buildCurrentOver(state.currentOver, theme),
          // Match result.
          if (state.matchResult != null)
            _buildMatchResult(state.matchResult!, theme),
          // Innings complete.
          if (state.inningsCompleteInfo != null && state.matchResult == null)
            _buildInningsComplete(state.inningsCompleteInfo!, theme),
        ],
      ),
    );
  }

  Widget _buildBattersSection(dynamic state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          if (state.striker != null)
            BatterCard(
              batter: state.striker!.toBatterInnings(),
              isStriker: true,
            ),
          if (state.nonStriker != null)
            BatterCard(
              batter: state.nonStriker!.toBatterInnings(),
              isStriker: false,
            ),
        ],
      ),
    );
  }

  Widget _buildBowlerSection(dynamic state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: BowlerCard(bowler: state.bowler!.toBowlerSpell()),
    );
  }

  Widget _buildCurrentOver(
      List<WsOverBallDisplay> balls, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Over',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: balls.map((ball) {
              Color bgColor;
              Color textColor;
              if (ball.isWicket) {
                bgColor = AppColors.wicket;
                textColor = Colors.white;
              } else if (ball.display == '4') {
                bgColor = AppColors.four;
                textColor = Colors.white;
              } else if (ball.display == '6') {
                bgColor = AppColors.six;
                textColor = Colors.white;
              } else if (ball.display == '.') {
                bgColor = AppColors.dot;
                textColor = Colors.white;
              } else if (ball.display.contains('Wd')) {
                bgColor = AppColors.wide;
                textColor = Colors.white;
              } else if (ball.display.contains('Nb')) {
                bgColor = AppColors.noBall;
                textColor = Colors.white;
              } else {
                bgColor = theme.colorScheme.surfaceContainerHighest;
                textColor = theme.colorScheme.onSurface;
              }

              return CircleAvatar(
                radius: 16,
                backgroundColor: bgColor,
                child: Text(
                  ball.display,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchResult(WsMatchCompleteData result, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        result.summary,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInningsComplete(
      WsInningsCompleteData info, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Innings Complete',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${info.battingTeam}: ${info.totalRuns}/${info.totalWickets} (${info.overs})',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${info.target}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
