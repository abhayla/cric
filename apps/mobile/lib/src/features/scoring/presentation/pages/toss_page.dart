import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../notifiers/toss_notifier.dart';

class TossPage extends StatefulWidget {
  const TossPage({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.playersPerSide,
    required this.homeRoster,
    required this.awayRoster,
    required this.onStartMatch,
  });

  final String matchId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final int playersPerSide;
  final List<RosterPlayer> homeRoster;
  final List<RosterPlayer> awayRoster;
  final Future<void> Function(TossState tossState) onStartMatch;

  @override
  State<TossPage> createState() => _TossPageState();
}

class _TossPageState extends State<TossPage> {
  late TossState _state;

  @override
  void initState() {
    super.initState();
    _state = TossState(
      matchId: widget.matchId,
      homeTeamId: widget.homeTeamId,
      homeTeamName: widget.homeTeamName,
      awayTeamId: widget.awayTeamId,
      awayTeamName: widget.awayTeamName,
      playersPerSide: widget.playersPerSide,
      homeRoster: widget.homeRoster,
      awayRoster: widget.awayRoster,
    );
  }

  void _updateState(TossState newState) {
    setState(() => _state = newState);
  }

  Future<void> _nextStep() async {
    if (kDebugMode) {
      debugPrint('[TossPage._nextStep] step=${_state.currentStep}, canProceed=${_state.canProceed}');
      if (_state.currentStep == TossStep.openers) {
        debugPrint('[TossPage._nextStep] openers=${_state.openingBatterIds.length}, '
            'striker=${_state.strikerId}, bowler=${_state.openingBowlerId}');
      }
    }
    if (!_state.canProceed) return;
    if (_state.isLastStep) {
      if (kDebugMode) {
        debugPrint('[TossPage._nextStep] Calling onStartMatch...');
      }
      await widget.onStartMatch(_state);
      return;
    }
    final nextIndex = _state.currentStep.index + 1;
    _updateState(
        _state.copyWith(currentStep: TossStep.values[nextIndex]));
  }

