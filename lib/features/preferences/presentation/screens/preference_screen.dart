import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_preference.dart';
import '../../domain/entities/university_location.dart';
import '../providers/preference_provider.dart';

class PreferenceScreen extends ConsumerStatefulWidget {
  const PreferenceScreen({super.key});

  @override
  ConsumerState<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends ConsumerState<PreferenceScreen> {
  static const _primary = Color(0xFF00A98F);
  static const _primaryDark = Color(0xFF008E78);
  static const _navy = Color(0xFF14243B);
  static const _background = Color(0xFFF5F8F7);
  static const _muted = Color(0xFF7C8999);

  bool _formInitialized = false;

  String? _university;
  String? _district;
  double? _latitude;
  double? _longitude;

  double _radiusKm = 5;
  int _budgetMax = 2000000;
  int _maxPeople = 1;
  String? _roomType;

  Set<String> _selectedAmenities = {};
  bool _bathroomPrivate = false;
  bool _hasBalcony = false;
  bool _alertsEnabled = true;

  static const _defaultBudgets = <int>[
    2000000,
    3000000,
    4000000,
    5000000,
    6000000,
    8000000,
    10000000,
  ];

  static const _defaultRadii = <double>[1, 3, 5, 10, 20, 30, 50];

  static const _roomTypes = <String, String>{
    'ROOM_SINGLE': 'Phòng đơn',
    'ROOM_SHARED': 'Ở ghép',
    'STUDIO': 'Studio',
    'ONE_BEDROOM': 'Căn hộ 1PN',
    'WHOLE_HOUSE': 'Nguyên căn',
  };

  void _fillForm(TenantPreference? preference) {
    if (_formInitialized) return;

    _formInitialized = true;

    if (preference == null) return;

    _university = _emptyToNull(preference.university);
    _district = _emptyToNull(preference.district);
    _latitude = preference.latitude;
    _longitude = preference.longitude;
    _radiusKm = preference.radiusKm.clamp(1, 50).toDouble();

    if (preference.budgetMax > 0) {
      _budgetMax = preference.budgetMax;
    }

    _maxPeople = preference.maxPeople.clamp(1, 4);
    _roomType = preference.roomType;
    _selectedAmenities = preference.amenities.toSet();
    _bathroomPrivate = preference.bathroomPrivate;
    _hasBalcony = preference.hasBalcony;
    _alertsEnabled = preference.alertsEnabled;
  }

  Future<void> _save() async {
    final preference = TenantPreference(
      university: _university,
      district: _district,
      latitude: _latitude,
      longitude: _longitude,
      radiusKm: _radiusKm,
      budgetMax: _budgetMax,
      roomType: _roomType,
      maxPeople: _maxPeople,
      amenities: _selectedAmenities.toList(),
      bathroomPrivate: _bathroomPrivate,
      hasBalcony: _hasBalcony,
      alertsEnabled: _alertsEnabled,
    );

    final success = await ref
        .read(tenantPreferenceProvider.notifier)
        .save(preference);

    if (!mounted) return;

    if (success) {
      final viewMatches = await _showSavedDialog();
      if (viewMatches && mounted) {
        context.push('/rooms/matches');
      }
      return;
    }

    final error = ref.read(tenantPreferenceProvider).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(error?.toString() ?? 'Không thể lưu nhu cầu tìm phòng.'),
      ),
    );
  }

  Future<bool> _showSavedDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFDDF6EF),
              child: Icon(Icons.check_rounded, size: 38, color: _primaryDark),
            ),
            SizedBox(height: 18),
            Text(
              'Lưu nhu cầu thành công!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'TrọSV đã ghi nhận các tiêu chí của bạn. Bạn có muốn xem những phòng phù hợp ngay bây giờ không?',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Để sau'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Xem phòng phù hợp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openUniversityPicker() async {
    List<UniversityLocation> universities;
    try {
      universities = await ref.read(universitiesProvider.future);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách trường: $error')),
      );
      return;
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<UniversityLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UniversityPicker(
        universities: universities,
        selectedUniversity: _university,
        selectedDistrict: _district,
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _university = selected.name;
      _district = selected.district;
      _latitude = selected.latitude;
      _longitude = selected.longitude;
    });
  }

  Future<T?> _openOptionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T value) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .68,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 52),
                  itemBuilder: (_, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      onTap: () => Navigator.of(sheetContext).pop(option),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? _primary : const Color(0xFF9AA7B3),
                      ),
                      title: Text(
                        labelBuilder(option),
                        style: TextStyle(
                          color: _navy,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: isSelected
                          ? const Color(0xFFEAF8F4)
                          : Colors.transparent,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferenceState = ref.watch(tenantPreferenceProvider);
    final amenitiesState = ref.watch(amenitiesProvider);

    ref.listen<AsyncValue<TenantPreference?>>(tenantPreferenceProvider, (
      _,
      next,
    ) {
      next.whenData((preference) {
        if (!mounted || _formInitialized) return;

        setState(() {
          _fillForm(preference);
        });
      });
    });

    if (preferenceState.hasValue && !_formInitialized) {
      _fillForm(preferenceState.value);
    }

    if (preferenceState.isLoading && !_formInitialized) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (preferenceState.hasError && !_formInitialized) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Nhu cầu tìm phòng'),
        ),
        body: _ErrorView(
          message: preferenceState.error.toString(),
          onRetry: () {
            ref.invalidate(tenantPreferenceProvider);
          },
        ),
      );
    }

    final budgetOptions = {..._defaultBudgets, _budgetMax}.toList()..sort();

    final radiusOptions = {..._defaultRadii, _radiusKm}.toList()..sort();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: _navy,
          ),
        ),
        title: const Text(
          'Nhu cầu tìm phòng',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _IntroCard(),
          const SizedBox(height: 14),

          _SectionCard(
            icon: Icons.tune_rounded,
            title: 'Nhu cầu của bạn',
            children: [
              _PickerLabel(text: 'Trường đại học'),
              const SizedBox(height: 7),
              _TapField(
                icon: Icons.school_outlined,
                value: _university == null
                    ? 'Chọn trường đại học'
                    : '$_university · ${_district ?? ''}',
                placeholder: _university == null,
                onTap: _openUniversityPicker,
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PickerLabel(text: 'Ngân sách tối đa'),
                        const SizedBox(height: 7),
                        _TapField(
                          icon: Icons.payments_outlined,
                          value: '${_formatMoneyShort(_budgetMax)} / tháng',
                          onTap: () async {
                            final value = await _openOptionSheet<int>(
                              title: 'Chọn ngân sách tối đa',
                              options: budgetOptions,
                              selected: _budgetMax,
                              labelBuilder: (item) =>
                                  '${_formatMoneyShort(item)} / tháng',
                            );
                            if (value != null && mounted) {
                              setState(() => _budgetMax = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PickerLabel(text: 'Bán kính'),
                        const SizedBox(height: 7),
                        _TapField(
                          icon: Icons.radar_rounded,
                          value: 'Trong ${_formatRadius(_radiusKm)} km',
                          onTap: () async {
                            final value = await _openOptionSheet<double>(
                              title: 'Chọn bán kính tìm kiếm',
                              options: radiusOptions,
                              selected: _radiusKm,
                              labelBuilder: (item) =>
                                  'Trong ${_formatRadius(item)} km',
                            );
                            if (value != null && mounted) {
                              setState(() => _radiusKm = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const _PickerLabel(text: 'Loại phòng'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _roomType == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _roomType = null),
                  ),
                  ..._roomTypes.entries.map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _roomType == entry.key,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _roomType = entry.key);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const _PickerLabel(text: 'Số người ở'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: List.generate(
                    4,
                    (index) => ButtonSegment<int>(
                      value: index + 1,
                      label: Text('${index + 1}'),
                    ),
                  ),
                  selected: {_maxPeople},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(vertical: 2),
                  ),
                  onSelectionChanged: (values) {
                    setState(() => _maxPeople = values.first);
                  },
                ),
              ),

              const SizedBox(height: 18),

              const _PickerLabel(text: 'Tiện ích mong muốn'),
              const SizedBox(height: 10),

              amenitiesState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                ),
                error: (error, _) => Column(
                  children: [
                    Text(
                      'Không thể tải tiện ích: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(amenitiesProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
                data: (amenities) {
                  if (amenities.isEmpty) {
                    return const Text(
                      'Hiện chưa có tiện ích.',
                      style: TextStyle(color: _muted),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenities.map((amenity) {
                      final selected = _selectedAmenities.contains(
                        amenity.code,
                      );

                      return FilterChip(
                        label: Text(amenity.name),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: const Color(0xFFDDF6EF),
                        backgroundColor: const Color(0xFFF7F9FA),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFFB7E6DA)
                              : const Color(0xFFE0E7E5),
                        ),
                        labelStyle: TextStyle(
                          color: selected ? _primaryDark : _navy,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              if (_selectedAmenities.length < 20) {
                                _selectedAmenities.add(amenity.code);
                              }
                            } else {
                              _selectedAmenities.remove(amenity.code);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 18),

              _CheckOption(
                title: 'WC khép kín',
                value: _bathroomPrivate,
                onChanged: (value) {
                  setState(() => _bathroomPrivate = value);
                },
              ),
              const SizedBox(height: 10),
              _CheckOption(
                title: 'Có ban công / thoáng gió',
                value: _hasBalcony,
                onChanged: (value) {
                  setState(() => _hasBalcony = value);
                },
              ),

              const SizedBox(height: 10),

              _AlertOption(
                value: _alertsEnabled,
                onChanged: (value) {
                  setState(() => _alertsEnabled = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: preferenceState.isLoading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withValues(alpha: .45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: preferenceState.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: const Text(
                'Lưu nhu cầu',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Sau khi hoàn thiện màn kết quả match, nút này có thể đổi thành “Tìm phòng phù hợp” và gọi POST /api/v1/rooms/match.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _formatMoneyShort(int value) {
    if (value % 1000000 == 0) {
      return '${value ~/ 1000000} triệu';
    }

    return '${(value / 1000000).toStringAsFixed(1)} triệu';
  }

  static String _formatRadius(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _UniversityPicker extends StatefulWidget {
  const _UniversityPicker({
    required this.universities,
    required this.selectedUniversity,
    required this.selectedDistrict,
  });

  final List<UniversityLocation> universities;
  final String? selectedUniversity;
  final String? selectedDistrict;

  @override
  State<_UniversityPicker> createState() => _UniversityPickerState();
}

class _UniversityPickerState extends State<_UniversityPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();

    final items = widget.universities.where((item) {
      if (normalized.isEmpty) return true;

      return item.label.toLowerCase().contains(normalized);
    }).toList();

    return FractionallySizedBox(
      heightFactor: .82,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text(
              'Chọn trường đại học',
              style: TextStyle(
                color: _PreferenceScreenState._navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _query = value);
              },
              decoration: InputDecoration(
                hintText: 'Tìm trường đại học...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F8F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Không tìm thấy trường phù hợp.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 58),
                    itemBuilder: (_, index) {
                      final item = items[index];

                      final selected =
                          item.name == widget.selectedUniversity &&
                          item.district == widget.selectedDistrict;

                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pop(item);
                        },
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFDDF6EF)
                                : const Color(0xFFF3F6F5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            color: selected
                                ? _PreferenceScreenState._primaryDark
                                : const Color(0xFF748497),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            color: _PreferenceScreenState._navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text('${item.shortName} · ${item.address}'),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _PreferenceScreenState._primary,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F8F2), Color(0xFFF4FBF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6F0E8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: _PreferenceScreenState._primaryDark,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tìm phòng phù hợp với bạn',
                  style: TextStyle(
                    color: _PreferenceScreenState._navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chọn trường, ngân sách, bán kính và các tiện ích mong muốn để TrọSV hiểu nhu cầu của bạn.',
                  style: TextStyle(
                    color: Color(0xFF56746C),
                    fontSize: 12,
                    height: 1.45,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _PreferenceScreenState._primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _PreferenceScreenState._navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDF1F0)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _PreferenceScreenState._navy,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FBFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDCE5E4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _PreferenceScreenState._primary),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: placeholder
                        ? const Color(0xFF9CA8B4)
                        : _PreferenceScreenState._navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF7D8999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECEB)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (value) {
          onChanged(value ?? false);
        },
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13),
        activeColor: _PreferenceScreenState._primary,
        title: Text(
          title,
          style: const TextStyle(
            color: _PreferenceScreenState._navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AlertOption extends StatelessWidget {
  const _AlertOption({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? const Color(0xFFE9F8F3) : const Color(0xFFF7F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? const Color(0xFFCDEDE4) : const Color(0xFFE7ECEB),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (value) {
          onChanged(value ?? false);
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        activeColor: _PreferenceScreenState._primary,
        title: const Text(
          'Báo khi có phòng mới phù hợp',
          style: TextStyle(
            color: _PreferenceScreenState._navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Nhận thông báo khi hệ thống có phòng mới phù hợp với nhu cầu đã lưu.',
          style: TextStyle(
            color: _PreferenceScreenState._muted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Color(0xFF718096),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
