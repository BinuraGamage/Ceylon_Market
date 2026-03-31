import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service provider for image-based product search helpers.
final imageSearchServiceProvider = Provider<ImageSearchService>((ref) {
  return const ImageSearchService();
});

/// Extracts lightweight label candidates from an image.
///
/// This is currently a fallback implementation that derives tags from
/// the filename. Replace this with a Vision API integration when API
/// credentials and endpoint wiring are finalized.
class ImageSearchService {
  const ImageSearchService();

  Future<List<String>> getLabelsFromImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      final nameWithoutExtension = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      final tags = nameWithoutExtension
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .split(' ')
          .where((word) => word.length >= 3)
          .toSet()
          .toList();

      return tags;
    } catch (e) {
      debugPrint('[ImageSearchService] getLabelsFromImage error: $e');
      return const [];
    }
  }
}
