import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';

class LandlordProfileScreen extends ConsumerWidget {
  const LandlordProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản chủ trọ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person_outline, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Chủ trọ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(user?.phone ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 24),

          if (user?.hasTenantRole == true)
            OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final success = await ref
                          .read(authControllerProvider.notifier)
                          .switchActiveMode('TENANT');

                      if (success && context.mounted) {
                        context.go('/');
                      }
                    },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Chuyển sang chế độ người thuê'),
            ),

          const SizedBox(height: 12),

          FilledButton.tonalIcon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).logout();

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
