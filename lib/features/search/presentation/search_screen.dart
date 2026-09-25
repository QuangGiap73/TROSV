import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../../preferences/domain/entities/amenity.dart';
import '../../preferences/presentation/providers/preference_provider.dart';
import '../../rooms/domain/entities/room_search_query.dart';
import '../../rooms/domain/entities/room_summary.dart';
import '../../rooms/presentation/providers/room_match_provider.dart';
import '../../rooms/presentation/providers/room_providers.dart';
import 'widgets/search_result_card.dart';

enum _SearchMode { all, recommended, newest }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  RoomSearchQuery _query = const RoomSearchQuery();
  _SearchMode _mode = _SearchMode.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _query = _query.copyWith(
          keyword: value.trim(),
          clearKeyword: value.trim().isEmpty,
          page: 1,
        );
        _mode = _SearchMode.all;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final favorites = ref.watch(favoritesProvider).asData?.value ?? const [];
    final amenities = ref.watch(amenitiesProvider).asData?.value ?? const [];
    final effectiveQuery = _mode == _SearchMode.newest
        ? _query.copyWith(sort: 'NEWEST')
        : _query;
    final publicRooms = ref.watch(roomSearchProvider(effectiveQuery));
    final matches = session != null && _mode == _SearchMode.recommended
        ? ref.watch(roomMatchesProvider)
        : null;
    final results = _mode == _SearchMode.recommended
        ? matches?.whenData(
                (items) => items.map((match) => match.room).toList(),
              ) ??
              const AsyncData<List<RoomSummary>>([])
        : publicRooms;
    final favoriteIds = favorites.map((room) => room.id).toSet();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Tìm trọ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF8FAF9),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onKeywordChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm khu vực, trường, địa chỉ...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 21),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onKeywordChanged('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: Color(0xFFE1E7E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: Color(0xFFE1E7E5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SquareFilterButton(
                  active: _activeFilterCount > 0,
                  count: _activeFilterCount,
                  onTap: () => _showMoreFilters(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _ModeSelector(
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _SearchViewSelector(
              onMapTap: () => context.push('/rooms/map'),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _SuggestionChip(
                  icon: Icons.school_outlined,
                  label: 'Đại học',
                  onTap: () => context.push('/profile/preferences'),
                ),
                const SizedBox(width: 8),
                _SuggestionChip(
                  icon: Icons.near_me_outlined,
                  label: 'Bán kính',
                  onTap: () => _message(
                    context,
                    'Hãy chọn trường trong Nhu cầu để tìm theo bán kính.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _FilterChip(
                  label: _query.district ?? 'Khu vực',
                  active: _query.district != null,
                  onTap: () => _chooseDistrict(context),
                ),
                _FilterChip(
                  label: _priceLabel,
                  active: _query.minPrice != null || _query.maxPrice != null,
                  onTap: () => _choosePrice(context),
                ),
                _FilterChip(
                  label: _roomTypeLabel(_query.roomType),
                  active: _query.roomType != null,
                  onTap: () => _chooseRoomType(context),
                ),
                _FilterChip(
                  label: _query.amenityCodes.isEmpty
                      ? 'Tiện ích'
                      : 'Tiện ích (${_query.amenityCodes.length})',
                  active: _query.amenityCodes.isNotEmpty,
                  onTap: () => _chooseAmenities(context, amenities),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: results.maybeWhen(
                    data: (items) => Text(
                      'Có ${items.length} phòng phù hợp',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF687773),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _chooseSort(context),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  label: Text(_sortLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF263431),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SearchError(
                onRetry: () {
                  if (_mode == _SearchMode.recommended) {
                    ref.invalidate(roomMatchesProvider);
                  } else {
                    ref.invalidate(roomSearchProvider(effectiveQuery));
                  }
                },
              ),
              data: (items) {
                if (_mode == _SearchMode.recommended && session == null) {
                  return _LoginForRecommendation(
                    onLogin: () => context.push('/login'),
                  );
                }
                if (items.isEmpty) return const _EmptyResults();

                return RefreshIndicator(
                  onRefresh: () async {
                    if (_mode == _SearchMode.recommended) {
                      ref.invalidate(roomMatchesProvider);
                      await ref.read(roomMatchesProvider.future);
                    } else {
                      ref.invalidate(roomSearchProvider(effectiveQuery));
                      await ref.read(roomSearchProvider(effectiveQuery).future);
                    }
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = items[index];
                      return SearchResultCard(
                        room: room,
                        isFavorite: favoriteIds.contains(room.id),
                        onTap: () => context.push('/rooms/${room.id}'),
                        onFavoriteTap: () => _toggleFavorite(context, room),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount => [
    _query.district,
    _query.minPrice ?? _query.maxPrice,
    _query.roomType,
    if (_query.amenityCodes.isNotEmpty) _query.amenityCodes,
    _query.bathroomPrivate,
    _query.hasBalcony,
  ].where((value) => value != null).length;

  String get _priceLabel {
    final min = _query.minPrice;
    final max = _query.maxPrice;
    if (min == null && max == null) return 'Giá';
    if (min == null) return 'Dưới ${(max! / 1000000).toStringAsFixed(0)}tr';
    if (max == null) return 'Trên ${(min / 1000000).toStringAsFixed(0)}tr';
    return '${(min / 1000000).toStringAsFixed(0)}-${(max / 1000000).toStringAsFixed(0)}tr';
  }

  String get _sortLabel => switch (_query.sort) {
    'PRICE_ASC' => 'Giá tăng',
    'PRICE_DESC' => 'Giá giảm',
    'DISTANCE' => 'Gần nhất',
    'NEWEST' => 'Mới nhất',
    _ => 'Sắp xếp',
  };

  Future<void> _chooseDistrict(BuildContext context) async {
    final value = await _pickOption<String?>(
      context,
      title: 'Chọn khu vực',
      options: const [
        (null, 'Tất cả khu vực'),
        ('Cầu Giấy', 'Cầu Giấy'),
        ('Đống Đa', 'Đống Đa'),
        ('Hai Bà Trưng', 'Hai Bà Trưng'),
        ('Thanh Xuân', 'Thanh Xuân'),
        ('Nam Từ Liêm', 'Nam Từ Liêm'),
        ('Hà Đông', 'Hà Đông'),
      ],
    );
    if (!mounted || value == _cancelValue) return;
    setState(
      () => _query = value == null
          ? _query.copyWith(clearDistrict: true)
          : _query.copyWith(district: value),
    );
  }

  Future<void> _choosePrice(BuildContext context) async {
    final value = await _pickOption<String>(
      context,
      title: 'Chọn khoảng giá',
      options: const [
        ('all', 'Tất cả mức giá'),
        ('under3', 'Dưới 3 triệu'),
        ('3to5', 'Từ 3 - 5 triệu'),
        ('5to7', 'Từ 5 - 7 triệu'),
        ('over7', 'Trên 7 triệu'),
      ],
    );
    if (!mounted || value == null) return;
    setState(() {
      _query = switch (value) {
        'under3' => _query.copyWith(clearPrice: true, maxPrice: 3000000),
        '3to5' => _query.copyWith(
          clearPrice: true,
          minPrice: 3000000,
          maxPrice: 5000000,
        ),
        '5to7' => _query.copyWith(
          clearPrice: true,
          minPrice: 5000000,
          maxPrice: 7000000,
        ),
        'over7' => _query.copyWith(clearPrice: true, minPrice: 7000000),
        _ => _query.copyWith(clearPrice: true),
      };
    });
  }

  Future<void> _chooseRoomType(BuildContext context) async {
    final value = await _pickOption<String?>(
      context,
      title: 'Chọn loại phòng',
      options: const [
        (null, 'Tất cả loại phòng'),
        ('ROOM_SINGLE', 'Phòng đơn'),
        ('ROOM_SHARED', 'Ở ghép'),
        ('STUDIO', 'Studio'),
        ('ONE_BEDROOM', 'Một phòng ngủ'),
        ('WHOLE_HOUSE', 'Nguyên căn'),
      ],
    );
    if (!mounted || value == _cancelValue) return;
    setState(
      () => _query = value == null
          ? _query.copyWith(clearRoomType: true)
          : _query.copyWith(roomType: value),
    );
  }

  Future<void> _chooseSort(BuildContext context) async {
    final value = await _pickOption<String>(
      context,
      title: 'Sắp xếp kết quả',
      options: const [
        ('RELEVANCE', 'Liên quan nhất'),
        ('NEWEST', 'Mới nhất'),
        ('PRICE_ASC', 'Giá thấp đến cao'),
        ('PRICE_DESC', 'Giá cao đến thấp'),
        ('DISTANCE', 'Gần nhất'),
      ],
    );
    if (!mounted || value == null) return;
    setState(() {
      _query = _query.copyWith(sort: value);
      if (_mode == _SearchMode.newest && value != 'NEWEST') {
        _mode = _SearchMode.all;
      }
    });
  }

  Future<T?> _pickOption<T>(
    BuildContext context, {
    required String title,
    required List<(T, String)> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(option.$2),
                onTap: () => Navigator.pop(context, option.$1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseAmenities(
    BuildContext context,
    List<Amenity> amenities,
  ) async {
    if (amenities.isEmpty) {
      _message(context, 'Chưa tải được danh sách tiện ích.');
      return;
    }
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AmenityPicker(
        amenities: amenities,
        initialCodes: _query.amenityCodes,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _query = _query.copyWith(amenityCodes: selected));
    }
  }

  Future<void> _showMoreFilters(BuildContext context) async {
    final result = await showModalBottomSheet<(bool?, bool?)>(
      context: context,
      showDragHandle: true,
      builder: (_) => _MoreFilters(
        bathroomPrivate: _query.bathroomPrivate,
        hasBalcony: _query.hasBalcony,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _query = _query.copyWith(
        bathroomPrivate: result.$1,
        clearBathroomPrivate: result.$1 == null,
        hasBalcony: result.$2,
        clearHasBalcony: result.$2 == null,
      );
    });
  }

  Future<void> _toggleFavorite(BuildContext context, RoomSummary room) async {
    var session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) return;
      session = ref.read(authControllerProvider).asData?.value;
    }
    if (session == null) return;

    try {
      await ref.read(favoritesProvider.future);
      await ref.read(favoritesProvider.notifier).toggle(room);
    } catch (_) {
      if (context.mounted) {
        _message(context, 'Không thể cập nhật phòng yêu thích.');
      }
    }
  }
}

const _cancelValue = '__CANCEL__';

String _roomTypeLabel(String? value) => switch (value) {
  'ROOM_SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' => 'Ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => 'Một phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => 'Loại phòng',
};

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});
  final _SearchMode value;
  final ValueChanged<_SearchMode> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ModeButton(
        label: 'Tất cả',
        selected: value == _SearchMode.all,
        onTap: () => onChanged(_SearchMode.all),
      ),
      _ModeButton(
        label: 'Gợi ý cho bạn',
        selected: value == _SearchMode.recommended,
        onTap: () => onChanged(_SearchMode.recommended),
      ),
      _ModeButton(
        label: 'Gần đây',
        selected: value == _SearchMode.newest,
        onTap: () => onChanged(_SearchMode.newest),
      ),
    ],
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? const Color(0xFF008E79) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF263431),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SearchViewSelector extends StatelessWidget {
  const _SearchViewSelector({required this.onMapTap});

  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE5E2)),
    ),
    child: Row(
      children: [
        const Expanded(
          child: _ViewOption(
            icon: Icons.format_list_bulleted_rounded,
            label: 'Danh sách',
            selected: true,
          ),
        ),
        Expanded(
          child: _ViewOption(
            icon: Icons.map_outlined,
            label: 'Bản đồ',
            selected: false,
            onTap: onMapTap,
          ),
        ),
      ],
    ),
  );
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF008E79) : Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : const Color(0xFF566763),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF566763),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 16, color: const Color(0xFF008E79)),
    label: Text(label),
    onPressed: onTap,
    backgroundColor: const Color(0xFFE4F5F1),
    side: BorderSide.none,
    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    visualDensity: VisualDensity.compact,
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ActionChip(
      label: Text(label),
      avatar: active
          ? const Icon(Icons.check_rounded, size: 15)
          : const Icon(Icons.keyboard_arrow_down_rounded, size: 15),
      onPressed: onTap,
      backgroundColor: active ? const Color(0xFFE1F5F0) : Colors.white,
      side: BorderSide(
        color: active ? const Color(0xFF62BBA8) : const Color(0xFFDDE4E2),
      ),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _SquareFilterButton extends StatelessWidget {
  const _SquareFilterButton({
    required this.active,
    required this.count,
    required this.onTap,
  });
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: active,
    label: Text('$count'),
    child: Material(
      color: active ? const Color(0xFFE1F5F0) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.tune_rounded),
        ),
      ),
    ),
  );
}

