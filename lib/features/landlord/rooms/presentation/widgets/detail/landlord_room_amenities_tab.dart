import 'package:flutter/material.dart';

import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_amenity_grid.dart';
import 'landlord_room_ui.dart';

class LandlordRoomAmenitiesTab extends StatelessWidget {
  const LandlordRoomAmenitiesTab({
    required this.room,
    required this.onRefresh,
    super.key,
  });

  final LandlordRoomDetail room;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: roomGreen,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('landlord-room-amenities'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          LandlordRoomSectionCard(
            title: 'Tiện ích phòng',
            subtitle: room.amenities.isEmpty
                ? 'Chưa cập nhật'
                : '${room.amenities.length} tiện ích',
            icon: Icons.weekend_outlined,
            child: room.amenities.isEmpty
                ? const _EmptyAmenities()
                : LandlordRoomAmenityGrid(amenities: room.amenities),
          ),
        ],
      ),
    );
  }
}

class _EmptyAmenities extends StatelessWidget {
  const _EmptyAmenities();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(Icons.weekend_outlined, size: 38, color: Color(0xFF9BA9A6)),
          SizedBox(height: 8),
          Text(
            'Phòng chưa cập nhật tiện ích.',
            style: TextStyle(fontSize: 12, color: roomMuted),
          ),
        ],
      ),
    );
  }
}
