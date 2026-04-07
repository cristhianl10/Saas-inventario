import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/tenant_service.dart';
import 'services/terms_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> _ensureTenantExists(String userId) async {
  try {
    final existing = await Supabase.instance.client
        .from('tenant_config')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      final config = {
        'app_name': 'StockFlow',
        'brand_name': 'Mi Negocio',
        'logo_path': 'assets/logos/logo_default.png',
        'primary_color': '#C1356F',
        'secondary_color': '#597FA9',
        'accent_color': '#E57836',
        'background_color': '#FBF8F1',
      };

      await Supabase.instance.client.from('tenant_config').insert({
        'user_id': userId,
        'config': config,
      });

      await Supabase.instance.client.from('user_terms').insert({
        'user_id': userId,
        'terms_version': TermsService.currentVersion,
        'accepted_at': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    debugPrint('Error ensuring tenant exists: $e');
  }
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const InventarioApp());
}

class InventarioApp extends StatefulWidget {
  const InventarioApp({super.key});

  @override
  State<InventarioApp> createState() => _InventarioAppState();
}

class _InventarioAppState extends State<InventarioApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _showOnboarding = false;
  String? _verifiedEmail;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _listenAuthChanges();
    await _checkAuth();
  }

  void _listenAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      debugPrint('Auth state changed: ${data.event}');
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut || session == null) {
        debugPrint('User signed out');
        TenantService.clearTenant();
        setState(() {
          _isAuthenticated = false;
          _verifiedEmail = null;
          _isLoading = false;
        });
        return;
      }

      final user = session.user;
      if (user != null) {
        debugPrint('User signed in: ${user.email}');
        _onUserLoggedIn(user);
      }
    });
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _onUserLoggedIn(user);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onUserLoggedIn(User user) async {
    debugPrint('_onUserLoggedIn called for: ${user.email}');
    try {
      await _ensureTenantExists(user.id);
      await TenantService.loadTenantConfig(user.id);
      await TermsService.needsToAcceptNewTerms(user.id);

      final prefs = await SharedPreferences.getInstance();
      final onboardingShown = prefs.getBool('onboarding_shown') ?? false;

      if (mounted) {
        setState(() {
          _showOnboarding = !onboardingShown;
        });
      }
    } catch (e) {
      debugPrint('Error loading user config: $e');
    }

    if (mounted) {
      debugPrint('Setting _isAuthenticated = true');
      setState(() {
        _isAuthenticated = true;
        _verifiedEmail = user.email;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  void _onAuthSuccess() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _onUserLoggedIn(user);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: currentMode,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConfig.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(color: AppConfig.primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      if (_showOnboarding) {
        return OnboardingScreen(onComplete: _completeOnboarding);
      }
      return const HomeScreen();
    }

    return AuthScreen(onAuthSuccess: _onAuthSuccess, onEmailVerified: (_) {});
  }
}
