import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../providers/room_match_provider.dart';
import '../widgets/room_match_card.dart';

class RoomMatchScreen extends ConsumerWidget {
  const RoomMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(roomMatchesProvider);
    final favorites = ref.watch(favoritesProvider).asData?.value ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Phòng phù hợp'),
        backgroundColor: const Color(0xFFF5F8F7),
        surfaceTintColor: Colors.transparent,
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(roomMatchesProvider);
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyView(
              onEditPreference: () {
                context.push('/profile/preferences');
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(roomMatchesProvider.notifier).reload();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _ResultHeader(resultCount: items.length),
                const SizedBox(height: 16),
                ...items.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: RoomMatchCard(
                      match: match,
                      isFavorite: favorites.any(
                        (room) => room.id == match.room.id,
                      ),
                      onTap: () {
                        context.push('/rooms/${match.room.id}');
                      },
                      onFavoritePressed: () async {
                        try {
                          await ref.read(favoritesProvider.future);

                          await ref
                              .read(favoritesProvider.notifier)
                              .toggle(match.room);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật danh sách yêu thích.'),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Không thể cập nhật yêu thích: $error',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.resultCount});

  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDDF6EF), Color(0xFFF3FBF8)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.auto_awesome, color: Color(0xFF008E78)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tìm thấy $resultCount phòng phù hợp với nhu cầu của bạn.',
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onEditPreference});

  final VoidCallback onEditPreference;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF718096),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có phòng phù hợp',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn có thể tăng ngân sách, mở rộng bán kính hoặc giảm bớt tiện ích yêu cầu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onEditPreference,
              icon: const Icon(Icons.tune),
              label: const Text('Điều chỉnh nhu cầu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 58,
              color: Color(0xFF718096),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tìm phòng phù hợp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
