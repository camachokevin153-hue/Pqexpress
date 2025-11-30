// ============================================================
// PQEXPRESS - Tema y Estilos de la Aplicación
// Diseño Moderno con Gradientes y Estilo Único
// ============================================================

import 'package:flutter/material.dart';

/// Clase que contiene todos los colores de la aplicación
class ColoresApp {
  // Colores principales - Púrpura Moderno
  static const Color primario = Color(0xFF6C63FF);        // Púrpura vibrante
  static const Color primarioOscuro = Color(0xFF5A52D5);  // Púrpura oscuro
  static const Color primarioClaro = Color(0xFF9D97FF);   // Púrpura claro
  
  // Colores secundarios - Verde Esmeralda
  static const Color secundario = Color(0xFF00D9A5);      // Verde esmeralda
  static const Color secundarioOscuro = Color(0xFF00B389);
  static const Color secundarioClaro = Color(0xFF5EFFD5);
  
  // Color de acento - Ámbar/Dorado
  static const Color acento = Color(0xFFFFC107);          // Amarillo dorado
  
  // Colores de estado
  static const Color exito = Color(0xFF00C853);           // Verde brillante
  static const Color error = Color(0xFFFF5252);           // Rojo coral
  static const Color advertencia = Color(0xFFFFAB00);     // Ámbar
  static const Color info = Color(0xFF448AFF);            // Azul brillante
  
  // Colores de fondo
  static const Color fondo = Color(0xFFF8F9FE);           // Blanco azulado
  static const Color fondoTarjeta = Colors.white;
  static const Color fondoOscuro = Color(0xFF1E1E2E);     // Oscuro elegante
  
  // Colores de texto
  static const Color textoOscuro = Color(0xFF2D3142);
  static const Color textoMedio = Color(0xFF9094A6);
  static const Color textoClaro = Color(0xFFD1D5E4);
  static const Color textoBlanco = Colors.white;
  
  // Colores de estados de envío - Más vibrantes
  static const Color estadoAsignado = Color(0xFF78909C);   // Gris azulado
  static const Color estadoEnCamino = Color(0xFFFF9100);   // Naranja intenso
  static const Color estadoCompletado = Color(0xFF00E676); // Verde neón
  static const Color estadoFallido = Color(0xFFFF5252);    // Rojo coral
  
  /// Obtiene el color según el estado del envío
  static Color colorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'asignado':
        return estadoAsignado;
      case 'en_camino':
        return estadoEnCamino;
      case 'completado':
        return estadoCompletado;
      case 'fallido':
        return estadoFallido;
      default:
        return estadoAsignado;
    }
  }
  
  // Gradientes
  static const LinearGradient gradientePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
  );
  
  static const LinearGradient gradienteSecundario = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D9A5), Color(0xFF00B4DB)],
  );
}

/// Clase que contiene la configuración del tema
class TemaApp {
  /// Tema claro de la aplicación
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      
      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColoresApp.primario,
        brightness: Brightness.light,
        primary: ColoresApp.primario,
        secondary: ColoresApp.secundario,
        error: ColoresApp.error,
        surface: ColoresApp.fondoTarjeta,
      ),
      
      // Color de fondo del Scaffold
      scaffoldBackgroundColor: ColoresApp.fondo,
      
      // AppBar - Estilo moderno sin elevación
      appBarTheme: const AppBarTheme(
        backgroundColor: ColoresApp.primario,
        foregroundColor: ColoresApp.textoBlanco,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColoresApp.textoBlanco,
          letterSpacing: 0.5,
        ),
      ),
      
      // Botones elevados - Más redondeados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.textoBlanco,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 4,
          shadowColor: ColoresApp.primario.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.primario,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Botones con borde - Estilo pill
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.primario,
          side: const BorderSide(color: ColoresApp.primario, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      // Campos de texto - Más suaves
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ColoresApp.textoClaro.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColoresApp.primario, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColoresApp.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIconColor: ColoresApp.textoMedio,
      ),
      
      // Tarjetas - Más redondeadas con sombra suave
      cardTheme: CardThemeData(
        color: ColoresApp.fondoTarjeta,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // FloatingActionButton - Con gradiente visual
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColoresApp.secundario,
        foregroundColor: ColoresApp.textoBlanco,
        elevation: 8,
        shape: CircleBorder(),
      ),
      
      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: ColoresApp.primario,
        unselectedItemColor: ColoresApp.textoMedio,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: ColoresApp.textoBlanco,
        unselectedLabelColor: Colors.white70,
        indicatorColor: ColoresApp.secundario,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: ColoresApp.textoClaro.withAlpha(77),
        thickness: 1,
      ),
      
      // Iconos
      iconTheme: const IconThemeData(
        color: ColoresApp.primario,
      ),
    );
  }
}

/// Estilos de texto personalizados
class EstilosTexto {
  static const TextStyle titulo = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: ColoresApp.textoOscuro,
    letterSpacing: -0.5,
  );
  
  static const TextStyle subtitulo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColoresApp.textoOscuro,
  );
  
  static const TextStyle cuerpo = TextStyle(
    fontSize: 15,
    color: ColoresApp.textoOscuro,
    height: 1.5,
  );
  
  static const TextStyle cuerpoSecundario = TextStyle(
    fontSize: 14,
    color: ColoresApp.textoMedio,
    height: 1.4,
  );
  
  static const TextStyle etiqueta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColoresApp.textoMedio,
    letterSpacing: 0.5,
  );
  
  static const TextStyle boton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ColoresApp.textoBlanco,
    letterSpacing: 0.5,
  );
}

/// Decoraciones y bordes personalizados
class DecoracionesApp {
  static BoxDecoration get tarjetaConSombra => BoxDecoration(
    color: ColoresApp.fondoTarjeta,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: ColoresApp.primario.withAlpha(25),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration get gradientePrimario => const BoxDecoration(
    gradient: ColoresApp.gradientePrincipal,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  
  static BoxDecoration get gradienteSecundario => const BoxDecoration(
    gradient: ColoresApp.gradienteSecundario,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  
  static BoxDecoration get contenedorSuave => BoxDecoration(
    color: ColoresApp.primario.withAlpha(25),
    borderRadius: BorderRadius.circular(16),
  );
}
