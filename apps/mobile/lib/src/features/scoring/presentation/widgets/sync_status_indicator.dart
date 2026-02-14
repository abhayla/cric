import 'package:flutter/material.dart';

import '../../../../shared/data/sync/sync_service.dart';

/// Compact sync status indicator for the score header.
///
/// Shows: green cloud_done (synced), orange cloud_upload with count badge
/// (pending), red cloud_off (error).
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.syncStatus,
    this.pendingCount = 0,
  });

  final SyncStatus syncStatus;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (syncStatus) {
      SyncStatus.allSynced => (Icons.cloud_done, Colors.green),
      SyncStatus.pending => (Icons.cloud_upload, Colors.orange),
      SyncStatus.error => (Icons.cloud_off, Colors.red),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        if (syncStatus == SyncStatus.pending && pendingCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '$pendingCount',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
