import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  static StorageService get instance =>
      StorageService(Supabase.instance.client);

  /// Upload document file, returns public URL
  Future<String> uploadDocument(File file, String userId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$userId/$fileName';

    await _client.storage
        .from(AppConstants.documentsBucket)
        .upload(path, file);

    return _client.storage
        .from(AppConstants.documentsBucket)
        .createSignedUrl(path, 3600 * 24 * 7); // 7-day signed URL
  }

  /// Upload avatar image
  Future<String> uploadAvatar(File file, String userId) async {
    final ext = file.path.split('.').last;
    final path = '$userId/avatar.$ext';

    await _client.storage
        .from(AppConstants.avatarsBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage
        .from(AppConstants.avatarsBucket)
        .getPublicUrl(path);
  }

  /// Upload OCR image
  Future<String> uploadOcrImage(File file, String userId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final path = '$userId/$fileName';

    await _client.storage
        .from(AppConstants.ocrImagesBucket)
        .upload(path, file);

    return _client.storage
        .from(AppConstants.ocrImagesBucket)
        .createSignedUrl(path, 3600);
  }

  /// Upload generated PDF report
  Future<String> uploadReport(Uint8List pdfBytes, String userId, String scanId) async {
    final path = '$userId/report_$scanId.pdf';

    await _client.storage
        .from(AppConstants.reportsBucket)
        .uploadBinary(path, pdfBytes,
            fileOptions:
                const FileOptions(contentType: 'application/pdf', upsert: true));

    return _client.storage
        .from(AppConstants.reportsBucket)
        .createSignedUrl(path, 3600 * 24);
  }

  /// Delete a file
  Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
