import 'package:flutter/material.dart';

import '../notifiers/match_setup_notifier.dart';

class MatchSetupPage extends StatefulWidget {
  const MatchSetupPage({
    super.key,
    required this.onMatchCreated,
    this.onNavigateToCreateTeam,
  });

  final void Function(String matchId) onMatchCreated;
  final void Function()? onNavigateToCreateTeam;

  @override
  State<MatchSetupPage> createState() => _MatchSetupPageState();
}

class _MatchSetupPageState extends State<MatchSetupPage> {
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
    _state = MatchSetupState();
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _state.isValid ? _handleProceedToToss : null,
                  child: const Text('Proceed to Toss'),
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
          onTap: () {},
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
          onTap: () {},
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

  void _handleProceedToToss() {
    // Will be wired to match creation API in routing integration (#24)
  }
}
