import 'dart:async';

import 'package:flutter/material.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchTap,
    required this.onFindRoomTap,
    required this.onRoommateTap,
    required this.onMapTap,
    required this.onNewRoomTap,
    this.userName,
    super.key,
  });

  final String? userName;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFindRoomTap;
  final VoidCallback onRoommateTap;
  final VoidCallback onMapTap;
  final VoidCallback onNewRoomTap;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentBanner = 0;

  static const _banners = [
    'assets/images/home/banner_home_B.png',
    'assets/images/home/banner_home_A.png',
    'assets/images/home/bannner_home_C.png',
  ];

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _showNextBanner(),
    );
  }

  void _showNextBanner() {
    if (!mounted || !_pageController.hasClients) return;

    final nextPage = (_currentBanner + 1) % _banners.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
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
    final name = widget.userName?.trim();
    final greeting = name == null || name.isEmpty ? 'bạn' : name;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onLocationTap,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 21),
                          SizedBox(width: 5),
                          Text(
                            'Hà Nội',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onNotificationTap,
                  tooltip: 'Thông báo',
                  icon: const Icon(Icons.notifications_none_rounded, size: 27),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Xin chào $greeting 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17201E),
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: widget.onSearchTap,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .035),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: Color(0xFF70827E)),
                      SizedBox(width: 10),
                      Text(
                        'Bạn muốn tìm phòng ở đâu?',
                        style: TextStyle(color: Color(0xFF899692)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 132,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) => _currentBanner = index,
                  itemBuilder: (_, index) =>
                      Image.asset(_banners[index], fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HomeShortcut(
                  asset: 'assets/images/icon/icon_timtro.png',
                  label: 'Tìm trọ',
                  onTap: widget.onFindRoomTap,
                ),
                _HomeShortcut(
                  asset: 'assets/images/icon/icon_oghep.png',
                  label: 'Ở ghép',
                  onTap: widget.onRoommateTap,
                ),
                _HomeShortcut(
                  asset: 'assets/images/icon/icon_vitri.png',
                  label: 'Bản đồ',
                  onTap: widget.onMapTap,
                ),
                _HomeShortcut(
                  asset: 'assets/images/icon/icon_ngoinha.png',
                  label: 'Phòng mới',
                  onTap: widget.onNewRoomTap,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
