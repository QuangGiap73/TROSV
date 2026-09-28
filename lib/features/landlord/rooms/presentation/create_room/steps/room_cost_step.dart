import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/create_room_reference.dart';
import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

class RoomCostStep extends StatefulWidget {
  const RoomCostStep({
    required this.draft,
    required this.amenities,
    required this.isLoadingAmenities,
    required this.onRetryAmenities,
    required this.onBack,
    required this.onNext,
    super.key,
  });
  final CreateRoomDraft draft;
  final List<AmenityOption> amenities;
  final bool isLoadingAmenities;
  final VoidCallback onRetryAmenities, onBack, onNext;
  @override
  State<RoomCostStep> createState() => _RoomCostStepState();
}

class _RoomCostStepState extends State<RoomCostStep> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return CreateRoomStepLayout(
      step: 4,
      title: 'Chi phí sinh hoạt',
      onBack: widget.onBack,
      onNext: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CostField(
            label: 'Tiền điện',
            suffix: 'VNĐ/kWh',
            value: draft.electricityPrice,
            onChanged: (value) => draft.electricityPrice = value,
          ),
          _CostField(
            label: 'Tiền nước',
            suffix: 'VNĐ/m³',
            value: draft.waterPrice,
            onChanged: (value) => draft.waterPrice = value,
          ),
          _CostField(
            label: 'Tiền Internet',
            suffix: 'VNĐ/tháng',
            value: draft.internetFee,
            onChanged: (value) => draft.internetFee = value,
          ),
          _CostField(
            label: 'Tiền gửi xe',
            suffix: 'VNĐ/tháng',
            value: draft.parkingFee,
            onChanged: (value) => draft.parkingFee = value,
          ),
          _CostField(
            label: 'Phí dịch vụ',
            suffix: 'VNĐ/tháng',
            value: draft.serviceFee,
            onChanged: (value) => draft.serviceFee = value,
          ),
          _CostField(
            label: 'Phí vệ sinh',
            suffix: 'VNĐ/tháng',
            value: draft.cleaningFee,
            onChanged: (value) => draft.cleaningFee = value,
          ),
          _CostField(
            label: 'Phí khác',
            suffix: 'VNĐ/tháng',
            value: draft.otherFee,
            onChanged: (value) => draft.otherFee = value,
          ),
          CreateRoomTextField(
            label: 'Mô tả phí khác',
            initialValue: draft.otherDescription,
            hint: 'Nhập mô tả nếu có...',
            onChanged: (value) {
              draft.otherDescription = value;
              draft.changed();
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Tiện ích',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Danh sách được lấy từ máy chủ',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (widget.isLoadingAmenities)
            const Center(child: CircularProgressIndicator())
          else if (widget.amenities.isEmpty)
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onRetryAmenities,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại tiện ích'),
              ),
            )
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: widget.amenities.map((amenity) {
                final selected = draft.amenityCodes.contains(amenity.code);
                return FilterChip(
                  selected: selected,
                  avatar: Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: selected ? const Color(0xFF008C72) : Colors.grey,
                  ),
                  label: Text(amenity.name),
                  onSelected: (_) {
                    draft.toggleAmenity(amenity.code);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CostField extends StatefulWidget {
  const _CostField({
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
  });
  final String label, suffix;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_CostField> createState() => _CostFieldState();
}

class _CostFieldState extends State<_CostField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == 0 ? '' : widget.value.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextField(
          controller: _controller,
          enabled: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (text) => widget.onChanged(int.tryParse(text) ?? 0),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: widget.suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFF00A884),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
