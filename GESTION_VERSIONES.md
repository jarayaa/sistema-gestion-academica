# 📦 GESTIÓN DE VERSIÓN DE LA APLICACIÓN

## 📖 ¿De Dónde Viene la Versión?

La versión de la aplicación se define en el archivo `pubspec.yaml` y se obtiene dinámicamente usando el paquete `package_info_plus`.

---

## 📄 Archivo pubspec.yaml

### Ubicación:
```
proyecto/
└── pubspec.yaml  ← Aquí se define la versión
```

### Formato de Versión:
```yaml
version: 2.0.0+2
         │││││ │
         ││││└─┴─ Build number (número de compilación)
         │││└──── Patch (correcciones de bugs)
         ││└───── Minor (nuevas funcionalidades compatibles)
         │└────── Major (cambios incompatibles)
         └─────── Esquema de versionado semántico
```

---

## 🔢 Versionado Semántico (SemVer)

### Estructura: MAJOR.MINOR.PATCH+BUILD

| Parte | Cuándo Incrementar | Ejemplo |
|-------|-------------------|---------|
| **MAJOR** | Cambios incompatibles con versiones anteriores | 1.x.x → **2**.0.0 |
| **MINOR** | Nuevas funcionalidades compatibles | 2.0.x → 2.**1**.0 |
| **PATCH** | Correcciones de bugs | 2.1.0 → 2.1.**1** |
| **BUILD** | Cada compilación nueva | 2.1.1+1 → 2.1.1+**2** |

---

## 📝 Ejemplos de Cambios de Versión

### Versión Actual:
```yaml
version: 2.0.0+2
```

### Escenario 1: Fix de Bug
```yaml
# Corriges el bug del loop con 1 nota
version: 2.0.1+3  # Incrementa PATCH y BUILD
```

### Escenario 2: Nueva Funcionalidad
```yaml
# Agregas exportar notas a PDF
version: 2.1.0+4  # Incrementa MINOR, resetea PATCH, incrementa BUILD
```

### Escenario 3: Cambio Mayor
```yaml
# Cambias completamente el sistema de datos (incompatible)
version: 3.0.0+5  # Incrementa MAJOR, resetea MINOR y PATCH, incrementa BUILD
```

### Escenario 4: Nueva Compilación
```yaml
# Recompilas sin cambios en el código (por ejemplo, para otra plataforma)
version: 2.0.0+3  # Solo incrementa BUILD
```

---

## 💻 Obtener la Versión en Código

### 1. Agregar Dependencia

```yaml
# pubspec.yaml
dependencies:
  package_info_plus: ^5.0.1
```

### 2. Importar Paquete

```dart
import 'package:package_info_plus/package_info_plus.dart';
```

### 3. Obtener Información

```dart
Future<void> _loadVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  
  // Versión completa
  String version = packageInfo.version;        // "2.0.0"
  String buildNumber = packageInfo.buildNumber; // "2"
  
  // Otras propiedades disponibles
  String appName = packageInfo.appName;         // "gestion_academica_unab"
  String packageName = packageInfo.packageName; // "com.example.gestion_academica_unab"
  
  // Usar en UI
  setState(() {
    _version = 'v$version';  // "v2.0.0"
  });
}
```

### 4. Información Disponible

| Propiedad | Descripción | Ejemplo |
|-----------|-------------|---------|
| `version` | Número de versión | "2.0.0" |
| `buildNumber` | Número de compilación | "2" |
| `appName` | Nombre de la app | "gestion_academica_unab" |
| `packageName` | Identificador del paquete | "com.unab.gestion" |

---

## 🎯 Uso en la Aplicación

### En SplashScreen:

```dart
class _SplashScreenState extends State<SplashScreen> {
  String _version = '...';  // Placeholder inicial
  
  @override
  void initState() {
    super.initState();
    _loadVersion();
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
      // Fallback si falla
      if (mounted) {
        setState(() {
          _version = 'v2.0.0';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(_version);  // Muestra "v2.0.0"
  }
}
```

---

## 🔄 Flujo de Actualización de Versión

```
1. Modificas el código
   ↓
2. Decides el tipo de cambio:
   - Bug fix → PATCH
   - Nueva feature → MINOR
   - Breaking change → MAJOR
   ↓
3. Actualizas pubspec.yaml:
   version: X.Y.Z+B
   ↓
4. La app lee automáticamente:
   PackageInfo.fromPlatform()
   ↓
5. Se muestra en Splash Screen
   y donde se necesite
```

---

## 📱 Versión en Diferentes Plataformas

### Android (build.gradle):
```gradle
// Se sincroniza automáticamente desde pubspec.yaml
def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
def flutterVersionName = localProperties.getProperty('flutter.versionName')

android {
    defaultConfig {
        versionCode flutterVersionCode.toInteger()  // 2
        versionName flutterVersionName              // "2.0.0"
    }
}
```

### iOS (Info.plist):
```xml
<!-- Se sincroniza automáticamente desde pubspec.yaml -->
<key>CFBundleShortVersionString</key>
<string>2.0.0</string>
<key>CFBundleVersion</key>
<string>2</string>
```

---

## 🎨 Mostrar Versión en la UI

### Opción 1: En Splash Screen
```dart
Text('v${packageInfo.version}')  // "v2.0.0"
```

