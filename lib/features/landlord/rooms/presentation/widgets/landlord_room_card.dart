import 'package:flutter/material.dart';

import '../../domain/entities/landlord_room.dart';

enum LandlordRoomAction {
  submit,
  show,
  hide,
  confirmAvailability,
  markRented,
  unmarkRented,
  delete,
}

class LandlordRoomCard extends StatelessWidget {
  const LandlordRoomCard({
    required this.room,
    required this.onAction,
    super.key,
  });

  final LandlordRoom room;
  final ValueChanged<LandlordRoomAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _availableActions(room.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 92,
                height: 92,
                child: room.imageUrl == null || room.imageUrl!.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFE8F4F1),
                        child: Icon(Icons.home_work_outlined, size: 34),
                      )
                    : Image.network(
                        room.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE8F4F1),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (actions.isNotEmpty)
                        PopupMenuButton<LandlordRoomAction>(
                          padding: EdgeInsets.zero,
                          onSelected: onAction,
                          itemBuilder: (_) => actions
                              .map(
                                (action) => PopupMenuItem(
                                  value: action,
                                  child: Text(_actionLabel(action)),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_money(room.priceMonthly)} đ/tháng',
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${room.areaM2.toStringAsFixed(0)} m² · Tối đa ${room.maxPeople} người',
                  ),
                  if (room.fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      room.fullAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _StatusChip(status: room.status),
                  if (room.rejectionReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Lý do từ chối: ${room.rejectionReason}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'DRAFT' => ('Bản nháp', Colors.blueGrey),
      'PENDING_REVIEW' => ('Chờ duyệt', Colors.orange),
      'PUBLISHED' => ('Đang hiển thị', Colors.green),
      'REJECTED' => ('Bị từ chối', Colors.red),
      'HIDDEN' => ('Đã ẩn', Colors.grey),
      'RENTED' => ('Đã cho thuê', Colors.indigo),
      'CANCELLED' => ('Đã hủy', Colors.brown),
      _ => (status, Colors.grey),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      ),
    );
  }
}

List<LandlordRoomAction> _availableActions(String status) => switch (status) {
  'DRAFT' ||
  'REJECTED' => const [LandlordRoomAction.submit, LandlordRoomAction.delete],
  'PUBLISHED' => const [
    LandlordRoomAction.confirmAvailability,
    LandlordRoomAction.hide,
    LandlordRoomAction.markRented,
  ],
  'HIDDEN' => const [LandlordRoomAction.show, LandlordRoomAction.delete],
  'RENTED' => const [LandlordRoomAction.unmarkRented],
  'CANCELLED' => const [LandlordRoomAction.delete],
  _ => const [],
};

String _actionLabel(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => 'Gửi duyệt',
  LandlordRoomAction.show => 'Hiện phòng',
  LandlordRoomAction.hide => 'Ẩn phòng',
  LandlordRoomAction.confirmAvailability => 'Xác nhận còn trống',
  LandlordRoomAction.markRented => 'Đánh dấu đã thuê',
  LandlordRoomAction.unmarkRented => 'Đánh dấu còn trống',
  LandlordRoomAction.delete => 'Xóa phòng',
};

String _money(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}
