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
  List<String> _carrerasDetectadasIds = [];
  String? _runValidationError;

  List<Map<String, dynamic>> _carrerasDisponibles = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  // Lógica del validador de RUN (Módulo 11) - Implementada localmente
  bool _esRunValido(String rut) {
    if (rut.isEmpty) return false;
    
    String limpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    
    if (limpio.length < 2) return false;
    
    String cuerpo = limpio.substring(0, limpio.length - 1);
    String dv = limpio.substring(limpio.length - 1);
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cuerpo)) return false;
    
    int suma = 0;
    int multiplicador = 2;
    
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador++;
      if (multiplicador > 7) multiplicador = 2;
    }
    
    int resto = 11 - (suma % 11);
    String dvCalculado;
    
    if (resto == 11) {
      dvCalculado = '0';
    } else if (resto == 10) {
      dvCalculado = 'K';
    } else {
      dvCalculado = resto.toString();
    }
    
    return dv == dvCalculado;
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

  // Función para validar RUN en tiempo real y buscar usuario
  Future<void> _verificarUsuarioNube() async {
    final run = _runController.text.trim();
    
    setState(() {
      _runValidationError = null;
      _carrerasDetectadasIds = [];
    });
    
    if (run.isEmpty) return;
    
    // 1. Validación en tiempo real para RUN INVÁLIDO
    if (run.length >= 7 && !_esRunValido(run)) {
        setState(() => _runValidationError = 'RUN inválido o incompleto');
        return;
    }
    
    // 2. Si el RUN es válido, intentar buscar en la nube
    if (_esRunValido(run)) {
        final datos = await _dbService.obtenerEstudiante(run);
        
        if (datos != null && mounted) {
          final List<String> detectedCarreras = [];
          
          // Extraer TODAS las carreras registradas
          if (datos['carreras'] is Map) {
              final Map carrerasMap = datos['carreras'];
              // CORRECCIÓN LINTER: Usando un for-in loop en lugar de forEach
              for (final key in carrerasMap.keys) {
                  detectedCarreras.add(key.toString());
              }
          }

          setState(() {
            _carrerasDetectadasIds = detectedCarreras;
            
            // Autocompletar nombre
            if (_nombreController.text.isEmpty) {
              _nombreController.text = datos['nombre'] ?? '';
            }
            
            // Seleccionar la última carrera activa si es la primera vez
            if (_carreraSeleccionada == null && datos['carrera_id'] != null) {
              final existe = _carrerasDisponibles.any((c) => c['id'] == datos['carrera_id']);
              if (existe) {
                _carreraSeleccionada = datos['carrera_id'];
              }
            }
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Bienvenido de vuelta! Carreras registradas resaltadas.'),
              backgroundColor: Color(0xFF34C759),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
                              colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
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
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF007AFF)),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              
                              // Mostrar error en tiempo real (RUN inválido)
                              errorText: _runValidationError,
                              
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
                            // Validación en tiempo real mientras se escribe
                            onChanged: (val) => _verificarUsuarioNube(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Requerido';
                              // Usar el validador de RUN al intentar enviar
                              if (!_esRunValido(value.trim())) return 'RUN inválido';
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
                              // LÓGICA DE RESALTADO:
                              // Verifica si la carrera está en la LISTA de detectadas
                              final bool esDetectada = _carrerasDetectadasIds.contains(carrera['id']);
                              
                              return DropdownMenuItem<String>(
                                value: carrera['id'],
                                child: Text(
                                  carrera['nombre'],
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    // Verde si está en la lista detectada, Blanco si no
                                    color: esDetectada ? const Color(0xFF34C759) : Colors.white,
                                    fontWeight: esDetectada ? FontWeight.bold : FontWeight.normal,
                                  ),
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