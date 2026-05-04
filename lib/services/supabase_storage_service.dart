import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseStorageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static String get _bucket => dotenv.env['SUPABASE_BUCKET'] ?? 'Rayen-Bucket';

  static Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final ext = path.extension(file.path);
    final filePath = 'avatars/$uid$ext';

    await _client.storage
        .from(_bucket)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from(_bucket).getPublicUrl(filePath);

    return url;
  }

  static Future<String> uploadCoursePdf({
    required String courseId,
    required File file,
  }) async {
    final ext = path.extension(file.path);
    final filePath = 'course-pdfs/$courseId$ext';
    await _client.storage
        .from(_bucket)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from(_bucket).getPublicUrl(filePath);
  }

  static Future<String> uploadCourseVideo({
    required String courseId,
    required String lessonId,
    required File file,
  }) async {
    final ext = path.extension(file.path);
    final filePath = 'course-videos/$courseId/$lessonId$ext';
    await _client.storage
        .from(_bucket)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from(_bucket).getPublicUrl(filePath);
  }

  static Future<String> uploadCertificatePdf({
    required String userId,
    required String courseId,
    required Uint8List bytes,
  }) async {
    final filePath = 'certificates/${userId}_$courseId.pdf';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(filePath);
  }
}
