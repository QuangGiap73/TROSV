import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';

const _primary = Color(0xFF00A889);
const _primaryDark = Color(0xFF00866E);

const _background = Color(0xFFF6F9F8);
const _surface = Colors.white;

const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF687873);

const _border = Color(0xFFE1E9E7);
const _error = Color(0xFFE24C4B);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  bool _submitting = false;

  String get _newPassword => _newPasswordController.text;

  bool get _hasMinimumLength => _newPassword.length >= 8;

  bool get _hasLetter =>
      RegExp(r'[A-Za-z]').hasMatch(_newPassword);

  bool get _hasNumber =>
      RegExp(r'[0-9]').hasMatch(_newPassword);

  bool get _differentFromCurrent =>
      _newPassword.isNotEmpty &&
      _newPassword != _currentPasswordController.text;

  int get _passwordStrength {
    var score = 0;

    if (_hasMinimumLength) score++;
    if (_hasLetter) score++;
    if (_hasNumber) score++;
    if (_differentFromCurrent) score++;

    return score;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword:
                _currentPasswordController.text.trim(),
            newPassword:
                _newPasswordController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mật khẩu đã được cập nhật thành công.',
                  ),
                ),
              ],
            ),
          ),
        );

      context.pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF323B39),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.toString(),
                  ),
                ),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      //
      // APP BAR
      //
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: _submitting
              ? null
              : () {
                  context.pop();
                },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: _textPrimary,
          ),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  //
                  // HEADER
                  //
                  const _SecurityCard(),

                  const SizedBox(height: 24),

                  //
                  // CURRENT PASSWORD
                  //
                  const _SectionTitle(
                    title: 'Mật khẩu hiện tại',
                  ),

                  const SizedBox(height: 8),

                  _PasswordField(
                    controller:
                        _currentPasswordController,
                    hintText:
                        'Nhập mật khẩu hiện tại',
                    icon:
                        Icons.lock_outline_rounded,
                    obscureText:
                        _hideCurrentPassword,
                    autofillHints: const [
                      AutofillHints.password,
                    ],
                    onChanged: (_) {
                      setState(() {});
                    },
                    onToggleVisibility: () {
                      setState(() {
                        _hideCurrentPassword =
                            !_hideCurrentPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Vui lòng nhập mật khẩu hiện tại.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 22),

                  //
                  // NEW PASSWORD
                  //
                  const _SectionTitle(
                    title: 'Mật khẩu mới',
                  ),

                  const SizedBox(height: 8),

                  _PasswordField(
                    controller:
                        _newPasswordController,
                    hintText:
                        'Nhập mật khẩu mới',
                    icon:
                        Icons.key_rounded,
                    obscureText:
                        _hideNewPassword,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    onChanged: (_) {
                      setState(() {});
                    },
                    onToggleVisibility: () {
                      setState(() {
                        _hideNewPassword =
                            !_hideNewPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới.';
                      }

                      if (value.length < 8) {
                        return 'Mật khẩu phải có ít nhất 8 ký tự.';
                      }

                      if (value ==
                          _currentPasswordController
                              .text) {
                        return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
                      }

                      return null;
                    },
                  ),

                  //
                  // PASSWORD STRENGTH
                  //
                  if (_newPassword.isNotEmpty) ...[
                    const SizedBox(height: 12),

                    _PasswordStrength(
                      strength:
                          _passwordStrength,
                    ),

                    const SizedBox(height: 12),

                    _PasswordRules(
                      hasMinimumLength:
                          _hasMinimumLength,
                      hasLetter: _hasLetter,
                      hasNumber: _hasNumber,
                      differentFromCurrent:
                          _differentFromCurrent,
                    ),
                  ],

                  const SizedBox(height: 22),

                  //
                  // CONFIRM PASSWORD
                  //
                  const _SectionTitle(
                    title:
                        'Xác nhận mật khẩu mới',
                  ),

                  const SizedBox(height: 8),

                  _PasswordField(
                    controller:
                        _confirmPasswordController,
                    hintText:
                        'Nhập lại mật khẩu mới',
                    icon:
                        Icons.verified_user_outlined,
                    obscureText:
                        _hideConfirmPassword,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    textInputAction:
                        TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_submitting) {
                        _submit();
                      }
                    },
                    onToggleVisibility: () {
                      setState(() {
                        _hideConfirmPassword =
                            !_hideConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu mới.';
                      }

                      if (value !=
                          _newPasswordController
                              .text) {
                        return 'Mật khẩu xác nhận không khớp.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  //
                  // SUBMIT BUTTON
                  //
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          _submitting
                              ? null
                              : _submit,
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _primaryDark,
                        disabledBackgroundColor:
                            _primaryDark
                                .withOpacity(0.5),
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                key: ValueKey(
                                  'loading',
                                ),
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                key: ValueKey(
                                  'button',
                                ),
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .lock_reset_rounded,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Cập nhật mật khẩu',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          14.5,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  //
                  // SMALL SECURITY NOTE
                  //
                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .security_rounded,
                        size: 14,
                        color: _textSecondary,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Mật khẩu của bạn được bảo mật.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                _textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// ==========================================================================
// HEADER
// ==========================================================================
//

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5ECE5),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _primaryDark,
              size: 26,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sử dụng mật khẩu mạnh và không chia sẻ với bất kỳ ai.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ==========================================================================
// SECTION TITLE
// ==========================================================================
//

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

//
// ==========================================================================
// PASSWORD FIELD
// ==========================================================================
//

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
    required this.autofillHints,
    this.textInputAction =
        TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;

  final String hintText;
  final IconData icon;

  final bool obscureText;

  final VoidCallback onToggleVisibility;

  final FormFieldValidator<String>
      validator;

  final Iterable<String>
      autofillHints;

  final TextInputAction
      textInputAction;

  final ValueChanged<String>?
      onFieldSubmitted;

  final ValueChanged<String>?
      onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints:
          autofillHints,
      textInputAction:
          textInputAction,
      onFieldSubmitted:
          onFieldSubmitted,
      onChanged: onChanged,
      validator: validator,

      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          color: Color(0xFF9BA8A4),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),

        prefixIcon: Icon(
          icon,
          size: 20,
          color: const Color(
            0xFF71837E,
          ),
        ),

        suffixIcon: IconButton(
          onPressed:
              onToggleVisibility,
          tooltip: obscureText
              ? 'Hiện mật khẩu'
              : 'Ẩn mật khẩu',
          icon: Icon(
            obscureText
                ? Icons
                    .visibility_outlined
                : Icons
                    .visibility_off_outlined,
            size: 20,
            color: const Color(
              0xFF71837E,
            ),
          ),
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: _border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: _primary,
            width: 1.4,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: _error,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: _error,
            width: 1.4,
          ),
        ),

        errorStyle: const TextStyle(
          fontSize: 10.5,
          height: 1.2,
        ),
      ),
    );
  }
}

