import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Obtiene los datos básicos del estudiante (nombre, carrera_id, etc.)
  Future<Map<String, dynamic>?> obtenerEstudiante(String runUsuario) async {
    try {
      final runLimpio = runUsuario.replaceAll('.', '').replaceAll('-', '').trim();
      final ref = _db.child('estudiantes/$runLimpio');

      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error obteniendo estudiante: $e");
      return null;
    }
  }

  /// Guarda los datos del perfil del estudiante (RUN, Nombre, Carrera seleccionada)
  Future<void> guardarEstudiante(String runUsuario, Map<String, dynamic> data) async {
    try {
      final runLimpio = runUsuario.replaceAll('.', '').replaceAll('-', '').trim();
      final ref = _db.child('estudiantes/$runLimpio');

      // Actualizamos los datos (update para no borrar notas si ya existen)
      await ref.update(data);
      debugPrint("☁️ Estudiante guardado: $runLimpio");
    } catch (e) {
      debugPrint("❌ Error guardando estudiante: $e");
      rethrow; // Corrección del linter
    }
  }

  /// Obtiene todas las notas de una carrera específica convertidas en Lista
  Future<List<Map<String, dynamic>>> obtenerNotasDeCarrera(String runUsuario, String carreraId) async {
    try {
      final runLimpio = runUsuario.replaceAll('.', '').replaceAll('-', '').trim();
      
      final ref = _db.child('estudiantes/$runLimpio/carreras/$carreraId/asignaturas');

      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;

        if (data is Map) {
          return data.values.map((value) {
            final mapValue = Map<String, dynamic>.from(value as Map);
            
            // Aseguramos que 'notas' sea una lista si viene como mapa
            if (mapValue['notas'] is Map) {
              mapValue['notas'] = (mapValue['notas'] as Map).values.toList();
            }
            
            return mapValue;
          }).toList();
          
        } else if (data is List) {
          return data.where((e) => e != null).map((e) {
            return Map<String, dynamic>.from(e as Map);
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      debugPrint("❌ Error RealtimeDB (Obtener Notas): $e");
      return [];
    }
  }

  /// Guarda o actualiza una asignatura
  Future<void> guardarAsignatura(String runUsuario, String carreraId, Map<String, dynamic> asignaturaJson) async {
    try {
      final runLimpio = runUsuario.replaceAll('.', '').replaceAll('-', '').trim();
      final codigo = asignaturaJson['codigoAsignatura'];
      
      final ref = _db.child('estudiantes/$runLimpio/carreras/$carreraId/asignaturas/$codigo');
      
      await ref.set(asignaturaJson);
      debugPrint("☁️ Asignatura $codigo sincronizada en nube.");
    } catch (e) {
      debugPrint("❌ Error RealtimeDB (Guardar Asignatura): $e");
      rethrow; // Corrección del linter: usa rethrow en lugar de throw e
    }
  }

  /// Borra todos los datos de una carrera (para la opción de reiniciar)
  Future<void> borrarCarrera(String runUsuario, String carreraId) async {
    try {
      final runLimpio = runUsuario.replaceAll('.', '').replaceAll('-', '').trim();
      final ref = _db.child('estudiantes/$runLimpio/carreras/$carreraId');
      await ref.remove();
    } catch (e) {
      debugPrint("❌ Error borrando carrera: $e");
      rethrow;
    }
  }
}