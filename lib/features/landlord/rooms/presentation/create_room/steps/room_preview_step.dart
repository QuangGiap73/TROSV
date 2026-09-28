import 'dart:io';

import 'package:flutter/material.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

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
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return CreateRoomStepLayout(
      step: 5,
      title: 'Mô tả và nội quy',
      onBack: widget.onBack,
      onNext: widget.onSubmit,
      onSecondary: widget.onSaveDraft,
      secondaryLabel: 'Lưu nháp',
      nextLabel: 'Gửi duyệt',
      isLoading: widget.isSubmitting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateRoomTextField(
            label: 'Mô tả phòng',
            initialValue: draft.description,
            hint: 'Mô tả điểm nổi bật của phòng...',
            maxLines: 6,
            maxLength: 500,
            onChanged: (value) {
              draft.description = value;
              draft.changed();
            },
          ),
          CreateRoomTextField(
            label: 'Nội quy',
            initialValue: draft.houseRules,
            hint: 'Ví dụ: Không nuôi thú cưng, không gây ồn sau 22h...',
            maxLines: 5,
            maxLength: 3000,
            onChanged: (value) {
              draft.houseRules = value;
              draft.changed();
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Xem trước thông tin phòng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _RoomPreviewCard(draft: draft),
        ],
      ),
    );
  }
}

class _RoomPreviewCard extends StatelessWidget {
  const _RoomPreviewCard({required this.draft});

  final CreateRoomDraft draft;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 8.5,
            child: draft.images.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFE4EEEB),
                    child: Icon(Icons.image_outlined, size: 54),
                  )
                : Image.file(File(draft.images.first.path), fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title.isEmpty ? 'Phòng chưa có tiêu đề' : draft.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_money(draft.priceMonthly ?? 0)} đ/tháng',
                  style: const TextStyle(
                    color: Color(0xFF009688),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${draft.areaM2 ?? 0} m²'
                  '  ·  Tối đa ${draft.maxPeople} người'
                  '${draft.floor == null ? '' : '  ·  Tầng ${draft.floor}'}',
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${draft.propertyName}\n${draft.addressText}',
                      ),
                    ),
                  ],
                ),
                if (draft.amenityCodes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: draft.amenityCodes
                        .map((code) => Chip(label: Text(code)))
                        .toList(),
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
