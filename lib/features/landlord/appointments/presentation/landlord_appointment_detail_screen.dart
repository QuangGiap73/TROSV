import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../appointments/presentation/widgets/appointment_card.dart';

const _green = Color(0xFF009B7D);

class LandlordAppointmentDetailScreen extends ConsumerStatefulWidget {
  const LandlordAppointmentDetailScreen({required this.appointment, super.key});
  final Appointment appointment;

  @override
  ConsumerState<LandlordAppointmentDetailScreen> createState() =>
      _LandlordAppointmentDetailScreenState();
}

class _LandlordAppointmentDetailScreenState
    extends ConsumerState<LandlordAppointmentDetailScreen> {
  late Appointment appointment = widget.appointment;

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(appointmentActionProvider).isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết lịch hẹn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _StatusBanner(status: appointment.status),
          const SizedBox(height: 12),
          _Section(
            title: 'Thông tin phòng',
            icon: Icons.home_work_outlined,
            child: AppointmentCard(
              appointment: appointment,
              landlordView: true,
              onTap: () =>
                  context.push('/landlord/rooms/${appointment.roomId}'),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Thông tin người đặt lịch',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Họ và tên',
                  value: appointment.tenantName,
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Điện thoại',
                  value: appointment.tenantPhone,
                  onTap: () => _copy(appointment.tenantPhone),
                ),
                if (appointment.tenantZalo?.isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Zalo',
                    value: appointment.tenantZalo!,
                    onTap: () => _copy(appointment.tenantZalo!),
                  ),
                if (appointment.tenantEmail?.isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: appointment.tenantEmail!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Thời gian xem phòng',
            icon: Icons.calendar_month_outlined,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày xem',
                  value: _formatDate(appointment.bookingDate),
                ),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Khung giờ',
                  value: appointment.timeSlot,
                ),
                if (appointment.note?.isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Lời nhắn',
                    value: appointment.note!,
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        status: appointment.status,
        busy: busy,
        onConfirm: () => _changeStatus('CONFIRMED'),
        onCancel: () => _changeStatus('CANCELLED', askReason: true),
        onComplete: () => _changeStatus('COMPLETED'),
      ),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép thông tin liên hệ.')),
      );
    }
  }

  Future<void> _changeStatus(String status, {bool askReason = false}) async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switch (status) {
          'CONFIRMED' => 'Xác nhận lịch hẹn?',
          'COMPLETED' => 'Đánh dấu đã hoàn thành?',
          _ => 'Từ chối lịch hẹn?',
        }),
        content: askReason
            ? TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lý do hoặc lời nhắn',
                  hintText: 'Ví dụ: Khung giờ này chủ nhà bận...',
                  border: OutlineInputBorder(),
                ),
              )
            : Text('Lịch của ${appointment.tenantName} sẽ được cập nhật.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (accepted != true) {
      controller.dispose();
      return;
    }
    final note = controller.text.trim();
    final result = await ref
        .read(appointmentActionProvider.notifier)
        .updateStatus(
          appointment.id,
          status: status,
          note: note.isEmpty ? null : note,
        );
    controller.dispose();
    if (!mounted) return;
    if (result == null) {
      final error = ref.read(appointmentActionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (error?.toString() ?? 'Không thể cập nhật lịch hẹn.').replaceFirst(
              'AppointmentFailure: ',
              '',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => appointment = result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'CONFIRMED'
              ? 'Đã xác nhận lịch hẹn.'
              : status == 'COMPLETED'
              ? 'Đã hoàn thành lịch hẹn.'
              : 'Đã hủy lịch hẹn.',
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      'CONFIRMED' => (
        Icons.verified_rounded,
        'Đã xác nhận',
        'Hãy chuẩn bị phòng và liên hệ người thuê khi cần.',
        _green,
      ),
      'COMPLETED' => (
        Icons.task_alt_rounded,
        'Đã hoàn thành',
        'Buổi xem phòng đã được hoàn tất.',
        const Color(0xFF2878C8),
      ),
      'CANCELLED' => (
        Icons.cancel_outlined,
        'Đã hủy',
        'Lịch hẹn này không còn hiệu lực.',
        const Color(0xFFE05252),
      ),
      _ => (
        Icons.hourglass_top_rounded,
        'Chờ chủ trọ xác nhận',
        'Kiểm tra thông tin trước khi duyệt lịch.',
        const Color(0xFFF59E0B),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.$4.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.$4.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(data.$1, color: data.$4, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.$2,
                  style: TextStyle(fontWeight: FontWeight.w800, color: data.$4),
                ),
                const SizedBox(height: 2),
                Text(
                  data.$3,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F706C),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE1ECE9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _green, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Divider(height: 22, color: Color(0xFFE8EFED)),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF66807A)),
          const SizedBox(width: 11),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF71817D), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onTap != null)
            const Icon(Icons.copy_rounded, size: 17, color: _green),
        ],
      ),
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.status,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });
  final String status;
  final bool busy;
  final VoidCallback onConfirm, onCancel, onComplete;
  @override
  Widget build(BuildContext context) {
    if (status == 'CANCELLED' || status == 'COMPLETED') {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE1ECE9))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Từ chối'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE05252),
                  side: const BorderSide(color: Color(0xFFE05252)),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy
                    ? null
                    : status == 'PENDING'
                    ? onConfirm
                    : onComplete,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        status == 'PENDING'
                            ? Icons.check_rounded
                            : Icons.task_alt_rounded,
                      ),
                label: Text(status == 'PENDING' ? 'Xác nhận' : 'Hoàn thành'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
