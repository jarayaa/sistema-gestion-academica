# 📚 Sistema de Gestión Académica UNAB

Aplicación móvil Flutter para gestión de notas y seguimiento académico de la Universidad Andrés Bello (Chile).

## 📖 Descripción
Sistema de Gestión Académica UNAB es una aplicación móvil desarrollada en Flutter que permite a los estudiantes de la Universidad Andrés Bello gestionar sus notas de manera eficiente y profesional.
La aplicación está específicamente diseñada para el sistema académico chileno, implementando:

Escala de notas 1.0 a 7.0 con formato chileno (coma decimal)
Cálculo de promedios ponderados basado en porcentajes
Malla curricular completa con 43 asignaturas distribuidas en 10 trimestres
Validaciones exhaustivas que previenen errores de ingreso
Persistencia local para acceder a tus datos sin conexión

## 🎓 ¿Para quién es esta app?
Esta aplicación es ideal para:

✅ Estudiantes que quieren llevar un registro organizado de sus notas
✅ Quienes necesitan calcular promedios ponderados rápidamente
✅ Estudiantes que cursan materias con evaluaciones parciales
✅ Quienes desean visualizar su progreso académico por trimestre
✅ Estudiantes que quieren guardar notas parciales antes de tener todos los resultados

## 💡 ¿Qué la hace especial?
A diferencia de calculadoras simples, esta aplicación:

🛡️ Protege tus datos: Advertencias antes de acciones destructivas
💾 Guarda automáticamente: Tus notas se mantienen entre sesiones
📊 Actualiza en tiempo real: Las estadísticas se actualizan instantáneamente
✨ Validación inteligente: Detecta errores mientras escribes
📱 100% Responsiva: Se adapta a cualquier dispositivo o tamaño de pantalla
🌙 Diseño profesional: Tema oscuro elegante estilo macOS

## 🚀 Caso de Uso Real
Escenario: Tienes 3 notas de ATDF101 (Tópicos de Ingeniería)

1️⃣ Abres la app → Seleccionas Trimestre 1
2️⃣ Ingresas tus notas:
   - Prueba 1: 6,5 (30%)
   - Prueba 2: 6,0 (40%)
   - Examen: Aún no rendido

3️⃣ Presionas "Guardar sin Calcular"
   → Tus notas quedan guardadas
   → La asignatura muestra "S/I" (Sin Información)

4️⃣ Después del examen:
   - Vuelves a la app
   - Completas: Examen: 6,8 (30%)
   - Presionas "Calcular Promedio"

5️⃣ Resultado instantáneo:
   → Promedio: 6,41
   → Estado: ¡Aprobado! ✅
   → Datos guardados automáticamente


---

## 🎯 Características Principales

### 📊 Gestión de Notas
- ✅ Calculadora de notas con validación en tiempo real
- ✅ Guardado parcial sin calcular promedio
- ✅ Protección contra pérdida de datos
- ✅ Soporte para 2-10 notas por asignatura
- ✅ Validación de rangos (notas 1.0-7.0, porcentajes 0-100%)
- ✅ Formato chileno (coma decimal)

### 📈 Estadísticas y Seguimiento
- ✅ Actualización automática de estadísticas
- ✅ Progreso por trimestre (Completadas/Pendientes)
- ✅ Visualización de estado: Aprobado/S/I/Reprobado
- ✅ Navegación entre 10 trimestres académicos

### 🎨 Diseño
- ✅ Tema oscuro macOS-style
- ✅ 100% responsivo (smartphones, tablets, plegables)
- ✅ Sin overflow en ninguna pantalla
- ✅ Material Design 3

### 💾 Persistencia
- ✅ Almacenamiento local con SharedPreferences
- ✅ Recuperación automática de datos
- ✅ Sincronización inmediata

---

## 📱 Capturas de Pantalla

### Pantalla Principal
- Vista de 10 trimestres en grid 2x5
- Estadísticas de progreso por trimestre
- Indicadores visuales de estado

### Calculadora de Notas
- Campos de entrada con validación en tiempo real
- Selector de cantidad (2-10 notas)
- Botones: Calcular Promedio / Guardar sin Calcular / Limpiar
- Advertencias de pérdida de datos

### Resultado del Cálculo
- Promedio ponderado grande y claro
- Estado: Aprobado / Debe Rendir Examen
- Desglose de notas calculadas

---

## 🚀 Instalación

### Prerrequisitos
```bash
- Flutter 3.18.0 o superior
- Dart 3.0.0 o superior
- Android SDK / Xcode (según plataforma)
```

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/jarayaa/gestion-academica-unab.git
cd gestion-academica-unab
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Copiar archivos principales**
```bash
# Copiar el código principal
cp main_gestion_academica.dart lib/main.dart

# Copiar datos de malla curricular
cp malla_curricular_data.dart lib/malla_curricular_data.dart
```

