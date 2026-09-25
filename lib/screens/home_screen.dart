import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_source_service.dart';
import '../services/permission_service.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickFromCamera(BuildContext context) async {
    final result = await PermissionService.requestCamera();
    if (!context.mounted) return;
    if (result == PermissionResult.denied) {
      _showSnack(context, 'Permissão de câmera negada.');
      return;
    }
    if (result == PermissionResult.permanentlyDenied) {
      _showSettingsDialog(context, 'câmera');
      return;
    }

    final file = await ImageSourceService.pickFromCamera();
    if (file != null && context.mounted) _openEditor(context, file);
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final result = await PermissionService.requestGallery();
    if (!context.mounted) return;
    if (result == PermissionResult.permanentlyDenied) {
      _showSettingsDialog(context, 'galeria');
      return;
    }
    // Em Android 13+ o seletor de fotos moderno não exige a permissão
    // READ_MEDIA_IMAGES; "denied" aqui não impede necessariamente a escolha,
    // então tentamos abrir o seletor mesmo assim.

    final file = await ImageSourceService.pickFromGallery();
    if (file != null && context.mounted) _openEditor(context, file);
  }

  void _openEditor(BuildContext context, File file) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(imageFile: file)),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSettingsDialog(BuildContext context, String recurso) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão necessária'),
        content: Text(
          'O acesso à $recurso foi negado permanentemente. Abra as configurações do app para conceder a permissão.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionService.openSettings();
            },
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Imagens')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, size: 96, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Capture ou selecione uma imagem para começar a editar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _pickFromCamera(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar foto'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickFromGallery(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
