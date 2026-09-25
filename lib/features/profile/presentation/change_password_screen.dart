import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: const Color(0xFFF5F8F7),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SecurityHeader(),
                const SizedBox(height: 24),
                _PasswordField(
                  controller: _currentPasswordController,
                  label: 'Mật khẩu hiện tại',
                  obscureText: _hideCurrentPassword,
                  autofillHints: const [AutofillHints.password],
                  onToggleVisibility: () {
                    setState(() {
                      _hideCurrentPassword = !_hideCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _newPasswordController,
                  label: 'Mật khẩu mới',
                  obscureText: _hideNewPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onToggleVisibility: () {
                    setState(() => _hideNewPassword = !_hideNewPassword);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới.';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu mới phải có ít nhất 8 ký tự.';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu mới',
                  obscureText: _hideConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_submitting) _submit();
                  },
                  onToggleVisibility: () {
                    setState(() {
                      _hideConfirmPassword = !_hideConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới.';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mật khẩu nên có ít nhất 8 ký tự và không dùng lại mật khẩu cũ.',
                  style: TextStyle(color: Color(0xFF687685), height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset_rounded),
                    label: const Text('Cập nhật mật khẩu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFDDF6EF),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 34,
            color: Color(0xFF008E78),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Bảo vệ tài khoản của bạn',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 5),
        Text(
          'Nhập mật khẩu hiện tại trước khi đặt mật khẩu mới.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF687685)),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
    required this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