4. **Ejecutar la aplicación**
```bash
# En emulador/dispositivo
flutter run

# Hot reload durante desarrollo
r

# Hot restart (recomendado después de cambios mayores)
R
```

---

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2  # Persistencia de datos

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                      # Código principal de la aplicación
├── malla_curricular_data.dart     # 43 asignaturas de la malla curricular
└── models/
    ├── asignatura.dart            # Modelo de asignatura
    ├── nota_item.dart             # Modelo de nota individual
    ├── nota_asignatura.dart       # Modelo de notas de asignatura
    └── data_manager.dart          # Gestor de persistencia
```

---

## 🎓 Funcionalidades Detalladas

### 1. Calculadora de Notas

#### Características:
- **Cantidad flexible:** 2-10 notas
- **Validación en tiempo real:** Detecta errores al escribir
- **Dos modos de guardado:**
  - Calcular Promedio: Requiere suma = 100%
  - Guardar sin Calcular: Permite guardado parcial

#### Validaciones Implementadas:
```
✅ Notas entre 1.0 y 7.0
✅ Porcentajes entre 0% y 100%
✅ Suma de porcentajes = 100% (para calcular)
✅ Pares completos (nota + porcentaje)
✅ Detección de campos incompletos
✅ Normalización de formato (coma/punto)
```

#### Mensajes Claros:
```
❌ "El campo 2 está incompleto"
❌ "La suma debe ser exactamente 100%"
❌ "La nota debe estar entre 1.0 y 7.0"
✅ "Se guardó 1 nota correctamente"
✅ "Promedio: 6.41 - ¡Aprobado!"
```

---

### 2. Guardar sin Calcular

#### ¿Cuándo usar?
```
Ejemplo: Asignatura ATDF101
- Prueba 1: 6,5 (30%) ✓
- Prueba 2: 6,0 (40%) ✓
- Examen: ??? (30%) ← Aún no rendido

Solución: "Guardar sin Calcular"
```

#### Flujo:
```
1. Ingresar notas parciales
2. Presionar "Guardar sin Calcular"
3. Confirmar en popup: "Se guardará 1 nota"
4. ✅ Datos guardados, asignatura muestra "S/I"
5. Volver después para completar
```

#### Beneficios:
- ✅ No pierdes datos ingresados
- ✅ Puedes completar más tarde
- ✅ No afecta estadísticas generales
- ✅ Fácil de identificar (badge gris "S/I")

---

### 3. Protección contra Pérdida de Datos

#### Escenario Protegido:
```
Usuario tiene 5 notas guardadas
Cambia selector: 5 → 3 notas

⚠️ ADVERTENCIA AUTOMÁTICA:
"Al reducir la cantidad de notas,
los campos 4, 5 perderán sus datos.
¿Deseas continuar?"

[Cancelar] [Continuar]
```

#### Casos Cubiertos:
- ✅ Reducir con datos → Advertencia
- ✅ Reducir sin datos → Sin advertencia
- ✅ Aumentar → Sin advertencia
- ✅ Detecta incluso campos parciales

---

### 4. Actualización Automática de Estadísticas

#### Antes del Fix:
```
❌ Guardar notas → Volver → Estadísticas desactualizadas
❌ Usuario confundido: "¿Por qué sigue en 0%?"
```

#### Después del Fix:
```
✅ Guardar notas → Volver → Estadísticas actualizadas
✅ Card de asignatura muestra promedio
✅ Contadores se actualizan inmediatamente
```

---

## 🎨 Diseño Responsivo

### Técnicas Implementadas:
```dart
✅ LayoutBuilder - Tamaños dinámicos
✅ FittedBox - Texto adaptable
✅ Porcentajes sobre píxeles fijos
✅ Ratios dinámicos (childAspectRatio)
```

### Dispositivos Compatibles:
```
📱 Smartphones:
   - iPhone SE (375px)
   - Pixel 5 (393px)
   - Galaxy S21 (360px)

📱 Tablets:
   - iPad Mini (768px)
   - iPad Pro (1024px)

📱 Plegables:
   - Galaxy Fold cerrado (280px)
   - Galaxy Fold abierto (717px)

🔄 Orientaciones:
   - Portrait ✅
   - Landscape ✅
