import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';

/// Profile setup page for new users.
///
/// Collects display name, playing role, batting/bowling style,
/// and optional location. Shows initials avatar.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, this.onSave});

  /// Called when user taps Save with complete profile data.
  final void Function(ProfileFormData data)? onSave;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

/// Form data collected from profile setup.
class ProfileFormData {
  const ProfileFormData({
    required this.displayName,
    required this.playerRole,
    required this.battingStyle,
    this.bowlingStyle,
    this.location,
  });

  final String displayName;
  final PlayerRole playerRole;
  final BattingStyle battingStyle;
  final BowlingStyle? bowlingStyle;
  final String? location;
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  PlayerRole? _playerRole;
  BattingStyle _battingStyle = BattingStyle.rightHand;
  BowlingStyle? _bowlingStyle;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    return name.length >= 2 && name.length <= 50 && _playerRole != null;
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  void _handleSave() {
    if (!_isValid) return;
    widget.onSave?.call(ProfileFormData(
      displayName: _nameController.text.trim(),
      playerRole: _playerRole!,
      battingStyle: _battingStyle,
      bowlingStyle: _bowlingStyle,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Avatar with initials
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              _initials.isEmpty ? 'Photo' : _initials,
                              style: _initials.isEmpty
                                  ? theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    )
                                  : theme.textTheme.headlineMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Optional',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Display Name
                    Text(
                      'Display Name *',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      maxLength: 50,
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        counterText: '',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Playing Role
                    Text(
                      'Playing Role *',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PlayerRole>(
                      value: _playerRole,
                      onChanged: (value) =>
                          setState(() => _playerRole = value),
                      decoration: const InputDecoration(
                        hintText: 'Select your role',
                      ),
                      items: PlayerRole.values
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.label),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Batting Style
                    Text(
                      'Batting Style *',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: BattingStyle.values.map((style) {
                        final isSelected = _battingStyle == style;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  style == BattingStyle.rightHand ? 8 : 0,
                              left: style == BattingStyle.leftHand ? 8 : 0,
                            ),
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  style.label,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _battingStyle = style),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Bowling Style
                    Text(
                      'Bowling Style',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BowlingStyle>(
                      value: _bowlingStyle,
                      onChanged: (value) =>
                          setState(() => _bowlingStyle = value),
                      decoration: const InputDecoration(
                        hintText: 'Select bowling style',
                      ),
                      items: BowlingStyle.values
                          .map((style) => DropdownMenuItem(
                                value: style,
                                child: Text(style.label),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'Location',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'City, State (e.g. Mumbai, Maharashtra)',
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isValid ? _handleSave : null,
                  child: const Text('Save & Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
