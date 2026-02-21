import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key, this.onSubmit});

  /// Called when user taps Create Team with valid data.
  /// Receives trimmed name, optional location, and optional logo file.
  final void Function(String name, String? location, XFile? logoFile)? onSubmit;

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _selectedLogoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    return name.length >= 2 && name.length <= 50;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedLogoFile = image);
    }
  }

  void _handleSubmit() {
    if (!_isValid) return;
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    widget.onSubmit?.call(
      name,
      location.isEmpty ? null : location,
      _selectedLogoFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
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

                    // Logo upload area
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: _selectedLogoFile != null
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: FileImage(
                                      File(_selectedLogoFile!.path),
                                    ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outline,
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 28,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Logo',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedLogoFile != null
                                ? 'Tap to change'
                                : 'Tap to upload',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Team Name
                    Text(
                      'Team Name *',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('teamNameField'),
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      maxLength: 50,
                      decoration: const InputDecoration(
                        hintText: 'Enter team name',
                        counterText: '',
                      ),
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
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: 'City, State (e.g. Ahmedabad, Gujarat)',
                        counterText: '',
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Create Team button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isValid ? _handleSubmit : null,
                  child: const Text('Create Team'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
