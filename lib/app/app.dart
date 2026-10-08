import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/notifications/presentation/providers/push_notification_lifecycle_provider.dart';

class TrosvApp extends ConsumerWidget {
  const TrosvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushNotificationLifecycleProvider);
    return MaterialApp.router(
      title: 'TrọSV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
