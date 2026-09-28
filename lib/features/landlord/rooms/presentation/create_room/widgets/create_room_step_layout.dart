import 'package:flutter/material.dart';

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
          'Đăng phòng trọ',
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
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
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
          if (onBack != null)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Quay lại'),
            ),
          const Spacer(),
          if (secondaryLabel != null) ...[
            OutlinedButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 145,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
    this.initialValue,
    this.hint,
    this.required = false,
    this.keyboardType,
    this.suffixText,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? initialValue;
  final String? hint;
  final bool required;
  final TextInputType? keyboardType;
  final String? suffixText;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
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
          enabled: enabled,
          initialValue: initialValue,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            filled: true,
            fillColor: Colors.white,
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
