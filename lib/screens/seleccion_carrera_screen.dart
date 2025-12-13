import 'package:flutter/material.dart';
import '../services/github_api_service.dart';
import '../services/auth_service.dart';
import '../services/realtime_db_service.dart';
import '../utils/rut_validator.dart';

class SeleccionCarreraScreen extends StatefulWidget {
  const SeleccionCarreraScreen({super.key});

  @override
  State<SeleccionCarreraScreen> createState() => _SeleccionCarreraScreenState();
}

class _SeleccionCarreraScreenState extends State<SeleccionCarreraScreen> {
  // Servicios
  final GitHubApiService _apiService = GitHubApiService();
  final RealtimeDBService _dbService = RealtimeDBService();
  
  // Controladores
  final TextEditingController _runController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  
  // Estado
  List<Map<String, dynamic>> _carreras = [];
  String? _carreraSeleccionada;
  bool _cargando = true;
  String? _carreraPreviaId; // Para resaltar la carrera si el usuario ya existe

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  /// Carga la lista de carreras desde el JSON en GitHub
  Future<void> _cargarCarreras() async {
    setState(() => _cargando = true);
    try {
      final carreras = await _apiService.fetchCarreras();
      if (mounted) {
        setState(() {
          _carreras = carreras;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar carreras: $e')),
        );
      }
    }
  }

  /// Detecta cambios en el RUT para buscar en Firebase Realtime Database
  Future<void> _onRutChanged(String val) async {
    if (val.length < 8) return; // Optimización básica para no consultar con textos muy cortos
    
    if (RutValidator.esValido(val)) {
      // Consultamos a Firebase
      final estudiante = await _dbService.obtenerEstudiante(val);
      
      if (estudiante != null && mounted) {
        setState(() {
          _nombreController.text = estudiante['nombre'] ?? '';
          _carreraPreviaId = estudiante['carrera_id'];
          
          // Si la carrera del estudiante está en la lista actual, la seleccionamos automáticamente
          if (_carreras.any((c) => c['id'] == _carreraPreviaId)) {
            _carreraSeleccionada = _carreraPreviaId;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido de nuevo! Datos recuperados de la nube.'),
            backgroundColor: Color(0xFF34C759), // Verde iOS
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Registra al usuario localmente y en Firebase
  Future<void> _registrarUsuario() async {
    final rut = _runController.text;
    
    // 1. Validar RUT
    if (!RutValidator.esValido(rut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El RUN ingresado no es válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validar campos vacíos
    if (_nombreController.text.isEmpty || _carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 3. Guardar sesión local (para persistencia offline en el dispositivo)
    final authService = await AuthService.init();
    final exitoLocal = await authService.registrarUsuario(
      run: rut,
      nombre: _nombreController.text,
      carreraId: _carreraSeleccionada!,
    );

    // 4. Guardar/Actualizar en Firebase Realtime Database
    // Esto asegura que si el usuario es nuevo, se cree en la nube.
    await _dbService.guardarEstudiante(
      run: rut,
      nombre: _nombreController.text,
      carreraId: _carreraSeleccionada!,
    );

    if (exitoLocal && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo Header
                    Center(
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B0088), Color(0xFFFF4444)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF8B0088).withValues(alpha:0.5), blurRadius: 20)
                          ],
                        ),
                        child: const Icon(Icons.school, size: 50, color: Colors.white),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text(
                      'Registro de Estudiante',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tu RUN para sincronizar tus datos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    // Input RUN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("RUN", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: TextField(
                            controller: _runController,
                            onChanged: _onRutChanged,
                            inputFormatters: [RutInputFormatter()], // Formatea automáticamente
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: '12.345.678-K',
                              hintStyle: TextStyle(color: Colors.white30),
                              prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF007AFF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Input Nombre
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre Completo',
                      hint: 'Ej: Juan Pérez',
                      icon: Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dropdown Carreras
                    const Text("Carrera", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _carreraSeleccionada,
                          hint: const Text('Selecciona tu carrera', style: TextStyle(color: Colors.grey)),
                          dropdownColor: const Color(0xFF2C2C2E),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF007AFF)),
                          items: _carreras.map((carrera) {
                            // Resaltamos en verde si es la carrera recuperada de la BD
                            final esPrevia = carrera['id'] == _carreraPreviaId;
                            return DropdownMenuItem<String>(
                              value: carrera['id'],
                              child: Text(
                                carrera['nombre'],
                                style: TextStyle(
                                  color: esPrevia ? const Color(0xFF34C759) : Colors.white,
                                  fontWeight: esPrevia ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _carreraSeleccionada = value),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Comenzar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: Icon(icon, color: const Color(0xFF007AFF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}