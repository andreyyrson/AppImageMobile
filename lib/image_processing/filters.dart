import 'dart:math';

import 'package:image/image.dart' as img;

import '../models/noise_level.dart';

/// Funções de processamento de pixel puro: cada uma recebe uma imagem e
/// devolve uma NOVA imagem (a entrada nunca é mutada), para preservar a
/// imagem original intacta enquanto o editor trabalha em cópias.
class Filters {
  Filters._();

  static img.Image toGrayscale(img.Image src) {
    return img.grayscale(src.clone());
  }

  static img.Image flipHorizontal(img.Image src) {
    return img.flipHorizontal(src.clone());
  }

  static img.Image sharpen(img.Image src) {
    // Kernel clássico de realce de nitidez (soma dos pesos = 1).
    return img.convolution(
      src.clone(),
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    );
  }

  static img.Image saltAndPepperNoise(img.Image src, NoiseLevel level) {
    final result = src.clone();
    final rand = Random();
    final totalPixels = result.width * result.height;
    final affected = (totalPixels * level.density).round();

    for (var i = 0; i < affected; i++) {
      final x = rand.nextInt(result.width);
      final y = rand.nextInt(result.height);
      final isSalt = rand.nextBool();
      final value = isSalt ? 255 : 0;
      result.setPixelRgb(x, y, value, value, value);
    }
    return result;
  }

  static img.Image crop(img.Image src, {required int x, required int y, required int width, required int height}) {
    // copyCrop já devolve uma imagem nova sem alterar `src`.
    return img.copyCrop(src, x: x, y: y, width: width, height: height);
  }

  /// Efeito Horror: combina 5 transformações reais sobre os pixels:
  /// dessaturação parcial, aumento de contraste, canal vermelho dominante,
  /// vinheta e granulação (ruído).
  static img.Image horror(img.Image src) {
    var result = src.clone();

    // 1) Dessaturação parcial (mantém um pouco de cor, mas achata).
    result = img.grayscale(result, amount: 0.55);

    // 2) Aumento de contraste.
    result = img.contrast(result, contrast: 145);

    final rand = Random();
    final w = result.width;
    final h = result.height;
    final cx = w / 2;
    final cy = h / 2;
    final maxDist = sqrt(cx * cx + cy * cy);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = result.getPixel(x, y);

        // 3) Predominância de vermelho + alteração de canais.
        var r = (p.r * 1.35).clamp(0, 255);
        var g = (p.g * 0.55).clamp(0, 255);
        var b = (p.b * 0.55).clamp(0, 255);

        // 4) Vinheta: escurece as bordas.
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy) / maxDist;
        final vignette = (1.0 - (dist * dist) * 0.85).clamp(0.15, 1.0);
        r *= vignette;
        g *= vignette;
        b *= vignette;

        // 5) Granulação (ruído aditivo aleatório).
        final grain = (rand.nextDouble() - 0.5) * 30;
        r = (r + grain).clamp(0, 255);
        g = (g + grain).clamp(0, 255);
        b = (b + grain).clamp(0, 255);

        result.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }

    return result;
  }

  /// Sobreposição vermelha automática usada no modo paisagem (não é uma
  /// transformação "salva": é aplicada só para exibição, em cima da imagem
  /// editada atual, e descartada ao voltar para retrato).
  static img.Image redOverlayForDisplay(img.Image src) {
    final result = src.clone();
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final p = result.getPixel(x, y);
        final gray = img.getLuminanceRgb(p.r.toInt(), p.g.toInt(), p.b.toInt());
        final r = (gray * 0.9 + 255 * 0.4).clamp(0, 255);
        final g = (gray * 0.35).clamp(0, 255);
        final b = (gray * 0.35).clamp(0, 255);
        result.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }
    return result;
  }
}
