import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de servicios
import 'services/auth_service.dart';
import 'services/github_api_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GestionAcademicaApp());
}

class GestionAcademicaApp extends StatelessWidget {
  const GestionAcademicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión Académica',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1C1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF1C1C1E),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/seleccion-carrera': (context) => const SeleccionCarreraScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// ======================== MODELOS ========================

class Asignatura {
  final String codigo;
  final String nombre;
  final int trimestre;
  final int creditos;

  const Asignatura({
    required this.codigo,
    required this.nombre,
    required this.trimestre,
    required this.creditos,
  });
}

class NotaAsignatura {
  final String codigoAsignatura;
  final List<NotaItem> notas;
  double? promedioFinal;

  NotaAsignatura({
    required this.codigoAsignatura,
    required this.notas,
    this.promedioFinal,
  });

  Map<String, dynamic> toJson() => {
    'codigoAsignatura': codigoAsignatura,
    'notas': notas.map((n) => n.toJson()).toList(),
    'promedioFinal': promedioFinal,
  };

  factory NotaAsignatura.fromJson(Map<String, dynamic> json) => NotaAsignatura(
    codigoAsignatura: json['codigoAsignatura'],
    notas: (json['notas'] as List).map((n) => NotaItem.fromJson(n)).toList(),
    promedioFinal: (json['promedioFinal'] as num?)?.toDouble(),
  );
}

class NotaItem {
  final double nota;
  final double porcentaje;

  NotaItem({required this.nota, required this.porcentaje});

  Map<String, dynamic> toJson() => {'nota': nota, 'porcentaje': porcentaje};
  
  factory NotaItem.fromJson(Map<String, dynamic> json) => NotaItem(
    nota: (json['nota'] as num?)?.toDouble() ?? 0.0,
    porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
  );
}

// ======================== DATA MANAGER ========================

class DataManager {
  static const String _keyNotas = 'notas_asignaturas';
  
  static Future<void> guardarNotas(List<NotaAsignatura> notas) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notas.map((n) => n.toJson()).toList();
    await prefs.setString(_keyNotas, jsonEncode(jsonList));
  }

  static Future<List<NotaAsignatura>> cargarNotas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyNotas);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((j) => NotaAsignatura.fromJson(j)).toList();
  }

  static Future<NotaAsignatura?> obtenerNotasAsignatura(String codigo) async {
    final todasNotas = await cargarNotas();
    try {
      return todasNotas.firstWhere((n) => n.codigoAsignatura == codigo);
    } catch (e) {
      return null;
    }
  }

  static Future<void> guardarNotasAsignatura(NotaAsignatura notaAsignatura) async {
    final todasNotas = await cargarNotas();
    final index = todasNotas.indexWhere((n) => n.codigoAsignatura == notaAsignatura.codigoAsignatura);
    
    if (index >= 0) {
      todasNotas[index] = notaAsignatura;
    } else {
      todasNotas.add(notaAsignatura);
    }
    
    await guardarNotas(todasNotas);
  }
}

