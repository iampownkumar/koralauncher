import 'package:flutter/material.dart';
import '../services/native_service.dart';
import '../services/storage_service.dart';
import '../database/database_provider.dart';
import '../services/rising_tide_service.dart';
import 'accessibility_disclosure_sheet.dart';
import 'permission_widgets.dart';

/// 4-page onboarding: Welcome → Intention → Permissions → Done.
/// Call [OnboardingFlow.show] from main.dart when onboarding is not complete.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _page = PageController();
  int _currentPage = 0;

  // Page 2 – intention
  final _intentionCtrl = TextEditingController();

  // Page 3 – permissions state
  bool _isDefault = false;
  bool _hasUsage = false;
  bool _hasAccessibility = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  @override
  void dispose() {
    _page.dispose();
    _intentionCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    final d = await NativeService.isDefaultLauncher();
    final u = await NativeService.hasUsagePermission();
    final a = await NativeService.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _isDefault = d;
        _hasUsage = u;
        _hasAccessibility = a;
      });
    }
  }

  void _next() {
    if (_currentPage < 3) {
      _page.nextPage(
          duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
    }
  }

  void _goPage(int page) {
    _page.animateToPage(page,
        duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    await StorageService.completeOnboarding();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _WelcomePage(
                onContinue: _next,
                onSkip: _finish,
              ),
              _IntentionPage(
                controller: _intentionCtrl,
                onSave: () async {
                  final text = _intentionCtrl.text.trim();
                  if (text.isNotEmpty) {
                    await StorageService.setDailyIntention(text);
                    await db.saveIntention(text);
                    RisingTideService.invalidateIntentionCache();
                  }
                  _next();
                },
                onSkip: _next,
              ),
              _PermissionsPage(
                isDefault: _isDefault,
                hasUsage: _hasUsage,
                hasAccessibility: _hasAccessibility,
                onRefresh: _refreshPermissions,
                onContinue: () => _goPage(3),
                onSkip: _finish,
              ),
              _DonePage(onGo: _finish),
            ],
          ),

          // Page indicator dots (top-right, skip on Done page)
          if (_currentPage < 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: Row(
                children: List.generate(4, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 6),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.cyanAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Page 1: Welcome
// ─────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onContinue, required this.onSkip});
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / wordmark
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.waves, color: Colors.cyanAccent, size: 28),
            ),
            const SizedBox(height: 40),
            const Text(
              'Welcome to Kora',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A minimal launcher that helps you pause\nbefore distraction.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            _PrimaryButton('Continue', onContinue),
            const SizedBox(height: 12),
            _GhostButton('Skip setup', onSkip),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Page 2: Intention
// ─────────────────────────────────────────────────
class _IntentionPage extends StatelessWidget {
  const _IntentionPage({
    required this.controller,
    required this.onSave,
    required this.onSkip,
  });
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 28, right: 28, top: 48,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What matters today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set a small intention for today.\nYou can change this later.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: controller,
              autofocus: false,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSave(),
              decoration: InputDecoration(
                hintText: 'Finish the app update',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const Spacer(),
            _PrimaryButton('Save and continue', onSave),
            const SizedBox(height: 12),
            _GhostButton('Skip', onSkip),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Page 3: Permissions
// ─────────────────────────────────────────────────
class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.isDefault,
    required this.hasUsage,
    required this.hasAccessibility,
    required this.onRefresh,
    required this.onContinue,
    required this.onSkip,
  });
  final bool isDefault;
  final bool hasUsage;
  final bool hasAccessibility;
  final VoidCallback onRefresh;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 48, 28, 0),
            child: Text(
              'Optional setup',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
            child: Text(
              'Turn on the features you want.\nYou can change these anytime in Settings.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                PermissionStatusCard(
                  icon: Icons.home_outlined,
                  title: 'Make Kora your launcher',
                  description:
                      'Lets Kora become your home screen.',
                  isEnabled: isDefault,
                  actionLabel:
                      isDefault ? 'Active' : 'Open Home Settings',
                  onAction: isDefault
                      ? () {}
                      : () async {
                          await NativeService.openDefaultLauncherSettings();
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          onRefresh();
                        },
                ),
                PermissionStatusCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Enable Usage Access',
                  description:
                      'Used for screen time, app usage stats, and daily limits.',
                  isEnabled: hasUsage,
                  actionLabel:
                      hasUsage ? 'Active' : 'Open Usage Access',
                  onAction: hasUsage
                      ? () {}
                      : () async {
                          await NativeService.openUsageSettings();
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          onRefresh();
                        },
                ),
                PermissionStatusCard(
                  icon: Icons.security_outlined,
                  title: 'Enable Focus Protection',
                  description:
                      'Pauses before apps you mark for Rising Tide.',
                  isEnabled: hasAccessibility,
                  actionLabel: hasAccessibility ? 'Active' : 'Enable',
                  onAction: hasAccessibility
                      ? () {}
                      : () => AccessibilityDisclosureSheet.show(context)
                            .then((_) => onRefresh()),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: _PrimaryButton('Continue', onContinue),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
            child: _GhostButton('Finish later', onSkip),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Page 4: Done
// ─────────────────────────────────────────────────
class _DonePage extends StatelessWidget {
  const _DonePage({required this.onGo});
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.cyanAccent, size: 30),
            ),
            const SizedBox(height: 36),
            const Text(
              'Kora is ready.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start simple.\nYou can enable more controls anytime.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            _PrimaryButton('Go to Home', onGo),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Shared button styles
// ─────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
      ),
    );
  }
}
