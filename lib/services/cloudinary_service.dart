import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';

/// Cloudinary upload service — M3 owns this file.
/// Replaces Firebase Storage for shop logo and banner uploads.
///
/// ⚠️  TEAM NOTE (AGENTS.md §10): This file requires the `http` package.
/// Add to pubspec.yaml and announce in group chat before merging:
///   http: ^1.2.1
///
/// Cloudinary config — set these in your .env or a constants file.
/// Never commit real credentials to git.
/// For now: add to lib/core/constants/cloudinary_config.dart (not tracked by git).
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  // ── Config ─────────────────────────────────────────────────────────────
  // Replace these with your actual Cloudinary cloud name and upload preset.
  // Upload preset must be set to "Unsigned" in your Cloudinary dashboard
  // (Settings → Upload → Upload presets → Add preset → Signing mode: Unsigned).
  static const String _cloudName = 'ds2tg7hco'; // User's Cloud Name
  static const String _uploadPreset = 'imageandvideo'; // Unsigned upload preset
  static const String _folder = 'sela_market/shops';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  static String get _uploadVideoUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload';

  // ── Public API ────────────────────────────────────────────────────────

  /// Compresses [file] and uploads it to Cloudinary.
  /// [publicId] becomes the file path inside your Cloudinary media library,
  /// e.g. "sela_market/shops/{shopId}/logo"
  /// Returns the secure HTTPS URL of the uploaded image.
  Future<String> uploadImage({
    required File file,
    required String publicId,
    int quality = 80,
  }) async {
    try {
      // ── Step 1: compress before uploading ──────────────────────────
      final compressed = await _compress(file, quality: quality);

      // ── Step 2: build multipart request ───────────────────────────
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = '$_folder/$publicId'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            compressed.path,
            // MIME type inferred from extension — jpg is always safe here
          ),
        );

      // ── Step 3: send & parse ──────────────────────────────────────
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        debugPrint(
          '[CloudinaryService.uploadImage] HTTP ${response.statusCode}: ${response.body}',
        );
        throw CloudinaryException(
          'Upload failed with status ${response.statusCode}',
          response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw const CloudinaryException(
          'No secure_url in Cloudinary response',
          0,
        );
      }

      debugPrint('[CloudinaryService.uploadImage] Uploaded: $secureUrl');
      return secureUrl;
    } on CloudinaryException {
      rethrow;
    } catch (e) {
      debugPrint('[CloudinaryService.uploadImage] Unexpected error: $e');
      throw CloudinaryException('Unexpected upload error: $e', 0);
    }
  }

  /// Convenience: upload a shop logo.
  /// publicId format: {shopId}/logo  →  stored as sela_market/shops/{shopId}/logo
  Future<String> uploadLogo(String shopId, File file) =>
      uploadImage(file: file, publicId: '$shopId/logo', quality: 85);

  /// Convenience: upload a shop banner.
  Future<String> uploadBanner(String shopId, File file) =>
      uploadImage(file: file, publicId: '$shopId/banner', quality: 80);

  /// Uploads a video to Cloudinary.
  /// publicId format: {shopId}/videos/{timestamp}
  Future<String> uploadVideo(String shopId, File file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final request = http.MultipartRequest('POST', Uri.parse(_uploadVideoUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = '$_folder/$shopId/videos/$timestamp'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        debugPrint(
          '[CloudinaryService.uploadVideo] HTTP ${response.statusCode}: ${response.body}',
        );
        throw CloudinaryException(
          'Upload failed with status ${response.statusCode}',
          response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw const CloudinaryException(
          'No secure_url in Cloudinary response',
          0,
        );
      }

      debugPrint('[CloudinaryService.uploadVideo] Uploaded: $secureUrl');
      return secureUrl;
    } on CloudinaryException {
      rethrow;
    } catch (e) {
      debugPrint('[CloudinaryService.uploadVideo] Unexpected error: $e');
      throw CloudinaryException('Unexpected upload error: $e', 0);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Compresses [file] to JPEG at [quality]% using flutter_image_compress.
  /// Returns the compressed file. Falls back to original if compression fails.
  Future<File> _compress(File file, {int quality = 80}) async {
    try {
      // flutter_image_compress writes to a temp path with _c suffix
      final targetPath = '${file.path}_compressed.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      // result is XFile? — fall back to original if null
      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      debugPrint(
        '[CloudinaryService._compress] Compression failed, using original: $e',
      );
      return file; // safe fallback — upload uncompressed
    }
  }
}

/// Thrown by [CloudinaryService] when an upload fails.
class CloudinaryException implements Exception {
  final String message;
  final int statusCode;
  const CloudinaryException(this.message, this.statusCode);

  @override
  String toString() => 'CloudinaryException($statusCode): $message';
}
