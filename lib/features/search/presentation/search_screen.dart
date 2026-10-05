import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../../preferences/domain/entities/amenity.dart';
import '../../preferences/presentation/providers/preference_provider.dart';
import '../../rooms/domain/entities/room_search_query.dart';
import '../../rooms/domain/entities/room_map_args.dart';
import '../../rooms/domain/entities/room_summary.dart';
import '../../rooms/presentation/providers/room_match_provider.dart';
import '../../rooms/presentation/providers/room_providers.dart';
import 'widgets/search_result_card.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF7FAF9);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF687571);
const _border = Color(0xFFE1EAE7);

enum _SearchMode { all, recommended, newest }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    this.initialQuery = const RoomSearchQuery(),
    this.title = 'Tìm trọ',
    this.mapFocusLabel,
    super.key,
  });
  final RoomSearchQuery initialQuery;
  final String title;
  final String? mapFocusLabel;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late RoomSearchQuery _query;
  String? _mapFocusLabel;
  _SearchMode _mode = _SearchMode.all;
  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _mapFocusLabel = widget.mapFocusLabel;
    _searchController.text = widget.initialQuery.keyword ?? '';
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _debounce?.cancel();
      _query = widget.initialQuery;
      _mapFocusLabel = widget.mapFocusLabel;
      _searchController.text = widget.initialQuery.keyword ?? '';
      _mode = _SearchMode.all;
    }
  }

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
        final keyword = value.trim();
        _query = _query.copyWith(
          keyword: keyword,
          clearKeyword: keyword.isEmpty,
          page: 1,
        );
        _mode = _SearchMode.all;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(
      authControllerProvider.select((state) => state.asData?.value),
    );
    final effectiveQuery = _mode == _SearchMode.newest
        ? _query.copyWith(sort: 'NEWEST')
        : _query;
    final AsyncValue<List<RoomSummary>> results;
    if (_mode == _SearchMode.recommended) {
      results = session == null
          ? const AsyncData<List<RoomSummary>>([])
          : ref
                .watch(roomMatchesProvider)
                .whenData((items) => items.map((match) => match.room).toList());
    } else {
      results = ref.watch(roomSearchProvider(effectiveQuery));
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _MapFloatingButton(
          onTap: () async {
            final result = await context.push<RoomMapArgs>(
              '/rooms/map',
              extra: RoomMapArgs(
                query: effectiveQuery,
                focusLabel: _mapFocusLabel,
              ),
            );
            if (!mounted || result == null) return;
            setState(() {
              _query = result.query;
              _mapFocusLabel = result.focusLabel;
              _mode = _SearchMode.all;
            });
          },
        ),
        body: RefreshIndicator(
          color: _green,
          onRefresh: () => _refreshResults(effectiveQuery),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: 700,
            slivers: [
              SliverToBoxAdapter(
                child: _SearchHero(
                  controller: _searchController,
                  activeFilterCount: _activeFilterCount,
                  onKeywordChanged: _onKeywordChanged,
                  onClearSearch: () {
                    _searchController.clear();
                    _onKeywordChanged('');
                    setState(() {});
                  },
                  onFilterTap: () => _showAdvancedFilters(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _ModeSelector(
                    value: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickFilterButton(
                          icon: Icons.school_outlined,
                          label: 'Gần trường',
                          active: false,
                          onTap: () => context.push('/profile/preferences'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _QuickFilterButton(
                          icon: Icons.payments_outlined,
                          label: _priceLabel,
                          active:
                              _query.minPrice != null ||
                              _query.maxPrice != null,
                          onTap: () => _choosePrice(context),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _QuickFilterButton(
                          icon: Icons.tune_rounded,
                          label: _activeFilterCount > 0
                              ? 'Bộ lọc ($_activeFilterCount)'
                              : 'Bộ lọc',
                          active: _activeFilterCount > 0,
                          onTap: () => _showAdvancedFilters(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: results.maybeWhen(
                          data: (items) => RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: _text,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                              children: [
                                TextSpan(
                                  text: '${items.length}',
                                  style: const TextStyle(
                                    color: _green,
                                    fontSize: 18,
                                  ),
                                ),
                                const TextSpan(text: ' phòng phù hợp'),
                              ],
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ),
                      _SortButton(
                        label: _sortLabel,
                        onTap: () => _chooseSort(context),
                      ),
                    ],
                  ),
                ),
              ),
              ...results.when(
                loading: () => const [
                  SliverFillRemaining(child: _SearchLoading()),
                ],
                error: (error, _) => [
                  SliverFillRemaining(
                    child: _SearchError(
                      onRetry: () {
                        if (_mode == _SearchMode.recommended) {
                          ref.invalidate(roomMatchesProvider);
                        } else {
                          ref.invalidate(roomSearchProvider(effectiveQuery));
                        }
                      },
                    ),
                  ),
                ],
                data: (items) {
                  if (_mode == _SearchMode.recommended && session == null) {
                    return [
                      SliverFillRemaining(
                        child: _LoginForRecommendation(
                          onLogin: () => context.push('/login'),
                        ),
                      ),
                    ];
                  }
                  if (items.isEmpty) {
                    return [
                      SliverFillRemaining(
                        child: _EmptyResults(
                          hasFilters:
                              _activeFilterCount > 0 ||
                              _searchController.text.trim().isNotEmpty,
                          onClear: _clearAllFilters,
                        ),
                      ),
                    ];
                  }
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final room = items[index];
                          return _SearchResultItem(
                            key: ValueKey(room.id),
                            room: room,
                            onTap: () => context.push('/rooms/${room.id}'),
                            onFavoriteTap: () => _toggleFavorite(context, room),
                          );
                        },
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshResults(RoomSearchQuery effectiveQuery) async {
    if (_mode == _SearchMode.recommended) {
      ref.invalidate(roomMatchesProvider);
      await ref.read(roomMatchesProvider.future);
      return;
    }
    ref.invalidate(roomSearchProvider(effectiveQuery));
    await ref.read(roomSearchProvider(effectiveQuery).future);
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
    if (min == null && max == null) {
      return 'Giá';
    }
    if (min == null) {
      return 'Dưới ${(max! / 1000000).toStringAsFixed(0)}tr';
    }
    if (max == null) {
      return 'Trên ${(min / 1000000).toStringAsFixed(0)}tr';
    }
    return '${(min / 1000000).toStringAsFixed(0)}-${(max / 1000000).toStringAsFixed(0)}tr';
  }

  String get _sortLabel => switch (_query.sort) {
    'PRICE_ASC' => 'Giá tăng',
    'PRICE_DESC' => 'Giá giảm',
    'DISTANCE' => 'Gần nhất',
    'NEWEST' => 'Mới nhất',
    _ => 'Sắp xếp',
  };
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
        'under3' => _query.copyWith(
          clearPrice: true,
          maxPrice: 3000000,
          page: 1,
        ),
        '3to5' => _query.copyWith(
          clearPrice: true,
          minPrice: 3000000,
          maxPrice: 5000000,
          page: 1,
        ),
        '5to7' => _query.copyWith(
          clearPrice: true,
          minPrice: 5000000,
          maxPrice: 7000000,
          page: 1,
        ),
        'over7' => _query.copyWith(
          clearPrice: true,
          minPrice: 7000000,
          page: 1,
        ),
        _ => _query.copyWith(clearPrice: true, page: 1),
      };
      _mode = _SearchMode.all;
    });
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
      _query = _query.copyWith(sort: value, page: 1);
      if (_mode == _SearchMode.newest && value != 'NEWEST') {
        _mode = _SearchMode.all;
      }
    });
  }

  Future<void> _showAdvancedFilters(BuildContext context) async {
    List<Amenity> amenities;
    try {
      amenities = await ref.read(amenitiesProvider.future);
    } catch (_) {
      if (context.mounted) {
        _message(context, 'KhÃ´ng thá»ƒ táº£i danh sÃ¡ch tiá»‡n Ã­ch.');
      }
      return;
    }
    if (!context.mounted) return;
    final result = await showModalBottomSheet<_AdvancedFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .32),
      builder: (_) => _AdvancedFilterSheet(query: _query, amenities: amenities),
    );
    if (!mounted || result == null) return;
    setState(() {
      _query = _query.copyWith(
        district: result.district,
        clearDistrict: result.district == null,
        roomType: result.roomType,
        clearRoomType: result.roomType == null,
        amenityCodes: result.amenityCodes,
        bathroomPrivate: result.bathroomPrivate,
        clearBathroomPrivate: result.bathroomPrivate == null,
        hasBalcony: result.hasBalcony,
        clearHasBalcony: result.hasBalcony == null,
        page: 1,
      );
      _mode = _SearchMode.all;
    });
  }

  Future<T?> _pickOption<T>(
    BuildContext context, {
    required String title,
    required List<(T, String)> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE5E2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    option.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 19),
                  onTap: () => Navigator.pop(context, option.$1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAllFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = widget.initialQuery.copyWith(
        clearKeyword: true,
        clearPrice: true,
        clearDistrict: true,
        clearRoomType: true,
        amenityCodes: const [],
        clearBathroomPrivate: true,
        clearHasBalcony: true,
        page: 1,
      );
      _mode = _SearchMode.all;
    });
  }

  Future<void> _toggleFavorite(BuildContext context, RoomSummary room) async {
    var session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) {
        return;
      }
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

