import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  // Instancia de Realtime Database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  // Nodo principal donde se guardarán los alumnos
  static const String _nodeEstudiantes = 'estudiantes';

  /// Busca un estudiante por su RUN.
  Future<Map<String, dynamic>?> obtenerEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      // Leemos el nodo específico del estudiante una sola vez
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key').get();

      if (snapshot.exists) {
        debugPrint('✅ Estudiante encontrado en Realtime DB: $run');
        // Convertimos el objeto genérico a Map
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

  /// Guarda o actualiza un estudiante
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
        'ultima_actualizacion': ServerValue.timestamp, // Marca de tiempo del servidor
      };

      // Guardamos en la ruta estudiantes/RUN_LIMPIO
      await _dbRef.child('$_nodeEstudiantes/$key').update(datos);
      
      debugPrint('💾 Datos sincronizados en Realtime DB para $run');
      return true;
    } catch (e) {
      debugPrint('❌ Error al escribir en Realtime DB: $e');
      return false;
    }
  }

  // Utilidad para limpiar el RUT y usarlo como Key (RTDB no permite ciertos caracteres como keys)
  String _limpiarRut(String run) {
    return run.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }
}