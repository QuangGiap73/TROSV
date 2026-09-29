import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_provider.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF6F9F8);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF667773);
const _border = Color(0xFFE2EAE8);

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({required this.appointment, super.key});

  final Appointment appointment;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late Appointment _appointment;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(appointmentActionProvider);
    final busy = actionState.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.pop(_changed);
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'Chi tiết lịch hẹn',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          actions: [
            PopupMenuButton<_MenuAction>(
              tooltip: 'Tùy chọn',
              onSelected: (value) {
                switch (value) {
                  case _MenuAction.copyId:
                    Clipboard.setData(ClipboardData(text: _appointment.id));
                    _message('Đã sao chép mã lịch hẹn.');
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.copyId,
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 19),
                      SizedBox(width: 9),
                      Text('Sao chép mã lịch'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: busy
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3),
                  child: LinearProgressIndicator(minHeight: 3, color: _green),
                )
              : null,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 148),
          children: [
            _StatusBanner(appointment: _appointment),
            const SizedBox(height: 13),

            _RoomSection(appointment: _appointment),
            const SizedBox(height: 13),

            _ScheduleSection(appointment: _appointment),
            const SizedBox(height: 13),

            _LandlordSection(
              appointment: _appointment,
              onContact: _showContact,
            ),
          ],
        ),
        bottomNavigationBar: _BottomActions(
          disabled: busy,
          canChange: _appointment.canTenantChange,
          onReschedule: _reschedule,
          onCancel: _cancel,
          onContact: _showContact,
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelSheet(appointment: _appointment),
    );

    if (accepted != true) return;

    final result = await ref
        .read(appointmentActionProvider.notifier)
        .cancel(_appointment.id);

    if (!mounted) return;

    if (result == null) {
      _message(_actionError(), error: true);
      return;
    }

    setState(() {
      _appointment = result;
      _changed = true;
    });

    _message('Đã hủy lịch xem phòng.');
  }

  Future<void> _reschedule() async {
    var selectedDate = _appointment.bookingDate;
    var selectedSlot = _appointment.timeSlot;

    const slots = <String>[
      '08:00 - 09:00',
      '09:00 - 10:00',
      '10:00 - 11:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
      '18:00 - 19:00',
    ];

    if (!slots.contains(selectedSlot)) {
      selectedSlot = slots.first;
    }

    final value = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _SheetHandle()),
                const SizedBox(height: 18),
                const Text(
                  'Đổi lịch xem phòng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Chọn ngày và khung giờ mới phù hợp với bạn.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 17),

                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate.isBefore(today)
                          ? today
                          : selectedDate,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 90)),
                      helpText: 'Chọn ngày xem phòng',
                      cancelText: 'Hủy',
                      confirmText: 'Chọn',
                    );

                    if (picked != null) {
                      updateSheet(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFFE4F7F1),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            color: _greenDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày xem phòng',
                                style: TextStyle(fontSize: 10.5, color: _muted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_weekday(selectedDate)}, ${_date(selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _muted),
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
                    color: _text,
                  ),
                ),
                const SizedBox(height: 9),

                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: slots.map((slot) {
                    final selected = slot == selectedSlot;

                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: _green,
                      backgroundColor: const Color(0xFFF7F9F8),
                      side: BorderSide(color: selected ? _green : _border),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _text,
                      ),
                      onSelected: (_) {
                        updateSheet(() {
                          selectedSlot = slot;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext, (selectedDate, selectedSlot));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Xác nhận đổi lịch',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (value == null) return;

    final result = await ref
        .read(appointmentActionProvider.notifier)
        .reschedule(_appointment.id, bookingDate: value.$1, timeSlot: value.$2);

    if (!mounted) return;

    if (result == null) {
      _message(_actionError(), error: true);
      return;
    }

    setState(() {
      _appointment = result;
      _changed = true;
    });

    _message('Đã cập nhật lịch xem phòng.');
  }

  void _showContact() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 18),
            const Text(
              'Liên hệ chủ trọ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Chạm vào thông tin để sao chép.',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 14),

            if (_appointment.landlordPhone?.trim().isNotEmpty == true)
              _ContactTile(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: _appointment.landlordPhone!,
                onTap: () =>
                    _copyContact(sheetContext, _appointment.landlordPhone!),
              ),

            if (_appointment.landlordZalo?.trim().isNotEmpty == true)
              _ContactTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Zalo',
                value: _appointment.landlordZalo!,
                onTap: () =>
                    _copyContact(sheetContext, _appointment.landlordZalo!),
              ),

            if (_appointment.landlordPhone?.trim().isNotEmpty != true &&
                _appointment.landlordZalo?.trim().isNotEmpty != true)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Chủ trọ chưa cập nhật thông tin liên hệ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyContact(BuildContext sheetContext, String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!sheetContext.mounted) return;

    Navigator.pop(sheetContext);

    _message('Đã sao chép $value.');
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
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }
}

