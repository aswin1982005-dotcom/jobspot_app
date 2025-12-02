import 'package:flutter/material.dart';
import 'package:jobspot_app/features/splash/presentation/screen/splash_screen.dart';

class AppRouter {
  static const String splash = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold());
    }
  }
}