//
// ==========================================================================
// PASSWORD STRENGTH
// ==========================================================================
//

class _PasswordStrength
    extends StatelessWidget {
  const _PasswordStrength({
    required this.strength,
  });

  final int strength;

  @override
  Widget build(BuildContext context) {
    final label =
        switch (strength) {
      0 || 1 => 'Yếu',
      2 => 'Trung bình',
      3 => 'Tốt',
      _ => 'Mạnh',
    };

    final color =
        switch (strength) {
      0 || 1 =>
        const Color(0xFFE65A58),
      2 =>
        const Color(0xFFE6A23C),
      3 =>
        const Color(0xFF2FA682),
      _ => _primaryDark,
    };

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Độ an toàn',
              style: TextStyle(
                fontSize: 11,
                color:
                    _textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Row(
          children:
              List.generate(
            4,
            (index) {
              final active =
                  index < strength;

              return Expanded(
                child: Container(
                  height: 4,
                  margin:
                      EdgeInsets.only(
                    right:
                        index == 3
                            ? 0
                            : 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: active
                        ? color
                        : const Color(
                            0xFFE3E9E7,
                          ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

//
// ==========================================================================
// PASSWORD RULES
// ==========================================================================
//

class _PasswordRules
    extends StatelessWidget {
  const _PasswordRules({
    required this.hasMinimumLength,
    required this.hasLetter,
    required this.hasNumber,
    required this.differentFromCurrent,
  });

  final bool hasMinimumLength;
  final bool hasLetter;
  final bool hasNumber;
  final bool differentFromCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _RuleItem(
            passed:
                hasMinimumLength,
            text:
                'Ít nhất 8 ký tự',
          ),

          const SizedBox(height: 8),

          _RuleItem(
            passed: hasLetter,
            text:
                'Có ít nhất một chữ cái',
          ),

          const SizedBox(height: 8),

          _RuleItem(
            passed: hasNumber,
            text:
                'Có ít nhất một chữ số',
          ),

          const SizedBox(height: 8),

          _RuleItem(
            passed:
                differentFromCurrent,
            text:
                'Khác mật khẩu hiện tại',
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.passed,
    required this.text,
  });

  final bool passed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: passed
                ? const Color(
                    0xFFE2F5EF,
                  )
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: passed
                  ? _primary
                  : const Color(
                      0xFFC8D2CF,
                    ),
            ),
          ),
          child: passed
              ? const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: _primaryDark,
                )
              : null,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: passed
                  ? _textPrimary
                  : _textSecondary,
              fontWeight: passed
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}