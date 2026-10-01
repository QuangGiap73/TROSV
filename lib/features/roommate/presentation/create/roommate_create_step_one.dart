import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/roommate_create_provider.dart';
import 'widgets/roommate_create_bottom_bar.dart';

class RoommateCreateStepOne extends ConsumerWidget {
  const RoommateCreateStepOne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(roommateCreateDraftProvider);
    final controller = ref.read(roommateCreateDraftProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Heading(
                title: 'Bạn đang muốn gì?',
                subtitle: 'Bước 1/3: Nhu cầu và thông tin người đăng',
              ),
              const SizedBox(height: 18),
              _ChoiceCard(
                selected: draft.postType == 'HAVE_ROOM',
                icon: Icons.home_rounded,
                title: 'Đã có phòng, tìm người ở cùng',
                subtitle: 'Đã có chỗ ở, cần thêm người ở ghép',
                onTap: () =>
                    controller.update(draft.copyWith(postType: 'HAVE_ROOM')),
              ),
              const SizedBox(height: 10),
              _ChoiceCard(
                selected: draft.postType == 'FIND_ROOM_TOGETHER',
                icon: Icons.groups_rounded,
                title: 'Tìm người cùng tìm phòng',
                subtitle: 'Chưa có phòng, muốn cùng nhau tìm phòng',
                onTap: () => controller.update(
                  draft.copyWith(postType: 'FIND_ROOM_TOGETHER'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thông tin người đăng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _DropdownField(
                label: 'Giới tính của bạn',
                value: draft.authorGender,
                items: const {
                  'ANY': 'Khác/Không muốn nói',
                  'MALE': 'Nam',
                  'FEMALE': 'Nữ',
                },
                onChanged: (value) =>
                    controller.update(draft.copyWith(authorGender: value)),
              ),
              const SizedBox(height: 12),
              _DropdownField(
                label: 'Ưu tiên giới tính',
                value: draft.genderPreference,
                items: const {'ANY': 'Tất cả', 'MALE': 'Nam', 'FEMALE': 'Nữ'},
                onChanged: (value) =>
                    controller.update(draft.copyWith(genderPreference: value)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Counter(
                      label: 'Số người hiện có',
                      value: draft.currentMembers,
                      max: 10,
                      onChanged: (value) => controller.update(
                        draft.copyWith(currentMembers: value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Counter(
                      label: 'Cần thêm',
                      value: draft.desiredRoommates,
                      max: 6,
                      onChanged: (value) => controller.update(
                        draft.copyWith(desiredRoommates: value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DropdownField(
                label: 'Phương thức liên hệ',
                value: draft.contactPreference,
                items: const {
                  'PHONE': 'Điện thoại',
                  'ZALO': 'Zalo',
                  'BOTH': 'Cả hai',
                },
                onChanged: (value) =>
                    controller.update(draft.copyWith(contactPreference: value)),
              ),
            ],
          ),
        ),
        RoommateCreateBottomBar(
          primaryLabel: 'Tiếp tục',
          onPrimary: controller.nextStep,
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Color(0xFF71807C))),
    ],
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE7F8F3) : Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF00A889) : const Color(0xFFDCE6E3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF009B7D), size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71807C),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF00A889)),
          ],
        ),
      ),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    items: items.entries
        .map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE6E3)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF687571)),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    ),
  );
}
