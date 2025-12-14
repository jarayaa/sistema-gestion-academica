import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  static const String _nodeEstudiantes = 'estudiantes';

  /// Obtiene los datos básicos del perfil
  Future<Map<String, dynamic>?> obtenerEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error al leer perfil: $e');
      return null;
    }
  }

  /// Obtiene las notas de una carrera específica
  Future<List<Map<String, dynamic>>> obtenerNotasDeCarrera(String run, String carreraId) async {
    try {
      final key = _limpiarRut(run);
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

  /// Guarda perfil y actualiza historial
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
        'carrera_id': carreraId,
        'ultima_actualizacion': ServerValue.timestamp,
      };

      await _dbRef.child('$_nodeEstudiantes/$key').update(datos);
      
      // Registrar en el historial para que aparezca en verde
      await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras/$carreraId').set(true);

      debugPrint('💾 Perfil sincronizado para $run (Carrera: $carreraId)');
      return true;
    } catch (e) {
      debugPrint('❌ Error al escribir perfil: $e');
      return false;
    }
  }

  /// Guarda notas jerárquicamente
  Future<void> guardarAsignatura(String run, String carreraId, Map<String, dynamic> asignaturaJson) async {
    try {
      final key = _limpiarRut(run);
      final codigo = asignaturaJson['codigoAsignatura'];
      
      await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId/asignaturas/$codigo').set(asignaturaJson);
      
      debugPrint('☁️ Notas de $codigo guardadas en carrera $carreraId.');
    } catch (e) {
      debugPrint('❌ Error al sincronizar notas: $e');
    }
  }

  /// NUEVO: Borra SOLO la carrera actual, manteniendo el usuario y otras carreras
  Future<bool> borrarCarrera(String run, String carreraId) async {
    try {
      final key = _limpiarRut(run);
      
      // 1. Borrar las notas y datos de ESTA carrera específica
      await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId').remove();
      
      // 2. Quitarla del historial (para que deje de salir verde en el login)
      await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras/$carreraId').remove();
      
      // 3. (Opcional) Si la carrera borrada era la "activa", limpiamos ese campo
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key/carrera_id').get();
      if (snapshot.exists && snapshot.value == carreraId) {
         await _dbRef.child('$_nodeEstudiantes/$key/carrera_id').remove();
      }

      debugPrint('🗑️ Carrera $carreraId eliminada para el usuario $run');
      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar carrera: $e');
      return false;
    }
  }

  String _limpiarRut(String run) {
    return run.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }
}