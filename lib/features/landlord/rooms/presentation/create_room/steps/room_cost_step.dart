import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/create_room_reference.dart';
import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _cardBorder = Color(0xFFE3ECE9);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);
const _fieldFill = Color(0xFFF8FAFA);

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
  final VoidCallback onRetryAmenities;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<RoomCostStep> createState() => _RoomCostStepState();
}

class _RoomCostStepState extends State<RoomCostStep> {
  late final TextEditingController _otherDescriptionController;

  CreateRoomDraft get draft => widget.draft;

  @override
  void initState() {
    super.initState();

    _otherDescriptionController = TextEditingController(
      text: widget.draft.otherDescription,
    );
  }

  @override
  void dispose() {
    _otherDescriptionController.dispose();
    super.dispose();
  }

  int get _fixedTotal =>
      draft.internetFee +
      draft.parkingFee +
      draft.serviceFee +
      draft.cleaningFee +
      draft.otherFee;

  void _update(VoidCallback action) {
    setState(action);
    draft.changed();
  }

  @override
  Widget build(BuildContext context) {
    return CreateRoomStepLayout(
      step: 4,
      title: '',
      onBack: widget.onBack,
      onNext: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi phí & tiện ích',
            style: TextStyle(
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Khai báo chi phí sinh hoạt và các tiện ích có trong phòng '
            'để người thuê dễ quyết định hơn.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // =========================
          // CHI PHÍ
          // =========================
          _SectionCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Chi phí sinh hoạt',
            subtitle: 'Nhập các khoản chi phí cố định và cách tính (nếu có)',
            child: Column(
              children: [
                _UtilityCostRow(
                  icon: Icons.bolt_rounded,
                  label: 'Tiền điện',
                  type: draft.electricityType,
                  types: const {
                    'PER_KWH': 'Theo số điện (kWh)',
                    'INCLUDED': 'Đã gồm trong giá',
                    'FREE': 'Miễn phí',
                  },
                  value: draft.electricityPrice,
                  unit: 'VNĐ/kWh',
                  onTypeChanged: (value) => _update(() {
                    draft.electricityType = value;

                    if (value == 'INCLUDED' || value == 'FREE') {
                      draft.electricityPrice = 0;
                    }
                  }),
                  onValueChanged: (value) => _update(() {
                    draft.electricityPrice = value;
                  }),
                ),
                _UtilityCostRow(
                  icon: Icons.water_drop_rounded,
                  label: 'Tiền nước',
                  type: draft.waterType,
                  types: const {
                    'PER_M3': 'Theo số nước (m³)',
                    'PER_PERSON': 'Theo đầu người',
                    'INCLUDED': 'Đã gồm trong giá',
                    'FREE': 'Miễn phí',
                  },
                  value: draft.waterPrice,
                  unit: draft.waterType == 'PER_PERSON'
                      ? 'VNĐ/người'
                      : 'VNĐ/m³',
                  onTypeChanged: (value) => _update(() {
                    draft.waterType = value;

                    if (value == 'INCLUDED' || value == 'FREE') {
                      draft.waterPrice = 0;
                    }
                  }),
                  onValueChanged: (value) => _update(() {
                    draft.waterPrice = value;
                  }),
                ),
                _SimpleCostRow(
                  icon: Icons.wifi_rounded,
                  label: 'Internet',
                  value: draft.internetFee,
                  onChanged: (value) => _update(() {
                    draft.internetFee = value;
                  }),
                ),
                _SimpleCostRow(
                  icon: Icons.two_wheeler_rounded,
                  label: 'Gửi xe',
                  value: draft.parkingFee,
                  onChanged: (value) => _update(() {
                    draft.parkingFee = value;
                  }),
                ),
                _SimpleCostRow(
                  icon: Icons.settings_rounded,
                  label: 'Phí dịch vụ',
                  value: draft.serviceFee,
                  onChanged: (value) => _update(() {
                    draft.serviceFee = value;
                  }),
                ),
                _SimpleCostRow(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Phí vệ sinh',
                  value: draft.cleaningFee,
                  onChanged: (value) => _update(() {
                    draft.cleaningFee = value;
                  }),
                ),
                _SimpleCostRow(
                  icon: Icons.more_horiz_rounded,
                  label: 'Phí khác',
                  value: draft.otherFee,
                  onChanged: (value) => _update(() {
                    draft.otherFee = value;
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otherDescriptionController,
                  maxLines: 2,
                  onChanged: (value) {
                    draft.otherDescription = value;
                    draft.changed();
                  },
                  decoration: _descriptionDecoration(
                    label: 'Mô tả phí khác',
                    hint: 'Nhập mô tả nếu có...',
                  ),
                ),
                const SizedBox(height: 14),
                _TotalCost(total: _fixedTotal),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // TIỆN ÍCH
          // =========================
          _SectionCard(
            icon: Icons.weekend_rounded,
            title: 'Tiện ích',
            subtitle: 'Chọn các tiện ích có trong phòng',
            child: _AmenityGrid(
              amenities: widget.amenities,
              selectedCodes: draft.amenityCodes,
              loading: widget.isLoadingAmenities,
              onRetry: widget.onRetryAmenities,
              onToggle: (code) {
                setState(() {
                  draft.toggleAmenity(code);
                });
              },
            ),
          ),

          const SizedBox(height: 14),
          const _TipBox(),
        ],
      ),
    );
  }
}

// =============================================================
// SECTION CARD
// =============================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F6EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _greenDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// =============================================================
// ELECTRIC / WATER ROW
// =============================================================

class _UtilityCostRow extends StatelessWidget {
  const _UtilityCostRow({
    required this.icon,
    required this.label,
    required this.type,
    required this.types,
    required this.value,
    required this.unit,
    required this.onTypeChanged,
    required this.onValueChanged,
  });

  final IconData icon;
  final String label;
  final String type;
  final Map<String, String> types;
  final int value;
  final String unit;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onValueChanged;

  bool get _priceEnabled => type != 'INCLUDED' && type != 'FREE';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 350;

        if (narrow) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CostLabel(
                  icon: icon,
                  label: label,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _TypeDropdown(
                        value: type,
                        items: types,
                        onChanged: onTypeChanged,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      flex: 4,
                      child: _MoneyField(
                        key: ValueKey('$label-$type'),
                        value: value,
                        enabled: _priceEnabled,
                        onChanged: onValueChanged,
                      ),
                    ),
                  ],
                ),
                if (_priceEnabled) ...[
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                child: _CostLabel(
                  icon: icon,
                  label: label,
                ),
              ),
              Expanded(
                flex: 6,
                child: _TypeDropdown(
                  value: type,
                  items: types,
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 92,
                child: _MoneyField(
                  key: ValueKey('$label-$type'),
                  value: value,
                  enabled: _priceEnabled,
                  onChanged: onValueChanged,
                ),
              ),
              const SizedBox(width: 6),
              _UnitPill(
                _priceEnabled
                    ? unit
                    : type == 'FREE'
                        ? 'Miễn phí'
                        : 'Đã gồm',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      decoration: _compactDecoration(),
      items: items.entries
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.key,
              child: Text(
                item.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

// =============================================================
// SIMPLE MONTHLY COST
// =============================================================

class _SimpleCostRow extends StatelessWidget {
  const _SimpleCostRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _CostLabel(
              icon: icon,
              label: label,
            ),
          ),
          SizedBox(
            width: 104,
            child: _MoneyField(
              value: value,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 6),
          const _UnitPill('VNĐ/tháng'),
        ],
      ),
    );
  }
}

class _CostLabel extends StatelessWidget {
  const _CostLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Icon(
            icon,
            color: _green,
            size: 23,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// MONEY FIELD
// =============================================================

class _MoneyField extends StatefulWidget {
  const _MoneyField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<_MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<_MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: _displayMoney(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant _MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      final nextText = _displayMoney(widget.value);

      if (_controller.text != nextText) {
        _controller.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(
            offset: nextText.length,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      inputFormatters: [
        _MoneyInputFormatter(),
      ],
      onChanged: (text) {
        widget.onChanged(
          int.tryParse(_digits(text)) ?? 0,
        );
      },
      decoration: _compactDecoration(
        hint: '0',
        disabled: !widget.enabled,
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      constraints: const BoxConstraints(
        minWidth: 74,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10.5,
          height: 1.15,
          color: _textSecondary,
        ),
      ),
    );
  }
}

// =============================================================
// TOTAL COST
// =============================================================

class _TotalCost extends StatelessWidget {
  const _TotalCost({
    required this.total,
  });

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE7F9F4),
            Color(0xFFF0FCF9),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD1F0E7),
        ),
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
            child: const Icon(
              Icons.calculate_rounded,
              color: _greenDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Tổng chi phí cố định tham khảo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF287568),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Color(0xFF4E8B80),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatMoney(total)} VNĐ/tháng',
                  style: const TextStyle(
                    color: _greenDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  '(chưa gồm điện, nước theo mức sử dụng)',
                  style: TextStyle(
                    fontSize: 10.5,
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
// AMENITY GRID
// =============================================================

class _AmenityGrid extends StatelessWidget {
  const _AmenityGrid({
    required this.amenities,
    required this.selectedCodes,
    required this.loading,
    required this.onRetry,
    required this.onToggle,
  });

  final List<AmenityOption> amenities;
  final Set<String> selectedCodes;
  final bool loading;
  final VoidCallback onRetry;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _green,
          ),
        ),
      );
    }

