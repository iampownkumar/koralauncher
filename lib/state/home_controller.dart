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
  bool isMandatoryIntention =
      false; // true when no intention has been set today
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
      isMandatoryIntention = true; // first-ever onboarding
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
    // Show the intention setter any time the user opens the launcher without
    // having set a goal today — time-of-day restriction removed.
    if (goal == null || goal!.isEmpty) {
      isMandatoryIntention = true;
      showGoalSetter = true;
      notifyListeners();
    }
  }

  void stopPulse() {
    if (pulseIntention) {
      pulseIntention = false;
      notifyListeners();
    }
  }

  void showGoalSetterOverlay() {
    // Edit mode — intention already exists so it’s not mandatory
    isMandatoryIntention = false;
    showGoalSetter = true;
    notifyListeners();
  }

  void dismissGoalSetter() {
    // Only callable in edit (non-mandatory) mode
    showGoalSetter = false;
    notifyListeners();
  }

  void dismissDefaultLauncherBanner() {
    hideDefaultLauncherBanner = true;
    notifyListeners();
  }

  void onGoalSet() {
    showGoalSetter = false;
    isMandatoryIntention = false;
    goal = StorageService.getDailyIntention();
    // Refresh todos so the new intention-linked todo appears on home screen
    TodoService.refreshTodos().then((_) => notifyListeners());
    notifyListeners();
  }

  void triggerRefresh() {
    goal = StorageService.getDailyIntention();
    notifyListeners();
  }
}