class _SearchResultItem extends ConsumerWidget {
  const _SearchResultItem({
    required this.room,
    required this.onTap,
    required this.onFavoriteTap,
    super.key,
  });

  final RoomSummary room;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (state) =>
            state.asData?.value.any((item) => item.id == room.id) ?? false,
      ),
    );

    return SearchResultCard(
      room: room,
      isFavorite: isFavorite,
      onTap: onTap,
      onFavoriteTap: onFavoriteTap,
    );
  }
}

class _SearchHero extends StatelessWidget {
  const _SearchHero({
    required this.controller,
    required this.activeFilterCount,
    required this.onKeywordChanged,
    required this.onClearSearch,
    required this.onFilterTap,
  });
  final TextEditingController controller;
  final int activeFilterCount;
  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    // Banner hiện tại được thiết kế gần tỷ lệ 3:1.
    // Search chồng lên mép dưới của banner nên không còn dải xanh thừa.
    final bannerHeight = size.width / 3;
    final searchTop = bannerHeight - 20;
    const searchHeight = 48.0;
    final heroHeight = searchTop + searchHeight;
    final cacheWidth = (size.width * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(720, 1200);
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: bannerHeight,
            child: Image.asset(
              'assets/images/banners/search_hero_v2.png',
              width: double.infinity,
              height: bannerHeight,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: cacheWidth,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: Color(0xFFF7FAF9));
              },
            ),
          ),
          // Nút quay lại nằm trực tiếp trên banner.
          if (Navigator.of(context).canPop())
            Positioned(
              top: statusBarHeight + 7,
              left: 10,
              child: _HeroIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
          // Search đè lên phần cuối banner giống màn Ở ghép.
          Positioned(
            left: 14,
            right: 14,
            top: searchTop,
            child: Container(
              height: searchHeight,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE7ECEA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: controller,
                        onChanged: onKeywordChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 12, color: _text),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Tìm khu vực, trường, địa chỉ...',
                          hintStyle: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF929F9B),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 39,
                            minHeight: 42,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 10, right: 6),
                            child: Icon(
                              Icons.search_rounded,
                              size: 19,
                              color: _greenDark,
                            ),
                          ),
                          suffixIcon: controller.text.isEmpty
                              ? null
                              : IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: onClearSearch,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF78857F),
                                  ),
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            right: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE7ECEA),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: onFilterTap,
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: 43,
                        height: 42,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: _greenDark,
                              size: 20,
                            ),
                            if (activeFilterCount > 0)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5F62),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .93),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 39,
          height: 39,
          child: Icon(icon, size: 18, color: _text),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});
  final _SearchMode value;
  final ValueChanged<_SearchMode> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4F2),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
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
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? _green : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : _text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = active ? _greenDark : _text;
    return Material(
      color: active ? const Color(0xFFE0F5EF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? const Color(0xFF9CDCCD) : _border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: _text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem bản đồ phòng trọ',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B894), Color(0xFF008F73)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _greenDark.withValues(alpha: .28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: Colors.white, size: 25),
                  SizedBox(width: 10),
                  Text(
                    'Xem bản đồ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _green, strokeWidth: 2.5),
    );
  }
}

