import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../image_processing/filters.dart';
import '../utils/image_codec.dart';

/// Tela de crop manual: o usuário arrasta e redimensiona um retângulo sobre
/// a imagem; ao confirmar, uma nova imagem é gerada com [Filters.crop]
/// (recorte real de pixels, não um `ClipRect` cosmético).
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.source});

  final img.Image source;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  static const double _handleSize = 28;

  late final Uint8List _previewBytes;
  Rect _rect = Rect.zero;
  Size? _widgetSize;

  @override
  void initState() {
    super.initState();
    _previewBytes = ImageCodec.encodePng(widget.source);
  }

  void _initRectIfNeeded(Size size) {
    if (_widgetSize == size) return;
    _widgetSize = size;
    final w = size.width * 0.7;
    final h = size.height * 0.7;
    _rect = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  void _moveRect(Offset delta, Size bounds) {
    setState(() {
      var newRect = _rect.shift(delta);
      if (newRect.left < 0) newRect = newRect.shift(Offset(-newRect.left, 0));
      if (newRect.top < 0) newRect = newRect.shift(Offset(0, -newRect.top));
      if (newRect.right > bounds.width) {
        newRect = newRect.shift(Offset(bounds.width - newRect.right, 0));
      }
      if (newRect.bottom > bounds.height) {
        newRect = newRect.shift(Offset(0, bounds.height - newRect.bottom));
      }
      _rect = newRect;
    });
  }

  void _resizeFromTopLeft(Offset delta) {
    setState(() {
      final left = (_rect.left + delta.dx).clamp(0.0, _rect.right - 40).toDouble();
      final top = (_rect.top + delta.dy).clamp(0.0, _rect.bottom - 40).toDouble();
      _rect = Rect.fromLTRB(left, top, _rect.right, _rect.bottom);
    });
  }

  void _resizeFromBottomRight(Offset delta, Size bounds) {
    setState(() {
      final right = (_rect.right + delta.dx).clamp(_rect.left + 40, bounds.width).toDouble();
      final bottom = (_rect.bottom + delta.dy).clamp(_rect.top + 40, bounds.height).toDouble();
      _rect = Rect.fromLTRB(_rect.left, _rect.top, right, bottom);
    });
  }

  void _confirmCrop() {
    final size = _widgetSize;
    if (size == null) return;
    final scaleX = widget.source.width / size.width;
    final scaleY = widget.source.height / size.height;

    final cropped = Filters.crop(
      widget.source,
      x: (_rect.left * scaleX).round(),
      y: (_rect.top * scaleY).round(),
      width: (_rect.width * scaleX).round(),
      height: (_rect.height * scaleY).round(),
    );
    Navigator.pop(context, cropped);
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.source.width / widget.source.height;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Selecionar região'),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: _confirmCrop),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _initRectIfNeeded(size);
              return Stack(
                children: [
                  Image.memory(_previewBytes, fit: BoxFit.fill),
                  CustomPaint(size: size, painter: _CropOverlayPainter(_rect)),
                  Positioned.fromRect(
                    rect: _rect,
                    child: GestureDetector(
                      onPanUpdate: (d) => _moveRect(d.delta, size),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Positioned(
                    left: _rect.left - _handleSize / 2,
                    top: _rect.top - _handleSize / 2,
                    child: _handle((d) => _resizeFromTopLeft(d.delta)),
                  ),
                  Positioned(
                    left: _rect.right - _handleSize / 2,
                    top: _rect.bottom - _handleSize / 2,
                    child: _handle((d) => _resizeFromBottomRight(d.delta, size)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _handle(void Function(DragUpdateDetails) onPanUpdate) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Container(
        width: _handleSize,
        height: _handleSize,
        decoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter(this.rect);
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRect(rect);
    final overlayPath = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) => oldDelegate.rect != rect;
}
