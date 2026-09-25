import 'package:flutter/material.dart';

import '../../../rooms/domain/entities/room_summary.dart';
import 'home_room_card.dart';

class HomeRoomSection extends StatelessWidget {
  const HomeRoomSection({
    required this.title,
    required this.rooms,
    required this.favoriteIds,
    required this.onSeeAll,
    required this.onRoomTap,
    required this.onFavoriteTap,
    super.key,
  });

  final String title;
  final List<RoomSummary> rooms;
  final Set<String> favoriteIds;
  final VoidCallback onSeeAll;
  final ValueChanged<RoomSummary> onRoomTap;
  final ValueChanged<RoomSummary> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17201E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF008E79),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return HomeRoomCard(
                  room: room,
                  isFavorite: favoriteIds.contains(room.id),
                  onTap: () => onRoomTap(room),
                  onFavoriteTap: () => onFavoriteTap(room),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
