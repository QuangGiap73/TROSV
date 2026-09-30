import 'package:flutter/material.dart';

import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_ui.dart';

class LandlordRoomAmenityGrid extends StatelessWidget {
  const LandlordRoomAmenityGrid({required this.amenities, super.key});

  final List<LandlordRoomAmenity> amenities;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: amenities.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.03,
          ),
          itemBuilder: (_, index) {
            final item = amenities[index];
            return Container(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE5E2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    roomAmenityIcon(item.code, item.name),
                    color: const Color(0xFF263833),
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.12,
                      fontWeight: FontWeight.w500,
                      color: roomText,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
