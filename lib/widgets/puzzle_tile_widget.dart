import 'dart:typed_data';

import 'package:flutter/material.dart';

class PuzzleTileWidget extends StatelessWidget {
  const PuzzleTileWidget({
    super.key,
    required this.bytes,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final Uint8List bytes;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.amber : Colors.black26,
            width: selected ? 4 : 1,
          ),
        ),
        child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}
