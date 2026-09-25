import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Comparação lado a lado: arraste a linha para revelar a imagem original
/// (esquerda) sobre a editada (direita).
class BeforeAfterView extends StatefulWidget {
  const BeforeAfterView({super.key, required this.before, required this.after});

  final Uint8List before;
  final Uint8List after;

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _position = (_position + details.delta.dx / width).clamp(0.0, 1.0).toDouble();
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(widget.after, fit: BoxFit.contain, gaplessPlayback: true),
                ClipRect(
                  clipper: _LeftClipper(_position),
                  child: Image.memory(widget.before, fit: BoxFit.contain, gaplessPlayback: true),
                ),
                Positioned(
                  left: (width * _position - 1).clamp(0, width - 2).toDouble(),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),
                const Positioned(top: 8, left: 8, child: _Tag('Original')),
                const Positioned(top: 8, right: 8, child: _Tag('Editada')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.position);
  final double position;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.position != position;
}
