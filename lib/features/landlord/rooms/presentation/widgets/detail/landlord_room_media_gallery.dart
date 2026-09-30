import 'package:flutter/material.dart';

import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_ui.dart';

class LandlordRoomMediaGallery extends StatefulWidget {
  const LandlordRoomMediaGallery({required this.room, super.key});

  final LandlordRoomDetail room;

  @override
  State<LandlordRoomMediaGallery> createState() =>
      _LandlordRoomMediaGalleryState();
}

class _LandlordRoomMediaGalleryState extends State<LandlordRoomMediaGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.room.images
        .map((item) => item.displayUrl)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: true);

    if (urls.isEmpty && widget.room.imageUrl?.trim().isNotEmpty == true) {
      urls.add(widget.room.imageUrl!);
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (urls.isEmpty)
              const ColoredBox(
                color: Color(0xFFE4F2EF),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 68,
                  color: Color(0xFF7BA89E),
                ),
              )
            else
              PageView.builder(
                itemCount: urls.length,
                onPageChanged: (value) {
                  if (_index == value) return;
                  setState(() => _index = value);
                },
                itemBuilder: (_, index) {
                  return Image.network(
                    urls[index],
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const ColoredBox(
                        color: Color(0xFFEAF2F0),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: roomGreen,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) {
                      return const ColoredBox(
                        color: Color(0xFFE4F2EF),
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 46,
                          color: Color(0xFF7BA89E),
                        ),
                      );
                    },
                  );
                },
              ),
            if (urls.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 11,
                child: _OverlayLabel(text: '${_index + 1}/${urls.length}'),
              ),
            if (widget.room.videos.isNotEmpty)
              Positioned(
                left: 12,
                bottom: 11,
                child: _OverlayLabel(
                  text: '${widget.room.videos.length} video',
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
