import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Extracts searchable product tags from a user-picked image.
///
/// Two input modes:
///   1. [getLabelsFromFile] — user picked from camera/gallery (local File).
///      Compresses → base64 → sends to Google Vision API.
///   2. [getLabelsFromCloudinaryUrl] — you have an existing Cloudinary URL
///      (e.g. from a product the user is "searching by"). Fetches the bytes
///      via Cloudinary's optimisation transform, then sends to Vision.
///
/// Both return List<String> of lowercase tags that match Firestore
/// product.tags[] and product.category fields.
///
/// M3 integration note:
///   M3's cloudinary_service.dart stores URLs in product.images[].
///   To "find similar" from an existing product, call:
///     getLabelsFromCloudinaryUrl(product.images.first)
///   For camera/gallery picks, call:
///     getLabelsFromFile(file)
///
/// Setup:
///   flutter run --dart-define=VISION_API_KEY=your_key
class ImageSearchService {
  static const String _apiKey = String.fromEnvironment('VISION_API_KEY');
  static const String _visionEndpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// User picked a photo from camera or gallery.
  Future<List<String>> getLabelsFromFile(File imageFile) async {
    try {
      final bytes = await _compressFile(imageFile);
      if (bytes == null) return _fallbackFromFilename(imageFile.path);
      return _sendToVision(bytes);
    } catch (e) {
      debugPrint('[ImageSearchService] getLabelsFromFile error: $e');
      return _fallbackFromFilename(imageFile.path);
    }
  }

  /// Alias so ImageSearchNotifier.searchWithImage() keeps working unchanged.
  Future<List<String>> getLabelsFromImage(File imageFile) =>
      getLabelsFromFile(imageFile);

  /// Search using an existing Cloudinary product image URL.
  /// Requests a compressed variant from Cloudinary before sending to Vision.
  Future<List<String>> getLabelsFromCloudinaryUrl(String url) async {
    try {
      final optimisedUrl = _buildCloudinaryOptimisedUrl(url);
      final bytes = await _fetchUrlBytes(optimisedUrl);
      if (bytes == null || bytes.isEmpty) {
        debugPrint('[ImageSearchService] Could not fetch: $url');
        return [];
      }
      return _sendToVision(bytes);
    } catch (e) {
      debugPrint('[ImageSearchService] getLabelsFromCloudinaryUrl error: $e');
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Injects Cloudinary URL transformation params to resize + compress
  /// before sending to Vision API (keeps payload well under 4 MB).
  /// Cloudinary URL structure: /image/upload/{transforms}/{public_id}
  String _buildCloudinaryOptimisedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.toList();
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1) return url;
      final newSegments = [
        ...segments.sublist(0, uploadIndex + 1),
        'w_600,q_70,f_jpg',
        ...segments.sublist(uploadIndex + 1),
      ];
      return uri.replace(pathSegments: newSegments).toString();
    } catch (_) {
      return url;
    }
  }

  /// Downloads raw bytes from any HTTPS URL.
  Future<List<int>?> _fetchUrlBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } catch (e) {
      debugPrint('[ImageSearchService] _fetchUrlBytes error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Compress a local file before encoding for Vision.
  Future<List<int>?> _compressFile(File file) {
    return FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 600,
      minHeight: 600,
      quality: 75,
    );
  }

  /// Core Vision API call. Returns matched Firestore tags.
  Future<List<String>> _sendToVision(List<int> imageBytes) async {
    if (_apiKey.isEmpty) {
      debugPrint('[ImageSearchService] VISION_API_KEY not set — '
          'build with --dart-define=VISION_API_KEY=xxx');
      return [];
    }

    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Encode(imageBytes)},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 15},
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
          ],
        }
      ]
    });

    final client = HttpClient();
    try {
      final request =
          await client.postUrl(Uri.parse('$_visionEndpoint?key=$_apiKey'));
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint(
            '[ImageSearchService] Vision ${response.statusCode}: $responseBody');
        return [];
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final responses = json['responses'] as List?;
      if (responses == null || responses.isEmpty) return [];

      final first = responses.first as Map<String, dynamic>;
      final rawLabels = <String>[];

      for (final l in first['labelAnnotations'] as List? ?? []) {
        final d = (l['description'] as String?)?.toLowerCase();
        if (d != null) rawLabels.add(d);
      }
      for (final o in first['localizedObjectAnnotations'] as List? ?? []) {
        final n = (o['name'] as String?)?.toLowerCase();
        if (n != null) rawLabels.add(n);
      }

      return _mapLabelsToProductTags(rawLabels);
    } finally {
      client.close();
    }
  }

  /// Maps Vision labels → Firestore tag/category strings.
  ///
  /// Keys must match ProductCategory enum values in product_model.dart
  /// and the tags that M4 writes when uploading products.
  /// Aligned with M3's Cloudinary folder naming conventions.
  List<String> _mapLabelsToProductTags(List<String> visionLabels) {
    const tagMap = <String, List<String>>{
      'crafts':    ['craft', 'handmade', 'artisan', 'wicker', 'cane', 'basket', 'weave', 'mat'],
      'clothing':  ['clothing', 'dress', 'saree', 'garment', 'fashion', 'batik', 'textile', 'fabric'],
      'furniture': ['furniture', 'chair', 'table', 'sofa', 'bed', 'desk', 'cabinet', 'shelf'],
      'food':      ['food', 'cake', 'biscuit', 'snack', 'sweet', 'dessert', 'baked'],
      'statues':   ['statue', 'figurine', 'sculpture', 'idol', 'buddha', 'deity'],
      'clay':      ['pottery', 'clay', 'ceramic', 'terracotta', 'earthenware'],
      'bottled':   ['bottle', 'jar', 'jam', 'pickle', 'achcharu', 'preserve', 'chutney'],
      'metal':     ['metal', 'brass', 'copper', 'iron', 'bronze', 'metalwork', 'alloy'],
      'paintings': ['painting', 'art', 'canvas', 'artwork', 'illustration', 'watercolour'],
      // Descriptive tags sellers commonly add
      'wood':      ['wood', 'wooden', 'timber', 'ebony', 'teak', 'carving'],
      'mask':      ['mask', 'face mask', 'devil mask', 'demon'],
      'honey':     ['honey', 'beeswax', 'honeycomb', 'nectar'],
      'lacquer':   ['lacquer', 'lacquerware', 'varnish'],
    };

    final matched = <String>{};
    for (final label in visionLabels) {
      for (final entry in tagMap.entries) {
        if (entry.value.any((kw) => label.contains(kw))) {
          matched.add(entry.key);
        }
      }
    }
    // Fallback: raw Vision labels may directly match seller-added tags
    matched.addAll(visionLabels.take(5));
    return matched.toList();
  }

  /// Fallback when Vision is unavailable — extract hints from filename.
  List<String> _fallbackFromFilename(String path) {
    final filename = path.split('/').last.toLowerCase();
    final words = filename.split(RegExp(r'[_\-\s\.]'));
    return _mapLabelsToProductTags(words);
  }
}

final imageSearchServiceProvider = Provider<ImageSearchService>((ref) {
  return ImageSearchService();
});