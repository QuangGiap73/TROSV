import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/create_room_reference.dart';
import '../../../domain/entities/location/geocoded_address.dart';
import '../models/create_room_draft.dart';
import '../providers/property_location_provider.dart';
import '../widgets/create_room_step_layout.dart';
import 'property_inline_map.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _cardBorder = Color(0xFFE3ECE9);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);
const _fieldFill = Color(0xFFF9FBFA);

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
      title: '',
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
          const _PageHeader(),

          const SizedBox(height: 20),

          if (draft.isEditing)
            const _EditPropertyNotice()
          else
            _PropertySelectorCard(
              selectedValue: draft.propertyId ?? _newPropertyValue,
              properties: widget.properties,
              loading: widget.isLoadingProperties,
              onChanged: widget.isLoadingProperties ? null : _onPropertyChanged,
              onRetry: widget.onRetryProperties,
            ),

          const SizedBox(height: 18),

          _FormSection(
            icon: Icons.home_work_rounded,
            title: 'Thông tin khu trọ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateRoomTextField(
                  controller: _nameController,
                  label: 'Tên khu trọ',
                  required: true,
                  enabled: editingNewProperty,
                  hint: 'VD: Nhà trọ Bình Minh',
                  onChanged: (value) {
                    draft.propertyName = value;
                    draft.changed();
                  },
                ),

                Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      Future<void>.delayed(
                        const Duration(milliseconds: 160),
                        () {
                          if (!mounted ||
                              _selectingSuggestion ||
                              _addressFocusNode.hasFocus) {
                            return;
                          }

                          _clearSuggestionState();
                        },
                      );
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          _MapSection(
            child: PropertyInlineMap(
              latitude: draft.latitude,
              longitude: draft.longitude,
              addressText: draft.addressText,
              enabled: editingNewProperty,
              onLocationChanged: _onMapLocationChanged,
            ),
          ),

          const SizedBox(height: 16),

          _FormSection(
            icon: Icons.location_city_rounded,
            title: 'Khu vực hành chính',
            subtitle: editingNewProperty
                ? 'Thông tin được tự động điền khi bạn chọn địa chỉ hoặc kéo bản đồ.'
                : 'Thông tin khu vực của khu trọ đã chọn.',
            child: Column(
              children: [
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
          ),

          const SizedBox(height: 14),

          const _LocationTip(),
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

  void _onAddressChanged(String value) {
    final draft = widget.draft;

    draft.addressText = value;

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

  void _handleAddressFocusChanged() {}

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

// =============================================================
// PAGE HEADER
// =============================================================

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: _greenDark, size: 25),
            SizedBox(width: 8),
            Text(
              'Vị trí khu trọ',
              style: TextStyle(
                fontSize: 25,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 7),
        Text(
          'Chọn hoặc tạo khu trọ, sau đó xác định vị trí chính xác '
          'để người thuê dễ dàng tìm thấy phòng của bạn.',
          style: TextStyle(fontSize: 13.5, height: 1.45, color: _textSecondary),
        ),
      ],
    );
  }
}

// =============================================================
// PROPERTY SELECTOR
// =============================================================

class _PropertySelectorCard extends StatelessWidget {
  const _PropertySelectorCard({
    required this.selectedValue,
    required this.properties,
    required this.loading,
    required this.onChanged,
    required this.onRetry,
  });

  final String selectedValue;
  final List<LandlordProperty> properties;
  final bool loading;
  final ValueChanged<String?>? onChanged;
  final VoidCallback onRetry;

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
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF7F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: _greenDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khu trọ của bạn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chọn khu trọ có sẵn hoặc tạo khu trọ mới.',
                      style: TextStyle(fontSize: 11.5, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: selectedValue,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _greenDark,
            ),
            decoration: _selectorDecoration(),
            items: [
              const DropdownMenuItem<String>(
                value: _PropertyStepState._newPropertyValue,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_business_rounded,
                      size: 19,
                      color: _greenDark,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Tạo khu trọ mới',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ...properties.map(
                (property) => DropdownMenuItem<String>(
                  value: property.id,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        size: 18,
                        color: Color(0xFF526B65),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          property.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),

          if (loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              minHeight: 2,
              color: _green,
              backgroundColor: Color(0xFFE3F1ED),
            ),
          ],

          if (!loading && properties.isEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tải lại danh sách'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditPropertyNotice extends StatelessWidget {
  const _EditPropertyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DEAE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF9B7018)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phòng đang thuộc khu trọ này. Backend hiện chưa hỗ trợ đổi '
              'khu trọ khi chỉnh sửa phòng.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF795B1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// FORM SECTION
// =============================================================

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
            color: Color(0x08000000),
            blurRadius: 12,
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
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

          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

// =============================================================
// MAP SECTION
// =============================================================

class _MapSection extends StatelessWidget {
  const _MapSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(5, 4, 5, 9),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: _greenDark, size: 21),
                SizedBox(width: 7),
                Text(
                  'Chọn vị trí trên bản đồ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
        ],
      ),
    );
  }
}

// =============================================================
// LOCATION TIP
// =============================================================

class _LocationTip extends StatelessWidget {
  const _LocationTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5EEF5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFBCE8F5),
            child: Icon(
              Icons.location_searching_rounded,
              color: Color(0xFF159BD3),
              size: 21,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vị trí chính xác rất quan trọng',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF146D67),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ghim đúng vị trí giúp người thuê dễ tìm phòng, '
                  'ước lượng khoảng cách đến trường và xem đường đi thuận tiện hơn.',
                  style: TextStyle(
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
// AUTOCOMPLETE
// =============================================================

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
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            ),
            SizedBox(width: 9),
            Text(
              'Đang lấy vị trí đã chọn...',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            ),
            SizedBox(width: 9),
            Text(
              'Đang tìm địa điểm...',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
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
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD7E5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
              const Divider(height: 1, indent: 54, color: Color(0xFFE8EEEC)),
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
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: _greenDark,
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    if (prediction.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        prediction.secondaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 6),
              const Icon(
                Icons.north_west_rounded,
                size: 16,
                color: Color(0xFF8AA19B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// DECORATION
// =============================================================

InputDecoration _selectorDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: _fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
