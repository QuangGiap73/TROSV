import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/room_report.dart';
import '../../providers/room_report_provider.dart';

const _reportGreen = Color(0xFF009B7D);

Future<RoomReport?> showRoomReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String roomId,
  required String roomTitle,
}) {
  ref.read(roomReportControllerProvider.notifier).clear();
  return showModalBottomSheet<RoomReport>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoomReportSheet(roomId: roomId, roomTitle: roomTitle),
  );
}

class _RoomReportSheet extends ConsumerStatefulWidget {
  const _RoomReportSheet({required this.roomId, required this.roomTitle});

  final String roomId;
  final String roomTitle;

  @override
  ConsumerState<_RoomReportSheet> createState() => _RoomReportSheetState();
}

class _RoomReportSheetState extends ConsumerState<_RoomReportSheet> {
  final _descriptionController = TextEditingController();
  RoomReportType? _selectedType;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = _selectedType;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một lý do báo cáo.')),
      );
      return;
    }
    if (selected == RoomReportType.other &&
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng mô tả lý do báo cáo.')),
      );
      return;
    }

    final report = await ref
        .read(roomReportControllerProvider.notifier)
        .submit(
          roomId: widget.roomId,
          type: selected,
          description: _descriptionController.text,
        );
    if (!mounted) return;
    if (report != null) {
      Navigator.pop(context, report);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể gửi báo cáo. Vui lòng thử lại sau.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomReportControllerProvider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4DEDB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Báo cáo phòng này',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: state.isLoading
                      ? null
                      : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      widget.roomTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF176A5C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vấn đề bạn gặp phải',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  ...RoomReportType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ReasonTile(
                        type: type,
                        selected: _selectedType == type,
                        onTap: state.isLoading
                            ? null
                            : () => setState(() => _selectedType = type),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mô tả thêm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    enabled: !state.isLoading,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText:
                          'Hãy cung cấp thông tin cụ thể để chúng tôi kiểm tra nhanh hơn...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _reportGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _reportGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.outlined_flag_rounded),
                      label: Text(
                        state.isLoading ? 'Đang gửi...' : 'Gửi báo cáo',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Thông tin báo cáo của bạn sẽ được bảo mật.',
                      style: TextStyle(color: Color(0xFF75827F), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final RoomReportType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE5F7F2) : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _reportGreen : const Color(0xFFDDE7E4),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(type),
              color: selected ? _reportGreen : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF24302E),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _reportGreen : Colors.transparent,
                border: Border.all(
                  color: selected ? _reportGreen : const Color(0xFFADB9B6),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ),
  );

  static IconData _iconFor(RoomReportType type) => switch (type) {
    RoomReportType.roomNotExist => Icons.home_work_outlined,
    RoomReportType.wrongPrice => Icons.payments_outlined,
    RoomReportType.wrongPhotos => Icons.image_not_supported_outlined,
    RoomReportType.rented => Icons.key_off_outlined,
    RoomReportType.wrongLocation => Icons.wrong_location_outlined,
    RoomReportType.hiddenFee => Icons.receipt_long_outlined,
    RoomReportType.fraud => Icons.gpp_bad_outlined,
    RoomReportType.other => Icons.more_horiz_rounded,
  };
}
