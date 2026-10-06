import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/room_detail.dart';
import '../providers/room_providers.dart';
import '../widgets/detail/shared_room_detail_content.dart';
import '../widgets/report/room_report_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.roomId, super.key});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomDetailProvider(roomId));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết phòng'),
          actions: [
            if (room.asData?.value case final detail?)
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                onSelected: (value) {
                  if (value == 'report') {
                    _openReport(context, ref, detail);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.outlined_flag_rounded,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text('Báo cáo phòng'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: const SharedRoomDetailTabBar(),
        ),
        body: room.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DetailError(
            onRetry: () => ref.invalidate(roomDetailProvider(roomId)),
          ),
          data: (data) => SharedRoomDetailTabView(
            room: _tenantViewData(data),
            onRefresh: () async {
              ref.invalidate(roomDetailProvider(roomId));
              await ref.read(roomDetailProvider(roomId).future);
            },
          ),
        ),
        bottomNavigationBar: room.hasValue
            ? SafeArea(
                minimum: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: room.asData?.value.status == 'PUBLISHED'
                      ? () => _openBooking(context, ref, room.asData!.value)
                      : null,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Đặt lịch xem phòng'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _openBooking(
    BuildContext context,
    WidgetRef ref,
    RoomDetail room,
  ) async {
    var session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) return;
      session = ref.read(authControllerProvider).asData?.value;
    }
    if (session == null || !context.mounted) return;
    await context.push<bool>(
      Uri(
        path: '/appointments/create',
        queryParameters: {'roomId': room.id, 'roomTitle': room.title},
      ).toString(),
    );
  }

  Future<void> _openReport(
    BuildContext context,
    WidgetRef ref,
    RoomDetail room,
  ) async {
    var session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      ref.read(authControllerProvider.notifier).clearError();
      final loggedIn = await context.push<bool>('/login');
      if (loggedIn != true || !context.mounted) return;
      session = ref.read(authControllerProvider).asData?.value;
    }
    if (session == null || !context.mounted) return;

    final report = await showRoomReportSheet(
      context: context,
      ref: ref,
      roomId: room.id,
      roomTitle: room.title,
    );
    if (report == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF009B7D),
          size: 52,
        ),
        title: const Text('Đã gửi báo cáo'),
        content: const Text(
          'Cảm ơn bạn đã giúp cộng đồng TrọSV an toàn và đáng tin cậy hơn. '
          'Chúng tôi sẽ kiểm tra thông tin sớm nhất có thể.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF009B7D),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

SharedRoomDetailData _tenantViewData(RoomDetail room) {
  final cost = room.cost;
  return SharedRoomDetailData(
    title: room.title,
    status: room.status,
    priceMonthly: room.priceMonthly,
    estimatedMonthlyCost: room.estimatedMonthlyCost,
    depositAmount: room.depositAmount,
    areaM2: room.areaM2,
    maxPeople: room.maxPeople,
    floor: room.floor,
    address: room.address,
    latitude: room.latitude,
    longitude: room.longitude,
    imageUrls: room.imageUrls,
    videoUrls: room.videoUrls,
    amenities: room.amenities,
    description: room.description,
    houseRules: room.houseRules,
    availableDate: room.availableDate,
    lastConfirmedAt: room.lastConfirmedAt,
    viewsCount: room.viewsCount,
    costs: {
      if (cost?.electricityPrice != null)
        'Tiền điện / kWh': cost!.electricityPrice!,
      if (cost?.waterPrice != null) 'Tiền nước': cost!.waterPrice!,
      if (cost?.internetFee != null) 'Internet': cost!.internetFee!,
      if (cost?.parkingFee != null) 'Gửi xe': cost!.parkingFee!,
      if (cost?.serviceFee != null) 'Phí dịch vụ': cost!.serviceFee!,
      if (cost?.cleaningFee != null) 'Phí vệ sinh': cost!.cleaningFee!,
      if (cost?.otherFee != null) 'Phí khác': cost!.otherFee!,
    },
  );
}

// TODO: Xóa phần chi tiết cũ sau khi ổn định SharedRoomDetailContent.
// ignore: unused_element
class _RoomDetailBody extends StatelessWidget {
  const _RoomDetailBody({required this.room});
  final RoomDetail room;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: 260,
          child: room.imageUrls.isEmpty
              ? const _DetailImageFallback()
              : PageView.builder(
                  itemCount: room.imageUrls.length,
                  itemBuilder: (_, index) => Image.network(
                    room.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _DetailImageFallback(),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RoomStatusBadge(status: room.status),
                  if (room.lastConfirmedAt != null)
                    _InfoBadge(
                      icon: Icons.update_rounded,
                      text: 'Xác nhận ${_formatDate(room.lastConfirmedAt!)}',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${formatVnd(room.priceMonthly)}/tháng',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(room.address)),
                ],
              ),
              const SizedBox(height: 20),
              if (room.availableDate != null) ...[
                _DetailInfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Có thể vào ở từ',
                  value: _formatDate(room.availableDate!),
                ),
                const SizedBox(height: 10),
              ],
              if (room.landlordName?.trim().isNotEmpty ?? false) ...[
                _DetailInfoRow(
                  icon: Icons.person_outline,
                  label: 'Chủ trọ',
                  value: room.landlordName!,
                ),
                const SizedBox(height: 10),
              ],
              _DetailInfoRow(
                icon: Icons.visibility_outlined,
                label: 'Lượt xem',
                value: room.viewsCount.toString(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Fact(icon: Icons.square_foot, text: '${room.areaM2} m²'),
                  _Fact(
                    icon: Icons.people_outline,
                    text: '${room.maxPeople} người',
                  ),
                  _Fact(
                    icon: Icons.stairs_outlined,
                    text: room.floor == null
                        ? 'Chưa rõ tầng'
                        : 'Tầng ${room.floor}',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _Title('Mô tả'),
              const SizedBox(height: 8),
              Text(room.description),
              const SizedBox(height: 24),
              const _Title('Chi phí'),
              _CostRow('Tiền thuê', room.priceMonthly),
              _CostRow('Tiền cọc', room.depositAmount),
              if (room.cost?.electricityPrice != null)
                _CostRow('Tiền điện / kWh', room.cost!.electricityPrice!),
              if (room.cost?.waterPrice != null)
                _CostRow('Tiền nước', room.cost!.waterPrice!),
              if (room.cost?.internetFee != null)
                _CostRow('Internet', room.cost!.internetFee!),
              if (room.cost?.parkingFee != null)
                _CostRow('Gửi xe', room.cost!.parkingFee!),
              const SizedBox(height: 24),
              const _Title('Tiện ích'),
              const SizedBox(height: 8),
              if (room.amenities.isEmpty)
                const Text('Chưa cập nhật tiện ích.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: room.amenities
                      .map(
                        (item) => Chip(
                          avatar: const Icon(Icons.check, size: 18),
                          label: Text(item),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
              const _Title('Nội quy'),
              const SizedBox(height: 8),
              Text(room.houseRules),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _statusLabel(String status) => switch (status) {
  'PUBLISHED' => 'Đang còn phòng',
  'RENTED' => 'Đã cho thuê',
  'HIDDEN' => 'Đang tạm ẩn',
  'PENDING_REVIEW' => 'Đang chờ duyệt',
  'DRAFT' => 'Bản nháp',
  'REJECTED' => 'Bị từ chối',
  'CANCELLED' => 'Đã hủy',
  _ => status,
};

class _RoomStatusBadge extends StatelessWidget {
  const _RoomStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status == 'PUBLISHED';
    final color = available ? const Color(0xFF008E78) : const Color(0xFF7A8794);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5D6B78)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Text('$label: ', style: const TextStyle(color: Color(0xFF687685))),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 6),
      Text(text),
    ],
  );
}

class _CostRow extends StatelessWidget {
  const _CostRow(this.label, this.amount);
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          formatVnd(amount),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('Không thể tải chi tiết phòng.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

class _DetailImageFallback extends StatelessWidget {
  const _DetailImageFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.home_work_outlined, size: 72)),
  );
}
