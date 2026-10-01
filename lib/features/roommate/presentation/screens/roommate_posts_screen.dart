import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/roommate_provider.dart';
import '../widgets/roommate_post_card.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF7FBFA);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF687571);
const _border = Color(0xFFE1EAE7);

class RoommatePostsScreen extends ConsumerStatefulWidget {
  const RoommatePostsScreen({super.key});

  @override
  ConsumerState<RoommatePostsScreen> createState() =>
      _RoommatePostsScreenState();
}

class _RoommatePostsScreenState extends ConsumerState<RoommatePostsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text =
        ref.read(roommateFilterProvider).universityOrWork ?? '';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(roommatePostsProvider);
    final filter = ref.watch(roommateFilterProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,

        // Không dùng AppBar riêng.
        // Hero image bắt đầu từ mép trên cùng, chạy sau status bar
        // giống bố cục mockup bạn gửi.
        body: RefreshIndicator(
          color: _green,
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          onRefresh: _refresh,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  searchController: _searchController,
                  filter: filter,
                  onSearchChanged: _onSearchChanged,
                  onTypeChanged: _setPostType,
                  onFilterPressed: _openFilterSheet,
                  onMinePressed: () => context.push('/roommate/mine'),
                ),
              ),

              // Header luôn giữ nguyên khi provider refresh.
              // Chỉ phần danh sách phía dưới thay đổi state.
              posts.when(
                skipLoadingOnRefresh: true,
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ListLoading(),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(roommatePostsProvider);
                    },
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        filtered: !filter.isEmpty,
                        onClearFilters: _clearFilters,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 104),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        // Dùng childCount xen kẽ card / khoảng cách
                        // để tương thích tốt với nhiều phiên bản Flutter.
                        if (index.isOdd) {
                          return const SizedBox(height: 10);
                        }

                        final itemIndex = index ~/ 2;
                        final post = items[itemIndex];

                        return RoommatePostCard(
                          post: post,
                          onTap: () {
                            context.push('/roommate/posts/${post.id}');
                          },
                        );
                      }, childCount: items.length * 2 - 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Mockup dùng nút + tròn thay vì FAB extended.
        floatingActionButton: FloatingActionButton(
          heroTag: 'create-roommate-post',
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: () => context.push('/roommate/create'),
          child: const Icon(Icons.add_rounded, size: 31),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      final current = ref.read(roommateFilterProvider);

      ref
          .read(roommateFilterProvider.notifier)
          .update(
            RoommateFilter(
              district: current.district,
              minBudget: current.minBudget,
              maxBudget: current.maxBudget,
              gender: current.gender,
              postType: current.postType,

              // Backend hiện hỗ trợ university_or_work,
              // nên search bar không giả lập tìm title ở frontend.
              universityOrWork: value.trim().isEmpty ? null : value.trim(),
            ),
          );
    });
  }

  void _setPostType(String? postType) {
    final current = ref.read(roommateFilterProvider);

    ref
        .read(roommateFilterProvider.notifier)
        .update(
          RoommateFilter(
            district: current.district,
            minBudget: current.minBudget,
            maxBudget: current.maxBudget,
            gender: current.gender,
            postType: postType,
            universityOrWork: current.universityOrWork,
          ),
        );
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(roommateFilterProvider.notifier).clear();
  }

  Future<void> _refresh() async {
    ref.invalidate(roommatePostsProvider);

    try {
      await ref.read(roommatePostsProvider.future);
    } catch (_) {
      // AsyncValue phía trên sẽ tự hiển thị lỗi.
    }
  }

  Future<void> _openFilterSheet() async {
    final current = ref.read(roommateFilterProvider);

    final districtController = TextEditingController(
      text: current.district ?? '',
    );
    final minBudgetController = TextEditingController(
      text: current.minBudget?.toString() ?? '',
    );
    final maxBudgetController = TextEditingController(
      text: current.maxBudget?.toString() ?? '',
    );

    String? selectedGender = current.gender;
    String? selectedPostType = current.postType;

    final result = await showModalBottomSheet<RoommateFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9E3E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bộ lọc tìm kiếm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            districtController.clear();
                            minBudgetController.clear();
                            maxBudgetController.clear();

                            setSheetState(() {
                              selectedGender = null;
                              selectedPostType = null;
                            });
                          },
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

                    const SizedBox(height: 14),
                    const _FilterTitle('Loại bài đăng'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChoice(
                          label: 'Tất cả',
                          selected: selectedPostType == null,
                          onTap: () {
                            setSheetState(() => selectedPostType = null);
                          },
                        ),
                        _FilterChoice(
                          label: 'Đã có phòng',
                          selected: selectedPostType == 'HAVE_ROOM',
                          onTap: () {
                            setSheetState(() => selectedPostType = 'HAVE_ROOM');
                          },
                        ),
                        _FilterChoice(
                          label: 'Cùng tìm phòng',
                          selected: selectedPostType == 'FIND_ROOM_TOGETHER',
                          onTap: () {
                            setSheetState(
                              () => selectedPostType = 'FIND_ROOM_TOGETHER',
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const _FilterTitle('Khu vực'),
                    TextField(
                      controller: districtController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'Nhập quận / huyện',
                        icon: Icons.location_on_outlined,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const _FilterTitle('Khoảng giá / người / tháng'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minBudgetController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hint: 'Từ',
                              suffix: 'đ',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '—',
                            style: TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: maxBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              hint: 'Đến',
                              suffix: 'đ',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const _FilterTitle('Giới tính mong muốn'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChoice(
                          label: 'Tất cả',
                          selected: selectedGender == null,
                          onTap: () {
                            setSheetState(() => selectedGender = null);
                          },
                        ),
                        _FilterChoice(
                          label: 'Nữ',
                          selected: selectedGender == 'FEMALE',
                          onTap: () {
                            setSheetState(() => selectedGender = 'FEMALE');
                          },
                        ),
                        _FilterChoice(
                          label: 'Nam',
                          selected: selectedGender == 'MALE',
                          onTap: () {
                            setSheetState(() => selectedGender = 'MALE');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            RoommateFilter(
                              district: _nullIfEmpty(districtController.text),
                              minBudget: _parseMoney(minBudgetController.text),
                              maxBudget: _parseMoney(maxBudgetController.text),
                              gender: selectedGender,
                              postType: selectedPostType,
                              universityOrWork: current.universityOrWork,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng bộ lọc',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    districtController.dispose();
    minBudgetController.dispose();
    maxBudgetController.dispose();

    if (result != null) {
      ref.read(roommateFilterProvider.notifier).update(result);
    }
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onFilterPressed,
    required this.onMinePressed,
  });

  final TextEditingController searchController;
  final RoommateFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onMinePressed;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    final activeFilterCount = <Object?>[
      filter.district,
      filter.minBudget,
      filter.maxBudget,
      filter.gender,
      filter.postType,
      filter.universityOrWork,
    ].where((value) => value != null).length;

    return Column(
      children: [
        // HERO bắt đầu ngay từ y = 0:
        // ảnh nằm sau cả status bar và khu vực "Ở ghép".
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          child: SizedBox(
            height: statusBarHeight + 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/banners/roommate_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(color: Color(0xFFE8F7F3));
                  },
                ),

                // Làm vùng trái sáng hơn một chút để chữ luôn dễ đọc.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.38),
                        Colors.white.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.48, 0.78],
                    ),
                  ),
                ),

                // "AppBar" tự vẽ trên ảnh.
                Positioned(
                  top: statusBarHeight + 4,
                  left: 4,
                  right: 7,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          _TopIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => context.pop(),
                          )
                        else
                          const SizedBox(width: 10),

                        const SizedBox(width: 1),
                        const Text(
                          'Ở ghép',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),

                        const Spacer(),

                        _TopIconButton(
                          icon: Icons.inventory_2_outlined,
                          tooltip: 'Tin của tôi',
                          onTap: onMinePressed,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tiêu đề lớn giống mockup.
                Positioned(
                  left: 28,
                  top: statusBarHeight + 57,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tìm bạn ở ghép',
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.02,
                          letterSpacing: -0.45,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF07584D),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Hợp vibe · Chia sẻ chi phí',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF385F59),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search + filter: khối thấp, nền kem nhẹ như ảnh tham chiếu.
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 11,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      // QUAN TRỌNG: đổi nền ngoài thành trắng
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              // Ô tìm kiếm cũng trắng
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: searchController,
                              onChanged: onSearchChanged,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _text,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,

                                // QUAN TRỌNG
                                filled: true,
                                fillColor: Colors.white,

                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 35,
                                  minHeight: 36,
                                ),

                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(left: 9, right: 6),
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: 17,
                                    color: Color(0xFF78857F),
                                  ),
                                ),

                                hintText: 'Tìm theo khu vực, trường, giá...',

                                hintStyle: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF9AA5A1),
                                  fontWeight: FontWeight.w400,
                                ),

                                // bỏ toàn bộ viền mặc định của TextField
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,

                                contentPadding: EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  right: 8,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // đường ngăn nhẹ giống ảnh mẫu
                        Container(
                          width: 1,
                          height: 22,
                          color: const Color(0xFFE8ECEB),
                        ),

                        Material(
                          // nút filter cũng trắng
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          child: InkWell(
                            onTap: onFilterPressed,
                            borderRadius: BorderRadius.circular(11),
                            child: SizedBox(
                              width: 38,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: Color(0xFF008C72),
                                    size: 19,
                                  ),

                                  if (activeFilterCount > 0)
                                    Positioned(
                                      right: 5,
                                      top: 5,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF735F),
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
          ),
        ),

        // Chips nằm sát ngay dưới banner.
        Container(
          color: _background,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
          child: Row(
            children: [
              Expanded(
                child: _QuickChip(
                  label: 'Tất cả',
                  selected: filter.postType == null,
                  onTap: () => onTypeChanged(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  label: 'Đã có phòng',
                  selected: filter.postType == 'HAVE_ROOM',
                  onTap: () => onTypeChanged('HAVE_ROOM'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  label: 'Cùng tìm phòng',
                  selected: filter.postType == 'FIND_ROOM_TOGETHER',
                  onTap: () {
                    onTypeChanged('FIND_ROOM_TOGETHER');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.50),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 37,
          height: 37,
          child: Icon(icon, size: 19, color: _text),
        ),
      ),
    );

    if (tooltip == null) return button;

    return Tooltip(message: tooltip!, child: button);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
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
      color: selected ? _green : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 37,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? _green : _border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.4,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _text,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _green, strokeWidth: 2.4),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.text);

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

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: const Color(0xFFF8FAF9),
      selectedColor: const Color(0xFFDFF5EF),
      side: BorderSide(color: selected ? _green : _border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: selected ? _greenDark : _text,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClearFilters});

  final bool filtered;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 66,
              color: Color(0xFF8EB1A8),
            ),
            const SizedBox(height: 14),
            Text(
              filtered ? 'Không có bài phù hợp bộ lọc' : 'Chưa có bài ở ghép',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Bài đăng vẫn còn, hãy xóa bộ lọc để xem toàn bộ.'
                  : 'Hãy đăng nhu cầu để tìm người ở cùng.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.45, color: _muted),
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 19),
                label: const Text('Xóa toàn bộ bộ lọc'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Color(0xFF8EB1A8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được bài ở ghép',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _green),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  IconData? icon,
  String? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, color: _muted),
    suffixText: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FBFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
  );
}

String? _nullIfEmpty(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int? _parseMoney(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}
