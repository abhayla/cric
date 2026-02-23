import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/cricket_ball_icon.dart';

/// Phone number login page.
///
/// Allows user to select a country code and enter their phone number.
/// Validates Indian numbers with regex ^[6-9]\d{9}$.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSendOtp});

  /// Called when user taps Send OTP with a valid phone number.
  /// Receives the full phone number with country code (e.g. "+919876543210").
  final void Function(String fullPhone)? onSendOtp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  _Country _selectedCountry = _countries.first; // India

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValidPhone {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.isEmpty) return false;
    // For India, validate ^[6-9]\d{9}$
    if (_selectedCountry.code == '+91') {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
    }
    // For other countries, just check minimum length
    return phone.length >= 7;
  }

  void _handleSendOtp() {
    if (!_isValidPhone) return;
    final phone = _phoneController.text.replaceAll(' ', '');
    final fullPhone = '${_selectedCountry.code}$phone';
    widget.onSendOtp?.call(fullPhone);
  }

  void _showCountryPicker() {
    showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top branding section
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const CricketBallIcon(size: 56),
                          const SizedBox(height: 20),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Cric',
                                  style:
                                      theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: 'App',
                                  style:
                                      theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your phone number to continue',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Phone input section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              // Country code selector
                              InkWell(
                                onTap: _showCountryPicker,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.colorScheme.outline,
                                    ),
                                    borderRadius:
                                        const BorderRadius.horizontal(
                                      left: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedCountry.flag,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedCountry.code,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Phone number field
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: '98765 43210',
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(12),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                        right: Radius.circular(12),
                                      ),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom CTA section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed:
                                  _isValidPhone ? _handleSendOtp : null,
                              child: const Text('Send OTP'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              children: const [
                                TextSpan(
                                    text:
                                        'By continuing, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Country picker bottom sheet with search.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.selected,
    required this.onSelect,
  });

  final _Country selected;
  final void Function(_Country) onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<_Country> _filtered = _countries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _countries;
      } else {
        final lower = query.toLowerCase();
        _filtered = _countries
            .where((c) =>
                c.name.toLowerCase().contains(lower) || c.code.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: const InputDecoration(
                hintText: 'Search country...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Country list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                final isSelected = country.code == widget.selected.code &&
                    country.name == widget.selected.name;
                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country.name),
                  trailing: Text(
                    country.code,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => widget.onSelect(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Country model for the country code picker.
class _Country {
  const _Country(this.flag, this.name, this.code);
  final String flag;
  final String name;
  final String code;
}

/// Top 20 cricket-playing nations.
const _countries = [
  _Country('\u{1F1EE}\u{1F1F3}', 'India', '+91'),
  _Country('\u{1F1F5}\u{1F1F0}', 'Pakistan', '+92'),
  _Country('\u{1F1E7}\u{1F1E9}', 'Bangladesh', '+880'),
  _Country('\u{1F1F1}\u{1F1F0}', 'Sri Lanka', '+94'),
  _Country('\u{1F1E6}\u{1F1FA}', 'Australia', '+61'),
  _Country('\u{1F1EC}\u{1F1E7}', 'United Kingdom', '+44'),
  _Country('\u{1F1FF}\u{1F1E6}', 'South Africa', '+27'),
  _Country('\u{1F1F3}\u{1F1FF}', 'New Zealand', '+64'),
  _Country('\u{1F1E6}\u{1F1EA}', 'UAE', '+971'),
  _Country('\u{1F1FA}\u{1F1F8}', 'United States', '+1'),
  _Country('\u{1F1E8}\u{1F1E6}', 'Canada', '+1'),
  _Country('\u{1F1F3}\u{1F1F5}', 'Nepal', '+977'),
  _Country('\u{1F1E6}\u{1F1EB}', 'Afghanistan', '+93'),
  _Country('\u{1F1FF}\u{1F1FC}', 'Zimbabwe', '+263'),
  _Country('\u{1F1EE}\u{1F1EA}', 'Ireland', '+353'),
  _Country('\u{1F1F0}\u{1F1EA}', 'Kenya', '+254'),
  _Country('\u{1F1F4}\u{1F1F2}', 'Oman', '+968'),
  _Country('\u{1F1F8}\u{1F1EC}', 'Singapore', '+65'),
  _Country('\u{1F1ED}\u{1F1F0}', 'Hong Kong', '+852'),
  _Country('\u{1F1F2}\u{1F1FE}', 'Malaysia', '+60'),
];
