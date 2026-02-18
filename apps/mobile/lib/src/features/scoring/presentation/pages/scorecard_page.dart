import 'package:flutter/material.dart';

import '../../../../core/utils/analytics_utils.dart';
import '../../../../core/utils/commentary_generator.dart';
import '../../../../core/utils/mvp_utils.dart';
import '../../../analytics/domain/entities/chart_data.dart';
import '../../../analytics/domain/entities/mvp_data.dart';
import '../../../analytics/presentation/widgets/manhattan_chart.dart';
import '../../../analytics/presentation/widgets/mvp_ranking_widget.dart';
import '../../../analytics/presentation/widgets/run_rate_chart.dart';
import '../../../analytics/presentation/widgets/worm_chart.dart';
import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/innings_data.dart';
import '../../domain/entities/scorecard_data.dart';

/// Scorecard page showing match results with 3 tabs:
/// Scorecard, Commentary, Analytics.
class ScorecardPage extends StatefulWidget {
  const ScorecardPage({super.key, required this.data});

  final ScorecardData data;

  @override
  State<ScorecardPage> createState() => _ScorecardPageState();
}

class _ScorecardPageState extends State<ScorecardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedInningsIndex = 0;

  ScorecardData get _data => widget.data;
  InningsData get _selectedInnings =>
      _selectedInningsIndex == 0 ? _data.firstInnings : _data.secondInnings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Match Details'),
      ),
      body: Column(
        children: [
          _buildScoreComparisonHeader(context),
          _buildResultBanner(context),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Analytics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScorecardTab(context),
                _buildCommentaryTab(context),
                _buildAnalyticsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComparisonHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: colorScheme.primary,
      child: Row(
        children: [
          Expanded(
            child: _buildTeamBlock(
              context,
              teamName: _data.firstInnings.teamName,
              score: _data.firstInnings.scoreDisplay,
              overs: _data.firstInnings.oversDisplay,
              avatarBackground: const Color(0xFFE3F2FD),
              avatarForeground: const Color(0xFF1565C0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'VS',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _buildTeamBlock(
              context,
              teamName: _data.secondInnings.teamName,
              score: _data.secondInnings.scoreDisplay,
              overs: _data.secondInnings.oversDisplay,
              avatarBackground: const Color(0xFFFCE4EC),
              avatarForeground: const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBlock(
    BuildContext context, {
    required String teamName,
    required String score,
    required String overs,
    required Color avatarBackground,
    required Color avatarForeground,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: avatarBackground,
          child: Text(
            _initials(teamName),
            style: TextStyle(
              color: avatarForeground,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '($overs ov)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: colorScheme.primaryContainer,
      child: Text(
        _data.matchResult.resultDescription,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildScorecardTab(BuildContext context) {
    final innings = _selectedInnings;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Innings toggle chips
          Row(
            children: [
              Expanded(
                child: _buildInningsChip(
                  context,
                  label: '${_data.firstInnings.teamName} — 1st Inn',
                  isSelected: _selectedInningsIndex == 0,
                  onTap: () => setState(() => _selectedInningsIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInningsChip(
                  context,
                  label: '${_data.secondInnings.teamName} — 2nd Inn',
                  isSelected: _selectedInningsIndex == 1,
                  onTap: () => setState(() => _selectedInningsIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Batting section
          Text(
            'Batting',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBattingTable(context, innings),
          const SizedBox(height: 8),

          // Extras
          _buildExtrasRow(context, innings),
          const SizedBox(height: 4),

          // Total
          _buildTotalRow(context, innings),
          const SizedBox(height: 12),

          // Yet to Bat
          if (innings.yetToBatPlayers.isNotEmpty)
            _buildYetToBat(context, innings),

          // Fall of Wickets
          if (innings.fallOfWickets.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFallOfWickets(context, innings),
          ],

          const Divider(height: 32),

          // Bowling section
          Text(
            'Bowling',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBowlingTable(context, innings),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInningsChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
        backgroundColor:
            isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildBattingTable(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    final batters = innings.battingOrder;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(32),
        2: FixedColumnWidth(32),
        3: FixedColumnWidth(28),
        4: FixedColumnWidth(28),
        5: FixedColumnWidth(44),
      },
      children: [
        // Header row
        TableRow(
          children: [
            _headerCell('Batter', theme),
            _headerCell('R', theme, align: TextAlign.center),
            _headerCell('B', theme, align: TextAlign.center),
            _headerCell('4s', theme, align: TextAlign.center),
            _headerCell('6s', theme, align: TextAlign.center),
            _headerCell('SR', theme, align: TextAlign.center),
          ],
        ),
        // Data rows
        for (final batter in batters) _buildBatterRow(theme, batter),
      ],
    );
  }

  TableRow _buildBatterRow(ThemeData theme, BatterInnings batter) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batter.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                batter.dismissalDescription,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        _dataCell('${batter.runsScored}', theme, align: TextAlign.center),
        _dataCell('${batter.ballsFaced}', theme, align: TextAlign.center),
        _dataCell('${batter.fours}', theme, align: TextAlign.center),
        _dataCell('${batter.sixes}', theme, align: TextAlign.center),
        _dataCell(
          batter.ballsFaced > 0
              ? batter.strikeRate.toStringAsFixed(1)
              : '0.0',
          theme,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExtrasRow(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Extras', style: theme.textTheme.bodySmall),
        Text(
          innings.extrasDisplay,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total (${innings.totalWickets} wkts, ${innings.oversDisplay} ov)',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${innings.totalRuns}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildYetToBat(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    final names = innings.yetToBatPlayers.map((p) => p.displayName).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yet to Bat',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 2),
        Text(names, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildFallOfWickets(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fall of Wickets',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: innings.fallOfWickets.map((fow) {
            return Chip(
              label: Text(
                '${fow.wicketNumber}-${fow.scoreAtFall} (${fow.dismissedPlayerName}, ${fow.oversAtFall})',
                style: theme.textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBowlingTable(BuildContext context, InningsData innings) {
    final theme = Theme.of(context);
    final bowlers = innings.bowlingOrder;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(36),
        2: FixedColumnWidth(24),
        3: FixedColumnWidth(32),
        4: FixedColumnWidth(28),
        5: FixedColumnWidth(44),
      },
      children: [
        // Header row
        TableRow(
          children: [
            _headerCell('Bowler', theme),
            _headerCell('O', theme, align: TextAlign.center),
            _headerCell('M', theme, align: TextAlign.center),
            _headerCell('R', theme, align: TextAlign.center),
            _headerCell('W', theme, align: TextAlign.center),
            _headerCell('Ec', theme, align: TextAlign.center),
          ],
        ),
        for (final bowler in bowlers) _buildBowlerRow(theme, bowler),
      ],
    );
  }

  TableRow _buildBowlerRow(ThemeData theme, BowlerSpell bowler) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            bowler.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _dataCell(bowler.oversDisplay, theme, align: TextAlign.center),
        _dataCell('${bowler.maidens}', theme, align: TextAlign.center),
        _dataCell('${bowler.runsConceded}', theme, align: TextAlign.center),
        _dataCell('${bowler.wicketsTaken}', theme, align: TextAlign.center),
        _dataCell(
          bowler.ballsBowled > 0
              ? bowler.economyRate.toStringAsFixed(2)
              : '0.00',
          theme,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCommentaryTab(BuildContext context) {
    final theme = Theme.of(context);
    final innings = _selectedInnings;
    final deliveries = innings.deliveryHistory.reversed.toList();

    if (deliveries.isEmpty) {
      return const Center(child: Text('No commentary available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        final strikerName =
            innings.batterStats[delivery.strikerId]?.displayName;
        final bowlerName =
            innings.bowlerStats[delivery.bowlerId]?.displayName;
        final text = generateCommentary(
          delivery,
          strikerName: strikerName,
          bowlerName: bowlerName,
          magicOverMultiplier: _data.magicOverRunMultiplier > 1
              ? _data.magicOverRunMultiplier
              : null,
        );
        final isMagic = delivery.isMagicOverDelivery;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: isMagic
              ? BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${delivery.overNumber}.${delivery.ballNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMagic ? Colors.amber.shade800 : theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isMagic ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    final chartData = computeMatchChartData(_data);
    final mvpData = computeMvp(_data);

    return _AnalyticsTabContent(
      chartData: chartData,
      mvpData: mvpData,
    );
  }

  // Table cell helpers
  Widget _headerCell(String text, ThemeData theme, {TextAlign? align}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: align,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _dataCell(String text, ThemeData theme, {TextAlign? align}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }
}

/// Analytics tab with 4 nested sub-tabs: Manhattan, Worm, Run Rate, MVP.
class _AnalyticsTabContent extends StatefulWidget {
  const _AnalyticsTabContent({
    required this.chartData,
    required this.mvpData,
  });

  final MatchChartData chartData;
  final MatchMvpData mvpData;

  @override
  State<_AnalyticsTabContent> createState() => _AnalyticsTabContentState();
}

class _AnalyticsTabContentState extends State<_AnalyticsTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _analyticsTabController;
  int _manhattanInningsIndex = 0;

  @override
  void initState() {
    super.initState();
    _analyticsTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _analyticsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        TabBar(
          controller: _analyticsTabController,
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelSmall,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Manhattan'),
            Tab(text: 'Worm'),
            Tab(text: 'Run Rate'),
            Tab(text: 'MVP'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _analyticsTabController,
            children: [
              _buildManhattanTab(),
              WormChart(data: widget.chartData),
              RunRateChart(data: widget.chartData),
              MvpRankingWidget(data: widget.mvpData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManhattanTab() {
    final data = _manhattanInningsIndex == 0
        ? widget.chartData.firstInnings
        : widget.chartData.secondInnings;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildInningsToggle(
                label: '1st Innings',
                isSelected: _manhattanInningsIndex == 0,
                onTap: () => setState(() => _manhattanInningsIndex = 0),
              ),
              const SizedBox(width: 8),
              _buildInningsToggle(
                label: '2nd Innings',
                isSelected: _manhattanInningsIndex == 1,
                onTap: () => setState(() => _manhattanInningsIndex = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: ManhattanChart(data: data),
        ),
      ],
    );
  }

  Widget _buildInningsToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
