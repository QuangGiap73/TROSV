import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_session.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _confirmPassword = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  String _role = 'TENANT';
  bool _hidePassword = true;
  int _otpSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    _email.dispose();
    _otp.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    ref.read(authControllerProvider.notifier).clearError();
    _formKey.currentState?.reset();
    setState(() => _mode = mode);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final success = _mode == _AuthMode.login
        ? await controller.login(phone: _phone.text, password: _password.text)
        : await controller.register(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
            otp: _otp.text,
            password: _password.text,
            role: _role,
          );
    if (!success || !mounted) return;

    final session = ref.read(authControllerProvider).asData?.value;
    if (session?.user.isLandlordMode == true) {
      context.go('/landlord');
    } else {
      context.pop(true);
    }
  }

  Future<void> _sendOtp() async {
    if (!_isPhone(_phone.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập số điện thoại hợp lệ.')),
      );
      return;
    }
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(_phone.text);
    if (result == null || !mounted) return;
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

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _otpSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _otpSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _otpSeconds = 0);
      } else {
        setState(() => _otpSeconds--);
      }
    });
  }

  bool _isPhone(String value) => RegExp(r'^(?:\+84|0)\d{9}$').hasMatch(value);

  bool _isEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: auth.isLoading ? null : () => context.pop(false),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _mode == _AuthMode.login
                      ? 'Chào mừng trở lại với TrọSV'
                      : 'Tạo tài khoản TrọSV',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cùng nhau kiến tạo những không gian sống tốt đẹp hơn.',
                ),
                const SizedBox(height: 24),
                SegmentedButton<_AuthMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _AuthMode.login,
                      label: Text('Đăng nhập'),
                    ),
                    ButtonSegment(
                      value: _AuthMode.register,
                      label: Text('Đăng ký'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: auth.isLoading
                      ? null
                      : (value) => _switchMode(value.first),
                ),
                const SizedBox(height: 24),
                if (_mode == _AuthMode.register) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'TENANT',
                        label: Text('Người thuê'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: 'LANDLORD',
                        label: Text('Chủ trọ'),
                        icon: Icon(Icons.home_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (value) =>
                        setState(() => _role = value.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Họ và tên phải có ít nhất 2 ký tự.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => !_isPhone(value?.trim() ?? '')
                      ? 'Số điện thoại không hợp lệ.'
                      : null,
                ),
                if (_mode == _AuthMode.register) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) => !_isEmail(value?.trim() ?? '')
                        ? 'Email không hợp lệ.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mã OTP',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      suffixIcon: TextButton(
                        onPressed: auth.isLoading || _otpSeconds > 0
                            ? null
                            : _sendOtp,
                        child: Text(
                          _otpSeconds > 0
                              ? 'Gửi lại ${_otpSeconds}s'
                              : 'Gửi OTP',
                        ),
                      ),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Vui lòng nhập mã OTP.'
                        : null,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    if (_mode == _AuthMode.register && value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự.';
                    }
                    return null;
                  },
                ),
                if (_mode == _AuthMode.register) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Mật khẩu nhập lại không khớp.'
                        : null,
                  ),
                ],
                if (auth.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    auth.error.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: auth.isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _mode == _AuthMode.login
                                ? 'Đăng nhập'
                                : 'Tạo tài khoản',
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : () => context.pop(false),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại màn hình trước'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
