import 'dart:typed_data';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as material show Image;
import 'package:image/image.dart' as img;

import '../image_processing/liquify_processor.dart';
import '../utils/image_codec.dart';

/// Área de toque do liquify: renderiza o campo de deformação em tempo real
/// sobre uma versão reduzida da imagem (para manter o arrasto fluido) e
/// delega o cálculo pesado para [LiquifyProcessor].
///
/// A view é forçada a manter a proporção exata da imagem (AspectRatio) para
/// que a conversão de coordenadas de toque -> pixel da imagem seja um
/// simples fator de escala, sem faixas de letterbox para descontar.
class LiquifyCanvas extends StatefulWidget {
  const LiquifyCanvas({
    super.key,
    required this.processor,
    required this.previewSource,
    required this.brushRadiusFraction,
    required this.intensity,
    required this.onDeformed,
  });

  final LiquifyProcessor processor;
  final img.Image previewSource;
  final double brushRadiusFraction;
  final double intensity;
  final VoidCallback onDeformed;

  @override
  State<LiquifyCanvas> createState() => LiquifyCanvasState();
}

class LiquifyCanvasState extends State<LiquifyCanvas> {
  Uint8List? _frameBytes;
  DateTime _lastRender = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _renderNow();
  }

  void _renderNow() {
    final warped = widget.processor.render(widget.previewSource);
    _frameBytes = ImageCodec.encodePng(warped);
  }

  void _maybeRender() {
    final now = DateTime.now();
    if (now.difference(_lastRender) < const Duration(milliseconds: 40)) return;
    _lastRender = now;
    setState(_renderNow);
  }

  /// Renderiza em resolução plena; usado quando o usuário confirma a edição.
  img.Image renderFull() => widget.processor.render(widget.processor.base);

  /// Força um novo frame (ex.: depois de [LiquifyProcessor.reset] chamado
  /// externamente pela tela que hospeda este canvas).
  void refresh() => setState(_renderNow);

  void _handleDrag(Offset localPosition, Offset delta, Size widgetSize) {
    final scaleX = widget.processor.base.width / widgetSize.width;
    final scaleY = widget.processor.base.height / widgetSize.height;
    final imagePos = Offset(localPosition.dx * scaleX, localPosition.dy * scaleY);
    final imageDelta = Offset(delta.dx * scaleX, delta.dy * scaleY);
    final brushRadiusPx = widget.brushRadiusFraction * widget.processor.base.width;

    widget.processor.applyDrag(imagePos, imageDelta, brushRadiusPx, widget.intensity);
    widget.onDeformed();
    _maybeRender();
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.previewSource.width / widget.previewSource.height;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanUpdate: (details) => _handleDrag(details.localPosition, details.delta, size),
            onPanEnd: (_) => setState(_renderNow),
            child: _frameBytes == null
                ? const SizedBox.expand()
                : material.Image.memory(
                    _frameBytes!,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
          );
        },
      ),
    );
  }
}
