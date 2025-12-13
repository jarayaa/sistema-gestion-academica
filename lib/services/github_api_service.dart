import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GitHubApiService {
  static const String _repoOwner = 'jarayaa';
  static const String _repoName = 'sistema-gestion-academica';
  static const String _branch = 'main';

  Future<List<Map<String, dynamic>>> fetchCarreras() async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json'
      );
      
      debugPrint('🔄 Cargando carreras desde: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData is Map && jsonData.containsKey('carreras')) {
          final List<dynamic> carrerasData = jsonData['carreras'];
          return carrerasData.map((carrera) {
            return {
              'id': carrera['id'],
              'codigo': carrera['codigo'],
              'nombre': carrera['nombre'],
              'facultad': carrera['facultad'],
              'escuela': carrera['escuela'],
              'modalidad': carrera['modalidad'],
              'duracion_trimestres': carrera['duracion_trimestres'],
              'duracion_anos': carrera['duracion_anos'],
              'creditos_totales_sct': carrera['creditos_totales_sct'],
            };
          }).toList().cast<Map<String, dynamic>>();
        }
      }
      return _carrerasPorDefecto();
    } catch (e) {
      debugPrint('❌ Error al cargar carreras desde GitHub: $e');
      return _carrerasPorDefecto();
    }
  }

  Future<Map<String, dynamic>?> fetchMallaCompleta(String carreraId) async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData is Map && jsonData.containsKey('carreras')) {
          final List<dynamic> carreras = jsonData['carreras'];
          final carrera = carreras.firstWhere((c) => c['id'] == carreraId, orElse: () => null);
          return carrera as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error al cargar malla completa: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _carrerasPorDefecto() {
    return [
      {'id': 'ICI_IND_ADV', 'nombre': 'Ingeniería Civil Industrial Advance'},
      {'id': 'ICI_INF_ADV', 'nombre': 'Ingeniería Civil Informática Advance'},
      {'id': 'ING_COM_ADV', 'nombre': 'Ingeniería Comercial Advance'},
      {'id': 'ING_COMP_ADV', 'nombre': 'Ingeniería en Computación e Informática Advance'},
    ];
  }
}