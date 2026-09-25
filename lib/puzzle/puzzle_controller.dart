import 'dart:math';

import 'package:flutter/foundation.dart';

/// Lógica do quebra-cabeça 3x3: cada posição da grade guarda o índice da
/// peça original que está ali. O jogador seleciona duas posições e elas
/// trocam de lugar (sem "peça vazia" — todas as 9 posições ficam sempre
/// ocupadas, conforme o enunciado pede troca por seleção, não deslize).
class PuzzleController extends ChangeNotifier {
  PuzzleController({this.tileCount = 9}) {
    shuffle();
  }

  final int tileCount;

  late List<int> tileAtPosition;
  int? selectedPosition;
  bool solved = false;

  void shuffle() {
    tileAtPosition = List.generate(tileCount, (i) => i);
    final rand = Random();
    do {
      tileAtPosition.shuffle(rand);
    } while (_isSolved(tileAtPosition));

    selectedPosition = null;
    solved = false;
    notifyListeners();
  }

  bool _isSolved(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  void selectTile(int position) {
    if (solved) return;

    if (selectedPosition == null) {
      selectedPosition = position;
    } else if (selectedPosition == position) {
      selectedPosition = null;
    } else {
      final tmp = tileAtPosition[selectedPosition!];
      tileAtPosition[selectedPosition!] = tileAtPosition[position];
      tileAtPosition[position] = tmp;
      selectedPosition = null;
      solved = _isSolved(tileAtPosition);
    }
    notifyListeners();
  }
}
