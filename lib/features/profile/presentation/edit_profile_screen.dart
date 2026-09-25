import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const Color _primary = Color(0xFF00A98F);
  static const Color _primaryDark = Color(0xFF008E78);
  static const Color _navy = Color(0xFF14243B);
  static const Color _background = Color(0xFFF5F8F7);
  static const Color _muted = Color(0xFF7D8999);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _zaloController;
  late final TextEditingController _avatarController;

  Uint8List? _selectedImageBytes;
  bool _uploadingImage = false;
  bool _hydratedUser = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authControllerProvider).asData?.value?.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _zaloController = TextEditingController(text: user?.zaloPhone ?? '');
    _avatarController = TextEditingController(text: user?.avatarUrl ?? '');

    _hydratedUser = user != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zaloController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          zaloPhone: _zaloController.text.trim(),
          avatarUrl: _avatarController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Cập nhật thông tin thành công.')),
            ],
          ),
        ),
      );

      context.pop();
      return;
    }

    final error = ref.read(authControllerProvider).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(error?.toString() ?? 'Không thể cập nhật thông tin.'),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
        _uploadingImage = true;
      });

      final url = await ref
          .read(authControllerProvider.notifier)
          .uploadProfileImage(bytes: bytes, filename: image.name);

      if (!mounted) return;

      setState(() {
        _avatarController.text = url;
        _uploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Ảnh đã tải lên. Hãy bấm Lưu thay đổi.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _uploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể tải ảnh lên: $error'),
        ),
      );
    }
  }

  void _hydrateControllers({
    required String? name,
    required String? zaloPhone,
    required String? avatarUrl,
  }) {
    if (_hydratedUser) return;

    _nameController.text = name ?? '';
    _zaloController.text = zaloPhone ?? '';
    _avatarController.text = avatarUrl ?? '';
    _hydratedUser = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value?.user;

    if (user != null && !_hydratedUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hydratedUser) return;

        _hydrateControllers(
          name: user.name,
          zaloPhone: user.zaloPhone,
          avatarUrl: user.avatarUrl,
        );

        setState(() {});
      });
    }

    if (user == null && auth.isLoading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Chỉnh sửa thông tin'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bạn cần đăng nhập để sửa thông tin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final avatarUrl = _avatarController.text.trim();
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      topPadding: topPadding,
                      avatarUrl: avatarUrl,
                      selectedImageBytes: _selectedImageBytes,
                      uploadingImage: _uploadingImage,
                      userName: user.name,
                      onBack: () => context.pop(),
                      onEditAvatar: _uploadingImage
                          ? null
                          : _pickAndUploadImage,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      104 + bottomPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionCard(
                          title: 'Thông tin có thể chỉnh sửa',
                          subtitle:
                              'Cập nhật các thông tin được phép thay đổi trên tài khoản.',
                          icon: Icons.edit_note_rounded,
                          child: Column(
                            children: [
                              _EditableField(
                                controller: _nameController,
                                label: 'Họ và tên',
                                hintText: 'Nhập họ và tên',
                                icon: Icons.person_outline_rounded,
                                requiredField: true,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Vui lòng nhập họ và tên.';
                                  }

                                  if (text.length < 2) {
                                    return 'Họ và tên phải có ít nhất 2 ký tự.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _EditableField(
                                controller: _zaloController,
                                label: 'Số điện thoại Zalo',
                                hintText: 'Nhập số Zalo',
                                icon: Icons.chat_bubble_outline_rounded,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Thông tin tài khoản',
                          subtitle:
                              'Các thông tin này được quản lý bởi hệ thống và hiện không chỉnh sửa tại đây.',
                          icon: Icons.shield_outlined,
                          child: Column(
                            children: [
                              _ReadOnlyField(
                                label: 'Số điện thoại',
                                value: _safeText(user.phone),
                                icon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 14),
                              _ReadOnlyField(
                                label: 'Email',
                                value: _safeText(user.email),
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CompactInfoTile(
                                      label: 'Vai trò',
                                      value: _roleName(user.activeMode),
                                      icon: Icons.person_pin_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _CompactInfoTile(
                                      label: 'Trạng thái',
                                      value: _statusName(user.status),
                                      icon: Icons.verified_user_outlined,
                                      positive: user.status == 'ACTIVE',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CompactInfoTile(
                                      label: 'Ngày tham gia',
                                      value: _joinDate(user.createdAt),
                                      icon: Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _CompactInfoTile(
                                      label: 'Mã tài khoản',
                                      value: '#${_shortId(user.id)}',
                                      icon: Icons.fingerprint_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD9F1EA)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: _primaryDark,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Họ tên, số Zalo và ảnh đại diện sẽ được cập nhật vào hồ sơ sau khi bạn bấm Lưu thay đổi.',
                                  style: TextStyle(
                                    color: Color(0xFF507168),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // Thanh lưu cố định ở cuối màn hình.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .97),
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE7EEEC)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 18,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.isLoading || _uploadingImage
                          ? null
                          : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withValues(
                          alpha: .45,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox.square(
                              dimension: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 21),
                                SizedBox(width: 8),
                                Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _safeText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chưa cập nhật';
    }
    return value.trim();
  }

  static String _shortId(String id) {
    final cleaned = id.replaceAll('-', '').toUpperCase();
    return cleaned.length <= 8 ? cleaned : cleaned.substring(0, 8);
  }

  static String _joinDate(DateTime? value) {
    if (value == null) return 'Chưa cập nhật';
    return '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  static String _roleName(String role) {
    return switch (role) {
      'TENANT' => 'Người thuê',
      'LANDLORD' => 'Chủ trọ',
      'LANDLORD_STAFF' => 'Nhân viên',
      'ORGANIZATION_OWNER' => 'Chủ tổ chức',
      _ => role,
    };
  }

  static String _statusName(String status) {
    return switch (status) {
      'ACTIVE' => 'Hoạt động',
      'SUSPENDED' => 'Tạm khóa',
      'LOCKED' => 'Đã khóa',
      _ => status,
    };
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.topPadding,
    required this.avatarUrl,
    required this.selectedImageBytes,
    required this.uploadingImage,
    required this.userName,
    required this.onBack,
    required this.onEditAvatar,
  });

  final double topPadding;
  final String avatarUrl;
  final Uint8List? selectedImageBytes;
  final bool uploadingImage;
  final String? userName;
  final VoidCallback onBack;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290 + topPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 214 + topPadding,
            child: Image.asset(
              'assets/images/profile/profile_B.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned(
            top: topPadding + 8,
            left: 10,
            right: 10,
            child: Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const Expanded(
                  child: Text(
                    'Chỉnh sửa hồ sơ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _EditProfileScreenState._navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
          Positioned(
            top: topPadding + 82,
            child: GestureDetector(
              onTap: onEditAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFFDDF6EF),
                      backgroundImage: selectedImageBytes != null
                          ? MemoryImage(selectedImageBytes!)
                          : avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: selectedImageBytes == null && avatarUrl.isEmpty
                          ? Text(
                              _initial(userName),
                              style: const TextStyle(
                                color: _EditProfileScreenState._primaryDark,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 3,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2EAE8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .10),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: uploadingImage
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _EditProfileScreenState._primary,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: _EditProfileScreenState._navy,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 212,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EFED)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .045),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F8F2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: _EditProfileScreenState._primaryDark,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ảnh đại diện',
                          style: TextStyle(
                            color: _EditProfileScreenState._navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chạm vào ảnh để chọn ảnh mới từ thiết bị',
                          style: TextStyle(
                            color: _EditProfileScreenState._muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF93A0AD),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initial(String? name) {
    if (name == null || name.trim().isEmpty) return 'T';
    return name.trim()[0].toUpperCase();
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .88),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: _EditProfileScreenState._navy),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EFED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8F3),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: _EditProfileScreenState._primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _EditProfileScreenState._navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _EditProfileScreenState._muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.requiredField = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool requiredField;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label, requiredField: requiredField),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(
            color: _EditProfileScreenState._navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(hintText: hintText, icon: icon),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6ECEE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF8090A0)),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6F7D8E),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: Color(0xFFA1ABB6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoTile extends StatelessWidget {
  const _CompactInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.positive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE8F8F1) : const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: positive ? const Color(0xFFD6EFE4) : const Color(0xFFE8ECEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: positive
                ? _EditProfileScreenState._primaryDark
                : const Color(0xFF778699),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _EditProfileScreenState._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: positive
                  ? _EditProfileScreenState._primaryDark
                  : _EditProfileScreenState._navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.requiredField = false});

  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF6A788A),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: Color(0xFFABB4BE),
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(icon, color: const Color(0xFF738397), size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE5E4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: _EditProfileScreenState._primary,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}
