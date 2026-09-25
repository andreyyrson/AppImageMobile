import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Encapsula o `image_picker` (câmera/galeria) atrás de uma interface simples
/// que devolve um [File] ou `null` se o usuário cancelar.
class ImageSourceService {
  ImageSourceService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    return xFile == null ? null : File(xFile.path);
  }

  static Future<File?> pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    return xFile == null ? null : File(xFile.path);
  }
}
