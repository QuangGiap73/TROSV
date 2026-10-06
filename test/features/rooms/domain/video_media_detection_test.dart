import 'package:flutter_test/flutter_test.dart';
import 'package:trosv_app/features/landlord/rooms/domain/entities/landlord_room_detail.dart';
import 'package:trosv_app/features/rooms/domain/entities/room_detail.dart';
import 'package:trosv_app/features/rooms/domain/entities/room_summary.dart';

void main() {
  const videoUrl = 'https://cdn.example.com/rooms/demo/video.MP4?token=abc';
  const imageUrl = 'https://cdn.example.com/rooms/demo/photo.webp';

  test('room detail detects a video even when API labels it as IMAGE', () {
    final room = RoomDetail.fromJson({
      'id': 'room-1',
      'media': [
        {'media_type': 'IMAGE', 'public_url': imageUrl},
        {'media_type': 'IMAGE', 'public_url': videoUrl},
      ],
    });

    expect(room.imageUrls, [imageUrl]);
    expect(room.videoUrls, [videoUrl]);
  });

  test('room summary removes video URLs from images and reports video', () {
    final room = RoomSummary.fromJson({
      'id': 'room-1',
      'image_urls': [imageUrl, videoUrl],
      'has_video': false,
    });

    expect(room.imageUrls, [imageUrl]);
    expect(room.hasVideo, isTrue);
  });

  test('landlord media detects a mislabeled video from its URL', () {
    const media = LandlordRoomMedia(
      id: 'media-1',
      roomId: 'room-1',
      mediaType: 'IMAGE',
      isPrimary: false,
      sortOrder: 1,
      publicUrl: videoUrl,
    );

    expect(media.isVideo, isTrue);
  });
}
