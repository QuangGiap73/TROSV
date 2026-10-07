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

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final String? roomAddress;

  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE4ECE9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //
                // ẢNH PHÒNG
                //
                _RoomImage(
                  url: appointment.roomImage,
                ),

                const SizedBox(width: 11),

                //
                // TOÀN BỘ THÔNG TIN
                //
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //
                      // TITLE
                      //
                      Text(
                        appointment.roomTitle ?? 'Phòng trọ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),

                      //
                      // PRICE
                      //
                      if (appointment.roomPrice != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${formatVnd(
                            appointment.roomPrice!,
                          )}/tháng',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: _greenDark,
                          ),
                        ),
                      ],

                      const SizedBox(height: 5),

                      //
                      // STATUS
                      //
                      AppointmentStatusBadge(
                        status: appointment.status,
                      ),

                      const SizedBox(height: 7),

                      //
                      // NGÀY + GIỜ
                      //
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13.5,
                            color: Color(0xFF687A75),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${_weekday(
                                appointment.bookingDate,
                              )}, ${_date(
                                appointment.bookingDate,
                              )}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.2,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFF687A75),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              appointment.timeSlot,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.2,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      //
                      // ĐỊA CHỈ - CHỈ HIỆN NẾU CÓ
                      //
                      if (roomAddress?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Color(0xFF687A75),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                roomAddress!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                //
                // MŨI TÊN
                //
                if (onTap != null) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF9AA7A3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentRoomInfo extends StatelessWidget {
  const _AppointmentRoomInfo({
    required this.appointment,
  });

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        // TITLE
        //
        Text(
          appointment.roomTitle ?? 'Phòng trọ',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),

        //
        // PRICE
        //
        if (appointment.roomPrice != null) ...[
          const SizedBox(height: 4),
          Text(
            '${formatVnd(appointment.roomPrice!)}/tháng',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: _greenDark,
            ),
          ),
        ],

        //
        // STATUS
        //
        const SizedBox(height: 7),

        AppointmentStatusBadge(
          status: appointment.status,
        ),
      ],
    );
  }
}

class _AppointmentMeta extends StatelessWidget {
  const _AppointmentMeta({
    required this.appointment,
    required this.roomAddress,
    required this.onTap,
  });

  final Appointment appointment;
  final String? roomAddress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //
              // NGÀY
              //
              _InfoLine(
                icon: Icons.calendar_today_outlined,
                text:
                    '${_weekday(appointment.bookingDate)}, '
                    '${_date(appointment.bookingDate)}',
              ),

              const SizedBox(height: 5),

              //
              // GIỜ
              //
              _InfoLine(
                icon: Icons.schedule_rounded,
                text: appointment.timeSlot,
              ),

              //
              // ĐỊA CHỈ
              //
              if (roomAddress?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 5),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: roomAddress!.trim(),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),

        if (onTap != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F7F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF768681),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({
    required this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 88,
        child: url == null || url!.trim().isEmpty
            ? const _RoomImageFallback()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const _RoomImageFallback(
                    broken: true,
                  );
                },
              ),
      ),
    );
  }
}

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback({
    this.broken = false,
  });

  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F4F1),
      child: Center(
        child: Icon(
          broken
              ? Icons.broken_image_outlined
              : Icons.home_work_outlined,
          color: const Color(0xFF79A097),
          size: broken ? 27 : 31,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 15,
            color: const Color(0xFF657872),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.22,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({
    required this.status,
    super.key,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: config.foreground.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: config.foreground,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            config.label,
            style: TextStyle(
              fontSize: 9.5,
              height: 1,
              fontWeight: FontWeight.w700,
              color: config.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StatusConfig = ({
  String label,
  Color foreground,
  Color background,
});

_StatusConfig _statusConfig(String status) {
  return switch (status) {
    'PENDING' => (
        label: 'Chờ xác nhận',
        foreground: Color(0xFFC97A00),
        background: Color(0xFFFFF3DE),
      ),

    'CONFIRMED' => (
        label: 'Đã xác nhận',
        foreground: _greenDark,
        background: Color(0xFFE6F7F2),
      ),

    'COMPLETED' => (
        label: 'Hoàn thành',
        foreground: Color(0xFF3478C8),
        background: Color(0xFFEDF5FF),
      ),

    'CANCELLED' => (
        label: 'Đã hủy',
        foreground: Color(0xFFD84B4B),
        background: Color(0xFFFFEEEE),
      ),

    'REJECTED' => (
        label: 'Đã từ chối',
        foreground: Color(0xFFD84B4B),
        background: Color(0xFFFFEEEE),
      ),

    _ => (
        label: status,
        foreground: Colors.grey,
        background: Color(0xFFF0F2F1),
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