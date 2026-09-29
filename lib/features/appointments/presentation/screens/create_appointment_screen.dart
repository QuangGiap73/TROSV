import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/appointment_provider.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _greenSoft = Color(0xFFEAF8F4);
const _background = Color(0xFFF7FAF9);
const _border = Color(0xFFE1EAE7);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  const CreateAppointmentScreen({
    required this.roomId,
    this.roomTitle,
    super.key,
  });

  final String roomId;
  final String? roomTitle;

  @override
  ConsumerState<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState
    extends ConsumerState<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _zalo;
  late final TextEditingController _note;

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _slot;

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
  void initState() {
    super.initState();

    final user = ref.read(authControllerProvider).asData?.value?.user;

    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _zalo = TextEditingController(text: user?.zaloPhone ?? '');
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _zalo.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(appointmentActionProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Text(
          'Đặt lịch xem phòng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 116),
          children: [
            const _IntroCard(),

            const SizedBox(height: 14),

            _SectionCard(
              icon: Icons.calendar_month_rounded,
              title: 'Thời gian xem phòng',
              subtitle:
                  'Chọn ngày và khung giờ phù hợp để chủ trọ sắp xếp đón bạn.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DatePickerRow(
                    selectedDate: _date,
                    onDateSelected: (value) {
                      setState(() {
                        _date = value;
                      });
                    },
                    onPickOtherDate: _pickDate,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn khung giờ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TimeSlotGrid(
                    slots: _slots,
                    selected: _slot,
                    onSelected: (value) {
                      setState(() {
                        _slot = value;
                      });
                    },
                  ),
                  if (_slot == null) ...[
                    const SizedBox(height: 9),
                    const Text(
                      'Bạn cần chọn một khung giờ trước khi gửi yêu cầu.',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              icon: Icons.person_outline_rounded,
              title: 'Thông tin liên hệ',
              subtitle:
                  'Thông tin này giúp chủ trọ xác nhận và liên hệ với bạn.',
              child: Column(
                children: [
                  _field(
                    _name,
                    'Họ và tên',
                    Icons.person_outline_rounded,
                    required: true,
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Tên cần ít nhất 2 ký tự.'
                        : null,
                  ),
                  _field(
                    _phone,
                    'Số điện thoại',
                    Icons.phone_outlined,
                    required: true,
                    keyboardType: TextInputType.phone,
                    validator: _phoneError,
                  ),
                  _field(
                    _zalo,
                    'Số Zalo',
                    Icons.chat_bubble_outline_rounded,
                    hint: 'Không bắt buộc',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? null
                        : _phoneError(value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              icon: Icons.edit_note_rounded,
              title: 'Lời nhắn cho chủ trọ',
              subtitle:
                  'Bạn có thể ghi thêm nhu cầu hoặc điều cần trao đổi trước khi đến xem.',
              child: TextFormField(
                controller: _note,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                decoration: _inputDecoration(
                  label: 'Ghi chú',
                  hint:
                      'Ví dụ: Mình muốn xem phòng vào buổi chiều và hỏi thêm về phí dịch vụ.',
                  icon: Icons.notes_rounded,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _AppointmentSummary(date: _date, slot: _slot),

            if (action.hasError) ...[
              const SizedBox(height: 12),
              _InlineError(message: _errorText(action.error)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: action.isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: action.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.event_available_rounded),
            label: Text(
              action.isLoading ? 'Đang gửi yêu cầu...' : 'Xác nhận đặt lịch',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: _inputDecoration(
          label: required ? '$label *' : label,
          hint: hint,
          icon: icon,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final value = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Chọn ngày xem phòng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (value != null) {
      setState(() {
        _date = value;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_slot == null) {
      _message('Hãy chọn khung giờ xem phòng.');
      return;
    }

    final result = await ref
        .read(appointmentActionProvider.notifier)
        .create(
          roomId: widget.roomId,
          tenantName: _name.text.trim(),
          tenantPhone: _phone.text.trim(),
          tenantZalo: _zalo.text.trim(),
          bookingDate: _date,
          timeSlot: _slot!,
          note: _note.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _message(_errorText(ref.read(appointmentActionProvider).error));
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SuccessDialog(date: _date, slot: _slot!),
    );

    if (mounted) {
      context.pop(true);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F8F3), Color(0xFFF4FBF9)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD5EEE7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFCFF1E7),
            child: Icon(
              Icons.event_available_rounded,
              color: _greenDark,
              size: 23,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hẹn xem phòng trực tiếp',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chọn thời gian phù hợp. Sau khi gửi, lịch hẹn sẽ ở trạng thái chờ chủ trọ xác nhận.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: _textSecondary,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _greenSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _greenDark, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPickOtherDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPickOtherDate;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    final dates = List<DateTime>.generate(
      6,
      (index) => start.add(Duration(days: index + 1)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chọn ngày',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onPickOtherDate,
              style: TextButton.styleFrom(
                foregroundColor: _greenDark,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text(
                'Ngày khác',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = dates[index];
              final selected = _sameDay(selectedDate, date);

              return InkWell(
                onTap: () => onDateSelected(date),
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? _green : const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: selected ? _green : _border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekday(date),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: _greenDark,
            ),
            const SizedBox(width: 5),
            Text(
              'Ngày đã chọn: ${_formatDate(selectedDate)}',
              style: const TextStyle(fontSize: 11.5, color: _textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  const _TimeSlotGrid({
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = slot == selected;

        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (_) => onSelected(slot),
          showCheckmark: false,
          side: BorderSide(color: isSelected ? _green : _border),
          backgroundColor: const Color(0xFFF8FAF9),
          selectedColor: _green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : _textPrimary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        );
      }).toList(),
    );
  }
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({required this.date, required this.slot});

  final DateTime date;
  final String? slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF4E7BF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFFFFECC4),
            child: Icon(
              Icons.schedule_rounded,
              color: Color(0xFFD88900),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt lịch hẹn',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slot == null
                      ? '${_formatDate(date)} · Chưa chọn khung giờ'
                      : '${_formatDate(date)} · $slot',
                  style: const TextStyle(fontSize: 11.5, color: _textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lịch sẽ chuyển sang “Chờ xác nhận” sau khi gửi.',
                  style: TextStyle(fontSize: 10.5, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF9C4545)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.date, required this.slot});

  final DateTime date;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _greenSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle_rounded, color: _green, size: 42),
      ),
      title: const Text(
        'Đã gửi yêu cầu',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900, color: _textPrimary),
      ),
      content: Text(
        'Lịch xem phòng ngày ${_formatDate(date)}, $slot đang chờ chủ trọ xác nhận.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.45,
          color: _textSecondary,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          ),
          child: const Text('Đã hiểu'),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF667773), size: 20),
    filled: true,
    fillColor: const Color(0xFFFAFCFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _green, width: 1.4),
    ),
  );
}

String? _phoneError(String? value) {
  return RegExp(r'^(?:\+84|0)\d{9}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Số điện thoại không đúng định dạng.';
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekday(DateTime value) {
  return switch (value.weekday) {
    DateTime.monday => 'T2',
    DateTime.tuesday => 'T3',
    DateTime.wednesday => 'T4',
    DateTime.thursday => 'T5',
    DateTime.friday => 'T6',
    DateTime.saturday => 'T7',
    DateTime.sunday => 'CN',
    _ => '',
  };
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}

String _errorText(Object? error) {
  return error?.toString() ?? 'Không thể đặt lịch. Vui lòng thử lại.';
}
