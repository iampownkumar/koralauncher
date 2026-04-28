/// Offline AI Engine — Downloads and manages the on-device AI model.
/// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
/// Last updated – 2026-04-28 14:00 IST

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';

class OfflineAIEngine extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────
  static final OfflineAIEngine _instance = OfflineAIEngine._internal();
  factory OfflineAIEngine() => _instance;
  OfflineAIEngine._internal();

  // ── Model config ───────────────────────────────────────────
  // Using a publicly accessible small TFLite model for demonstration.
  // In production, replace with your own hosted model URL.
  static const String modelUrl =
      'https://storage.googleapis.com/mediapipe-models/text_classifier/bert_classifier/float32/1/bert_classifier.tflite';
  static const String _modelFileName = 'kora_ai_model.tflite';

  // ── State ──────────────────────────────────────────────────
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelReady = false;
  String? _modelPath;
  String? _errorMessage;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelReady => _isModelReady;
  String? get modelPath => _modelPath;
  String? get errorMessage => _errorMessage;

  // ── Initialize — check if model already exists ─────────────
  Future<void> init() async {
    final savedPath = StorageService.getOfflineAiModelPath();
    if (savedPath != null && await File(savedPath).exists()) {
      _modelPath = savedPath;
      _isModelReady = true;
      debugPrint('OfflineAI: Model found at $savedPath');
    } else {
      _isModelReady = false;
      _modelPath = null;
      debugPrint('OfflineAI: No model found on disk.');
    }
    notifyListeners();
  }

  // ── Download the model ─────────────────────────────────────
  Future<void> downloadModel() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$_modelFileName';
      final file = File(filePath);

      debugPrint('OfflineAI: Starting download from $modelUrl');

      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw HttpException('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? -1;
      int receivedBytes = 0;
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress = receivedBytes / totalBytes;
          } else {
            // Unknown size — show indeterminate-ish progress
            _downloadProgress = (receivedBytes / (50 * 1024 * 1024)).clamp(0.0, 0.95);
          }
          notifyListeners();
        },
        onDone: () async {
          await sink.close();
        },
        onError: (e) async {
          await sink.close();
          throw e;
        },
        cancelOnError: true,
      ).asFuture();

      // Persist
      await StorageService.setOfflineAiModelPath(filePath);
      await StorageService.setOfflineAiEnabled(true);

      _modelPath = filePath;
      _isModelReady = true;
      _downloadProgress = 1.0;
      _isDownloading = false;
      debugPrint('OfflineAI: Download complete → $filePath');
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _errorMessage = e.toString();
      debugPrint('OfflineAI: Download error — $e');
      notifyListeners();
    }
  }

  // ── Delete model from disk ─────────────────────────────────
  Future<void> deleteModel() async {
    if (_modelPath != null) {
      final file = File(_modelPath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('OfflineAI: Model deleted from $_modelPath');
      }
    }
    await StorageService.clearOfflineAiModelPath();
    await StorageService.setOfflineAiEnabled(false);
    _modelPath = null;
    _isModelReady = false;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  // ── Stub inference — returns a context-aware prompt ────────
  Future<String> generateAnswer(Map<String, dynamic> context) async {
    if (!_isModelReady) {
      return 'AI model not ready. Please download it first.';
    }

    // Simulated inference delay
    await Future.delayed(const Duration(milliseconds: 800));

    final package = context['packageName'] ?? 'this app';
    final intention = context['todayIntention'] ?? 'your goal';
    final mood = context['mood'] ?? 'neutral';

    // In production, this would call tflite_flutter for real inference.
    return 'You\'re about to open $package while feeling $mood. '
        'Does this align with "$intention"?';
  }
}
