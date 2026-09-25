import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../image_processing/liquify_processor.dart';
import '../utils/image_codec.dart';
import '../widgets/liquify_canvas.dart';

/// Tela de deformação por toque. Trabalha numa cópia reduzida da imagem para
/// manter o arrasto responsivo; ao confirmar, gera o resultado em resolução
/// plena a partir do mesmo campo de deformação.
class LiquifyScreen extends StatefulWidget {
  const LiquifyScreen({super.key, required this.source});

  final img.Image source;

  @override
  State<LiquifyScreen> createState() => _LiquifyScreenState();
}

class _LiquifyScreenState extends State<LiquifyScreen> {
  late final LiquifyProcessor _processor;
  late final img.Image _previewSource;
  final _canvasKey = GlobalKey<LiquifyCanvasState>();

  double _brushRadiusFraction = 0.12;
  double _intensity = 1.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processor = LiquifyProcessor(widget.source);
    _previewSource = ImageCodec.downscaleForEditing(widget.source, maxDimension: 480);
  }

  Future<void> _confirm() async {
    if (!_processor.hasDeformation) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isProcessing = true);
    // Renderiza em resolução plena fora do frame de build para não travar a UI.
    final result = await Future(() => _processor.render(widget.source));
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Liquify'),
        actions: [
          TextButton(
            onPressed: () {
              _processor.reset();
              _canvasKey.currentState?.refresh();
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: Colors.white),
            onPressed: _isProcessing ? null : _confirm,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: LiquifyCanvas(
                key: _canvasKey,
                processor: _processor,
                previewSource: _previewSource,
                brushRadiusFraction: _brushRadiusFraction,
                intensity: _intensity,
                onDeformed: () {},
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Slider(
                  label: 'Tamanho do pincel',
                  value: _brushRadiusFraction,
                  min: 0.03,
                  max: 0.35,
                  onChanged: (v) => setState(() => _brushRadiusFraction = v),
                ),
                _Slider(
                  label: 'Intensidade',
                  value: _intensity,
                  min: 0.2,
                  max: 2.0,
                  onChanged: (v) => setState(() => _intensity = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
