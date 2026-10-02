import 'dart:async';

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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  Timer? _timer;

  String _role = 'TENANT';
  int _otpSeconds = 0;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool _isPhone(String value) {
    return RegExp(r'^(?:\+84|0)\d{9}$').hasMatch(value);
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();

    setState(() {
      _otpSeconds = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _otpSeconds <= 1) {
        timer.cancel();

        if (mounted) {
          setState(() {
            _otpSeconds = 0;
          });
        }

        return;
      }

      setState(() {
        _otpSeconds--;
      });
    });
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    final phone = _phone.text.trim();

    if (!_isPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập số điện thoại hợp lệ trước khi gửi OTP.'),
        ),
      );
      return;
    }

    final result =
        await ref.read(authControllerProvider.notifier).sendOtp(phone);

    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.debugOtp == null
              ? result.message
              : '${result.message} OTP test: ${result.debugOtp}',
        ),
      ),
    );

    _startCountdown(result.cooldownSeconds);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn cần đồng ý với Điều khoản và Chính sách của TrọSV.',
          ),
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).register(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          otp: _otp.text.trim(),
          password: _password.text,
          role: _role,
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
                assetPath: 'assets/images/auth/banner_dang_ky_trosv.jpg',
                onBack: auth.isLoading
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop(false);
                        } else {
                          context.go('/login');
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
                          'Đăng ký',
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
                          'Tạo tài khoản để bắt đầu hành trình cùng TrọSV',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Bạn sử dụng TrọSV với vai trò nào?',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _RoleSelector(
                          value: _role,
                          enabled: !auth.isLoading,
                          onChanged: (value) {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();

                            setState(() {
                              _role = value;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        _AuthField(
                          controller: _name,
                          label: 'Họ và tên',
                          hintText: 'Nhập họ và tên',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          enabled: !auth.isLoading,
                          validator: (value) {
                            if ((value?.trim().length ?? 0) < 2) {
                              return 'Họ và tên phải có ít nhất 2 ký tự.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
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
                          controller: _email,
                          label: 'Email',
                          hintText: 'Nhập email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !auth.isLoading,
                          validator: (value) {
                            if (!_isEmail(value?.trim() ?? '')) {
                              return 'Email không hợp lệ.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        _OtpField(
                          controller: _otp,
                          enabled: !auth.isLoading,
                          seconds: _otpSeconds,
                          onSend: auth.isLoading || _otpSeconds > 0
                              ? null
                              : _sendOtp,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mã OTP.';
                            }
                            if (value.trim().length < 4) {
                              return 'Mã OTP không hợp lệ.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        _AuthField(
                          controller: _password,
                          label: 'Mật khẩu',
                          hintText: 'Ít nhất 8 ký tự',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          enabled: !auth.isLoading,
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
                            if (value.length < 8) {
                              return 'Mật khẩu phải có ít nhất 8 ký tự.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        _AuthField(
                          controller: _confirmPassword,
                          label: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu',
                          icon: Icons.lock_reset_rounded,
                          obscureText: _hideConfirmPassword,
                          textInputAction: TextInputAction.done,
                          enabled: !auth.isLoading,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    setState(
                                      () => _hideConfirmPassword =
                                          !_hideConfirmPassword,
                                    );
                                  },
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 21,
                              color: _muted,
                            ),
                          ),
                          validator: (value) {
                            if (value != _password.text) {
                              return 'Mật khẩu nhập lại không khớp.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: auth.isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _acceptedTerms = !_acceptedTerms;
                                  });
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _acceptedTerms
                                        ? _primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: _acceptedTerms
                                          ? _primary
                                          : const Color(0xFFBCC9C5),
                                    ),
                                  ),
                                  child: _acceptedTerms
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 9),
                                const Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.45,
                                        color: _muted,
                                      ),
                                      children: [
                                        TextSpan(text: 'Tôi đồng ý với '),
                                        TextSpan(
                                          text: 'Điều khoản sử dụng',
                                          style: TextStyle(
                                            color: _primaryDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(text: ' và '),
                                        TextSpan(
                                          text: 'Chính sách bảo mật',
                                          style: TextStyle(
                                            color: _primaryDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(text: ' của TrọSV.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (auth.hasError) ...[
                          const SizedBox(height: 14),
                          _ErrorBox(message: auth.error.toString()),
                        ],
                        const SizedBox(height: 20),
                        _PrimaryButton(
                          label: 'Tạo tài khoản',
                          loading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _submit,
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .clearError();

                                  if (context.canPop()) {
                                    context.pop(false);
                                  } else {
                                    context.go('/login');
                                  }
                                },
                          child: const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _muted,
                              ),
                              children: [
                                TextSpan(text: 'Đã có tài khoản?  '),
                                TextSpan(
                                  text: 'Đăng nhập',
                                  style: TextStyle(
                                    color: _primaryDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _RoleButton(
            selected: value == 'TENANT',
            icon: Icons.person_search_outlined,
            label: 'Người tìm trọ',
            enabled: enabled,
            onTap: () => onChanged('TENANT'),
          ),
          const SizedBox(width: 4),
          _RoleButton(
            selected: value == 'LANDLORD',
            icon: Icons.home_work_outlined,
            label: 'Chủ trọ',
            enabled: enabled,
            onTap: () => onChanged('LANDLORD'),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: selected
                  ? Border.all(color: const Color(0xFF8FD5C5))
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(.035),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? _primaryDark : _muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w700,
                      color: selected ? _primaryDark : _muted,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: _primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({
    required this.controller,
    required this.enabled,
    required this.seconds,
    required this.onSend,
    required this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final int seconds;
  final VoidCallback? onSend;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _text,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: 'Mã OTP',
        hintText: 'Nhập mã xác thực',
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA0AAA7),
          fontSize: 12,
        ),
        prefixIcon: const Icon(
          Icons.verified_user_outlined,
          color: _primaryDark,
          size: 21,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 7),
          child: TextButton(
            onPressed: onSend,
            style: TextButton.styleFrom(
              foregroundColor: _primaryDark,
              backgroundColor: const Color(0xFFE5F7F2),
              minimumSize: const Size(78, 38),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              seconds > 0 ? 'Gửi lại ${seconds}s' : 'Gửi mã',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 94),
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
      height: (width * .58).clamp(195.0, 255.0),
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
