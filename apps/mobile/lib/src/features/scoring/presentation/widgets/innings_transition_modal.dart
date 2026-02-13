import 'package:flutter/material.dart';

import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../domain/entities/playing_xi_player.dart';
import '../notifiers/scoring_notifier.dart';

/// Result returned when the innings transition modal is completed.
class InningsTransitionResult {
  const InningsTransitionResult({
    required this.strikerId,
    required this.strikerName,
    required this.nonStrikerId,
    required this.nonStrikerName,
    required this.bowlerId,
    required this.bowlerName,
  });

  final String strikerId;
  final String strikerName;
  final String nonStrikerId;
  final String nonStrikerName;
  final String bowlerId;
  final String bowlerName;
}

/// 3-step innings transition modal.
///
/// Step 1: Innings summary (score, extras, FOW, top performers, target).
/// Step 2: Select 2 opening batters + designate striker.
/// Step 3: Select opening bowler.
class InningsTransitionModal extends StatefulWidget {
  const InningsTransitionModal({
    super.key,
    required this.battingTeamName,
    required this.chasingTeamName,
    required this.totalRuns,
    required this.totalWickets,
    required this.oversDisplay,
    required this.totalExtras,
    required this.totalWides,
    required this.totalNoBalls,
    required this.totalByes,
    required this.totalLegByes,
    required this.runRate,
    required this.target,
    required this.totalOvers,
    required this.fallOfWickets,
    required this.topBatters,
    required this.topBowler,
    required this.chasingTeamPlayers,
    required this.bowlingTeamPlayers,
    required this.onConfirm,
  });

  final String battingTeamName;
  final String chasingTeamName;
  final int totalRuns;
  final int totalWickets;
  final String oversDisplay;
  final int totalExtras;
  final int totalWides;
  final int totalNoBalls;
  final int totalByes;
  final int totalLegByes;
  final double runRate;
  final int target;
  final int totalOvers;
  final List<FallOfWicket> fallOfWickets;
  final List<BatterInnings> topBatters;
  final BowlerSpell? topBowler;
  final List<PlayingXIPlayer> chasingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final ValueChanged<InningsTransitionResult> onConfirm;

  @override
  State<InningsTransitionModal> createState() =>
      _InningsTransitionModalState();
}

class _InningsTransitionModalState extends State<InningsTransitionModal> {
  int _step = 1;

  // Step 2 state
  final List<String> _selectedBatterIds = [];
  String? _strikerId;

  // Step 3 state
  String? _selectedBowlerId;

  String get _primaryButtonLabel =>
      _step == 3 ? 'Start Innings' : 'Next';

  bool get _isPrimaryEnabled {
    switch (_step) {
      case 1:
        return true;
      case 2:
        return _selectedBatterIds.length == 2;
      case 3:
        return _selectedBowlerId != null;
      default:
        return false;
    }
  }

  void _onPrimaryTap() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      // Build result
      final strikerId = _strikerId ?? _selectedBatterIds[0];
      final nonStrikerId = _selectedBatterIds.firstWhere(
        (id) => id != strikerId,
      );
      final striker = widget.chasingTeamPlayers.firstWhere(
        (p) => p.playerId == strikerId,
      );
      final nonStriker = widget.chasingTeamPlayers.firstWhere(
        (p) => p.playerId == nonStrikerId,
      );
      final bowler = widget.bowlingTeamPlayers.firstWhere(
        (p) => p.playerId == _selectedBowlerId,
      );

