import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'github_api_service.dart';

/// Clase para almacenar información de actualización
class UpdateInfo {
  final bool disponible;
  final String versionActual;
  final String versionNueva;
  final String url;
  final String descripcion;
  final String fechaPublicacion;

  UpdateInfo({
    required this.disponible,
    required this.versionActual,
    required this.versionNueva,
    required this.url,
    required this.descripcion,
    required this.fechaPublicacion,
  });

  UpdateInfo.noDisponible()
      : disponible = false,
        versionActual = '',
        versionNueva = '',
        url = '',
        descripcion = '',
        fechaPublicacion = '';
}

class UpdateService {
  static const String _repoOwner = 'jarayaa';
  static const String _repoName = 'sistema-gestion-academica';

  UpdateService(GitHubApiService apiService);

  /// Verifica si hay actualizaciones disponibles
  Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionActual = packageInfo.version;

      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versionNueva = (data['tag_name'] as String).replaceAll('v', '');

        if (_esVersionMayor(versionNueva, versionActual)) {
          return UpdateInfo(
            disponible: true,
            versionActual: versionActual,
            versionNueva: versionNueva,
            url: data['html_url'] ?? '',
            descripcion: data['body'] ?? 'Nueva versión disponible',
            fechaPublicacion: data['published_at'] ?? '',
          );
        }
      }

      return UpdateInfo.noDisponible();
    } catch (e) {
      // Si hay error, retornar que no hay actualización
      return UpdateInfo.noDisponible();
    }
  }

  /// Compara versiones para determinar si v1 es mayor que v2
  bool _esVersionMayor(String v1, String v2) {
    try {
      final partes1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final partes2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      // Asegurar que ambas listas tengan al menos 3 elementos
      while (partes1.length < 3) {
        partes1.add(0);
      }
      while (partes2.length < 3) {
        partes2.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (partes1[i] > partes2[i]) return true;
        if (partes1[i] < partes2[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la versión actual de la app
  Future<String> getVersionActual() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }
}
