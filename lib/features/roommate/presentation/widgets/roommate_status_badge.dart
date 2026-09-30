import 'package:flutter/material.dart';

class RoommateStatusBadge extends StatelessWidget {
  const RoommateStatusBadge({
    required this.status,
    super.key,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final configuration = switch (status) {
      'ACTIVE' => (
          'Đang hiển thị',
          const Color(0xFF008F72),
          const Color(0xFFE2F7F1),
        ),
      'PENDING_REVIEW' => (
          'Chờ duyệt',
          const Color(0xFFE89100),
          const Color(0xFFFFF3D8),
        ),
      'REJECTED' => (
          'Bị từ chối',
          const Color(0xFFE5484D),
          const Color(0xFFFFE8E9),
        ),
      'CLOSED' => (
          'Đã đóng',
          const Color(0xFF687571),
          const Color(0xFFEDF1F0),
        ),
      _ => (
          status,
          const Color(0xFF687571),
          const Color(0xFFEDF1F0),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: configuration.$3,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        configuration.$1,
        style: TextStyle(
          fontSize: 10,
          color: configuration.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}