import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart' as platform_saver;

class FileSaver {
  static void saveFile(Uint8List bytes, String filename) {
    platform_saver.saveFileBytes(bytes, filename);
  }
}
