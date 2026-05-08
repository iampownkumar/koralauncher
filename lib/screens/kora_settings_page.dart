// Kora Settings Page — Offline AI management & app settings.
// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
// Last updated – 2026-04-28 14:00 IST

import 'package:flutter/material.dart';
import '../ai/offline_ai_engine.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';

class KoraSettingsPage extends StatefulWidget {
  const KoraSettingsPage({super.key});

  @override
  State<KoraSettingsPage> createState() => _KoraSettingsPageState();
}

class _KoraSettingsPageState extends State<KoraSettingsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final OfflineAIEngine _engine = OfflineAIEngine();
  final TextEditingController _promptController = TextEditingController();

  bool _isDefaultLauncher = false;
  bool _hasUsagePerm = false;
  bool _hasAccessPerm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine.init();
    _engine.addListener(_onEngineUpdate);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final isDefault = await NativeService.isDefaultLauncher();
    final hasUsage = await NativeService.hasUsagePermission();
    final hasAccess = await NativeService.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _isDefaultLauncher = isDefault;
        _hasUsagePerm = hasUsage;
        _hasAccessPerm = hasAccess;
      });
    }
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.removeListener(_onEngineUpdate);
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF050510), Color(0xFF080818)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Kora Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                background: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50, right: 20),
                        child: Icon(
                          Icons.settings_suggest_rounded,
                          size: 64,
                          color: Colors.cyanAccent.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('SYSTEM', Icons.phone_android),
                  _buildLauncherStatusCard(),
                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'PERMISSIONS',
                    Icons.admin_panel_settings,
                  ),
                  _buildPermissionsCard(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('AI ENGINE', Icons.psychology),
                  _buildAiStatusCard(),
                  const SizedBox(height: 16),
                  if (_engine.isDownloading ||
                      !_engine.isModelReady ||
                      _engine.isModelReady)
                    _buildModelManagementCard(),
                  const SizedBox(height: 16),
                  _buildPromptTemplatesCard(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('ABOUT', Icons.info_outline),
                  _buildAboutCard(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Launcher Status ──────────────────────────────────────────
  Widget _buildLauncherStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                (_isDefaultLauncher ? Colors.greenAccent : Colors.orangeAccent)
                    .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isDefaultLauncher ? Icons.home_filled : Icons.home_work_outlined,
            color: _isDefaultLauncher
                ? Colors.greenAccent
                : Colors.orangeAccent,
            size: 24,
          ),
        ),
        title: const Text(
          'Default Launcher',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _isDefaultLauncher
              ? 'Kora is your home app'
              : 'Tap to set Kora as default',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        trailing: _isDefaultLauncher
            ? const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 20,
              )
            : const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
        onTap: () async {
          if (!_isDefaultLauncher) {
            await NativeService.openDefaultLauncherSettings();
            await Future.delayed(const Duration(seconds: 1));
            _checkPermissions();
          }
        },
      ),
    );
  }

  // ── Permissions Card ──────────────────────────────────────────
  Widget _buildPermissionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildPermissionTile(
            'Usage Access',
            'Required for app limits and stats',
            _hasUsagePerm,
            () async {
              await NativeService.openUsageSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkPermissions();
            },
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          _buildPermissionTile(
            'Accessibility Service',
            'Required for gatekeeper interception',
            _hasAccessPerm,
            () async {
              await NativeService.openAccessibilitySettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkPermissions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String subtitle,
    bool isGranted,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isGranted ? Colors.greenAccent : Colors.redAccent).withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isGranted ? 'Granted' : 'Missing',
          style: TextStyle(
            color: isGranted ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: isGranted ? null : onTap,
    );
  }

  // ── AI Status Card ───────────────────────────────────────
  Widget _buildAiStatusCard() {
    final isReady = _engine.isModelReady;
    final isEnabled = StorageService.isOfflineAiEnabled();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isReady
              ? [
                  const Color(0xFF0D2818).withValues(alpha: 0.5),
                  const Color(0xFF0A1F14).withValues(alpha: 0.5),
                ]
              : [
                  const Color(0xFF1A1040).withValues(alpha: 0.5),
                  const Color(0xFF12122A).withValues(alpha: 0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.cyanAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isReady ? Colors.greenAccent : Colors.cyanAccent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isReady ? Icons.check_circle : Icons.psychology,
                  color: isReady ? Colors.greenAccent : Colors.cyanAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady ? 'AI Model Ready' : 'Offline AI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReady
                          ? 'On-device inference active'
                          : 'Download model to enable',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReady)
                Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.greenAccent,
                  onChanged: (val) async {
                    await StorageService.setOfflineAiEnabled(val);
                    setState(() {});
                  },
                ),
            ],
          ),
          if (_engine.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _engine.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Model Management Card ────────────────────────────────
  Widget _buildModelManagementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                color: Colors.cyanAccent,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Model Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_engine.isDownloading) ...[
            _buildProgressSection(),
            const SizedBox(height: 16),
          ],

          if (!_engine.isModelReady && !_engine.isDownloading)
            _buildDownloadButton()
          else if (_engine.isModelReady)
            _buildModelInfoSection(),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final pct = (_engine.downloadProgress * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading model…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _engine.downloadProgress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.memory, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Requires 4GB+ RAM. Download size: ${OfflineAIEngine.modelSize}',
                  style: TextStyle(color: Colors.amber, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '100% on-device. Your data never leaves your phone.',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _engine.downloadModel(),
            icon: const Icon(Icons.download, size: 18),
            label: Text(
              'Download ${OfflineAIEngine.modelDisplayName} (${OfflineAIEngine.modelSize})',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelInfoSection() {
    return Column(
      children: [
        _buildInfoRow(
          Icons.smart_toy_outlined,
          'Model',
          OfflineAIEngine.modelDisplayName,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.check_circle_outline,
          'Status',
          _engine.isModelLoaded
              ? 'Loaded & Running'
              : 'Downloaded (loading...)',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.shield_outlined, 'Privacy', '100% on-device'),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _testAI,
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Test AI Response'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
              side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove Model'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove AI Model?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete the downloaded model from your device. You can re-download it later.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _engine.deleteModel();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Prompt Templates Card ────────────────────────────────
  Widget _buildPromptTemplatesCard() {
    final prompts = StorageService.getOfflineAiPrompts();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high,
                color: Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Prompt Templates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showAddPromptDialog,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.amberAccent,
                  size: 22,
                ),
                tooltip: 'Add prompt',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Custom questions the AI can ask you at gates.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          if (prompts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No custom prompts yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...prompts.asMap().entries.map(
              (entry) => _buildPromptTile(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildPromptTile(int index, String prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prompt,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _deletePrompt(index),
            child: const Icon(Icons.close, color: Colors.white24, size: 18),
          ),
        ],
      ),
    );
  }

  void _showAddPromptDialog() {
    _promptController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Prompt Template',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _promptController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Is this app helping you right now?',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = _promptController.text.trim();
              if (text.isNotEmpty) {
                _addPrompt(text);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _addPrompt(String prompt) {
    final prompts = StorageService.getOfflineAiPrompts();
    prompts.add(prompt);
    StorageService.setOfflineAiPrompts(prompts);
    setState(() {});
  }

  void _deletePrompt(int index) {
    final prompts = StorageService.getOfflineAiPrompts();
    if (index < prompts.length) {
      prompts.removeAt(index);
      StorageService.setOfflineAiPrompts(prompts);
      setState(() {});
    }
  }

  void _testAI() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
    );

    final result = await _engine.testInference();

    if (!mounted) return;
    Navigator.pop(context); // dismiss spinner

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Test Response',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          result,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  // ── About Card ──────────────────────────────────────────────
  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.rocket_launch,
              color: Colors.cyanAccent,
              size: 24,
            ),
            title: const Text(
              'Kora Launcher',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Version 1.1.2+14',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
