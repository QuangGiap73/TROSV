import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../../rooms/presentation/providers/room_providers.dart';
import '../../rooms/presentation/widgets/room_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(featuredRoomsProvider);
    final favorites = ref.watch(favoritesProvider).asData?.value ?? const [];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrọSV'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(featuredRoomsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tìm một nơi ở thật phù hợp',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Giá rõ ràng, thông tin minh bạch và đặt lịch nhanh chóng.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              readOnly: true,
              onTap: () => context.go('/search'),
              decoration: const InputDecoration(
                hintText: 'Bạn muốn tìm phòng ở đâu?',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.tune),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Phòng trọ nổi bật',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/search'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            rooms.when(
              loading: () => const _RoomLoading(),
              error: (error, _) => _RoomError(
                onRetry: () => ref.invalidate(featuredRoomsProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const _RoomEmpty();
                return Column(
                  children: items
                      .map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RoomCard(
                            room: room,
                            isFavorite: favorites.any(
                              (favorite) => favorite.id == room.id,
                            ),
                            onTap: () => context.push('/rooms/${room.id}'),
                            onFavoritePressed: () async {
                              final authState = ref.read(
                                authControllerProvider,
                              );
                              var session = authState.asData?.value;
                              if (authState.isLoading) {
                                try {
                                  session = await ref.read(
                                    authControllerProvider.future,
                                  );
                                } catch (_) {
                                  session = null;
                                }
                              }
                              if (session == null && context.mounted) {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .clearError();
                                final loggedIn = await context.push<bool>(
                                  '/login',
                                );
                                if (loggedIn != true || !context.mounted) {
                                  return;
                                }
                                session = ref
                                    .read(authControllerProvider)
                                    .asData
                                    ?.value;
                              }
                              if (session == null || !context.mounted) return;
                              try {
                                await ref.read(favoritesProvider.future);
                                final controller = ref.read(
                                  favoritesProvider.notifier,
                                );
                                final wasFavorite = controller.isFavorite(
                                  room.id,
                                );
                                await controller.toggle(room);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        wasFavorite
                                            ? 'Đã bỏ phòng khỏi yêu thích.'
                                            : 'Đã thêm phòng vào yêu thích.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Không thể lưu phòng. Vui lòng thử lại.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomLoading extends StatelessWidget {
  const _RoomLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _RoomEmpty extends StatelessWidget {
  const _RoomEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text('Hiện chưa có phòng trọ công khai.')),
  );
}

class _RoomError extends StatelessWidget {
  const _RoomError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 52),
        const SizedBox(height: 12),
        const Text('Không thể tải danh sách phòng.'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
