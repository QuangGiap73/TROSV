import 'package:flutter/material.dart';

class RoommateCreateBottomBar extends StatelessWidget {
  const RoommateCreateBottomBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.loading = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16)],
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: onBack == null ? 1 : 2,
              child: FilledButton(
                onPressed: loading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF00A889),
                ),
                child: loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(primaryLabel),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
