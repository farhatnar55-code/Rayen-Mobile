import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/router/app_router.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/notifications/presentation/providers/notification_provider.dart';
import 'package:rayen_mobile/services/push_notification_service.dart';

class PushNotificationBootstrapper extends StatefulWidget {
  final Widget child;

  const PushNotificationBootstrapper({super.key, required this.child});

  @override
  State<PushNotificationBootstrapper> createState() =>
      _PushNotificationBootstrapperState();
}

class _PushNotificationBootstrapperState
    extends State<PushNotificationBootstrapper> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final push = context.read<PushNotificationService>();
    final notifications = context.read<NotificationProvider>();

    if (!_initialized) {
      _initialized = true;
      push.initialize(
        onForegroundMessage: (message) async {
          final uid = auth.user?.uid;
          if (uid != null && uid.isNotEmpty) {
            await notifications.loadNotifications(uid);
          }
        },
        onOpenMessage: (message) async {
          final uid = auth.user?.uid;
          if (uid != null && uid.isNotEmpty) {
            await notifications.loadNotifications(uid);
          }
          final route = message.data['targetRoute'] as String?;
          if (route != null && route.isNotEmpty) {
            final router = AppRouter.currentRouter;
            if (router != null) {
              router.go(route);
            }
          }
        },
      );
    }

    push.syncUser(auth.user);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