// =============================================================
// STATUS
// =============================================================

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(appointment.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: config.foreground.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: config.foreground.withValues(alpha: 0.12),
            child: Icon(config.icon, color: config.foreground, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: config.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _muted,
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

typedef _StatusData = ({
  String label,
  String message,
  Color foreground,
  Color background,
  IconData icon,
});

_StatusData _statusConfig(String status) {
  return switch (status) {
    'CONFIRMED' => (
      label: 'Đã xác nhận',
      message: 'Chủ trọ đã xác nhận lịch hẹn của bạn.',
      foreground: _greenDark,
      background: const Color(0xFFE2F7F1),
      icon: Icons.check_circle_rounded,
    ),
    'PENDING' => (
      label: 'Chờ xác nhận',
      message: 'Yêu cầu đang chờ chủ trọ phản hồi.',
      foreground: const Color(0xFFC77900),
      background: const Color(0xFFFFF2DA),
      icon: Icons.schedule_rounded,
    ),
    'COMPLETED' => (
      label: 'Đã hoàn thành',
      message: 'Lịch xem phòng đã hoàn thành.',
      foreground: const Color(0xFF3478C8),
      background: const Color(0xFFEAF3FF),
      icon: Icons.task_alt_rounded,
    ),
    'CANCELLED' => (
      label: 'Đã hủy',
      message: 'Lịch xem phòng này đã được hủy.',
      foreground: const Color(0xFFD84B4B),
      background: const Color(0xFFFFEAEA),
      icon: Icons.cancel_rounded,
    ),
    _ => (
      label: status,
      message: 'Trạng thái lịch hẹn.',
      foreground: Colors.grey,
      background: const Color(0xFFF0F2F1),
      icon: Icons.info_outline_rounded,
    ),
  };
}

// =============================================================
// ROOM
// =============================================================

class _RoomSection extends StatelessWidget {
  const _RoomSection({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Thông tin phòng',
      child: InkWell(
        onTap: () => context.push('/rooms/${appointment.roomId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 92,
                  height: 82,
                  child:
                      appointment.roomImage == null ||
                          appointment.roomImage!.trim().isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE8F3F0),
                          child: Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFF7CA299),
                            size: 31,
                          ),
                        )
                      : Image.network(
                          appointment.roomImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE8F3F0),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF7CA299),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.roomTitle ?? 'Phòng trọ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    if (appointment.roomPrice != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${formatVnd(appointment.roomPrice!)}/tháng',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: _greenDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: _greenDark,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Xem chi tiết phòng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _greenDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SCHEDULE
// =============================================================

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final note = appointment.note?.trim();

    return _SectionCard(
      title: 'Thông tin lịch hẹn',
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày xem phòng',
            value:
                '${_weekday(appointment.bookingDate)}, ${_date(appointment.bookingDate)}',
          ),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'Khung giờ',
            value: appointment.timeSlot,
          ),
          _DetailRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Ghi chú của bạn',
            value: note == null || note.isEmpty ? 'Không có ghi chú.' : note,
            multiline: true,
            last: true,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// LANDLORD
// =============================================================

class _LandlordSection extends StatelessWidget {
  const _LandlordSection({required this.appointment, required this.onContact});

  final Appointment appointment;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final hasPhone = appointment.landlordPhone?.trim().isNotEmpty == true;
    final hasZalo = appointment.landlordZalo?.trim().isNotEmpty == true;

    return _SectionCard(
      title: 'Thông tin chủ trọ',
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFDFF4EE),
                child: Text(
                  _initial(appointment.landlordName),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _greenDark,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.landlordName ?? 'Chủ trọ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Chủ trọ',
                      style: TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasPhone || hasZalo) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                if (hasPhone)
                  Expanded(
                    child: _ContactButton(
                      icon: Icons.phone_outlined,
                      label: appointment.landlordPhone!,
                      onTap: onContact,
                    ),
                  ),
                if (hasPhone && hasZalo) const SizedBox(width: 8),
                if (hasZalo)
                  Expanded(
                    child: _ContactButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat Zalo',
                      outlined: true,
                      zalo: true,
                      onTap: onContact,
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

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.zalo = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool zalo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.white : const Color(0xFFE5F7F2),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: outlined
                  ? const Color(0xFFB9E1D7)
                  : const Color(0xFFD2ECE5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (zalo)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1677FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(icon, size: 18, color: _greenDark),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: zalo ? const Color(0xFF1677FF) : _greenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SECTION / ROW
// =============================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF1EF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF536A64)),
          const SizedBox(width: 9),
          SizedBox(
            width: 103,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: multiline ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// BOTTOM ACTIONS
// =============================================================

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.disabled,
    required this.canChange,
    required this.onReschedule,
    required this.onCancel,
    required this.onContact,
  });

  final bool disabled;
  final bool canChange;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                'Hành động',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_calendar_outlined,
                    label: 'Đổi lịch',
                    foreground: const Color(0xFF4F625D),
                    background: const Color(0xFFF5F7F6),
                    border: const Color(0xFFD7E1DE),
                    onTap: disabled || !canChange ? null : onReschedule,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Hủy lịch',
                    foreground: Colors.redAccent,
                    background: const Color(0xFFFFEEEE),
                    border: const Color(0xFFFFBFC2),
                    onTap: disabled || !canChange ? null : onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Liên hệ',
                    foreground: _greenDark,
                    background: const Color(0xFFDDF6EF),
                    border: const Color(0xFFAEDFD3),
                    onTap: disabled ? null : onContact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: onTap == null ? Colors.grey : foreground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: onTap == null ? Colors.grey : foreground,
                ),
              ),
            ],
          ),
        ),
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
          const _SheetHandle(),
          const SizedBox(height: 20),
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
              size: 32,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hủy lịch xem phòng?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn có chắc muốn hủy lịch ${appointment.timeSlot} ngày ${_date(appointment.bookingDate)} không?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.45, color: _muted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Giữ lịch'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
// CONTACT SHEET
// =============================================================

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F7F1),
          child: Icon(icon, color: _greenDark),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value),
        trailing: const Icon(Icons.copy_rounded, size: 19),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFDDE5E2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// =============================================================
// HELPERS
// =============================================================

enum _MenuAction { copyId }

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}

String _weekday(DateTime value) {
  return const [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ][value.weekday - 1];
}

String _initial(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'C';
  }

  return text.substring(0, 1).toUpperCase();
}
