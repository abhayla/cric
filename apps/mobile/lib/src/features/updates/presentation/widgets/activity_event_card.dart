import 'package:flutter/material.dart';

import '../../domain/entities/activity_event.dart';

class ActivityEventCard extends StatelessWidget {
  const ActivityEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final ActivityEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _iconColor(theme).withValues(alpha: 0.1),
        child: Icon(
          _iconData,
          color: _iconColor(theme),
          size: 20,
        ),
      ),
      title: Text(
        event.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: event.isRead ? FontWeight.normal : FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.description != null) ...[
            const SizedBox(height: 2),
            Text(
              event.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            _relativeTime(event.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: event.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
    );
  }

  IconData get _iconData => switch (event.iconType) {
        IconType.match => Icons.sports_cricket,
        IconType.team => Icons.groups,
        IconType.tournament => Icons.emoji_events,
        IconType.milestone => Icons.star,
        IconType.general => Icons.notifications,
      };

  Color _iconColor(ThemeData theme) => switch (event.iconType) {
        IconType.match => Colors.green,
        IconType.team => Colors.blue,
        IconType.tournament => Colors.orange,
        IconType.milestone => Colors.purple,
        IconType.general => theme.colorScheme.primary,
      };

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
