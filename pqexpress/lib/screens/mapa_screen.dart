// ============================================================
// PQEXPRESS - Pantalla de Mapa con Ruta
// Muestra mapa interactivo con ruta calculada por OSRM
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/envio.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../config/theme.dart';

class MapaScreen extends StatefulWidget {
  final Envio envio;

  const MapaScreen({
    super.key,
    required this.envio,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();

  LatLng? _ubicacionActual;
  List<LatLng> _puntosRuta = [];
  RutaResultado? _infoRuta;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Obtener ubicación actual
      final posicion = await _locationService.obtenerUbicacionActual();
      
      if (posicion != null) {
        _ubicacionActual = LatLng(posicion.latitud, posicion.longitud);
        
        // Calcular ruta si hay coordenadas de destino
        if (widget.envio.tieneCoordenadas) {
          final destino = LatLng(
            widget.envio.latDestino!,
            widget.envio.lngDestino!,
          );
          
          final resultado = await _routeService.obtenerRuta(_ubicacionActual!, destino);
          _puntosRuta = resultado.puntos;
          _infoRuta = resultado;
        }
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  void _centrarEnMiUbicacion() {
    if (_ubicacionActual != null) {
      _mapController.move(_ubicacionActual!, 15);
    }
  }

  void _centrarEnDestino() {
    if (widget.envio.tieneCoordenadas) {
      final destino = LatLng(
        widget.envio.latDestino!,
        widget.envio.lngDestino!,
      );
      _mapController.move(destino, 15);
    }
  }

  void _verRutaCompleta() {
    if (_ubicacionActual != null && widget.envio.tieneCoordenadas) {
      final destino = LatLng(
        widget.envio.latDestino!,
        widget.envio.lngDestino!,
      );
      
      // Calcular bounds para ver ambos puntos
      final bounds = LatLngBounds(_ubicacionActual!, destino);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  Future<void> _abrirEnGoogleMaps() async {
    if (!widget.envio.tieneCoordenadas) return;

    final lat = widget.envio.latDestino!;
    final lng = widget.envio.lngDestino!;
    
    // URL para navegación en Google Maps
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir Google Maps'),
            backgroundColor: ColoresApp.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.near_me_rounded, size: 22),
            const SizedBox(width: 10),
            const Text('Navegación'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Abrir en Google Maps',
              onPressed: _abrirEnGoogleMaps,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Actualizar',
              onPressed: _inicializar,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          _buildMapa(),

          // Info de la ruta
          if (_infoRuta != null) _buildInfoRuta(),

          // Botones flotantes
          _buildBotonesFlotantes(),

          // Indicador de carga
          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    // Centro inicial del mapa
    LatLng centroInicial;
    if (_ubicacionActual != null) {
      centroInicial = _ubicacionActual!;
    } else if (widget.envio.tieneCoordenadas) {
      centroInicial = LatLng(widget.envio.latDestino!, widget.envio.lngDestino!);
    } else {
      // Ciudad de México como fallback
      centroInicial = const LatLng(19.4326, -99.1332);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centroInicial,
        initialZoom: 13,
        maxZoom: 18,
        minZoom: 5,
      ),
      children: [
        // Capa de tiles (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pqexpress.app',
        ),

        // Línea de la ruta
        if (_puntosRuta.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _puntosRuta,
                strokeWidth: 5,
                color: ColoresApp.primario,
              ),
            ],
          ),

        // Marcadores
        MarkerLayer(
          markers: [
            // Marcador de ubicación actual
            if (_ubicacionActual != null)
              Marker(
                point: _ubicacionActual!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: ColoresApp.primario,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

            // Marcador de destino
            if (widget.envio.tieneCoordenadas)
              Marker(
                point: LatLng(widget.envio.latDestino!, widget.envio.lngDestino!),
                width: 50,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColoresApp.secundario,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRuta() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColoresApp.primario.withAlpha(25),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destino
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColoresApp.secundario.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.pin_drop_rounded, color: ColoresApp.secundario, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destino de entrega',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColoresApp.textoMedio,
                        ),
                      ),
                      Text(
                        widget.envio.direccionFormateada,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
            const SizedBox(height: 14),
            Divider(color: ColoresApp.textoClaro.withAlpha(60)),
            const SizedBox(height: 12),
            // Distancia y tiempo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.route_rounded,
                  _infoRuta!.distanciaFormateada,
                  'Distancia',
                  ColoresApp.primario,
                ),
                Container(
                  width: 1,
                  height: 45,
                  color: ColoresApp.textoClaro.withAlpha(60),
                ),
                _buildInfoItem(
                  Icons.schedule_rounded,
                  _infoRuta!.duracionFormateada,
                  'Tiempo estimado',
                  ColoresApp.secundario,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icono, String valor, String etiqueta, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 11,
            color: ColoresApp.textoMedio,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesFlotantes() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ver ruta completa
          _buildBotonFlotante(
            heroTag: 'ruta',
            icono: Icons.fullscreen_rounded,
            color: Colors.white,
            colorIcono: ColoresApp.textoOscuro,
            onPressed: _verRutaCompleta,
          ),
          const SizedBox(height: 10),
          // Centrar en destino
          _buildBotonFlotante(
            heroTag: 'destino',
            icono: Icons.outlined_flag_rounded,
            color: ColoresApp.secundario,
            colorIcono: Colors.white,
            onPressed: _centrarEnDestino,
          ),
          const SizedBox(height: 10),
          // Centrar en mi ubicación
          _buildBotonFlotante(
            heroTag: 'ubicacion',
            icono: Icons.my_location_rounded,
            color: ColoresApp.primario,
            colorIcono: Colors.white,
            onPressed: _centrarEnMiUbicacion,
            grande: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFlotante({
    required String heroTag,
    required IconData icono,
    required Color color,
    required Color colorIcono,
    required VoidCallback onPressed,
    bool grande = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        mini: !grande,
        backgroundColor: color,
        elevation: 0,
        onPressed: onPressed,
        child: Icon(icono, color: colorIcono, size: grande ? 26 : 22),
      ),
    );
  }
}
