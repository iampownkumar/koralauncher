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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await AppLockManager.init();
  await LauncherService.init();
  await UsageService.refreshUsage();
  await TodoService.init();
  
  await RisingTideService.syncInterceptionState();
  
  NativeService.initMethodCallHandler();

  runApp(const KoraLauncher());
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
      home: const HomeScreen(),
    );
  }
}
