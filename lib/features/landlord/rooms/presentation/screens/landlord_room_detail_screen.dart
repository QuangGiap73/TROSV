import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/landlord_room_detail.dart';
import '../providers/landlord_room_provider.dart';
import '../widgets/landlord_room_card.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF7FAF9);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF667773);

class LandlordRoomDetailScreen extends ConsumerWidget {
  const LandlordRoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(landlordRoomDetailProvider(roomId));
    final action = ref.watch(landlordRoomActionProvider);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết phòng',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: action.isLoading ? null : () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: action.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3, color: _green),
              )
            : null,
      ),
      body: detail.when(
        loading: () => const _DetailLoading(),
        error: (error, _) => _DetailError(
          message: _errorText(error),
          onRetry: () => _refresh(ref),
        ),
        data: (room) => RefreshIndicator(
          color: _green,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _MediaGallery(room: room),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 23,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusBadge(status: room.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_money(room.priceMonthly)} đ/tháng',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: _greenDark,
                      ),
                    ),
                    if (room.fullAddress.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: _muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              room.fullAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (room.status == 'REJECTED' &&
                        room.rejectionReason?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _RejectedCard(
                        roomId: room.id,
                        reason: room.rejectionReason!,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _RoomFacts(room: room),
                    if (room.description?.isNotEmpty == true)
                      _TextSection(
                        title: 'Mô tả',
                        icon: Icons.notes_rounded,
                        value: room.description!,
                      ),
                    if (room.houseRules?.isNotEmpty == true)
                      _TextSection(
                        title: 'Nội quy',
                        icon: Icons.rule_rounded,
                        value: room.houseRules!,
                      ),
                    if (room.spaces.isNotEmpty)
                      _SpacesSection(spaces: room.spaces),
                    if (room.amenities.isNotEmpty)
                      _AmenitiesSection(amenities: room.amenities),
                    if (room.cost != null) _CostSection(cost: room.cost!),
                    _TrackingSection(room: room),
                    const SizedBox(height: 18),
                    _ActionSection(room: room, disabled: action.isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(landlordRoomDetailProvider(roomId));
    try {
      await ref.read(landlordRoomDetailProvider(roomId).future);
    } catch (_) {}
  }
}

class _MediaGallery extends StatefulWidget {
  const _MediaGallery({required this.room});
  final LandlordRoomDetail room;
  @override
  State<_MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<_MediaGallery> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final urls = widget.room.images
        .map((e) => e.displayUrl)
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
    if (urls.isEmpty && widget.room.imageUrl?.isNotEmpty == true) {
      urls.add(widget.room.imageUrl!);
    }
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            const ColoredBox(
              color: Color(0xFFE4F2EF),
              child: Icon(
                Icons.home_work_outlined,
                size: 72,
                color: Color(0xFF7BA89E),
              ),
            )
          else
            PageView.builder(
              itemCount: urls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, index) => Image.network(
                urls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE4F2EF),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Color(0xFF7BA89E),
                  ),
                ),
              ),
            ),
          if (urls.isNotEmpty)
            Positioned(
              right: 14,
              bottom: 12,
              child: _OverlayLabel(text: '${_index + 1}/${urls.length}'),
            ),
          if (widget.room.videos.isNotEmpty)
            Positioned(
              left: 14,
              bottom: 12,
              child: _OverlayLabel(
                text: '${widget.room.videos.length} video',
                icon: Icons.play_circle_outline_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RoomFacts extends StatelessWidget {
  const _RoomFacts({required this.room});
  final LandlordRoomDetail room;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Thông tin phòng',
    icon: Icons.meeting_room_outlined,
    child: GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 2.7,
      children: [
        _Fact(
          icon: Icons.home_outlined,
          label: 'Loại phòng',
          value: _roomType(room.roomType),
        ),
        _Fact(
          icon: Icons.square_foot_rounded,
          label: 'Diện tích',
          value: '${_decimal(room.areaM2)} m²',
        ),
        _Fact(
          icon: Icons.layers_outlined,
          label: 'Tầng',
          value: room.floor?.toString() ?? 'Chưa cập nhật',
        ),
        _Fact(
          icon: Icons.people_alt_outlined,
          label: 'Tối đa',
          value: '${room.maxPeople} người',
        ),
        _Fact(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Tiền cọc',
          value: '${_money(room.depositAmount)} đ',
        ),
        _Fact(
          icon: Icons.event_available_outlined,
          label: 'Có thể vào ở',
          value: _date(room.availableDate),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F4),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 20, color: _greenDark),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: _muted)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.title,
    required this.icon,
    required this.value,
  });
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: title,
    icon: icon,
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        height: 1.55,
        color: Color(0xFF44534F),
      ),
    ),
  );
}

