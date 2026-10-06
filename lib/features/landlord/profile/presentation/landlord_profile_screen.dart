import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _primary = Color(0xFF00A884);
const _primaryDark = Color(0xFF008C72);
const _primarySoft = Color(0xFFE6F7F2);
const _background = Color(0xFFF5F9F7);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF74817E);

class LandlordProfileScreen extends ConsumerWidget {
  const LandlordProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value?.user;

    if (auth.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Về trang đăng nhập'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        color: _primary,
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
                onProfile: () => context.push('/profile/personal-info'),
                onRooms: () => context.go('/landlord/rooms'),
                onAppointments: () => context.go('/landlord/appointments'),
                onNotifications: () => context.push('/notifications'),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CompletionCard(
                complete: user.profileComplete,
                onTap: () => context.push('/profile/edit'),
              ),
            ),
            const _SectionTitle(title: 'Quản lý cho thuê'),
            _MenuItem(
              icon: Icons.home_work_outlined,
              iconColor: _primaryDark,
              title: 'Phòng của tôi',
              subtitle: 'Đăng mới và quản lý tình trạng phòng',
              onTap: () => context.go('/landlord/rooms'),
            ),
            _MenuItem(
              icon: Icons.event_available_outlined,
              iconColor: const Color(0xFFF09A36),
              title: 'Lịch hẹn khách thuê',
              subtitle: 'Theo dõi và xác nhận lịch xem phòng',
              onTap: () => context.go('/landlord/appointments'),
            ),
            _MenuItem(
              icon: Icons.notifications_none_rounded,
              iconColor: const Color(0xFFE9608E),
              title: 'Thông báo',
              subtitle: 'Cập nhật hoạt động phòng và lịch hẹn',
              onTap: () => context.push('/notifications'),
            ),
            const _SectionTitle(title: 'Tài khoản & bảo mật'),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFF17A673),
              title: 'Thông tin cá nhân',
              subtitle: 'Xem và cập nhật thông tin tài khoản',
              onTap: () => context.push('/profile/personal-info'),
            ),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF4386E6),
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu đăng nhập',
              onTap: () => context.push('/profile/change-password'),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFF7659D6),
              title: 'Quyền vị trí',
              subtitle: 'Quản lý quyền GPS của TrọSV',
              onTap: () => context.push('/profile/location-settings'),
            ),
            if (user.hasTenantRole)
              _MenuItem(
                icon: Icons.swap_horiz_rounded,
                iconColor: _primary,
                title: 'Chuyển sang người thuê',
                subtitle: 'Tìm phòng, lưu phòng và quản lý lịch xem',
                onTap: auth.isLoading
                    ? null
                    : () => _switchToTenant(context, ref),
              ),
            _MenuItem(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFE05252),
              title: 'Đăng xuất',
              subtitle: 'Đăng xuất tài khoản khỏi thiết bị này',
              showChevron: false,
              onTap: auth.isLoading
                  ? null
                  : () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Future<void> _switchToTenant(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .switchActiveMode('TENANT');
    if (success && context.mounted) context.go('/');
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE05252),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/');
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final name = _displayName(user);
    return SizedBox(
      height: 330 + top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
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
                        colors: [Color(0xFF7FD7C5), Color(0xFFC5F0E6)],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: .24,
                    child: Image.asset(
                      'assets/images/profile/profile_A.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const Positioned(
                    right: -40,
                    top: -60,
                    child: _GlowCircle(size: 190),
                  ),
                  const Positioned(
                    left: -45,
                    bottom: -75,
                    child: _GlowCircle(size: 170),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 22,
            left: 20,
            right: 20,
            child: Column(
              children: [
                _Avatar(user: user, radius: 54),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17352F),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Tài khoản chủ trọ',
                  style: TextStyle(
                    color: Color(0xFF42675F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 17,
                                  color: _primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Chủ trọ',
                                style: TextStyle(
                                  color: _primaryDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.phone,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF72807D),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.radius});

  final AuthUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl?.trim();
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: _primarySoft,
        backgroundImage: url != null && url.isNotEmpty
            ? NetworkImage(url)
            : null,
        child: url == null || url.isEmpty
            ? Text(
                _initial(user),
                style: TextStyle(
                  color: _primaryDark,
                  fontSize: radius * .62,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onProfile,
    required this.onRooms,
    required this.onAppointments,
    required this.onNotifications,
  });

  final VoidCallback onProfile;
  final VoidCallback onRooms;
  final VoidCallback onAppointments;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _QuickActionSlot(
        icon: Icons.badge_outlined,
        label: 'Hồ sơ',
        color: const Color(0xFF17A673),
        onTap: onProfile,
      ),
      const SizedBox(width: 8),
      _QuickActionSlot(
        icon: Icons.home_work_outlined,
        label: 'Phòng',
        color: const Color(0xFF4386E6),
        onTap: onRooms,
      ),
      const SizedBox(width: 8),
      _QuickActionSlot(
        icon: Icons.calendar_month_outlined,
        label: 'Lịch hẹn',
        color: const Color(0xFFF09A36),
        onTap: onAppointments,
      ),
      const SizedBox(width: 8),
      _QuickActionSlot(
        icon: Icons.notifications_none_rounded,
        label: 'Thông báo',
        color: const Color(0xFFE9608E),
        onTap: onNotifications,
      ),
    ],
  );
}

class _QuickActionSlot extends StatelessWidget {
  const _QuickActionSlot({
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
  Widget build(BuildContext context) => Expanded(
    child: Material(
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.complete, required this.onTap});

  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = complete ? 1.0 : .8;
    return Material(
      color: _primarySoft,
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
                  color: _primary,
                  shape: BoxShape.circle,
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
                      'Hồ sơ đã hoàn thiện ${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: _primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: _primary,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bổ sung thông tin để tăng độ tin cậy với người thuê.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF55706A)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _primaryDark),
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
        color: Color(0xFF293633),
        fontSize: 14,
        fontWeight: FontWeight.w800,
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
  final VoidCallback? onTap;
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
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
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

String _displayName(AuthUser user) {
  final name = user.name?.trim();
  return name == null || name.isEmpty ? 'Chủ trọ TrọSV' : name;
}

String _initial(AuthUser user) {
  final value = _displayName(user).trim();
  return value.isEmpty ? 'T' : value.substring(0, 1).toUpperCase();
}
