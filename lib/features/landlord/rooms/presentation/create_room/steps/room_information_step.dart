import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

class RoomInformationStep extends StatefulWidget {
  const RoomInformationStep({
    required this.draft,
    required this.onBack,
    required this.onNext,
    required this.onChangeProperty,
    required this.isSaving,
    super.key,
  });

  final CreateRoomDraft draft;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onChangeProperty;
  final bool isSaving;

  @override
  State<RoomInformationStep> createState() => _RoomInformationStepState();
}

class _RoomInformationStepState extends State<RoomInformationStep> {
  static const _roomTypes = <(String, String)>[
    ('ROOM_SINGLE', 'Phòng đơn'),
    ('ROOM_SHARED', 'Ở ghép'),
    ('STUDIO', 'Studio'),
    ('ONE_BEDROOM', '1 phòng ngủ'),
    ('WHOLE_HOUSE', 'Nguyên căn'),
  ];

  CreateRoomDraft get draft => widget.draft;

  @override
  Widget build(BuildContext context) {
    return CreateRoomStepLayout(
      step: 2,
      title: '',
      onBack: widget.onBack,
      onNext: _validateAndContinue,
      isLoading: widget.isSaving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(),
          const SizedBox(height: 16),
          _PropertyCard(draft: draft, onChange: widget.onChangeProperty),
          const SizedBox(height: 18),
          CreateRoomTextField(
            label: 'Tiêu đề phòng',
            required: true,
            prefixIcon: Icons.edit_outlined,
            initialValue: draft.title,
            hint: 'VD: Phòng khép kín, đầy đủ nội thất',
            onChanged: (value) {
              draft.title = value;
              draft.changed();
            },
          ),
          const _FieldLabel('Loại phòng', required: true),
          const SizedBox(height: 8),
          _RoomTypeGrid(
            selected: draft.roomType,
            onSelected: (value) {
              setState(() {
                draft.roomType = value;
                draft.changed();
              });
            },
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CreateRoomTextField(
                  label: 'Diện tích',
                  required: true,
                  prefixIcon: Icons.square_foot_outlined,
                  initialValue: draft.areaM2?.toString(),
                  hint: 'VD: 25',
                  suffixText: 'm²',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    draft.areaM2 = double.tryParse(value.replaceAll(',', '.'));
                    draft.changed();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CreateRoomTextField(
                  label: 'Tầng',
                  prefixIcon: Icons.stairs_outlined,
                  initialValue: draft.floor?.toString(),
                  hint: 'VD: 3',
                  suffixText: 'tầng',
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
            prefixIcon: Icons.people_outline,
            initialValue: draft.maxPeople.toString(),
            hint: 'VD: 2',
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
            prefixIcon: Icons.monetization_on_outlined,
            initialValue: _displayMoney(draft.priceMonthly),
            hint: 'VD: 3.500.000',
            suffixText: 'đ/tháng',
            keyboardType: TextInputType.number,
            inputFormatters: const [_VietnameseMoneyInputFormatter()],
            onChanged: (value) {
              draft.priceMonthly = int.tryParse(_digits(value));
              draft.changed();
            },
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CreateRoomTextField(
                  label: 'Tiền cọc',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  initialValue: _displayMoney(draft.depositAmount),
                  hint: 'VD: 1.000.000',
                  suffixText: 'đồng',
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_VietnameseMoneyInputFormatter()],
                  onChanged: (value) {
                    draft.depositAmount = int.tryParse(_digits(value)) ?? 0;
                    draft.changed();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AvailableDateField(
                  date: draft.availableDate,
                  onTap: _selectDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: draft.availableDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        draft.availableDate = date;
        draft.changed();
      });
    }
  }

  void _validateAndContinue() {
    if (!draft.isRoomInformationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ tiêu đề, diện tích và giá thuê.'),
        ),
      );
      return;
    }
    widget.onNext();
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.home_rounded, color: Color(0xFF00A884), size: 27),
      SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin phòng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Cung cấp thông tin chi tiết về phòng trọ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.draft, required this.onChange});
  final CreateRoomDraft draft;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.apartment_rounded, color: Color(0xFF00A884)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.propertyName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                draft.addressText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onChange, child: const Text('Thay đổi')),
      ],
    ),
  );
}

class _RoomTypeGrid extends StatelessWidget {
  const _RoomTypeGrid({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const types = _RoomInformationStepState._roomTypes;
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _typeButton(types[index])),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _typeButton(types[3])),
            const SizedBox(width: 8),
            Expanded(child: _typeButton(types[4])),
          ],
        ),
      ],
    );
  }

  Widget _typeButton((String, String) type) {
    final isSelected = selected == type.$1;
    return Material(
      color: isSelected ? const Color(0xFF00A884) : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => onSelected(type.$1),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00A884)
                  : const Color(0xFFDCE6E3),
            ),
          ),
          child: Text(
            type.$2,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF263833),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableDateField extends StatelessWidget {
  const _AvailableDateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FieldLabel('Ngày có thể vào ở'),
      const SizedBox(height: 7),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFDDE5E2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 17),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.w600),
      children: [
        if (required)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
      ],
    ),
  );
}

String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String? _displayMoney(int? value) {
  if (value == null || value <= 0) return null;
  return _formatMoney(value);
}

String _formatMoney(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}

class _VietnameseMoneyInputFormatter extends TextInputFormatter {
  const _VietnameseMoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(newValue.text);
    if (digits.isEmpty) return const TextEditingValue();

    final value = int.tryParse(digits);
    if (value == null) return oldValue;

    final formatted = _formatMoney(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
