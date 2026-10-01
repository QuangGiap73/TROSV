import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../create/roommate_create_step_one.dart';
import '../create/roommate_create_step_two.dart';
import '../create/roommate_create_step_three.dart';
import '../create/widgets/roommate_step_indicator.dart';
import '../providers/roommate_create_provider.dart';

class CreateRoommatePostScreen extends ConsumerWidget {
  const CreateRoommatePostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      roommateCreateDraftProvider.select((value) => value.step),
    );

    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step > 0) {
          ref.read(roommateCreateDraftProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            'Đăng tin ở ghép - Bước ${step + 1}/3',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (step > 0) {
                ref.read(roommateCreateDraftProvider.notifier).previousStep();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(8),
            child: RoommateStepIndicator(currentStep: step, totalSteps: 3),
          ),
        ),
        body: IndexedStack(
          index: step,
          children: const [
            RoommateCreateStepOne(),
            RoommateCreateStepTwo(),
            RoommateCreateStepThree(),
          ],
        ),
      ),
    );
  }
}
