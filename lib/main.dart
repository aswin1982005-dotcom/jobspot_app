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
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:jobspot_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SeekerHomeProvider()),
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
  bool _videoComplete = false;
  bool _showSplash = true;
  Widget? _home;
  Widget? _pendingHome;
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

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // Initialize OneSignal
    _initOneSignal();

    final session = supabase.auth.currentSession;

    if (session == null) {
      _updateHome(const LoginScreen());
    } else {
      _handleUser(session.user);
      // Link OneSignal User
      OneSignal.login(session.user.id);
    }

    _authSub = supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user != null) {
        _handleUser(user);
        OneSignal.login(user.id);
      } else {
        OneSignal.logout();
        _updateHome(const LoginScreen());
      }
    }, onError: (_) => _updateHome(const LoginScreen()));
  }

  Future<void> _initOneSignal() async {
    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null) {
      debugPrint("ONESIGNAL_APP_ID not found in .env");
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(appId);

      // Request permission
      OneSignal.Notifications.requestPermission(true);

      // Handler for notification clicks
      OneSignal.Notifications.addClickListener((event) {
        debugPrint(
          "NOTIFICATION CLICKED: ${event.notification.jsonRepresentation()}",
        );
        // Refresh notifications when user opens app via notification
        final context = navigatorKey.currentContext;
        if (context != null) {
          Provider.of<NotificationProvider>(context, listen: false).refresh();
        }
      });

      // Handler for foreground notifications
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
          "FOREGROUND NOTIFICATION RECEIVED: ${event.notification.title}",
        );
        // Refresh notifications immediately
        final context = navigatorKey.currentContext;
        if (context != null) {
          Provider.of<NotificationProvider>(context, listen: false).refresh();
        }

        // Show the alert (default behavior is to show it, but explicit confirm is good)
        event.preventDefault();
        event.notification.display();
      });
    } catch (e) {
      debugPrint("Error initializing OneSignal: $e");
    }
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

      // Preload data if seeker
      if (role == UserRole.seeker && mounted) {
        Provider.of<SeekerHomeProvider>(context, listen: false).loadData();
      }

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
    _pendingHome = screen;
    _attemptNavigation();
  }

  void _attemptNavigation() {
    // If splash cycle is done (video done AND we have a destination)
    // Or if we are already running (splash done) and just updating home
    if ((_videoComplete && _pendingHome != null) ||
        (!_showSplash && _pendingHome != null)) {
      setState(() {
        _home = _pendingHome;
        _loading = false;
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinish: () {
          _videoComplete = true;
          _attemptNavigation();
        },
      );
    }

    // Normal loading state (after splash)
    if (_loading || _home == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    return _home!;
  }
}
