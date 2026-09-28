import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/create_room_reference.dart';
import '../../../domain/entities/location/geocoded_address.dart';
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
  ConsumerState<PropertyStep> createState() => _PropertyStepState();
}

class _PropertyStepState extends ConsumerState<PropertyStep> {
  static const String _newPropertyValue = '__CREATE_NEW_PROPERTY__';

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _provinceController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;

  final FocusNode _addressFocusNode = FocusNode();

  Timer? _autocompleteDebounce;

  List<GoongPlacePrediction> _suggestions = const [];

  bool _loadingSuggestions = false;
  bool _selectingSuggestion = false;

  String? _autocompleteError;

  int _autocompleteRequestId = 0;
  int _placeDetailRequestId = 0;

  @override
  void initState() {
    super.initState();

    final draft = widget.draft;

    _nameController = TextEditingController(text: draft.propertyName);

    _addressController = TextEditingController(text: draft.addressText);

    _provinceController = TextEditingController(text: draft.province);

    _districtController = TextEditingController(text: draft.district);

    _wardController = TextEditingController(text: draft.ward);

    _addressFocusNode.addListener(_handleAddressFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PropertyStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.draft, widget.draft)) {
      _syncControllersFromDraft();
    }
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();

    _addressFocusNode
      ..removeListener(_handleAddressFocusChanged)
      ..dispose();

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

    final editingNewProperty = draft.propertyId == null;

