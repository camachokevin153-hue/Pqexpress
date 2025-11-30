// ============================================================
// PQEXPRESS - Aplicación de Gestión de Entregas
// Punto de entrada principal de la aplicación Flutter
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/envios_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación preferida (solo portrait)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PQExpressApp());
}

class PQExpressApp extends StatelessWidget {
  const PQExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider de autenticación
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Provider de envíos
        ChangeNotifierProvider(
          create: (_) => EnviosProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'PQExpress',
        debugShowCheckedModeBanner: false,
        
        // Tema personalizado
        theme: TemaApp.temaClaro,
        
        // Pantalla inicial
        home: const SplashScreen(),
      ),
    );
  }
}