    if (amenities.isEmpty) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Tải lại tiện ích',
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= 340 ? 4 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: amenities.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.03,
          ),
          itemBuilder: (_, index) {
            final amenity = amenities[index];
            final selected = selectedCodes.contains(
              amenity.code,
            );

            return _AmenityTile(
              amenity: amenity,
              selected: selected,
              onTap: () => onToggle(
                amenity.code,
              ),
            );
          },
        );
      },
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({
    required this.amenity,
    required this.selected,
    required this.onTap,
  });

  final AmenityOption amenity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFE7F9F4)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  5,
                  10,
                  5,
                  6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? _green
                        : const Color(0xFFDDE5E2),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _amenityIcon(
                        amenity.code,
                        amenity.name,
                      ),
                      color: selected
                          ? _greenDark
                          : const Color(0xFF263833),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amenity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 5,
                top: 5,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: _green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TIP
// =============================================================

class _TipBox extends StatelessWidget {
  const _TipBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD5EEF5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFBCE8F5),
            child: Icon(
              Icons.info_rounded,
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
                  'Gợi ý hiển thị',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF146D67),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Thông tin rõ ràng về chi phí và tiện ích giúp bài đăng '
                  'tăng độ tin cậy và dễ thu hút người thuê hơn.',
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
// DECORATIONS / HELPERS
// =============================================================

