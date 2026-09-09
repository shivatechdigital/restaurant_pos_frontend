import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'picked_image.dart';

/// Opens the browser's native file picker and reads the chosen image as bytes.
Future<PickedImage?> pickImageFile() async {
  final input = html.FileUploadInputElement()..accept = 'image/png,image/jpeg,image/webp';
  input.click();

  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;

  final reader = html.FileReader();
  final completer = Completer<PickedImage?>();
  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is Uint8List) {
      completer.complete(PickedImage(result, file.name));
    } else if (result is ByteBuffer) {
      completer.complete(PickedImage(result.asUint8List(), file.name));
    } else {
      completer.complete(null);
    }
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsArrayBuffer(file);
  return completer.future;
}
