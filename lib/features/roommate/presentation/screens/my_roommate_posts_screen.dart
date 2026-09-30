import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/roommate_provider.dart';
import '../widgets/roommate_post_card.dart';

class MyRoommatePostsScreen extends ConsumerWidget {
  const MyRoommatePostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(myRoommatePostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tin của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: posts.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, _) {
          return Center(
            child: FilledButton.icon(
              onPressed: () {
                ref.invalidate(myRoommatePostsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: Text(error.toString()),
            ),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return _MyPostsEmpty(
              onCreate: () {
                context.push('/roommate/create');
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myRoommatePostsProvider);

              await ref.read(
                myRoommatePostsProvider.future,
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (_, index) {
                return RoommatePostCard(
                  post: items[index],
                  showStatus: true,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF009B7D),
        foregroundColor: Colors.white,
        onPressed: () {
          context.push('/roommate/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin'),
      ),
    );
  }
}

class _MyPostsEmpty extends StatelessWidget {
  const _MyPostsEmpty({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 74,
              color: Color(0xFF8EB1A8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa đăng tin nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Đăng tin để tìm người ở ghép phù hợp với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF687571),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Đăng tin ở ghép'),
            ),
          ],
        ),
      ),
    );
  }
}