import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/domain/entities/team.dart';
import '../../../teams/providers.dart' as teams;
import '../../providers.dart' as scoring;
import '../notifiers/match_setup_notifier.dart';

class MatchSetupPage extends ConsumerStatefulWidget {
  const MatchSetupPage({
    super.key,
    required this.onMatchCreated,
    this.onNavigateToCreateTeam,
    this.initialHomeTeamId,
    this.initialHomeTeamName,
    this.initialAwayTeamId,
    this.initialAwayTeamName,
    this.initialOvers,
    this.initialPlayersPerSide,
  });

  final void Function(
    String matchId, {
    required String homeTeamId,
    required String homeTeamName,
    required String awayTeamId,
    required String awayTeamName,
    required int playersPerSide,
    required int totalOvers,
    required int wideRuns,
    required int noBallRuns,
    required List<int>? magicOverNumbers,
    required int magicOverRunMultiplier,
    required int magicOverWicketPenalty,
  }) onMatchCreated;
  final void Function()? onNavigateToCreateTeam;

  /// Pre-selected teams (e.g. from fixture tap).
  final String? initialHomeTeamId;
  final String? initialHomeTeamName;
  final String? initialAwayTeamId;
  final String? initialAwayTeamName;
  final int? initialOvers;
  final int? initialPlayersPerSide;

  @override
  ConsumerState<MatchSetupPage> createState() => _MatchSetupPageState();
}

class _MatchSetupPageState extends ConsumerState<MatchSetupPage> {
  late MatchSetupState _state;
  final _venueController = TextEditingController();
  final _oversController = TextEditingController();
  final _playersController = TextEditingController();
  final _wideRunsController = TextEditingController();
  final _noBallRunsController = TextEditingController();
  final _maxOversController = TextEditingController();
  final _powerplayController = TextEditingController();

  static const _oversPresets = [5, 10, 15, 20, 25, 50];
  static const _playersPresets = [6, 8, 11];

  @override
  void initState() {
    super.initState();
    _state = MatchSetupState(
      homeTeamId: widget.initialHomeTeamId,
      homeTeamName: widget.initialHomeTeamName,
      awayTeamId: widget.initialAwayTeamId,
      awayTeamName: widget.initialAwayTeamName,
      totalOvers: widget.initialOvers ?? 20,
      playersPerSide: widget.initialPlayersPerSide ?? 11,
    );
    _oversController.text = _state.totalOvers.toString();
    _playersController.text = _state.playersPerSide.toString();
    _wideRunsController.text = _state.wideRuns.toString();
    _noBallRunsController.text = _state.noBallRuns.toString();
  }

  @override
  void dispose() {
    _venueController.dispose();
    _oversController.dispose();
    _playersController.dispose();
    _wideRunsController.dispose();
    _noBallRunsController.dispose();
    _maxOversController.dispose();
    _powerplayController.dispose();
    super.dispose();
  }

  void _updateState(MatchSetupState newState) {
    setState(() => _state = newState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Match')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildTeamsSection(theme),
                    const SizedBox(height: 24),
                    _buildMatchFormatSection(theme),
                    const SizedBox(height: 24),
                    _buildPlayersPerSideSection(theme),
                    const SizedBox(height: 24),
                    _buildBallTypeSection(theme),
                    const SizedBox(height: 24),
                    _buildMatchDateSection(theme),
                    const SizedBox(height: 24),
                    _buildVenueSection(theme),
                    const SizedBox(height: 24),
                    _buildAdvancedSettingsSection(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _state.isValid && !_state.isSubmitting
                      ? _handleProceedToToss
                      : null,
                  child: _state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Proceed to Toss'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teams',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildTeamSelector(
          theme: theme,
          teamName: _state.homeTeamName,
          placeholder: 'Select Team A',
          onTap: () => _showTeamPicker(isHome: true),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'VS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        _buildTeamSelector(
          theme: theme,
          teamName: _state.awayTeamName,
          placeholder: 'Select Team B',
          onTap: () => _showTeamPicker(isHome: false),
        ),
      ],
    );
  }

