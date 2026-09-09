import 'picked_image.dart';

/// Non-web fallback: image picking via browser file input isn't available here.
Future<PickedImage?> pickImageFile() async => null;
