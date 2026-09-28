import 'package:flutter/material.dart';
import '../../../domain/entities/create_room_reference.dart';
import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';
import 'property_location_picker_screen.dart';

class PropertyStep extends StatefulWidget {
  const PropertyStep({
    required this.draft,
    required this.properties,
    required this.isLoadingProperties,
    required this.onRetryProperties,
    required this.onNext,
    required this.onClose,
    super.key,
  });
  final CreateRoomDraft draft;
  final List<LandlordProperty> properties;
  final bool isLoadingProperties;
  final VoidCallback onRetryProperties, onNext, onClose;
  @override
  State<PropertyStep> createState() => _PropertyStepState();
}

class _PropertyStepState extends State<PropertyStep> {
  int _fieldRevision = 0;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return CreateRoomStepLayout(
      step: 1,
      title: 'Vị trí khu trọ',
      onBack: widget.onClose,
      onNext: () {
        if (!draft.isPropertyValid) {
          _message('Bạn cần chọn khu trọ hoặc nhập đầy đủ vị trí khu trọ mới.');
          return;
        }
        widget.onNext();
      },
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            initialValue: draft.propertyId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khu trọ của bạn',
              prefixIcon: Icon(Icons.apartment_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tạo khu trọ mới'),
              ),
              ...widget.properties.map(
                (property) => DropdownMenuItem<String?>(
                  value: property.id,
                  child: Text(property.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: widget.isLoadingProperties
                ? null
                : (id) {
                    final selected = id == null
                        ? null
                        : widget.properties.firstWhere((item) => item.id == id);
                    setState(() {
                      draft.selectProperty(selected);
                      _fieldRevision++;
                    });
                  },
          ),
          if (widget.isLoadingProperties)
            const LinearProgressIndicator(minHeight: 2),
          if (!widget.isLoadingProperties && widget.properties.isEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onRetryProperties,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại danh sách'),
              ),
            ),
          const SizedBox(height: 18),
          CreateRoomTextField(
            key: ValueKey('name-${draft.propertyId}-$_fieldRevision'),
            label: 'Tên khu trọ',
            required: true,
            enabled: draft.propertyId == null,
            initialValue: draft.propertyName,
            hint: 'Ví dụ: Nhà trọ An Bình',
            onChanged: (value) {
              draft.propertyName = value;
              draft.changed();
            },
          ),
          CreateRoomTextField(
            key: ValueKey('address-${draft.propertyId}-$_fieldRevision'),
            label: 'Địa chỉ',
            required: true,
            enabled: draft.propertyId == null,
            initialValue: draft.addressText,
            hint: 'Nhập số nhà, tên đường...',
            onChanged: (value) {
              draft.addressText = value;
              draft.changed();
            },
          ),
          _MapPlaceholder(
            hasLocation: draft.latitude != null && draft.longitude != null,
            onChooseLocation: draft.propertyId != null
                ? null
                : () async {
                    final result = await Navigator.push<PropertyLocationResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyLocationPickerScreen(
                          latitude: draft.latitude,
                          longitude: draft.longitude,
                        ),
                      ),
                    );
                    if (result == null) return;
                    setState(() {
                      draft.latitude = result.latitude;
                      draft.longitude = result.longitude;
                      draft.addressText = result.addressText;
                      draft.province = result.province;
                      draft.district = result.district;
                      draft.ward = result.ward;
                      _fieldRevision++;
                      draft.changed();
                    });
                  },
          ),
          const SizedBox(height: 18),
          CreateRoomTextField(
            key: ValueKey('province-${draft.propertyId}-$_fieldRevision'),
            label: 'Tỉnh/Thành phố',
            required: true,
            enabled: draft.propertyId == null,
            initialValue: draft.province,
            onChanged: (value) {
              draft.province = value;
              draft.changed();
            },
          ),
          CreateRoomTextField(
            key: ValueKey('district-${draft.propertyId}-$_fieldRevision'),
            label: 'Quận/Huyện',
            enabled: draft.propertyId == null,
            initialValue: draft.district,
            onChanged: (value) {
              draft.district = value;
              draft.changed();
            },
          ),
          CreateRoomTextField(
            key: ValueKey('ward-${draft.propertyId}-$_fieldRevision'),
            label: 'Phường/Xã',
            required: true,
            enabled: draft.propertyId == null,
            initialValue: draft.ward,
            onChanged: (value) {
              draft.ward = value;
              draft.changed();
            },
          ),
        ],
      ),
    );
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.hasLocation,
    required this.onChooseLocation,
  });
  final bool hasLocation;
  final VoidCallback? onChooseLocation;
  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F1EE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD6E3E0)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.map_outlined, size: 70, color: Color(0xFF80AAA1)),
        Icon(
          Icons.location_pin,
          size: 48,
          color: hasLocation ? Colors.green : Colors.redAccent,
        ),
        Positioned(
          bottom: 12,
          child: FilledButton.icon(
            onPressed: onChooseLocation,
            icon: const Icon(Icons.my_location),
            label: Text(
              onChooseLocation == null
                  ? 'Vị trí của khu trọ đã chọn'
                  : hasLocation
                  ? 'Đổi vị trí'
                  : 'Chọn vị trí trên bản đồ',
            ),
          ),
        ),
      ],
    ),
  );
}
