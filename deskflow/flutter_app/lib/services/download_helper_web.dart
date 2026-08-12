import 'dart:html' as html;
import 'dart:typed_data';

/// Web: ينزل الملف فعلاً عن طريق Blob URL
Future<void> saveFileToDevice(String fileName, Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = fileName;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}