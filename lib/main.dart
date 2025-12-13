import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de servicios y pantallas
import 'services/auth_service.dart';
import 'services/github_api_service.dart';
import 'screens/seleccion_carrera_screen.dart';
import 'screens/splash_screen.dart';

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
      title: 'Sistema de Gestión Académica', // 1. Nombre corregido
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
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

// ======================== HOME PAGE ========================

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
      
      // 2. Validación de persistencia: Si no hay usuario, volver al inicio
      if (!authService.isUsuarioRegistrado()) {
        if(mounted) Navigator.of(context).pushReplacementNamed('/seleccion-carrera');
        return;
      }

      final carreraId = authService.getCarreraId();
      final nombre = authService.getNombre();
      
      if (carreraId != null) {
        final apiService = GitHubApiService();
        final carrera = await apiService.fetchMallaCompleta(carreraId);
        
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

  // 3. Botón y lógica para borrar todo
  Future<void> _borrarTodoYSalir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("¿Borrar todo y reiniciar?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Esta acción eliminará tu cuenta, carrera seleccionada y todas las notas guardadas de este dispositivo.\n\nNo se puede deshacer.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Borrar Todo", style: TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = await AuthService.init();
      await authService.borrarTodo(); // Asegúrate de haber implementado esto en AuthService
      
      if (mounted) {
        // Redirigir y limpiar el historial de navegación
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
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
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Color(0xFFFF453A)),
            onPressed: _borrarTodoYSalir,
            tooltip: 'Borrar todo',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF152D45), Color(0xFF1F4060)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      _carreraData!['nombre'] ?? 'Carrera',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Universidad Andrés Bello',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalTrimestres Trimestres • ${_todasAsignaturas.length} Asignaturas',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bienvenido, $_nombreUsuario', 
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Selecciona un Trimestre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
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
              _buildEstadisticasCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrimestreCard(BuildContext context, int trimestre, int numAsignaturas) {
    return InkWell(
      onTap: () => _navegarATrimestre(context, trimestre),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2540),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$trimestre',
                  style: const TextStyle(
                    fontSize: 24,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$numAsignaturas asignaturas',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
    final progreso = totalAsignaturas > 0 ? (aprobadas / totalAsignaturas * 100) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.check_circle, '$aprobadas', 'Completadas', const Color(0xFF34C759)),
              _buildStatItem(Icons.more_horiz, '$pendientes', 'Pendientes', const Color(0xFFFF9F0A)),
              _buildStatItem(Icons.trending_up, '${progreso.toStringAsFixed(1)}%', 'Progreso', const Color(0xFF007AFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ======================== ASIGNATURAS PAGE ========================

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
        backgroundColor: const Color(0xFF000000),
      ),
      body: widget.asignaturas.isEmpty 
        ? const Center(child: Text('No hay asignaturas', style: TextStyle(color: Colors.white)))
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
    // Definimos colores y textos directamente basados en el promedio
    final Color badgeBgColor = promedio == null 
        ? const Color(0xFF3A3A3C) 
        : (promedio >= 3.95 ? const Color(0xFF34C759).withValues(alpha: 0.2) : const Color(0xFFFF3B30).withValues(alpha: 0.2));
    
    final Color badgeTextColor = promedio == null 
        ? Colors.white 
        : (promedio >= 3.95 ? const Color(0xFF34C759) : const Color(0xFFFF3B30));

    final String badgeText = promedio == null ? 'S/I' : promedio.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirCalculadora(asignatura),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono cuadrado azul con código
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2540),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      asignatura.codigo.split(RegExp(r'\d')).first, // Solo letras del código
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asignatura.codigo,
                        style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        asignatura.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${asignatura.creditos} créditos',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Badge S/I y flecha
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================== CALCULADORA ========================

class CalculadoraPage extends StatefulWidget {
  final Asignatura asignatura;

  const CalculadoraPage({super.key, required this.asignatura});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  int _cantidadNotas = 3;
  final List<TextEditingController> _notasControllers = [];
  final List<TextEditingController> _porcentajesControllers = [];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarDatosExistentes();
  }

  void _inicializarControladores() {
    _notasControllers.clear();
    _porcentajesControllers.clear();
    for (int i = 0; i < 10; i++) { // Max 10 notas
      _notasControllers.add(TextEditingController());
      _porcentajesControllers.add(TextEditingController());
    }
  }

  Future<void> _cargarDatosExistentes() async {
    final datos = await DataManager.obtenerNotasAsignatura(widget.asignatura.codigo);
    if (datos != null) {
      setState(() {
        _cantidadNotas = datos.notas.length;
        for (int i = 0; i < datos.notas.length; i++) {
          _notasControllers[i].text = datos.notas[i].nota.toString().replaceAll('.', ',');
          _porcentajesControllers[i].text = datos.notas[i].porcentaje.toStringAsFixed(0);
        }
      });
    }
  }

  double? _calcularPromedio() {
    double promedio = 0;
    double sumaPorc = 0;
    
    for (int i = 0; i < _cantidadNotas; i++) {
      String nText = _notasControllers[i].text.replaceAll(',', '.');
      String pText = _porcentajesControllers[i].text.replaceAll(',', '.');
      
      if (nText.isNotEmpty && pText.isNotEmpty) {
        final nota = double.tryParse(nText) ?? 0;
        final porc = double.tryParse(pText) ?? 0;
        
        if (nota < 1.0 || nota > 7.0) return null;
        
        promedio += nota * (porc / 100);
        sumaPorc += porc;
      } else {
        return null; 
      }
    }
    
    if ((sumaPorc - 100).abs() > 0.1) return null;
    
    return promedio;
  }

  bool _validarInputs() {
    for (int i = 0; i < _cantidadNotas; i++) {
      String nText = _notasControllers[i].text.replaceAll(',', '.');
      String pText = _porcentajesControllers[i].text.replaceAll(',', '.');
      
      if (nText.isNotEmpty) {
        double n = double.tryParse(nText) ?? 0;
        if (n < 1.0 || n > 7.0) {
          _mostrarAlertaError('La nota debe estar entre 1.0 y 7.0');
          return false;
        }
      }
      
      if (pText.isNotEmpty) {
        double p = double.tryParse(pText) ?? 0;
        if (p < 0 || p > 100) {
          _mostrarAlertaError('El porcentaje debe estar entre 0% y 100%');
          return false;
        }
      }
    }
    return true;
  }

  void _mostrarAlertaError(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, color: Color(0xFFFF453A), size: 48),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Toca para cerrar", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar(bool calcular) async {
    if (!_validarInputs()) return;

    double? promedio;
    if (calcular) {
      promedio = _calcularPromedio();
      
      double sumaPorc = 0;
      for(int i=0; i<_cantidadNotas; i++) {
        sumaPorc += double.tryParse(_porcentajesControllers[i].text.replaceAll(',', '.')) ?? 0;
      }
      if ((sumaPorc - 100).abs() > 0.1) {
        _mostrarAlertaError("La suma de porcentajes debe ser exactamente 100%");
        return;
      }
      
      if (promedio == null) {
         _mostrarAlertaError("Faltan datos para calcular");
         return;
      }
    }

    List<NotaItem> items = [];
    for (int i = 0; i < _cantidadNotas; i++) {
      String nText = _notasControllers[i].text.replaceAll(',', '.');
      String pText = _porcentajesControllers[i].text.replaceAll(',', '.');
      if (nText.isNotEmpty && pText.isNotEmpty) {
        items.add(NotaItem(
          nota: double.parse(nText),
          porcentaje: double.parse(pText),
        ));
      }
    }

    await DataManager.guardarNotasAsignatura(NotaAsignatura(
      codigoAsignatura: widget.asignatura.codigo,
      notas: items,
      promedioFinal: promedio,
    ));

    if (mounted) {
      if (calcular && promedio != null) {
        _mostrarModalResultado(promedio);
      } else {
        _mostrarModalGuardadoSinCalcular(items.length);
      }
    }
  }

  void _mostrarModalResultado(double promedio) {
    bool aprobado = promedio >= 3.95;
    bool examen = promedio >= 3.0 && promedio < 3.95;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: aprobado ? const Color(0xFF1B3B1B) : (examen ? const Color(0xFF3B1B1B) : const Color(0xFF3B1B1B)),
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: aprobado 
                ? [const Color(0xFF2E5C2E), const Color(0xFF1B3B1B)] 
                : [const Color(0xFF5C2E2E), const Color(0xFF3B1B1B)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  aprobado ? Icons.check : Icons.warning_amber_rounded,
                  size: 40,
                  color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF453A),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.asignatura.codigo, style: const TextStyle(color: Colors.white70)),
              Text(
                promedio.toStringAsFixed(2).replaceAll('.', ','),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF453A),
                ),
              ),
              const Text("Promedio Ponderado", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: aprobado ? const Color(0xFF34C759) : const Color(0xFFFF453A),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  aprobado ? "¡Aprobado!" : (examen ? "Debe Rendir Examen" : "Reprobado"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_box, color: Color(0xFF34C759), size: 20),
                  SizedBox(width: 8),
                  Text("Datos guardados correctamente", style: TextStyle(color: Color(0xFF34C759))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3A3C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("Volver a Asignaturas", style: TextStyle(color: Color(0xFF007AFF))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalGuardadoSinCalcular(int cantidad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.save_outlined, color: Color(0xFFFF9F0A), size: 48),
            const SizedBox(height: 16),
            const Text("¿Guardar sin calcular?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              "Se guardarán $cantidad notas pero no se calculará el promedio.\n\nLa asignatura se mantendrá como \"S/I\".",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("No", style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F0A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Sí, guardar", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.asignatura.codigo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.asignatura.nombre, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        backgroundColor: const Color(0xFF000000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selector Cantidad Notas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2540),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers, color: Color(0xFF007AFF)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cantidad de Notas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("Selecciona entre 2 y 10 notas", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
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
                      items: List.generate(9, (index) => index + 2).map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("$e", style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _cantidadNotas = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Lista de Inputs
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cantidadNotas,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Número
                      Container(
                        width: 40,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2540),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("${index+1}", style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      // Input Nota
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _notasControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [DecimalTextInputFormatter()],
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Nota",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.star, color: Color(0xFF007AFF), size: 18),
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Input Porcentaje
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _porcentajesControllers[index],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "%",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              suffixText: "%",
                              suffixStyle: TextStyle(color: Colors.grey),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Botones Acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _guardar(true), // Calcular
                    icon: const Icon(Icons.calculate),
                    label: const Text("Calcular Promedio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A3C)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF007AFF)),
                    onPressed: _inicializarControladores,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFFF9F0A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _guardar(false), // Guardar sin calcular
                icon: const Icon(Icons.save, color: Color(0xFFFF9F0A)),
                label: const Text("Guardar sin Calcular", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9F0A))),
              ),
            ),
            
            const SizedBox(height: 24),
            // Info Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2540).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F2540)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF007AFF), size: 20),
                      SizedBox(width: 12),
                      Expanded(child: Text("La suma de porcentajes debe ser exactamente 100% para calcular el promedio", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.save, color: Color(0xFFFF9F0A), size: 20),
                      SizedBox(width: 12),
                      Expanded(child: Text("Puedes guardar datos parciales sin calcular el promedio", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}