### Opción 2: En Configuración/Ajustes
```dart
ListTile(
  title: Text('Versión de la app'),
  trailing: Text('v${packageInfo.version}'),
)
```

### Opción 3: En About Dialog
```dart
showAboutDialog(
  context: context,
  applicationName: packageInfo.appName,
  applicationVersion: 'v${packageInfo.version}',
  applicationIcon: Icon(Icons.school),
)
```

### Opción 4: Footer en HomePage
```dart
Text(
  'v${packageInfo.version} • Build ${packageInfo.buildNumber}',
  style: TextStyle(fontSize: 10, color: Colors.grey),
)
```

---

## 🔧 Comandos Útiles

### Ver versión actual:
```bash
grep "version:" pubspec.yaml
```

### Actualizar versión con sed:
```bash
# Incrementar patch: 2.0.0 → 2.0.1
sed -i 's/version: 2.0.0/version: 2.0.1/' pubspec.yaml

# Incrementar minor: 2.0.0 → 2.1.0
sed -i 's/version: 2.0.0/version: 2.1.0/' pubspec.yaml

# Incrementar build: +2 → +3
sed -i 's/+2/+3/' pubspec.yaml
```

### Actualizar y compilar:
```bash
# 1. Actualizar versión
vim pubspec.yaml

# 2. Obtener dependencias
flutter pub get

# 3. Limpiar build anterior
flutter clean

# 4. Compilar
flutter build apk  # Android
flutter build ios  # iOS
```

---

## 📊 Historial de Versiones Sugerido

### v1.0.0 (Primera versión)
```yaml
version: 1.0.0+1
```
- Calculadora básica
- Navegación trimestres
- Persistencia local

### v2.0.0 (Actual)
```yaml
version: 2.0.0+2
```
- Splash screen
- Guardar sin calcular
- Protección de datos
- Diseño responsivo
- Validaciones exhaustivas

### v2.1.0 (Futuro - Mejoras)
```yaml
version: 2.1.0+3
```
- Exportar a PDF
- Gráficos de progreso
- Temas personalizables

### v3.0.0 (Futuro - Mayor)
```yaml
version: 3.0.0+4
```
- Backend con Firebase
- Sincronización en la nube
- Multi-dispositivo

---

## 🚨 Buenas Prácticas

### ✅ Hacer:
- Incrementar build number en CADA compilación
- Usar versionado semántico consistente
- Documentar cambios en CHANGELOG.md
- Mantener versiones sincronizadas en todas las plataformas
- Probar después de cambiar versión

### ❌ No Hacer:
- Saltar números de versión sin razón
- Usar versiones inconsistentes
- Olvidar incrementar build number
- Hardcodear versión en múltiples lugares
- Cambiar MAJOR sin cambios reales significativos

---

## 📝 Plantilla CHANGELOG.md

```markdown
# Changelog

## [2.0.0] - 2025-11-29
### Agregado
- Splash screen con animaciones
- Guardar notas parciales sin calcular
- Protección contra pérdida de datos

### Corregido
- Bug de loop con 1 nota
- Overflow en cards de trimestre
- Estadísticas que no se actualizaban

### Cambiado
- Diseño 100% responsivo
- Actualizadas librerías deprecated

## [1.0.0] - 2025-11-15
### Agregado
- Calculadora básica de notas
- Navegación por trimestres
- Persistencia local
- Tema oscuro
```

---

## 🔍 Verificar Versión Instalada

### En desarrollo:
```dart
// Debug mode
debugPrint('App version: ${packageInfo.version}');
debugPrint('Build number: ${packageInfo.buildNumber}');
```

### En producción:
```dart
// Logs de Crashlytics / Analytics
FirebaseCrashlytics.instance.setCustomKey('app_version', packageInfo.version);
```

---

## 📦 Build Numbers Recomendados

### Estrategia 1: Incremental Simple
```
1.0.0+1
1.0.0+2
1.0.1+3
1.1.0+4
2.0.0+5
```

### Estrategia 2: Por Plataforma
```
1.0.0+101  # Android build 1
1.0.0+201  # iOS build 1
1.0.0+102  # Android build 2
```

### Estrategia 3: Fecha
```
2.0.0+20251129  # YYYYMMDD
```

---

## 🎓 Resumen

| Aspecto | Detalle |
|---------|---------|
| **Definición** | `pubspec.yaml` |
| **Formato** | `MAJOR.MINOR.PATCH+BUILD` |
| **Obtención** | `package_info_plus` |
| **Actualización** | Manual en pubspec.yaml |
| **Sincronización** | Automática a Android/iOS |
| **Visualización** | Dinámica en UI |

---

## ✅ Checklist de Actualización

- [ ] Decidir tipo de cambio (major/minor/patch)
- [ ] Actualizar `version:` en pubspec.yaml
- [ ] Incrementar build number (+X)
- [ ] Ejecutar `flutter pub get`
- [ ] Probar que la versión se muestra correctamente
- [ ] Actualizar CHANGELOG.md
- [ ] Commit: "chore: bump version to X.Y.Z"
- [ ] Tag en Git: `git tag vX.Y.Z`
- [ ] Compilar para distribución

---

**Archivo:** `pubspec.yaml` (línea 6)  
**Versión Actual:** 2.0.0+2  
**Package:** package_info_plus ^5.0.1

---

**¡La versión ahora se gestiona centralmente y se muestra dinámicamente!** 📦✨