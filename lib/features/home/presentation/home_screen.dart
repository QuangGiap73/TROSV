import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../../rooms/domain/entities/room_summary.dart';
import '../../rooms/presentation/providers/room_providers.dart';
import '../../rooms/presentation/providers/room_match_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/home_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(featuredRoomsProvider);
    final favorites = ref.watch(favoritesProvider).asData?.value ?? const [];
    final session = ref.watch(authControllerProvider).asData?.value;
    final user = session?.user;
    final roomMatches = session == null ? null : ref.watch(roomMatchesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      body: RefreshIndicator(
        color: const Color(0xFF008E79),
        onRefresh: () async {
          ref.invalidate(featuredRoomsProvider);
          if (session != null) ref.invalidate(roomMatchesProvider);

          await ref.read(featuredRoomsProvider.future);
          if (session != null) {
            try {
              await ref.read(roomMatchesProvider.future);
            } catch (_) {
              // Home vẫn hiển thị phòng công khai nếu chưa có nhu cầu hoặc
              // dịch vụ gợi ý tạm thời không khả dụng.
            }
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                userName: user?.name,
                onLocationTap: () => _comingSoon(context, 'Chọn khu vực'),
                onNotificationTap: () => _comingSoon(context, 'Thông báo'),
                onSearchTap: () => context.go('/search'),
                onFindRoomTap: () => context.go('/search'),
                onRoommateTap: () => context.go('/roommate'),
                onMapTap: () => context.push('/rooms/map'),
                onNewRoomTap: () => context.go('/search'),
              ),
            ),
            rooms.when(
              loading: () => const SliverToBoxAdapter(child: _RoomLoading()),
              error: (_, _) => SliverToBoxAdapter(
                child: _RoomError(
                  onRetry: () => ref.invalidate(featuredRoomsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverToBoxAdapter(child: _RoomEmpty());
                }

                final newestRooms = [...items]
                  ..sort((a, b) => _roomDate(b).compareTo(_roomDate(a)));
                final favoriteIds = favorites.map((room) => room.id).toSet();
                final matchedRooms = roomMatches?.asData?.value
                    .map((match) => match.room)
                    .toList();
                final suggestedRooms =
                    matchedRooms != null && matchedRooms.isNotEmpty
                    ? matchedRooms
                    : items;

                return SliverList.list(
                  children: [
                    HomeRoomSection(
                      title: 'Gợi ý cho bạn',
                      rooms: suggestedRooms.take(8).toList(),
                      favoriteIds: favoriteIds,
                      onSeeAll: () => context.go('/search'),
                      onRoomTap: (room) => context.push('/rooms/${room.id}'),
                      onFavoriteTap: (room) =>
                          _toggleFavorite(context, ref, room),
                    ),
                    HomeRoomSection(
                      title: 'Phòng mới đăng',
                      rooms: newestRooms.take(8).toList(),
                      favoriteIds: favoriteIds,
                      onSeeAll: () => context.go('/search'),
                      onRoomTap: (room) => context.push('/rooms/${room.id}'),
                      onFavoriteTap: (room) =>
                          _toggleFavorite(context, ref, room),
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _roomDate(RoomSummary room) {
    return room.publishedAt ?? room.createdAt ?? DateTime(2000);
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature đang được phát triển.')));
  }

  static Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    RoomSummary room,
  ) async {
    final authState = ref.read(authControllerProvider);
    var session = authState.asData?.value;

    if (authState.isLoading) {
      try {
        session = await ref.read(authControllerProvider.future);
      } catch (_) {
        session = null;
      }
    }

    if (session == null && context.mounted) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) return;
      session = ref.read(authControllerProvider).asData?.value;
    }

    if (session == null || !context.mounted) return;

    try {
      await ref.read(favoritesProvider.future);
      final controller = ref.read(favoritesProvider.notifier);
      final wasFavorite = controller.isFavorite(room.id);
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
            content: Text('Không thể lưu phòng. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }
}

class _RoomLoading extends StatelessWidget {
  const _RoomLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 70),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _RoomEmpty extends StatelessWidget {
  const _RoomEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
    child: Center(child: Text('Hiện chưa có phòng trọ công khai.')),
  );
}

class _RoomError extends StatelessWidget {
  const _RoomError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 10),
        const Text('Không thể tải danh sách phòng.'),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
