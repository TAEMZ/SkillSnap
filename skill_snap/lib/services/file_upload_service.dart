import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadResult {
  final String? url;
  final bool isImage;
  final String name;

  FileUploadResult({
    required this.url,
    required this.isImage,
    required this.name,
  });
}

class FileUploadService {
  static final _client = Supabase.instance.client;
  static final _bucket = _client.storage.from('exchangefiles');

  static Future<FileUploadResult?> uploadFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    if (bytes == null) return null;

    await _bucket.uploadBinary(fileName, bytes);

    final url = _bucket.getPublicUrl(fileName);
    final ext = file.extension?.toLowerCase() ?? '';

    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    return FileUploadResult(url: url, isImage: isImage, name: file.name);
  }

  static Future<FileUploadResult?> uploadVoiceFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    final fileBytes = await file.readAsBytes();

    await _bucket.uploadBinary(fileName, fileBytes);

    final url = _bucket.getPublicUrl(fileName);

    return FileUploadResult(
      url: url,
      isImage: false,
      name: path.basename(file.path),
    );
  }
}
