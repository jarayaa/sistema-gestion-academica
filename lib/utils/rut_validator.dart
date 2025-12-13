import 'package:flutter/services.dart';

class RutValidator {
  // Formatea el RUT añadiendo puntos y guión (XX.XXX.XXX-Y)
  static String formatear(String rut) {
    if (rut.isEmpty) return "";
    rut = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (rut.length < 2) return rut;
    
    String dv = rut.substring(rut.length - 1);
    String cuerpo = rut.substring(0, rut.length - 1);
    
    // Añadir puntos
    String cuerpoFormateado = "";
    int contador = 0;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      cuerpoFormateado = cuerpo[i] + cuerpoFormateado;
      contador++;
      if (contador == 3 && i != 0) {
        cuerpoFormateado = ".$cuerpoFormateado";
        contador = 0;
      }
    }
    
    return "$cuerpoFormateado-$dv";
  }

  // Valida el RUT usando Módulo 11
  static bool esValido(String rut) {
    if (rut.isEmpty) return false;
    
    // Limpiar el RUT
    String limpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    
    if (limpio.length < 2) return false;
    
    String cuerpo = limpio.substring(0, limpio.length - 1);
    String dv = limpio.substring(limpio.length - 1);
    
    // Validar que el cuerpo sea numérico
    if (!RegExp(r'^[0-9]+$').hasMatch(cuerpo)) return false;
    
    int suma = 0;
    int multiplicador = 2;
    
    // Algoritmo Módulo 11 (inverso)
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
}

// Formatter para el TextField
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = RutValidator.formatear(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}