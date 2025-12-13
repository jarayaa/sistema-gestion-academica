import 'package:flutter/material.dart';
import '../services/github_api_service.dart';
import '../services/auth_service.dart';

class SeleccionCarreraScreen extends StatefulWidget {
  const SeleccionCarreraScreen({super.key});

  @override
  State<SeleccionCarreraScreen> createState() => _SeleccionCarreraScreenState();
}

class _SeleccionCarreraScreenState extends State<SeleccionCarreraScreen> {
  final GitHubApiService _apiService = GitHubApiService();
  final TextEditingController _runController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  
  List<Map<String, dynamic>> _carreras = [];
  String? _carreraSeleccionada;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final carreras = await _apiService.fetchCarreras();
      setState(() {
        _carreras = carreras;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar carreras: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _registrarUsuario() async {
    if (_runController.text.isEmpty || 
        _nombreController.text.isEmpty || 
        _carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authService = await AuthService.init();
      final exito = await authService.registrarUsuario(
        run: _runController.text,
        nombre: _nombreController.text,
        carreraId: _carreraSeleccionada!,
      );

      // Verificamos mounted antes de usar el context
      if (!mounted) return;

      if (exito) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        throw Exception('No se pudo registrar el usuario');
      }
    } catch (e) {
      // ✅ CORRECCIÓN AQUÍ: Verificar mounted antes de mostrar SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              )
            : _error != null
                ? _buildError()
                : _buildForm(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarCarreras,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          
          // Logo o título
          const Icon(
            Icons.school,
            size: 80,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Registro de Usuario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tus datos para comenzar',
            style: TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Campo RUN
          TextField(
            controller: _runController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'RUN (Ej: 12.345.678-9)',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.badge, color: Color(0xFF3B82F6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
            keyboardType: TextInputType.text,
          ),
          
          const SizedBox(height: 20),
          
          // Campo Nombre
          TextField(
            controller: _nombreController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre Completo',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF3B82F6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Selector de Carrera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _carreraSeleccionada,
                hint: const Text(
                  'Selecciona tu carrera',
                  style: TextStyle(color: Colors.white60),
                ),
                dropdownColor: const Color(0xFF1E293B),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                items: _carreras.map((carrera) {
                  return DropdownMenuItem<String>(
                    value: carrera['id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          carrera['nombre'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${carrera['modalidad']} - ${carrera['duracion_trimestres']} trimestres',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _carreraSeleccionada = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Botón de registro
          ElevatedButton(
            onPressed: _registrarUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Comenzar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info del dispositivo
          FutureBuilder<AuthService>(
            future: AuthService.init(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final deviceId = snapshot.data!.getDeviceId();
                return Text(
                  'Device ID: ${deviceId?.substring(0, 20)}...',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _runController.dispose();
    _nombreController.dispose();
    super.dispose();
  }
}