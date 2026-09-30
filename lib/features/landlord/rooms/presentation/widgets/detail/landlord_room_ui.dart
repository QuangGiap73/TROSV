import 'package:flutter/material.dart';

const roomGreen = Color(0xFF00A884);
const roomGreenDark = Color(0xFF008C72);
const roomBackground = Color(0xFFF6F9F8);
const roomText = Color(0xFF17211F);
const roomMuted = Color(0xFF667773);
const roomBorder = Color(0xFFE2EAE8);

String roomMoney(int value) {
  final text = value.toString();
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

String roomDecimal(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String roomDate(DateTime? value) {
  if (value == null) return 'Chưa cập nhật';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

String roomErrorText(Object? error) {
  return error?.toString().replaceFirst('LandlordRoomFailure: ', '') ??
      'Có lỗi xảy ra. Vui lòng thử lại.';
}

String roomStatusLabel(String value) => switch (value) {
  'DRAFT' => 'Bản nháp',
  'PENDING_REVIEW' => 'Chờ duyệt',
  'PUBLISHED' => 'Đang đăng',
  'REJECTED' => 'Bị từ chối',
  'HIDDEN' => 'Đã ẩn',
  'RENTED' => 'Đã thuê',
  'CANCELLED' => 'Đã hủy',
  _ => value,
};

Color roomStatusColor(String value) => switch (value) {
  'PUBLISHED' => roomGreenDark,
  'PENDING_REVIEW' => Colors.orange,
  'REJECTED' => Colors.redAccent,
  'HIDDEN' => Colors.blueGrey,
  'RENTED' => Colors.indigo,
  'CANCELLED' => Colors.brown,
  _ => Colors.blueGrey,
};

String roomTypeLabel(String value) => switch (value) {
  'ROOM_SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' => 'Phòng ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};

String roomSpaceLabel(String value) => switch (value) {
  'MAIN_ROOM' => 'Phòng chính',
  'BATHROOM' => 'Nhà vệ sinh',
  'KITCHEN' => 'Khu bếp',
  'BALCONY' => 'Ban công',
  'OTHER' => 'Không gian khác',
  _ => value,
};

IconData roomSpaceIcon(String value) => switch (value) {
  'MAIN_ROOM' => Icons.bed_outlined,
  'BATHROOM' => Icons.bathtub_outlined,
  'KITCHEN' => Icons.kitchen_outlined,
  'BALCONY' => Icons.balcony_outlined,
  _ => Icons.other_houses_outlined,
};

IconData roomAmenityIcon(String code, [String? name]) {
  final value = '$code ${name ?? ''}'.toUpperCase();

  if (value.contains('WIFI')) return Icons.wifi_rounded;
  if (value.contains('AIR') ||
      value.contains('DIEU_HOA') ||
      value.contains('ĐIỀU HÒA')) {
    return Icons.ac_unit_rounded;
  }
  if (value.contains('WASH') || value.contains('MÁY GIẶT')) {
    return Icons.local_laundry_service_outlined;
  }
  if (value.contains('FRIDGE') ||
      value.contains('REFRIGERATOR') ||
      value.contains('TU_LANH') ||
      value.contains('TỦ LẠNH')) {
    return Icons.kitchen_outlined;
  }
  if (value.contains('HOT') ||
      value.contains('WATER_HEATER') ||
      value.contains('NÓNG LẠNH')) {
    return Icons.hot_tub_outlined;
  }
  if (value.contains('FINGER') || value.contains('VÂN TAY')) {
    return Icons.fingerprint_rounded;
  }
  if (value.contains('PARK') || value.contains('ĐỂ XE')) {
    return Icons.two_wheeler_rounded;
  }
  if (value.contains('CAMERA')) return Icons.photo_camera_outlined;
  if (value.contains('ELEVATOR') || value.contains('THANG MÁY')) {
    return Icons.elevator_rounded;
  }
  if (value.contains('BALCONY') || value.contains('BAN CÔNG')) {
    return Icons.balcony_rounded;
  }
  if (value.contains('WARDROBE') || value.contains('TỦ QUẦN')) {
    return Icons.door_sliding_outlined;
  }
  if (value.contains('BED') || value.contains('GIƯỜNG')) {
    return Icons.bed_rounded;
  }
  if (value.contains('KITCHEN') || value.contains('BẾP')) {
    return Icons.soup_kitchen_rounded;
  }
  if (value.contains('PET') || value.contains('THÚ CƯNG')) {
    return Icons.pets_outlined;
  }

  return Icons.check_circle_outline_rounded;
}

String utilityPrice({
  required String? type,
  required int price,
  required bool electricity,
}) {
  return switch (type) {
    'FREE' => 'Miễn phí',
    'INCLUDED' => 'Đã gồm trong tiền phòng',
    'PER_PERSON' => '${roomMoney(price)} đ/người',
    'PER_KWH' => '${roomMoney(price)} đ/kWh',
    'PER_M3' => '${roomMoney(price)} đ/m³',
    _ => electricity ? '${roomMoney(price)} đ/kWh' : '${roomMoney(price)} đ/m³',
  };
}

class LandlordRoomStatusBadge extends StatelessWidget {
  const LandlordRoomStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = roomStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Text(
        roomStatusLabel(status),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class LandlordRoomSectionCard extends StatelessWidget {
  const LandlordRoomSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roomBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: roomGreenDark),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: roomText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 11, color: roomMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class LandlordRoomFactTile extends StatelessWidget {
  const LandlordRoomFactTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: roomGreenDark),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: roomMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: roomText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LandlordRoomDetailLoading extends StatelessWidget {
  const LandlordRoomDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Skeleton(height: 190),
        SizedBox(height: 14),
        _Skeleton(height: 24, widthFactor: .70),
        SizedBox(height: 10),
        _Skeleton(height: 18, widthFactor: .42),
        SizedBox(height: 18),
        _Skeleton(height: 120),
        SizedBox(height: 12),
        _Skeleton(height: 150),
      ],
    );
  }
}

class LandlordRoomDetailError extends StatelessWidget {
  const LandlordRoomDetailError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không tải được dữ liệu phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: roomText,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: roomMuted,
              ),
            ),
            const SizedBox(height: 16),
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

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.widthFactor = 1});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EEEB),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
