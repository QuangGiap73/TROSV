import 'package:flutter/material.dart';

class LandlordRoomEmpty extends StatelessWidget {
  const LandlordRoomEmpty({required this.onCreateRoom, super.key});

  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_work_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Chưa có phòng nào trong trạng thái này.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateRoom,
            icon: const Icon(Icons.add),
            label: const Text('Đăng phòng mới'),
          ),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
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
