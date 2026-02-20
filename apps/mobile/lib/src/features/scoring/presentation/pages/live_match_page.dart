import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/websocket/websocket_client.dart';
import '../../../../shared/data/websocket/ws_message_model.dart';
import '../notifiers/match_live_notifier.dart';
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
  // Saved during initState so dispose() doesn't need ref.read() (which throws
  // when the widget is already unmounted).
  MatchLiveNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    // Join the match room after first build.
    Future.microtask(() {
      _notifier = ref.read(matchLiveNotifierProvider.notifier);
      _notifier!.joinMatch(widget.matchId);
    });
  }

  @override
  void dispose() {
    // Leave the WS match room on dispose.
    // Fire-and-forget — don't await or reset state since the widget tree
    // is being torn down and state changes would cause framework errors.
    final notifier = _notifier;
    if (notifier != null) {
      Future.microtask(() => notifier.leaveMatch());
    }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            battingTeamName: state.battingTeamName,
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
            isFreeHitPending: state.isFreeHitPending,
            isMagicOver: state.isMagicOver,
            magicOverMultiplier: state.magicOverMultiplier,
            onBack: () {
              ref.read(matchLiveNotifierProvider.notifier).leaveMatch();
              Navigator.of(context).maybePop();
            },
          ),
          // Scrollable middle content.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Last delivery description banner.
                  if (state.lastDeliveryDescription != null)
                    _buildLastDeliveryBanner(
                        state.lastDeliveryDescription!, theme),
                  // Wicket notification banner.
                  if (state.wicketNotification != null)
                    _buildWicketNotification(state.wicketNotification!, theme),
                  // Batters section with stat headers.
                  if (state.striker != null || state.nonStriker != null) ...[
                    _buildBatterStatHeaders(theme),
                    _buildBattersSection(state, theme),
                  ],
                  // Divider between batters and bowler.
                  if ((state.striker != null || state.nonStriker != null) &&
                      state.bowler != null)
                    const Divider(height: 16),
                  // Bowler section with stat headers.
                  if (state.bowler != null) ...[
                    _buildBowlerStatHeaders(theme),
                    _buildBowlerSection(state, theme),
                  ],
                  // Divider between bowler and over display.
                  if (state.bowler != null && state.currentOver.isNotEmpty)
                    const Divider(height: 16),
                  // Current over display.
                  if (state.currentOver.isNotEmpty)
                    _buildCurrentOver(state, theme),
                  // Match result.
                  if (state.matchResult != null)
                    _buildMatchResult(state.matchResult!, theme),
                  // Innings complete.
                  if (state.inningsCompleteInfo != null &&
                      state.matchResult == null)
                    _buildInningsComplete(state.inningsCompleteInfo!, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastDeliveryBanner(String description, ThemeData theme) {
    Color bgColor;
    if (description.contains('FOUR')) {
      bgColor = AppColors.four;
    } else if (description.contains('SIX')) {
      bgColor = AppColors.six;
    } else if (description.contains('WICKET')) {
      bgColor = AppColors.wicket;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHighest;
    }

    final isHighlight = description.contains('FOUR') ||
        description.contains('SIX') ||
        description.contains('WICKET');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: Text(
        description,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isHighlight ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWicketNotification(WsWicketData wicket, ThemeData theme) {
    return Dismissible(
      key: ValueKey('wicket_${wicket.dismissedPlayer}_${wicket.overs}'),
      onDismissed: (_) {
        ref.read(matchLiveNotifierProvider.notifier).dismissWicketNotification();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.wicket,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${wicket.dismissedPlayer} ${wicket.description}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ref
                    .read(matchLiveNotifierProvider.notifier)
                    .dismissWicketNotification();
              },
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterStatHeaders(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Batter', style: style)),
          SizedBox(
              width: 36,
              child: Text('R', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 36,
              child: Text('B', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 28,
              child: Text('4s', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 28,
              child: Text('6s', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 64,
              child: Text('SR', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildBattersSection(LiveMatchState state, ThemeData theme) {
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

  Widget _buildBowlerStatHeaders(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Bowler', style: style)),
          SizedBox(
              width: 36,
              child: Text('O', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 28,
              child: Text('M', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 36,
              child: Text('R', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 28,
              child: Text('W', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 48,
              child: Text('Ec', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildBowlerSection(LiveMatchState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: BowlerCard(bowler: state.bowler!.toBowlerSpell()),
    );
  }

  Widget _buildCurrentOver(LiveMatchState state, ThemeData theme) {
    // Derive over number from oversDisplay: "1.3" → over 2 (0-indexed overNumber = 1)
    final oversParts = state.oversDisplay.split('.');
    final completedOvers = int.tryParse(oversParts[0]) ?? 0;
    final ballsInOver =
        oversParts.length > 1 ? int.tryParse(oversParts[1]) ?? 0 : 0;
    final displayOverNumber =
        ballsInOver > 0 ? completedOvers + 1 : completedOvers;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Over $displayOverNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (state.isMagicOver) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MAGIC ${state.magicOverMultiplier}x',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (state.isFreeHitPending) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FREE HIT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: state.currentOver.map((ball) {
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
