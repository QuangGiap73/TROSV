import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../domain/entities/landlord_room.dart';
import 'providers/landlord_room_provider.dart';

class LandlordRoomsScreen extends ConsumerStatefulWidget {
  const LandlordRoomsScreen({super.key});
  @override
  ConsumerState<LandlordRoomsScreen> createState() => _State();
}

class _State extends ConsumerState<LandlordRoomsScreen> {
  String? status;
  static const filters = <String?, String>{
    null: 'Tất cả',
    'DRAFT': 'Bản nháp',
    'PENDING_REVIEW': 'Chờ duyệt',
    'PUBLISHED': 'Đang đăng',
    'RENTED': 'Đã thuê',
    'HIDDEN': 'Đang ẩn',
    'REJECTED': 'Từ chối',
  };

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(landlordRoomsProvider(status));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Phòng của tôi'),
        backgroundColor: const Color(0xFFF5F8F7),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Màn hình đăng phòng sẽ được xây tiếp.'),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Đăng phòng'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final entry = filters.entries.elementAt(index);
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: status == entry.key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => status = entry.key),
                );
              },
            ),
          ),
          Expanded(
            child: rooms.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Error(
                message: error.toString().replaceFirst('Exception: ', ''),
                retry: () => ref.invalidate(landlordRoomsProvider(status)),
              ),
              data: (items) => items.isEmpty
                  ? const _Empty()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(landlordRoomsProvider(status).future),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) =>
                            _RoomCard(room: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final LandlordRoom room;

  @override
  Widget build(BuildContext context) {
    final badge = _status(room.status);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: room.imageUrl == null || room.imageUrl!.isEmpty
                ? const _Fallback()
                : Image.network(
                    room.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _Fallback(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        room.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Badge(label: badge.label, color: badge.color),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${formatVnd(room.priceMonthly)}/tháng',
                  style: const TextStyle(
                    color: Color(0xFF008E78),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (room.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 5),
                      Expanded(child: Text(room.fullAddress, maxLines: 2)),
                    ],
                  ),
                ],
                const SizedBox(height: 11),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _Fact(
                      Icons.square_foot,
                      '${room.areaM2.toStringAsFixed(0)} m²',
                    ),
                    _Fact(Icons.people_outline, '${room.maxPeople} người'),
                    _Fact(Icons.visibility_outlined, '${room.viewsCount} lượt'),
                    _Fact(
                      Icons.event_available_outlined,
                      'Trống từ ${_date(room.availableDate)}',
                    ),
                  ],
                ),
                if (room.rejectionReason?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lý do từ chối: ${room.rejectionReason}',
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: const Color(0xFF657381)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8EFED),
    child: Center(child: Icon(Icons.home_work_outlined, size: 52)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Chưa có phòng trong mục này.'));
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 58),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

({String label, Color color}) _status(String value) => switch (value) {
  'DRAFT' => (label: 'Bản nháp', color: const Color(0xFF657381)),
  'PENDING_REVIEW' => (label: 'Chờ duyệt', color: const Color(0xFFE58A00)),
  'PUBLISHED' => (label: 'Đang đăng', color: const Color(0xFF008E78)),
  'RENTED' => (label: 'Đã thuê', color: const Color(0xFF6C5CE7)),
  'HIDDEN' => (label: 'Đang ẩn', color: const Color(0xFF718096)),
  'REJECTED' => (label: 'Từ chối', color: const Color(0xFFB42318)),
  _ => (label: value, color: const Color(0xFF657381)),
};

String _date(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
