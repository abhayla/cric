import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/team_repository.dart';
import '../../providers.dart';

class AddPlayerPage extends StatefulWidget {
  const AddPlayerPage({
    super.key,
    required this.teamId,
    this.onCreatePlayer,
    this.onAddExisting,
  });

  final String teamId;

  /// Called when creating a new player.
  final Future<void> Function(
    String name,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  )?
  onCreatePlayer;

  /// Called when adding an existing player by ID.
  final Future<void> Function(String playerId)? onAddExisting;

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
            _SearchTab(onAddExisting: widget.onAddExisting),
            _CreateTab(onCreatePlayer: widget.onCreatePlayer),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab({this.onAddExisting});

  final Future<void> Function(String playerId)? onAddExisting;

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _phoneController = TextEditingController();
  AsyncValue<PlayerSearchResult?>? _searchResult;
  bool _isAdding = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAddExisting(String playerId) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      await widget.onAddExisting?.call(playerId);
    } catch (_) {
      // Error handling is in the callback (router shows SnackBar)
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _handleSearch() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) return;

    setState(() => _searchResult = const AsyncValue.loading());

    try {
      final result = await ref
          .read(teamRepositoryProvider)
          .searchPlayerByPhone('+91$phone');
      if (!mounted) return;
      setState(() => _searchResult = AsyncValue.data(result));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _searchResult = AsyncValue.error(e, st));
    }
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
                child: Text('+91', style: theme.textTheme.bodyMedium),
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
              onPressed: _handleSearch,
              child: const Text('Search'),
            ),
          ),
          if (_searchResult != null) ...[
            const SizedBox(height: 24),
            _searchResult!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, st) => Text(
                'Search failed. Please try again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (player) => player == null
                  ? Text(
                      'No player found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : _PlayerResultCard(
                      player: player,
                      onAdd: _isAdding
                          ? null
                          : () => _handleAddExisting(player.id),
                    ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 24),
        ],
      ),
    );
  }
}

class _PlayerResultCard extends StatelessWidget {
  const _PlayerResultCard({required this.player, this.onAdd});

  final PlayerSearchResult player;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (player.playerRole != null) ...[
              const SizedBox(height: 4),
              Text(
                player.playerRole!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAdd,
                child: const Text('Add to Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTab extends StatefulWidget {
  const _CreateTab({this.onCreatePlayer});

  final Future<void> Function(
    String name,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  )?
  onCreatePlayer;

  @override
  State<_CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends State<_CreateTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'batter';
  String _selectedBattingStyle = 'right_hand';
  String _selectedBowlingStyle = 'right_arm_medium';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  bool get _isPhoneValid => _phoneRegex.hasMatch(_phoneController.text.trim());

  bool get _isValid => _nameController.text.trim().length >= 2 && _isPhoneValid;

  Future<void> _handleSubmit() async {
    if (!_isValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final phone = _phoneController.text.trim();
      await widget.onCreatePlayer?.call(
        _nameController.text.trim(),
        phone.isEmpty ? null : '+91$phone',
        _selectedRole,
        _selectedBattingStyle,
        _selectedBowlingStyle,
      );
    } catch (_) {
      // Error handling is in the callback (router shows SnackBar)
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                child: Text('+91', style: theme.textTheme.bodyMedium),
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
          if (_phoneController.text.trim().isNotEmpty && !_isPhoneValid)
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
                _buildBowlingChip(style.label, style.apiValue),
            ],
          ),

          const SizedBox(height: 24),

          // Add to Team button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isValid && !_isSubmitting ? _handleSubmit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add to Team'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 24),
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
