import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/roommate_provider.dart';
import '../widgets/roommate_post_card.dart';

class RoommatePostsScreen extends ConsumerWidget {
  const RoommatePostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(roommatePostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Ở ghép',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.push('/roommate/mine');
            },
            child: const Text('Tin của tôi'),
          ),
        ],
      ),
      body: posts.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) {
          return _ErrorState(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(roommatePostsProvider);
            },
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(roommatePostsProvider);
              await ref.read(roommatePostsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (_, index) {
                return RoommatePostCard(
                  post: items[index],
                  onTap: () =>
                      context.push('/roommate/posts/${items[index].id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-roommate-post',
        backgroundColor: const Color(0xFF009B7D),
        foregroundColor: Colors.white,
        onPressed: () {
          context.push('/roommate/create');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Đăng tin ở ghép',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 70, color: Color(0xFF8EB1A8)),
            SizedBox(height: 14),
            Text(
              'Chưa có bài ở ghép',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Hãy là người đầu tiên đăng nhu cầu tìm người ở cùng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF687571)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Color(0xFF8EB1A8),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
