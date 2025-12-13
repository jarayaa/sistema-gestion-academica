import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AuthService {
  static const String _keyRegistrado = 'usuario_registrado';
  static const String _keyRun = 'usuario_run';
  static const String _keyNombre = 'usuario_nombre';
  static const String _keyCarreraId = 'usuario_carrera_id';
  static const String _keyDeviceId = 'device_id';

  final SharedPreferences _prefs;

  AuthService._(this._prefs);

  /// Inicializa el servicio de autenticación
  static Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService._(prefs);
  }

  /// Verifica si el usuario está registrado
  bool isUsuarioRegistrado() {
    return _prefs.getBool(_keyRegistrado) ?? false;
  }

  /// Registra un nuevo usuario
  Future<bool> registrarUsuario({
    required String run,
    required String nombre,
    required String carreraId,
  }) async {
    try {
      await _prefs.setBool(_keyRegistrado, true);
      await _prefs.setString(_keyRun, run);
      await _prefs.setString(_keyNombre, nombre);
      await _prefs.setString(_keyCarreraId, carreraId);
      
      // Generar un ID de dispositivo si no existe
      if (!_prefs.containsKey(_keyDeviceId)) {
        final deviceId = _generarDeviceId();
        await _prefs.setString(_keyDeviceId, deviceId);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los datos del usuario registrado
  Map<String, String> obtenerDatosUsuario() {
    return {
      'run': _prefs.getString(_keyRun) ?? '',
      'nombre': _prefs.getString(_keyNombre) ?? '',
      'carreraId': _prefs.getString(_keyCarreraId) ?? '',
    };
  }

  /// Obtiene el RUN del usuario
  String? getRun() {
    return _prefs.getString(_keyRun);
  }

  /// Obtiene el nombre del usuario
  String? getNombre() {
    return _prefs.getString(_keyNombre);
  }

  /// Obtiene el ID de la carrera del usuario
  String? getCarreraId() {
    return _prefs.getString(_keyCarreraId);
  }

  /// Obtiene el ID del dispositivo
  String getDeviceId() {
    if (!_prefs.containsKey(_keyDeviceId)) {
      final deviceId = _generarDeviceId();
      _prefs.setString(_keyDeviceId, deviceId);
      return deviceId;
    }
    return _prefs.getString(_keyDeviceId) ?? '';
  }

  /// Cierra la sesión del usuario
  Future<void> cerrarSesion() async {
    final deviceId = _prefs.getString(_keyDeviceId);
    await _prefs.clear();
    if (deviceId != null) {
      await _prefs.setString(_keyDeviceId, deviceId);
    }
  }

  /// Genera un ID único para el dispositivo
  String _generarDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other';
    return '$platform-$timestamp';
  }
}
