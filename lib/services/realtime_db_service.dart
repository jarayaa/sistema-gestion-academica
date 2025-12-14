import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  static const String _nodeEstudiantes = 'estudiantes';

  /// Obtiene los datos básicos del perfil (nombre, carrera activa e historial)
  Future<Map<String, dynamic>?> obtenerEstudiante(String run) async {
    try {
      final key = _limpiarRut(run);
      final snapshot = await _dbRef.child('$_nodeEstudiantes/$key').get();

      if (snapshot.exists) {
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

  /// Guarda el perfil, actualiza la carrera activa y registra el HISTORIAL
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
        'carrera_id': carreraId, // Puntero a la última carrera activa
        'ultima_actualizacion': ServerValue.timestamp,
      };

      // 1. Actualizar datos raíz del usuario
      await _dbRef.child('$_nodeEstudiantes/$key').update(datos);
      
      // 2. Registrar en el historial que este usuario tiene esta carrera
      await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras/$carreraId').set(true);

      debugPrint('💾 Perfil sincronizado para $run (Carrera: $carreraId)');
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
      
      await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId/asignaturas/$codigo').set(asignaturaJson);
      
      debugPrint('☁️ Notas de $codigo guardadas en carrera $carreraId.');
    } catch (e) {
      debugPrint('❌ Error al sincronizar notas: $e');
    }
  }

  /// Borra la carrera actual. Si el usuario se queda sin carreras, SE BORRA EL USUARIO.
  Future<bool> borrarCarrera(String run, String carreraId) async {
    try {
      final key = _limpiarRut(run);
      
      // 1. Borrar las notas y datos de ESTA carrera específica
      await _dbRef.child('$_nodeEstudiantes/$key/carreras/$carreraId').remove();
      
      // 2. Quitarla del historial
      await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras/$carreraId').remove();
      
      // 3. Si la carrera borrada era la "activa", limpiamos ese campo
      final pointerSnap = await _dbRef.child('$_nodeEstudiantes/$key/carrera_id').get();
      if (pointerSnap.exists && pointerSnap.value == carreraId) {
         await _dbRef.child('$_nodeEstudiantes/$key/carrera_id').remove();
      }

      // --- VALIDACIÓN DE LIMPIEZA TOTAL ---
      // 4. Verificar si quedan otras carreras en el historial
      final historySnap = await _dbRef.child('$_nodeEstudiantes/$key/historial_carreras').get();

      if (!historySnap.exists || historySnap.children.isEmpty) {
        // CASO: No quedan carreras asociadas -> Borramos todo el nodo del usuario
        await _dbRef.child('$_nodeEstudiantes/$key').remove();
        debugPrint('🗑️ Usuario $run eliminado completamente (sin carreras restantes).');
      } else {
        debugPrint('🗑️ Carrera $carreraId eliminada. El usuario conserva otras carreras.');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar carrera: $e');
      return false;
    }
  }

  /// Método legacy (por si se necesita borrar forzosamente todo)
  Future<bool> borrarEstudianteCompleto(String run) async {
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