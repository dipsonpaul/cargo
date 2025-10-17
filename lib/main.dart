import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'firebase_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'loginpage.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/auth/password_change_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with demo configuration
  await FirebaseConfig.initialize();
  
  // Initialize notifications (optional for demo)
  try {
    NotificationService notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    print('Notifications not available for demo: $e');
  }
  
  runApp(const ProviderScope(child: CargoApp()));
}

class CargoApp extends StatelessWidget {
  const CargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
    return MaterialApp(
          title: 'Cargo Collection System',
          debugShowCheckedModeBanner: false,
      theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2196F3),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/admin': (context) => const AdminDashboard(),
            '/driver': (context) => const DriverDashboard(),
            '/customer': (context) => const CustomerDashboard(),
            '/password-change': (context) => const PasswordChangeScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        try {
          UserModel? userModel = await _authService.getUserById(user.uid);
          if (mounted) {
            setState(() {
              _currentUser = userModel;
            });
          }
        } catch (e) {
          print('Error getting user data: $e');
        }
      } else {
        if (mounted) {
          setState(() {
            _currentUser = null;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const SplashScreen();
    }

    // Check if first login and redirect to password change
    if (_currentUser!.isFirstLogin) {
      // return const PasswordChangeScreen();
    }

    // Route based on user role
    switch (_currentUser!.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.driver:
        return const DriverDashboard();
      case UserRole.customer:
        return const CustomerDashboard();
    }
  }
}
