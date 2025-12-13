import 'package:flutter/material.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _version = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _cargarVersion();
    _iniciarCarga();
  }

  Future<void> _cargarVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if(mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  Future<void> _iniciarSesionSilenciosa() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        debugPrint("🔐 Sesión segura iniciada: ${userCredential.user?.uid}");
      } else {
        debugPrint("🔐 Usuario ya autenticado: ${user.uid}");
      }
    } catch (e) {
      debugPrint("❌ Error en autenticación anónima: $e");
    }
  }

  void _iniciarCarga() {
    const totalDuration = Duration(milliseconds: 1500);
    const steps = 50;
    final stepDuration = Duration(milliseconds: totalDuration.inMilliseconds ~/ steps);
    
    Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _progress += 1 / steps;
      });

      if (_progress >= 1.0) {
        timer.cancel();
        _navegarSiguientePantalla();
      }
    });
  }

  Future<void> _navegarSiguientePantalla() async {
    await _iniciarSesionSilenciosa();

    final authService = await AuthService.init();
    if (!mounted) return;

    if (authService.isUsuarioRegistrado()) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF8B0088), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_,__,___) => const Icon(Icons.school, size: 80, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B0088), Color(0xFFFF4444)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text('Sistema de Gestión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Roboto')),
                    Text('Académica', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Grupo 3 - APTC106', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8B0088).withValues(alpha: 0.5), const Color(0xFFFF4444).withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_version, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text('Cargando...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B0088), Color(0xFFFF4444)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}