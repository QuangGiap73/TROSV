import 'package:flutter/material.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

class LandlordRoomLoading extends StatelessWidget {
  const LandlordRoomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _RoomSkeleton(),
    );
  }
}

class LandlordRoomEmpty extends StatelessWidget {
  const LandlordRoomEmpty({required this.onCreateRoom, super.key});

  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE9F8F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 44,
                color: _greenDark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có phòng nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Hãy đăng phòng đầu tiên để bắt đầu tiếp cận người thuê.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreateRoom,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Đăng phòng mới'),
            ),
          ],
        ),
      ),
    );
  }
}

class LandlordRoomSearchEmpty extends StatelessWidget {
  const LandlordRoomSearchEmpty({
    required this.query,
    required this.onClear,
    super.key,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Color(0xFF8AA19B),
            ),
            const SizedBox(height: 13),
            const Text(
              'Không tìm thấy phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Không có kết quả phù hợp với “$query”.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _textSecondary),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onClear, child: const Text('Xóa tìm kiếm')),
          ],
        ),
      ),
    );
  }
}

class LandlordRoomError extends StatelessWidget {
  const LandlordRoomError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tải được danh sách phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 17),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomSkeleton extends StatelessWidget {
  const _RoomSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EDEB)),
      ),
      child: Row(
        children: [
          Container(
            width: 105,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFED),
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(width: 150, height: 14),
                const SizedBox(height: 9),
                _line(width: 105, height: 13),
                const SizedBox(height: 10),
                _line(width: 125, height: 10),
                const Spacer(),
                _line(width: 78, height: 23, radius: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFED),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
