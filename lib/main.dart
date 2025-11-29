import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestionAcademicaApp());
}

class GestionAcademicaApp extends StatelessWidget {
  const GestionAcademicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica UNAB',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1C1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF1C1C1E),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF2C2C2E),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ======================== SPLASH SCREEN ========================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  String _version = '...';

  @override
  void initState() {
    super.initState();
    
    // Obtener versión de la app desde pubspec.yaml
    _loadVersion();
    
    // Animaciones
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );
    
    _controller.forward();
    
    // Simular carga
    _simulateLoading();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${packageInfo.version}';
        });
      }
    } catch (e) {
      // Si falla, usar versión por defecto
      if (mounted) {
        setState(() {
          _version = 'v1.0.0';
        });
      }
    }
  }

  Future<void> _simulateLoading() async {
    // Simular progreso de carga
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _progress = i / 100;
        });
      }
    }
    
    // Esperar un poco más para que se aprecie la pantalla
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navegar a HomePage
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo con gradiente
                  _buildLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // Nombre de la aplicación
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B0088), // Violeta
                          Color(0xFF6B006B), // Violeta oscuro
                          Color(0xFFFF4500), // Rojo
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Sistema de Gestión\nAcadémica',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Grupo de trabajo APTC106
                  Text(
                    'Grupo 3 - APTC106',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Versión
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B0088), // Violeta
                          Color(0xFFCC3700), // Rojo oscuro
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B0088).withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _version,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Barra de progreso
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progress,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF8B0088), // Violeta
                                          Color(0xFFB8008B), // Violeta medio
                                          Color(0xFFFF4500), // Rojo
                                          Color(0xFFCC3700), // Rojo oscuro
                                        ],
                                        stops: [0.0, 0.33, 0.66, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 6.28,
          colors: [
            Color(0xFF8B0088), // Violeta
            Color(0xFF6B006B), // Violeta más oscuro
            Color(0xFFFF4500), // Rojo
            Color(0xFFCC3700), // Rojo oscuro
            Color(0xFF8B0088), // Violeta (cierra el círculo)
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0088).withValues(alpha: 0.6),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFFFF4500).withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo interno oscuro para contraste
          Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0a0a0a),
            ),
          ),
          
          // Icono central
          Icon(
            Icons.school_rounded,
            size: 60,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}


