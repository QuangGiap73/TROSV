import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/create_room_reference.dart';
import '../models/create_room_draft.dart';
import '../providers/property_location_provider.dart';
import '../widgets/create_room_step_layout.dart';
import 'property_inline_map.dart';

class PropertyStep extends ConsumerStatefulWidget {
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
  final VoidCallback onRetryProperties;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  ConsumerState<PropertyStep> createState() =>
      _PropertyStepState();
}

class _PropertyStepState
    extends ConsumerState<PropertyStep> {
  static const String _newPropertyValue =
      '__CREATE_NEW_PROPERTY__';

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _addressController;

  late final TextEditingController
      _provinceController;

  late final TextEditingController
      _districtController;

  late final TextEditingController
      _wardController;

  Timer? _addressDebounce;

  int _addressRequestId = 0;

  bool _searchingAddress = false;
  String? _addressSearchError;

  @override
  void initState() {
    super.initState();

    final draft = widget.draft;

    _nameController = TextEditingController(
      text: draft.propertyName,
    );

    _addressController =
        TextEditingController(
      text: draft.addressText,
    );

    _provinceController =
        TextEditingController(
      text: draft.province,
    );

    _districtController =
        TextEditingController(
      text: draft.district,
    );

    _wardController =
        TextEditingController(
      text: draft.ward,
    );
  }

  @override
  void didUpdateWidget(
    covariant PropertyStep oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!identical(
      oldWidget.draft,
      widget.draft,
    )) {
      _syncControllersFromDraft();
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();

    _nameController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final editingNewProperty =
        draft.propertyId == null;

    return CreateRoomStepLayout(
      step: 1,
      title: 'Vị trí khu trọ',
      onBack: widget.onClose,
      onNext: () {
        if (!draft.isPropertyValid) {
          _message(
            'Bạn cần chọn khu trọ hoặc nhập đầy đủ vị trí khu trọ mới.',
          );
          return;
        }

        widget.onNext();
      },
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue:
                draft.propertyId ??
                    _newPropertyValue,
            isExpanded: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Khu trọ của bạn',
              prefixIcon: Icon(
                Icons.apartment_rounded,
              ),
              border:
                  OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<
                  String>(
                value:
                    _newPropertyValue,
                child: Text(
                  'Tạo khu trọ mới',
                ),
              ),
              ...widget.properties.map(
                (property) =>
                    DropdownMenuItem<
                        String>(
                  value: property.id,
                  child: Text(
                    property.name,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                ),
              ),
            ],
            onChanged:
                widget.isLoadingProperties
                    ? null
                    : _onPropertyChanged,
          ),

          if (widget
              .isLoadingProperties)
            const LinearProgressIndicator(
              minHeight: 2,
            ),

          if (!widget
                  .isLoadingProperties &&
              widget.properties.isEmpty)
            Align(
              alignment:
                  Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget
                    .onRetryProperties,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Tải lại danh sách',
                ),
              ),
            ),

          const SizedBox(height: 18),

          CreateRoomTextField(
            controller:
                _nameController,
            label: 'Tên khu trọ',
            required: true,
            enabled:
                editingNewProperty,
            hint:
                'Ví dụ: Nhà trọ An Bình',
            onChanged: (value) {
              draft.propertyName =
                  value;
              draft.changed();
            },
          ),

          CreateRoomTextField(
            controller:
                _addressController,
            label: 'Địa chỉ',
            required: true,
            enabled:
                editingNewProperty,
            hint:
                'Ví dụ: 91 Trung Kính, Cầu Giấy, Hà Nội',
            keyboardType:
                TextInputType.streetAddress,
            onChanged: (value) {
              draft.addressText =
                  value;
              draft.changed();

              if (editingNewProperty) {
                _scheduleAddressSearch(
                  value,
                );
              }
            },
          ),

          if (editingNewProperty &&
              _searchingAddress) ...[
            const Row(
              children: [
                SizedBox.square(
                  dimension: 16,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 9),
                Text(
                  'Đang tìm vị trí của địa chỉ...',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
          ],

          if (editingNewProperty &&
              _addressSearchError !=
                  null) ...[
            Text(
              _addressSearchError!,
              style: const TextStyle(
                color:
                    Colors.redAccent,
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],

          PropertyInlineMap(
            latitude: draft.latitude,
            longitude:
                draft.longitude,
            addressText:
                draft.addressText,
            enabled:
                editingNewProperty,
            onLocationChanged:
                _onMapLocationChanged,
          ),

          CreateRoomTextField(
            controller:
                _provinceController,
            label:
                'Tỉnh/Thành phố',
            required: true,
            enabled:
                editingNewProperty,
            onChanged: (value) {
              draft.province = value;
              draft.changed();
            },
          ),

          CreateRoomTextField(
            controller:
                _districtController,
            label: 'Quận/Huyện',
            enabled:
                editingNewProperty,
            onChanged: (value) {
              draft.district = value;
              draft.changed();
            },
          ),

          CreateRoomTextField(
            controller:
                _wardController,
            label: 'Phường/Xã',
            required: true,
            enabled:
                editingNewProperty,
            onChanged: (value) {
              draft.ward = value;
              draft.changed();
            },
          ),
        ],
      ),
    );
  }

  void _onPropertyChanged(
    String? value,
  ) {
    final selected =
        value ==
                _newPropertyValue
            ? null
            : widget.properties
                .firstWhere(
                (item) =>
                    item.id == value,
              );

    _addressDebounce?.cancel();
    _addressRequestId++;

    widget.draft.selectProperty(
      selected,
    );

    _syncControllersFromDraft();

    setState(() {
      _searchingAddress = false;
      _addressSearchError = null;
    });
  }

  void _scheduleAddressSearch(
    String rawAddress,
  ) {
    _addressDebounce?.cancel();

    final address =
        rawAddress.trim();

    if (address.length < 5) {
      if (_searchingAddress ||
          _addressSearchError !=
              null) {
        setState(() {
          _searchingAddress =
              false;
          _addressSearchError =
              null;
        });
      }

      return;
    }

    _addressDebounce = Timer(
      const Duration(
        milliseconds: 850,
      ),
      () {
        _searchAddress(
          address,
        );
      },
    );
  }

  Future<void> _searchAddress(
    String address,
  ) async {
    if (!mounted ||
        widget.draft.propertyId !=
            null) {
      return;
    }

    final requestId =
        ++_addressRequestId;

    setState(() {
      _searchingAddress = true;
      _addressSearchError = null;
    });

    try {
      final result = await ref.read(
        forwardGeocodeProvider(
          address,
        ).future,
      );

      if (!mounted ||
          requestId !=
              _addressRequestId ||
          widget.draft.propertyId !=
              null) {
        return;
      }

      final draft = widget.draft;

      draft.addressText = result
          .address.formattedAddress;

      draft.latitude =
          result.latitude;

      draft.longitude =
          result.longitude;

      draft.province =
          result.address.province;

      draft.district =
          result.address.district;

      draft.ward =
          result.address.ward;

      _setControllerText(
        _addressController,
        draft.addressText,
      );

      _setControllerText(
        _provinceController,
        draft.province,
      );

      _setControllerText(
        _districtController,
        draft.district,
      );

      _setControllerText(
        _wardController,
        draft.ward,
      );

      draft.changed();

      // Chỉ rebuild một lần sau khi
      // forward geocode hoàn tất để map
      // nhận lat/lng mới và animate.
      setState(() {
        _searchingAddress = false;
        _addressSearchError = null;
      });
    } catch (_) {
      if (!mounted ||
          requestId !=
              _addressRequestId) {
        return;
      }

      setState(() {
        _searchingAddress = false;
        _addressSearchError =
            'Không tìm thấy vị trí phù hợp với địa chỉ này.';
      });
    }
  }

  void _onMapLocationChanged(
    PropertyInlineMapResult result,
  ) {
    if (widget.draft.propertyId !=
        null) {
      return;
    }

    _addressDebounce?.cancel();
    _addressRequestId++;

    final draft = widget.draft;

    draft.latitude =
        result.latitude;

    draft.longitude =
        result.longitude;

    draft.addressText =
        result.addressText;

    draft.province =
        result.province;

    draft.district =
        result.district;

    draft.ward = result.ward;

    // Không setState và không dùng ValueKey.
    // Chỉ cập nhật trực tiếp controller.
    _setControllerText(
      _addressController,
      draft.addressText,
    );

    _setControllerText(
      _provinceController,
      draft.province,
    );

    _setControllerText(
      _districtController,
      draft.district,
    );

    _setControllerText(
      _wardController,
      draft.ward,
    );

    draft.changed();
  }

  void _syncControllersFromDraft() {
    final draft = widget.draft;

    _setControllerText(
      _nameController,
      draft.propertyName,
    );

    _setControllerText(
      _addressController,
      draft.addressText,
    );

    _setControllerText(
      _provinceController,
      draft.province,
    );

    _setControllerText(
      _districtController,
      draft.district,
    );

    _setControllerText(
      _wardController,
      draft.ward,
    );
  }

  void _setControllerText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) {
      return;
    }

    controller.value =
        TextEditingValue(
      text: value,
      selection:
          TextSelection.collapsed(
        offset: value.length,
      ),
    );
  }

  void _message(
    String value,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(value),
      ),
    );
  }
}