// ======================== FORMATTER ========================

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 10) return oldValue;
    String newText = newValue.text.replaceAll('.', ',');
    int commaCount = ','.allMatches(newText).length;
    if (commaCount > 1) return oldValue;
    if (newText.isNotEmpty && newText != ',') {
      final testValue = newText.replaceAll(',', '.');
      if (double.tryParse(testValue) == null) return oldValue;
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// ======================== SPLASH SCREEN (DISEÑO ORIGINAL RESTAURADO) ========================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  double _progress = 0.0;
  String _estado = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Simular progreso de carga
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _progress = i / 100;
            if (i < 30) {
              _estado = 'Verificando actualizaciones...';
            } else if (i < 70) {
              _estado = 'Cargando datos...';
            } else {
              _estado = 'Preparando interfaz...';
            }
          });
        }
      }

      // Verificar actualizaciones
      await _verificarActualizaciones();
      
      // Verificar autenticación
      final authService = await AuthService.init();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        if (authService.isUsuarioRegistrado()) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estado = 'Error: $e');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
        }
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
      debugPrint('Error al verificar actualizaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B0088), Color(0xFFFF4444)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo animado (DISEÑO ORIGINAL)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Título (DISEÑO ORIGINAL)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: const Column(
                    children: [
                      Text(
                        'Sistema de Gestión',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Académica',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Stage 3 | APTC106',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Barra de progreso (DISEÑO ORIGINAL)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _estado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Versión
                const Text(
                  'v3.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ======================== SELECCIÓN CARRERA (CONSERVADO) ========================

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

      if (!mounted) return;

      if (exito) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        throw Exception('No se pudo registrar el usuario');
      }
    } catch (e) {
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
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
          Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarCarreras,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
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
          const Icon(Icons.school, size: 80, color: Color(0xFF3B82F6)),
          const SizedBox(height: 16),
          const Text('Registro de Usuario', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Ingresa tus datos para comenzar', style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
          const SizedBox(height: 48),
          
          TextField(
            controller: _runController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'RUN (Ej: 12.345.678-9)',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.badge, color: Color(0xFF3B82F6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
            keyboardType: TextInputType.text,
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _nombreController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre Completo',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF3B82F6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          
          const SizedBox(height: 20),
          
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
                hint: const Text('Selecciona tu carrera', style: TextStyle(color: Colors.white60)),
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
                        Text(carrera['nombre'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                        Text('${carrera['modalidad']} - ${carrera['duracion_trimestres']} trimestres', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
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
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Comenzar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 24),
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

// ======================== HOME PAGE (DISEÑO ORIGINAL RESTAURADO) ========================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _notaAprobacion = 3.95;
  
  List<NotaAsignatura> _notas = [];
  Map<String, dynamic>? _carreraData;
  List<Asignatura> _todasAsignaturas = [];
  bool _cargando = true;
  String _nombreUsuario = 'Estudiante';

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    setState(() => _cargando = true);
    
    try {
      final authService = await AuthService.init();
      final carreraId = authService.getCarreraId();
      final nombre = authService.getNombre();
      
      if (carreraId != null) {
        final apiService = GitHubApiService();
        final carrera = await apiService.fetchCarreraPorId(carreraId);
        
        if (carrera != null) {
          final List<Asignatura> listaAsignaturas = [];
          final trimestres = List<Map<String, dynamic>>.from(carrera['trimestres'] ?? []);
          
          for (var t in trimestres) {
            final numTrimestre = t['numero'] as int;
            final asigs = List<Map<String, dynamic>>.from(t['asignaturas'] ?? []);
            
            for (var a in asigs) {
              listaAsignaturas.add(Asignatura(
                codigo: a['codigo'],
                nombre: a['nombre'],
                trimestre: numTrimestre,
                creditos: a['creditos_unab'] ?? 0,
              ));
            }
          }

          if (mounted) {
            setState(() {
              _carreraData = carrera;
              _todasAsignaturas = listaAsignaturas;
              _nombreUsuario = nombre ?? 'Estudiante';
            });
          }
        }
      }
      
      final notas = await DataManager.cargarNotas();
      
      if (mounted) {
        setState(() {
          _notas = notas;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar home: $e');
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _navegarATrimestre(BuildContext context, int trimestre) async {
    final asignaturasTrimestre = _todasAsignaturas
        .where((a) => a.trimestre == trimestre)
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AsignaturasPage(
          trimestre: trimestre, 
          asignaturas: asignaturasTrimestre
        ),
      ),
    );
    
    _inicializarDatos();
  }
  
  Future<void> _cerrarSesion() async {
    final authService = await AuthService.init();
    await authService.cerrarSesion();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_carreraData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar la información de la carrera'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cerrarSesion, 
                child: const Text('Volver a seleccionar')
              )
            ],
          ),
        ),
      );
    }

    final totalTrimestres = _carreraData!['duracion_trimestres'] as int? ?? 10;
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Gestión Académica',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cambiar Carrera',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER CON GRADIENTE (DISEÑO ORIGINAL)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C3A5A), Color(0xFF2C4A6A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _carreraData!['nombre'] ?? 'Carrera',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Universidad Andrés Bello',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bienvenido, $_nombreUsuario',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // TÍTULO SECCIÓN
              const Text(
                'Selecciona un Trimestre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // GRILLA DE TRIMESTRES (DISEÑO ORIGINAL)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: totalTrimestres,
                itemBuilder: (context, index) {
                  final trimestre = index + 1;
                  final numAsignaturas = _todasAsignaturas
                      .where((a) => a.trimestre == trimestre)
                      .length;
                  
                  return _buildTrimestreCard(context, trimestre, numAsignaturas);
                },
              ),
              
              const SizedBox(height: 24),
              
              // ESTADÍSTICAS (DISEÑO ORIGINAL)
              _buildEstadisticasCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrimestreCard(BuildContext context, int trimestre, int numAsignaturas) {
    // Diseño ORIGINAL de las tarjetas de trimestre
    return InkWell(
      onTap: () => _navegarATrimestre(context, trimestre),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1C1E),
              const Color(0xFF2C2C2E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3A3A3C),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF007AFF),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$trimestre',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Trimestre $trimestre',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$numAsignaturas asignaturas',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(BuildContext context) {
    final totalAsignaturas = _todasAsignaturas.length;
    final aprobadas = _notas.where((n) => 
      n.promedioFinal != null && n.promedioFinal! >= _notaAprobacion
    ).length;
    
    final pendientes = totalAsignaturas - aprobadas;
    final porcentaje = totalAsignaturas > 0 
        ? (aprobadas / totalAsignaturas * 100).toStringAsFixed(1) 
        : '0.0';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assessment, color: Color(0xFF007AFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tu Avance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.check_circle_outline,
                '$aprobadas',
                'Completadas',
                const Color(0xFF34C759),
              ),
              Container(width: 1, height: 40, color: const Color(0xFF3A3A3C)),
              _buildStatItem(
                Icons.pending_outlined,
                '$pendientes',
                'Pendientes',
                const Color(0xFFFF9500),
              ),
              Container(width: 1, height: 40, color: const Color(0xFF3A3A3C)),
              _buildStatItem(
                Icons.trending_up,
                '$porcentaje%',
                'Progreso',
                const Color(0xFF007AFF),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          LinearProgressIndicator(
            value: totalAsignaturas > 0 ? aprobadas / totalAsignaturas : 0,
            backgroundColor: const Color(0xFF2C2C2E),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

// ======================== ASIGNATURAS PAGE (DISEÑO ORIGINAL RESTAURADO) ========================

class AsignaturasPage extends StatefulWidget {
  final int trimestre;
  final List<Asignatura> asignaturas;

  const AsignaturasPage({
    super.key, 
    required this.trimestre,
    required this.asignaturas,
  });

  @override
  State<AsignaturasPage> createState() => _AsignaturasPageState();
}

class _AsignaturasPageState extends State<AsignaturasPage> {
  Map<String, double?> _promedios = {};

  @override
  void initState() {
    super.initState();
    _cargarPromedios();
  }

  Future<void> _cargarPromedios() async {
    final notas = await DataManager.cargarNotas();
    if (mounted) {
      setState(() {
        _promedios = {
          for (var n in notas) n.codigoAsignatura: n.promedioFinal
        };
      });
    }
  }

  Future<void> _abrirCalculadora(Asignatura asignatura) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculadoraPage(asignatura: asignatura),
      ),
    );
    await _cargarPromedios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text('Trimestre ${widget.trimestre}'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: widget.asignaturas.isEmpty 
        ? const Center(child: Text('No hay asignaturas en este trimestre', style: TextStyle(color: Colors.white60)))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: widget.asignaturas.length,
            itemBuilder: (context, index) {
              final asignatura = widget.asignaturas[index];
              final promedio = _promedios[asignatura.codigo];
              return _buildAsignaturaCard(context, asignatura, promedio);
            },
          ),
    );
  }

  Widget _buildAsignaturaCard(BuildContext context, Asignatura asignatura, double? promedio) {
    final tienePromedio = promedio != null;
    final aprobado = tienePromedio && promedio >= 3.95;
    
    // DISEÑO ORIGINAL de las tarjetas de asignatura
    return Card(
      elevation: 0,
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3A3A3C), width: 1),
      ),
      child: InkWell(
        onTap: () => _abrirCalculadora(asignatura),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono con código
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: tienePromedio
                      ? (aprobado ? const Color(0xFF34C759).withValues(alpha: 0.2) : const Color(0xFFFF3B30).withValues(alpha: 0.2))
                      : const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tienePromedio
                        ? (aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                        : const Color(0xFF007AFF),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    asignatura.codigo.length > 4 
                        ? asignatura.codigo.substring(0, 4) 
                        : asignatura.codigo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: tienePromedio
                          ? (aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                          : const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asignatura.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${asignatura.creditos} créditos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        if (tienePromedio) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: aprobado 
                                  ? const Color(0xFF34C759).withValues(alpha: 0.2)
                                  : const Color(0xFFFF3B30).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              aprobado ? 'Aprobado' : 'Reprobado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Badge de nota
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: tienePromedio
                      ? (aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                      : const Color(0xFF8E8E93),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tienePromedio ? promedio.toStringAsFixed(1) : '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== CALCULADORA (DISEÑO ORIGINAL RESTAURADO) ========================

class CalculadoraPage extends StatefulWidget {
  final Asignatura asignatura;

  const CalculadoraPage({super.key, required this.asignatura});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  final _formKey = GlobalKey<FormState>();
  int _cantidadNotas = 3;
  final List<TextEditingController> _notasControllers = [];
  final List<TextEditingController> _porcentajesControllers = [];
  final List<FocusNode> _notasFocus = [];
  final List<FocusNode> _porcentajesFocus = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await DataManager.obtenerNotasAsignatura(widget.asignatura.codigo);
    _actualizarControladores(datos?.notas.length ?? 3);
    
    if (datos != null) {
      for (int i = 0; i < datos.notas.length; i++) {
        _notasControllers[i].text = datos.notas[i].nota.toString().replaceAll('.', ',');
        _porcentajesControllers[i].text = datos.notas[i].porcentaje.toString();
      }
    }
    setState(() {});
  }

  void _actualizarControladores(int cantidad) {
    // Limpiar controladores anteriores
    for (var controller in _notasControllers) {
      controller.dispose();
    }
    for (var controller in _porcentajesControllers) {
      controller.dispose();
    }
    for (var focus in _notasFocus) {
      focus.dispose();
    }
    for (var focus in _porcentajesFocus) {
      focus.dispose();
    }
    
    _notasControllers.clear();
    _porcentajesControllers.clear();
    _notasFocus.clear();
    _porcentajesFocus.clear();
    
    for (int i = 0; i < cantidad; i++) {
      _notasControllers.add(TextEditingController());
      _porcentajesControllers.add(TextEditingController());
      _notasFocus.add(FocusNode());
      _porcentajesFocus.add(FocusNode());
    }
    
    setState(() => _cantidadNotas = cantidad);
  }

  double? _calcularPromedio() {
    double promedio = 0;
    double sumaPorc = 0;
    
    for (int i = 0; i < _cantidadNotas; i++) {
      if (_notasControllers[i].text.isNotEmpty && _porcentajesControllers[i].text.isNotEmpty) {
        final nota = double.tryParse(_notasControllers[i].text.replaceAll(',', '.')) ?? 0;
        final porc = double.tryParse(_porcentajesControllers[i].text.replaceAll(',', '.')) ?? 0;
        promedio += nota * (porc / 100);
        sumaPorc += porc;
      }
    }
    
    if (sumaPorc != 100) return null;
    return promedio;
  }

  bool _validarSumaPorcentajes() {
    double suma = 0;
    for (var controller in _porcentajesControllers) {
      if (controller.text.isNotEmpty) {
        suma += double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
      }
    }
    return (suma - 100).abs() < 0.01;
  }

  Future<void> _mostrarResultado() async {
    final promedio = _calcularPromedio();
    
    if (promedio == null) {
      if (!_validarSumaPorcentajes()) {
        _mostrarDialogoError('Error de Validación', 'La suma de ponderaciones debe ser exactamente 100%');
        return;
      }
      _mostrarDialogoError('Campos Incompletos', 'Por favor completa todas las notas y ponderaciones');
      return;
    }

    final aprobado = promedio >= 3.95;
    final necesitaExamen = promedio >= 3.0 && promedio < 4.0;
    
    await showDialog(
      context: context,
      builder: (context) => _buildResultDialog(promedio, aprobado, necesitaExamen),
    );
  }

  Widget _buildResultDialog(double promedio, bool aprobado, bool necesitaExamen) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              aprobado ? Icons.check_circle : Icons.cancel,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.asignatura.codigo,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            promedio.toStringAsFixed(2).replaceAll('.', ','),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Promedio Ponderado',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: aprobado 
                  ? const Color(0xFF34C759).withValues(alpha: 0.2)
                  : const Color(0xFFFF3B30).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  aprobado ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied,
                  color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                Text(
                  aprobado ? '¡Aprobado!' : 
                  necesitaExamen ? 'Debe Rendir Examen' : '¡Reprobado!',
                  style: TextStyle(
                    color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (necesitaExamen) ...[
            const SizedBox(height: 16),
            _buildNotaExamen(promedio),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _guardar(promedio);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotaExamen(double promedio) {
    final notaExamen = ((4.0 * 0.7 - promedio * 0.3) / 0.7).clamp(1.0, 7.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFFF9500), size: 24),
          const SizedBox(height: 8),
          const Text(
            'Nota mínima de examen para aprobar:',
            style: TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            notaExamen.toStringAsFixed(1).replaceAll('.', ','),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9500),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF3B30)),
            const SizedBox(width: 12),
            Text(titulo, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar(double promedio) async {
    List<NotaItem> notas = [];
    for (int i = 0; i < _cantidadNotas; i++) {
      if (_notasControllers[i].text.isNotEmpty && _porcentajesControllers[i].text.isNotEmpty) {
        final n = double.parse(_notasControllers[i].text.replaceAll(',', '.'));
        final p = double.parse(_porcentajesControllers[i].text.replaceAll(',', '.'));
        notas.add(NotaItem(nota: n, porcentaje: p));
      }
    }
    
    await DataManager.guardarNotasAsignatura(NotaAsignatura(
      codigoAsignatura: widget.asignatura.codigo,
      notas: notas,
      promedioFinal: promedio,
    ));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Notas guardadas correctamente'),
          backgroundColor: Color(0xFF34C759),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _limpiarCampos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas limpiar todos los campos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      for (var controller in _notasControllers) {
        controller.clear();
      }
      for (var controller in _porcentajesControllers) {
        controller.clear();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final sumaPorcentajes = _porcentajesControllers.fold<double>(
      0,
      (sum, controller) => sum + (double.tryParse(controller.text.replaceAll(',', '.')) ?? 0),
    );
    
    final porcentajesValidos = (sumaPorcentajes - 100).abs() < 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(widget.asignatura.codigo),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _limpiarCampos,
            tooltip: 'Limpiar campos',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header con info de la asignatura
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.asignatura.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.asignatura.creditos} créditos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF007AFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Selector de cantidad de notas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _cantidadNotas,
                          dropdownColor: const Color(0xFF2C2C2E),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF007AFF)),
                          items: List.generate(9, (i) => i + 2).map((n) {
                            return DropdownMenuItem(
                              value: n,
                              child: Text(
                                'Cantidad de Notas: $n',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _actualizarControladores(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de notas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _cantidadNotas,
                itemBuilder: (context, i) {
                  return _buildNotaRow(i);
                },
              ),
            ),

            // Indicador de suma de porcentajes
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: porcentajesValidos 
                    ? const Color(0xFF34C759).withValues(alpha: 0.2)
                    : const Color(0xFFFF9500).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: porcentajesValidos 
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    porcentajesValidos ? Icons.check_circle : Icons.warning_amber,
                    color: porcentajesValidos 
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La suma de ponderaciones debe ser exactamente 100%',
                      style: TextStyle(
                        fontSize: 11,
                        color: porcentajesValidos 
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF9500),
                      ),
                    ),
                  ),
                  Text(
                    '${sumaPorcentajes.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: porcentajesValidos 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                    ),
                  ),
                ],
              ),
            ),

            // Botón calcular
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _mostrarResultado,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Calcular Promedio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotaRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nota ${index + 1}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _notasControllers[index],
                  focusNode: _notasFocus[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalTextInputFormatter()],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Nota',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                    hintText: '1,0 - 7,0',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF007AFF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _porcentajesControllers[index],
                  focusNode: _porcentajesFocus[index],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: '%',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                    hintText: '0-100',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.percent, color: Color(0xFF007AFF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _notasControllers) {
      controller.dispose();
    }
    for (var controller in _porcentajesControllers) {
      controller.dispose();
    }
    for (var focus in _notasFocus) {
      focus.dispose();
    }
    for (var focus in _porcentajesFocus) {
      focus.dispose();
    }
    super.dispose();
  }
}