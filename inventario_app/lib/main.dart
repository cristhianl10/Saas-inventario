import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/screens.dart';
import 'config/app_theme.dart';
import 'config/app_config.dart';
import 'config/tenant_service.dart';

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
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _emailVerified = false;
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
    ) async {
      if (!mounted) return;

      final event = data.event;
      final session = data.session;
      final user = session?.user;

      debugPrint(
        'Auth Event: $event, User: ${user?.email}, Confirmed: ${user?.emailConfirmedAt}',
      );

      if (event == AuthChangeEvent.signedOut || session == null) {
        TenantService.clearTenant();
        setState(() {
          _isAuthenticated = false;
          _emailVerified = false;
          _verifiedEmail = null;
          _isLoading = false;
        });
        return;
      }

      if (event == AuthChangeEvent.userUpdated && user != null) {
        if (user.emailConfirmedAt != null) {
          setState(() {
            _emailVerified = true;
            _verifiedEmail = user.email;
            _isAuthenticated = true;
          });
        }
      }

      if (user != null && user.emailConfirmedAt != null) {
        await TenantService.loadTenantConfig(user.id);
        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _emailVerified = true;
          _verifiedEmail = user.email;
          _isLoading = false;
        });
      } else if (user != null && user.emailConfirmedAt == null) {
        setState(() {
          _emailVerified = false;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await TenantService.loadTenantConfig(user.id);
      setState(() {
        _isAuthenticated = true;
        _emailVerified = user.emailConfirmedAt != null;
        _verifiedEmail = user.email;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _onAuthSuccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await TenantService.loadTenantConfig(user.id);
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  void _onEmailVerified(String email) {
    setState(() {
      _emailVerified = true;
      _verifiedEmail = email;
      _isAuthenticated = true;
    });
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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    if (_emailVerified && _verifiedEmail != null) {
      return EmailVerifiedScreen(
        email: _verifiedEmail!,
        onContinue: () {
          setState(() {
            _emailVerified = false;
          });
        },
      );
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    }

    return AuthScreen(
      onAuthSuccess: _onAuthSuccess,
      onEmailVerified: _onEmailVerified,
    );
  }
}
