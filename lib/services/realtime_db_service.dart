import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  static const String _nodeEstudiantes = 'estudiantes';

  /// Obtiene los datos básicos del perfil (nombre, carrera activa)
  Future<Map<String, dynamic>?> obtenerEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key').get();

      if (snapshot.exists) {
        // Retornamos los datos planos del usuario, sin profundizar en todas las asignaturas aún
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('✅ Estudiante encontrado: $run');
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error al leer perfil: $e');
      return null;
    }
  }

  /// Obtiene las notas guardadas ESPECÍFICAMENTE para una carrera
  Future<List<Map<String, dynamic>>> obtenerNotasDeCarrera(String run, String carreraId) async {
    try {
      final key = _limpiarRut(run);
      // Ruta: estudiantes/RUN/carreras/ID_CARRERA/asignaturas
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId/asignaturas').get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> mapaNotas = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> lista = [];
        
        mapaNotas.forEach((codigo, data) {
          lista.add(Map<String, dynamic>.from(data as Map));
        });
        
        debugPrint('📥 Descargadas ${lista.length} asignaturas para la carrera $carreraId');
        return lista;
      }
    } catch (e) {
      debugPrint('⚠️ No se pudieron descargar notas remotas: $e');
    }
    return [];
  }

  /// Guarda el perfil y actualiza el "puntero" de la carrera activa
  Future<bool> guardarEstudiante({
    required String run,
    required String nombre,
    required String carreraId,
  }) async {
    try {
      final key = _limpiarRut(run);
      
      final datos = {
        'run': run,
        'nombre': nombre,
        'carrera_id': carreraId, // Actualiza la carrera activa actual
        'ultima_actualizacion': ServerValue.timestamp,
      };

      // 1. Actualizar datos raíz del usuario
      await _dbRef.child('$_nodeEstudiantes/$key').update(datos);
      
      // 2. Registrar en el historial que este usuario tiene esta carrera
      // Esto sirve para saber que la carrera existe aunque no sea la activa
      await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras/$carreraId').set(true);

      debugPrint('💾 Perfil sincronizado para $run');
      return true;
    } catch (e) {
      debugPrint('❌ Error al escribir perfil: $e');
      return false;
    }
  }

  /// Guarda las notas DENTRO de la carpeta de la carrera correspondiente
  Future<void> guardarAsignatura(String run, String carreraId, Map<String, dynamic> asignaturaJson) async {
    try {
      final key = _limpiarRut(run);
      final codigo = asignaturaJson['codigoAsignatura'];
      
      // Estructura Jerárquica: estudiantes -> RUN -> carreras -> ID_CARRERA -> asignaturas -> CODIGO
      await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId/asignaturas/$codigo').set(asignaturaJson);
      
      debugPrint('☁️ Notas de $codigo guardadas en carrera $carreraId.');
    } catch (e) {
      debugPrint('❌ Error al sincronizar notas: $e');
    }
  }

  Future<bool> borrarEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      await _dbRef.child('$_nodeEstudiantes/$key').remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  String _limpiarRut(String run) {
    return run.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }
}