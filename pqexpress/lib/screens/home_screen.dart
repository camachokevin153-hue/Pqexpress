// ============================================================
// PQEXPRESS - Pantalla Principal (Home)
// Lista de envíos con tabs: En Entrega y Pendientes
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/envios_provider.dart';
import '../models/envio.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import 'envio_detalle_screen.dart';
import 'historial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Cargar envíos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enviosProvider = Provider.of<EnviosProvider>(context, listen: false);
    
    enviosProvider.setApiService(authProvider.apiService);
    enviosProvider.cargarEnvios();
  }

  Future<void> _refrescar() async {
    final enviosProvider = Provider.of<EnviosProvider>(context, listen: false);
    await enviosProvider.refrescar();
  }

  void _cerrarSesion() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final enviosProvider = Provider.of<EnviosProvider>(context, listen: false);
      
      await authProvider.logout();
      enviosProvider.limpiar();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_rounded, size: 26),
            const SizedBox(width: 8),
            const Text('PQExpress'),
          ],
        ),
        actions: [
          // Botón de historial
          IconButton(
            icon: const Icon(Icons.auto_stories_rounded),
            tooltip: 'Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialScreen()),
              );
            },
          ),
          // Botón de logout
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ColoresApp.secundario,
          indicatorWeight: 4,
          tabs: const [
            Tab(
              icon: Icon(Icons.bolt_rounded),
              text: 'EN RUTA',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_rounded),
              text: 'POR ENTREGAR',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Información del usuario
          _buildInfoUsuario(),
          
          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaEnvios(esEnRuta: true),
                _buildListaEnvios(esEnRuta: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoUsuario() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final usuario = authProvider.usuario;
        if (usuario == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColoresApp.primario.withAlpha(30),
                ColoresApp.secundario.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColoresApp.primario.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              // Avatar con gradiente
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: ColoresApp.gradientePrincipal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColoresApp.primario.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    usuario.iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Qué tal, ${usuario.primerNombre}! 👋',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.textoOscuro,
                      ),
                    ),
                    Consumer<EnviosProvider>(
                      builder: (context, enviosProvider, _) {
                        return Text(
                          '${enviosProvider.totalActivos} envíos activos',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ColoresApp.textoMedio,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Botón refrescar
              IconButton(
                icon: const Icon(Icons.refresh),
                color: ColoresApp.primario,
                onPressed: _refrescar,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaEnvios({required bool esEnRuta}) {
    return Consumer<EnviosProvider>(
      builder: (context, enviosProvider, _) {
        if (enviosProvider.estaCargando) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final envios = esEnRuta 
            ? enviosProvider.enviosEnRuta 
            : enviosProvider.enviosPendientes;

        if (envios.isEmpty) {
          return _buildEstadoVacio(esEnRuta);
        }

        return RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: envios.length,
            itemBuilder: (context, index) {
              return _buildTarjetaEnvio(envios[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEstadoVacio(bool esEnRuta) {
    return RefreshIndicator(
      onRefresh: _refrescar,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ColoresApp.primario.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esEnRuta ? Icons.electric_bolt_rounded : Icons.inventory_2_outlined,
                      size: 60,
                      color: ColoresApp.primario.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    esEnRuta 
                        ? '¡Todo tranquilo por aquí! 🌟'
                        : '¡Sin paquetes pendientes! 📦',
                    style: const TextStyle(
                      fontSize: 18,
                      color: ColoresApp.textoOscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desliza hacia abajo para actualizar',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColoresApp.textoMedio,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEnvio(Envio envio) {
    final colorEstado = ColoresApp.colorPorEstado(envio.estatusEnvio.valor);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            colorEstado.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorEstado.withAlpha(30),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EnvioDetalleScreen(envio: envio),
              ),
            ).then((_) => _refrescar());
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con gradiente
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorEstado.withAlpha(25),
                        colorEstado.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Número de guía con icono diferente
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColoresApp.primario.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.confirmation_number_rounded,
                              size: 18,
                              color: ColoresApp.primario,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'N° GUÍA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ColoresApp.textoMedio,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                envio.numeroGuia,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ColoresApp.textoOscuro,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Estado con icono
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorEstado.withAlpha(40),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: colorEstado.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              envio.estaEnCamino ? Icons.local_shipping_rounded : Icons.pending_rounded,
                              size: 14,
                              color: colorEstado,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              envio.estatusEnvio.etiqueta,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorEstado,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 18),
              
                // Destinatario
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColoresApp.secundario.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_circle_rounded, size: 20, color: ColoresApp.secundario),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinatario',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColoresApp.textoMedio,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            envio.receptorNombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ColoresApp.textoOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Dirección
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColoresApp.primario.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pin_drop_rounded, size: 20, color: ColoresApp.primario),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación de entrega',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColoresApp.textoMedio,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            envio.direccionFormateada,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ColoresApp.textoOscuro,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnvioDetalleScreen(envio: envio),
                        ),
                      ).then((_) => _refrescar());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: envio.estaEnCamino 
                          ? ColoresApp.secundario 
                          : ColoresApp.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          envio.estaEnCamino ? Icons.near_me_rounded : Icons.play_circle_filled_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          envio.estaEnCamino ? 'NAVEGAR RUTA' : 'COMENZAR ENVÍO',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
