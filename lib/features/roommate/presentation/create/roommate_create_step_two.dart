import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';

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
  Province? _selectedProvince;
  District? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    final value = ref.read(roommateCreateDraftProvider);
    _province = TextEditingController(text: value.province);
    _district = TextEditingController(text: value.district);
    _ward = TextEditingController(text: value.ward);
    _address = TextEditingController(text: value.addressHint);
    _budget = TextEditingController(text: _initialMoney(value.budgetPerPerson));
    _total = TextEditingController(text: _initialMoney(value.totalRoomPrice));
    _deposit = TextEditingController(
      text: _initialMoney(value.depositPerPerson),
    );
    _university = TextEditingController(text: value.universityOrWork);
    _restoreAdministrativeSelection();
  }

  void _restoreAdministrativeSelection() {
    _selectedProvince = _findByName(
      VietnamProvinces.getProvinces(),
      value: _province.text,
      nameOf: (item) => item.name,
    );
    if (_selectedProvince == null) return;

    _selectedDistrict = _findByName(
      VietnamProvinces.getDistricts(provinceCode: _selectedProvince!.code),
      value: _district.text,
      nameOf: (item) => item.name,
    );
    if (_selectedDistrict == null) return;

    final savedWard = _findByName(
      VietnamProvinces.getWards(
        provinceCode: _selectedProvince!.code,
        districtCode: _selectedDistrict!.code,
      ),
      value: _ward.text,
      nameOf: (item) => item.name,
    );
    if (savedWard != null) _ward.text = savedWard.name;
  }

  T? _findByName<T>(
    List<T> items, {
    required String value,
    required String Function(T item) nameOf,
  }) {
    final target = _administrativeName(value);
    for (final item in items) {
      if (_administrativeName(nameOf(item)) == target) return item;
    }
    return null;
  }

  String _administrativeName(String value) => value
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^(thành phố|tỉnh|quận|huyện|thị xã)\s+'), '');

  String _initialMoney(int value) => value == 0 ? '' : _formatMoney(value);

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

  Future<void> _pickProvince() async {
    final selected = await _showAdministrativePicker<Province>(
      title: 'Chọn tỉnh/thành phố',
      items: VietnamProvinces.getProvinces(),
      nameOf: (item) => item.name,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedProvince = selected;
      _selectedDistrict = null;
      _province.text = selected.name;
      _district.clear();
      _ward.clear();
    });
  }

  Future<void> _pickDistrict() async {
    final province = _selectedProvince;
    if (province == null) return;
    final selected = await _showAdministrativePicker<District>(
      title: 'Chọn quận/huyện',
      items: VietnamProvinces.getDistricts(provinceCode: province.code),
      nameOf: (item) => item.name,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDistrict = selected;
      _district.text = selected.name;
      _ward.clear();
    });
  }

  Future<void> _pickWard() async {
    final province = _selectedProvince;
    final district = _selectedDistrict;
    if (province == null || district == null) return;
    final selected = await _showAdministrativePicker<Ward>(
      title: 'Chọn phường/xã',
      items: VietnamProvinces.getWards(
        provinceCode: province.code,
        districtCode: district.code,
      ),
      nameOf: (item) => item.name,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _ward.text = selected.name;
    });
  }

  Future<T?> _showAdministrativePicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) nameOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _AdministrativePicker<T>(title: title, items: items, nameOf: nameOf),
    );
  }

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
                _selectionField(
                  _province,
                  'Tỉnh/Thành phố',
                  'Chọn tỉnh/thành phố',
                  onTap: _pickProvince,
                  validator: _required,
                ),
                _selectionField(
                  _district,
                  'Quận/Huyện',
                  _selectedProvince == null
                      ? 'Chọn tỉnh/thành phố trước'
                      : 'Chọn quận/huyện',
                  onTap: _selectedProvince == null ? null : _pickDistrict,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Vui lòng chọn quận/huyện.'
                      : null,
                ),
                _selectionField(
                  _ward,
                  'Phường/Xã',
                  _selectedDistrict == null
                      ? 'Chọn quận/huyện trước'
                      : 'Chọn phường/xã',
                  onTap: _selectedDistrict == null ? null : _pickWard,
                  validator: _required,
                ),
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

  Widget _selectionField(
    TextEditingController controller,
    String label,
    String hint, {
    required VoidCallback? onTap,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: onTap == null
              ? const Color(0xFFB7C0BD)
              : const Color(0xFF00A887),
        ),
        filled: true,
        fillColor: onTap == null ? const Color(0xFFF3F6F5) : Colors.white,
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
      inputFormatters: const [_MoneyInputFormatter()],
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

class _AdministrativePicker<T> extends StatefulWidget {
  const _AdministrativePicker({
    required this.title,
    required this.items,
    required this.nameOf,
  });

  final String title;
  final List<T> items;
  final String Function(T item) nameOf;

  @override
  State<_AdministrativePicker<T>> createState() =>
      _AdministrativePickerState<T>();
}

class _AdministrativePickerState<T> extends State<_AdministrativePicker<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.items.where((item) {
      return widget.nameOf(item).toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5DDDA),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF3F7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Không tìm thấy khu vực phù hợp.'))
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(widget.nameOf(item)),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7B8A86),
                        ),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoneyInputFormatter extends TextInputFormatter {
  const _MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = digits.isEmpty ? '' : _formatMoney(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatMoney(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}
