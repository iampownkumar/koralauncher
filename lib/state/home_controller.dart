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

  /// Guards against concurrent refreshHomeState calls.  When the drawer is
  /// dismissed by the Home button, both the lifecycle observer (resumed) and
  /// the Navigator .then() callback fire within the same frame, causing two
  /// heavy refresh passes to run simultaneously.  This flag collapses them.
  bool _refreshInFlight = false;

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
      // Wait for pop animations to finish before doing any heavy work.
      // The Home gesture sequence is: paused → resumed → onNewIntent,
      // and the popUntil animation takes ~300ms.  We schedule the refresh
      // well after that so it never competes with rendering.
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshHomeState();
      });
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
    // Collapse concurrent invocations — the second call becomes a no-op
    // while the first is still executing.
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    try {
      // Run the three independent permission checks concurrently instead of
      // sequentially.  This halves the wall-clock time of the refresh.
      final permissionFutures = [
        NativeService.isDefaultLauncher(),
        NativeService.hasUsagePermission(),
        NativeService.hasAccessibilityPermission(),
      ];
      final results = await Future.wait(permissionFutures);
      final isDefault = results[0];
      final hasUsage = results[1];
      final hasAccessibility = results[2];

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
    } finally {
      _refreshInFlight = false;
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
