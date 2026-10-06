import 'package:flutter/material.dart';

import '../../../../../rooms/presentation/widgets/network_video_player.dart';
import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_ui.dart';

class LandlordRoomMediaTab extends StatelessWidget {
  const LandlordRoomMediaTab({
    required this.room,
    required this.onRefresh,
    required this.onEdit,
    super.key,
  });

  final LandlordRoomDetail room;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final urls = room.images
        .map((item) => item.displayUrl)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: true);

    if (urls.isEmpty && room.imageUrl?.trim().isNotEmpty == true) {
      urls.add(room.imageUrl!);
    }

    return RefreshIndicator(
      color: roomGreen,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('landlord-room-media'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          LandlordRoomSectionCard(
            title: 'Hình ảnh',
            subtitle: '${urls.length} ảnh',
            icon: Icons.photo_library_outlined,
            child: urls.isEmpty
                ? const _EmptyMedia(
                    icon: Icons.photo_outlined,
                    text: 'Phòng chưa có hình ảnh.',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: urls.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (_, index) {
                      return _ImageTile(
                        url: urls[index],
                        primary: index == 0,
                        onTap: () => _showImage(context, urls[index]),
                      );
                    },
                  ),
          ),
          LandlordRoomSectionCard(
            title: 'Video',
            subtitle: '${room.videos.length} video',
            icon: Icons.play_circle_outline_rounded,
            child: room.videos.isEmpty
                ? const _EmptyMedia(
                    icon: Icons.videocam_outlined,
                    text: 'Phòng chưa có video.',
                  )
                : Column(
                    children: [
                      for (var index = 0; index < room.videos.length; index++)
                        if (room.videos[index].displayUrl case final url?) ...[
                          NetworkVideoPlayer(
                            key: ValueKey(url),
                            url: url,
                          ),
                          if (index < room.videos.length - 1)
                            const SizedBox(height: 12),
                        ],
                    ],
                  ),
          ),
          OutlinedButton.icon(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: roomGreenDark,
              side: const BorderSide(color: roomGreen),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Chỉnh sửa hình ảnh & video',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImage(BuildContext context, String url) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(child: Image.network(url, fit: BoxFit.contain)),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton.filled(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.url,
    required this.primary,
    required this.onTap,
  });

  final String url;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF2F0),
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) {
                return const Center(
                  child: Icon(Icons.broken_image_outlined, color: roomMuted),
                );
              },
            ),
            if (primary)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roomGreenDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ảnh đại diện',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF9AA9A5)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: roomMuted)),
        ],
      ),
    );
  }
}
