import 'package:flutter/material.dart';

import '../../domain/entities/delivery.dart';
import '../../domain/entities/playing_xi_player.dart';

/// Result returned by WicketDialog after user completes the wizard.
class WicketDialogResult {
  const WicketDialogResult({
    required this.dismissalType,
    required this.dismissedPlayerId,
    this.fielderId,
    this.fielderName,
    this.runsFromBat = 0,
    this.battersCrossed = false,
  });

  final DismissalType dismissalType;
  final String dismissedPlayerId;
  final String? fielderId;
  final String? fielderName;
  final int runsFromBat;
  final bool battersCrossed;
}

/// Multi-step wicket dialog for recording dismissal information.
///
/// 3-Step wizard:
/// 1. Dismissal type grid (always shown)
/// 2. Fielder selection (caught, stumped, run out)
/// 3. Run out details (run out only)
class WicketDialog extends StatefulWidget {
  const WicketDialog({
    super.key,
    required this.bowlingTeamPlayers,
    required this.strikerName,
    required this.strikerId,
    required this.nonStrikerName,
    required this.nonStrikerId,
    required this.isFreeHitPending,
    required this.onConfirm,
  });

  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final String strikerName;
  final String strikerId;
  final String nonStrikerName;
  final String nonStrikerId;
  final bool isFreeHitPending;
  final ValueChanged<WicketDialogResult> onConfirm;

  @override
  State<WicketDialog> createState() => _WicketDialogState();
}

class _WicketDialogState extends State<WicketDialog> {
  int _step = 1;
  DismissalType? _selectedType;
  String? _selectedFielderId;
  String? _selectedFielderName;
  String? _dismissedPlayerId;
  bool _battersCrossed = false;
  int _runsBeforeRunOut = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dismissedPlayerId = widget.strikerId;
  }

  /// Maximum step for the selected dismissal type.
  int get _maxStep {
    if (_selectedType == null) return 1;
    if (_selectedType == DismissalType.runOut) return 3;
    if (_selectedType!.requiresFielder) return 2;
    return 1;
  }

  /// Whether the selected type is a terminal step 1 type (no fielder needed).
  bool get _isStep1Terminal => _maxStep == 1;

  /// Button label for the primary action.
  String get _primaryButtonLabel {
    if (_selectedType == null) return 'Next';
    if (_step < _maxStep) return 'Next';
    return 'Confirm Wicket';
  }

  /// Whether the primary button should be enabled.
  bool get _isPrimaryEnabled {
    switch (_step) {
      case 1:
        return _selectedType != null;
      case 2:
        return _selectedFielderId != null;
      case 3:
        return true; // Always valid on step 3 (defaults are set)
      default:
        return false;
    }
  }

  /// Grid label for a dismissal type.
  String _gridLabel(DismissalType type) => switch (type) {
        DismissalType.bowled => 'Bowled',
        DismissalType.caught => 'Caught',
        DismissalType.lbw => 'LBW',
        DismissalType.runOut => 'Run Out',
        DismissalType.stumped => 'Stumped',
        DismissalType.hitWicket => 'Hit Wicket',
        DismissalType.caughtAndBowled => 'C & B',
        DismissalType.retiredHurt => 'Ret. Hurt',
        DismissalType.retiredOut => 'Ret. Out',
        DismissalType.timedOut => 'Timed Out',
        DismissalType.obstructingField => 'Obstruct.',
      };

  /// Whether a dismissal type is enabled in the grid.
  bool _isTypeEnabled(DismissalType type) {
    if (!type.isMvpActive) return false;
    if (widget.isFreeHitPending && !type.isValidOnFreeHit) return false;
    return true;
  }

  void _onTypeSelected(DismissalType type) {
    if (!_isTypeEnabled(type)) return;
    setState(() {
      _selectedType = type;
    });
  }

  void _onNext() {
    if (!_isPrimaryEnabled) return;
    if (_step >= _maxStep) {
      _confirm();
      return;
    }
    setState(() => _step++);
  }

  void _onBack() {
    if (_step <= 1) return;
    setState(() => _step--);
  }

  void _confirm() {
    widget.onConfirm(WicketDialogResult(
      dismissalType: _selectedType!,
      dismissedPlayerId: _dismissedPlayerId ?? widget.strikerId,
      fielderId: _selectedFielderId,
      fielderName: _selectedFielderName,
      runsFromBat: _selectedType == DismissalType.runOut ? _runsBeforeRunOut : 0,
      battersCrossed: _battersCrossed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: switch (_step) {
                  1 => _buildStep1(context),
                  2 => _buildStep2(context),
                  3 => _buildStep3(context),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFEBEE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Text(
            'Wicket!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'How was the batter dismissed?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DismissalType.values.map((type) {
              final enabled = _isTypeEnabled(type);
              final selected = _selectedType == type;
              return _DismissalChip(
                label: _gridLabel(type),
                enabled: enabled,
                selected: selected,
                onTap: () => _onTypeSelected(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.bowlingTeamPlayers.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          'Select Fielder',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search player...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final player = filtered[i];
              final isSelected = _selectedFielderId == player.playerId;
              return _FielderRow(
                player: player,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFielderId = player.playerId;
                    _selectedFielderName = player.displayName;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    final theme = Theme.of(context);
    final isStrikerSelected = _dismissedPlayerId == widget.strikerId;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Run Out Details',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Which batter was run out?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BatterCard(
                  name: widget.strikerName,
                  label: 'Striker',
                  isSelected: isStrikerSelected,
                  onTap: () =>
                      setState(() => _dismissedPlayerId = widget.strikerId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BatterCard(
                  name: widget.nonStrikerName,
                  label: 'Non-Striker',
                  isSelected: !isStrikerSelected,
                  onTap: () =>
                      setState(() => _dismissedPlayerId = widget.nonStrikerId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Had batters crossed?',
                style: theme.textTheme.bodyMedium,
              ),
              Switch(
                value: _battersCrossed,
                onChanged: (v) => setState(() => _battersCrossed = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Runs before run out',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0, 1, 2, 3].map((r) {
              final selected = _runsBeforeRunOut == r;
              return ChoiceChip(
                label: Text('$r'),
                selected: selected,
                onSelected: (_) => setState(() => _runsBeforeRunOut = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _step > 1 ? _onBack : null,
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: _isPrimaryEnabled ? _onNext : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: Text(_primaryButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _DismissalChip extends StatelessWidget {
  const _DismissalChip({
    required this.label,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: selected ? const Color(0xFFFFEBEE) : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? const Color(0xFFC62828)
                : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? const Color(0xFFC62828)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FielderRow extends StatelessWidget {
  const _FielderRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFEBEE) : null,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFC62828)
                  : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFCE4EC),
                child: Text(
                  player.initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  player.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (player.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    player.badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatterCard extends StatelessWidget {
  const _BatterCard({
    required this.name,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : null,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC62828)
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFFC62828) : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
