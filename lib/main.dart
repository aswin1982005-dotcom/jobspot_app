import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jobspot_app/core/constants/user_role.dart';
import 'package:jobspot_app/core/routes/dashboard_router.dart';
import 'package:jobspot_app/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:jobspot_app/features/auth/presentation/screens/unable_account_page.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jobspot_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const JobSpotApp());
}

class JobSpotApp extends StatelessWidget {
  const JobSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobSpot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootPage(),
    );
  }
}

final supabase = Supabase.instance.client;

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _loading = true;
  Widget? _home;
  late StreamSubscription<AuthState> _authStateSubscription;
  Timer? _authCheckTimer;
  int _loginPageCheckCount = 0;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _setupAuthStateListener();
    _startPeriodicAuthCheck();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _authCheckTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicAuthCheck() {
    _authCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      final currentUser = supabase.auth.currentUser;
      if (_home is LoginScreen) {
        _loginPageCheckCount++;
      } else {
        _loginPageCheckCount = 0;
      }
      bool shouldLog =
          timer.tick % 20 == 0 ||
          (_loginPageCheckCount > 0 && _loginPageCheckCount % 6 == 0);
      if (shouldLog) {
        print(
          '🔄 Periodic auth check #${timer.tick} - User: ${currentUser?.email}',
        );
        print('🔄 Current home widget: ${_home.runtimeType}');
        if (_loginPageCheckCount > 0) {
          print(
            '🔄 Login page check count: $_loginPageCheckCount (${_loginPageCheckCount * 0.5}s on login)',
          );
        }
      }

      if (currentUser != null &&
          (_home is LoginScreen)) {
        print(
          '🔄 ⚡ OAUTH CALLBACK DETECTED: Found authenticated user on ${_home.runtimeType}',
        );
        print('🔄 ⚡ User: ${currentUser.email} (ID: ${currentUser.id})');
        print('🔄 ⚡ Provider: ${currentUser.appMetadata['provider']}');
        print('🔄 ⚡ Login page duration: ${_loginPageCheckCount * 0.5}s');
        print('🔄 ⚡ Immediately handling auth state to redirect user');
        _handleAuthStateChange(currentUser);
        if (_home is LoginScreen) {
          timer.cancel();
          _loginPageCheckCount = 0;
          print(
            '🔄 ⚡ Periodic check timer cancelled - user redirected from login',
          );
        }
      }
    });
  }

  void _setupAuthStateListener() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('🔐 Auth State Change: $event');
      print('🔐 Session User: ${session?.user.email}');
      print('🔐 Current home widget: ${_home.runtimeType}');
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        print('🔐 Processing signedIn event for user: ${session!.user.email}');
        print('🔐 User providers: ${session.user.appMetadata['providers']}');
        _handleAuthStateChange(session.user);
      } else if (event == AuthChangeEvent.tokenRefreshed &&
          session?.user != null) {
        print(
          '🔐 Processing tokenRefreshed event for user: ${session!.user.email}',
        );
        _handleAuthStateChange(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        print('🔐 User signed out, redirecting to login');
        _redirectToLogin();
      } else {
        print('🔐 Unhandled auth event: $event');
      }
    });
  }

  Future<void> _handleAuthStateChange(User user) async {
    try {
      print('🔍 ===== HANDLING AUTH STATE CHANGE =====');
      print('🔍 User: ${user.email} (ID: ${user.id})');

      final userProfile = await supabase
          .from('user_profiles')
          .select(
            'role, account_disable, profile_completed, name, custom_user_id, user_id, email, mobile_number, profile_picture',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      print('🔍 User profile found: ${userProfile != null}');

      if (userProfile == null) {
        print('🆕 New user detected - redirecting to role selection');
        _redirectToRoleSelection();
      } else {
        final isDisabled = userProfile['account_disable'] as bool? ?? false;
        if (isDisabled) {
          _redirectToUnableAccount(userProfile);
          return;
        }

        final isProfileCompleted =
            userProfile['profile_completed'] as bool? ?? false;
        final role = userProfile['role'];

        if (!isProfileCompleted || role == null) {
          _redirectToRoleSelection();
        } else {
          _redirectToDashboard(role);
        }
      }
    } catch (e) {
      print('❌ Error handling auth state change: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      setState(() {
        _home = const LoginScreen();
        _loading = false;
      });
    }
  }

  void _redirectToRoleSelection() {
    if (mounted) {
      setState(() {
        _home = const RoleSelectionScreen();
        _loading = false;
      });
    }
  }

  void _redirectToDashboard(String role) {
    if (mounted) {
      final userRole = UserRoleExtension.fromDbValue(role);
      if (userRole != null) {
        setState(() {
          _home = DashboardRouter(role: userRole);
          _loading = false;
        });
      } else {
        _redirectToRoleSelection();
      }
    }
  }

  void _redirectToUnableAccount(Map<String, dynamic> userProfile) {
    if (mounted) {
      setState(() {
        _home = UnableAccountPage(userProfile: userProfile);
        _loading = false;
      });
    }
  }

  Future<void> _checkSession() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      await _handleAuthStateChange(user);
    } else {
      _redirectToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _home!;
  }
}
