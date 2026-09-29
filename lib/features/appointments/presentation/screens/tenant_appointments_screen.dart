import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/appointment.dart';
import '../providers/appointment_provider.dart';
import '../widgets/appointment_card.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _greenSoft = Color(0xFFE8F8F3);
const _background = Color(0xFFF5F9F7);
const _border = Color(0xFFE1EAE7);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

class TenantAppointmentsScreen extends ConsumerStatefulWidget {
  const TenantAppointmentsScreen({super.key});

  @override
  ConsumerState<TenantAppointmentsScreen> createState() =>
      _TenantAppointmentsScreenState();
}

class _TenantAppointmentsScreenState
    extends ConsumerState<TenantAppointmentsScreen> {
  String? _status;

  static const _filters = <(String, String?)>[
    ('Tất cả', null),
    ('Chờ xác nhận', 'PENDING'),
    ('Đã xác nhận', 'CONFIRMED'),
    ('Hoàn thành', 'COMPLETED'),
    ('Đã hủy', 'CANCELLED'),
  ];

  static const _slots = <String>[
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '18:00 - 19:00',
  ];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myAppointmentsProvider);
    final actionState = ref.watch(appointmentActionProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch hẹn của tôi',
              style: TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Theo dõi và quản lý lịch xem phòng',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: actionState.isLoading
                ? null
                : () => ref.invalidate(myAppointmentsProvider),
            icon: const Icon(Icons.refresh_rounded, color: _textPrimary),
          ),
          const SizedBox(width: 6),
        ],
        bottom: actionState.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _green,
                  backgroundColor: Color(0xFFDDF1EB),
                ),
              )
            : null,
      ),
      body: data.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(
          message: _cleanError(error),
          onRetry: () => ref.invalidate(myAppointmentsProvider),
        ),
        data: (items) => _buildContent(items, actionState.isLoading),
      ),
    );
  }

  Widget _buildContent(List<Appointment> items, bool busy) {
    final visible = _status == null
        ? items
        : items.where((item) => item.status == _status).toList(growable: false);

    final sorted = [...visible]
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        ref.invalidate(myAppointmentsProvider);
        await ref.read(myAppointmentsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _TopArea(
              items: items,
              filters: _filters,
              selected: _status,
              onChanged: (value) {
                setState(() => _status = value);
              },
            ),
          ),

          if (sorted.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyView(
                hasAppointments: items.isNotEmpty,
                selectedStatus: _status,
                onShowAll: () {
                  setState(() => _status = null);
                },
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Danh sách lịch hẹn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${sorted.length} lịch',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
              sliver: SliverList.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 11),
                itemBuilder: (context, index) {
                  final item = sorted[index];

                  return AppointmentCard(
                    appointment: item,
                    landlordView: false,
                    onTap: () async {
                      final changed = await context.push<bool>(
                        '/profile/appointments/${item.id}',
                        extra: item,
                      );
                      if (changed == true) {
                        ref.invalidate(myAppointmentsProvider);
                      }
                    },
                    onLongPress: () => _openAppointmentActions(item, busy),
                    onCancel: item.canTenantChange && !busy
                        ? () => _cancel(item)
                        : null,
                    onReschedule: item.canTenantChange && !busy
                        ? () => _reschedule(item)
                        : null,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAppointmentActions(Appointment item, bool busy) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentActionsSheet(
        appointment: item,
        busy: busy,
        onReschedule: item.canTenantChange && !busy
            ? () {
                Navigator.pop(context);
                _reschedule(item);
              }
            : null,
        onCancel: item.canTenantChange && !busy
            ? () {
                Navigator.pop(context);
                _cancel(item);
              }
            : null,
      ),
    );
  }

  Future<void> _cancel(Appointment item) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CancelSheet(appointment: item),
    );

    if (accepted != true) return;

    final result = await ref
        .read(appointmentActionProvider.notifier)
        .cancel(item.id);

    if (!mounted) return;

    _message(
      result == null ? _actionError() : 'Đã hủy lịch hẹn.',
      error: result == null,
    );
  }

  Future<void> _reschedule(Appointment item) async {
    final value = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RescheduleSheet(
        initialDate: item.bookingDate,
        initialSlot: item.timeSlot,
        slots: _slots,
      ),
    );

    if (value == null) return;

    final result = await ref
        .read(appointmentActionProvider.notifier)
        .reschedule(item.id, bookingDate: value.$1, timeSlot: value.$2);

    if (!mounted) return;

    _message(
      result == null ? _actionError() : 'Đã cập nhật lịch hẹn.',
      error: result == null,
    );
  }

  String _actionError() {
    return ref.read(appointmentActionProvider).error?.toString() ??
        'Không thể cập nhật lịch hẹn.';
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }
}

// =============================================================
// TOP AREA
// =============================================================

class _TopArea extends StatelessWidget {
  const _TopArea({
    required this.items,
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  final List<Appointment> items;
  final List<(String, String?)> filters;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final upcoming = _findNearestUpcoming(items);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcoming != null) ...[
            _UpcomingBanner(appointment: upcoming),
            const SizedBox(height: 14),
          ],

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];

                final count = filter.$2 == null
                    ? items.length
                    : items.where((item) => item.status == filter.$2).length;

                final active = selected == filter.$2;

