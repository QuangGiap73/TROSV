import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/roommate_create_provider.dart';
import 'widgets/roommate_create_bottom_bar.dart';

class RoommateCreateStepTwo extends ConsumerStatefulWidget {
  const RoommateCreateStepTwo({super.key});
  @override
  ConsumerState<RoommateCreateStepTwo> createState() =>
      _RoommateCreateStepTwoState();
}

class _RoommateCreateStepTwoState extends ConsumerState<RoommateCreateStepTwo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _province;
  late final TextEditingController _district;
  late final TextEditingController _ward;
  late final TextEditingController _address;
  late final TextEditingController _budget;
  late final TextEditingController _total;
  late final TextEditingController _deposit;
  late final TextEditingController _university;

  @override
  void initState() {
    super.initState();
    final value = ref.read(roommateCreateDraftProvider);
    _province = TextEditingController(text: value.province);
    _district = TextEditingController(text: value.district);
    _ward = TextEditingController(text: value.ward);
    _address = TextEditingController(text: value.addressHint);
    _budget = TextEditingController(
      text: value.budgetPerPerson == 0 ? '' : '${value.budgetPerPerson}',
    );
    _total = TextEditingController(
      text: value.totalRoomPrice == 0 ? '' : '${value.totalRoomPrice}',
    );
    _deposit = TextEditingController(
      text: value.depositPerPerson == 0 ? '' : '${value.depositPerPerson}',
    );
    _university = TextEditingController(text: value.universityOrWork);
  }

  @override
  void dispose() {
    for (final controller in [
      _province,
      _district,
      _ward,
      _address,
      _budget,
      _total,
      _deposit,
      _university,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _money(TextEditingController controller) =>
      int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _save() {
    final current = ref.read(roommateCreateDraftProvider);
    ref
        .read(roommateCreateDraftProvider.notifier)
        .update(
          current.copyWith(
            province: _province.text.trim(),
            district: _district.text.trim(),
            ward: _ward.text.trim(),
            addressHint: _address.text.trim(),
            budgetPerPerson: _money(_budget),
            totalRoomPrice: _money(_total),
            depositPerPerson: _money(_deposit),
            universityOrWork: _university.text.trim(),
          ),
        );
  }

  void _next() {
    _save();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(roommateCreateDraftProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(roommateCreateDraftProvider);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Khu vực & ngân sách',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bước 2/3: Điền khu vực và chi phí dự kiến',
                  style: TextStyle(color: Color(0xFF71807C)),
                ),
                const SizedBox(height: 20),
                _field(
                  _province,
                  'Tỉnh/Thành phố',
                  'Ví dụ: Hà Nội',
                  validator: _required,
                ),
                _field(
                  _district,
                  'Quận/Huyện',
                  'Ví dụ: Hà Đông',
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Nhập tối thiểu 2 ký tự.'
                      : null,
                ),
                _field(_ward, 'Phường/Xã', 'Ví dụ: Yên Nghĩa'),
                _field(
                  _address,
                  'Địa chỉ gợi ý',
                  'Ví dụ: Ngõ 12 Nguyễn Văn Cừ',
                ),
                _field(
                  _university,
                  'Trường/Nơi làm việc',
                  'Ví dụ: Đại học Phenikaa',
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _moneyField(
                        _budget,
                        'Ngân sách/người',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _moneyField(_total, 'Tổng giá phòng')),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _moneyField(_deposit, 'Tiền cọc/người')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: draft.moveInDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (picked != null) {
                            ref
                                .read(roommateCreateDraftProvider.notifier)
                                .update(draft.copyWith(moveInDate: picked));
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày chuyển vào',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_date(draft.moveInDate)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          RoommateCreateBottomBar(
            primaryLabel: 'Tiếp tục',
            onBack: () {
              _save();
              ref.read(roommateCreateDraftProvider.notifier).previousStep();
            },
            onPrimary: _next,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  Widget _moneyField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: required
          ? (value) => _money(controller) < 300000 ? 'Tối thiểu 300.000đ' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        suffixText: 'đ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Không được để trống.' : null;
  String _date(DateTime? date) => date == null
      ? 'Chọn ngày'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
