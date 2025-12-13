import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApiService {
  static const String _repoOwner = 'jarayaa';
  static const String _repoName = 'sistema-gestion-academica';
  static const String _branch = 'main';

  /// Obtiene la lista de carreras desde GitHub (mallas.json)
  Future<List<Map<String, dynamic>>> fetchCarreras() async {
    try {
      // URL del archivo mallas.json en GitHub
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json'
      );
      
      print('🔄 Cargando carreras desde: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Decodificar el JSON
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Extraer la lista de carreras
        if (jsonData is Map && jsonData.containsKey('carreras')) {
          final List<dynamic> carrerasData = jsonData['carreras'];
          
          // Convertir a lista de mapas
          final carreras = carrerasData.map((carrera) {
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
          
          print('✅ Carreras cargadas exitosamente: ${carreras.length}');
          return carreras;
        }
        
        print('⚠️ Estructura JSON inesperada');
        return _carrerasPorDefecto();
      }
      
      print('⚠️ Error HTTP ${response.statusCode}');
      return _carrerasPorDefecto();
    } catch (e) {
      print('❌ Error al cargar carreras desde GitHub: $e');
      // Si falla, usar carreras por defecto
      return _carrerasPorDefecto();
    }
  }

  /// Obtiene información de una carrera específica por ID
  Future<Map<String, dynamic>?> fetchCarreraPorId(String carreraId) async {
    try {
      final carreras = await fetchCarreras();
      return carreras.firstWhere(
        (c) => c['id'] == carreraId,
        orElse: () => {},
      );
    } catch (e) {
      print('❌ Error al buscar carrera por ID: $e');
      return null;
    }
  }

  /// Obtiene la configuración de la app desde GitHub (config.json)
  Future<Map<String, dynamic>> fetchConfig() async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/config.json'
      );
      
      print('🔄 Cargando configuración desde: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final config = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        print('✅ Configuración cargada exitosamente');
        return config;
      }
      
      print('⚠️ Error HTTP ${response.statusCode} al cargar config');
      return {};
    } catch (e) {
      print('❌ Error al cargar configuración: $e');
      return {};
    }
  }

  /// Obtiene la malla completa de una carrera específica
  Future<Map<String, dynamic>?> fetchMallaCompleta(String carreraId) async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/data/mallas.json'
      );
      
      print('🔄 Cargando malla completa para carrera: $carreraId');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (jsonData is Map && jsonData.containsKey('carreras')) {
          final List<dynamic> carreras = jsonData['carreras'];
          
          // Buscar la carrera específica
          final carrera = carreras.firstWhere(
            (c) => c['id'] == carreraId,
            orElse: () => null,
          );
          
          if (carrera != null) {
            print('✅ Malla completa cargada para $carreraId');
            return carrera as Map<String, dynamic>;
          }
        }
      }
      
      print('⚠️ No se encontró la malla para $carreraId');
      return null;
    } catch (e) {
      print('❌ Error al cargar malla completa: $e');
      return null;
    }
  }

  /// Lista de carreras por defecto (fallback cuando GitHub no está disponible)
  List<Map<String, dynamic>> _carrerasPorDefecto() {
    print('⚠️ Usando carreras por defecto (fallback)');
    return [
      {
        'id': 'ICI_IND_ADV',
        'codigo': 'UNAB37044',
        'nombre': 'Ingeniería Civil Industrial Advance',
        'facultad': 'Facultad de Ingeniería',
        'escuela': 'Escuela de Industrias',
        'modalidad': 'Full Online Vespertino',
        'duracion_trimestres': 15,
        'duracion_anos': 5,
        'creditos_totales_sct': 300,
      },
      {
        'id': 'ICI_INF_ADV',
        'codigo': 'UNAB32215',
        'nombre': 'Ingeniería Civil Informática Advance',
        'facultad': 'Facultad de Ingeniería',
        'escuela': 'Escuela de Informática',
        'modalidad': 'Full Online Vespertino',
        'duracion_trimestres': 10,
        'duracion_anos': 3.5,
        'creditos_totales_sct': 200,
      },
      {
        'id': 'ING_COM_ADV',
        'codigo': 'UNAB_ICOM',
        'nombre': 'Ingeniería Comercial Advance',
        'facultad': 'Facultad de Economía y Negocios',
        'escuela': 'Escuela de Comercio',
        'modalidad': 'Full Online Vespertino',
        'duracion_trimestres': 9,
        'duracion_anos': 3,
        'creditos_totales_sct': 180,
      },
      {
        'id': 'ING_COMP_ADV',
        'codigo': 'UNAB_ICOMP',
        'nombre': 'Ingeniería en Computación e Informática Advance',
        'facultad': 'Facultad de Ingeniería',
        'escuela': 'Escuela de Informática',
        'modalidad': 'Full Online Vespertino',
        'duracion_trimestres': 8,
        'duracion_anos': 2.7,
        'creditos_totales_sct': 160,
      },
    ];
  }
}
