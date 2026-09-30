import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/create_roommate_post_request.dart';
import '../../domain/models/roommate_lifestyle_traits.dart';
import '../providers/roommate_provider.dart';

class CreateRoommatePostScreen extends ConsumerStatefulWidget {
  const CreateRoommatePostScreen({super.key});

  @override
  ConsumerState<CreateRoommatePostScreen> createState() {
    return _CreateRoommatePostScreenState();
  }
}

class _CreateRoommatePostScreenState
    extends ConsumerState<CreateRoommatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _provinceController = TextEditingController(text: 'Hà Nội');
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _budgetController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _depositController = TextEditingController();
  final _universityController = TextEditingController();

  String _postType = 'FIND_ROOM_TOGETHER';
  String _authorGender = 'ANY';
  String _genderPreference = 'ANY';
  String _contactPreference = 'BOTH';
  String _curfew = '22:00';
  String _cleanliness = 'Gọn gàng';
  bool _smoking = false;
  bool _cooking = true;
  bool _pets = false;
  bool _guests = false;

  int _currentMembers = 1;
  int _desiredRoommates = 1;

  DateTime _moveInDate = DateTime.now().add(const Duration(days: 7));

  final Set<String> _lifestyleTags = {};

  static const _availableTags = [
    'Yên tĩnh',
    'Đi học/đi làm đúng giờ',
    'Thân thiện',
    'Tôn trọng riêng tư',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    _totalPriceController.dispose();
    _depositController.dispose();
    _universityController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(roommatePostActionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Đăng tin ở ghép',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          children: [
            const _SectionTitle(title: 'Bạn đang muốn gì?'),
            _PostTypeOption(
              title: 'Tìm người cùng tìm phòng',
              subtitle: 'Chưa có phòng, muốn tìm bạn cùng thuê.',
              icon: Icons.groups_outlined,
              selected: _postType == 'FIND_ROOM_TOGETHER',
              onTap: () {
                setState(() {
                  _postType = 'FIND_ROOM_TOGETHER';
                });
              },
            ),
            const SizedBox(height: 10),
            _PostTypeOption(
              title: 'Đã có phòng, tìm người ở ghép',
              subtitle: 'Đã có phòng và cần tìm thêm người.',
              icon: Icons.home_outlined,
              selected: _postType == 'HAVE_ROOM',
              onTap: () {
                setState(() {
                  _postType = 'HAVE_ROOM';
                });
              },
            ),
            const SizedBox(height: 22),

            const _SectionTitle(title: 'Nội dung bài đăng'),
            TextFormField(
              controller: _titleController,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề *',
                hintText: 'Ví dụ: Tìm một bạn nữ ở ghép gần Phenikaa',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 10) {
                  return 'Tiêu đề phải có ít nhất 10 ký tự.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              maxLength: 3000,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết *',
                hintText:
                    'Mô tả phòng, môi trường sống và người bạn muốn tìm...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 20) {
                  return 'Mô tả phải có ít nhất 20 ký tự.';
                }

                return null;
              },
            ),
            const SizedBox(height: 22),

            const _SectionTitle(title: 'Khu vực và ngân sách'),
            TextFormField(
              controller: _provinceController,
              decoration: const InputDecoration(
                labelText: 'Tỉnh/Thành phố *',
                border: OutlineInputBorder(),
              ),
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'Quận/Huyện *',
                hintText: 'Ví dụ: Hà Đông',
                border: OutlineInputBorder(),
              ),
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wardController,
              decoration: const InputDecoration(
                labelText: 'Phường/Xã',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ gợi ý',
                hintText: 'Ví dụ: Gần Đại học Phenikaa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách mỗi người/tháng *',
                suffixText: 'VNĐ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = _parseMoney(value);

                if (amount == null || amount < 300000) {
                  return 'Ngân sách tối thiểu là 300.000đ.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tổng giá phòng',
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tiền cọc/người',
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            const _SectionTitle(title: 'Người ở ghép mong muốn'),
            Row(
              children: [
                Expanded(
                  child: _CounterField(
                    label: 'Hiện có',
                    value: _currentMembers,
                    maximum: 10,
                    onChanged: (value) {
                      setState(() {
                        _currentMembers = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CounterField(
                    label: 'Cần tìm thêm',
                    value: _desiredRoommates,
                    maximum: 6,
                    onChanged: (value) {
                      setState(() {
                        _desiredRoommates = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _authorGender,
              decoration: const InputDecoration(
                labelText: 'Giới tính của bạn',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ANY',
                  child: Text('Không muốn cung cấp'),
                ),
                DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
              ],
              onChanged: (value) {
                setState(() {
                  _authorGender = value ?? 'ANY';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _genderPreference,
              decoration: const InputDecoration(
                labelText: 'Giới tính mong muốn',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ANY', child: Text('Không yêu cầu')),
                DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
              ],
              onChanged: (value) {
                setState(() {
                  _genderPreference = value ?? 'ANY';
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(
                labelText: 'Trường/Nơi làm việc',
                hintText: 'Ví dụ: Đại học Phenikaa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày muốn chuyển vào'),
              subtitle: Text(_formatDate(_moveInDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _selectMoveInDate,
            ),
            const SizedBox(height: 16),

            const _SectionTitle(title: 'Thói quen sinh hoạt'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final selected = _lifestyleTags.contains(tag);

                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFDDF5EF),
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _lifestyleTags.remove(tag);
                      } else {
                        _lifestyleTags.add(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _LifestyleCard(
              curfew: _curfew,
              cleanliness: _cleanliness,
              smoking: _smoking,
              cooking: _cooking,
              pets: _pets,
              guests: _guests,
              onPickCurfew: _selectCurfew,
              onCleanlinessChanged: (value) {
                setState(() => _cleanliness = value);
              },
              onSmokingChanged: (value) {
                setState(() => _smoking = value);
              },
              onCookingChanged: (value) {
                setState(() => _cooking = value);
              },
              onPetsChanged: (value) {
                setState(() => _pets = value);
              },
              onGuestsChanged: (value) {
                setState(() => _guests = value);
              },
            ),
            const SizedBox(height: 22),

            const _SectionTitle(title: 'Phương thức liên hệ'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'PHONE', label: Text('Điện thoại')),
                ButtonSegment(value: 'ZALO', label: Text('Zalo')),
                ButtonSegment(value: 'BOTH', label: Text('Cả hai')),
              ],
              selected: {_contactPreference},
              showSelectedIcon: false,
              onSelectionChanged: (values) {
                setState(() {
                  _contactPreference = values.first;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE1EAE7))),
          ),
          child: FilledButton.icon(
            onPressed: action.isLoading ? null : _submit,
            icon: action.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(action.isLoading ? 'Đang gửi bài...' : 'Đăng tin'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF009B7D),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectMoveInDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() {
        _moveInDate = result;
      });
    }
  }

  Future<void> _selectCurfew() async {
    final parts = _curfew.split(':');
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 22,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      ),
    );
    if (result == null) return;
    setState(() {
      _curfew =
          '${result.hour.toString().padLeft(2, '0')}:'
          '${result.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final traits = RoommateLifestyleTraits(
      curfew: _curfew,
      smoking: _smoking,
      cooking: _cooking,
      pets: _pets,
      guests: _guests,
      cleanliness: _cleanliness,
    );

    final request = CreateRoommatePostRequest(
      postType: _postType,
      title: _titleController.text,
      description: _descriptionController.text,
      province: _provinceController.text,
      district: _districtController.text,
      ward: _wardController.text,
      addressHint: _addressController.text,
      budgetPerPerson: _parseMoney(_budgetController.text)!,
      totalRoomPrice: _parseMoney(_totalPriceController.text),
      depositPerPerson: _parseMoney(_depositController.text),
      moveInDate: _moveInDate,
      desiredRoommates: _desiredRoommates,
      currentMembers: _currentMembers,
      authorGender: _authorGender,
      genderPreference: _genderPreference,
      contactPreference: _contactPreference,
      universityOrWork: _universityController.text,
      lifestyleTags: traits.buildTags(_lifestyleTags),
      lifestyleTraits: traits,
      mediaUrls: const [],
    );

    final result = await ref
        .read(roommatePostActionProvider.notifier)
        .createPost(request);

    if (!mounted) return;

    if (result == null) {
      final error = ref.read(roommatePostActionProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Không thể đăng bài.')),
      );

      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: Color(0xFF009B7D),
          ),
          title: const Text('Đã gửi bài thành công'),
          content: const Text(
            'Bài viết đang được kiểm duyệt. '
            'Bạn có thể theo dõi trạng thái trong Tin của tôi.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Xem tin của tôi'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    context.go('/roommate/mine');
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PostTypeOption extends StatelessWidget {
  const _PostTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F7F2) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF009B7D) : const Color(0xFFDCE7E4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 31, color: const Color(0xFF009B7D)),
            const SizedBox(width: 13),
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
                      color: Color(0xFF687571),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF009B7D)),
          ],
        ),
      ),
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({
    required this.curfew,
    required this.cleanliness,
    required this.smoking,
    required this.cooking,
    required this.pets,
    required this.guests,
    required this.onPickCurfew,
    required this.onCleanlinessChanged,
    required this.onSmokingChanged,
    required this.onCookingChanged,
    required this.onPetsChanged,
    required this.onGuestsChanged,
  });

  final String curfew;
  final String cleanliness;
  final bool smoking;
  final bool cooking;
  final bool pets;
  final bool guests;
  final VoidCallback onPickCurfew;
  final ValueChanged<String> onCleanlinessChanged;
  final ValueChanged<bool> onSmokingChanged;
  final ValueChanged<bool> onCookingChanged;
  final ValueChanged<bool> onPetsChanged;
  final ValueChanged<bool> onGuestsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _LifestyleRow(
            icon: Icons.schedule_rounded,
            title: 'Giờ về dự kiến',
            description: 'Chọn giờ sinh hoạt thường ngày',
            control: _ValueButton(text: curfew, onTap: onPickCurfew),
          ),
          const Divider(height: 1),
          _LifestyleRow(
            icon: Icons.cleaning_services_outlined,
            title: 'Mức độ sạch sẽ',
            description: 'Không gian sống của bạn thường như thế nào?',
            control: _ValueButton(
              text: cleanliness,
              onTap: () => _pickCleanliness(context),
            ),
          ),
          const Divider(height: 1),
          _LifestyleRow(
            icon: Icons.smoking_rooms_outlined,
            title: 'Hút thuốc',
            description: 'Bạn có hút thuốc không?',
            control: _TwoChoiceButton(
              value: smoking,
              falseLabel: 'Không',
              trueLabel: 'Có',
              onChanged: onSmokingChanged,
            ),
          ),
          const Divider(height: 1),
          _LifestyleRow(
            icon: Icons.soup_kitchen_outlined,
            title: 'Nấu ăn',
            description: 'Bạn thường nấu ăn ở nhà với tần suất như thế nào?',
            control: _TwoChoiceButton(
              value: cooking,
              falseLabel: 'Ít',
              trueLabel: 'Thường',
              onChanged: onCookingChanged,
            ),
          ),
          const Divider(height: 1),
          _LifestyleRow(
            icon: Icons.pets_outlined,
            title: 'Nuôi thú cưng',
            description: 'Bạn có nuôi thú cưng không?',
            control: _TwoChoiceButton(
              value: pets,
              falseLabel: 'Không',
              trueLabel: 'Có',
              onChanged: onPetsChanged,
            ),
          ),
          const Divider(height: 1),
          _LifestyleRow(
            icon: Icons.groups_outlined,
            title: 'Bạn bè đến chơi',
            description: 'Bạn có thoải mái khi bạn bè đến chơi không?',
            control: _TwoChoiceButton(
              value: guests,
              falseLabel: 'Hạn chế',
              trueLabel: 'Thoải mái',
              onChanged: onGuestsChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCleanliness(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mức độ sạch sẽ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            for (final option in const [
              'Rất gọn gàng',
              'Gọn gàng',
              'Bình thường',
              'Thoải mái',
            ])
              ListTile(
                title: Text(option),
                trailing: option == cleanliness
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF008F79),
                      )
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (result != null) onCleanlinessChanged(result);
  }
}

class _LifestyleRow extends StatelessWidget {
  const _LifestyleRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.control,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F7F4),
            ),
            child: Icon(icon, color: const Color(0xFF007F70), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17211F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: Color(0xFF87938F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          control,
        ],
      ),
    );
  }
}

class _ValueButton extends StatelessWidget {
  const _ValueButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        constraints: const BoxConstraints(minWidth: 105),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFDDE7E4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF087D6E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF087D6E),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoChoiceButton extends StatelessWidget {
  const _TwoChoiceButton({
    required this.value,
    required this.falseLabel,
    required this.trueLabel,
    required this.onChanged,
  });

  final bool value;
  final String falseLabel;
  final String trueLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 43,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChoicePart(
              label: falseLabel,
              selected: !value,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ChoicePart(
              label: trueLabel,
              selected: value,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicePart extends StatelessWidget {
  const _ChoicePart({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF008F79) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : const Color(0xFF43514E),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.maximum,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maximum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7E4)),
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
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: value < maximum ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập thông tin này.';
  }

  return null;
}

int? _parseMoney(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');

  return int.tryParse(normalized);
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
