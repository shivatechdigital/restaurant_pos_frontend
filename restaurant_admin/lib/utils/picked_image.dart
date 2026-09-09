import 'dart:typed_data';

class PickedImage {
  final Uint8List bytes;
  final String filename;
  PickedImage(this.bytes, this.filename);
}
