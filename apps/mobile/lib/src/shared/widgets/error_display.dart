import 'package:flutter/material.dart';

import '../../core/errors/exceptions.dart';

/// Maps errors to user-friendly messages and shows a retry button.
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  String get _userMessage {
    if (error is NetworkException) {
      return 'Check your internet connection and try again.';
    }
    if (error is AuthException) {
      return 'Session expired. Please log in again.';
    }
    if (error is ServerException) {
      final statusCode = (error as ServerException).statusCode;
      if (statusCode == null) return 'Something went wrong. Please try again.';
      return switch (statusCode) {
        401 => 'Session expired. Please log in again.',
        403 => 'You don\'t have permission for this action.',
        404 => 'The requested data was not found.',
        >= 500 => 'Something went wrong on our end. Please try again.',
        _ => 'Something went wrong. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _userMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
