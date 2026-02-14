import 'package:flutter/material.dart';

import '../../../../shared/data/websocket/websocket_client.dart';

/// Connection status banner for live match viewing.
///
/// Shows nothing when connected, progress indicator when connecting/reconnecting,
/// and error with retry button when disconnected.
class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({
    super.key,
    required this.status,
    this.onRetry,
  });

  final ConnectionStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (status) {
      ConnectionStatus.connected => const SizedBox.shrink(),
      ConnectionStatus.connecting => _buildBanner(
          theme: theme,
          color: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          text: 'Connecting...',
          showProgress: true,
        ),
      ConnectionStatus.reconnecting => _buildBanner(
          theme: theme,
          color: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          text: 'Reconnecting...',
          showProgress: true,
        ),
      ConnectionStatus.disconnected => _buildBanner(
          theme: theme,
          color: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          text: 'Disconnected',
          showRetry: onRetry != null,
        ),
    };
  }

  Widget _buildBanner({
    required ThemeData theme,
    required Color color,
    required Color textColor,
    required String text,
    bool showProgress = false,
    bool showRetry = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
          if (showRetry) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
