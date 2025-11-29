
# 📚 Sistema de Gestión Académica

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.18+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/License-Academic-green?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge)

**Aplicación móvil Flutter para gestión de notas y seguimiento académico**

*APTC106 - Taller de Desarrollo Web y Móvil | Grupo 3*

</div>

---
## Video del Funcionamiento de la Aplicación

<div align="center">

[![Ver video en YouTube](https://img.youtube.com/vi/BQNvytTCMLg/maxresdefault.jpg)](https://www.youtube.com/watch?v=BQNvytTCMLg)

</div>

## 📖 Descripción

Sistema de Gestión Académica es una aplicación móvil desarrollada en Flutter que permite a los estudiantes de la carrera de Ingeniería Civil Informática Advance de la Universidad Andrés Bello gestionar sus notas de manera eficiente y profesional.

La aplicación está específicamente diseñada para el sistema académico chileno, implementando:

- 🎯 Escala de notas 1.0 a 7.0 con formato chileno (coma decimal)
- 📊 Cálculo de promedios ponderados basado en porcentajes
- 📚 Malla curricular completa con 43 asignaturas distribuidas en 10 trimestres
- ✅ Validaciones exhaustivas que previenen errores de ingreso
- 💾 Persistencia local para acceder a tus datos sin conexión

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
- ✅ Splash Screen con animaciones
- ✅ Tema oscuro macOS-style
- ✅ 100% responsivo (smartphones, tablets, plegables)
- ✅ Material Design 3

### 💾 Persistencia
- ✅ Almacenamiento local con SharedPreferences
- ✅ Recuperación automática de datos
- ✅ Sincronización inmediata

---

## 📱 Mockups de la Aplicación

<div align="center">

[![Mockups Interactivos](/mockups/sitio_mockups.png)](https://jarayaa.github.io/sistema-gestion-academica/mockups_interactivos.html)

</div>

### Flujo de Navegación

<div align="center">

![Flujo de Nevagación](flujo_navegacion.svg)

</div>

### 1️⃣ Splash Screen

<div align="center">
    <img src="https://github.com/jarayaa/sistema-gestion-academica/blob/main/mockups/01_splash_screen.png" 
         alt="Splash Screen" 
         style="width: 30%;">
</div>

**Características:**
- Logo con gradiente violeta-rojo
- Barra de progreso animada
- Versión dinámica desde pubspec.yaml
- Transición automática a Home

### 2️⃣ Vista Principal (Home)

<div align="center">
    <img src="https://github.com/jarayaa/sistema-gestion-academica/blob/main/mockups/02_vista_principal.png" 
         alt="Vista Principal" 
         style="width: 30%;">
</div>

**Características:**
- Grid 2x5 de trimestres
- Estadísticas en tiempo real
- Contadores de progreso
- Navegación intuitiva

### 3️⃣ Vista de Asignaturas

<div align="center">
    <img src="https://github.com/jarayaa/sistema-gestion-academica/blob/main/mockups/03_vista_asignaturas.png" 
         alt="Vista Asignaturas" 
         style="width: 30%;">
</div>

**Características:**
- Cards con información completa
- Badges de color por estado
- Promedio visible
- Navegación a calculadora

### 4️⃣ Vista Notas y Ponderaciones

<div align="center">
    <img src="https://github.com/jarayaa/sistema-gestion-academica/blob/main/mockups/04_vista_notas.png" 
         alt="Vista Notas y Ponderaciones" 
         style="width: 30%;">
</div>

**Características:**
- Selector dinámico (2-10 notas)
- Validación en tiempo real
- Dos modos de guardado
- Formato chileno

### 5️⃣ Vista de Resultado Aprobado (Promedio >= 5,5)

<div align="center">
    <img src="https://github.com/jarayaa/sistema-gestion-academica/blob/main/mockups/05_vista_resultado_aprobado.png" 
         alt="Vista Resultado Aprobado" 
         style="width: 30%;">
</div>

**Características:**
- Promedio destacado
- Estado claro (Aprobado/Reprobado)
- Confirmación de guardado
- Navegación de retorno

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
git clone https://github.com/jarayaa/sistema-gestion-academica.git
cd sistema-gestion-academica
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la aplicación**
```bash
flutter run
```

---

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.5.3    # Persistencia local
  package_info_plus: ^9.0.0     # Info de la app (versión)
  cupertino_icons: ^1.0.2       # Iconos iOS
```

---

## 🏗️ Arquitectura

La aplicación sigue el patrón **MVC** (Modelo-Vista-Controlador):

<div align="center">

![Diagrama de Arquitectura](diagrama_arquitectura.svg)

</div>

---

## 🎓 Malla Curricular Incluida

| Trimestre | Asignaturas | Créditos Totales |
|:---------:|:-----------:|:----------------:|
|     1     |      3      |        36        |
|     2     |      4      |        44        |
|     3     |      4      |        40        |
|     4     |      4      |        40        |
|     5     |      4      |        38        |
|     6     |      4      |        39        |
|     7     |      4      |        42        |
|     8     |      4      |        36        |
|     9     |      4      |        40        |
|     10    |      4      |        43        |
| **Total** |    **43**   |      **398**     |

---

## 🧪 Validaciones Implementadas

### Notas
- ✅ Rango: 1.0 - 7.0
- ✅ Formato: Acepta coma y punto decimal
- ✅ Feedback visual inmediato (borde rojo si inválido)

### Porcentajes
- ✅ Rango: 0% - 100%
- ✅ Suma: Debe ser exactamente 100% para calcular
- ✅ Guardado parcial sin completar 100%

### Protección de Datos
- ✅ Advertencia al reducir cantidad de notas
- ✅ Confirmación antes de acciones destructivas
- ✅ Guardado automático tras cálculo

---

## 📊 Formato de Datos

### Estructura JSON (Guardado Completo)
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

### Estructura JSON (Guardado Parcial)
```json
{
  "codigoAsignatura": "ATDF101",
  "notas": [
    {"nota": 6.5, "porcentaje": 30.0}
  ],
  "promedioFinal": null
}
```

---

## 🔧 Configuración

### Cambiar Nota de Aprobación
```dart
static const double _notaAprobacion = 5.5; // Modificar aquí
```

### Cambiar Cantidad de Notas
```dart
static const int _minNotas = 2;
static const int _maxNotas = 10;
```

---

## 👨‍💻 Autores - Grupo 3

|         Nombre       |              Rol              |
|----------------------|-------------------------------|
| **Jaime Araya**      | Desarrollo Frontend & Backend |
| **Rodrigo Sanhueza** | Diseño UI/UX & Testing        |
| **Sergio Simi**      | Documentación & QA            |

---

## 📅 Historial de Versiones

### v1.0.0 - 29 Noviembre 2025
- ✅ Splash Screen animado
- ✅ Calculadora de notas completa
- ✅ Validaciones en tiempo real
- ✅ Persistencia local
- ✅ Tema oscuro profesional
- ✅ Diseño 100% responsivo
- ✅ Guardar sin calcular

---

## 🔗 Enlaces

- 📁 **Repositorio**: [github.com/jarayaa/sistema-gestion-academica](https://github.com/jarayaa/sistema-gestion-academica)
- 📱 **Video de la Aplicación**: [www.youtube.com](https://youtu.be/BQNvytTCMLg)
- 📖 **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev/)
- 🎨 **Material Design 3**: [m3.material.io](https://m3.material.io/)

---

## 📜 Licencia

Este proyecto es de uso académico para estudiantes de la Universidad Andrés Bello.

---

<div align="center">

**APTC106 - Taller de Desarrollo Web y Móvil**

Universidad Andrés Bello | Noviembre 2025

⭐ Si te sirvió este proyecto, dale una estrella en GitHub ⭐

</div>
