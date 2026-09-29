import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF6F9F8);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);
const _border = Color(0xFFE2EAE8);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Thông báo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Cập nhật mới từ hệ thống',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: notifications.when(
        loading: () => const _NotificationLoading(),
        error: (_, _) => _NotificationError(
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const _NotificationEmpty();
          }

          final groups = _groupNotifications(page.items);

          return RefreshIndicator(
            color: _green,
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
              children: [
                if (groups.today.isNotEmpty) ...[
                  const _SectionTitle('Hôm nay'),
                  const SizedBox(height: 9),
                  ..._tiles(groups.today, context, ref),
                ],
                if (groups.yesterday.isNotEmpty) ...[
                  if (groups.today.isNotEmpty) const SizedBox(height: 18),
                  const _SectionTitle('Hôm qua'),
                  const SizedBox(height: 9),
                  ..._tiles(groups.yesterday, context, ref),
                ],
                if (groups.older.isNotEmpty) ...[
                  if (groups.today.isNotEmpty || groups.yesterday.isNotEmpty)
                    const SizedBox(height: 18),
                  const _SectionTitle('Trước đó'),
                  const SizedBox(height: 9),
                  ..._tiles(groups.older, context, ref),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tiles(
    List<AppNotification> items,
    BuildContext context,
    WidgetRef ref,
  ) {
    return [
      for (var index = 0; index < items.length; index++) ...[
        _NotificationTile(
          item: items[index],
          onTap: () => _open(context, ref, items[index]),
        ),
        if (index != items.length - 1) const SizedBox(height: 10),
      ],
    ];
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    await ref.read(notificationsProvider.notifier).markRead(item);

    if (!context.mounted) return;

    final appointmentId = item.data['appointment_id'];
    final roomId = item.data['room_id'];

    if (appointmentId is String && appointmentId.trim().isNotEmpty) {
      final user = ref.read(authControllerProvider).asData?.value?.user;

      context.push(
        user?.isLandlordMode == true
            ? '/landlord/appointments'
            : '/profile/appointments',
      );
      return;
    }

    if (roomId is String && roomId.trim().isNotEmpty) {
      context.push('/rooms/$roomId');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: _textPrimary,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = _notificationVisual(item);
    final hasDestination = _hasDestination(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: item.isRead ? _border : const Color(0xFFD4EEE7),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: config.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.foreground, size: 23),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: item.isRead
                                  ? FontWeight.w800
                                  : FontWeight.w900,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: CircleAvatar(
                              radius: 4.5,
                              backgroundColor: _green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.42,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _friendlyTime(item.createdAt),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A9692),
                            ),
                          ),
                        ),
                        if (hasDestination)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF81908C),
                            size: 21,
                          ),
                      ],
                    ),
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

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F8F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: _greenDark,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Bạn chưa có thông báo nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Các cập nhật về lịch hẹn, phòng trọ và hoạt động tài khoản sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 13),
            const Text(
              'Không thể tải thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Đã xảy ra lỗi khi tải danh sách thông báo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _textSecondary),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLoading extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const _NotificationSkeleton(),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EFEC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(170, 14),
                const SizedBox(height: 9),
                _line(double.infinity, 10),
                const SizedBox(height: 6),
                _line(210, 10),
                const Spacer(),
                _line(92, 9),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EFEC),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

typedef _VisualConfig = ({IconData icon, Color foreground, Color background});

_VisualConfig _notificationVisual(AppNotification item) {
  final text = '${item.title} ${item.body}'.toLowerCase();

  if (text.contains('lịch') || item.data['appointment_id'] != null) {
    return (
      icon: Icons.calendar_month_outlined,
      foreground: _greenDark,
      background: const Color(0xFFDDF5EE),
    );
  }

  if (text.contains('phòng') || item.data['room_id'] != null) {
    return (
      icon: Icons.home_work_outlined,
      foreground: const Color(0xFF3579C8),
      background: const Color(0xFFE8F2FF),
    );
  }

  if (text.contains('duyệt') || text.contains('xác nhận')) {
    return (
      icon: Icons.verified_outlined,
      foreground: _greenDark,
      background: const Color(0xFFDDF5EE),
    );
  }

  return (
    icon: Icons.notifications_none_rounded,
    foreground: const Color(0xFF6D7D78),
    background: const Color(0xFFF0F3F2),
  );
}

bool _hasDestination(AppNotification item) {
  final appointmentId = item.data['appointment_id'];
  final roomId = item.data['room_id'];

  return appointmentId is String || roomId is String;
}

typedef _NotificationGroups = ({
  List<AppNotification> today,
  List<AppNotification> yesterday,
  List<AppNotification> older,
});

_NotificationGroups _groupNotifications(List<AppNotification> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final todayItems = <AppNotification>[];
  final yesterdayItems = <AppNotification>[];
  final olderItems = <AppNotification>[];

  final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  for (final item in sorted) {
    final local = item.createdAt.toLocal();
    final date = DateTime(local.year, local.month, local.day);

    if (date == today) {
      todayItems.add(item);
    } else if (date == yesterday) {
      yesterdayItems.add(item);
    } else {
      olderItems.add(item);
    }
  }

  return (today: todayItems, yesterday: yesterdayItems, older: olderItems);
}

String _friendlyTime(DateTime value) {
  final d = value.toLocal();
  final now = DateTime.now();

  final sameDay =
      d.year == now.year && d.month == now.month && d.day == now.day;

  final yesterday = now.subtract(const Duration(days: 1));

  final isYesterday =
      d.year == yesterday.year &&
      d.month == yesterday.month &&
      d.day == yesterday.day;

  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  if (sameDay) {
    return 'Hôm nay, $time';
  }

  if (isYesterday) {
    return 'Hôm qua, $time';
  }

  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $time';
}