    return CreateRoomStepLayout(
      step: 1,
      title: 'Vị trí khu trọ',
      onBack: widget.onClose,
      onNext: () {
        if (!draft.isPropertyValid) {
          _message(
            'Bạn cần chọn khu trọ hoặc chọn một địa chỉ hợp lệ trên bản đồ.',
          );
          return;
        }

        widget.onNext();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: draft.propertyId ?? _newPropertyValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khu trọ của bạn',
              prefixIcon: Icon(Icons.apartment_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: _newPropertyValue,
                child: Text('Tạo khu trọ mới'),
              ),
              ...widget.properties.map(
                (property) => DropdownMenuItem<String>(
                  value: property.id,
                  child: Text(property.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: widget.isLoadingProperties ? null : _onPropertyChanged,
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
            controller: _nameController,
            label: 'Tên khu trọ',
            required: true,
            enabled: editingNewProperty,
            hint: 'Ví dụ: Nhà trọ An Bình',
            onChanged: (value) {
              draft.propertyName = value;
              draft.changed();
            },
          ),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                Future<void>.delayed(const Duration(milliseconds: 160), () {
                  if (!mounted ||
                      _selectingSuggestion ||
                      _addressFocusNode.hasFocus) {
                    return;
                  }

                  _clearSuggestionState();
                });
              }
            },
            child: CreateRoomTextField(
              controller: _addressController,
              focusNode: _addressFocusNode,
              label: 'Địa chỉ',
              required: true,
              enabled: editingNewProperty,
              keyboardType: TextInputType.streetAddress,
              hint: 'Nhập số nhà, tên đường hoặc địa điểm...',
              onChanged: editingNewProperty ? _onAddressChanged : (_) {},
            ),
          ),

          if (editingNewProperty)
            _AutocompleteArea(
              loading: _loadingSuggestions,
              selecting: _selectingSuggestion,
              error: _autocompleteError,
              suggestions: _suggestions,
              onSelected: _selectSuggestion,
            ),

          PropertyInlineMap(
            latitude: draft.latitude,
            longitude: draft.longitude,
            addressText: draft.addressText,
            enabled: editingNewProperty,
            onLocationChanged: _onMapLocationChanged,
          ),

          CreateRoomTextField(
            controller: _provinceController,
            label: 'Tỉnh/Thành phố',
            required: true,
            enabled: editingNewProperty,
            onChanged: (value) {
              draft.province = value;
              draft.changed();
            },
          ),

          CreateRoomTextField(
            controller: _districtController,
            label: 'Quận/Huyện',
            enabled: editingNewProperty,
            onChanged: (value) {
              draft.district = value;
              draft.changed();
            },
          ),

          CreateRoomTextField(
            controller: _wardController,
            label: 'Phường/Xã',
            required: true,
            enabled: editingNewProperty,
            onChanged: (value) {
              draft.ward = value;
              draft.changed();
            },
          ),
        ],
      ),
    );
  }

  void _onPropertyChanged(String? value) {
    final selected = value == _newPropertyValue
        ? null
        : widget.properties.firstWhere((item) => item.id == value);

    _cancelSearchRequests();

    widget.draft.selectProperty(selected);

    _syncControllersFromDraft();

    setState(() {
      _suggestions = const [];
      _loadingSuggestions = false;
      _selectingSuggestion = false;
      _autocompleteError = null;
    });
  }

  /// User đang gõ:
  /// - chỉ cập nhật chữ họ đang nhập;
  /// - KHÔNG tự chọn kết quả;
  /// - KHÔNG tự di chuyển map.
  void _onAddressChanged(String value) {
    final draft = widget.draft;

    draft.addressText = value;

    // Nếu trước đó đã chọn một vị trí mà user bắt đầu sửa địa chỉ,
    // tọa độ cũ không còn được xem là địa chỉ đã xác nhận.
    if (draft.latitude != null || draft.longitude != null) {
      draft.latitude = null;
      draft.longitude = null;

      draft.province = '';
      draft.district = '';
      draft.ward = '';

      _setControllerText(_provinceController, '');

      _setControllerText(_districtController, '');

      _setControllerText(_wardController, '');
    }

    draft.changed();

    _scheduleAutocomplete(value);
  }

  void _scheduleAutocomplete(String rawInput) {
    _autocompleteDebounce?.cancel();

    final input = rawInput.trim();

    if (input.length < 2) {
      _autocompleteRequestId++;

      if (mounted) {
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
          _autocompleteError = null;
        });
      }

      return;
    }

    _autocompleteDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(input);
    });
  }

  Future<void> _loadSuggestions(String input) async {
    if (!mounted || widget.draft.propertyId != null) {
      return;
    }

    final requestId = ++_autocompleteRequestId;

    setState(() {
      _loadingSuggestions = true;
      _autocompleteError = null;
    });

    try {
      final result = await ref
          .read(goongLocationDataSourceProvider)
          .autocomplete(input: input, limit: 5);

      if (!mounted || requestId != _autocompleteRequestId) {
        return;
      }

      // Chỉ hiển thị suggestion nếu input hiện tại
      // vẫn đúng với truy vấn đã gửi.
      if (_addressController.text.trim() != input) {
        return;
      }

      setState(() {
        _suggestions = result;
        _loadingSuggestions = false;

        _autocompleteError = result.isEmpty
            ? 'Không tìm thấy địa điểm phù hợp.'
            : null;
      });
    } catch (_) {
      if (!mounted || requestId != _autocompleteRequestId) {
        return;
      }

      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
        _autocompleteError = 'Không tải được gợi ý địa điểm.';
      });
    }
  }

  /// Chỉ TẠI ĐÂY map mới được di chuyển từ ô search.
  /// Hàm chỉ chạy khi user bấm một suggestion.
  Future<void> _selectSuggestion(GoongPlacePrediction prediction) async {
    if (_selectingSuggestion) {
      return;
    }

    _autocompleteDebounce?.cancel();

    final requestId = ++_placeDetailRequestId;

    _autocompleteRequestId++;

    setState(() {
      _selectingSuggestion = true;
      _loadingSuggestions = false;
      _autocompleteError = null;
    });

    try {
      final detail = await ref
          .read(goongLocationDataSourceProvider)
          .placeDetail(placeId: prediction.placeId);

      if (!mounted || requestId != _placeDetailRequestId) {
        return;
      }

      final draft = widget.draft;

      final selectedAddress = detail.address.formattedAddress.isNotEmpty
          ? detail.address.formattedAddress
          : prediction.description;

      draft.addressText = selectedAddress;

      draft.latitude = detail.latitude;

      draft.longitude = detail.longitude;

      draft.province = detail.address.province;

      draft.district = detail.address.district;

      draft.ward = detail.address.ward;

      _setControllerText(_addressController, draft.addressText);

      _setControllerText(_provinceController, draft.province);

      _setControllerText(_districtController, draft.district);

      _setControllerText(_wardController, draft.ward);

      draft.changed();

      _addressFocusNode.unfocus();

      // Chỉ rebuild một lần sau khi đã chọn.
      // PropertyInlineMap nhận lat/lng mới và animate tới đó.
      setState(() {
        _suggestions = const [];
        _selectingSuggestion = false;
        _autocompleteError = null;
      });
    } catch (_) {
      if (!mounted || requestId != _placeDetailRequestId) {
        return;
      }

      setState(() {
        _selectingSuggestion = false;
        _autocompleteError = 'Không lấy được chi tiết địa điểm này.';
      });
    }
  }

  /// Chiều ngược:
  /// User kéo map -> reverse geocode -> cập nhật form.
  ///
  /// Không gọi autocomplete lại vì controller.text được thay
  /// bằng code, không phải thao tác gõ của user.
  void _onMapLocationChanged(PropertyInlineMapResult result) {
    if (widget.draft.propertyId != null) {
      return;
    }

    _cancelSearchRequests();

    final draft = widget.draft;

    draft.latitude = result.latitude;

    draft.longitude = result.longitude;

    draft.addressText = result.addressText;

    draft.province = result.province;

    draft.district = result.district;

    draft.ward = result.ward;

    _setControllerText(_addressController, draft.addressText);

    _setControllerText(_provinceController, draft.province);

    _setControllerText(_districtController, draft.district);

    _setControllerText(_wardController, draft.ward);

    draft.changed();

    if (_suggestions.isNotEmpty ||
        _loadingSuggestions ||
        _autocompleteError != null) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
        _autocompleteError = null;
      });
    }
  }

  void _handleAddressFocusChanged() {
    // Listener thật của TextField.
    // Focus wrapper phía trên xử lý việc đóng suggestion.
  }

  void _clearSuggestionState() {
    if (!mounted) {
      return;
    }

    _autocompleteDebounce?.cancel();
    _autocompleteRequestId++;

    if (_suggestions.isEmpty &&
        !_loadingSuggestions &&
        _autocompleteError == null) {
      return;
    }

    setState(() {
      _suggestions = const [];
      _loadingSuggestions = false;
      _autocompleteError = null;
    });
  }

  void _cancelSearchRequests() {
    _autocompleteDebounce?.cancel();
    _autocompleteRequestId++;
    _placeDetailRequestId++;
  }

  void _syncControllersFromDraft() {
    final draft = widget.draft;

    _setControllerText(_nameController, draft.propertyName);

    _setControllerText(_addressController, draft.addressText);

    _setControllerText(_provinceController, draft.province);

    _setControllerText(_districtController, draft.district);

    _setControllerText(_wardController, draft.ward);
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _AutocompleteArea extends StatelessWidget {
  const _AutocompleteArea({
    required this.loading,
    required this.selecting,
    required this.error,
    required this.suggestions,
    required this.onSelected,
  });

  final bool loading;
  final bool selecting;
  final String? error;
  final List<GoongPlacePrediction> suggestions;
  final ValueChanged<GoongPlacePrediction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (selecting) {
      return const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text('Đang lấy vị trí đã chọn...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (loading && suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text('Đang tìm địa điểm...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      if (error == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 14),
        child: Text(
          error!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suggestions.length; i++) ...[
            _SuggestionTile(
              prediction: suggestions[i],
              onTap: () {
                onSelected(suggestions[i]);
              },
            ),
            if (i != suggestions.length - 1)
              const Divider(height: 1, indent: 50),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.prediction, required this.onTap});

  final GoongPlacePrediction prediction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF008E78),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (prediction.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      prediction.secondaryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7673),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
