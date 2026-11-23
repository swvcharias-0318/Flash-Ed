import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      (user?.displayName?.isNotEmpty ?? false)
                          ? user!.displayName![0].toUpperCase()
                          : 'S',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName?.isNotEmpty ?? false
                              ? user!.displayName!
                              : 'Student',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(user?.email ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (user?.isGuest != true)
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Reset password'),
              subtitle: const Text('We will send a reset link to your email.'),
              onTap: () => context.push('/reset-password'),
            )
          else
            const ListTile(
              leading: Icon(Icons.phone_android_rounded),
              title: Text('Local guest mode'),
              subtitle: Text(
                'Flashcards and progress are stored on this device only.',
              ),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Flash-Ed'),
            subtitle: const Text('Learn. Create. Review. Master.'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(user?.isGuest == true ? 'Exit local mode' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}
