import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../puzzle/puzzle_controller.dart';
import '../puzzle/puzzle_slicer.dart';
import '../utils/image_codec.dart';
import '../widgets/puzzle_tile_widget.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.source});

  final img.Image source;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const int _gridSize = 3;

  late final List<Uint8List> _tileBytes;
  late final PuzzleController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    final tiles = PuzzleSlicer.slice(widget.source, rows: _gridSize, cols: _gridSize);
    _tileBytes = tiles.map(ImageCodec.encodePng).toList();
    _controller = PuzzleController(tileCount: _gridSize * _gridSize);
    _controller.addListener(_onPuzzleChanged);
  }

  void _onPuzzleChanged() {
    if (_controller.solved && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSolvedDialog());
    }
    setState(() {});
  }

  void _showSolvedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parabéns! 🎉'),
        content: const Text('Você concluiu o quebra-cabeça.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.shuffle();
              _dialogShown = false;
            },
            child: const Text('Jogar de novo'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Voltar ao editor'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onPuzzleChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quebra-cabeça 3x3'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Embaralhar novamente',
            onPressed: () {
              _dialogShown = false;
              _controller.shuffle();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_controller.solved)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Concluído! 🎉',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Toque em duas peças para trocá-las de lugar.'),
              ),
            Expanded(
              child: AspectRatio(
                aspectRatio: widget.source.width / widget.source.height,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _gridSize * _gridSize,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    // Peças da grade têm a mesma proporção da imagem inteira,
                    // já que ela é dividida em fatias iguais 3x3.
                    childAspectRatio: widget.source.width / widget.source.height,
                  ),
                  itemBuilder: (context, position) {
                    final tileIndex = _controller.tileAtPosition[position];
                    return PuzzleTileWidget(
                      bytes: _tileBytes[tileIndex],
                      selected: _controller.selectedPosition == position,
                      locked: _controller.solved,
                      onTap: () => _controller.selectTile(position),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
