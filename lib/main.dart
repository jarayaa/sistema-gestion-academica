import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Importaciones de tus servicios y pantallas nuevas
import 'services/auth_service.dart';
import 'services/github_api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/seleccion_carrera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios básicos
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
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

      // RUTAS ACTUALIZADAS
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // Usa la importada de screens/
        '/seleccion-carrera': (context) => const SeleccionCarreraScreen(),
        '/home': (context) => const HomePage(), // Ahora apunta correctamente al Home
      },
    );
  }
}

// ======================== MODELOS DE DATOS ========================

// Modelo adaptado para trabajar con JSON dinámico
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

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      trimestre: 0, // Se asigna externamente al leer el trimestre
      creditos: json['creditos'] ?? 0,
    );
  }
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
    promedioFinal: json['promedioFinal']?.toDouble(),
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
    nota: json['nota']?.toDouble() ?? 0.0,
    porcentaje: json['porcentaje']?.toDouble() ?? 0.0,
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

// ======================== PANTALLA PRINCIPAL (HOME) ========================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _notaAprobacion = 3.95; // Ajuste para aproximación a 4.0
  
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
      // 1. Obtener datos del usuario (carrera seleccionada)
      final authService = await AuthService.init();
      final carreraId = authService.getCarreraId();
      final nombre = authService.getNombre();
      
      if (carreraId != null) {
        // 2. Obtener malla de esa carrera desde GitHub/Cache
        final apiService = GitHubApiService();
        final carrera = await apiService.fetchCarreraPorId(carreraId);
        
        if (carrera != null) {
          // 3. Procesar asignaturas
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
                creditos: a['creditos'],
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
      
      // 4. Cargar notas guardadas
      final notas = await DataManager.cargarNotas();
      
      if (mounted) {
        setState(() {
          _notas = notas;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error al cargar home: $e');
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _navegarATrimestre(BuildContext context, int trimestre) async {
    // Filtrar asignaturas de este trimestre
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
    
    // Recargar estadísticas al volver
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_cargando) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_carreraData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar la información de la carrera'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cambiar Carrera',
          )
        ],
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
                child: _buildTrimestreGrid(context, totalTrimestres, isDark),
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
          const Icon(Icons.school_rounded, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            _carreraData!['nombre'] ?? 'Carrera',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Bienvenido, $_nombreUsuario',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_carreraData!['duracion_trimestres']} Trimestres • ${_todasAsignaturas.length} Asignaturas',
              style: const TextStyle(
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

  Widget _buildTrimestreGrid(BuildContext context, int totalTrimestres, bool isDark) {
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
            children: List.generate(totalTrimestres, (index) {
              final trimestre = index + 1;
              final numAsignaturas = _todasAsignaturas
                  .where((a) => a.trimestre == trimestre)
                  .length;
              
              return _buildTrimestreCard(context, trimestre, numAsignaturas, isDark);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.15),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$numAsignaturas asignaturas',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(BuildContext context, bool isDark) {
    final totalAsignaturas = _todasAsignaturas.length;
    final aprobadas = _notas.where((n) => 
      n.promedioFinal != null && n.promedioFinal! >= _notaAprobacion
    ).length;
    
    // El resto de la lógica de estadísticas...
    final porcentaje = totalAsignaturas > 0 
        ? (aprobadas / totalAsignaturas * 100).toStringAsFixed(1) 
        : '0.0';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('Progreso General', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalAsignaturas > 0 ? aprobadas / totalAsignaturas : 0,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            color: const Color(0xFF007AFF),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('$aprobadas de $totalAsignaturas asignaturas aprobadas ($porcentaje%)'),
        ],
      ),
    );
  }
}

// ======================== PANTALLA DE ASIGNATURAS (ACTUALIZADA) ========================

class AsignaturasPage extends StatefulWidget {
  final int trimestre;
  final List<Asignatura> asignaturas; // Recibe la lista dinámica

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
    setState(() {
      _promedios = {
        for (var n in notas) n.codigoAsignatura: n.promedioFinal
      };
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Trimestre ${widget.trimestre}'),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      ),
      body: widget.asignaturas.isEmpty 
        ? const Center(child: Text('No hay asignaturas en este trimestre'))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: widget.asignaturas.length,
            itemBuilder: (context, index) {
              final asignatura = widget.asignaturas[index];
              final promedio = _promedios[asignatura.codigo];
              return _buildAsignaturaCard(context, asignatura, promedio, isDark);
            },
          ),
    );
  }

  Widget _buildAsignaturaCard(BuildContext context, Asignatura asignatura, double? promedio, bool isDark) {
    final tienePromedio = promedio != null;
    // Ajuste de aprobación
    final aprobado = tienePromedio && promedio >= 3.95; 
    
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _abrirCalculadora(asignatura),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tienePromedio
                ? (aprobado ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2))
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              asignatura.codigo.length > 3 ? asignatura.codigo.substring(0, 3) : asignatura.codigo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tienePromedio
                    ? (aprobado ? Colors.green : Colors.red)
                    : Colors.blue,
              ),
            ),
          ),
        ),
        title: Text(
          asignatura.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${asignatura.creditos} créditos'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tienePromedio
                ? (aprobado ? Colors.green : Colors.red)
                : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tienePromedio ? promedio.toStringAsFixed(1) : '-',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ======================== CALCULADORA (MANTENER LA ANTERIOR) ========================
// NOTA: Copia aquí la clase CalculadoraPage que ya tenías en tu código original
// ya que esa parte funcionaba bien. Solo asegúrate de usar la clase Asignatura
// nueva que definimos arriba.

class CalculadoraPage extends StatefulWidget {
  final Asignatura asignatura;

  const CalculadoraPage({super.key, required this.asignatura});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  // ... (PEGA AQUÍ EL CÓDIGO DE TU CALCULADORA PAGE QUE YA TENÍAS)
  // Para que compile rápido, he incluido una versión mínima funcional aquí abajo.
  // Recomiendo usar tu versión completa si tenía validaciones extra.

  final _formKey = GlobalKey<FormState>();
  int _cantidadNotas = 3;
  final List<TextEditingController> _notasControllers = [];
  final List<TextEditingController> _porcentajesControllers = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await DataManager.obtenerNotasAsignatura(widget.asignatura.codigo);
    // Lógica simplificada de carga
    _actualizarControladores(datos?.notas.length ?? 3);
    if (datos != null) {
      for (int i = 0; i < datos.notas.length; i++) {
        _notasControllers[i].text = datos.notas[i].nota.toString();
        _porcentajesControllers[i].text = datos.notas[i].porcentaje.toString();
      }
    }
  }

  void _actualizarControladores(int cantidad) {
    _notasControllers.clear();
    _porcentajesControllers.clear();
    for (int i = 0; i < cantidad; i++) {
      _notasControllers.add(TextEditingController());
      _porcentajesControllers.add(TextEditingController());
    }
    setState(() => _cantidadNotas = cantidad);
  }

  Future<void> _guardar() async {
    List<NotaItem> notas = [];
    double promedio = 0;
    for (int i = 0; i < _cantidadNotas; i++) {
      if (_notasControllers[i].text.isNotEmpty) {
        final n = double.parse(_notasControllers[i].text.replaceAll(',', '.'));
        final p = double.parse(_porcentajesControllers[i].text.replaceAll(',', '.'));
        notas.add(NotaItem(nota: n, porcentaje: p));
        promedio += n * (p / 100);
      }
    }
    
    await DataManager.guardarNotasAsignatura(NotaAsignatura(
      codigoAsignatura: widget.asignatura.codigo,
      notas: notas,
      promedioFinal: promedio,
    ));
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.asignatura.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(_cantidadNotas, (i) => Row(
            children: [
              Expanded(child: TextField(controller: _notasControllers[i], decoration: const InputDecoration(labelText: 'Nota'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _porcentajesControllers[i], decoration: const InputDecoration(labelText: '%'))),
            ],
          )),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _guardar, child: const Text('Guardar'))
        ],
      ),
    );
  }
}