  void _prevStep() {
    if (_state.isFirstStep) return;
    final prevIndex = _state.currentStep.index - 1;
    _updateState(
        _state.copyWith(currentStep: TossStep.values[prevIndex]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Toss')),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStepContent(theme),
              ),
            ),
            _buildButtonRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: List.generate(TossStep.values.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector
            final stepBefore = i ~/ 2;
            final isCompleted =
                stepBefore < _state.currentStep.index;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final step = TossStep.values[stepIndex];
          final isActive = step == _state.currentStep;
          final isCompleted = stepIndex < _state.currentStep.index;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${step.stepNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive || isCompleted
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_state.currentStep) {
      case TossStep.tossWinner:
        return _buildStep1TossWinner(theme);
      case TossStep.decision:
        return _buildStep2Decision(theme);
      case TossStep.xiTeamA:
        return _buildStep3XiTeamA(theme);
      case TossStep.xiTeamB:
        return _buildStep4XiTeamB(theme);
      case TossStep.openers:
        return _buildStep5Openers(theme);
    }
  }

  // -- Step 1: Who won the toss? --

  Widget _buildStep1TossWinner(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'Who won the toss?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTeamTossCard(
                theme: theme,
                teamId: widget.homeTeamId,
                teamName: widget.homeTeamName,
                isSelected: _state.tossWinnerId == widget.homeTeamId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamTossCard(
                theme: theme,
                teamId: widget.awayTeamId,
                teamName: widget.awayTeamName,
                isSelected: _state.tossWinnerId == widget.awayTeamId,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamTossCard({
    required ThemeData theme,
    required String teamId,
    required String teamName,
    required bool isSelected,
  }) {
    final initials = teamName.length >= 2
        ? teamName
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0] : '')
            .join()
            .toUpperCase()
        : teamName.isNotEmpty
            ? teamName[0].toUpperCase()
            : '?';

    return InkWell(
      onTap: () {
        _updateState(_state.copyWith(tossWinnerId: teamId));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHigh,
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              teamName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -- Step 2: Bat or Field? --

  Widget _buildStep2Decision(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          '${_state.tossWinnerName} chose to',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select batting or fielding',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecisionCard(
              theme: theme,
              label: 'Bat',
              icon: Icons.sports_cricket,
              isSelected:
                  _state.tossDecision == TossDecision.bat,
              onTap: () {
                _updateState(
                    _state.copyWith(tossDecision: TossDecision.bat));
              },
            ),
            const SizedBox(width: 16),
            _buildDecisionCard(
              theme: theme,
              label: 'Field',
              icon: Icons.sports,
              isSelected:
                  _state.tossDecision == TossDecision.field,
              onTap: () {
                _updateState(
                    _state.copyWith(tossDecision: TossDecision.field));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionCard({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Step 3: Playing XI - Team A (home) --

  Widget _buildStep3XiTeamA(ThemeData theme) {
    return _buildXiStep(
      theme: theme,
      teamName: widget.homeTeamName,
      roster: widget.homeRoster,
      selectedIds: _state.selectedHomePlayerIds,
      countLabel: _state.homeXICountLabel,
      onToggle: (playerId) {
        final updated = Set<String>.from(_state.selectedHomePlayerIds);
        if (updated.contains(playerId)) {
          updated.remove(playerId);
        } else if (updated.length < widget.playersPerSide) {
          updated.add(playerId);
        }
        _updateState(
            _state.copyWith(selectedHomePlayerIds: updated));
      },
    );
  }

  // -- Step 4: Playing XI - Team B (away) --

  Widget _buildStep4XiTeamB(ThemeData theme) {
    return _buildXiStep(
      theme: theme,
      teamName: widget.awayTeamName,
      roster: widget.awayRoster,
      selectedIds: _state.selectedAwayPlayerIds,
      countLabel: _state.awayXICountLabel,
      onToggle: (playerId) {
        final updated = Set<String>.from(_state.selectedAwayPlayerIds);
        if (updated.contains(playerId)) {
          updated.remove(playerId);
        } else if (updated.length < widget.playersPerSide) {
          updated.add(playerId);
        }
        _updateState(
            _state.copyWith(selectedAwayPlayerIds: updated));
      },
    );
  }

  Widget _buildXiStep({
    required ThemeData theme,
    required String teamName,
    required List<RosterPlayer> roster,
    required Set<String> selectedIds,
    required String countLabel,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Playing XI',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select ${widget.playersPerSide} from $teamName',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...roster.map((player) {
          final isSelected = selectedIds.contains(player.playerId);
          return _buildPlayerSelectRow(
            theme: theme,
            player: player,
            isSelected: isSelected,
            onTap: () => onToggle(player.playerId),
          );
        }),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            countLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlayerSelectRow({
    required ThemeData theme,
    required RosterPlayer player,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        size: 14, color: theme.colorScheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHigh,
                child: Text(
                  player.initials,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.displayName}${player.badge != null ? ' ${player.badge}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.playerRole != null)
                      Text(
                        player.playerRole!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Step 5: Openers & Bowler --

  Widget _buildStep5Openers(ThemeData theme) {
    final battingXI = _state.battingXI;
    final fieldingXI = _state.fieldingXI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Select Opening Batsmen',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose 2 from ${_state.battingTeamName}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...battingXI.map((player) {
          final isSelected =
              _state.openingBatterIds.contains(player.playerId);
          return _buildPlayerSelectRow(
            theme: theme,
            player: player,
            isSelected: isSelected,
            onTap: () {
              final updated =
                  List<String>.from(_state.openingBatterIds);
              if (updated.contains(player.playerId)) {
                updated.remove(player.playerId);
                // Clear striker if deselected
                final newStriker =
                    _state.strikerId == player.playerId
                        ? null
                        : _state.strikerId;
                _updateState(_state.copyWith(
                  openingBatterIds: updated,
                  strikerId: newStriker,
                ));
              } else if (updated.length < 2) {
                updated.add(player.playerId);
                _updateState(
                    _state.copyWith(openingBatterIds: updated));
              }
            },
          );
        }),

        // Striker prompt
        if (_state.openingBatterIds.length == 2) ...[
          const SizedBox(height: 16),
          _buildStrikerPrompt(theme),
        ],

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        Text(
          'Select Opening Bowler',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose 1 from ${_state.fieldingTeamName}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...fieldingXI.map((player) {
          final isSelected =
              _state.openingBowlerId == player.playerId;
          return _buildPlayerSelectRow(
            theme: theme,
            player: player,
            isSelected: isSelected,
            onTap: () {
              _updateState(
                  _state.copyWith(openingBowlerId: player.playerId));
            },
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStrikerPrompt(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.primary, width: 1.5),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who will face the first ball?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._state.openingBatterIds.map((id) {
            final player = _state.battingXI.firstWhere(
              (p) => p.playerId == id,
            );
            final isSelected = _state.strikerId == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  _updateState(_state.copyWith(strikerId: id));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? theme.colorScheme.primary
                            .withValues(alpha: 0.08)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: isSelected ? 5 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        player.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // -- Bottom buttons --

  Widget _buildButtonRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
          if (!_state.isFirstStep)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _prevStep,
                  child: const Text('Back'),
                ),
              ),
            ),
          if (!_state.isFirstStep) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _state.canProceed ? _nextStep : null,
                child: Text(_state.nextButtonLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