```

---

## 🐛 Bugs Corregidos

### 1. Loop Infinito con 1 Nota
**Problema:** Guardar 1 nota → Volver a entrar → App en loop
**Solución:** Asegurar mínimo 2 controladores al cargar

### 2. Overflow Amarillo
**Problema:** Cards de trimestre mostraban overflow
**Solución:** Diseño 100% responsivo con LayoutBuilder

### 3. Warnings de Deprecación
**Problemas corregidos:**
```dart
❌ background → ✅ surface
❌ dialogBackgroundColor → ✅ DialogThemeData
❌ withOpacity → ✅ withValues(alpha:)
```
Total: 15 correcciones

### 4. Estadísticas No Actualizadas
**Problema:** Estadísticas no se refrescaban al volver
**Solución:** Recargar promedios después de Navigator.pop

---

## 📊 Datos de Ejemplo

### Estructura JSON (Guardado Completo):
```json
{
  "codigoAsignatura": "ATDF101",
  "notas": [
    {"nota": 6.5, "porcentaje": 30.0},
    {"nota": 6.0, "porcentaje": 40.0},
    {"nota": 6.8, "porcentaje": 30.0}
  ],
  "promedioFinal": 6.41
}
```

### Estructura JSON (Guardado Parcial):
```json
{
  "codigoAsignatura": "ATDF101",
  "notas": [
    {"nota": 6.5, "porcentaje": 30.0},
    {"nota": 6.0, "porcentaje": 40.0}
  ],
  "promedioFinal": null
}
```

---

## 🧪 Testing

### Casos de Prueba Implementados:

#### Validación de Entrada:
```
✅ Campos vacíos → Error
✅ Solo nota sin % → Error
✅ Solo % sin nota → Error
✅ Nota fuera de rango → Error
✅ % fuera de rango → Error
✅ Texto no numérico → Error
✅ Pares completos → OK
```

#### Cantidad de Notas:
```
✅ 0 notas (nuevo) → 3 campos por defecto
✅ 1 nota guardada → Muestra 2 campos (1 lleno)
✅ 2-10 notas → Carga correctamente
✅ Aumentar cantidad → Crea campos vacíos
✅ Reducir con datos → Advertencia
✅ Reducir sin datos → Sin advertencia
```

#### Cálculo de Promedio:
```
✅ Suma ≠ 100% → Error
✅ Suma = 100% → Calcula correctamente
✅ Promedio ≥ 5.5 → Aprobado
✅ Promedio < 5.5 → Debe Rendir Examen
```

---

## 📝 Formato de Notas Chileno

### Características:
```
✅ Coma como separador decimal (6,5 en lugar de 6.5)
✅ Escala 1.0 - 7.0
✅ Nota de aprobación: 5.5
✅ Promedio ponderado
✅ Porcentajes con %
```

### Conversión Automática:
```
Entrada del usuario: "6,5" o "6.5"
Almacenamiento interno: 6.5 (double)
Visualización: "6,5" (string con coma)
```

---

## 🔧 Configuración Avanzada

### Cambiar Nota de Aprobación:
```dart
// En CalculadoraPage
static const double _notaAprobacion = 5.5; // Cambiar aquí
```

### Cambiar Rangos:
```dart
// Notas
static const double _notaMin = 1.0;
static const double _notaMax = 7.0;

