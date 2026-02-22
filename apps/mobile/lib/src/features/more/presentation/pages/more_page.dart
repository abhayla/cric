import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Tournaments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.tournaments),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.about),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.help),
          ),
        ],
      ),
    );
  }
}
