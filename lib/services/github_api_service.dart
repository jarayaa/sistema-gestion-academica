import 'dart:convert';
import 'package:flutter/foundation.dart'; // Agregado para usar debugPrint
import 'package:http/http.dart' as http;

class GitHubApiService {
  
  static const String _baseUrl = 
    'https://raw.githubusercontent.com/jarayaa/sistema-gestion-academica/main/data';
  
  // Cache en memoria para evitar llamadas repetidas
  static Map<String, dynamic>? _mallasCache;
  static Map<String, dynamic>? _configCache;
  static DateTime? _lastFetch;
  
  // Tiempo de cache: 5 minutos
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  /// Verifica si el cache está vigente
  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }
  
  /// Obtiene las mallas curriculares
  Future<Map<String, dynamic>> fetchMallas({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid() && _mallasCache != null) {
      return _mallasCache!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mallas.json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _mallasCache = json.decode(response.body);
        _lastFetch = DateTime.now();
        return _mallasCache!;
      } else {
        throw Exception('Error ${response.statusCode}: No se pudieron cargar las mallas');
      }
    } catch (e) {
      // Si hay cache, retornar aunque esté expirado
      if (_mallasCache != null) {
        return _mallasCache!;
      }
      rethrow;
    }
  }
  
  /// Obtiene la lista de carreras disponibles
  Future<List<Map<String, dynamic>>> fetchCarreras() async {
    final data = await fetchMallas();
    return List<Map<String, dynamic>>.from(data['carreras'] ?? []);
  }
  
  /// Obtiene una carrera específica por ID
  Future<Map<String, dynamic>?> fetchCarreraPorId(String carreraId) async {
    final carreras = await fetchCarreras();
    try {
      return carreras.firstWhere((c) => c['id'] == carreraId);
    } catch (e) {
      return null;
    }
  }
  
  /// Obtiene las asignaturas de un trimestre específico
  Future<List<Map<String, dynamic>>> fetchAsignaturas(
    String carreraId, 
    int trimestre
  ) async {
    final carrera = await fetchCarreraPorId(carreraId);
    if (carrera == null) return [];
    
    final trimestres = List<Map<String, dynamic>>.from(carrera['trimestres'] ?? []);
    final trimestreData = trimestres.firstWhere(
      (t) => t['numero'] == trimestre,
      orElse: () => {'asignaturas': []},
    );
    
    return List<Map<String, dynamic>>.from(trimestreData['asignaturas'] ?? []);
  }
  
  /// Obtiene los datos de un estudiante por RUN
  Future<Map<String, dynamic>?> fetchEstudiante(String run) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/estudiantes.json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final estudiantes = List<Map<String, dynamic>>.from(data['estudiantes'] ?? []);
        
        // Normalizar RUN (quitar puntos y guiones para comparar)
        final runNormalizado = run.replaceAll(RegExp(r'[.-]'), '').toUpperCase();
        
        return estudiantes.firstWhere(
          (e) {
            final runEstudiante = (e['run'] as String).replaceAll(RegExp(r'[.-]'), '').toUpperCase();
            return runEstudiante == runNormalizado;
          },
          orElse: () => <String, dynamic>{},
        );
      }
    } catch (e) {
      debugPrint('Error al buscar estudiante: $e');
    }
    return null;
  }
  
  /// Obtiene las notas de un estudiante para una asignatura
  Future<Map<String, dynamic>?> fetchNotasEstudiante(
    String run, 
    String codigoAsignatura
  ) async {
    final estudiante = await fetchEstudiante(run);
    if (estudiante == null || estudiante.isEmpty) return null;
    
    final notas = estudiante['notas'] as Map<String, dynamic>?;
    return notas?[codigoAsignatura] as Map<String, dynamic>?;
  }
  
  /// Obtiene la configuración de la app (incluyendo actualizaciones)
  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid() && _configCache != null) {
      return _configCache!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/config.json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _configCache = json.decode(response.body);
        return _configCache!;
      } else {
        throw Exception('Error al cargar configuración');
      }
    } catch (e) {
      if (_configCache != null) return _configCache!;
      rethrow;
    }
  }
  
  /// Limpia el cache
  void clearCache() {
    _mallasCache = null;
    _configCache = null;
    _lastFetch = null;
  }
}