                return ChoiceChip(
                  selected: active,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(filter.$2),
                  label: Text('${filter.$1} ($count)'),
                  backgroundColor: Colors.white,
                  selectedColor: _green,
                  side: BorderSide(color: active ? _green : _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? Colors.white : _textSecondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBanner extends StatelessWidget {
  const _UpcomingBanner({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F7F1), Color(0xFFF3FBF8)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD2ECE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: _greenDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch hẹn sắp tới',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _greenDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  appointment.roomTitle ?? 'Phòng trọ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_weekdayLong(appointment.bookingDate)}, ${_date(appointment.bookingDate)} · ${appointment.timeSlot}',
                  style: const TextStyle(fontSize: 11.5, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ACTION SHEET
// =============================================================

class _AppointmentActionsSheet extends StatelessWidget {
  const _AppointmentActionsSheet({
    required this.appointment,
    required this.busy,
    this.onReschedule,
    this.onCancel,
  });

  final Appointment appointment;
  final bool busy;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE5E2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            appointment.roomTitle ?? 'Phòng trọ',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${_weekdayLong(appointment.bookingDate)}, ${_date(appointment.bookingDate)} · ${appointment.timeSlot}',
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),

          const SizedBox(height: 16),

          _SheetInfoRow(
            icon: Icons.person_pin_circle_outlined,
            label: 'Chủ trọ',
            value: appointment.landlordName ?? 'Chủ trọ',
          ),

          if (appointment.landlordPhone?.trim().isNotEmpty == true)
            _SheetInfoRow(
              icon: Icons.phone_outlined,
              label: 'Liên hệ',
              value: appointment.landlordPhone!,
            ),

          if (appointment.note?.trim().isNotEmpty == true)
            _SheetInfoRow(
              icon: Icons.notes_rounded,
              label: 'Ghi chú',
              value: appointment.note!,
            ),

          if (onReschedule != null || onCancel != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                if (onReschedule != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onReschedule,
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Đổi lịch'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _greenDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                if (onReschedule != null && onCancel != null)
                  const SizedBox(width: 9),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onCancel,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Hủy lịch'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Color(0xFFFFCFCF)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: _greenDark),
          const SizedBox(width: 9),
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: _textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// CANCEL SHEET
// =============================================================

class _CancelSheet extends StatelessWidget {
  const _CancelSheet({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE5E2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 21),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hủy lịch xem phòng?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn muốn hủy lịch ${appointment.timeSlot} ngày ${_date(appointment.bookingDate)}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Giữ lịch'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Hủy lịch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// RESCHEDULE
// =============================================================

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.initialDate,
    required this.initialSlot,
    required this.slots,
  });

  final DateTime initialDate;
  final String initialSlot;
  final List<String> slots;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date;
  late String _slot;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _slot = widget.initialSlot;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE5E2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Đổi lịch xem phòng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Chọn ngày và khung giờ mới phù hợp với bạn.',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: _greenDark),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${_weekdayLong(_date)}, ${_dateLabel(_date)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Khung giờ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: widget.slots.map((slot) {
              final selected = slot == _slot;

              return ChoiceChip(
                label: Text(slot),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _slot = slot;
                  });
                },
                selectedColor: _green,
                backgroundColor: const Color(0xFFF7F9F8),
                side: BorderSide(color: selected ? _green : _border),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, (_date, _slot)),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu lịch mới'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Chọn ngày xem phòng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }
}

// =============================================================
// STATES
// =============================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.hasAppointments,
    required this.selectedStatus,
    required this.onShowAll,
  });

  final bool hasAppointments;
  final String? selectedStatus;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                size: 40,
                color: _greenDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasAppointments
                  ? 'Không có lịch ở trạng thái này'
                  : 'Bạn chưa có lịch xem phòng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasAppointments
                  ? 'Hãy chọn trạng thái khác để xem các lịch hẹn còn lại.'
                  : 'Sau khi đặt lịch xem phòng, bạn có thể theo dõi trạng thái tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
            if (hasAppointments && selectedStatus != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onShowAll, child: const Text('Xem tất cả')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được lịch hẹn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _textSecondary),
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 11),
      itemBuilder: (_, _) => const _Skeleton(),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFED),
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(150, 14),
                const SizedBox(height: 8),
                _line(100, 12),
                const SizedBox(height: 14),
                _line(125, 10),
                const SizedBox(height: 8),
                _line(95, 10),
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
        color: const Color(0xFFE9EFED),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// =============================================================
// HELPERS
// =============================================================

Appointment? _findNearestUpcoming(List<Appointment> items) {
  final now = DateTime.now();

  final candidates =
      items
          .where(
            (item) =>
                item.status != 'CANCELLED' &&
                item.status != 'COMPLETED' &&
                !item.bookingDate.isBefore(
                  DateTime(now.year, now.month, now.day),
                ),
          )
          .toList()
        ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

  return candidates.isEmpty ? null : candidates.first;
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}

String _dateLabel(DateTime value) => _date(value);

String _weekdayLong(DateTime value) {
  return switch (value.weekday) {
    DateTime.monday => 'Thứ 2',
    DateTime.tuesday => 'Thứ 3',
    DateTime.wednesday => 'Thứ 4',
    DateTime.thursday => 'Thứ 5',
    DateTime.friday => 'Thứ 6',
    DateTime.saturday => 'Thứ 7',
    DateTime.sunday => 'Chủ nhật',
    _ => '',
  };
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('AppointmentFailure: ', '');
}
