import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/appointment.dart';

const _greenDark = Color(0xFF008C72);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);
const _border = Color(0xFFE4ECE9);

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    required this.appointment,
    required this.landlordView,
    this.onCancel,
    this.onReschedule,
    this.onConfirm,
    this.onComplete,
    this.onTap,
    this.onLongPress,
    this.roomAddress,
    super.key,
  });

  final Appointment appointment;
  final bool landlordView;

  /// Dùng để mở màn chi tiết lịch hẹn khi bấm card.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Backend AppointmentResponse hiện chưa có room_address.
  /// Nếu sau này API trả địa chỉ hoặc màn cha lấy được địa chỉ phòng,
  /// chỉ cần truyền vào đây.
  final String? roomAddress;

  // Giữ các callback cũ để không phá code màn đang dùng AppointmentCard.
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomImage(url: appointment.roomImage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                appointment.roomTitle ?? 'Phòng trọ',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.18,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppointmentStatusBadge(status: appointment.status),
                          ],
                        ),
                        if (appointment.roomPrice != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${formatVnd(appointment.roomPrice!)}/tháng',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _greenDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoLine(
                          icon: Icons.calendar_today_outlined,
                          text:
                              '${_weekday(appointment.bookingDate)}, ${_date(appointment.bookingDate)}',
                        ),
                        const SizedBox(height: 6),
                        _InfoLine(
                          icon: Icons.schedule_rounded,
                          text: appointment.timeSlot,
                        ),
                        if (roomAddress?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          _InfoLine(
                            icon: Icons.location_on_outlined,
                            text: roomAddress!,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF84938F),
                      size: 22,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 82,
        height: 72,
        child: url == null || url!.trim().isEmpty
            ? const ColoredBox(
                color: Color(0xFFE8F4F1),
                child: Icon(
                  Icons.home_work_outlined,
                  color: Color(0xFF79A097),
                  size: 29,
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE8F4F1),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF79A097),
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.5, color: const Color(0xFF5E716C)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.25,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: config.foreground,
        ),
      ),
    );
  }
}

typedef _StatusConfig = ({String label, Color foreground, Color background});

_StatusConfig _statusConfig(String status) {
  return switch (status) {
    'PENDING' => (
      label: 'Chờ xác nhận',
      foreground: const Color(0xFFC97A00),
      background: const Color(0xFFFFF1D8),
    ),
    'CONFIRMED' => (
      label: 'Đã xác nhận',
      foreground: _greenDark,
      background: const Color(0xFFE3F7F1),
    ),
    'COMPLETED' => (
      label: 'Hoàn thành',
      foreground: const Color(0xFF3478C8),
      background: const Color(0xFFEAF3FF),
    ),
    'CANCELLED' => (
      label: 'Đã hủy',
      foreground: const Color(0xFFD84B4B),
      background: const Color(0xFFFFEAEA),
    ),
    _ => (
      label: status,
      foreground: Colors.grey,
      background: const Color(0xFFF0F2F1),
    ),
  };
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _weekday(DateTime value) {
  return switch (value.weekday) {
    DateTime.monday => 'Thứ 2',
    DateTime.tuesday => 'Thứ 3',
    DateTime.wednesday => 'Thứ 4',
    DateTime.thursday => 'Thứ 5',
    DateTime.friday => 'Thứ 6',
    DateTime.saturday => 'Thứ 7',
    DateTime.sunday => 'Chủ nhật',
    _ => '',
  };
}
