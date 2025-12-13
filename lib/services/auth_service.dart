import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyRegistrado = 'usuario_registrado';
  static const String _keyRun = 'usuario_run';
  static const String _keyNombre = 'usuario_nombre';
  static const String _keyCarreraId = 'usuario_carrera_id';

  final SharedPreferences _prefs;

  AuthService._(this._prefs);

  static Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService._(prefs);
  }

  bool isUsuarioRegistrado() {
    return _prefs.getBool(_keyRegistrado) == true && 
           _prefs.getString(_keyCarreraId) != null;
  }

  Future<bool> registrarUsuario({
    required String run,
    required String nombre,
    required String carreraId,
  }) async {
    await _prefs.setBool(_keyRegistrado, true);
    await _prefs.setString(_keyRun, run);
    await _prefs.setString(_keyNombre, nombre);
    await _prefs.setString(_keyCarreraId, carreraId);
    return true;
  }

  String? getCarreraId() => _prefs.getString(_keyCarreraId);
  String? getNombre() => _prefs.getString(_keyNombre);
  String? getRun() => _prefs.getString(_keyRun); // Necesario para borrar en Firebase

  Future<void> cerrarSesion() async {
    await _prefs.remove(_keyRegistrado);
  }

  Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}