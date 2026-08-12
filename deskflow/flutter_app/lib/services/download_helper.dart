import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Windows/Desktop: يفتح نافذة "Save As" ويحفظ الملف
Future<void> saveFileToDevice(String fileName, Uint8List bytes) async {
  await FilePicker.platform.saveFile(
    dialogTitle: 'Save document',
    fileName: fileName,
    bytes: bytes,
  );
}