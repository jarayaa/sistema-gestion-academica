import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'github_api_service.dart';

enum UpdateType {
  none,       // No hay actualización
  optional,   // Actualización opcional
  recommended,// Actualización recomendada
  critical,   // Actualización crítica (forzosa)
}

class UpdateInfo {
  final bool disponible;
  final UpdateType tipo;
  final String versionActual;
  final String versionNueva;
  final List<String> changelog;
  final String? urlDescarga;
  final bool esForzosa;
  
  UpdateInfo({
    required this.disponible,
    required this.tipo,
    required this.versionActual,
    required this.versionNueva,
    required this.changelog,
    this.urlDescarga,
    this.esForzosa = false,
  });
}

class UpdateService {
  final GitHubApiService _apiService;
  
  UpdateService(this._apiService);
  
  /// Verifica si hay actualizaciones disponibles
  Future<UpdateInfo> checkForUpdates() async {
    try {
      // Obtener versión actual de la app
      final packageInfo = await PackageInfo.fromPlatform();
      final versionActual = packageInfo.version;
      final buildActual = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      // Obtener configuración del servidor
      final config = await _apiService.fetchConfig(forceRefresh: true);
      final updateConfig = config['actualizaciones'] as Map<String, dynamic>?;
      
      if (updateConfig == null) {
        return UpdateInfo(
          disponible: false,
          tipo: UpdateType.none,
          versionActual: versionActual,
          versionNueva: versionActual,
          changelog: [],
        );
      }
      
      final versionNueva = updateConfig['version'] as String? ?? versionActual;
      final buildNuevo = updateConfig['build_number'] as int? ?? buildActual;
      final esCritica = updateConfig['es_critica'] as bool? ?? false;
      final esForzosa = updateConfig['es_forzosa'] as bool? ?? false;
      final changelog = List<String>.from(updateConfig['changelog'] ?? []);
      
      // Determinar URL de descarga según plataforma
      final urls = updateConfig['urls'] as Map<String, dynamic>?;
      String? urlDescarga;
      if (urls != null) {
        if (Platform.isAndroid) {
          urlDescarga = urls['android'] as String?;
        } else if (Platform.isIOS) {
          urlDescarga = urls['ios'] as String?;
        }
      }
      
      // Comparar versiones
      final hayActualizacion = _compararVersiones(versionActual, versionNueva) < 0 ||
                               buildActual < buildNuevo;
      
      if (!hayActualizacion) {
        return UpdateInfo(
          disponible: false,
          tipo: UpdateType.none,
          versionActual: versionActual,
          versionNueva: versionNueva,
          changelog: changelog,
        );
      }
      
      // Determinar tipo de actualización
      UpdateType tipo;
      if (esForzosa || esCritica) {
        tipo = UpdateType.critical;
      } else if (_esMajorUpdate(versionActual, versionNueva)) {
        tipo = UpdateType.recommended;
      } else {
        tipo = UpdateType.optional;
      }
      
      return UpdateInfo(
        disponible: true,
        tipo: tipo,
        versionActual: versionActual,
        versionNueva: versionNueva,
        changelog: changelog,
        urlDescarga: urlDescarga,
        esForzosa: esForzosa,
      );
    } catch (e) {
      print('Error al verificar actualizaciones: $e');
      final packageInfo = await PackageInfo.fromPlatform();
      return UpdateInfo(
        disponible: false,
        tipo: UpdateType.none,
        versionActual: packageInfo.version,
        versionNueva: packageInfo.version,
        changelog: [],
      );
    }
  }
  
  /// Compara dos versiones semánticas
  /// Retorna: -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2
  int _compararVersiones(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    // Asegurar que ambas tengan 3 partes
    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }
    
    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }
  
  /// Verifica si es una actualización mayor (cambio en major o minor)
  bool _esMajorUpdate(String v1, String v2) {
    final parts1 = v1.split('.');
    final parts2 = v2.split('.');
    
    // Si cambia el major o minor, es major update
    return parts1[0] != parts2[0] || 
           (parts1.length > 1 && parts2.length > 1 && parts1[1] != parts2[1]);
  }
  
  /// Abre la URL de descarga/actualización
  Future<bool> abrirActualizacion(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
    } catch (e) {
      print('Error al abrir URL de actualización: $e');
    }
    return false;
  }
}