  Widget _buildTeamSelector({
    required ThemeData theme,
    required String? teamName,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              child: Icon(
                Icons.shield,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                teamName ?? placeholder,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: teamName != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFormatSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Format',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _oversPresets.map((overs) {
            return ChoiceChip(
              label: Text('$overs'),
              selected: _state.totalOvers == overs,
              onSelected: (selected) {
                if (selected) {
                  _oversController.text = overs.toString();
                  _updateState(_state.copyWith(totalOvers: overs));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayersPerSideSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Players Per Side',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _playersPresets.map((count) {
            return ChoiceChip(
              label: Text('$count'),
              selected: _state.playersPerSide == count,
              onSelected: (selected) {
                if (selected) {
                  _playersController.text = count.toString();
                  _updateState(_state.copyWith(playersPerSide: count));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBallTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ball Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BallType.values.map((type) {
            return ChoiceChip(
              label: Text(type.label),
              selected: _state.ballTypeId == type.id,
              onSelected: (selected) {
                if (selected) {
                  _updateState(_state.copyWith(ballTypeId: type.id));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchDateSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Date',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  _state.matchDate,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue (optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _venueController,
          decoration: const InputDecoration(
            hintText: 'Enter venue name',
          ),
          onChanged: (value) {
            _updateState(
              _state.copyWith(venue: value.trim().isEmpty ? null : value.trim()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            _updateState(
                _state.copyWith(isAdvancedOpen: !_state.isAdvancedOpen));
          },
          child: Row(
            children: [
              Text(
                'Advanced Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                _state.isAdvancedOpen
                    ? Icons.expand_less
                    : Icons.expand_more,
              ),
            ],
          ),
        ),
        if (_state.isAdvancedOpen) ...[
          const SizedBox(height: 16),
          _buildNumberField(
            theme: theme,
            label: 'Wide Runs',
            controller: _wideRunsController,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _updateState(_state.copyWith(wideRuns: parsed));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            theme: theme,
            label: 'No-Ball Runs',
            controller: _noBallRunsController,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _updateState(_state.copyWith(noBallRuns: parsed));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            theme: theme,
            label: 'Max Overs Per Bowler',
            controller: _maxOversController,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _updateState(_state.copyWith(maxOversPerBowler: parsed));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            theme: theme,
            label: 'Powerplay Overs',
            controller: _powerplayController,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _updateState(_state.copyWith(powerplayOvers: parsed));
              }
            },
          ),
          const SizedBox(height: 24),
          _buildMagicOverSection(theme),
        ],
      ],
    );
  }

  Widget _buildMagicOverSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Enable Magic Over',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text('Multiply runs and penalize wickets in selected overs'),
          value: _state.magicOverEnabled,
          onChanged: (value) {
            _updateState(_state.copyWith(magicOverEnabled: value));
          },
        ),
        if (_state.magicOverEnabled) ...[
          const SizedBox(height: 8),
          Text(
            'Select Magic Overs',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_state.magicOverError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _state.magicOverError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_state.totalOvers, (i) {
              final overNum = i + 1;
              final isSelected = _state.magicOverNumbers.contains(overNum);
              return FilterChip(
                label: Text('$overNum'),
                selected: isSelected,
                onSelected: (selected) {
                  final updated = List<int>.from(_state.magicOverNumbers);
                  if (selected) {
                    updated.add(overNum);
                  } else {
                    updated.remove(overNum);
                  }
                  updated.sort();
                  _updateState(_state.copyWith(magicOverNumbers: updated));
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Run Multiplier',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 5].map((m) {
              return ChoiceChip(
                label: Text('${m}x'),
                selected: _state.magicOverRunMultiplier == m,
                onSelected: (_) {
                  _updateState(_state.copyWith(magicOverRunMultiplier: m));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Wicket Penalty: ${_state.magicOverWicketPenalty} runs',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: _state.magicOverWicketPenalty.toDouble(),
            min: -20,
            max: 0,
            divisions: 20,
            label: '${_state.magicOverWicketPenalty}',
            onChanged: (value) {
              _updateState(
                _state.copyWith(magicOverWicketPenalty: value.round()),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-20', style: theme.textTheme.bodySmall),
              Text('0 (none)', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNumberField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter value',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final parts = _state.matchDate.split('-');
    final initial = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _updateState(_state.copyWith(matchDate: formatted));
    }
  }

  Future<void> _showTeamPicker({required bool isHome}) async {
    if (!mounted) return;

    // Only refresh if there is no data yet (initial load or error state).
    // When navigating away from the Teams tab the provider keeps its cached
    // data because it is not auto-disposed, so a fresh fetch is usually
    // unnecessary and would briefly reset the list to a loading spinner.
    final current = ref.read(teams.teamsListProvider);
    if (!current.hasValue) {
      ref.read(teams.teamsListProvider.notifier).refresh();
    }

    final selected = await showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final teamsAsync = ref.watch(teams.teamsListProvider);
            final teamList = teamsAsync.value?.teams ?? [];
            final isLoading = teamsAsync.isLoading;

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              maxChildSize: 0.8,
              minChildSize: 0.3,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        isHome ? 'Select Team A' : 'Select Team B',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : teamList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('No teams found'),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          widget.onNavigateToCreateTeam?.call();
                                        },
                                        child: const Text('Create Team'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: teamList.length,
                                  itemBuilder: (context, index) {
                                    final team = teamList[index];
                                    // Exclude already-selected team
                                    final isDisabled = isHome
                                        ? team.id == _state.awayTeamId
                                        : team.id == _state.homeTeamId;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(team.initial),
                                      ),
                                      title: Text(team.name),
                                      subtitle: Text(team.subtitle),
                                      enabled: !isDisabled,
                                      onTap: isDisabled
                                          ? null
                                          : () => Navigator.of(context).pop(team),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selected != null) {
      if (isHome) {
        _updateState(_state.copyWith(
          homeTeamId: selected.id,
          homeTeamName: selected.name,
        ));
      } else {
        _updateState(_state.copyWith(
          awayTeamId: selected.id,
          awayTeamName: selected.name,
        ));
      }
    }
  }

  Future<void> _handleProceedToToss() async {
    _updateState(_state.copyWith(isSubmitting: true));

    try {
      final matchRepo = ref.read(scoring.matchRepositoryProvider);
      final match = await matchRepo.createMatch(_state.toCreateMatchInput());

      if (!mounted) return;
      widget.onMatchCreated(
        match.id,
        homeTeamId: _state.homeTeamId ?? '',
        homeTeamName: _state.homeTeamName ?? '',
        awayTeamId: _state.awayTeamId ?? '',
        awayTeamName: _state.awayTeamName ?? '',
        playersPerSide: _state.playersPerSide,
        totalOvers: _state.totalOvers,
        wideRuns: _state.wideRuns,
        noBallRuns: _state.noBallRuns,
        magicOverNumbers: _state.magicOverEnabled ? _state.magicOverNumbers : null,
        magicOverRunMultiplier: _state.magicOverRunMultiplier,
        magicOverWicketPenalty: _state.magicOverWicketPenalty,
      );
    } catch (e) {
      if (!mounted) return;
      _updateState(_state.copyWith(isSubmitting: false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create match: $e')),
      );
    }
  }
}
