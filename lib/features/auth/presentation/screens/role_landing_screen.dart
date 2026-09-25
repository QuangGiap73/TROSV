import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_session.dart';
import '../providers/auth_provider.dart';

class RoleLandingScreen extends ConsumerWidget {
  const RoleLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      if (next.isLoading || !context.mounted) return;
      final session = next.asData?.value;
      context.go(session?.user.isLandlordMode == true ? '/landlord' : '/');
    });

    if (!auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final session = auth.asData?.value;
        context.go(session?.user.isLandlordMode == true ? '/landlord' : '/');
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
