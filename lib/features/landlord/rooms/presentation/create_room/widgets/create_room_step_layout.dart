import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateRoomStepLayout extends StatelessWidget {
  const CreateRoomStepLayout({
    required this.step,
    required this.title,
    required this.child,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Tiếp tục',
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
    super.key,
  });

  final int step;
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAF9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Thông tin phòng trọ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                '$step/5',
                style: const TextStyle(
                  color: Color(0xFF009688),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: step / 5,
            minHeight: 4,
            color: const Color(0xFF00A884),
            backgroundColor: const Color(0xFFE0ECE9),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    child,
                  ],
                ),
              ),
            ),
            _BottomActions(
              onBack: onBack,
              onNext: isLoading ? null : onNext,
              nextLabel: nextLabel,
              secondaryLabel: secondaryLabel,
              onSecondary: isLoading ? null : onSecondary,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.isLoading,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4EAE8))),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008C72),
                  side: const BorderSide(color: Color(0xFFCDEBE4), width: 1),
                  backgroundColor: const Color(0xFFEAF8F5),
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (secondaryLabel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(secondaryLabel!),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(nextLabel),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateRoomTextField extends StatelessWidget {
  const CreateRoomTextField({
    required this.label,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.required = false,
    this.enabled = true,
    this.keyboardType,
    this.prefixIcon,
    this.suffixText,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'Không dùng controller và initialValue cùng lúc.',
       );

  final String label;
  final TextEditingController? controller;
  final String? initialValue;

  /// Thêm focusNode để ô địa chỉ có thể quản lý
  /// lúc đang search autocomplete / lúc đóng suggestion.
  final FocusNode? focusNode;

  final String? hint;
  final bool required;
  final bool enabled;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? suffixText;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19),
            suffixText: suffixText,
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F4F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
