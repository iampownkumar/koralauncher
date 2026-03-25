import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/launcher_service.dart';
import 'services/usage_service.dart';

// Fix — remove that line entirely, the lazy getter handles it
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await LauncherService.init();
  await UsageService.refreshUsage();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kora Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
