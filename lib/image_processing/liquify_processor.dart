import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// Deformação tipo "liquify": mantém um campo de deslocamento (uma malha de
/// vetores) em pixels da imagem [base]. Arrastar o dedo empurra os nós da
/// malha perto do toque na direção do arrasto; renderizar a imagem final
/// consiste em, para cada pixel de saída, olhar o deslocamento da malha
/// naquele ponto e amostrar (com interpolação bilinear) a imagem original
/// na posição inversa — ou seja, os pixels de fato se movem, não é um efeito
/// visual sobreposto.
class LiquifyProcessor {
  LiquifyProcessor(this.base, {this.gridSize = 24})
      : _nodes = gridSize + 1,
        _stepX = base.width / gridSize,
        _stepY = base.height / gridSize,
        _dx = List.generate(gridSize + 1, (_) => List.filled(gridSize + 1, 0.0)),
        _dy = List.generate(gridSize + 1, (_) => List.filled(gridSize + 1, 0.0));

  /// Imagem de trabalho em resolução plena. Nunca é modificada por esta
  /// classe: [render] sempre lê dela (ou de uma versão redimensionada) e
  /// escreve num buffer novo.
  final img.Image base;
  final int gridSize;
  final int _nodes;
  final double _stepX;
  final double _stepY;
  final List<List<double>> _dx;
  final List<List<double>> _dy;

  bool get hasDeformation {
    for (var j = 0; j < _nodes; j++) {
      for (var i = 0; i < _nodes; i++) {
        if (_dx[j][i].abs() > 0.05 || _dy[j][i].abs() > 0.05) return true;
      }
    }
    return false;
  }

  void reset() {
    for (var j = 0; j < _nodes; j++) {
      for (var i = 0; i < _nodes; i++) {
        _dx[j][i] = 0;
        _dy[j][i] = 0;
      }
    }
  }

  /// [imagePos]/[imageDelta] e [brushRadius] em pixels da imagem [base].
  /// [intensity] tipicamente entre 0.2 e 2.0.
  void applyDrag(Offset imagePos, Offset imageDelta, double brushRadius, double intensity) {
    if (imageDelta.distance < 0.001 || brushRadius <= 0) return;
    final r2 = brushRadius * brushRadius;

    for (var j = 0; j < _nodes; j++) {
      final ny = j * _stepY;
      final ddy = ny - imagePos.dy;
      for (var i = 0; i < _nodes; i++) {
        final nx = i * _stepX;
        final ddx = nx - imagePos.dx;
        final dist2 = ddx * ddx + ddy * ddy;
        if (dist2 >= r2) continue;
        final falloff = pow(1 - (dist2 / r2), 2).toDouble();
        _dx[j][i] += imageDelta.dx * falloff * intensity;
        _dy[j][i] += imageDelta.dy * falloff * intensity;
      }
    }
  }

  Offset _sampleGrid(double px, double py) {
    final gx = (px / _stepX).clamp(0, gridSize.toDouble()).toDouble();
    final gy = (py / _stepY).clamp(0, gridSize.toDouble()).toDouble();
    final i0 = gx.floor();
    final j0 = gy.floor();
    final i1 = min(i0 + 1, gridSize);
    final j1 = min(j0 + 1, gridSize);
    final tx = gx - i0;
    final ty = gy - j0;

    double lerp(double a, double b, double t) => a + (b - a) * t;

    final dxTop = lerp(_dx[j0][i0], _dx[j0][i1], tx);
    final dxBot = lerp(_dx[j1][i0], _dx[j1][i1], tx);
    final dy0 = lerp(dxTop, dxBot, ty);

    final dyTop = lerp(_dy[j0][i0], _dy[j0][i1], tx);
    final dyBot = lerp(_dy[j1][i0], _dy[j1][i1], tx);
    final dy1 = lerp(dyTop, dyBot, ty);

    return Offset(dy0, dy1);
  }

  /// Gera a imagem deformada. [target] pode ser [base] (resultado em
  /// resolução plena, mais lento) ou uma cópia redimensionada dele (preview
  /// leve durante o arrasto, para manter a UI responsiva).
  img.Image render(img.Image target) {
    final scaleX = target.width / base.width;
    final scaleY = target.height / base.height;
    final out = img.Image.from(target, noPixels: true);

    for (var oy = 0; oy < target.height; oy++) {
      final basePy = oy / scaleY;
      for (var ox = 0; ox < target.width; ox++) {
        final basePx = ox / scaleX;
        final disp = _sampleGrid(basePx, basePy);
        final srcX = ox - disp.dx * scaleX;
        final srcY = oy - disp.dy * scaleY;
        final color = _bilinearSample(target, srcX, srcY);
        out.setPixelRgb(ox, oy, color[0], color[1], color[2]);
      }
    }
    return out;
  }

  List<int> _bilinearSample(img.Image src, double x, double y) {
    final cx = x.clamp(0, src.width - 1).toDouble();
    final cy = y.clamp(0, src.height - 1).toDouble();
    final x0 = cx.floor();
    final y0 = cy.floor();
    final x1 = min(x0 + 1, src.width - 1);
    final y1 = min(y0 + 1, src.height - 1);
    final tx = cx - x0;
    final ty = cy - y0;

    final p00 = src.getPixel(x0, y0);
    final p10 = src.getPixel(x1, y0);
    final p01 = src.getPixel(x0, y1);
    final p11 = src.getPixel(x1, y1);

    int mix4(num a, num b, num c, num d) {
      final top = a + (b - a) * tx;
      final bottom = c + (d - c) * tx;
      return (top + (bottom - top) * ty).round();
    }

    return [
      mix4(p00.r, p10.r, p01.r, p11.r),
      mix4(p00.g, p10.g, p01.g, p11.g),
      mix4(p00.b, p10.b, p01.b, p11.b),
    ];
  }
}