class _AdvancedFilterResult {
  const _AdvancedFilterResult({
    this.district,
    this.roomType,
    this.amenityCodes = const [],
    this.bathroomPrivate,
    this.hasBalcony,
  });
  final String? district;
  final String? roomType;
  final List<String> amenityCodes;
  final bool? bathroomPrivate;
  final bool? hasBalcony;
}

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({required this.query, required this.amenities});
  final RoomSearchQuery query;
  final List<Amenity> amenities;
  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  String? _district;
  String? _roomType;
  late Set<String> _amenityCodes;
  bool? _bathroomPrivate;
  bool? _hasBalcony;
  static const _districts = [
    'Cầu Giấy',
    'Đống Đa',
    'Hai Bà Trưng',
    'Thanh Xuân',
    'Nam Từ Liêm',
    'Hà Đông',
  ];
  static const _roomTypes = <(String, String)>[
    ('ROOM_SINGLE', 'Phòng đơn'),
    ('ROOM_SHARED', 'Ở ghép'),
    ('STUDIO', 'Studio'),
    ('ONE_BEDROOM', 'Một phòng ngủ'),
    ('WHOLE_HOUSE', 'Nguyên căn'),
  ];
  @override
  void initState() {
    super.initState();
    _district = widget.query.district;
    _roomType = widget.query.roomType;
    _amenityCodes = widget.query.amenityCodes.toSet();
    _bathroomPrivate = widget.query.bathroomPrivate;
    _hasBalcony = widget.query.hasBalcony;
  }

  void _reset() {
    setState(() {
      _district = null;
      _roomType = null;
      _amenityCodes.clear();
      _bathroomPrivate = null;
      _hasBalcony = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _AdvancedFilterResult(
        district: _district,
        roomType: _roomType,
        amenityCodes: _amenityCodes.toList(),
        bathroomPrivate: _bathroomPrivate,
        hasBalcony: _hasBalcony,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .84,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 43,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE5E2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bộ lọc tìm phòng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      color: _greenDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FilterSectionTitle('Khu vực'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoiceChip(
                        label: 'Tất cả',
                        selected: _district == null,
                        onTap: () {
                          setState(() => _district = null);
                        },
                      ),
                      ..._districts.map(
                        (district) => _ChoiceChip(
                          label: district,
                          selected: _district == district,
                          onTap: () {
                            setState(() => _district = district);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _FilterSectionTitle('Loại phòng'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoiceChip(
                        label: 'Tất cả',
                        selected: _roomType == null,
                        onTap: () {
                          setState(() => _roomType = null);
                        },
                      ),
                      ..._roomTypes.map(
                        (option) => _ChoiceChip(
                          label: option.$2,
                          selected: _roomType == option.$1,
                          onTap: () {
                            setState(() => _roomType = option.$1);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (widget.amenities.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _FilterSectionTitle('Tiện ích'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.amenities.map((amenity) {
                        final selected = _amenityCodes.contains(amenity.code);
                        return _ChoiceChip(
                          label: amenity.name,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _amenityCodes.remove(amenity.code);
                              } else {
                                _amenityCodes.add(amenity.code);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const _FilterSectionTitle('WC khép kín'),
                  _BooleanFilterRow(
                    value: _bathroomPrivate,
                    onChanged: (value) {
                      setState(() {
                        _bathroomPrivate = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const _FilterSectionTitle('Ban công'),
                  _BooleanFilterRow(
                    value: _hasBalcony,
                    onChanged: (value) {
                      setState(() {
                        _hasBalcony = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: _text,
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDFF5EF) : const Color(0xFFF8FAF9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _green : _border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? _greenDark : _text,
            ),
          ),
        ),
      ),
    );
  }
}

class _BooleanFilterRow extends StatelessWidget {
  const _BooleanFilterRow({required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool?> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceChip(
            label: 'Tất cả',
            selected: value == null,
            onTap: () => onChanged(null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChoiceChip(
            label: 'Có',
            selected: value == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChoiceChip(
            label: 'Không',
            selected: value == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _LoginForRecommendation extends StatelessWidget {
  const _LoginForRecommendation({required this.onLogin});
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F5F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 34,
                color: _greenDark,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Gợi ý dành riêng cho bạn',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đăng nhập để xem các phòng phù hợp với nhu cầu của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.45, color: _muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onLogin,
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.hasFilters, required this.onClear});
  final bool hasFilters;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 55,
              color: Color(0xFF8FA9A3),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy phòng phù hợp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử thay đổi từ khóa hoặc nới rộng bộ lọc để xem thêm phòng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, height: 1.4, color: _muted),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFF8FA9A3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Không thể tải danh sách phòng.',
            style: TextStyle(fontWeight: FontWeight.w800, color: _text),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
