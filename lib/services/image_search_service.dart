import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Extracts searchable product tags from a user-picked image.
///
/// Two input modes:
///   1. [getLabelsFromFile] — user picked from camera/gallery (local File).
///      Compresses → base64 → sends to Gemini multimodal API.
///   2. [getLabelsFromCloudinaryUrl] — you have an existing Cloudinary URL
///      (e.g. from a product the user is "searching by"). Fetches the bytes
///      via Cloudinary's optimisation transform, then sends to Gemini.
///
/// Both return lowercase tag strings that match Firestore
/// product tag lists and product.category fields.
///
/// M3 integration note:
///   M3's cloudinary_service.dart stores URLs in product.images[].
///   To "find similar" from an existing product, call:
///     getLabelsFromCloudinaryUrl(product.images.first)
///   For camera/gallery picks, call:
///     getLabelsFromFile(file)
///
/// Setup:
///   flutter run --dart-define=GEMINI_API_KEY=your_key
class ImageSearchService {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3-flash-preview',
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// User picked a photo from camera or gallery.
  Future<List<String>> getLabelsFromFile(File imageFile) async {
    try {
      final bytes = await _compressFile(imageFile);
      if (bytes == null) return _fallbackFromFilename(imageFile.path);
      final labels = await _sendToGemini(bytes);
      if (labels.isNotEmpty) return labels;
      return _fallbackFromFilename(imageFile.path);
    } catch (e) {
      debugPrint('[ImageSearchService] getLabelsFromFile error: $e');
      return _fallbackFromFilename(imageFile.path);
    }
  }

  /// Alias so ImageSearchNotifier.searchWithImage() keeps working unchanged.
  Future<List<String>> getLabelsFromImage(File imageFile) =>
      getLabelsFromFile(imageFile);

  /// Gemini-only extraction for flows that must avoid synthetic fallback tags.
  ///
  /// Returns an empty list when Gemini labeling is unavailable.
  Future<List<String>> getGeminiLabelsFromImage(File imageFile) async {
    try {
      final bytes = await _compressFile(imageFile);
      if (bytes == null) return [];
      return _sendToGemini(bytes);
    } catch (e) {
      debugPrint('[ImageSearchService] getGeminiLabelsFromImage error: $e');
      return [];
    }
  }

  /// Search using an existing Cloudinary product image URL.
  /// Requests a compressed variant from Cloudinary before sending to Gemini.
  Future<List<String>> getLabelsFromCloudinaryUrl(String url) async {
    try {
      final optimisedUrl = _buildCloudinaryOptimisedUrl(url);
      final bytes = await _fetchUrlBytes(optimisedUrl);
      if (bytes == null || bytes.isEmpty) {
        debugPrint('[ImageSearchService] Could not fetch: $url');
        return _fallbackFromFilename(url);
      }
      final labels = await _sendToGemini(bytes);
      if (labels.isNotEmpty) return labels;
      return _fallbackFromFilename(url);
    } catch (e) {
      debugPrint('[ImageSearchService] getLabelsFromCloudinaryUrl error: $e');
      return _fallbackFromFilename(url);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Injects Cloudinary URL transformation params to resize + compress
  /// before sending to Gemini API (keeps payload well under 4 MB).
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

  /// Compress a local file before encoding for Gemini.
  Future<List<int>?> _compressFile(File file) {
    return FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 600,
      minHeight: 600,
      quality: 75,
    );
  }

  /// Core Gemini multimodal API call. Returns matched Firestore tags.
  Future<List<String>> _sendToGemini(List<int> imageBytes) async {
    if (_geminiApiKey.isEmpty) {
      debugPrint('[ImageSearchService] GEMINI_API_KEY not set — '
          'build with --dart-define=GEMINI_API_KEY=xxx');
      return [];
    }

    const prompt =
        'You are generating product search tags for an e-commerce app. '
        'Analyze this image and return ONLY a JSON array of 5 to 12 short, '
        'lowercase tags. Include product type, material, and style. '
        'No prose, no markdown, no code fence.';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 200,
      },
    });

    final client = HttpClient();
    try {
      final endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$_geminiModel:generateContent?key=$_geminiApiKey';
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint(
          '[ImageSearchService] Gemini ${response.statusCode}: $responseBody',
        );
        return [];
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return [];

      final first = candidates.first as Map<String, dynamic>;
      final content = first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return [];

      final rawText = parts
          .map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
          .join(' ')
          .trim();

      if (rawText.isEmpty) return [];

      final rawLabels = _extractLabelsFromGeminiText(rawText);
      return _mapLabelsToProductTags(rawLabels);
    } catch (e) {
      debugPrint('[ImageSearchService] _sendToGemini error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  /// Parses Gemini text output into a normalized list of tags.
  List<String> _extractLabelsFromGeminiText(String rawText) {
    final normalized = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final labels = <String>{};

    void addLabel(String value) {
      final clean = value
          .toLowerCase()
          .replaceAll(RegExp(r'^[\s\-\*\d\.\)]+'), '')
          .replaceAll(RegExp(r'["\[\]]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (clean.length < 2) return;
      labels.add(clean);
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is List) {
        for (final item in decoded) {
          addLabel(item.toString());
        }
      }
    } catch (_) {
      // Ignore and continue with best-effort parsing.
    }

    if (labels.isEmpty) {
      final start = normalized.indexOf('[');
      final end = normalized.lastIndexOf(']');
      if (start != -1 && end > start) {
        final jsonSlice = normalized.substring(start, end + 1);
        try {
          final decoded = jsonDecode(jsonSlice);
          if (decoded is List) {
            for (final item in decoded) {
              addLabel(item.toString());
            }
          }
        } catch (_) {
          // Ignore and continue with split fallback.
        }
      }
    }

    if (labels.isEmpty) {
      for (final part in normalized.split(RegExp(r'[,\n;|]'))) {
        addLabel(part);
      }
    }

    return labels.take(12).toList();
  }

  /// Maps model labels → Firestore tag/category strings.
  ///
  /// Keys must match ProductCategory enum values in product_model.dart
  /// and the tags that M4 writes when uploading products.
  /// Aligned with M3's Cloudinary folder naming conventions.
  List<String> _mapLabelsToProductTags(List<String> modelLabels) {
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
    for (final label in modelLabels) {
      for (final entry in tagMap.entries) {
        if (entry.value.any((kw) => label.contains(kw))) {
          matched.add(entry.key);
        }
      }
    }
    // Fallback: raw model labels may directly match seller-added tags.
    matched.addAll(modelLabels.take(5));
    return matched.toList();
  }

  /// Fallback when AI labeling is unavailable — extract hints from filename.
  List<String> _fallbackFromFilename(String path) {
    final filename = path.split(RegExp(r'[\\/]')).last.toLowerCase();
    final ignored = {
      'img',
      'image',
      'photo',
      'pic',
      'camera',
      'screenshot',
      'jpg',
      'jpeg',
      'png',
      'heic',
      'webp',
    };

    final words = filename
        .split(RegExp(r'[_\-\s\.]'))
        .map((w) => w.trim())
        .where((w) => w.length >= 3)
        .where((w) => RegExp(r'[a-z]').hasMatch(w))
        .where((w) => !ignored.contains(w))
        .toList();

    final mapped = _mapLabelsToProductTags(words);
    if (mapped.isNotEmpty) return mapped;

    // Last-resort fallback: broad categories so users still get results.
    return const ['crafts', 'clothing', 'furniture'];
  }
}

final imageSearchServiceProvider = Provider<ImageSearchService>((ref) {
  return ImageSearchService();
});