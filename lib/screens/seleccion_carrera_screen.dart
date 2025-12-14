import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/github_api_service.dart';
import '../services/realtime_db_service.dart';

class SeleccionCarreraScreen extends StatefulWidget {
  const SeleccionCarreraScreen({super.key});

  @override
  State<SeleccionCarreraScreen> createState() => _SeleccionCarreraScreenState();
}

class _SeleccionCarreraScreenState extends State<SeleccionCarreraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _runController = TextEditingController();
  final _nombreController = TextEditingController();
  
  // Servicios
  final _apiService = GitHubApiService();
  final _dbService = RealtimeDBService();

  String? _carreraSeleccionada;
  List<Map<String, dynamic>> _carrerasDisponibles = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final carreras = await _apiService.fetchCarreras();
      if (mounted) {
        setState(() {
          _carrerasDisponibles = carreras;
          _cargando = false;
        });
      }
      _verificarSesionExistente();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando carreras: $e')),
        );
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _verificarUsuarioNube() async {
    final run = _runController.text.trim();
    if (run.length < 8) return; 

    final datos = await _dbService.obtenerEstudiante(run);
    
    if (datos != null && mounted) {
      if (_nombreController.text.isEmpty) {
        _nombreController.text = datos['nombre'] ?? '';
      }
      if (_carreraSeleccionada == null && datos['carrera_id'] != null) {
        setState(() {
          final existe = _carrerasDisponibles.any((c) => c['id'] == datos['carrera_id']);
          if (existe) {
            _carreraSeleccionada = datos['carrera_id'];
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido de vuelta! Datos recuperados.'),
          backgroundColor: Color(0xFF34C759),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _verificarSesionExistente() async {
    final auth = await AuthService.init();
    if (auth.isUsuarioRegistrado()) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una carrera')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final run = _runController.text.trim();
      final nombre = _nombreController.text.trim();

      final auth = await AuthService.init();
      await auth.registrarUsuario(
        run: run,
        nombre: nombre,
        carreraId: _carreraSeleccionada!,
      );

      await _dbService.guardarEstudiante(
        run, 
        {    
          'nombre': nombre,
          'carrera_id': _carreraSeleccionada,
          'ultimo_acceso': DateTime.now().toIso8601String(),
        }
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // Widget auxiliar para las etiquetas de los campos
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
        : SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGO DEGRADADO
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFF9C27B0)], // Rosa a Morado
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66E91E63),
                                blurRadius: 20,
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: const Icon(Icons.school, size: 50, color: Colors.white),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Registro de Estudiante',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),

                      // CAMPO RUN
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('RUN'),
                          TextFormField(
                            controller: _runController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '12.345.678-K',
                              // CORRECCIÓN: Uso de withValues en lugar de withOpacity
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF007AFF)),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.text,
                            onChanged: (val) {
                              if(val.length >= 7) _verificarUsuarioNube();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Requerido';
                              if (value.length < 7) return 'RUN inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // CAMPO NOMBRE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nombre Completo'),
                          TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ej: Juan Pérez',
                              // CORRECCIÓN: Uso de withValues en lugar de withOpacity
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF007AFF)),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) => 
                              (value == null || value.isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // CAMPO CARRERA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Carrera'),
                          DropdownButtonFormField<String>(
                            initialValue: _carreraSeleccionada,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2C2C2E),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF007AFF)),
                            decoration: InputDecoration(
                              hintText: 'Selecciona tu carrera',
                              // CORRECCIÓN: Uso de withValues en lugar de withOpacity
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: null,
                              filled: true,
                              fillColor: const Color(0xFF1C1C1E),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _carrerasDisponibles.map((carrera) {
                              return DropdownMenuItem<String>(
                                value: carrera['id'],
                                child: Text(
                                  carrera['nombre'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _carreraSeleccionada = value),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),

                      // BOTÓN COMENZAR
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _guardando ? null : _guardarDatos,
                          child: _guardando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Comenzar',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}