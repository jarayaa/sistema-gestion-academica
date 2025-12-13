import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/github_api_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _estado = 'Iniciando...';
  
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Paso 1: Verificar actualizaciones
      setState(() => _estado = 'Verificando actualizaciones...');
      await _verificarActualizaciones();
      
      // Paso 2: Verificar si el usuario está registrado
      setState(() => _estado = 'Cargando perfil...');
      final authService = await AuthService.init();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        if (authService.isUsuarioRegistrado()) {
          // Usuario ya registrado, ir al home
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Usuario nuevo, ir a registro
          Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
        }
      }
    } catch (e) {
      setState(() => _estado = 'Error: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
      }
    }
  }

  Future<void> _verificarActualizaciones() async {
    try {
      final apiService = GitHubApiService();
      final updateService = UpdateService(apiService);
      
      final updateInfo = await updateService.checkForUpdates();
      
      if (updateInfo.disponible && mounted) {
        await UpdateDialog.show(context, updateInfo, updateService);
      }
    } catch (e) {
      print('Error al verificar actualizaciones: $e');
      // Continuar aunque falle la verificación
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.school,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Calculadora de Notas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const Text(
              'UNAB',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 48),
            
            const CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _estado,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}