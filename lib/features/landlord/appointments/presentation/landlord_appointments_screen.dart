import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../appointments/presentation/widgets/appointment_card.dart';

class LandlordAppointmentsScreen extends ConsumerStatefulWidget {
  const LandlordAppointmentsScreen({super.key});

  @override
  ConsumerState<LandlordAppointmentsScreen> createState() =>
      _LandlordAppointmentsScreenState();
}

class _LandlordAppointmentsScreenState
    extends ConsumerState<LandlordAppointmentsScreen> {
  String? _status;
  static const _filters = <(String, String?)>[
    ('Tất cả', null),
    ('Chờ xác nhận', 'PENDING'),
    ('Sắp tới', 'CONFIRMED'),
    ('Hoàn thành', 'COMPLETED'),
    ('Đã hủy', 'CANCELLED'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(landlordAppointmentsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Lịch hẹn xem phòng',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: _errorText(error),
          onRetry: () => ref.invalidate(landlordAppointmentsProvider),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(List<Appointment> items) {
    final visible = _status == null
        ? items
        : items.where((item) => item.status == _status).toList();
    final pending = items.where((item) => item.status == 'PENDING').length;
    final confirmed = items.where((item) => item.status == 'CONFIRMED').length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(landlordAppointmentsProvider);
        await ref.read(landlordAppointmentsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.pending_actions_rounded,
                      value: pending,
                      label: 'Chờ xác nhận',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.event_available_rounded,
                      value: confirmed,
                      label: 'Sắp tới',
                      color: const Color(0xFF009B7D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 47,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final filter = _filters[index];
                  final selected = _status == filter.$2;
                  return ChoiceChip(
                    label: Text(filter.$1),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF009B7D),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF53645F),
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: Color(0xFFDDE9E6)),
                    onSelected: (_) => setState(() => _status = filter.$2),
                  );
                },
              ),
            ),
          ),
          if (visible.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = visible[index];
                  return AppointmentCard(
                    appointment: item,
                    landlordView: true,
                    onTap: () async {
                      await context.push(
                        '/landlord/appointments/${item.id}',
                        extra: item,
                      );
                      ref.invalidate(landlordAppointmentsProvider);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE1ECE9)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF71817D)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined, size: 62, color: Color(0xFF9CB2AC)),
          SizedBox(height: 14),
          Text(
            'Chưa có lịch hẹn phù hợp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Các yêu cầu xem phòng của người thuê sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF71817D)),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Color(0xFF78928B),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

String _errorText(Object error) => error
    .toString()
    .replaceFirst('AppointmentFailure: ', '')
    .replaceFirst('Exception: ', '');
