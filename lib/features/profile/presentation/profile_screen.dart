import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value?.user;

    if (auth.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: user == null
          ? _GuestProfile(
              onLogin: () async {
                ref.read(authControllerProvider.notifier).clearError();
                await context.push<bool>('/login');
              },
            )
          : RefreshIndicator(
              color: _ProfileColors.primary,
              onRefresh: () =>
                  ref.read(authControllerProvider.notifier).refreshProfile(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _ProfileHero(
                    user: user,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _QuickActions(
                      onPersonalInfo: () =>
                          context.push('/profile/personal-info'),
                      onPreferences: () => context.push('/profile/preferences'),
                      onFavorites: () => context.go('/favorites'),
                      onAppointments: () => _comingSoon(context, 'Lịch hẹn'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CompletionCard(
                      percent: user.profileComplete ? 1 : .8,
                      onTap: () => context.push('/profile/edit'),
                    ),
                  ),
                  const _SectionTitle(title: 'Cá nhân'),
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF17A673),
                    title: 'Thông tin cá nhân',
                    subtitle: 'Xem họ tên, liên hệ và thông tin tài khoản',
                    onTap: () => context.push('/profile/personal-info'),
                  ),
                  _MenuItem(
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF6C63D9),
                    title: 'Nhu cầu tìm phòng',
                    subtitle: 'Cập nhật tiêu chí phòng trọ phù hợp',
                    onTap: () => context.push('/profile/preferences'),
                  ),
                  _MenuItem(
                    icon: Icons.groups_2_outlined,
                    iconColor: const Color(0xFFF09A36),
                    title: 'Tin tìm người ở ghép',
                    subtitle: 'Quản lý các tin tìm người ở ghép của bạn',
                    onTap: () => _comingSoon(context, 'Tin tìm người ở ghép'),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFFE9608E),
                    title: 'Thông báo',
                    subtitle: 'Cài đặt và xem thông báo mới',
                    onTap: () => _comingSoon(context, 'Thông báo'),
                  ),
                  const _SectionTitle(title: 'Tài khoản & bảo mật'),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF4386E6),
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu đăng nhập',
                    onTap: () => context.push('/profile/change-password'),
                  ),
                  _MenuItem(
                    icon: Icons.devices_rounded,
                    iconColor: const Color(0xFF7659D6),
                    title: 'Quản lý thiết bị',
                    subtitle: 'Kiểm tra các thiết bị đang đăng nhập',
                    onTap: () =>
                        _comingSoon(context, 'Quản lý thiết bị đăng nhập'),
                  ),
                  if (user.availableLandlordMode != null)
                    _MenuItem(
                      icon: Icons.apartment_rounded,
                      iconColor: _ProfileColors.primary,
                      title: 'Chuyển sang chủ trọ',
                      subtitle: 'Quản lý phòng và hoạt động cho thuê',
                      onTap: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .switchActiveMode(user.availableLandlordMode!);
                        if (success && context.mounted) {
                          context.go('/landlord');
                        }
                      },
                    ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFE05252),
                    title: 'Đăng xuất',
                    subtitle: 'Đăng xuất tài khoản khỏi thiết bị này',
                    showChevron: false,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature đang được phát triển.')));
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE05252),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final displayName = _displayName(user);

    return SizedBox(
      height: 330 + topPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 88,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF91DFCF), Color(0xFFC5F0E6)],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: .28,
                    child: Image.asset(
                      'assets/images/profile/profile_A.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const Positioned(
                    top: -55,
                    right: -30,
                    child: _GlowCircle(size: 190),
                  ),
                  const Positioned(
                    left: -55,
                    bottom: -70,
                    child: _GlowCircle(size: 170),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _Avatar(user: user, radius: 54),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17352F),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              elevation: 0,
              shadowColor: Colors.black.withValues(alpha: .16),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Avatar(user: user, radius: 31),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 17,
                                  color: _ProfileColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _ProfileColors.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roleLabel(user),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _ProfileColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID: ${_shortId(user.id)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF78837F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF34413E),
                      ),
                    ],
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .22),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.radius});

  final AuthUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl?.trim();

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: _ProfileColors.primarySoft,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(
                _initial(user),
                style: TextStyle(
                  fontSize: radius * .62,
                  fontWeight: FontWeight.w800,
                  color: _ProfileColors.primaryDark,
                ),
              )
            : null,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPersonalInfo,
    required this.onPreferences,
    required this.onFavorites,
    required this.onAppointments,
  });

  final VoidCallback onPersonalInfo;
  final VoidCallback onPreferences;
  final VoidCallback onFavorites;
  final VoidCallback onAppointments;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _QuickAction(
          icon: Icons.badge_outlined,
          label: 'Hồ sơ',
          color: const Color(0xFF17A673),
          onTap: onPersonalInfo,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.tune_rounded,
          label: 'Nhu cầu',
          color: const Color(0xFF6C63D9),
          onTap: onPreferences,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.favorite_border_rounded,
          label: 'Đã lưu',
          color: const Color(0xFFE9608E),
          onTap: onFavorites,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'Lịch hẹn',
          color: const Color(0xFFF09A36),
          onTap: onAppointments,
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percent, required this.onTap});

  final double percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0.0, 1.0).toDouble();
    final label = '${(value * 100).round()}%';

    return Material(
      color: _ProfileColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ProfileColors.primary,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ đã hoàn thiện $label',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ProfileColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.white,
                        color: _ProfileColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bổ sung thông tin để tăng độ tin cậy.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF55706A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 7),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF293633),
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2C29),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C8885),
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA5A2),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 50),
        Container(
          width: 104,
          height: 104,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _ProfileColors.primarySoft,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 55,
            color: _ProfileColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tài khoản của bạn',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Đăng nhập để quản lý hồ sơ, lưu phòng yêu thích và cập nhật nhu cầu tìm trọ.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, color: Color(0xFF687571)),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onLogin,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _ProfileColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

abstract final class _ProfileColors {
  static const background = Color(0xFFF5F7F6);
  static const primary = Color(0xFF08A887);
  static const primaryDark = Color(0xFF087A65);
  static const primarySoft = Color(0xFFE7F8F3);
}

String _displayName(AuthUser user) {
  final name = user.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return user.phone.isNotEmpty ? user.phone : 'Người dùng TrọSV';
}

String _initial(AuthUser user) {
  final value = _displayName(user).trim();
  return value.isEmpty ? 'T' : value.substring(0, 1).toUpperCase();
}

String _shortId(String id) {
  if (id.length <= 8) return id.toUpperCase();
  return id.substring(0, 8).toUpperCase();
}

String _roleLabel(AuthUser user) {
  return user.isLandlordMode ? 'Chủ trọ' : 'Người thuê';
}
