import 'package:flutter/material.dart';
import 'app_navigator.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/launcher_service.dart';
import 'services/usage_service.dart';
import 'services/rising_tide_service.dart';
import 'services/app_lock_manager.dart';
import 'services/native_service.dart';
import 'services/todo_service.dart';
import 'widgets/onboarding_flow.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint("FlutterError: ${details.exceptionAsString()}");
  };

  debugPrint("KoraLauncher: Starting minimal shell...");
  runApp(const KoraStartupShell());
}

class KoraStartupShell extends StatefulWidget {
  const KoraStartupShell({super.key});

  @override
  State<KoraStartupShell> createState() => _KoraStartupShellState();
}

class _KoraStartupShellState extends State<KoraStartupShell> {
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _hydrateData();
  }

  Future<void> _hydrateData() async {
    try {
      debugPrint("KoraLauncher: Hydrating data...");
      await StorageService.init();
      await AppLockManager.init();
      await LauncherService.init();
      await UsageService.refreshUsage();
      await TodoService.init();

      await RisingTideService.syncInterceptionState();

      NativeService.initMethodCallHandler();

      debugPrint("KoraLauncher: Hydration complete. Launching main app.");
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("KoraLauncher Initialization Error: $e\n$stack");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "Startup Error: $_errorMessage\n\nTap refresh to retry.",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _hasError = false;
              });
              _hydrateData();
            },
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(), // Pure black minimal shell
        ),
      );
    }

    return const KoraLauncher();
  }
}

class KoraLauncher extends StatelessWidget {
  const KoraLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kora Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      home: StorageService.hasCompletedOnboarding()
          ? const HomeScreen()
          : _OnboardingGate(),
    );
  }
}

/// Shows onboarding on first launch, then replaces itself with HomeScreen.
class _OnboardingGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OnboardingFlow(
      onComplete: () {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim1, anim2) => const HomeScreen(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
    );
  }
}
