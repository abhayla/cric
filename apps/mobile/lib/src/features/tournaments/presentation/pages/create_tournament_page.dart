import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tournament.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../providers.dart';

class CreateTournamentPage extends ConsumerStatefulWidget {
  const CreateTournamentPage({
    super.key,
    required this.onCreated,
  });

  final void Function(String tournamentId) onCreated;

  @override
  ConsumerState<CreateTournamentPage> createState() =>
      _CreateTournamentPageState();
}

class _CreateTournamentPageState extends ConsumerState<CreateTournamentPage> {
  final _nameController = TextEditingController();
  final _oversController = TextEditingController(text: '20');
  final _formKey = GlobalKey<FormState>();

  TournamentFormat _format = TournamentFormat.groupKnockout;
  int _ballTypeId = 1; // Leather
  int _playersPerSide = 11;
  int _maxOversPerBowler = 4;
  int _wideRuns = 1;
  int _noBallRuns = 1;
  int? _powerplayOvers;
  int _pointsWin = 2;
  int _pointsTie = 1;
  int _pointsNoResult = 1;
  int _pointsLoss = 0;
  int _numGroups = 2;
  int _qualifyPerGroup = 2;
  String? _startDate;
  String? _endDate;

  static const _oversPresets = [5, 10, 15, 20, 25, 50];
  static const _ballTypes = [
    (id: 1, label: 'Leather'),
    (id: 2, label: 'Tennis'),
    (id: 3, label: 'Tape'),
    (id: 4, label: 'Other'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _oversController.dispose();
    super.dispose();
  }

  int get _overs => int.tryParse(_oversController.text) ?? 20;

  bool get _showPoints => _format != TournamentFormat.knockout;
  bool get _showGroups => _format == TournamentFormat.groupKnockout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tournament')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildNameField(theme),
                      const SizedBox(height: 24),
                      _buildFormatSection(theme),
                      const SizedBox(height: 24),
                      _buildOversSection(theme),
                      const SizedBox(height: 24),
                      _buildBallTypeSection(theme),
                      const SizedBox(height: 24),
                      _buildMatchRulesSection(theme),
                      if (_showPoints) ...[
                        const SizedBox(height: 24),
                        _buildPointsSection(theme),
                      ],
                      if (_showGroups) ...[
                        const SizedBox(height: 24),
                        _buildGroupSettingsSection(theme),
                      ],
                      const SizedBox(height: 24),
                      _buildDatesSection(theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _handleCreate,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Tournament'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Name --

  Widget _buildNameField(ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Tournament Name',
        hintText: 'e.g. Summer Cricket League 2026',
      ),
      validator: (value) => Tournament.validateName(value?.trim() ?? ''),
    );
  }

  // -- Format --

