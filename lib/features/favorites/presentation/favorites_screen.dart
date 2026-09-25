import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../rooms/presentation/widgets/room_card.dart';
import 'providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng đã lưu')),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : session == null
          ? const _LoginRequired()
          : _FavoritesContent(ref: ref),
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  const _FavoritesContent({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          _FavoritesError(onRetry: () => ref.invalidate(favoritesProvider)),
      data: (rooms) {
        if (rooms.isEmpty) return const _FavoritesEmpty();
        return RefreshIndicator(
          onRefresh: () => ref.read(favoritesProvider.notifier).reload(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return RoomCard(
                room: room,
                isFavorite: true,
                onTap: () => context.push('/rooms/${room.id}'),
                onFavoritePressed: () async {
                  try {
                    await ref.read(favoritesProvider.notifier).remove(room.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã bỏ phòng khỏi yêu thích.'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không thể bỏ yêu thích. Hãy thử lại.'),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập để xem phòng đã lưu',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    ),
  );
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa lưu phòng nào',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy khám phá và nhấn biểu tượng trái tim trên phòng bạn thích.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Khám phá phòng'),
          ),
        ],
      ),
    ),
  );
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 56),
        const SizedBox(height: 12),
        const Text('Không thể tải danh sách yêu thích.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
