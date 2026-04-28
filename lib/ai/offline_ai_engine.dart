/// Offline AI Engine — Downloads, manages, and runs the on-device AI model.
/// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
/// Last updated – 2026-04-28 14:30 IST
///
/// Privacy guarantee: ALL inference runs 100% on-device.
/// No data ever leaves the phone after the initial model download.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';

class OfflineAIEngine extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────
  static final OfflineAIEngine _instance = OfflineAIEngine._internal();
  factory OfflineAIEngine() => _instance;
  OfflineAIEngine._internal();

  // ── Native bridge ──────────────────────────────────────────
  static const _channel = MethodChannel('org.korelium.koralauncher/gemma');

  // ── Model config ───────────────────────────────────────────
  // Gemma 2B int4 quantized model (~1.3 GB)
  // Hosted publicly — download once, runs forever on-device.
  static const String modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1B-it-int4.task';
  static const String _modelFileName = 'gemma3-1b-it-int4.task';
  static const String modelDisplayName = 'Gemma 3 1B IT (int4)';
  static const String modelSize = '~550 MB';

  // ── State ──────────────────────────────────────────────────
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelReady = false;
  bool _isModelLoaded = false;
  String? _modelPath;
  String? _errorMessage;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelReady => _isModelReady;
  bool get isModelLoaded => _isModelLoaded;
  String? get modelPath => _modelPath;
  String? get errorMessage => _errorMessage;

  // ── Initialize — check if model exists & load it ───────────
  Future<void> init() async {
    // Check 1: Previously downloaded/copied model in prefs
    final savedPath = StorageService.getOfflineAiModelPath();
    if (savedPath != null && await File(savedPath).exists()) {
      _modelPath = savedPath;
      _isModelReady = true;
      debugPrint('OfflineAI: Model found at $savedPath');
    }

    // Check 2: Try to copy from ADB push location via native code
    // (Dart can't read /data/local/tmp due to sandboxing, but native Kotlin can)
    if (!_isModelReady) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final targetPath = '${dir.path}/$_modelFileName';
        final copied = await _channel.invokeMethod<bool>('copyModelFromAdb', {
          'adbPath': '/data/local/tmp/llm/$_modelFileName',
          'targetPath': targetPath,
        });
        if (copied == true && await File(targetPath).exists()) {
          _modelPath = targetPath;
          _isModelReady = true;
          await StorageService.setOfflineAiModelPath(targetPath);
          await StorageService.setOfflineAiEnabled(true);
          debugPrint('OfflineAI: Copied model from ADB push → $targetPath');
        }
      } catch (e) {
        debugPrint('OfflineAI: ADB copy not available: $e');
      }
    }

    if (!_isModelReady) {
      debugPrint('OfflineAI: No model found on disk.');
    }

    // Model will be loaded lazily on first inference request
    // to avoid native crashes during app startup.
    notifyListeners();
  }

  // ── Load model into native inference engine ────────────────
  Future<bool> _loadModelNative() async {
    if (_modelPath == null) return false;
    try {
      debugPrint('OfflineAI: Loading model into native engine...');
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': _modelPath,
      });
      _isModelLoaded = result == true;
      debugPrint('OfflineAI: Model loaded = $_isModelLoaded');
      notifyListeners();
      return _isModelLoaded;
    } catch (e) {
      debugPrint('OfflineAI: Failed to load model natively: $e');
      _errorMessage = 'Failed to load model: $e';
      _isModelLoaded = false;
      notifyListeners();
      return false;
    }
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

      await response.stream
          .listen(
            (chunk) {
              sink.add(chunk);
              receivedBytes += chunk.length;
              if (totalBytes > 0) {
                _downloadProgress = receivedBytes / totalBytes;
              } else {
                _downloadProgress = (receivedBytes / (550 * 1024 * 1024)).clamp(
                  0.0,
                  0.95,
                );
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
          )
          .asFuture();

      // Persist
      await StorageService.setOfflineAiModelPath(filePath);
      await StorageService.setOfflineAiEnabled(true);

      _modelPath = filePath;
      _isModelReady = true;
      _downloadProgress = 1.0;
      _isDownloading = false;
      debugPrint('OfflineAI: Download complete → $filePath');

      // Auto-load the model after download
      await _loadModelNative();

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
    // Unload from native engine first
    try {
      await _channel.invokeMethod('unloadModel');
    } catch (_) {}
    _isModelLoaded = false;

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

  // ── Generate AI response — real on-device inference ────────
  /// Returns an AI-generated response, or null if inference fails/times out.
  /// The caller should fall back to templates when this returns null.
  Future<String?> generateAnswer(Map<String, dynamic> context) async {
    if (!_isModelReady) return null;

    // Ensure model is loaded
    if (!_isModelLoaded) {
      final loaded = await _loadModelNative();
      if (!loaded) return null;
    }

    try {
      // Build the Gemma chat prompt
      final prompt = _buildGemmaPrompt(context);

      // Run inference with a 3-second timeout — fall back to templates if slow
      final result = await _channel
          .invokeMethod<String>('generate', {'prompt': prompt})
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('OfflineAI: Inference timed out (>3s), falling back');
              return null;
            },
          );

      if (result != null && result.trim().isNotEmpty) {
        debugPrint('OfflineAI: Generated response (${result.length} chars)');
        return result.trim();
      }
      return null;
    } catch (e) {
      debugPrint('OfflineAI: Inference error — $e');
      return null;
    }
  }

  // ── Build Gemma-compatible prompt ──────────────────────────
  String _buildGemmaPrompt(Map<String, dynamic> context) {
    final appName = context['appName'] ?? 'this app';
    final intention = context['todayIntention'] ?? 'not set';
    final minutes = context['minutesToday'] ?? 0;
    final limit = context['limitMinutes'] ?? 10;
    final opens = context['opensToday'] ?? 0;
    final time = context['currentTime'] ?? '';
    final mood = context['mood'] ?? '';

    return '''<start_of_turn>user
You are Kora, a calm inner voice. Write ONE short question (max 20 words) to help someone decide if opening $appName right now is the right choice.

Facts: Used ${minutes}m of ${limit}m limit today. Opened $opens times. Time: $time. Goal: "$intention". ${mood.isNotEmpty ? 'Feeling: $mood.' : ''}

Rules: No lecturing. No emojis. Be gentle, factual, varied. Sometimes wry, sometimes warm.
<end_of_turn>
<start_of_turn>model
''';
  }

  // ── Test inference (for settings page) ─────────────────────
  Future<String> testInference() async {
    final result = await generateAnswer({
      'appName': 'Instagram',
      'todayIntention': 'finish my project',
      'minutesToday': 25,
      'limitMinutes': 30,
      'opensToday': 5,
      'currentTime': '2:30 PM',
      'mood': 'focused',
    });
    return result ??
        'Model returned no response. Template fallback will be used.';
  }
}
