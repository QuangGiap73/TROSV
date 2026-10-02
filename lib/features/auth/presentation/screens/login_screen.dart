import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_session.dart';
import '../providers/auth_provider.dart';

const _primary = Color(0xFF00A884);
const _primaryDark = Color(0xFF008C72);
const _background = Color(0xFFF6FAF9);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF6F7D79);
const _field = Color(0xFFF7F9F9);
const _border = Color(0xFFE3EBE8);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isPhone(String value) {
    return RegExp(r'^(?:\+84|0)\d{9}$').hasMatch(value);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(
          phone: _phone.text.trim(),
          password: _password.text,
        );

    if (!success || !mounted) {
      return;
    }

    final session = ref.read(authControllerProvider).asData?.value;

    if (session?.user.isLandlordMode == true) {
      context.go('/landlord');
      return;
    }

    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  Future<void> _openRegister() async {
    ref.read(authControllerProvider.notifier).clearError();

    final registered = await context.push<bool>('/register');

    if (registered != true || !mounted) {
      return;
    }

    final session = ref.read(authControllerProvider).asData?.value;

    if (session?.user.isLandlordMode == true) {
      context.go('/landlord');
      return;
    }

    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _background,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 16 : 24),
          child: Column(
            children: [
              _AuthBanner(
                assetPath: 'assets/images/auth/banner_dang_nhap_trosv.jpg',
                onBack: auth.isLoading
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop(false);
                        } else {
                          context.go('/');
                        }
                      },
              ),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.055),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: _text,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Chào mừng bạn quay lại với TrọSV',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AuthField(
                          controller: _phone,
                          label: 'Số điện thoại',
                          hintText: 'Nhập số điện thoại',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !auth.isLoading,
                          validator: (value) {
                            if (!_isPhone(value?.trim() ?? '')) {
                              return 'Số điện thoại không hợp lệ.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        _AuthField(
                          controller: _password,
                          label: 'Mật khẩu',
                          hintText: 'Nhập mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !auth.isLoading,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    setState(
                                      () => _hidePassword = !_hidePassword,
                                    );
                                  },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 21,
                              color: _muted,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu.';
                            }
                            return null;
                          },
                        ),
                        if (auth.hasError) ...[
                          const SizedBox(height: 14),
                          _ErrorBox(message: auth.error.toString()),
                        ],
                        const SizedBox(height: 22),
                        _PrimaryButton(
                          label: 'Đăng nhập',
                          loading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _submit,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: _border, height: 1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Chưa có tài khoản?',
                                style: TextStyle(
                                  color: _muted.withOpacity(.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: _border, height: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        OutlinedButton(
                          onPressed: auth.isLoading ? null : _openRegister,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryDark,
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(
                              color: Color(0xFF9FDCCF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Tạo tài khoản TrọSV',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Đăng nhập để lưu phòng, liên hệ chủ trọ và quản lý lịch xem phòng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: Color(0xFF8A9692),
                          ),
                        ),
                      ],
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
}

class _AuthBanner extends StatelessWidget {
  const _AuthBanner({
    required this.assetPath,
    required this.onBack,
  });

  final String assetPath;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: double.infinity,
      height: (width * .66).clamp(215.0, 290.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) {
              return const ColoredBox(
                color: Color(0xFFE2F7F2),
                child: Center(
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 54,
                    color: _primaryDark,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 14,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              color: Colors.white.withOpacity(.92),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: _text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _text,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA0AAA7),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: _primaryDark, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: _field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE36868)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE36868),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? const [Color(0xFFA8CBC3), Color(0xFFA8CBC3)]
              : const [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: onPressed == null
            ? const []
            : [
                BoxShadow(
                  color: _primary.withOpacity(.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 19,
            color: Color(0xFFCE4A4A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB63D3D),
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
