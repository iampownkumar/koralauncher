/// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
/// Last updated – 2026-04-28 13:07 IST

import 'dart:async';
import '../models/rising_tide_stage.dart';
import '../services/usage_service.dart';
import '../services/rising_tide_service.dart';
import '../services/rising_tide_logger.dart';

class RisingTideController {
  final String packageName;
  final _stageController = StreamController<RisingTideStage>.broadcast();
  RisingTideStage _currentStage = RisingTideStage.whisper;

  RisingTideStage get currentStage => _currentStage;
  Stream<RisingTideStage> get stageStream => _stageController.stream;

  // Public method to advance to a specific stage (used by UI gates)
  Future<void> advanceToStage(RisingTideStage stage) async => _enterStage(stage);

  RisingTideController(this.packageName) {
    // Listen to usage percent updates (stubbed to a dummy stream for now)
    UsageService.usagePercentStream(packageName).listen(_handleUsage);
  }

  void _handleUsage(double percent) {
    if (_currentStage == RisingTideStage.whisper && percent >= 0.5) {
      _enterStage(RisingTideStage.dim);
    }
    // Additional logic for 100% will be handled elsewhere.
  }

  void _enterStage(RisingTideStage stage) async {
    _currentStage = stage;
    _stageController.add(stage);
    
    // Persist transition via Logger
    await RisingTideLogger.logTideEvent(
      packageName: packageName,
      eventType: 'stage_transition',
      detail: 'entered_${stage.name}',
      stage: stage,
    );
    
    await RisingTideService.syncInterceptionState();
  }

  Future<void> resetToWhisper() async => _enterStage(RisingTideStage.whisper);

  void dispose() => _stageController.close();
}
