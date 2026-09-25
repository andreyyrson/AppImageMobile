import 'package:permission_handler/permission_handler.dart';

enum PermissionResult { granted, denied, permanentlyDenied }

/// Solicita e trata permissões de câmera e galeria. Mantido separado das
/// telas para centralizar a lógica de "negado x negado para sempre"
/// (importante para orientar o usuário a abrir as configurações do app).
class PermissionService {
  PermissionService._();

  static Future<PermissionResult> requestCamera() => _request(Permission.camera);

  static Future<PermissionResult> requestGallery() => _request(Permission.photos);

  static Future<PermissionResult> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return PermissionResult.granted;
    if (status.isPermanentlyDenied) return PermissionResult.permanentlyDenied;
    return PermissionResult.denied;
  }

  static Future<void> openSettings() => openAppSettings();
}
