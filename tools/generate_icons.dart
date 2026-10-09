// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/images/logo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/images/logo.png not found');
    exit(1);
  }

  print('Reading logo image...');
  final imageBytes = logoFile.readAsBytesSync();
  final original = img.decodeImage(imageBytes);

  if (original == null) {
    print('Error: Failed to decode logo image');
    exit(1);
  }

  print('Original dimensions: ${original.width}x${original.height}');

  final targets = <String, int>{
    // Web icons
    'web/favicon.png': 128,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,

    // Android launcher icons
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in targets.entries) {
    final path = entry.key;
    final size = entry.value;

    final resized = img.copyResize(
      original,
      width: size,
      height: size,
      interpolation: img.Interpolation.linear,
    );

    final targetFile = File(path);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated: $path (${size}x$size)');
  }

  print('Successfully generated all web and Android app launcher icons!');
}