// ======================== MODELOS DE DATOS ========================

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

  static const List<Asignatura> mallaCurricular = [
    // TRIMESTRE 1
    Asignatura(codigo: 'ATDF101', nombre: 'TÓPICOS DE INGENIERÍA', trimestre: 1, creditos: 8),
    Asignatura(codigo: 'CFSA3180', nombre: 'ELEMENTOS DE FÍSICA Y MEDICIÓN', trimestre: 1, creditos: 14),
    Asignatura(codigo: 'FMMA015', nombre: 'FUNDAMENTOS DE MATEMÁTICAS', trimestre: 1, creditos: 14),

    // TRIMESTRE 2
    Asignatura(codigo: 'ATDF102', nombre: 'INTRODUCCIÓN A LA PROGRAMACIÓN', trimestre: 2, creditos: 10),
    Asignatura(codigo: 'CFSA3220', nombre: 'MECÁNICA', trimestre: 2, creditos: 10),
    Asignatura(codigo: 'FMMA115', nombre: 'CÁLCULO DIFERENCIAL E INTEGRAL', trimestre: 2, creditos: 14),
    Asignatura(codigo: 'QUIA090', nombre: 'QUÍMICA Y AMBIENTE', trimestre: 2, creditos: 10),

    // TRIMESTRE 3
    Asignatura(codigo: 'ATDF103', nombre: 'BASE DE DATOS', trimestre: 3, creditos: 8),
    Asignatura(codigo: 'CFSA3440', nombre: 'ELECTRICIDAD Y MAGNETISMO', trimestre: 3, creditos: 10),
    Asignatura(codigo: 'FMMA215', nombre: 'SISTEMAS LINEALES Y ECUACIONES DIFERENCIALES', trimestre: 3, creditos: 14),
    Asignatura(codigo: 'INGA119', nombre: 'INGLÉS I', trimestre: 3, creditos: 8),

    // TRIMESTRE 4
    Asignatura(codigo: 'APTC101', nombre: 'PROGRAMACIÓN AVANZADA', trimestre: 4, creditos: 8),
    Asignatura(codigo: 'APTC104', nombre: 'DISEÑO DE ALGORITMOS', trimestre: 4, creditos: 10),
    Asignatura(codigo: 'FMSA315', nombre: 'TALLER DE MÉTODOS CUANTITATIVOS', trimestre: 4, creditos: 14),
    Asignatura(codigo: 'INGA129', nombre: 'INGLÉS II', trimestre: 4, creditos: 8),

    // TRIMESTRE 5
    Asignatura(codigo: 'ACIF101', nombre: 'FUNDAMENTOS DE COMPUTACIÓN DE ALTO DESEMPEÑO', trimestre: 5, creditos: 10),
    Asignatura(codigo: 'APTC103', nombre: 'INFRAESTRUCTURA TI', trimestre: 5, creditos: 10),
    Asignatura(codigo: 'ATDF105', nombre: 'MINERÍA DE DATOS', trimestre: 5, creditos: 10),
    Asignatura(codigo: 'INGA239', nombre: 'INGLÉS III', trimestre: 5, creditos: 8),

    // TRIMESTRE 6
    Asignatura(codigo: 'ACIF102', nombre: 'FUNDAMENTOS DE INTELIGENCIA ARTIFICIAL', trimestre: 6, creditos: 11),
    Asignatura(codigo: 'APTC105', nombre: 'INGENIERÍA DE SOFTWARE', trimestre: 6, creditos: 12),
    Asignatura(codigo: 'ATDF106', nombre: 'GESTIÓN DE LA TRANSFORMACIÓN DIGITAL', trimestre: 6, creditos: 8),
    Asignatura(codigo: 'INGA249', nombre: 'INGLÉS IV', trimestre: 6, creditos: 8),

    // TRIMESTRE 7
    Asignatura(codigo: 'AACD101', nombre: 'TALLER DE INNOVACIÓN Y EMPRENDIMIENTO I', trimestre: 7, creditos: 8),
    Asignatura(codigo: 'ACIF103', nombre: 'OPTIMIZACIÓN', trimestre: 7, creditos: 10),
    Asignatura(codigo: 'ACIF104', nombre: 'APRENDIZAJE DE MÁQUINA', trimestre: 7, creditos: 12),
    Asignatura(codigo: 'APTC106', nombre: 'TALLER DE DESARROLLO WEB Y MÓVIL', trimestre: 7, creditos: 12),

    // TRIMESTRE 8
    Asignatura(codigo: 'AACD102', nombre: 'TALLER DE INNOVACIÓN Y EMPRENDIMIENTO II', trimestre: 8, creditos: 8),
    Asignatura(codigo: 'ACIF200', nombre: 'SEMINARIO DE LICENCIATURA EN INGENIERÍA', trimestre: 8, creditos: 12),
    Asignatura(codigo: 'APTC107', nombre: 'CIBERSEGURIDAD', trimestre: 8, creditos: 10),
    Asignatura(codigo: 'CEGARS14', nombre: 'RESPONSABILIDAD SOCIAL', trimestre: 8, creditos: 6),

    // TRIMESTRE 9
    Asignatura(codigo: 'ACIF105', nombre: 'TÓPICOS DE ESPECIALIDAD I', trimestre: 9, creditos: 10),
    Asignatura(codigo: 'ACIF107', nombre: 'GESTIÓN FINANCIERA DE PROYECTOS DE I+D+i', trimestre: 9, creditos: 11),
    Asignatura(codigo: 'ACIF108', nombre: 'TÓPICOS DE ESPECIALIDAD II', trimestre: 9, creditos: 10),
    Asignatura(codigo: 'ACIF300', nombre: 'ANTEPROYECTO', trimestre: 9, creditos: 9),

    // TRIMESTRE 10
    Asignatura(codigo: 'ACIF109', nombre: 'EMPRESAS DE BASE TECNOLÓGICA', trimestre: 10, creditos: 11),
    Asignatura(codigo: 'ACIF110', nombre: 'TÓPICOS DE ESPECIALIDAD III', trimestre: 10, creditos: 11),
    Asignatura(codigo: 'ACIF111', nombre: 'CIENCIA DE DATOS AVANZADA', trimestre: 10, creditos: 11),
    Asignatura(codigo: 'ACIF112', nombre: 'PROYECTO DE TÍTULO', trimestre: 10, creditos: 10),
  ];
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
    promedioFinal: json['promedioFinal'],
  );
}