class _AmenityPicker extends StatefulWidget {
  const _AmenityPicker({required this.amenities, required this.initialCodes});
  final List<Amenity> amenities;
  final List<String> initialCodes;

  @override
  State<_AmenityPicker> createState() => _AmenityPickerState();
}

class _AmenityPickerState extends State<_AmenityPicker> {
  late final Set<String> _selected = widget.initialCodes.toSet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích mong muốn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 7,
                children: widget.amenities.map((amenity) {
                  final selected = _selected.contains(amenity.code);
                  return FilterChip(
                    label: Text(amenity.name),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      value
                          ? _selected.add(amenity.code)
                          : _selected.remove(amenity.code);
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF008E79),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    ),
  );
}

class _MoreFilters extends StatefulWidget {
  const _MoreFilters({this.bathroomPrivate, this.hasBalcony});
  final bool? bathroomPrivate;
  final bool? hasBalcony;

  @override
  State<_MoreFilters> createState() => _MoreFiltersState();
}

class _MoreFiltersState extends State<_MoreFilters> {
  late bool _bathroom = widget.bathroomPrivate ?? false;
  late bool _balcony = widget.hasBalcony ?? false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Bộ lọc thêm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          SwitchListTile(
            title: const Text('WC khép kín'),
            value: _bathroom,
            onChanged: (value) => setState(() => _bathroom = value),
          ),
          SwitchListTile(
            title: const Text('Có ban công'),
            value: _balcony,
            onChanged: (value) => setState(() => _balcony = value),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, (null, null)),
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, (_bathroom, _balcony)),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LoginForRecommendation extends StatelessWidget {
  const _LoginForRecommendation({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Đăng nhập để xem phòng phù hợp với nhu cầu của bạn.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onLogin, child: const Text('Đăng nhập')),
        ],
      ),
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text('Không tìm thấy phòng phù hợp với bộ lọc.'),
    ),
  );
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 8),
        const Text('Không thể tải danh sách phòng.'),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
