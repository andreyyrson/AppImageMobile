import 'package:image/image.dart' as img;

/// Divide uma imagem numa grade rows x cols. O índice da lista retornada é
/// a ordem "correta" (0 = topo-esquerda, lendo linha a linha).
class PuzzleSlicer {
  PuzzleSlicer._();

  static List<img.Image> slice(img.Image src, {int rows = 3, int cols = 3}) {
    final tileWidth = src.width ~/ cols;
    final tileHeight = src.height ~/ rows;
    final tiles = <img.Image>[];

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        tiles.add(img.copyCrop(
          src,
          x: col * tileWidth,
          y: row * tileHeight,
          width: tileWidth,
          height: tileHeight,
        ));
      }
    }
    return tiles;
  }
}
