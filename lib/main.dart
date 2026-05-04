import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_strings.dart';
import 'package:rayen_mobile/core/router/app_router.dart';
import 'package:rayen_mobile/core/theme/app_theme.dart';
import 'package:rayen_mobile/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:rayen_mobile/features/admin/domain/repositories/admin_repository_impl.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:rayen_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/course/data/datasources/course_remote_datasource.dart';
import 'package:rayen_mobile/features/course/domain/repositories/course_repository_impl.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';
import 'package:rayen_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:rayen_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:rayen_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:rayen_mobile/features/recommendation/data/repositories/recommendation_repository_impl.dart';
import 'package:rayen_mobile/features/recommendation/domain/usecases/get_recommendations.dart';
import 'package:rayen_mobile/features/recommendation/presentation/providers/recommendation_provider.dart';
import 'package:rayen_mobile/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:rayen_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:rayen_mobile/features/notifications/presentation/providers/notification_provider.dart';
import 'package:rayen_mobile/features/training/data/datasources/training_remote_datasource.dart';
import 'package:rayen_mobile/features/training/data/repositories/training_repository_impl.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';
import 'package:rayen_mobile/services/paymee_payment_service.dart';
import 'package:rayen_mobile/services/notification_service.dart';
import 'package:rayen_mobile/services/push_notification_service.dart';
import 'package:rayen_mobile/services/push_notification_bootstrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('fr', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(AuthRepositoryImpl(AuthRemoteDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CourseProvider(CourseRepositoryImpl(CourseRemoteDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AdminProvider(AdminRepositoryImpl(AdminRemoteDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) => TrainingProvider(
            TrainingRepositoryImpl(TrainingRemoteDataSource()),
            NotificationService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            NotificationRepositoryImpl(NotificationRemoteDataSource()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ProfileProvider(ProfileRepositoryImpl(ProfileRemoteDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) => RecommendationProvider(
            GetRecommendations(
              RecommendationRepositoryImpl(FirebaseFirestore.instance),
            ),
          ),
        ),
        Provider<PaymeePaymentService>(
          create: (_) => PaymeePaymentService(
            isSandbox: dotenv.env['PAYMEE_SANDBOX'] == 'true',
            apiKey: dotenv.env['PAYMEE_API_KEY'] ?? '',
          ),
        ),
        Provider<PushNotificationService>(
          create: (_) => PushNotificationService(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return PushNotificationBootstrapper(
            child: MaterialApp.router(
              title: AppStrings.appName,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeMode.system,
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.router(context.read<AuthProvider>()),
            ),
          );
        },
      ),
    );
  }
}
