import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../image_processing/filters.dart';
import '../models/noise_level.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../utils/image_codec.dart';
import '../widgets/before_after_view.dart';
import 'crop_screen.dart';
import 'liquify_screen.dart';
import 'puzzle_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  img.Image? _original;
  img.Image? _edited;
  Uint8List? _originalBytes;
  Uint8List? _editedBytes;

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isUploading = false;
  bool _showComparison = false;
  String? _loadError;

  // Cache do overlay vermelho automático de paisagem, para não recodificar
  // PNG a cada rebuild não relacionado enquanto a orientação não muda.
  img.Image? _landscapeCacheSource;
  Uint8List? _landscapeCacheBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final decoded = await ImageCodec.decodeFile(widget.imageFile);
      final working = ImageCodec.downscaleForEditing(decoded, maxDimension: 1600);
      setState(() {
        _original = working;
        _edited = working.clone();
        _originalBytes = ImageCodec.encodePng(_original!);
        _editedBytes = _originalBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Não foi possível abrir esta imagem: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runTransform(img.Image Function(img.Image src) transform) async {
    if (_edited == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    // Deixa um frame renderizar o spinner antes do processamento (síncrono
    // e potencialmente pesado) tomar a thread principal.
    await Future.delayed(Duration.zero);

    final result = transform(_edited!);
    setState(() {
      _edited = result;
      _editedBytes = ImageCodec.encodePng(_edited!);
      _isProcessing = false;
    });
  }

  void _restoreOriginal() {
    if (_original == null) return;
    setState(() {
      _edited = _original!.clone();
      _editedBytes = _originalBytes;
    });
  }

  Future<void> _openCrop() async {
    if (_edited == null) return;
    final result = await Navigator.of(context).push<img.Image>(
      MaterialPageRoute(builder: (_) => CropScreen(source: _edited!)),
    );
    if (result != null) {
      setState(() {
        _edited = result;
        _editedBytes = ImageCodec.encodePng(_edited!);
      });
    }
  }

  Future<void> _openLiquify() async {
    if (_edited == null) return;
    final result = await Navigator.of(context).push<img.Image>(
      MaterialPageRoute(builder: (_) => LiquifyScreen(source: _edited!)),
    );
    if (result != null) {
      setState(() {
        _edited = result;
        _editedBytes = ImageCodec.encodePng(_edited!);
      });
    }
  }

  void _openPuzzle() {
    if (_edited == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PuzzleScreen(source: _edited!)),
    );
  }

  Future<void> _pickNoiseLevel() async {
    final level = await showModalBottomSheet<NoiseLevel>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nível de ruído', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final option in NoiseLevel.values)
              ListTile(
                title: Text(option.label),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (level != null) {
      await _runTransform((src) => Filters.saltAndPepperNoise(src, level));
    }
  }

  Future<void> _saveLocally() async {
    if (_edited == null) return;
    final bytes = ImageCodec.encodePng(_edited!);
    final result = await LocalStorageService.saveToGallery(bytes);
    if (!mounted) return;
    _showSnack(result.isSuccess ? 'Imagem salva na galeria.' : result.errorMessage!);
  }

  Future<void> _uploadToCloud() async {
    if (_edited == null || _isUploading) return;
    setState(() => _isUploading = true);
    final bytes = ImageCodec.encodePng(_edited!);
    final result = await SupabaseService.uploadImage(bytes);
    if (!mounted) return;
    setState(() => _isUploading = false);
    _showSnack(result.isSuccess ? 'Upload concluído: ${result.publicUrl}' : result.errorMessage!);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Uint8List _redOverlayBytesFor(img.Image source) {
    if (identical(_landscapeCacheSource, source) && _landscapeCacheBytes != null) {
      return _landscapeCacheBytes!;
    }
    final tinted = Filters.redOverlayForDisplay(source);
    _landscapeCacheBytes = ImageCodec.encodePng(tinted);
    _landscapeCacheSource = source;
    return _landscapeCacheBytes!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          IconButton(
            icon: Icon(_showComparison ? Icons.compare : Icons.compare_outlined),
            tooltip: 'Comparar com original',
            onPressed: () => setState(() => _showComparison = !_showComparison),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restaurar original',
            onPressed: _restoreOriginal,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _showComparison
                  ? BeforeAfterView(before: _originalBytes!, after: _editedBytes!)
                  : Builder(
                      builder: (context) {
                        // MediaQuery reflete a orientação real do dispositivo
                        // (gira sozinho, sem depender de nenhum botão) e já
                        // reconstrói esta subárvore automaticamente quando o
                        // usuário vira o aparelho.
                        final orientation = MediaQuery.orientationOf(context);
                        final bytes = orientation == Orientation.landscape
                            ? _redOverlayBytesFor(_edited!)
                            : _editedBytes!;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.memory(bytes, gaplessPlayback: true, fit: BoxFit.contain),
                            if (_isProcessing)
                              Container(
                                color: Colors.black26,
                                child: const CircularProgressIndicator(),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          _Toolbar(
            isUploading: _isUploading,
            onGrayscale: () => _runTransform(Filters.toGrayscale),
            onFlip: () => _runTransform(Filters.flipHorizontal),
            onNoise: _pickNoiseLevel,
            onSharpen: () => _runTransform(Filters.sharpen),
            onHorror: () => _runTransform(Filters.horror),
            onCrop: _openCrop,
            onLiquify: _openLiquify,
            onPuzzle: _openPuzzle,
            onSaveLocal: _saveLocally,
            onUploadCloud: _uploadToCloud,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.isUploading,
    required this.onGrayscale,
    required this.onFlip,
    required this.onNoise,
    required this.onSharpen,
    required this.onHorror,
    required this.onCrop,
    required this.onLiquify,
    required this.onPuzzle,
    required this.onSaveLocal,
    required this.onUploadCloud,
  });

  final bool isUploading;
  final VoidCallback onGrayscale;
  final VoidCallback onFlip;
  final VoidCallback onNoise;
  final VoidCallback onSharpen;
  final VoidCallback onHorror;
  final VoidCallback onCrop;
  final VoidCallback onLiquify;
  final VoidCallback onPuzzle;
  final VoidCallback onSaveLocal;
  final VoidCallback onUploadCloud;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 88,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            _ToolButton(icon: Icons.filter_b_and_w, label: 'P&B', onTap: onGrayscale),
            _ToolButton(icon: Icons.flip, label: 'Espelhar', onTap: onFlip),
            _ToolButton(icon: Icons.grain, label: 'Ruído', onTap: onNoise),
            _ToolButton(icon: Icons.crop, label: 'Cortar', onTap: onCrop),
            _ToolButton(icon: Icons.blur_on, label: 'Nitidez', onTap: onSharpen),
            _ToolButton(icon: Icons.mood_bad, label: 'Horror', onTap: onHorror),
            _ToolButton(icon: Icons.gesture, label: 'Liquify', onTap: onLiquify),
            _ToolButton(icon: Icons.extension, label: 'Puzzle', onTap: onPuzzle),
            _ToolButton(icon: Icons.save_alt, label: 'Salvar', onTap: onSaveLocal),
            _ToolButton(
              icon: isUploading ? Icons.hourglass_top : Icons.cloud_upload,
              label: 'Nuvem',
              onTap: isUploading ? null : onUploadCloud,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: onTap == null ? Colors.grey : null),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
