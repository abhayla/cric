import 'package:flutter/material.dart';

import '../../../auth/domain/entities/app_user.dart';

class AddPlayerPage extends StatefulWidget {
  const AddPlayerPage({
    super.key,
    required this.teamId,
    this.onCreatePlayer,
    this.onAddExisting,
  });

  final String teamId;

  /// Called when creating a new player.
  final void Function(
    String name,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  )? onCreatePlayer;

  /// Called when adding an existing player by ID.
  final void Function(String playerId)? onAddExisting;

  @override
  State<AddPlayerPage> createState() => _AddPlayerPageState();
}

class _AddPlayerPageState extends State<AddPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Player'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search by Phone'),
              Tab(text: 'Create New'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SearchTab(
              onAddExisting: widget.onAddExisting,
            ),
            _CreateTab(
              onCreatePlayer: widget.onCreatePlayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab({this.onAddExisting});

  final void Function(String playerId)? onAddExisting;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+91',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                // TODO: Search player by phone
              },
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTab extends StatefulWidget {
  const _CreateTab({this.onCreatePlayer});

  final void Function(
    String name,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  )? onCreatePlayer;

  @override
  State<_CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends State<_CreateTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'batter';
  String _selectedBattingStyle = 'right_hand';
  String _selectedBowlingStyle = 'right_arm_medium';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  bool get _isPhoneValid => _phoneRegex.hasMatch(_phoneController.text.trim());

  bool get _isValid =>
      _nameController.text.trim().length >= 2 && _isPhoneValid;

  void _handleSubmit() {
    if (!_isValid) return;
    final phone = _phoneController.text.trim();
    widget.onCreatePlayer?.call(
      _nameController.text.trim(),
      phone.isEmpty ? null : phone,
      _selectedRole,
      _selectedBattingStyle,
      _selectedBowlingStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Name
          Text(
            'Player Name *',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('playerNameField'),
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'Enter full name',
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),

          // Phone Number (required)
          Text(
            'Phone Number *',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+91',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const Key('playerPhoneField'),
                  controller: _phoneController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          if (_phoneController.text.trim().isNotEmpty &&
              !_isPhoneValid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Enter a valid 10-digit Indian mobile number',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Role
          Text(
            'Role',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildRoleChip('Batter', 'batter'),
              _buildRoleChip('Bowler', 'bowler'),
              _buildRoleChip('All-Rounder', 'all_rounder'),
              _buildRoleChip('WK-Batter', 'wk_batter'),
            ],
          ),

          const SizedBox(height: 16),

          // Batting Style
          Text(
            'Batting Style',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildBattingChip('Right Hand', 'right_hand'),
              _buildBattingChip('Left Hand', 'left_hand'),
            ],
          ),

          const SizedBox(height: 16),

          // Bowling Style
          Text(
            'Bowling Style',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in BowlingStyle.values)
                _buildBowlingChip(
                  style.label,
                  style.name,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Add to Team button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isValid ? _handleSubmit : null,
              child: const Text('Add to Team'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRole == value,
      onSelected: (_) => setState(() => _selectedRole = value),
    );
  }

  Widget _buildBattingChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedBattingStyle == value,
      onSelected: (_) => setState(() => _selectedBattingStyle = value),
    );
  }

  Widget _buildBowlingChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedBowlingStyle == value,
      onSelected: (_) => setState(() => _selectedBowlingStyle = value),
    );
  }
}
