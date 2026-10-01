import 'package:flutter/material.dart';

class RoommateStepIndicator extends StatelessWidget {
  const RoommateStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? const Color(0xFF00A889)
                    : const Color(0xFFDCEAE6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }
}
