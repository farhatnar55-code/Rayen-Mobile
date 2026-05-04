import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/authentication/presentation/screens/splash_screen.dart';
import 'package:rayen_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:rayen_mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:rayen_mobile/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:rayen_mobile/features/student/presentation/screens/student_home_screen.dart';
import 'package:rayen_mobile/features/instructor/presentation/screens/instructor_dashboard_screen.dart';
import 'package:rayen_mobile/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:rayen_mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:rayen_mobile/features/training/presentation/screens/trainer_dashboard_screen.dart';
import 'package:rayen_mobile/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:rayen_mobile/features/notifications/presentation/screens/notifications_screen.dart';

class AppRouter {
  static GoRouter? currentRouter;

  static GoRouter router(AuthProvider authProvider) {
    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page introuvable: ${state.uri}'))),
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final loc = state.matchedLocation;
        final user = authProvider.user;

        if (loc == '/') return '/splash';
        if (loc == '/home') return _roleHome(authProvider.role);

        final isAuthRoute =
            loc == '/login' || loc == '/register' || loc == '/splash';

        if (!isAuthenticated && !isAuthRoute) return '/login';

        if (isAuthenticated) {
          if (isAuthRoute) {
            if (user != null && !user.profileCompleted) {
              return '/complete-profile';
            }
            return _roleHome(authProvider.role);
          }

          if (loc == '/complete-profile') {
            if (user != null && user.profileCompleted) {
              return _roleHome(authProvider.role);
            }
            return null;
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/complete-profile',
          builder: (_, __) => const CompleteProfileScreen(),
        ),
        GoRoute(
          path: '/student/home',
          builder: (_, __) => const StudentHomeScreen(),
        ),
        GoRoute(
          path: '/instructor/dashboard',
          builder: (_, __) => const InstructorDashboardScreen(),
        ),
        GoRoute(
          path: '/organizer/dashboard',
          builder: (_, __) => const OrganizerDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (_, __) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/trainer/dashboard',
          builder: (_, __) => const TrainerDashboardScreen(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (_, __) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ],
    );

    currentRouter = router;
    return router;
  }

  static String _roleHome(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.instructor:
        return '/instructor/dashboard';
      case UserRole.organizer:
        return '/organizer/dashboard';
      case UserRole.trainer:
        return '/trainer/dashboard';
      case UserRole.student:
      default:
        return '/student/home';
    }
  }
}
