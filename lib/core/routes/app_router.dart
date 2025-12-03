import 'package:flutter/material.dart';
import 'package:jobspot_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jobspot_app/features/splash/presentation/screen/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold());
    }
  }
}