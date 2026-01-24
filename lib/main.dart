import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jobspot_app/core/constants/user_role.dart';
import 'package:jobspot_app/core/routes/dashboard_router.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jobspot_app/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:jobspot_app/features/auth/presentation/screens/unable_account_page.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const JobSpotApp(),
    ),
  );
}

class JobSpotApp extends StatelessWidget {
  const JobSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'JobSpot',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const RootPage(),
        );
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _loading = true;
  Widget? _home;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initAuth);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    final session = supabase.auth.currentSession;

    if (session == null) {
      _updateHome(const LoginScreen());
    } else {
      _handleUser(session.user);
    }

    _authSub = supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user != null) {
        _handleUser(user);
      } else {
        _updateHome(const LoginScreen());
      }
    }, onError: (_) => _updateHome(const LoginScreen()));
  }

  Future<void> _handleUser(User user) async {
    try {
      _setLoading();

      final profile = await supabase
          .from('user_profiles')
          .select('role, account_disabled, profile_completed')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        _updateHome(const RoleSelectionScreen());
        return;
      }

      if (profile['account_disabled'] == true) {
        _updateHome(UnableAccountPage(userProfile: profile));
        return;
      }

      final roleStr = profile['role'] as String?;
      final role = roleStr != null
          ? UserRoleExtension.fromDbValue(roleStr)
          : null;

      _updateHome(DashboardRouter(role: role));
    } catch (_) {
      _updateHome(const LoginScreen());
    }
  }

  void _setLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
  }

  void _updateHome(Widget screen) {
    if (!mounted) return;

    if (_home?.runtimeType == screen.runtimeType && !_loading) return;

    setState(() {
      _home = screen;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _home == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    return _home!;
  }
}
