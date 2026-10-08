import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../../rooms/domain/entities/room_summary.dart';
import '../../rooms/presentation/providers/room_match_provider.dart';
import '../../rooms/presentation/providers/room_providers.dart';
import '../data/university_catalog.dart';
import '../domain/university_item.dart';
import 'providers/university_explore_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/home_promo_slider.dart';
import 'widgets/home_section.dart';
import 'widgets/university_explore_section.dart';

const _homeBackground = Color(0xFFF9FAFA);
const _primary = Color(0xFF00A884);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final user = session?.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _homeBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _homeBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                color: _primary,
                edgeOffset: MediaQuery.paddingOf(context).top + 8,
                onRefresh: () async {
                  ref.invalidate(featuredRoomsProvider);

                  if (session != null) {
                    ref.invalidate(roomMatchesProvider);
                  }

                  await ref.read(featuredRoomsProvider.future);

                  if (session != null) {
                    try {
                      await ref.read(roomMatchesProvider.future);
                    } catch (_) {
                      // Home vẫn hiển thị danh sách phòng công khai
                      // nếu matching tạm thời không khả dụng.
                    }
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        userName: user?.name,
                        onLocationTap: () =>
                            _comingSoon(context, 'Chọn khu vực'),
                        onNotificationTap: () async {
                          if (session == null) {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();

                            final loggedIn = await context.push<bool>('/login');

                            if (loggedIn != true || !context.mounted) {
                              return;
                            }
                          }

                          if (context.mounted) {
                            context.push('/notifications');
                          }
                        },
                        onSearchTap: () => context.go('/search'),
                        onFindRoomTap: () => context.go('/search'),
                        onRoommateTap: () => context.go('/roommate'),
                        onMapTap: () => context.push('/rooms/map'),
                        onNewRoomTap: () {
                          final uri = Uri(
                            path: '/search',
                            queryParameters: const {'sort': 'NEWEST'},
                          );
                          context.go(uri.toString());
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: HomePromoSlider(
                        onFindRoomTap: () => context.go('/search'),
                        onRoommateTap: () => context.go('/roommate'),
                        onNewRoomTap: () {
                          final uri = Uri(
                            path: '/search',
                            queryParameters: const {'sort': 'NEWEST'},
                          );
                          context.go(uri.toString());
                        },
                      ),
                    ),

                    const _UniversityExploreSliver(),

                    _HomeRoomsSliver(sessionAvailable: session != null),
                  ],
                ),
              ),
            ),
            _PreferenceChatButton(
              onTap: () => _openPreferenceChat(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _roomDate(RoomSummary room) {
    return room.publishedAt ?? room.createdAt ?? DateTime(2000);
  }

  static Future<void> _openUniversity(
    BuildContext context,
    WidgetRef ref,
    UniversityItem university,
  ) async {
    final target = await ref
        .read(universityExploreProvider.notifier)
        .resolve(university);

    if (!context.mounted) return;

    if (target == null) {
      final error = ref.read(universityExploreProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString() ?? 'Không thể xác định vị trí của trường.',
          ),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () => _openUniversity(context, ref, university),
          ),
        ),
      );
      return;
    }

    final uri = Uri(
      path: '/search',
      queryParameters: {
        'title': 'Trọ quanh ${target.university.name}',
        'focus': target.university.name,
        'lat': target.latitude.toString(),
        'lng': target.longitude.toString(),
        'radius': target.university.defaultRadiusMeters.toString(),
        'sort': 'DISTANCE',
      },
    );

    context.go(uri.toString());
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature đang được phát triển.')));
  }

  static Future<void> _openPreferenceChat(
    BuildContext context,
    WidgetRef ref,
  ) async {
    var session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) return;
      session = ref.read(authControllerProvider).asData?.value;
    }
    if (session != null && context.mounted) {
      context.push('/profile/preferences');
    }
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

      if (loggedIn != true || !context.mounted) {
        return;
      }

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

class _PreferenceChatButton extends StatefulWidget {
  const _PreferenceChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PreferenceChatButton> createState() => _PreferenceChatButtonState();
}

class _PreferenceChatButtonState extends State<_PreferenceChatButton> {
  static const _buttonSize = 58.0;
  double _right = 16;
  double _bottom = 16;

