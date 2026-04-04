import 'package:flutter/material.dart';

import '../services/native_service.dart';
import '../services/todo_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/rising_tide_service.dart';

import '../services/glass_settings_service.dart';
import '../wallpaper/wallpaper_service.dart';

class HomeController extends ChangeNotifier with WidgetsBindingObserver {
  bool showGoalSetter = false;
  bool isDefaultLauncher = true;
  bool hideDefaultLauncherBanner = false;
  bool hasUsagePermission = true;
  bool hasAccessibilityPermission = true;
  bool pulseIntention = false;
  String? goal;
  bool isInitialized = false;

  GlassTint currentTint = GlassTint.medium;
  String? wallpaperPath;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (state == AppLifecycleState.resumed) {
      refreshHomeState();
    }
  }

  Future<void> _loadInitialData() async {
    // main.dart already ran LauncherService.init(), UsageService.refreshUsage(), TodoService.init().
    // We only need to poll permissions and restore goal/onboarding state here.
    await refreshHomeState();

    if (!StorageService.hasCompletedOnboarding()) {
      showGoalSetter = true;
      notifyListeners();
    } else {
      _checkMorningGoalTrigger();
    }

    isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshHomeState() async {
    final isDefault = await NativeService.isDefaultLauncher();
    final hasUsage = await NativeService.hasUsagePermission();
    final hasAccessibility = await NativeService.hasAccessibilityPermission();
    await UsageService.refreshUsage();
    await TodoService.refreshTodos();
    final newGoal = StorageService.getDailyIntention();
    await RisingTideService.syncInterceptionState();
    final tint = await GlassSettingsService.getTintPreference();
    final wp = await WallpaperService.getSavedWallpaperPath();

    if (isDefaultLauncher != isDefault ||
        hasUsagePermission != hasUsage ||
        hasAccessibilityPermission != hasAccessibility ||
        goal != newGoal ||
        currentTint != tint ||
        wallpaperPath != wp) {
      isDefaultLauncher = isDefault;
      hasUsagePermission = hasUsage;
      hasAccessibilityPermission = hasAccessibility;
      goal = newGoal;
      currentTint = tint;
      wallpaperPath = wp;
      notifyListeners();
    }
  }

  void _checkMorningGoalTrigger() {
    final now = DateTime.now();
    if (now.hour >= 5 && now.hour < 10) {
      if (goal == null || goal!.isEmpty) {
        pulseIntention = true;
        notifyListeners();
      }
    }
  }

  void stopPulse() {
    if (pulseIntention) {
      pulseIntention = false;
      notifyListeners();
    }
  }

  void showGoalSetterOverlay() {
    showGoalSetter = true;
    notifyListeners();
  }

  void dismissGoalSetter() {
    showGoalSetter = false;
    notifyListeners();
  }

  void dismissDefaultLauncherBanner() {
    hideDefaultLauncherBanner = true;
    notifyListeners();
  }

  void onGoalSet() {
    showGoalSetter = false;
    goal = StorageService.getDailyIntention();
    notifyListeners();
  }

  void triggerRefresh() {
    notifyListeners();
  }
}
