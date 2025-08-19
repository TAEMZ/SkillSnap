import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceRecorderService {
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentPath;
  static DateTime? _startTime;

  static Future<bool> startRecording() async {
    if (_isRecording) return false;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startTime = DateTime.now();

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentPath!, // Add ! to assert non-null
      );
      _isRecording = true;
      return true;
    } catch (e) {
      _currentPath = null;
      _startTime = null;
      return false;
    }
  }

  static Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      final duration = DateTime.now().difference(_startTime!);
      _isRecording = false;

      if (path != null && duration.inSeconds > 0) {
        return VoiceRecordingResult(path: path, duration: duration);
      }
      return null;
    } finally {
      _currentPath = null;
      _startTime = null;
    }
  }

  static Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _isRecording = false;
    _currentPath = null;
    _startTime = null;
  }
}

class VoiceRecordingResult {
  final String path;
  final Duration duration;

  VoiceRecordingResult({required this.path, required this.duration});
}
