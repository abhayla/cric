import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/providers.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        children: [
          // My Profile
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (userId != null) {
                context.push(AppRoutes.playerProfilePath(userId));
              }
            },
          ),
          const Divider(height: 1),
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