// Porcentajes
static const double _porcentajeMin = 0.0;
static const double _porcentajeMax = 100.0;
```

### Cambiar Cantidad de Notas:
```dart
static const int _minNotas = 2;
static const int _maxNotas = 10;
```

---

## 📚 Malla Curricular

### Trimestres Incluidos:
```
Trimestre 1-10: 43 asignaturas totales
Distribución:
- Trimestre 1: 3 asignaturas
- Trimestre 2: 5 asignaturas
- Trimestre 3: 5 asignaturas
- ... (continúa hasta Trimestre 10)
```

### Ejemplo de Asignatura:
```dart
Asignatura(
  codigo: 'ATDF101',
  nombre: 'TÓPICOS DE INGENIERÍA',
  creditos: 6,
  trimestre: 1,
)
```

---

## 🚀 Próximas Mejoras Potenciales

### Funcionalidades Sugeridas:
```
📊 Exportar notas a PDF/Excel
📈 Gráficos de progreso
🔔 Notificaciones de plazos
☁️ Sincronización en la nube
👥 Compartir con compañeros
📅 Calendario académico
🎯 Metas de promedio
📧 Envío por email
```

---

## 🤝 Contribuir

### Pasos para Contribuir:
```bash
1. Fork el repositorio
2. Crear rama: git checkout -b feature/nueva-funcionalidad
3. Commit cambios: git commit -m 'Agregar nueva funcionalidad'
4. Push a rama: git push origin feature/nueva-funcionalidad
5. Crear Pull Request
```

### Guías de Estilo:
- ✅ Usar Material Design 3
- ✅ Mantener tema oscuro
- ✅ Validar todas las entradas
- ✅ Documentar cambios
- ✅ Probar en múltiples dispositivos

---

## 📄 Documentación Adicional

### Archivos de Documentación:
```
📖 INSTALACION_COMPLETA.md - Guía detallada de instalación
📖 NUEVAS_FUNCIONALIDADES.md - Funcionalidades recientes
📖 VALIDACIONES_GUARDAR.md - Sistema de validaciones
📖 PROTECCION_PERDIDA_DATOS.md - Protección implementada
📖 FIX_BUG_UNA_NOTA.md - Corrección del bug de loop
📖 DISENO_RESPONSIVO.md - Técnicas de diseño
📖 CAMBIOS_DEPRECACION.md - Actualizaciones de Flutter
📖 TEST_CASOS_0_A_10_NOTAS.md - Casos de prueba
```

---

## ⚠️ Troubleshooting

### Problema: App crashea al abrir
```bash
Solución:
1. flutter clean
2. flutter pub get
3. flutter run
```

### Problema: Hot reload no funciona
```bash
Solución:
1. Presionar R (Hot restart)
2. O detener app y ejecutar: flutter run
```

### Problema: Datos no se guardan
```bash
Verificar:
1. Permisos de almacenamiento
2. SharedPreferences inicializado
3. No usar navegador web (usar emulador/dispositivo)
```

### Problema: Overflow en pantalla
```bash
Solución:
1. Verificar que tienes la versión más reciente
2. El diseño es 100% responsivo ahora
3. Si persiste, reportar con captura de pantalla
```

---

## 📊 Estadísticas del Proyecto

```
📝 Líneas de código: ~2100
📂 Archivos principales: 5
📚 Asignaturas incluidas: 43
🎨 Pantallas: 4 principales
✅ Validaciones: 15+
🐛 Bugs corregidos: 4 mayores
📖 Documentación: 8 archivos
```

---

## 📜 Licencia

Este proyecto es de uso académico para estudiantes de la Universidad Andrés Bello.

---

## 👨‍💻 Autor

**Jaime Araya** - **Rodrigo Sanhueza** - **Sergio Simi**
- 🏫 Universidad Andrés Bello
- 📧 [Contacto](mailto:j.arayaaros@uandresbello.edu)
- 💼 [GitHub](https://github.com/jarayaa)

---

## 📅 Historial de Versiones

### v1.0.0 (Actual) - Noviembre 2025
```
✅ Protección contra pérdida de datos
✅ Guardar sin calcular promedio
✅ Actualización automática de estadísticas
✅ Diseño 100% responsivo
✅ Fix bug loop con 1 nota
✅ Validaciones exhaustivas
✅ Correcciones de deprecación Flutter
```

### v1.0.0 - Noviembre 2025
```
✅ Calculadora básica de notas
✅ Navegación por trimestres
✅ Persistencia con SharedPreferences
✅ Tema oscuro macOS
✅ Validación en tiempo real
```

---

## 🔗 Enlaces Útiles

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design 3](https://m3.material.io/)
- [SharedPreferences Package](https://pub.dev/packages/shared_preferences)

---

## ❓ Preguntas Frecuentes

### ¿Puedo usar esto en otra universidad?
```
Sí, solo necesitas:
1. Modificar malla_curricular_data.dart
2. Ajustar rangos de notas si es necesario
3. Actualizar información de la universidad
```

### ¿Funciona offline?
```
✅ Sí, completamente offline
✅ Usa almacenamiento local
✅ No requiere internet
```

### ¿Puedo exportar mis notas?
```
⚠️ Actualmente no implementado
📌 Funcionalidad sugerida para v3.0
💡 Se puede agregar como contribución
```

### ¿Es compatible con iOS?
```
✅ Sí, Flutter es multiplataforma
✅ Probado en simulador iOS
✅ Requiere Xcode para compilar
```

---

## 🎯 Roadmap

### Corto Plazo (v2.1):
```
🔄 Sincronización entre dispositivos
📊 Exportar a PDF
🎨 Temas personalizables
```

### Mediano Plazo (v3.0):
```
📈 Gráficos de rendimiento
📅 Calendario de evaluaciones
🔔 Sistema de recordatorios
```

### Largo Plazo (v4.0):
```
☁️ Backend con Firebase
👥 Compartir con amigos
🤖 Recomendaciones con IA
```

---

**¿Preguntas o sugerencias?** Abre un [Issue en GitHub](https://github.com/jarayaa/gestion-academica/issues)

---

**⭐ Si te sirvió este proyecto, dale una estrella en GitHub!** ⭐