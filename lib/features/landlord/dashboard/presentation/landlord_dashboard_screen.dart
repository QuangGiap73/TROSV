import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../rooms/domain/entities/landlord_room.dart';
import '../../rooms/presentation/providers/landlord_room_provider.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _bg = Color(0xFFF7FAF9);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF6A7975);
const _border = Color(0xFFE3ECE9);

class LandlordDashboardScreen extends ConsumerStatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  ConsumerState<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState
    extends ConsumerState<LandlordDashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(landlordRoomsProvider);
    try {
      await ref.read(landlordRoomsProvider(null).future);
    } catch (_) {}
  }

  Future<void> _createRoom() async {
    final created = await context.push<bool>('/landlord/rooms/create');
    if (created == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value?.user;
    final rooms = ref.watch(landlordRoomsProvider(null));
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _green,
        onRefresh: _refresh,
        child: rooms.when(
          loading: () => _DashboardList(
            top: top,
            name: user?.name,
            avatarUrl: user?.avatarUrl,
            onCreateRoom: _createRoom,
            child: const _LoadingBody(),
          ),
          error: (error, _) => _DashboardList(
            top: top,
            name: user?.name,
            avatarUrl: user?.avatarUrl,
            onCreateRoom: _createRoom,
            child: _ErrorCard(
              message: _errorText(error),
              onRetry: _refresh,
            ),
          ),
          data: (items) {
            final total = items.length;
            final published =
                items.where((e) => e.status == 'PUBLISHED').length;
            final rented =
                items.where((e) => e.status == 'RENTED').length;
            final pending =
                items.where((e) => e.status == 'PENDING_REVIEW').length;
            final drafts =
                items.where((e) => e.status == 'DRAFT').length;
            final rejected =
                items.where((e) => e.status == 'REJECTED').length;

            return _DashboardList(
              top: top,
              name: user?.name,
              avatarUrl: user?.avatarUrl,
              onCreateRoom: _createRoom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    title: 'Tổng quan',
                    subtitle: 'Tình trạng các phòng bạn đang quản lý',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: total,
                          label: 'Tổng phòng',
                          icon: Icons.home_work_outlined,
                          iconBg: Color(0xFFE5F7F2),
                          iconColor: _greenDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: published,
                          label: 'Đang hiển thị',
                          icon: Icons.visibility_outlined,
                          iconBg: Color(0xFFE9F8F0),
                          iconColor: Color(0xFF16945F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: rented,
                          label: 'Đã thuê',
                          icon: Icons.key_outlined,
                          iconBg: Color(0xFFEAF2FF),
                          iconColor: Color(0xFF477ED8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: pending,
                          label: 'Chờ duyệt',
                          icon: Icons.hourglass_top_rounded,
                          iconBg: Color(0xFFFFF4DE),
                          iconColor: Color(0xFFD78B14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Việc cần xử lý',
                    action: 'Quản lý phòng',
                    onTap: () => context.go('/landlord/rooms'),
                  ),
                  const SizedBox(height: 9),
                  _TaskBox(
                    drafts: drafts,
                    rejected: rejected,
                    pending: pending,
                    onRooms: () => context.go('/landlord/rooms'),
                    onAppointments: () =>
                        context.go('/landlord/appointments'),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Thao tác nhanh',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.add_home_work_outlined,
                        label: 'Đăng phòng',
                        onTap: _createRoom,
                      ),
                      _QuickAction(
                        icon: Icons.home_work_outlined,
                        label: 'Quản lý',
                        onTap: () => context.go('/landlord/rooms'),
                      ),
                      _QuickAction(
                        icon: Icons.event_available_outlined,
                        label: 'Lịch hẹn',
                        onTap: () =>
                            context.go('/landlord/appointments'),
                      ),
                      _QuickAction(
                        icon: Icons.notifications_none_rounded,
                        label: 'Thông báo',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Phòng của tôi',
                    action: 'Xem tất cả',
                    onTap: () => context.go('/landlord/rooms'),
                  ),
                  const SizedBox(height: 9),
                  if (items.isEmpty)
                    _EmptyRooms(onCreate: _createRoom)
                  else
                    ...items.take(3).map(
                          (room) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RoomPreviewCard(
                              room: room,
                              onTap: () => context
                                  .push('/landlord/rooms/${room.id}'),
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                  _AppointmentShortcut(
                    onTap: () =>
                        context.go('/landlord/appointments'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({
    required this.top,
    required this.name,
    required this.avatarUrl,
    required this.onCreateRoom,
    required this.child,
  });

  final double top;
  final String? name;
  final String? avatarUrl;
  final VoidCallback onCreateRoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 110),
      children: [
        _Header(
          name: name,
          avatarUrl: avatarUrl,
          onBell: () => context.push('/notifications'),
        ),
        const SizedBox(height: 15),
        _HeroBanner(onCreateRoom: onCreateRoom),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.avatarUrl,
    required this.onBell,
  });

  final String? name;
  final String? avatarUrl;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final displayName =
        name?.trim().isNotEmpty == true ? name!.trim() : 'Chủ trọ';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE3F5F1),
          backgroundImage: avatarUrl?.trim().isNotEmpty == true
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl?.trim().isNotEmpty == true
              ? null
              : Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: _greenDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào,',
                style: TextStyle(fontSize: 11.5, color: _muted),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Chế độ chủ trọ',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onBell,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _text,
            side: const BorderSide(color: _border),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onCreateRoom});
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, _greenDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -18,
            child: Icon(
              Icons.apartment_rounded,
              size: 124,
              color: Colors.white.withOpacity(.14),
            ),
          ),
          Positioned(
            right: 82,
            bottom: 6,
            child: Icon(
              Icons.home_rounded,
              size: 62,
              color: Colors.white.withOpacity(.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 120, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý phòng trọ\nnhẹ nhàng hơn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đăng phòng, theo dõi trạng thái\nvà xử lý lịch hẹn cùng TrọSV.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.88),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: onCreateRoom,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _greenDark,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text(
                      'Đăng phòng mới',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: _muted,
            ),
          ),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _greenDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TaskBox extends StatelessWidget {
  const _TaskBox({
    required this.drafts,
    required this.rejected,
    required this.pending,
    required this.onRooms,
    required this.onAppointments,
  });

  final int drafts;
  final int rejected;
  final int pending;
  final VoidCallback onRooms;
  final VoidCallback onAppointments;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (drafts > 0) {
      rows.add(
        _TaskRow(
          icon: Icons.edit_note_rounded,
          title: '$drafts phòng đang ở bản nháp',
          subtitle: 'Hoàn thiện thông tin và gửi duyệt',
          color: const Color(0xFF4A7CC3),
          bg: const Color(0xFFEAF4FF),
          onTap: onRooms,
        ),
      );
    }
    if (rejected > 0) {
      rows.add(
        _TaskRow(
          icon: Icons.error_outline_rounded,
          title: '$rejected phòng bị từ chối',
          subtitle: 'Xem lý do và chỉnh sửa lại tin',
          color: const Color(0xFFD65757),
          bg: const Color(0xFFFFEAEA),
          onTap: onRooms,
        ),
      );
    }
    if (pending > 0) {
      rows.add(
        _TaskRow(
          icon: Icons.hourglass_top_rounded,
          title: '$pending phòng đang chờ duyệt',
          subtitle: 'Theo dõi trạng thái xét duyệt',
          color: const Color(0xFFD78B14),
          bg: const Color(0xFFFFF4DE),
          onTap: onRooms,
        ),
      );
    }

    rows.add(
      _TaskRow(
        icon: Icons.calendar_month_outlined,
        title: 'Lịch hẹn xem phòng',
        subtitle: 'Kiểm tra và xử lý yêu cầu từ người thuê',
        color: _greenDark,
        bg: const Color(0xFFE5F7F2),
        onTap: onAppointments,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: rows
            .expand((e) => [
                  e,
                  if (e != rows.last)
                    const Padding(
                      padding: EdgeInsets.only(left: 60),
                      child:
                          Divider(height: 1, color: Color(0xFFEDF2F0)),
                    ),
                ])
            .toList(),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: Color(0xFF9BA7A3),
              ),
            ],
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7F2),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 18, color: _greenDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _text,
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

class _RoomPreviewCard extends StatelessWidget {
  const _RoomPreviewCard({
    required this.room,
    required this.onTap,
  });

  final LandlordRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _status(room.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 78,
                  child: room.imageUrl?.trim().isNotEmpty == true
                      ? Image.network(
                          room.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: status.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: status.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_money(room.priceMonthly)} đ/tháng',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _greenDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      room.fullAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 9.5, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9BA7A3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFE8F4F1),
        child: Center(
          child: Icon(
            Icons.home_work_outlined,
            color: Color(0xFF77A59B),
            size: 29,
          ),
        ),
      );
}

class _AppointmentShortcut extends StatelessWidget {
  const _AppointmentShortcut({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFE8F7F3),
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: _greenDark,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý lịch hẹn xem phòng',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xem yêu cầu mới và cập nhật trạng thái lịch.',
                        style: TextStyle(
                          fontSize: 10,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _greenDark,
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.add_home_work_outlined,
              color: _greenDark,
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Bạn chưa có phòng nào',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onCreate,
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: const Text('Đăng phòng mới'),
            ),
          ],
        ),
      );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          4,
          (i) => Container(
            height: 86,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: _muted, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: _muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
}

({String label, Color bg, Color fg}) _status(String value) {
  return switch (value) {
    'PUBLISHED' => (
        label: 'Đang đăng',
        bg: const Color(0xFFE5F7F2),
        fg: _greenDark,
      ),
    'RENTED' => (
        label: 'Đã thuê',
        bg: const Color(0xFFEAF2FF),
        fg: const Color(0xFF477ED8),
      ),
    'PENDING_REVIEW' => (
        label: 'Chờ duyệt',
        bg: const Color(0xFFFFF4DE),
        fg: const Color(0xFFD78B14),
      ),
    'REJECTED' => (
        label: 'Từ chối',
        bg: const Color(0xFFFFEAEA),
        fg: const Color(0xFFD65757),
      ),
    'DRAFT' => (
        label: 'Bản nháp',
        bg: const Color(0xFFF0F2F2),
        fg: const Color(0xFF697572),
      ),
    _ => (
        label: value,
        bg: const Color(0xFFF0F2F2),
        fg: const Color(0xFF697572),
      ),
  };
}

String _money(int value) {
  final s = value.toString();
  final out = StringBuffer();

  for (var i = 0; i < s.length; i++) {
    final remaining = s.length - i;
    out.write(s[i]);
    if (remaining > 1 && remaining % 3 == 1) out.write('.');
  }

  return out.toString();
}

String _errorText(Object error) {
  final value = error.toString().replaceFirst('Exception: ', '').trim();
  return value.isEmpty ? 'Đã xảy ra lỗi. Vui lòng thử lại.' : value;
}
