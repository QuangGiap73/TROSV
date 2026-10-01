import 'package:flutter/material.dart';

const _primaryDark = Color(0xFF007E6A);
const _pageBackground = Color(0xFFF9FAFA);
const _text = Color(0xFF17211F);

class HomeHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final heroCacheWidth = (screenWidth * devicePixelRatio).round().clamp(
      720,
      1200,
    );

    final rawName = userName?.trim();
    final greeting = rawName == null || rawName.isEmpty ? 'bạn' : rawName;

    // Banner mới có tỉ lệ gần 1.44 : 1.
    // Tính chiều cao theo chiều rộng giúp ảnh hiển thị cân hơn trên nhiều máy.
    final heroHeight = (screenWidth / 1.44).clamp(245.0, 290.0);

    return Column(
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ======================================================
              // HERO IMAGE - CHỈ DÙNG 1 ẢNH
              // ======================================================
              Image.asset(
                'assets/images/home/home_hero.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: heroCacheWidth,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: Color(0xFFDDF4EE));
                },
              ),

              // Gradient nhẹ phía dưới để chữ trắng dễ đọc.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: .08),
                          Colors.black.withValues(alpha: .24),
                        ],
                        stops: const [0, .46, .70, 1],
                      ),
                    ),
                  ),
                ),
              ),

              // ======================================================
              // LOCATION + NOTIFICATION
              // ======================================================
              Positioned(
                top: statusBarHeight + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: onLocationTap,
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: _primaryDark,
                                size: 19,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Hà Nội',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: _text,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Material(
                      color: Colors.white.withValues(alpha: .95),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onNotificationTap,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: _text,
                                size: 23,
                              ),
                              Positioned(
                                top: 7,
                                right: 7,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5C63),
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

              // ======================================================
              // GREETING
              // ======================================================
              Positioned(
                left: 20,
                right: 20,
                bottom: 69,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào $greeting 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.04,
                        letterSpacing: -.35,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0x77000000), blurRadius: 9),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tìm căn phòng phù hợp với bạn',
                      style: TextStyle(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 7),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // SEARCH
              // ======================================================
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: .12),
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(25),
                    child: const SizedBox(
                      height: 48,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: _primaryDark,
                              size: 23,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bạn muốn tìm phòng ở đâu?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.3,
                                  color: Color(0xFF7B8985),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ======================================================
              // WAVE
              // ======================================================
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                child: SizedBox(
                  height: 24,
                  child: CustomPaint(painter: _HomeWavePainter()),
                ),
              ),
            ],
          ),
        ),

        // ==========================================================
        // QUICK ACTIONS
        // ==========================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              _HomeShortcut(
                asset: 'assets/images/icon/icon_timtro.png',
                label: 'Tìm trọ',
                onTap: onFindRoomTap,
              ),
              _HomeShortcut(
                asset: 'assets/images/icon/icon_oghep.png',
                label: 'Ở ghép',
                onTap: onRoommateTap,
              ),
              _HomeShortcut(
                asset: 'assets/images/icon/icon_vitri.png',
                label: 'Bản đồ',
                onTap: onMapTap,
              ),
              _HomeShortcut(
                asset: 'assets/images/icon/icon_ngoinha.png',
                label: 'Phòng mới',
                onTap: onNewRoomTap,
              ),
            ],
          ),
        ),
      ],
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
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .055),
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
                style: const TextStyle(
                  fontSize: 11.3,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Lớp xanh mint nhẹ phía sau.
    final accentPaint = Paint()
      ..color = const Color(0xFFC8F0E6)
      ..style = PaintingStyle.fill;

    final accentPath = Path()
      ..moveTo(0, 6)
      ..cubicTo(size.width * .16, 24, size.width * .34, 3, size.width * .52, 10)
      ..cubicTo(size.width * .72, 19, size.width * .86, 17, size.width, 4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(accentPath, accentPaint);

    // Lớp nền chính của Home.
    final backgroundPaint = Paint()
      ..color = _pageBackground
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..moveTo(0, 12)
      ..cubicTo(size.width * .18, 28, size.width * .34, 7, size.width * .53, 14)
      ..cubicTo(size.width * .72, 23, size.width * .87, 20, size.width, 8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(backgroundPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
