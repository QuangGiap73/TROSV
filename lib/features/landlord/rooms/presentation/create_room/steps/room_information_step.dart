import 'package:flutter/material.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

class RoomInformationStep extends StatelessWidget {
  const RoomInformationStep({
    required this.draft,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final CreateRoomDraft draft;
  final VoidCallback onBack;
  final VoidCallback onNext;

  static const roomTypes = {
    'ROOM_SINGLE': 'Phòng đơn',
    'ROOM_SHARED': 'Ở ghép',
    'STUDIO': 'Studio',
    'ONE_BEDROOM': '1 phòng ngủ',
    'WHOLE_HOUSE': 'Nguyên căn',
  };

  @override
  Widget build(BuildContext context) {
    return CreateRoomStepLayout(
      step: 2,
      title: 'Thông tin phòng',
      onBack: onBack,
      onNext: () {
        if (!draft.isRoomInformationValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng nhập đủ tiêu đề, diện tích và giá thuê.'),
            ),
          );
          return;
        }

        onNext();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PropertySummary(draft: draft),
          const SizedBox(height: 18),
          CreateRoomTextField(
            label: 'Tiêu đề phòng',
            required: true,
            initialValue: draft.title,
            hint: 'Phòng khép kín, đầy đủ nội thất',
            onChanged: (value) {
              draft.title = value;
              draft.changed();
            },
          ),
          const Text(
            'Loại phòng *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roomTypes.entries.map((entry) {
              return ChoiceChip(
                label: Text(entry.value),
                selected: draft.roomType == entry.key,
                onSelected: (_) {
                  draft.roomType = entry.key;
                  draft.changed();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CreateRoomTextField(
                  label: 'Diện tích',
                  required: true,
                  initialValue: draft.areaM2?.toString(),
                  suffixText: 'm²',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    draft.areaM2 = double.tryParse(value);
                    draft.changed();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CreateRoomTextField(
                  label: 'Tầng',
                  initialValue: draft.floor?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    draft.floor = int.tryParse(value);
                    draft.changed();
                  },
                ),
              ),
            ],
          ),
          CreateRoomTextField(
            label: 'Số người tối đa',
            initialValue: draft.maxPeople.toString(),
            suffixText: 'người',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              draft.maxPeople = int.tryParse(value) ?? 1;
              draft.changed();
            },
          ),
          CreateRoomTextField(
            label: 'Giá thuê',
            required: true,
            initialValue: draft.priceMonthly?.toString(),
            suffixText: 'VNĐ/tháng',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              draft.priceMonthly = int.tryParse(value);
              draft.changed();
            },
          ),
          CreateRoomTextField(
            label: 'Tiền cọc',
            initialValue: draft.depositAmount.toString(),
            suffixText: 'VNĐ',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              draft.depositAmount = int.tryParse(value) ?? 0;
              draft.changed();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ngày có thể vào ở'),
            subtitle: Text(
              '${draft.availableDate.day.toString().padLeft(2, '0')}/'
              '${draft.availableDate.month.toString().padLeft(2, '0')}/'
              '${draft.availableDate.year}',
            ),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: draft.availableDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );

              if (date != null) {
                draft.availableDate = date;
                draft.changed();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PropertySummary extends StatelessWidget {
  const _PropertySummary({required this.draft});

  final CreateRoomDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xFFF0F7F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.apartment_rounded, color: Color(0xFF009688)),
      title: Text(
        draft.propertyName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(draft.addressText),
    );
  }
}
