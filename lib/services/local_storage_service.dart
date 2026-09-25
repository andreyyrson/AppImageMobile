import 'dart:typed_data';

import 'package:gal/gal.dart';

class LocalSaveResult {
  const LocalSaveResult.success() : errorMessage = null;
  const LocalSaveResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

/// Salva a imagem processada na galeria do dispositivo usando `gal`
/// (mais simples e mantido que mexer direto em MediaStore/Photos).
class LocalStorageService {
  LocalStorageService._();

  static const _album = 'Editor de Imagens';

  static Future<LocalSaveResult> saveToGallery(Uint8List pngBytes, {String name = 'editada'}) async {
    try {
      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) {
        return const LocalSaveResult.failure('Permissão de acesso à galeria negada.');
      }
      await Gal.putImageBytes(pngBytes, album: _album, name: name);
      return const LocalSaveResult.success();
    } on GalException catch (e) {
      return LocalSaveResult.failure(e.type.message);
    } catch (e) {
      return LocalSaveResult.failure('Erro inesperado ao salvar: $e');
    }
  }
}
