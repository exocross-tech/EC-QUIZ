import 'dart:io';

/// Platform check implementation for IO platforms (mobile, desktop, and test VM).
bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');
