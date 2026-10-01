import 'dart:async';

import 'package:flutter/material.dart';

const _green = Color(0xFF00A884);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF7A8985);
const _indicatorInactive = Color(0xFFD7E4E1);

class HomePromoSlider extends StatefulWidget {
  const HomePromoSlider({
    required this.onFindRoomTap,
    required this.onRoommateTap,
    required this.onNewRoomTap,
    super.key,
  });

  final VoidCallback onFindRoomTap;
  final VoidCallback onRoommateTap;
  final VoidCallback onNewRoomTap;

  @override
  State<HomePromoSlider> createState() => _HomePromoSliderState();
}

class _HomePromoSliderState extends State<HomePromoSlider>
    with AutomaticKeepAliveClientMixin {
  /// 1.0 = chỉ hiển thị đúng 1 banner.
  /// Không còn lộ banner bên trái / bên phải.
  final PageController _pageController = PageController(viewportFraction: 1.0);

  Timer? _autoSlideTimer;
  int _currentIndex = 0;
  bool _userIsScrolling = false;

  static const List<String> _banners = [
    'assets/images/home/banner_home_B.png',
    'assets/images/home/banner_home_A.png',
    'assets/images/home/bannner_home_C.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _goToNextBanner(),
    );
  }

  void _goToNextBanner() {
    if (!mounted || !_pageController.hasClients || _userIsScrolling) return;

    final nextIndex = (_currentIndex + 1) % _banners.length;

    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleBannerTap(int index) {
    switch (index) {
      case 0:
        widget.onRoommateTap();
        break;
      case 1:
        widget.onFindRoomTap();
        break;
      case 2:
        widget.onNewRoomTap();
        break;
    }
  }

  Future<void> _goToPage(int index) async {
    if (!_pageController.hasClients) return;

    _startAutoSlide();

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.sizeOf(context).width - 40;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width * pixelRatio).round().clamp(720, 1200);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // TITLE
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Khám phá TrọSV',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1}/${_banners.length}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =========================
            // SLIDER
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  /// Tỉ lệ gần với banner hiện tại.
                  /// Mục đích:
                  /// - không còn khoảng trắng trên/dưới;
                  /// - hạn chế crop chữ hai bên;
                  /// - tất cả banner có cùng chiều cao.
                  aspectRatio: 2.75,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _userIsScrolling = true;
                        _autoSlideTimer?.cancel();
                      } else if (notification is ScrollEndNotification) {
                        _userIsScrolling = false;
                        _startAutoSlide();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      clipBehavior: Clip.hardEdge,
                      itemCount: _banners.length,
                      onPageChanged: (index) {
                        if (!mounted) return;
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _BannerItem(
                          asset: _banners[index],
                          cacheWidth: cacheWidth,
                          onTap: () => _handleBannerTap(index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // =========================
            // INDICATOR
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final isActive = index == _currentIndex;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _goToPage(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 6,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? _green : _indicatorInactive,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({
    required this.asset,
    required this.cacheWidth,
    required this.onTap,
  });

  final String asset;
  final int cacheWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Image.asset(
            asset,
            width: double.infinity,
            height: double.infinity,

            /// Dùng cover vì container đã được đưa về đúng tỉ lệ banner.
            /// Nhờ vậy ảnh phủ kín khung, không còn dải trắng trên/dưới.
            fit: BoxFit.cover,

            /// Giữ nội dung ở giữa, hạn chế mất chữ.
            alignment: Alignment.center,
            cacheWidth: cacheWidth,

            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,

            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFE8F5F2),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF8AA49E),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Không tải được banner',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7A8985)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
