import 'package:flutter/foundation.dart'; // ✅ NECESARIO para debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AuthService {
  static const String _keyDeviceId = 'device_unique_id';
  static const String _keyRun = 'user_run';
  static const String _keyCarreraId = 'user_carrera_id';
  static const String _keyNombreUsuario = 'user_nombre';
  static const String _keyFechaRegistro = 'user_fecha_registro';
  
  final SharedPreferences _prefs;
  
  AuthService(this._prefs);
  
  /// Inicializa el servicio de autenticación
  static Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = AuthService(prefs);
    
    // Generar Device ID si no existe
    await service._ensureDeviceId();
    
    return service;
  }
  
  /// Asegura que exista un Device ID único
  Future<void> _ensureDeviceId() async {
    if (_prefs.getString(_keyDeviceId) == null) {
      final deviceId = await _generateDeviceId();
      await _prefs.setString(_keyDeviceId, deviceId);
    }
  }
  
  /// Genera un ID único basado en el dispositivo
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String uniqueId;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Combinar varios identificadores para mayor unicidad
        uniqueId = '${androidInfo.id}_${androidInfo.fingerprint}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        uniqueId = iosInfo.identifierForVendor ?? const Uuid().v4();
      } else {
        uniqueId = const Uuid().v4();
      }
    } catch (e) {
      // Fallback a UUID si falla la obtención de info del dispositivo
      uniqueId = const Uuid().v4();
    }
    
    // Agregar timestamp para asegurar unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${uniqueId}_$timestamp';
  }
  
  /// Obtiene el Device ID (perpetuo hasta que se elimine la app)
  String? getDeviceId() {
    return _prefs.getString(_keyDeviceId);
  }
  
  /// Registra un usuario con su RUN
  Future<bool> registrarUsuario({
    required String run,
    required String nombre,
    required String carreraId,
  }) async {
    try {
      // Validar formato de RUN chileno
      if (!_validarRun(run)) {
        throw Exception('RUN inválido');
      }
      
      await _prefs.setString(_keyRun, _formatearRun(run));
      await _prefs.setString(_keyNombreUsuario, nombre);
      await _prefs.setString(_keyCarreraId, carreraId);
      await _prefs.setString(_keyFechaRegistro, DateTime.now().toIso8601String());
      
      return true;
    } catch (e) {
      // ✅ CORRECCIÓN AQUÍ: debugPrint
      debugPrint('Error al registrar usuario: $e');
      return false;
    }
  }
  
  /// Valida el formato del RUN chileno
  bool _validarRun(String run) {
    // Limpiar el RUN
    final runLimpio = run.replaceAll(RegExp(r'[.-]'), '').toUpperCase();
    
    if (runLimpio.length < 8 || runLimpio.length > 9) return false;
    
    final cuerpo = runLimpio.substring(0, runLimpio.length - 1);
    final dv = runLimpio.substring(runLimpio.length - 1);
    
    // Calcular dígito verificador
    int suma = 0;
    int multiplicador = 2;
    
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    
    final resto = suma % 11;
    final dvCalculado = resto == 0 ? '0' : (resto == 1 ? 'K' : (11 - resto).toString());
    
    return dv == dvCalculado;
  }
  
  /// Formatea el RUN con puntos y guión
  String _formatearRun(String run) {
    final runLimpio = run.replaceAll(RegExp(r'[.-]'), '').toUpperCase();
    final cuerpo = runLimpio.substring(0, runLimpio.length - 1);
    final dv = runLimpio.substring(runLimpio.length - 1);
    
    // Agregar puntos cada 3 dígitos
    String cuerpoFormateado = '';
    for (int i = 0; i < cuerpo.length; i++) {
      if (i > 0 && (cuerpo.length - i) % 3 == 0) {
        cuerpoFormateado += '.';
      }
      cuerpoFormateado += cuerpo[i];
    }
    
    return '$cuerpoFormateado-$dv';
  }
  
  /// Obtiene el RUN del usuario registrado
  String? getRun() {
    return _prefs.getString(_keyRun);
  }
  
  /// Obtiene el nombre del usuario
  String? getNombre() {
    return _prefs.getString(_keyNombreUsuario);
  }
  
  /// Obtiene la carrera seleccionada
  String? getCarreraId() {
    return _prefs.getString(_keyCarreraId);
  }
  
  /// Verifica si el usuario está registrado
  bool isUsuarioRegistrado() {
    return _prefs.getString(_keyRun) != null;
  }
  
  /// Cierra la sesión (elimina datos del usuario pero mantiene Device ID)
  Future<void> cerrarSesion() async {
    await _prefs.remove(_keyRun);
    await _prefs.remove(_keyNombreUsuario);
    await _prefs.remove(_keyCarreraId);
    await _prefs.remove(_keyFechaRegistro);
    // Nota: NO eliminamos el Device ID
  }
  
  /// Obtiene información completa del usuario
  Map<String, String?> getUsuarioInfo() {
    return {
      'deviceId': getDeviceId(),
      'run': getRun(),
      'nombre': getNombre(),
      'carreraId': getCarreraId(),
      'fechaRegistro': _prefs.getString(_keyFechaRegistro),
    };
  }
}