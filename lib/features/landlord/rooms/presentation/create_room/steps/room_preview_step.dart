import 'dart:io';

import 'package:flutter/material.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _greenSoft = Color(0xFFEAF9F5);
const _cardBorder = Color(0xFFE3ECE9);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

class RoomPreviewStep extends StatefulWidget {
  const RoomPreviewStep({
    required this.draft,
    required this.onBack,
    required this.onSaveDraft,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final CreateRoomDraft draft;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  State<RoomPreviewStep> createState() => _RoomPreviewStepState();
}

class _RoomPreviewStepState extends State<RoomPreviewStep> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _houseRulesController;

  CreateRoomDraft get draft => widget.draft;

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(text: draft.description);

    _houseRulesController = TextEditingController(text: draft.houseRules);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _houseRulesController.dispose();
    super.dispose();
  }

  bool get _hasBasicInformation =>
      draft.title.trim().isNotEmpty &&
      draft.priceMonthly != null &&
      draft.priceMonthly! > 0 &&
      draft.areaM2 != null &&
      draft.areaM2! > 0;

  bool get _hasLocation =>
      draft.propertyName.trim().isNotEmpty &&
      draft.addressText.trim().isNotEmpty;

  bool get _hasImage => draft.images.isNotEmpty;

  int get _completedItems {
    var count = 0;

    if (_hasBasicInformation) count++;
    if (_hasLocation) count++;
    if (_hasImage) count++;
    if (draft.description.trim().isNotEmpty) count++;
    if (draft.houseRules.trim().isNotEmpty) count++;

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return CreateRoomStepLayout(
      step: 5,
      title: '',
      onBack: widget.onBack,
      onNext: widget.onSubmit,
      onSecondary: widget.onSaveDraft,
      secondaryLabel: 'Lưu nháp',
      nextLabel: 'Gửi duyệt',
      isLoading: widget.isSubmitting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả & xem trước',
            style: TextStyle(
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Hoàn thiện nội dung cuối cùng và kiểm tra lại bài đăng '
            'trước khi gửi duyệt.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          if (draft.backendPreview case final preview?) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCDEDE4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: _greenDark),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Đã tải preview từ backend · '
                      '${preview['status'] ?? 'DRAFT'}',
                      style: const TextStyle(
                        color: _greenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _CompletenessCard(completed: _completedItems, total: 5),

          const SizedBox(height: 16),

          _EditorCard(
            icon: Icons.edit_note_rounded,
            title: 'Mô tả phòng',
            subtitle:
                'Nêu những điểm nổi bật để người thuê hiểu nhanh căn phòng.',
            child: TextField(
              controller: _descriptionController,
              minLines: 5,
              maxLines: 7,
              maxLength: 500,
              onChanged: (value) {
                setState(() {
                  draft.description = value;
                  draft.changed();
                });
              },
              decoration: _textAreaDecoration(
                hint:
                    'Ví dụ: Phòng khép kín, đầy đủ nội thất, nhiều ánh sáng tự nhiên, gần trường học...',
              ),
            ),
          ),

          const SizedBox(height: 14),

          _EditorCard(
            icon: Icons.rule_rounded,
            title: 'Nội quy',
            subtitle: 'Quy định rõ ràng giúp hạn chế hiểu nhầm sau khi thuê.',
            child: TextField(
              controller: _houseRulesController,
              minLines: 4,
              maxLines: 6,
              maxLength: 3000,
              onChanged: (value) {
                setState(() {
                  draft.houseRules = value;
                  draft.changed();
                });
              },
              decoration: _textAreaDecoration(
                hint:
                    'Ví dụ:\n• Giữ gìn vệ sinh chung\n• Không gây ồn sau 22h\n• Không hút thuốc trong phòng',
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Row(
            children: [
              Icon(Icons.visibility_outlined, color: _greenDark, size: 22),
              SizedBox(width: 8),
              Text(
                'Xem trước bài đăng',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Đây là cách thông tin phòng có thể hiển thị với người thuê.',
            style: TextStyle(fontSize: 12.5, color: _textSecondary),
          ),

          const SizedBox(height: 12),

          _RoomPreviewCard(draft: draft),

          const SizedBox(height: 14),

          _ReviewNotice(
            ready: _hasBasicInformation && _hasLocation && _hasImage,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// COMPLETENESS
// =============================================================

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9F9F5), Color(0xFFF5FCFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2EFE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFDCECE8),
                    color: _green,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _greenDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm tra độ hoàn thiện',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bổ sung đầy đủ ảnh, mô tả và nội quy sẽ giúp bài đăng rõ ràng hơn.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// EDITOR SECTION
// =============================================================

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF7F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _greenDark, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =============================================================
// ROOM PREVIEW
// =============================================================

class _RoomPreviewCard extends StatelessWidget {
  const _RoomPreviewCard({required this.draft});

  final CreateRoomDraft draft;

  @override
  Widget build(BuildContext context) {
    final visibleAmenities = draft.amenityCodes.take(5).toList();

    final remainingAmenities =
        draft.amenityCodes.length - visibleAmenities.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: draft.images.isEmpty
                    ? Container(
                        color: const Color(0xFFE8F0EE),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Color(0xFF8FA9A3),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Chưa có ảnh phòng',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image.file(
                        File(draft.images.first.path),
                        fit: BoxFit.cover,
                      ),
              ),

              if (draft.images.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ảnh đại diện',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (draft.images.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '1/${draft.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title.trim().isEmpty
                      ? 'Phòng chưa có tiêu đề'
                      : draft.title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${_money(draft.priceMonthly ?? 0)} đ/tháng',
                  style: const TextStyle(
                    color: _greenDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _InfoChip(
                      icon: Icons.square_foot_rounded,
                      text: '${_formatArea(draft.areaM2)} m²',
                    ),
                    _InfoChip(
                      icon: Icons.people_alt_outlined,
                      text: 'Tối đa ${draft.maxPeople} người',
                    ),
                    if (draft.floor != null)
                      _InfoChip(
                        icon: Icons.stairs_rounded,
                        text: 'Tầng ${draft.floor}',
                      ),
                  ],
                ),

                const SizedBox(height: 13),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 19,
                      color: _greenDark,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (draft.propertyName.trim().isNotEmpty)
                            Text(
                              draft.propertyName.trim(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          if (draft.addressText.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              draft.addressText.trim(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (visibleAmenities.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  const Divider(height: 1, color: Color(0xFFE9EFED)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ...visibleAmenities.map(
                        (code) => _AmenityChip(code: code),
                      ),
                      if (remainingAmenities > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+$remainingAmenities tiện ích',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                if (draft.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    draft.description.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E9E6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF526B65)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF526B65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _greenSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDEDE4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_amenityIcon(code), size: 14, color: _greenDark),
          const SizedBox(width: 5),
          Text(
            _amenityLabel(code),
            style: const TextStyle(
              fontSize: 10.5,
              color: _greenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// REVIEW NOTICE
// =============================================================

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final background = ready
        ? const Color(0xFFEAF9F0)
        : const Color(0xFFFFF7E7);

    final border = ready ? const Color(0xFFCDEEDB) : const Color(0xFFF2DFB2);

    final iconBackground = ready
        ? const Color(0xFFD5F3E1)
        : const Color(0xFFFFEBC1);

    final iconColor = ready ? const Color(0xFF2DAA67) : const Color(0xFFD78A17);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.check_circle_rounded : Icons.info_rounded,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready
                      ? 'Tin đăng đã sẵn sàng để gửi duyệt'
                      : 'Bạn nên kiểm tra lại trước khi gửi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ready
                        ? const Color(0xFF26794C)
                        : const Color(0xFF946616),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ready
                      ? 'Hãy kiểm tra lại thông tin, hình ảnh và mức giá trước khi gửi.'
                      : 'Nên bổ sung ảnh và các thông tin cơ bản để bài đăng rõ ràng hơn.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// HELPERS
// =============================================================

InputDecoration _textAreaDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFF9AA7A4),
      fontSize: 12,
      height: 1.35,
    ),
    filled: true,
    fillColor: const Color(0xFFF9FBFA),
    contentPadding: const EdgeInsets.all(13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE6E3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE6E3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green, width: 1.4),
    ),
  );
}

String _formatArea(double? value) {
  if (value == null) {
    return '0';
  }

  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String _money(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }

    buffer.write(digits[index]);
  }

  return buffer.toString();
}

String _amenityLabel(String code) {
  final upper = code.toUpperCase();

  if (upper.contains('WIFI')) {
    return 'Wifi';
  }

  if (upper.contains('AIR')) {
    return 'Điều hòa';
  }

  if (upper.contains('WASH')) {
    return 'Máy giặt';
  }

  if (upper.contains('FRIDGE')) {
    return 'Tủ lạnh';
  }

  if (upper.contains('WATER_HEATER')) {
    return 'Nóng lạnh';
  }

  if (upper.contains('ELEVATOR')) {
    return 'Thang máy';
  }

  if (upper.contains('BALCONY')) {
    return 'Ban công';
  }

  if (upper.contains('PARK')) {
    return 'Chỗ để xe';
  }

  if (upper.contains('CAMERA')) {
    return 'Camera';
  }

  if (upper.contains('BED')) {
    return 'Giường';
  }

  if (upper.contains('KITCHEN')) {
    return 'Bếp';
  }

  return code
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((item) => item.isNotEmpty)
      .map((item) => '${item[0].toUpperCase()}${item.substring(1)}')
      .join(' ');
}

IconData _amenityIcon(String code) {
  final upper = code.toUpperCase();

  if (upper.contains('WIFI')) {
    return Icons.wifi_rounded;
  }

  if (upper.contains('AIR')) {
    return Icons.ac_unit_rounded;
  }

  if (upper.contains('WASH')) {
    return Icons.local_laundry_service_rounded;
  }

  if (upper.contains('FRIDGE')) {
    return Icons.kitchen_rounded;
  }

  if (upper.contains('WATER_HEATER')) {
    return Icons.hot_tub_rounded;
  }

  if (upper.contains('ELEVATOR')) {
    return Icons.elevator_rounded;
  }

  if (upper.contains('BALCONY')) {
    return Icons.balcony_rounded;
  }

  if (upper.contains('PARK')) {
    return Icons.two_wheeler_rounded;
  }

  if (upper.contains('CAMERA')) {
    return Icons.photo_camera_outlined;
  }

  if (upper.contains('BED')) {
    return Icons.bed_rounded;
  }

  if (upper.contains('KITCHEN')) {
    return Icons.soup_kitchen_rounded;
  }

  return Icons.check_circle_outline_rounded;
}