class _SpacesSection extends StatelessWidget {
  const _SpacesSection({required this.spaces});
  final List<LandlordRoomSpace> spaces;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Không gian',
    icon: Icons.dashboard_customize_outlined,
    child: Column(
      children: spaces
          .map(
            (space) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    _spaceIcon(space.spaceType),
                    color: _greenDark,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _spaceType(space.spaceType),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        if (space.description?.isNotEmpty == true)
                          Text(
                            space.description!,
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F7F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      space.privacyType == 'SHARED' ? 'Dùng chung' : 'Riêng',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _greenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _AmenitiesSection extends StatelessWidget {
  const _AmenitiesSection({required this.amenities});
  final List<LandlordRoomAmenity> amenities;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Tiện ích',
    icon: Icons.weekend_outlined,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities
          .map(
            (item) => Chip(
              avatar: Icon(
                _amenityIcon(item.code),
                size: 17,
                color: _greenDark,
              ),
              label: Text(item.name),
              labelStyle: const TextStyle(fontSize: 12, color: _text),
              backgroundColor: const Color(0xFFF0FAF7),
              side: const BorderSide(color: Color(0xFFD1EBE4)),
            ),
          )
          .toList(),
    ),
  );
}

class _CostSection extends StatelessWidget {
  const _CostSection({required this.cost});
  final LandlordRoomCost cost;
  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, String)>[
      (
        'Tiền điện',
        cost.electricityPrice,
        cost.electricityType == 'PER_PERSON' ? 'đ/người' : 'đ/kWh',
      ),
      (
        'Tiền nước',
        cost.waterPrice,
        cost.waterType == 'PER_PERSON' ? 'đ/người' : 'đ/m³',
      ),
      ('Internet', cost.internetFee, 'đ/tháng'),
      ('Gửi xe', cost.parkingFee, 'đ/tháng'),
      ('Phí dịch vụ', cost.serviceFee, 'đ/tháng'),
      ('Phí vệ sinh', cost.cleaningFee, 'đ/tháng'),
      ('Phí khác', cost.otherFee, 'đ/tháng'),
    ];
    return _SectionCard(
      title: 'Chi phí sinh hoạt',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                  Text(
                    '${_money(row.$2)} ${row.$3}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cost.otherDescription?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cost.otherDescription!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackingSection extends StatelessWidget {
  const _TrackingSection({required this.room});
  final LandlordRoomDetail room;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Theo dõi tin đăng',
    icon: Icons.query_stats_rounded,
    child: Row(
      children: [
        Expanded(
          child: _Fact(
            icon: Icons.visibility_outlined,
            label: 'Lượt xem',
            value: '${room.viewsCount} lượt',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Fact(
            icon: Icons.verified_outlined,
            label: 'Xác nhận còn trống',
            value: _dateTime(room.lastConfirmedAt),
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE2EAE8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: _greenDark),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({required this.roomId, required this.reason});
  final String roomId, reason;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFCACA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Tin đăng bị từ chối',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9F2828),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Lý do: $reason',
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF8E3B3B),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/landlord/rooms/$roomId/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Chỉnh sửa & gửi duyệt lại'),
        ),
      ],
    ),
  );
}

class _ActionSection extends ConsumerWidget {
  const _ActionSection({required this.room, required this.disabled});
  final LandlordRoomDetail room;
  final bool disabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _actions(room.status);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Thao tác',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 10),
        if (room.status == 'DRAFT')
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: OutlinedButton.icon(
              onPressed: disabled
                  ? null
                  : () => context.push('/landlord/rooms/${room.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa phòng'),
            ),
          ),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: FilledButton.icon(
              onPressed: disabled ? null : () => _perform(context, ref, action),
              style: FilledButton.styleFrom(
                backgroundColor: _actionDangerous(action)
                    ? Colors.redAccent
                    : _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(_actionIcon(action)),
              label: Text(_actionLabel(action)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    LandlordRoomAction action,
  ) async {
    if (action == LandlordRoomAction.delete) {
      final accepted = await _confirm(context, action);
      if (!accepted || !context.mounted) return;
    } else if ({
      LandlordRoomAction.hide,
      LandlordRoomAction.markRented,
      LandlordRoomAction.unmarkRented,
    }.contains(action)) {
      final accepted = await _confirm(context, action);
      if (!accepted || !context.mounted) return;
    }
    final controller = ref.read(landlordRoomActionProvider.notifier);
    final success = switch (action) {
      LandlordRoomAction.submit => await controller.submitRoom(room.id),
      LandlordRoomAction.show => await controller.updateVisibility(
        room.id,
        visible: true,
      ),
      LandlordRoomAction.hide => await controller.updateVisibility(
        room.id,
        visible: false,
      ),
      LandlordRoomAction.confirmAvailability =>
        await controller.confirmAvailability(room.id),
      LandlordRoomAction.markRented => await controller.markRented(room.id),
      LandlordRoomAction.unmarkRented => await controller.unmarkRented(room.id),
      LandlordRoomAction.delete => await controller.deleteRoom(room.id),
    };
    if (!context.mounted) return;
    if (success && action == LandlordRoomAction.delete) {
      context.pop(true);
      return;
    }
    final message = success
        ? 'Đã cập nhật trạng thái phòng.'
        : _errorText(ref.read(landlordRoomActionProvider).error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<bool> _confirm(
    BuildContext context,
    LandlordRoomAction action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_actionLabel(action)),
          content: Text(
            'Bạn có chắc muốn ${_actionLabel(action).toLowerCase()} “${room.title}”?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ) ??
      false;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'REJECTED' => Colors.redAccent,
      'PUBLISHED' => _greenDark,
      'PENDING_REVIEW' => Colors.orange,
      'RENTED' => Colors.indigo,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        _status(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _green));
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 55,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          const Text(
            'Không tải được chi tiết phòng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 16),
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

List<LandlordRoomAction> _actions(String status) => switch (status) {
  'DRAFT' => const [LandlordRoomAction.submit, LandlordRoomAction.delete],
  'REJECTED' => const [LandlordRoomAction.submit],
  'PUBLISHED' => const [
    LandlordRoomAction.confirmAvailability,
    LandlordRoomAction.hide,
    LandlordRoomAction.markRented,
  ],
  'HIDDEN' => const [LandlordRoomAction.show],
  'RENTED' => const [LandlordRoomAction.unmarkRented],
  _ => const [],
};
String _actionLabel(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => 'Gửi duyệt',
  LandlordRoomAction.show => 'Hiện phòng',
  LandlordRoomAction.hide => 'Ẩn phòng',
  LandlordRoomAction.confirmAvailability => 'Xác nhận còn trống',
  LandlordRoomAction.markRented => 'Đánh dấu đã thuê',
  LandlordRoomAction.unmarkRented => 'Chuyển về còn trống',
  LandlordRoomAction.delete => 'Hủy phòng',
};
IconData _actionIcon(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => Icons.send_rounded,
  LandlordRoomAction.show => Icons.visibility_rounded,
  LandlordRoomAction.hide => Icons.visibility_off_rounded,
  LandlordRoomAction.confirmAvailability => Icons.event_available_rounded,
  LandlordRoomAction.markRented => Icons.key_rounded,
  LandlordRoomAction.unmarkRented => Icons.home_work_rounded,
  LandlordRoomAction.delete => Icons.delete_outline_rounded,
};
bool _actionDangerous(LandlordRoomAction action) =>
    action == LandlordRoomAction.delete;
String _status(String value) => switch (value) {
  'DRAFT' => 'Bản nháp',
  'PENDING_REVIEW' => 'Chờ duyệt',
  'PUBLISHED' => 'Đang đăng',
  'REJECTED' => 'Bị từ chối',
  'HIDDEN' => 'Đã ẩn',
  'RENTED' => 'Đã thuê',
  'CANCELLED' => 'Đã hủy',
  _ => value,
};
String _roomType(String value) => switch (value) {
  'ROOM_SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' => 'Phòng ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};
String _spaceType(String value) => switch (value) {
  'MAIN_ROOM' => 'Phòng chính',
  'BATHROOM' => 'Nhà vệ sinh',
  'KITCHEN' => 'Khu bếp',
  'BALCONY' => 'Ban công',
  'OTHER' => 'Không gian khác',
  _ => value,
};
IconData _spaceIcon(String value) => switch (value) {
  'BATHROOM' => Icons.bathtub_outlined,
  'KITCHEN' => Icons.kitchen_outlined,
  'BALCONY' => Icons.balcony_outlined,
  'MAIN_ROOM' => Icons.bed_outlined,
  _ => Icons.other_houses_outlined,
};
IconData _amenityIcon(String code) {
  final value = code.toUpperCase();
  if (value.contains('WIFI')) return Icons.wifi_rounded;
  if (value.contains('AIR') || value.contains('DIEU_HOA')) {
    return Icons.ac_unit_rounded;
  }
  if (value.contains('WASH')) return Icons.local_laundry_service_outlined;
  if (value.contains('PARK')) return Icons.two_wheeler_rounded;
  if (value.contains('CAMERA')) return Icons.videocam_outlined;
  if (value.contains('ELEVATOR')) return Icons.elevator_outlined;
  return Icons.check_circle_outline_rounded;
}

String _money(int value) {
  final text = value.toString();
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
String _date(DateTime? value) => value == null
    ? 'Chưa cập nhật'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _dateTime(DateTime? value) =>
    value == null ? 'Chưa xác nhận' : _date(value.toLocal());
String _errorText(Object? error) =>
    error?.toString().replaceFirst('LandlordRoomFailure: ', '') ??
    'Có lỗi xảy ra. Vui lòng thử lại.';
