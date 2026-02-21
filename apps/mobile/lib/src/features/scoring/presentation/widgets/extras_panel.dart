import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Type of extra delivery.
enum ExtraType {
  wide,
  noBall,
  bye,
  legBye;

  String get displayName => switch (this) {
        wide => 'Wide',
        noBall => 'No Ball',
        bye => 'Bye',
        legBye => 'Leg Bye',
      };

  Color get color => switch (this) {
        wide => AppColors.wide,
        noBall => AppColors.noBall,
        bye => AppColors.bye,
        legBye => AppColors.legBye,
      };

  String get runsLabel => switch (this) {
        wide => 'Additional Runs',
        noBall => 'Runs from Bat',
        bye => 'Bye Runs',
        legBye => 'Leg Bye Runs',
      };

  List<int> get runOptions => switch (this) {
        wide => [0, 1, 2, 3, 4],
        noBall => [0, 1, 2, 3, 4, 6],
        bye => [1, 2, 3, 4],
        legBye => [1, 2, 3, 4],
      };

  int get defaultRuns => switch (this) {
        wide || noBall => 0,
        bye || legBye => 1,
      };
}

/// No-ball run type when wicket is toggled.
enum NoBallRunType { batRuns, byes, legByes }

/// Bottom sheet panel for recording extra deliveries (wide, no ball, bye, leg bye).
class ExtrasPanel extends StatefulWidget {
  const ExtrasPanel({
    super.key,
    required this.extraType,
    this.wideRunsPenalty = 1,
    this.noBallRunsPenalty = 1,
    required this.onConfirm,
    required this.onClose,
  });

  final ExtraType extraType;
  final int wideRunsPenalty;
  final int noBallRunsPenalty;
  final void Function(int runs, {bool withWicket, NoBallRunType? noBallRunType}) onConfirm;
  final VoidCallback onClose;

  @override
  State<ExtrasPanel> createState() => _ExtrasPanelState();
}

class _ExtrasPanelState extends State<ExtrasPanel> {
  late int _selectedRuns;
  bool _wicketToggled = false;
  NoBallRunType _noBallRunType = NoBallRunType.batRuns;

  @override
  void initState() {
    super.initState();
    _selectedRuns = widget.extraType.defaultRuns;
  }

  bool get _canToggleWicket =>
      widget.extraType == ExtraType.wide || widget.extraType == ExtraType.noBall;

  int get _totalRuns => switch (widget.extraType) {
        ExtraType.wide => widget.wideRunsPenalty + _selectedRuns,
        ExtraType.noBall => widget.noBallRunsPenalty + _selectedRuns,
        ExtraType.bye || ExtraType.legBye => _selectedRuns,
      };

  void _showCustomRunPicker() {
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Runs'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [5, 6, 7, 8, 9, 10, 11, 12].map((n) {
            return ActionChip(
              label: Text('$n'),
              onPressed: () => Navigator.of(ctx).pop(n),
            );
          }).toList(),
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() => _selectedRuns = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = widget.extraType;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + badge + close
          Row(
            children: [
              Text(
                'Extra',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: type.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Runs label
          Text(
            type.runsLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Run buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...type.runOptions.map((r) => _buildRunButton(r, theme)),
              _buildCustomButton(theme),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // NB run type selector (only for no-ball)
          if (type == ExtraType.noBall) ...[
            Text(
              'Run Type',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Bat Runs'),
                  selected: _noBallRunType == NoBallRunType.batRuns,
                  onSelected: (_) =>
                      setState(() => _noBallRunType = NoBallRunType.batRuns),
                ),
                ChoiceChip(
                  label: const Text('Byes'),
                  selected: _noBallRunType == NoBallRunType.byes,
                  onSelected: (_) =>
                      setState(() => _noBallRunType = NoBallRunType.byes),
                ),
                ChoiceChip(
                  label: const Text('Leg Byes'),
                  selected: _noBallRunType == NoBallRunType.legByes,
                  onSelected: (_) =>
                      setState(() => _noBallRunType = NoBallRunType.legByes),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Wicket toggle (only for wide / no-ball)
          if (_canToggleWicket) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wicket?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _wicketToggled,
                  onChanged: (v) => setState(() => _wicketToggled = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total runs for this delivery',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$_totalRuns',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onConfirm(
                _selectedRuns,
                withWicket: _wicketToggled,
                noBallRunType: type == ExtraType.noBall ? _noBallRunType : null,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _wicketToggled
                    ? const Color(0xFFC62828)
                    : type.color,
              ),
              child: Text(_wicketToggled ? 'Next: Select Wicket' : 'Confirm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(int runs, ThemeData theme) {
    final isSelected = _selectedRuns == runs;
    if (isSelected) {
      return FilledButton(
        onPressed: () => setState(() => _selectedRuns = runs),
        style: FilledButton.styleFrom(
          backgroundColor: widget.extraType.color,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text('$runs'),
      );
    }
    return OutlinedButton(
      onPressed: () => setState(() => _selectedRuns = runs),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Text('$runs'),
    );
  }

  Widget _buildCustomButton(ThemeData theme) {
    // Show "..." if no custom value, or if a standard option is selected.
    final isCustomSelected =
        !widget.extraType.runOptions.contains(_selectedRuns);
    if (isCustomSelected) {
      return FilledButton(
        onPressed: _showCustomRunPicker,
        style: FilledButton.styleFrom(
          backgroundColor: widget.extraType.color,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text('$_selectedRuns'),
      );
    }
    return OutlinedButton(
      onPressed: _showCustomRunPicker,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: const Text('...'),
    );
  }
}