  ({double right, double bottom}) _clampPosition(
    BuildContext context, {
    required double right,
    required double bottom,
  }) {
    final media = MediaQuery.of(context);
    final maxRight = media.size.width - _buttonSize - 8;
    final maxBottom =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        _buttonSize -
        82;
    return (
      right: right.clamp(8.0, maxRight < 8 ? 8.0 : maxRight).toDouble(),
      bottom: bottom.clamp(8.0, maxBottom < 8 ? 8.0 : maxBottom).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = _clampPosition(context, right: _right, bottom: _bottom);
    return Positioned(
      right: position.right,
      bottom: position.bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final next = _clampPosition(
            context,
            right: _right - details.delta.dx,
            bottom: _bottom - details.delta.dy,
          );
          setState(() {
            _right = next.right;
            _bottom = next.bottom;
          });
        },
        child: Semantics(
          button: true,
          label: 'Mở trợ lý tìm trọ. Có thể kéo để thay đổi vị trí.',
          child: Tooltip(
            message: 'Trợ lý tìm trọ • Giữ và kéo để di chuyển',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: _buttonSize,
                  height: _buttonSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF19BEA2), Color(0xFF008E78)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: .32),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                      Positioned(
                        top: 17,
                        child: Icon(
                          Icons.home_rounded,
                          color: _primary,
                          size: 13,
                        ),
                      ),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A34),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UniversityExploreSliver extends ConsumerWidget {
  const _UniversityExploreSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(universityExploreProvider);
    final loadingId = state.isLoading
        ? ref.read(universityExploreProvider.notifier).resolvingUniversityId
        : null;
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: UniversityExploreSection(
          universities: universityCatalog,
          loadingUniversityId: loadingId,
          onUniversityTap: (university) =>
              HomeScreen._openUniversity(context, ref, university),
        ),
      ),
    );
  }
}

class _HomeRoomsSliver extends ConsumerWidget {
  const _HomeRoomsSliver({required this.sessionAvailable});

  final bool sessionAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(featuredRoomsProvider);
    final favorites =
        ref.watch(favoritesProvider).asData?.value ?? const <RoomSummary>[];
    final matches = sessionAvailable ? ref.watch(roomMatchesProvider) : null;

    return rooms.when(
      loading: () => const SliverToBoxAdapter(child: _RoomLoading()),
      error: (_, _) => SliverToBoxAdapter(
        child: _RoomError(onRetry: () => ref.invalidate(featuredRoomsProvider)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: _RoomEmpty());
        }
        final newestRooms = [...items]
          ..sort(
            (a, b) =>
                HomeScreen._roomDate(b).compareTo(HomeScreen._roomDate(a)),
          );
        final favoriteIds = favorites.map((room) => room.id).toSet();
        final matchedRooms = matches?.asData?.value
            .map((match) => match.room)
            .toList(growable: false);
        final suggested = matchedRooms?.isNotEmpty == true
            ? matchedRooms!
            : items;

        return SliverList.list(
          children: [
            RepaintBoundary(
              child: HomeRoomSection(
                title: 'Gợi ý cho bạn',
                rooms: suggested.take(8).toList(growable: false),
                favoriteIds: favoriteIds,
                onSeeAll: () => context.go('/search'),
                onRoomTap: (room) => context.push('/rooms/${room.id}'),
                onFavoriteTap: (room) =>
                    HomeScreen._toggleFavorite(context, ref, room),
              ),
            ),
            RepaintBoundary(
              child: HomeRoomSection(
                title: 'Phòng mới đăng',
                rooms: newestRooms.take(8).toList(growable: false),
                favoriteIds: favoriteIds,
                onSeeAll: () => context.go('/search?sort=NEWEST'),
                onRoomTap: (room) => context.push('/rooms/${room.id}'),
                onFavoriteTap: (room) =>
                    HomeScreen._toggleFavorite(context, ref, room),
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

class _RoomLoading extends StatelessWidget {
  const _RoomLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
      ),
    );
  }
}

class _RoomEmpty extends StatelessWidget {
  const _RoomEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: Text(
          'Hiện chưa có phòng trọ công khai.',
          style: TextStyle(color: Color(0xFF687571)),
        ),
      ),
    );
  }
}

class _RoomError extends StatelessWidget {
  const _RoomError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFF8AA39D),
          ),
          const SizedBox(height: 10),
          const Text('Không thể tải danh sách phòng.'),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