InputDecoration _compactDecoration({
  String? hint,
  bool disabled = false,
}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: disabled
        ? const Color(0xFFF0F2F2)
        : _fieldFill,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 13,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFDDE5E2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFDDE5E2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: _green,
        width: 1.4,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFE1E6E5),
      ),
    ),
  );
}

InputDecoration _descriptionDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    prefixIcon: const Padding(
      padding: EdgeInsets.only(bottom: 34),
      child: Icon(
        Icons.chat_rounded,
        color: _green,
      ),
    ),
    filled: true,
    fillColor: _fieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(
        color: Color(0xFFDDE5E2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(
        color: Color(0xFFDDE5E2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(
        color: _green,
        width: 1.4,
      ),
    ),
  );
}

IconData _amenityIcon(
  String code,
  String name,
) {
  final value = '$code $name'.toUpperCase();

  if (value.contains('WIFI')) {
    return Icons.wifi_rounded;
  }

  if (value.contains('AIR') ||
      value.contains('ĐIỀU HÒA')) {
    return Icons.ac_unit_rounded;
  }

  if (value.contains('WASH') ||
      value.contains('MÁY GIẶT')) {
    return Icons.local_laundry_service_rounded;
  }

  if (value.contains('FRIDGE') ||
      value.contains('TỦ LẠNH')) {
    return Icons.kitchen_rounded;
  }

  if (value.contains('WATER_HEATER') ||
      value.contains('NÓNG LẠNH')) {
    return Icons.hot_tub_rounded;
  }

  if (value.contains('FINGER') ||
      value.contains('VÂN TAY')) {
    return Icons.fingerprint_rounded;
  }

  if (value.contains('ELEVATOR') ||
      value.contains('THANG MÁY')) {
    return Icons.elevator_rounded;
  }

  if (value.contains('BALCONY') ||
      value.contains('BAN CÔNG')) {
    return Icons.balcony_rounded;
  }

  if (value.contains('PARK') ||
      value.contains('ĐỂ XE')) {
    return Icons.two_wheeler_rounded;
  }

  if (value.contains('CAMERA')) {
    return Icons.photo_camera_outlined;
  }

  if (value.contains('WARDROBE') ||
      value.contains('TỦ QUẦN')) {
    return Icons.door_sliding_outlined;
  }

  if (value.contains('BED') ||
      value.contains('GIƯỜNG')) {
    return Icons.bed_rounded;
  }

  if (value.contains('KITCHEN') ||
      value.contains('BẾP')) {
    return Icons.soup_kitchen_rounded;
  }

  return Icons.check_circle_outline_rounded;
}

class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(
      newValue.text,
    );

    final formatted = digits.isEmpty
        ? ''
        : _formatMoney(
            int.parse(digits),
          );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

String _digits(String value) {
  return value.replaceAll(
    RegExp(r'[^0-9]'),
    '',
  );
}

String _displayMoney(int value) {
  if (value <= 0) {
    return '0';
  }

  return _formatMoney(value);
}

String _formatMoney(int value) {
  final digits = value.toString();
  final output = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 &&
        (digits.length - index) % 3 == 0) {
      output.write('.');
    }

    output.write(
      digits[index],
    );
  }

  return output.toString();
}
