import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadTextFile(String filename, String content, String mimeType) async {
  final blob = html.Blob([utf8.encode(content)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}

Future<bool> downloadBytesFile(String filename, List<int> bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}