      widget.onConfirm(InningsTransitionResult(
        strikerId: strikerId,
        strikerName: striker.displayName,
        nonStrikerId: nonStrikerId,
        nonStrikerName: nonStriker.displayName,
        bowlerId: _selectedBowlerId!,
        bowlerName: bowler.displayName,
      ));
    }
  }

  void _onBackTap() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

  void _toggleBatter(String playerId) {
    setState(() {
      if (_selectedBatterIds.contains(playerId)) {
        _selectedBatterIds.remove(playerId);
        // Reset striker if deselected
        if (_strikerId == playerId) _strikerId = null;
      } else {
        if (_selectedBatterIds.length >= 2) {
          // Deselect first
          final removed = _selectedBatterIds.removeAt(0);
          if (_strikerId == removed) _strikerId = null;
        }
        _selectedBatterIds.add(playerId);
      }
      // Auto-designate first as striker when 2 selected
      if (_selectedBatterIds.length == 2 && _strikerId == null) {
        _strikerId = _selectedBatterIds[0];
      }
    });
  }

  void _selectBowler(String playerId) {
    setState(() => _selectedBowlerId = playerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 620),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Innings Transition',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStepper(theme),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: switch (_step) {
                  1 => _buildSummary(theme),
                  2 => _buildOpeners(theme),
                  3 => _buildBowlerSelection(theme),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _step > 1 ? _onBackTap : null,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isPrimaryEnabled ? _onPrimaryTap : null,
                      child: Text(_primaryButtonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(ThemeData theme) {
    const labels = ['Summary', 'Openers', 'Bowler'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Container(
              width: 32,
              height: 2,
              color: i <= _step - 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i + 1 <= _step
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i + 1 <= _step
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Step 1: Summary ──

  Widget _buildSummary(ThemeData theme) {
    final rrr = widget.target / widget.totalOvers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score
        Center(
          child: Text(
            '${widget.totalRuns}/${widget.totalWickets}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            '${widget.battingTeamName} \u2022 ${widget.oversDisplay} overs',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Divider(height: 24),

        // Extras
        _statRow(theme, 'Extras',
            '${widget.totalExtras} (Wd ${widget.totalWides}, NB ${widget.totalNoBalls}, B ${widget.totalByes}, LB ${widget.totalLegByes})'),
        _statRow(theme, 'Run Rate', widget.runRate.toStringAsFixed(2)),
        const Divider(height: 24),

        // Fall of wickets
        Text(
          'Fall of Wickets',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: widget.fallOfWickets.map((fow) {
            return Text(
              '${fow.wicketNumber}-${fow.scoreAtFall} (${fow.dismissedPlayerName}, ${fow.oversAtFall})',
              style: theme.textTheme.bodySmall,
            );
          }).toList(),
        ),
        const Divider(height: 24),

        // Top performers
        Text(
          'Top Performers',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (final batter in widget.topBatters)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${batter.displayName} — ${batter.runsScored}${batter.isNotOut ? '*' : ''}(${batter.ballsFaced})',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (widget.topBowler != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${widget.topBowler!.displayName} — ${widget.topBowler!.figures}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        const Divider(height: 24),

        // Target
        Center(
          child: Text(
            'Target for ${widget.chasingTeamName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Center(
          child: Text(
            '${widget.target}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Center(
          child: Text(
            'in ${widget.totalOvers} overs (RRR: ${rrr.toStringAsFixed(2)})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Opening Batters ──

  Widget _buildOpeners(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Opening Batters',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose 2 players from ${widget.chasingTeamName}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final player in widget.chasingTeamPlayers)
          _PlayerCheckRow(
            player: player,
            isSelected: _selectedBatterIds.contains(player.playerId),
            onTap: () => _toggleBatter(player.playerId),
          ),
        // Striker designation
        if (_selectedBatterIds.length == 2) ...[
          const Divider(height: 24),
          Text(
            'Who will face the first ball?',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _selectedBatterIds.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _StrikerRadioRow(
                    name: widget.chasingTeamPlayers
                        .firstWhere(
                            (p) => p.playerId == _selectedBatterIds[i])
                        .displayName,
                    isSelected: _strikerId == _selectedBatterIds[i],
                    onTap: () => setState(
                        () => _strikerId = _selectedBatterIds[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ── Step 3: Opening Bowler ──

  Widget _buildBowlerSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Opening Bowler',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose 1 bowler from ${widget.battingTeamName}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final player in widget.bowlingTeamPlayers)
          _PlayerRadioRow(
            player: player,
            isSelected: _selectedBowlerId == player.playerId,
            onTap: () => _selectBowler(player.playerId),
          ),
      ],
    );
  }
}

// ── Private Widgets ──

class _PlayerCheckRow extends StatelessWidget {
  const _PlayerCheckRow({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final PlayingXIPlayer player;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14,
                        color: theme.colorScheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    theme.colorScheme.secondaryContainer,
                child: Text(
                  player.initials,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.roleLabel != null || player.battingStyleShort != null)
                      Text(
                        [
                          if (player.roleLabel != null) player.roleLabel,
                          if (player.battingStyleShort != null)
                            player.battingStyleShort,
                        ].join(' \u2022 '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (player.badge != null)
                Text(
                  player.badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrikerRadioRow extends StatelessWidget {
  const _StrikerRadioRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRadioRow extends StatelessWidget {
  const _PlayerRadioRow({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final PlayingXIPlayer player;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    theme.colorScheme.secondaryContainer,
                child: Text(
                  player.initials,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.bowlingStyle != null)
                      Text(
                        player.bowlingStyle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (player.badge != null)
                Text(
                  player.badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
