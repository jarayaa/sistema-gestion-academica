import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  static const String _nodeEstudiantes = 'estudiantes';

  Future<Map<String, dynamic>?> obtenerEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key').get();

      if (snapshot.exists) {
        debugPrint('✅ Estudiante encontrado en Realtime DB: $run');
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        debugPrint('⚠️ Estudiante nuevo: $run');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error al leer Realtime DB: $e');
      return null;
    }
  }

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
      debugPrint('💾 Datos sincronizados en Realtime DB para $run');
      return true;
    } catch (e) {
      debugPrint('❌ Error al escribir en Realtime DB: $e');
      return false;
    }
  }

  /// Borra el registro del estudiante de la base de datos
  Future<bool> borrarEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      await _dbRef.child('$_nodeEstudiantes/$key').remove();
      debugPrint('🗑️ Datos borrados de Firebase para $run');
      return true;
    } catch (e) {
      debugPrint('❌ Error al borrar de Realtime DB: $e');
      return false;
    }
  }

  String _limpiarRut(String run) {
    return run.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }
}