import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class CloudUploadResult {
  const CloudUploadResult.success(this.publicUrl) : errorMessage = null;
  const CloudUploadResult.failure(this.errorMessage) : publicUrl = null;

  final String? publicUrl;
  final String? errorMessage;
  bool get isSuccess => publicUrl != null;
}

/// Upload da imagem processada para o Supabase Storage. As credenciais
/// ficam em [SupabaseConfig] — veja lá antes de testar esta tela.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Chamado uma vez em main.dart. Não derruba o app se as credenciais
  /// ainda não tiverem sido preenchidas: o upload simplesmente falhará com
  /// uma mensagem clara na hora de usar.
  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) return;
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
    _initialized = true;
  }

  static Future<CloudUploadResult> uploadImage(Uint8List pngBytes, {String? fileName}) async {
    if (!SupabaseConfig.isConfigured) {
      return const CloudUploadResult.failure(
        'Supabase não configurado. Preencha lib/services/supabase_config.dart com a URL e a anon key do seu projeto.',
      );
    }

    try {
      final client = Supabase.instance.client;
      final name = fileName ?? 'imagem_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'uploads/$name';

      await client.storage.from(SupabaseConfig.bucket).uploadBinary(
            path,
            pngBytes,
            fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
          );

      final publicUrl = client.storage.from(SupabaseConfig.bucket).getPublicUrl(path);
      return CloudUploadResult.success(publicUrl);
    } on StorageException catch (e) {
      return CloudUploadResult.failure('Falha no upload: ${e.message}');
    } catch (e) {
      return CloudUploadResult.failure('Erro inesperado no upload: $e');
    }
  }
}
