import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/screens.dart';
import 'config/app_theme.dart';
import 'config/app_config.dart';
import 'config/tenant_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenAuthChanges();
    _checkAuth();
  }

  void _listenAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut || session == null) {
        TenantService.clearTenant();
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
        return;
      }

      final user = session.user;
      await TenantService.loadTenantConfig(user.id);
      if (!mounted) return;
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    });
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await TenantService.loadTenantConfig(user.id);
      setState(() {
        _isAuthenticated = true;
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
    }
    setState(() {
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
          home: _isLoading
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _isAuthenticated
                  ? const HomeScreen()
                  : AuthScreen(onAuthSuccess: _onAuthSuccess),
        );
      },
    );
  }
}