  Widget _buildFormatSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TournamentFormat.values.map((format) {
            final isSelected = _format == format;
            return ChoiceChip(
              label: Text(format.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _format = format),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -- Overs --

  Widget _buildOversSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overs per Side', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                key: const Key('oversInput'),
                controller: _oversController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                validator: (value) {
                  final overs = int.tryParse(value ?? '');
                  if (overs == null) return 'Required';
                  return Tournament.validateOvers(overs);
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Text('overs', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _oversPresets.map((preset) {
            final isSelected = _overs == preset;
            return ChoiceChip(
              label: Text('$preset'),
              selected: isSelected,
              onSelected: (_) {
                _oversController.text = '$preset';
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // -- Ball Type --

  Widget _buildBallTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ball Type', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _ballTypes.map((bt) {
            final isSelected = _ballTypeId == bt.id;
            return ChoiceChip(
              label: Text(bt.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _ballTypeId = bt.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -- Match Rules --

  Widget _buildMatchRulesSection(ThemeData theme) {
    return _ConditionalSection(
      label: 'MATCH RULES',
      child: Column(
        children: [
          _StepperRow(
            key: const Key('playersPerSideStepper'),
            label: 'Players Per Side',
            value: _playersPerSide,
            min: 2,
            max: 11,
            onChanged: (v) => setState(() => _playersPerSide = v),
          ),
          _StepperRow(
            label: 'Max Overs/Bowler',
            value: _maxOversPerBowler,
            min: 1,
            max: 50,
            onChanged: (v) => setState(() => _maxOversPerBowler = v),
          ),
          _StepperRow(
            label: 'Wide Runs',
            value: _wideRuns,
            min: 1,
            max: 5,
            onChanged: (v) => setState(() => _wideRuns = v),
          ),
          _StepperRow(
            label: 'No-Ball Runs',
            value: _noBallRuns,
            min: 1,
            max: 5,
            onChanged: (v) => setState(() => _noBallRuns = v),
          ),
          _NullableStepperRow(
            label: 'Powerplay Overs',
            value: _powerplayOvers,
            min: 1,
            max: 50,
            onChanged: (v) => setState(() => _powerplayOvers = v),
          ),
        ],
      ),
    );
  }

  // -- Points System --

  Widget _buildPointsSection(ThemeData theme) {
    return _ConditionalSection(
      label: 'POINTS SYSTEM',
      child: Row(
        children: [
          _PointsCell(
            label: 'Win',
            value: _pointsWin,
            onChanged: (v) => setState(() => _pointsWin = v),
          ),
          const SizedBox(width: 8),
          _PointsCell(
            label: 'Tie',
            value: _pointsTie,
            onChanged: (v) => setState(() => _pointsTie = v),
          ),
          const SizedBox(width: 8),
          _PointsCell(
            label: 'NR',
            value: _pointsNoResult,
            onChanged: (v) => setState(() => _pointsNoResult = v),
          ),
          const SizedBox(width: 8),
          _PointsCell(
            label: 'Loss',
            value: _pointsLoss,
            onChanged: (v) => setState(() => _pointsLoss = v),
          ),
        ],
      ),
    );
  }

  // -- Group Settings --

  Widget _buildGroupSettingsSection(ThemeData theme) {
    return _ConditionalSection(
      label: 'GROUP STAGE SETTINGS',
      child: Column(
        children: [
          _StepperRow(
            key: const Key('numGroupsStepper'),
            label: 'Number of Groups',
            value: _numGroups,
            min: 1,
            max: 8,
            onChanged: (v) => setState(() => _numGroups = v),
          ),
          _StepperRow(
            key: const Key('qualifyPerGroupStepper'),
            label: 'Top N Qualify',
            value: _qualifyPerGroup,
            min: 1,
            max: 4,
            onChanged: (v) => setState(() => _qualifyPerGroup = v),
          ),
        ],
      ),
    );
  }

  // -- Dates --

  Widget _buildDatesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dates (optional)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Start Date',
                value: _startDate,
                onChanged: (v) => setState(() => _startDate = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'End Date',
                value: _endDate,
                onChanged: (v) => setState(() => _endDate = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -- Submit --

  bool _isSubmitting = false;

  Future<void> _handleCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(tournamentRepositoryProvider);
      final tournament = await repository.createTournament(
        CreateTournamentInput(
          name: _nameController.text.trim(),
          format: _format,
          oversPerMatch: _overs,
          ballTypeId: _ballTypeId,
          playersPerSide: _playersPerSide,
          maxOversPerBowler: _maxOversPerBowler,
          wideRuns: _wideRuns,
          noBallRuns: _noBallRuns,
          powerplayOvers: _powerplayOvers,
          pointsWin: _pointsWin,
          pointsTie: _pointsTie,
          pointsNoResult: _pointsNoResult,
          pointsLoss: _pointsLoss,
          numGroups: _numGroups,
          qualifyPerGroup: _qualifyPerGroup,
          startDate: _startDate,
          endDate: _endDate,
        ),
      );
      widget.onCreated(tournament.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create tournament: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// -- Reusable sub-widgets --

class _ConditionalSection extends StatelessWidget {
  const _ConditionalSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: const CircleBorder(),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NullableStepperRow extends StatelessWidget {
  const _NullableStepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value != null
                ? () => onChanged(value! > min ? value! - 1 : null)
                : null,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: const CircleBorder(),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value != null ? '$value' : '\u2014',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (value == null) {
                onChanged(min);
              } else if (value! < max) {
                onChanged(value! + 1);
              }
            },
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsCell extends StatelessWidget {
  const _PointsCell({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: TextFormField(
              initialValue: '$value',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (text) {
                final v = int.tryParse(text);
                if (v != null && v >= 0 && v <= 10) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select date',
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      controller: TextEditingController(text: value),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
    );
  }
}
