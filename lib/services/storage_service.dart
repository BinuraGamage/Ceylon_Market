import 'dart:io';

import 'package:flutter/foundation.dart';
import 'cloudinary_service.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Future<String> uploadProductImage({
    required File file,
    required String shopId,
    required String productId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Note: CloudinaryService already prepends its folder (sela_market/shops),
      // so this will be structured as sela_market/shops/products/shopId/productId/timestamp
      final publicId = 'products/$shopId/$productId/$timestamp';

      return await CloudinaryService.instance.uploadImage(
        file: file,
        publicId: publicId,
      );
    } catch (e) {
      debugPrint('[StorageService] uploadProductImage error: $e');
      rethrow;
    }
  }

  Future<List<String>> uploadProductImages({
    required List<File> files,
    required String shopId,
    required String productId,
  }) async {
    // Uploads concurrently for faster processing
    final futures = files.map(
      (file) =>
          uploadProductImage(file: file, shopId: shopId, productId: productId),
    );
    return Future.wait(futures);
  }
}
