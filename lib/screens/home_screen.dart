import 'package:flutter/material.dart';
import 'dart:io';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../services/storage_service.dart';
import '../services/todo_service.dart';
import 'app_drawer_screen.dart';
import '../widgets/goal_setter.dart';
import 'todo_screen.dart';
import 'usage_dashboard_screen.dart';
import 'tide_pool_screen.dart';
import 'permissions_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../wallpaper/wallpaper_service.dart';
import 'kora_settings_page.dart';

import 'package:upgrader/upgrader.dart';
import 'package:intl/intl.dart';
import '../state/home_controller.dart';
import '../widgets/home_banners.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAppDrawer() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppDrawerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      // Lightweight: only re-reads goal from storage.
      // The full heavy refresh (permissions, usage, etc.) is already
      // handled by the HomeController's lifecycle observer on resume.
      _controller.triggerRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                if (_controller.wallpaperPath != null)
                  Positioned.fill(
                    child: Image.file(
                      File(_controller.wallpaperPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onLongPress: () {
                    WallpaperService.openWallpaperPicker();
                  },
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < -300) {
                      _openAppDrawer();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity;
                    if (velocity != null) {
                      if (velocity > 300) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const TidePoolScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        ).then((_) => _controller.triggerRefresh());
                      } else if (velocity < -300) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const TodoScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        ).then((_) => _controller.triggerRefresh());
                      }
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height:
                              MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top -
                              MediaQuery.of(context).padding.bottom,
                          child: Column(
                            children: [
                              HomeBanners(controller: _controller),
                              if (StorageService.hasCompletedOnboarding() &&
                                  !_controller.isDefaultLauncher &&
                                  !_controller.hideDefaultLauncherBanner)
                                _buildDefaultLauncherBanner(),
                              _buildTopInfoBar(),

                              const SizedBox(height: 16),

                              if (!_controller.showGoalSetter) ...[
                                _buildTinyTodoChip(),
                              ],

                              const Spacer(flex: 3),

                              _buildTimeAndDate(),
                              const SizedBox(
                                height: 20,
                              ), //change here for space the time  widget

                              _buildQuickAccessDock(),
                              const SizedBox(height: 7),

                              _buildSwipeHint(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_controller.showGoalSetter)
                  GoalSetter(
                    initialGoal: _controller.goal,
                    onDismiss: _controller.dismissGoalSetter,
                    isMandatory: _controller.isMandatoryIntention,
                    onGoalSet: _controller.onGoalSet,
                  ),

                UpgradeAlert(
                  showIgnore: false,
                  showLater: true,
                  dialogStyle: UpgradeDialogStyle.material,
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTinyTodoChip() {
    final todos = TodoService.todos;
    final pending = todos.where((t) => !t.isCompleted).toList();
    final topTask = pending.isNotEmpty ? pending.first.title : null;
    final count = pending.length;

    if (count == 0 && todos.isEmpty) {
      return GestureDetector(
        onTap: () => _showQuickTodoSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                'Add a task',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'All done! 🎉',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showQuickTodoSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle_outlined, color: Colors.cyanAccent.withOpacity(0.7), size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                topTask ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (count > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${count - 1}',
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickTodoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuickTodoSheet(
        onChanged: () {
          _controller.triggerRefresh();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Widget _buildDefaultLauncherBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Set Kora as default launcher to keep it as your home screen.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => NativeService.openDefaultLauncherSettings(),
            child: const Text(
              'Set now',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _controller.dismissDefaultLauncherBanner(),
            child: const Icon(Icons.close, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAndDate() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Column(
          children: [
            Text(
              DateFormat('HH:mm:ss').format(now), // to add seconds
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(now).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeHint() {
    return GestureDetector(
      onTap: _openAppDrawer,
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PermissionsAndPrivacyScreen(),
          ),
        ).then((_) => _controller.refreshHomeState());
      },
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard_arrow_up, color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildWideIntentionPill()),
          const SizedBox(width: 12),
          _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildWideIntentionPill() {
    final String? goalStr = _controller.goal;
    final hasGoal = goalStr != null && goalStr.isNotEmpty;

    Widget pillContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag,
            size: 16,
            color: hasGoal ? Colors.white : Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasGoal ? goalStr : "Set a daily goal",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasGoal
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (_controller.pulseIntention && !hasGoal) {
      pillContent = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutSine,
        builder: (context, val, child) {
          return Opacity(opacity: val, child: child!);
        },
        onEnd: () {
          _controller.stopPulse();
        },
        child: pillContent,
      );
    }

    return GestureDetector(
      onTap: () {
        _controller.stopPulse();
        _controller.showGoalSetterOverlay();
      },
      child: pillContent,
    );
  }

  Widget _buildUsageStats() {
    final hasPermission = _controller.hasUsagePermission;
    final totalUsage = UsageService.getVisibleTotalUsage(minRoundedMinutes: 1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const UsageDashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ).then((_) => _controller.triggerRefresh());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: hasPermission
              ? Colors.black.withOpacity(0.3)
              : Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasPermission
                ? Colors.white.withOpacity(0.2)
                : Colors.redAccent.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasPermission ? Icons.bar_chart : Icons.warning_amber_rounded,
              size: 16,
              color: hasPermission ? Colors.white : Colors.red[200],
            ),
            const SizedBox(width: 6),
            Text(
              hasPermission ? UsageService.formatDuration(totalUsage) : "?",
              style: TextStyle(
                color: hasPermission ? Colors.white : Colors.red[100],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildShortcutIcon(
            icon: Icons.phone,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.DIAL',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.message,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_MESSAGING',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.language, // Browser
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_BROWSER',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.camera_alt,
            onTap: () => const AndroidIntent(
              action: 'android.media.action.STILL_IMAGE_CAMERA',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.image_outlined,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_GALLERY',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.settings_outlined,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const KoraSettingsPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              ).then((_) => _controller.refreshHomeState());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Quick Todo Bottom Sheet — compact task manager from home
// ─────────────────────────────────────────────────
class _QuickTodoSheet extends StatefulWidget {
  const _QuickTodoSheet({required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<_QuickTodoSheet> createState() => _QuickTodoSheetState();
}

class _QuickTodoSheetState extends State<_QuickTodoSheet> {
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    await TodoService.addTodo(text);
    _addController.clear();
    widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final todos = TodoService.todos;
    final pending = todos.where((t) => !t.isCompleted).toList();
    final completed = todos.where((t) => t.isCompleted).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Tasks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pending.length} left',
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (c, a, s) => const TodoScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        ).then((_) => widget.onChanged());
                      },
                      child: Text(
                        'Full view',
                        style: TextStyle(
                          color: Colors.cyanAccent.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Quick add field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        focusNode: _addFocusNode,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTask(),
                        decoration: InputDecoration(
                          hintText: 'Add a task...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addTask,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add,
                            color: Colors.cyanAccent, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Task list
              if (todos.isNotEmpty)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      // Pending tasks first
                      ...pending.map((todo) => _buildTodoRow(todo, false)),
                      // Completed tasks (dimmed)
                      ...completed.map((todo) => _buildTodoRow(todo, true)),
                    ],
                  ),
                ),
              if (todos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No tasks yet. Type above to add one.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoRow(dynamic todo, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () async {
          await TodoService.toggleTodo(todo.id);
          widget.onChanged();
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? Colors.cyanAccent.withOpacity(0.5)
                    : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
