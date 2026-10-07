import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class ImageTooLargeException implements Exception {
  final String message;
  ImageTooLargeException([this.message = 'Image exceeds the maximum allowed size (200 KB)']);

  @override
  String toString() => message;
}

class ImageUtils {
  /// Compresses [rawBytes] into a high-efficiency JPEG under [maxSizeBytes] (default 200 KB)
  /// and returns it as a Base64-encoded string.
  /// Throws [ImageTooLargeException] if it cannot be compressed below the ceiling.
  static Future<String> compressAndEncodeBase64(
    Uint8List rawBytes, {
    int maxSizeBytes = AppConstants.maxImageSizeBytes,
    int maxDimension = 600,
  }) async {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('Failed to decode selected image.');
    }

    // Resize image maintaining aspect ratio if larger than maxDimension
    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: maxDimension);
      } else {
        resized = img.copyResize(decoded, height: maxDimension);
      }
    }

    // Progressively compress until it meets maxSizeBytes
    int quality = 85;
    Uint8List compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

    while (compressed.lengthInBytes > maxSizeBytes && quality > 25) {
      quality -= 15;
      compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    // If still too large, resize further
    if (compressed.lengthInBytes > maxSizeBytes) {
      final smaller = img.copyResize(resized, width: (resized.width * 0.7).toInt());
      compressed = Uint8List.fromList(img.encodeJpg(smaller, quality: 60));
    }

    if (compressed.lengthInBytes > maxSizeBytes) {
      final kb = (compressed.lengthInBytes / 1024).toStringAsFixed(1);
      throw ImageTooLargeException(
        'Unable to compress image below 200 KB (current: $kb KB). Please pick a smaller image to preserve Firestore document limits.',
      );
    }

    return base64Encode(compressed);
  }

  /// Decodes a base64 string to Uint8List for display
  static Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      // Strip potential data URI prefix if present
      String clean = base64String.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  /// Returns an ImageProvider from a base64 string, or null on error
  static ImageProvider? imageProviderFromBase64(String? base64String) {
    final bytes = base64ToBytes(base64String);
    if (bytes == null) return null;
    return MemoryImage(bytes);
  }

  /// Returns size in KB of a base64 string
  static double getBase64SizeInKb(String base64String) {
    return (base64String.length * 3 / 4) / 1024;
  }
}
