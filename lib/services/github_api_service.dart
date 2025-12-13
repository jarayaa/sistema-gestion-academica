import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GitHubApiService {
  static const String _repoOwner = 'jarayaa';
  static const String _repoName = 'sistema-gestion-academica';
  static const String _branch = 'main';

  // --- MÉTODOS EXISTENTES DE CARRERAS (fetchCarreras, etc) SE MANTIENEN IGUAL ---
  // ... (Mantén tu código anterior de fetchCarreras aquí) ...

  /// NUEVO: Busca un estudiante por su RUT en estudiantes.json
  Future<Map<String, dynamic>?> buscarEstudiantePorRut(String run) async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/estudiantes.json'
      );
      
      debugPrint('🔍 Buscando estudiante en: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final estudiantes = data['estudiantes'] as List;
        
        // Limpiamos el RUT de entrada y el del JSON para comparar solo números y K
        final runLimpio = run.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
        
        final estudiante = estudiantes.firstWhere(
          (e) => (e['run'] as String).replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase() == runLimpio,
          orElse: () => null,
        );
        
        return estudiante;
      }
    } catch (e) {
      debugPrint('❌ Error al buscar estudiante: $e');
    }
    return null;
  }

  // --- RESTO DE MÉTODOS (fetchConfig, fetchMallaCompleta) SE MANTIENEN IGUAL ---
  // Asegúrate de incluir fetchCarreras, fetchConfig, fetchMallaCompleta aquí abajo como estaban.
  // Solo estoy ahorrando espacio en la respuesta, pero el archivo debe tener todo.
  
  // Copia aquí el resto de tu archivo original...
  Future<List<Map<String, dynamic>>> fetchCarreras() async {
    try {
      final url = Uri.parse('https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(jsonData['carreras']);
      }
      return _carrerasPorDefecto();
    } catch (e) {
      return _carrerasPorDefecto();
    }
  }
  
  Future<Map<String, dynamic>?> fetchMallaCompleta(String carreraId) async {
     // Implementación existente...
     try {
      final url = Uri.parse('https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        final lista = jsonData['carreras'] as List;
        return lista.firstWhere((c) => c['id'] == carreraId, orElse: () => null);
      }
      return null;
    } catch (e) {
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