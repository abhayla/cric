import 'package:flutter/material.dart';

import '../../domain/entities/playing_xi_player.dart';

/// Result from the super over setup wizard.
class SuperOverSetupResult {
  const SuperOverSetupResult({
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

/// 3-step wizard for setting up a super over.
///
/// Step 1: Select 2 batters from the batting team (team that batted 2nd)
/// Step 2: Select 1 bowler from the bowling team (excludes previous SO bowlers)
/// Step 3: Confirm selections
class SuperOverSetupWizard extends StatefulWidget {
  const SuperOverSetupWizard({
    super.key,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
    required this.superOverNumber,
    this.previousSuperOverBowlerIds = const [],
    required this.onConfirm,
  });

  final String battingTeamName;
  final String bowlingTeamName;
  final List<PlayingXIPlayer> battingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final int superOverNumber;
  final List<String> previousSuperOverBowlerIds;
  final ValueChanged<SuperOverSetupResult> onConfirm;

  @override
  State<SuperOverSetupWizard> createState() => _SuperOverSetupWizardState();
}

class _SuperOverSetupWizardState extends State<SuperOverSetupWizard> {
  int _step = 1;
  final List<String> _selectedBatterIds = [];
  String? _selectedBowlerId;

  String get _stepTitle => switch (_step) {
        1 => 'Select 2 Batters (${widget.battingTeamName})',
        2 => 'Select Bowler (${widget.bowlingTeamName})',
        3 => 'Confirm Super Over',
        _ => '',
      };

  bool get _canProceed => switch (_step) {
        1 => _selectedBatterIds.length == 2,
        2 => _selectedBowlerId != null,
        3 => true,
        _ => false,
      };

  void _onNext() {
    if (!_canProceed) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _confirm();
    }
  }

  void _onBack() {
    if (_step > 1) setState(() => _step--);
  }

  void _confirm() {
    final striker = widget.battingTeamPlayers.firstWhere(
      (p) => p.playerId == _selectedBatterIds[0],
    );
    final nonStriker = widget.battingTeamPlayers.firstWhere(
      (p) => p.playerId == _selectedBatterIds[1],
    );
    final bowler = widget.bowlingTeamPlayers.firstWhere(
      (p) => p.playerId == _selectedBowlerId,
    );

    widget.onConfirm(SuperOverSetupResult(
      strikerId: striker.playerId,
      strikerName: striker.displayName,
      nonStrikerId: nonStriker.playerId,
      nonStrikerName: nonStriker.displayName,
      bowlerId: bowler.playerId,
      bowlerName: bowler.displayName,
    ));
  }

  void _toggleBatter(String playerId) {
    setState(() {
      if (_selectedBatterIds.contains(playerId)) {
        _selectedBatterIds.remove(playerId);
      } else if (_selectedBatterIds.length < 2) {
        _selectedBatterIds.add(playerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Text(
                    'Super Over ${widget.superOverNumber}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step $_step of 3: $_stepTitle',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: switch (_step) {
                  1 => _buildBatterSelection(),
                  2 => _buildBowlerSelection(),
                  3 => _buildConfirmation(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _step > 1 ? _onBack : null,
                    child: const Text('Back'),
                  ),
                  FilledButton(
                    onPressed: _canProceed ? _onNext : null,
                    child: Text(_step == 3 ? 'Start Super Over' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterSelection() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.battingTeamPlayers.length,
      itemBuilder: (ctx, i) {
        final player = widget.battingTeamPlayers[i];
        final isSelected = _selectedBatterIds.contains(player.playerId);
        return _PlayerTile(
          player: player,
          isSelected: isSelected,
          isEnabled:
              isSelected || _selectedBatterIds.length < 2,
          onTap: () => _toggleBatter(player.playerId),
        );
      },
    );
  }

  Widget _buildBowlerSelection() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.bowlingTeamPlayers.length,
      itemBuilder: (ctx, i) {
        final player = widget.bowlingTeamPlayers[i];
        final isExcluded = widget.previousSuperOverBowlerIds
            .contains(player.playerId);
        final isSelected = _selectedBowlerId == player.playerId;
        return _PlayerTile(
          player: player,
          isSelected: isSelected,
          isEnabled: !isExcluded,
          subtitle: isExcluded ? 'Bowled in previous SO' : null,
          onTap: isExcluded
              ? null
              : () => setState(() => _selectedBowlerId = player.playerId),
        );
      },
    );
  }

  Widget _buildConfirmation() {
    final theme = Theme.of(context);
    final striker = widget.battingTeamPlayers
        .firstWhere((p) => p.playerId == _selectedBatterIds[0]);
    final nonStriker = widget.battingTeamPlayers
        .firstWhere((p) => p.playerId == _selectedBatterIds[1]);
    final bowler = widget.bowlingTeamPlayers
        .firstWhere((p) => p.playerId == _selectedBowlerId);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batting', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Striker: ${striker.displayName}'),
            Text('Non-Striker: ${nonStriker.displayName}'),
            const SizedBox(height: 16),
            Text('Bowling', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Bowler: ${bowler.displayName}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Super Over: 1 over, 2 wickets = all out. '
                'If tied again, another super over follows.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.isSelected,
    required this.isEnabled,
    this.subtitle,
    this.onTap,
  });

  final PlayingXIPlayer player;
  final bool isSelected;
  final bool isEnabled;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : null,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    player.initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
