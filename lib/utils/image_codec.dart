import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Conversões entre File/bytes (mundo Flutter/IO) e img.Image (mundo de
/// processamento de pixel). Mantido separado para as telas não precisarem
/// saber como decodificar/codificar.
class ImageCodec {
  ImageCodec._();

  static Future<img.Image> decodeFile(File file) async {
    final bytes = await file.readAsBytes();
    return decodeBytes(bytes);
  }

  static img.Image decodeBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Não foi possível decodificar a imagem.');
    }
    // Aplica a orientação EXIF (fotos de câmera costumam vir rotacionadas) e
    // normaliza para RGB de 3 canais: simplifica todo o pipeline de
    // processamento (sem precisar tratar canal alfa em cada filtro) e evita
    // que o buffer "em branco" do liquify (que começa zerado) saia com
    // alfa 0 (totalmente transparente) quando a origem tinha canal alfa.
    final oriented = img.bakeOrientation(decoded);
    return oriented.convert(numChannels: 3);
  }

  static Uint8List encodePng(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }

  static Uint8List encodeJpg(img.Image image, {int quality = 92}) {
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Reduz a imagem para uma dimensão máxima de trabalho, preservando a
  /// proporção. Usado para manter a edição (principalmente o liquify, que
  /// reprocessa a imagem inteira a cada gesto) responsiva em imagens de
  /// câmera muito grandes.
  static img.Image downscaleForEditing(img.Image src, {int maxDimension = 1280}) {
    if (src.width <= maxDimension && src.height <= maxDimension) {
      return src;
    }
    if (src.width >= src.height) {
      return img.copyResize(src, width: maxDimension);
    }
    return img.copyResize(src, height: maxDimension);
  }
}
