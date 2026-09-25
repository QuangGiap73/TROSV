import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  static const _green = Color(0xFF05A886);
  static const _background = Color(0xFFF5F8F7);

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(authControllerProvider.notifier).refreshProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value?.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: user == null
            ? _EmptyState(
                loading: auth.isLoading,
                message: auth.hasError
                    ? auth.error.toString()
                    : 'Bạn cần đăng nhập để xem thông tin cá nhân.',
                onRetry: () =>
                    ref.read(authControllerProvider.notifier).refreshProfile(),
              )
            : RefreshIndicator(
                color: _green,
                onRefresh: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .refreshProfile();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _ProfileHero(user: user),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InformationCard(user: user),
                          if (auth.hasError) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Không thể làm mới dữ liệu: ${auth.error}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final AuthUser user;

  static const _green = Color(0xFF05A886);
  static const _darkText = Color(0xFF152238);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 286 + topPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Banner phủ từ mép trên màn hình, nằm sau status bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 168 + topPadding,
            child: Image.asset(
              'assets/images/profile/profile_B.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // Gradient giúp phần banner hòa mềm với nền nội dung.
          // Positioned(
          //   top: 108 + topPadding,
          //   left: 0,
          //   right: 0,
          //   height: 80,
          //   child: IgnorePointer(
          //     child: Container(
          //       decoration: const BoxDecoration(
          //         gradient: LinearGradient(
          //           begin: Alignment.topCenter,
          //           end: Alignment.bottomCenter,
          //           colors: [
          //             Colors.transparent,
          //             _background,
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // Header đặt trực tiếp trên banner.
          Positioned(
            top: topPadding + 7,
            left: 6,
            right: 6,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: _darkText,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Thông tin cá nhân',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // Avatar.
          Positioned(
            top: topPadding + 66,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _Avatar(user: user, radius: 45),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE1E8E6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Color(0xFF243957),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tên, vai trò, ID, ngày tham gia.
          Positioned(
            top: topPadding + 172,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.name ?? 'Người dùng TrọSV',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, size: 19, color: _green),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7EF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _roleName(user.activeMode),
                    style: const TextStyle(
                      color: Color(0xFF008D73),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'ID: #${_shortId(user.id)}',
                  style: const TextStyle(
                    color: Color(0xFF738096),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _joinDate(user.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF9AA5B5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) {
    final cleaned = id.replaceAll('-', '').toUpperCase();

    if (cleaned.length <= 8) {
      return cleaned;
    }

    return cleaned.substring(0, 8);
  }

  static String _joinDate(DateTime? value) {
    if (value == null) {
      return 'Chưa có thông tin ngày tham gia';
    }

    return 'Tham gia từ tháng ${value.month}, ${value.year}';
  }

  static String _roleName(String role) {
    return switch (role) {
      'TENANT' => 'Người thuê',
      'LANDLORD' => 'Chủ trọ',
      'LANDLORD_STAFF' => 'Nhân viên chủ trọ',
      'ORGANIZATION_OWNER' => 'Chủ tổ chức',
      _ => role,
    };
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 17, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(
                color: Color(0xFF152238),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Họ và tên',
              value: _text(user.name),
            ),
            _ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: _text(user.phone),
            ),
            _ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _text(user.email),
            ),
            _ProfileInfoRow(
              icon: Icons.chat_bubble_outline,
              label: 'Số điện thoại Zalo',
              value: _text(user.zaloPhone),
            ),
            _ProfileInfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Ngày tham gia',
              value: _date(user.createdAt),
            ),
            _ProfileInfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Trạng thái tài khoản',
              trailing: _StatusChip(status: user.status),
            ),
            _ProfileInfoRow(
              icon: Icons.groups_outlined,
              label: 'Vai trò hiện tại',
              trailing: _RoleChip(role: user.activeMode),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _text(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chưa cập nhật';
    }

    return value;
  }

  static String _date(DateTime? value) {
    if (value == null) {
      return 'Chưa cập nhật';
    }

    return 'Tháng ${value.month}, ${value.year}';
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F3F4), width: .8),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Icon(icon, size: 18, color: const Color(0xFF68758A)),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7B8698), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null)
            trailing!
          else
            Expanded(
              flex: 5,
              child: Text(
                value ?? '',
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF25344D),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0F8EE) : const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        active ? 'Đang hoạt động' : status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF00966F) : Colors.redAccent,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F8EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _roleName(role),
        style: const TextStyle(
          color: Color(0xFF00966F),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _roleName(String role) {
    return switch (role) {
      'TENANT' => 'Người thuê',
      'LANDLORD' => 'Chủ trọ',
      'LANDLORD_STAFF' => 'Nhân viên chủ trọ',
      'ORGANIZATION_OWNER' => 'Chủ tổ chức',
      _ => role,
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.radius});

  final AuthUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatarUrl;

    if (avatar != null && avatar.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFDDF6EF),
        backgroundImage: NetworkImage(avatar),
      );
    }

    final initial = (user.name?.trim().isNotEmpty ?? false)
        ? user.name!.trim()[0].toUpperCase()
        : 'T';

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFDDF6EF),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * .65,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF008E78),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: Color(0xFF718096),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
      ),
    );
  }
}