class NotaItem {
  final double nota;
  final double porcentaje;

  NotaItem({required this.nota, required this.porcentaje});

  Map<String, dynamic> toJson() => {
    'nota': nota,
    'porcentaje': porcentaje,
  };

  factory NotaItem.fromJson(Map<String, dynamic> json) => NotaItem(
    nota: json['nota'],
    porcentaje: json['porcentaje'],
  );
}

// ======================== GESTOR DE DATOS ========================

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

// ======================== PANTALLA PRINCIPAL ========================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Constante para nota de aprobación (Chile)
  static const double _notaAprobacion = 5.5;
  
  // Estado local de las notas
  List<NotaAsignatura> _notas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  /// Carga las estadísticas desde SharedPreferences
  Future<void> _cargarEstadisticas() async {
    setState(() {
      _cargando = true;
    });
    
    try {
      final notas = await DataManager.cargarNotas();
      if (mounted) {
        setState(() {
          _notas = notas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notas = [];
          _cargando = false;
        });
      }
    }
  }

  /// Navega a AsignaturasPage y recarga al volver
  Future<void> _navegarATrimestre(BuildContext context, int trimestre) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AsignaturasPage(trimestre: trimestre),
      ),
    );
    
    // CLAVE: Recargar estadísticas al volver
    _cargarEstadisticas();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestión Académica',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, isDark),
              const SizedBox(height: 12),
              Expanded(
                child: _buildTrimestreGrid(context, isDark),
              ),
              const SizedBox(height: 12),
              _buildEstadisticasCard(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1C3A5A), const Color(0xFF2C4A6A)]
              : [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school_rounded,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingeniería Civil Informática',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            'Universidad Andrés Bello',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '10 Trimestres • 43 Asignaturas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimestreGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un Trimestre',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: List.generate(10, (index) {
              final trimestre = index + 1;
              final asignaturas = Asignatura.mallaCurricular
                  .where((a) => a.trimestre == trimestre)
                  .toList();
              
              return _buildTrimestreCard(context, trimestre, asignaturas.length, isDark);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTrimestreCard(BuildContext context, int trimestre, int numAsignaturas, bool isDark) {
    return InkWell(
      onTap: () => _navegarATrimestre(context, trimestre),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final circleSize = constraints.maxWidth * 0.40;
            final numberSize = circleSize * 0.45;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$trimestre',
                        style: TextStyle(
                          fontSize: numberSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Trimestre $trimestre',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$numAsignaturas asignaturas',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(BuildContext context, bool isDark) {
    // Calcular estadísticas CORRECTAS
    final totalAsignaturas = Asignatura.mallaCurricular.length;
    
    // Solo asignaturas con promedio >= 5.5 se consideran aprobadas
    final aprobadas = _notas.where((n) => 
      n.promedioFinal != null && n.promedioFinal! >= _notaAprobacion
    ).length;
    
    // Asignaturas con promedio < 5.5 requieren examen
    final conExamen = _notas.where((n) => 
      n.promedioFinal != null && n.promedioFinal! < _notaAprobacion
    ).length;
    
    // Asignaturas sin promedio calculado
    final sinCalificar = _notas.where((n) => 
      n.promedioFinal == null
    ).length;
    
    // Pendientes = Total - (Aprobadas + Con Examen + Sin Calificar)
    final pendientes = totalAsignaturas - aprobadas - conExamen - sinCalificar;
    
    // Progreso se calcula solo con aprobadas
    final porcentaje = (aprobadas / totalAsignaturas * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Color(0xFF007AFF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu Avance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _cargando
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Aprobadas',
                      '$aprobadas',
                      Icons.check_circle_rounded,
                      Colors.green,
                      isDark,
                    ),
                    if (conExamen > 0)
                      _buildStatItem(
                        'Con Examen',
                        '$conExamen',
                        Icons.edit_note_rounded,
                        Colors.orange,
                        isDark,
                      ),
                    _buildStatItem(
                      'Pendientes',
                      '$pendientes',
                      Icons.pending_rounded,
                      Colors.grey,
                      isDark,
                    ),
                    _buildStatItem(
                      'Progreso',
                      '$porcentaje%',
                      Icons.trending_up_rounded,
                      const Color(0xFF007AFF),
                      isDark,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}


// ======================== PANTALLA DE ASIGNATURAS ========================

class AsignaturasPage extends StatefulWidget {
  final int trimestre;

  const AsignaturasPage({super.key, required this.trimestre});

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
    setState(() {
      _promedios = {
        for (var n in notas) n.codigoAsignatura: n.promedioFinal
      };
    });
  }

  // Llamar cuando se vuelve de la calculadora
  Future<void> _abrirCalculadora(Asignatura asignatura) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculadoraPage(asignatura: asignatura),
      ),
    );
    // Recargar promedios después de volver
    await _cargarPromedios();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asignaturas = Asignatura.mallaCurricular
        .where((a) => a.trimestre == widget.trimestre)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Trimestre ${widget.trimestre}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: asignaturas.length,
        itemBuilder: (context, index) {
          final asignatura = asignaturas[index];
          final promedio = _promedios[asignatura.codigo];
          
          return _buildAsignaturaCard(context, asignatura, promedio, isDark);
        },
      ),
    );
  }

  Widget _buildAsignaturaCard(BuildContext context, Asignatura asignatura, double? promedio, bool isDark) {
    final tienePromedio = promedio != null;
    final aprobado = tienePromedio && promedio >= 5.5;
    
    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => _abrirCalculadora(asignatura),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tienePromedio
                      ? (aprobado ? Colors.green.shade100 : Colors.red.shade100)
                      : const Color(0xFF007AFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    asignatura.codigo.substring(0, 4),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tienePromedio
                          ? (aprobado ? Colors.green.shade700 : Colors.red.shade700)
                          : const Color(0xFF007AFF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asignatura.codigo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF007AFF) : Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asignatura.nombre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${asignatura.creditos} créditos',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tienePromedio
                      ? (aprobado ? Colors.green.shade600 : Colors.red.shade600)
                      : Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tienePromedio
                      ? promedio.toStringAsFixed(2).replaceAll('.', ',')
                      : 'S/I',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== CALCULADORA DE NOTAS ========================

class CalculadoraPage extends StatefulWidget {
  final Asignatura asignatura;

  const CalculadoraPage({super.key, required this.asignatura});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  final _formKey = GlobalKey<FormState>();
  
  static const int _minNotas = 2;
  static const int _maxNotas = 10;
  static const double _notaMin = 1.0;
  static const double _notaMax = 7.0;
  static const double _porcentajeMin = 0.0;
  static const double _porcentajeMax = 100.0;
  static const double _notaAprobacion = 5.5;

  int _cantidadNotas = 3;
  
  final List<TextEditingController> _notasControllers = <TextEditingController>[];
  final List<TextEditingController> _porcentajesControllers = <TextEditingController>[];
  final List<bool> _notasErrors = <bool>[];
  final List<bool> _porcentajesErrors = <bool>[];
  
  final Map<int, Timer?> _debounceTimers = {};
  
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final notasGuardadas = await DataManager.obtenerNotasAsignatura(widget.asignatura.codigo);
    
    if (notasGuardadas != null && notasGuardadas.notas.isNotEmpty) {
      // Asegurar que la cantidad sea al menos _minNotas (2)
      // Si hay menos notas guardadas, crear controladores extra vacíos
      final cantidadAMostrar = notasGuardadas.notas.length < _minNotas 
          ? _minNotas 
          : notasGuardadas.notas.length;
      
      _actualizarCantidadControladores(cantidadAMostrar);
      
      // Cargar las notas guardadas
      for (int i = 0; i < notasGuardadas.notas.length; i++) {
        if (i < _notasControllers.length) {
          _notasControllers[i].text = notasGuardadas.notas[i].nota.toString().replaceAll('.', ',');
          _porcentajesControllers[i].text = notasGuardadas.notas[i].porcentaje.toString().replaceAll('.', ',');
        }
      }
      
      setState(() {
        _cantidadNotas = cantidadAMostrar;
      });
    } else {
      _actualizarCantidadControladores(3);
      setState(() {
        _cantidadNotas = 3;
      });
    }
    
    setState(() => _cargando = false);
  }

  Future<void> _cambiarCantidadConAdvertencia(int nuevaCantidad) async {
    // Si está reduciendo la cantidad
    if (nuevaCantidad < _cantidadNotas) {
      // Verificar si hay datos en los campos que se ocultarán
      bool hayDatosEnCamposOcultos = false;
      List<int> camposConDatos = [];
      
      for (int i = nuevaCantidad; i < _cantidadNotas; i++) {
        if (_notasControllers[i].text.trim().isNotEmpty || 
            _porcentajesControllers[i].text.trim().isNotEmpty) {
          hayDatosEnCamposOcultos = true;
          camposConDatos.add(i + 1); // +1 para mostrar número humano (1-indexed)
        }
      }
      
      if (hayDatosEnCamposOcultos) {
        final confirmar = await _mostrarAdvertenciaReduccion(camposConDatos);
        if (confirmar != true) {
          // Usuario canceló, no hacer nada
          return;
        }
      }
    }
    
    // Continuar con la actualización
    _actualizarCantidadControladores(nuevaCantidad);
  }

  Future<bool?> _mostrarAdvertenciaReduccion(List<int> camposConDatos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camposTexto = camposConDatos.length == 1
        ? 'el campo ${camposConDatos[0]}'
        : 'los campos ${camposConDatos.join(', ')}';
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Advertencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Al reducir la cantidad de notas, $camposTexto ${camposConDatos.length == 1 ? 'perderá sus' : 'perderán sus'} datos.\n\n¿Deseas continuar?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark 
                              ? const Color(0xFF3A3A3C) 
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _actualizarCantidadControladores(int nuevaCantidad) {
    if (nuevaCantidad < _minNotas || nuevaCantidad > _maxNotas) return;

    if (nuevaCantidad > _notasControllers.length) {
      final controllersToAdd = <TextEditingController>[];
      final porcentajesToAdd = <TextEditingController>[];
      
      for (int i = _notasControllers.length; i < nuevaCantidad; i++) {
        final notaCtrl = TextEditingController();
        final porcCtrl = TextEditingController();
        
        final index = i;
        notaCtrl.addListener(() => _validarNotaEnTiempoRealDebounced(index));
        porcCtrl.addListener(() => _validarPorcentajeEnTiempoRealDebounced(index));

        controllersToAdd.add(notaCtrl);
        porcentajesToAdd.add(porcCtrl);
      }

      setState(() {
        _notasControllers.addAll(controllersToAdd);
        _porcentajesControllers.addAll(porcentajesToAdd);
        _notasErrors.addAll(List.filled(controllersToAdd.length, false));
        _porcentajesErrors.addAll(List.filled(porcentajesToAdd.length, false));
        _cantidadNotas = nuevaCantidad;
      });
    } else if (nuevaCantidad < _notasControllers.length) {
      for (int i = _notasControllers.length - 1; i >= nuevaCantidad; i--) {
        _debounceTimers[i]?.cancel();
        _debounceTimers.remove(i);
        
        _notasControllers[i].dispose();
        _porcentajesControllers[i].dispose();
      }

      setState(() {
        _notasControllers.removeRange(nuevaCantidad, _notasControllers.length);
        _porcentajesControllers.removeRange(nuevaCantidad, _porcentajesControllers.length);
        _notasErrors.removeRange(nuevaCantidad, _notasErrors.length);
        _porcentajesErrors.removeRange(nuevaCantidad, _porcentajesErrors.length);
        _cantidadNotas = nuevaCantidad;
      });
    }
  }

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();

    for (var controller in _notasControllers) {
      controller.dispose();
    }
    for (var controller in _porcentajesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validarNotaEnTiempoRealDebounced(int index) {
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] = Timer(const Duration(milliseconds: 300), () {
      _validarNotaEnTiempoReal(index);
    });
  }

  void _validarPorcentajeEnTiempoRealDebounced(int index) {
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] = Timer(const Duration(milliseconds: 300), () {
      _validarPorcentajeEnTiempoReal(index);
    });
  }

  void _validarNotaEnTiempoReal(int index) {
    if (index < 0 || index >= _notasControllers.length) return;

    final controller = _notasControllers[index];
    
    if (controller.text.isEmpty) {
      setState(() => _notasErrors[index] = false);
      return;
    }

    final nota = double.tryParse(controller.text.replaceAll(',', '.'));
    
    if (nota == null || nota < _notaMin || nota > _notaMax) {
      setState(() => _notasErrors[index] = true);
      _mostrarErrorPopupSimple(
        'La nota debe estar entre $_notaMin y $_notaMax',
        Icons.star_border_rounded,
      );
    } else {
      setState(() => _notasErrors[index] = false);
    }
  }

  void _validarPorcentajeEnTiempoReal(int index) {
    if (index < 0 || index >= _porcentajesControllers.length) return;

    final controller = _porcentajesControllers[index];
    
    if (controller.text.isEmpty) {
      setState(() => _porcentajesErrors[index] = false);
      return;
    }

    final porcentaje = double.tryParse(controller.text.replaceAll(',', '.'));
    
    if (porcentaje == null || porcentaje < _porcentajeMin || porcentaje > _porcentajeMax) {
      setState(() => _porcentajesErrors[index] = true);
      _mostrarErrorPopupSimple(
        'El porcentaje debe estar entre ${_porcentajeMin.toInt()}% y ${_porcentajeMax.toInt()}%',
        Icons.percent_rounded,
      );
    } else {
      setState(() => _porcentajesErrors[index] = false);
    }
  }

  void _mostrarErrorPopupSimple(String mensaje, IconData icono) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Material(
          color: Colors.black38,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      mensaje,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toca para cerrar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validarNota(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final nota = double.tryParse(value.replaceAll(',', '.'));
    if (nota == null) return 'Inválido';
    if (nota < _notaMin || nota > _notaMax) return 'Fuera de rango';
    return null;
  }

  String? _validarPorcentaje(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final p = double.tryParse(value.replaceAll(',', '.'));
    if (p == null) return 'Inválido';
    if (p < _porcentajeMin || p > _porcentajeMax) return 'Fuera de rango';
    return null;
  }

  Future<void> _guardarSinCalcular() async {
    // Verificar si hay al menos un PAR completo (nota + porcentaje)
    bool hayParCompleto = false;
    int paresCompletos = 0;
    
    for (int i = 0; i < _cantidadNotas; i++) {
      final notaText = _notasControllers[i].text.trim();
      final porcText = _porcentajesControllers[i].text.trim();
      
      // Si ambos campos tienen datos, es un par completo
      if (notaText.isNotEmpty && porcText.isNotEmpty) {
        hayParCompleto = true;
        paresCompletos++;
      }
      // Si solo uno tiene datos, es un error
      else if (notaText.isNotEmpty || porcText.isNotEmpty) {
        _mostrarErrorPopupSimple(
          'El campo ${i + 1} está incompleto.\n\nDebes llenar tanto la nota como el porcentaje, o dejar ambos vacíos.',
          Icons.warning_amber_rounded,
        );
        return;
      }
    }

    if (!hayParCompleto) {
      _mostrarErrorPopupSimple(
        'No hay datos para guardar.\n\nIngresa al menos una nota completa con su porcentaje.',
        Icons.info_outline,
      );
      return;
    }

    // Validar que las notas y porcentajes sean válidos
    try {
      for (int i = 0; i < _cantidadNotas; i++) {
        final notaText = _notasControllers[i].text.trim();
        final porcText = _porcentajesControllers[i].text.trim();
        
        if (notaText.isNotEmpty && porcText.isNotEmpty) {
          final nota = double.parse(notaText.replaceAll(',', '.'));
          final porcentaje = double.parse(porcText.replaceAll(',', '.'));
          
          // Validar rangos
          if (nota < _notaMin || nota > _notaMax) {
            _mostrarErrorPopupSimple(
              'La nota del campo ${i + 1} debe estar entre $_notaMin y $_notaMax',
              Icons.error_outline,
            );
            return;
          }
          
          if (porcentaje < _porcentajeMin || porcentaje > _porcentajeMax) {
            _mostrarErrorPopupSimple(
              'El porcentaje del campo ${i + 1} debe estar entre ${_porcentajeMin.toInt()}% y ${_porcentajeMax.toInt()}%',
              Icons.error_outline,
            );
            return;
          }
        }
      }
    } catch (e) {
      _mostrarErrorPopupSimple(
        'Hay valores inválidos.\n\nVerifica que todos los números estén correctamente escritos.',
        Icons.error_outline,
      );
      return;
    }

    // Mostrar popup de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildConfirmacionGuardadoDialog(ctx, paresCompletos),
    );

    if (confirmar != true) return;

    // Guardar solo los pares completos
    final notasItems = <NotaItem>[];
    
    for (int i = 0; i < _cantidadNotas; i++) {
      final notaText = _notasControllers[i].text.trim();
      final porcText = _porcentajesControllers[i].text.trim();
      
      if (notaText.isNotEmpty && porcText.isNotEmpty) {
        final nota = double.parse(notaText.replaceAll(',', '.'));
        final porcentaje = double.parse(porcText.replaceAll(',', '.'));
        notasItems.add(NotaItem(nota: nota, porcentaje: porcentaje));
      }
    }

    // Guardar sin promedio (promedioFinal = null)
    final notaAsignatura = NotaAsignatura(
      codigoAsignatura: widget.asignatura.codigo,
      notas: notasItems,
      promedioFinal: null,
    );
    
    await DataManager.guardarNotasAsignatura(notaAsignatura);
    
    if (mounted) {
      _mostrarGuardadoExitosoDialog(paresCompletos);
    }
  }

  Widget _buildConfirmacionGuardadoDialog(BuildContext ctx, int paresCompletos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.save_outlined,
              color: Colors.orange.shade600,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Guardar sin calcular?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Se guardarán $paresCompletos ${paresCompletos == 1 ? 'nota' : 'notas'} pero no se calculará el promedio.\n\nLa asignatura se mantendrá como "S/I".',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark 
                            ? const Color(0xFF3A3A3C) 
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sí, guardar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarGuardadoExitosoDialog(int paresCompletos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Datos Guardados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se ${paresCompletos == 1 ? 'guardó' : 'guardaron'} $paresCompletos ${paresCompletos == 1 ? 'nota' : 'notas'} correctamente.\n\nPuedes volver más tarde para completar y calcular el promedio.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Volver a Asignaturas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _calcularYGuardar() async {
    if (!_formKey.currentState!.validate()) return;

    double sumaPorcentajes = 0;
    double sumaPonderada = 0;

    final notasItems = <NotaItem>[];

    try {
      for (int i = 0; i < _cantidadNotas; i++) {
        if (i >= _notasControllers.length || i >= _porcentajesControllers.length) {
          throw Exception('Índice fuera de rango');
        }

        final nota = double.parse(_notasControllers[i].text.replaceAll(',', '.'));
        final porcentaje = double.parse(_porcentajesControllers[i].text.replaceAll(',', '.'));
        
        notasItems.add(NotaItem(nota: nota, porcentaje: porcentaje));
        
        sumaPorcentajes += porcentaje;
        sumaPonderada += (nota * porcentaje / 100);
      }
    } catch (e) {
      _mostrarErrorPopupSimple(
        'Error al procesar los datos. Verifica que todos los campos estén completos.',
        Icons.error_outline,
      );
      return;
    }

    if ((sumaPorcentajes - 100).abs() > 0.01) {
      _mostrarErrorSumaPopup(sumaPorcentajes);
      return;
    }

    // Guardar en SharedPreferences
    final notaAsignatura = NotaAsignatura(
      codigoAsignatura: widget.asignatura.codigo,
      notas: notasItems,
      promedioFinal: sumaPonderada,
    );
    
    await DataManager.guardarNotasAsignatura(notaAsignatura);
    
    if (mounted) {
      _mostrarResultadoPopup(sumaPonderada);
    }
  }

  void _mostrarErrorSumaPopup(double suma) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textoError = suma > 100 
        ? 'La suma de porcentajes no puede ser mayor a 100%'
        : 'La suma de porcentajes debe ser exactamente 100%';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Material(
          color: Colors.black38,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.orange.shade700,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      textoError,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Suma actual: ${suma.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Entendido',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarResultadoPopup(double promedio) {
    final bool aprobado = promedio >= _notaAprobacion;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: aprobado 
                  ? isDark 
                      ? [const Color(0xFF1C3A1C), const Color(0xFF2C4A2C)]
                      : [Colors.green.shade50, Colors.green.shade100]
                  : isDark
                      ? [const Color(0xFF3A1C1C), const Color(0xFF4A2C2C)]
                      : [Colors.red.shade50, Colors.red.shade100],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: aprobado 
                        ? Colors.green.shade100.withValues(alpha: 0.3)
                        : Colors.red.shade100.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    aprobado ? Icons.check_circle_rounded : Icons.warning_rounded,
                    size: 48,
                    color: aprobado ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.asignatura.codigo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  promedio.toStringAsFixed(2).replaceAll('.', ','),
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    color: aprobado ? Colors.green.shade700 : Colors.red.shade700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Promedio Ponderado',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: aprobado ? Colors.green.shade600 : Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    aprobado ? '¡Aprobado!' : 'Debe Rendir Examen',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '✅ Datos guardados correctamente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark 
                          ? const Color(0xFF3A3A3C) 
                          : Colors.white,
                      foregroundColor: const Color(0xFF007AFF),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark 
                              ? const Color(0xFF3A3A3C) 
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Volver a Asignaturas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _limpiar() {
    for (var ctrl in _notasControllers) {
      ctrl.clear();
    }
    for (var ctrl in _porcentajesControllers) {
      ctrl.clear();
    }
    
    setState(() {
      for (int i = 0; i < _cantidadNotas; i++) {
        _notasErrors[i] = false;
        _porcentajesErrors[i] = false;
      }
    });
  }

  Widget _buildNotaInput(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
              ? const Color(0xFF3A3A3C) 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _notasControllers[index],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  DecimalTextInputFormatter(),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Nota',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.stars_rounded,
                    color: _notasErrors[index] 
                        ? Colors.red 
                        : const Color(0xFF007AFF).withValues(alpha: 0.5),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? const Color(0xFF2C2C2E) 
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _notasErrors[index]
                          ? Colors.red
                          : isDark 
                              ? const Color(0xFF3A3A3C) 
                              : Colors.grey.shade300,
                      width: _notasErrors[index] ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _notasErrors[index]
                          ? Colors.red
                          : const Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                validator: _validarNota,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _porcentajesControllers[index],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  DecimalTextInputFormatter(),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: '%',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? const Color(0xFF2C2C2E) 
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _porcentajesErrors[index]
                          ? Colors.red
                          : isDark 
                              ? const Color(0xFF3A3A3C) 
                              : Colors.grey.shade300,
                      width: _porcentajesErrors[index] ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _porcentajesErrors[index]
                          ? Colors.red
                          : const Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                validator: _validarPorcentaje,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_cargando) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.asignatura.codigo),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.asignatura.codigo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              widget.asignatura.nombre,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                        ? const Color(0xFF3A3A3C) 
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Color(0xFF007AFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cantidad de Notas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Selecciona entre 2 y 10 notas',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2C2C2E) 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _cantidadNotas,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF007AFF)),
                        dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: List.generate(
                          _maxNotas - _minNotas + 1,
                          (index) => _minNotas + index,
                        ).map((int number) {
                          return DropdownMenuItem<int>(
                            value: number,
                            child: Text('$number'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            _cambiarCantidadConAdvertencia(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              ...List.generate(_cantidadNotas, (index) => _buildNotaInput(index)),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _calcularYGuardar,
                      icon: const Icon(Icons.calculate_rounded, size: 20),
                      label: const Text(
                        'Calcular Promedio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _limpiar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                        color: isDark 
                            ? const Color(0xFF3A3A3C) 
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 24),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Botón para guardar sin calcular
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _guardarSinCalcular,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Guardar sin Calcular',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: Colors.orange.shade600,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF007AFF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'La suma de porcentajes debe ser exactamente 100% para calcular el promedio',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.save_outlined,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Puedes guardar datos parciales sin calcular el promedio',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}