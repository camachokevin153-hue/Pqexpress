// ============================================================
// PQEXPRESS - Pantalla de Detalle de Envío
// Muestra información completa y acciones disponibles
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/envio.dart';
import '../providers/auth_provider.dart';
import '../providers/envios_provider.dart';
import '../config/theme.dart';
import 'mapa_screen.dart';
import 'entrega_screen.dart';

class EnvioDetalleScreen extends StatefulWidget {
  final Envio envio;

  const EnvioDetalleScreen({
    super.key,
    required this.envio,
  });

  @override
  State<EnvioDetalleScreen> createState() => _EnvioDetalleScreenState();
}

class _EnvioDetalleScreenState extends State<EnvioDetalleScreen> {
  late Envio _envio;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _envio = widget.envio;
  }

  Future<void> _iniciarRuta() async {
    setState(() => _procesando = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enviosProvider = Provider.of<EnviosProvider>(context, listen: false);
    
    enviosProvider.setApiService(authProvider.apiService);

    final exito = await enviosProvider.iniciarRuta(_envio.idEnvio);

    setState(() => _procesando = false);

    if (exito && mounted) {
      // Actualizar el envío local
      setState(() {
        _envio = enviosProvider.envioSeleccionado ?? _envio;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta iniciada correctamente'),
          backgroundColor: ColoresApp.exito,
        ),
      );

      // Navegar al mapa
      _verMapa();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enviosProvider.errorMensaje ?? 'Error al iniciar ruta'),
          backgroundColor: ColoresApp.error,
        ),
      );
    }
  }

  void _verMapa() {
    if (!_envio.tieneCoordenadas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este envío no tiene coordenadas GPS'),
          backgroundColor: ColoresApp.advertencia,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaScreen(envio: _envio),
      ),
    );
  }

  void _registrarEntrega() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntregaScreen(envio: _envio),
      ),
    ).then((resultado) {
      if (resultado == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = ColoresApp.colorPorEstado(_envio.estatusEnvio.valor);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.confirmation_number_rounded, size: 22),
            const SizedBox(width: 10),
            Text(_envio.numeroGuia),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado con estado
            _buildEncabezado(colorEstado),

            // Información del destinatario
            _buildSeccion(
              titulo: 'Destinatario',
              icono: Icons.account_circle_rounded,
              children: [
                _buildInfoRow('Nombre', _envio.receptorNombre),
                if (_envio.receptorTelefono != null)
                  _buildInfoRow('Teléfono', _envio.receptorTelefono!),
              ],
            ),

            // Dirección
            _buildSeccion(
              titulo: 'Dirección de Entrega',
              icono: Icons.pin_drop_rounded,
              children: [
                _buildInfoRow('Calle', _envio.calle),
                if (_envio.numeroExterior != null)
                  _buildInfoRow('Número', _envio.numeroExterior!),
                if (_envio.colonia != null)
                  _buildInfoRow('Colonia', _envio.colonia!),
                if (_envio.municipioCiudad != null)
                  _buildInfoRow('Ciudad', _envio.municipioCiudad!),
                if (_envio.codigoPostal != null)
                  _buildInfoRow('CP', _envio.codigoPostal!),
                if (_envio.referenciasAdicionales != null)
                  _buildInfoRow('Referencias', _envio.referenciasAdicionales!),
              ],
            ),

            // Coordenadas GPS
            if (_envio.tieneCoordenadas)
              _buildSeccion(
                titulo: 'Ubicación GPS',
                icono: Icons.satellite_alt_rounded,
                children: [
                  _buildInfoRow('Latitud', _envio.latDestino!.toStringAsFixed(6)),
                  _buildInfoRow('Longitud', _envio.lngDestino!.toStringAsFixed(6)),
                ],
              ),

            // Fechas
            _buildSeccion(
              titulo: 'Información del Envío',
              icono: Icons.analytics_rounded,
              children: [
                if (_envio.fechaAsignacion != null)
                  _buildInfoRow('Asignado', _formatearFecha(_envio.fechaAsignacion!)),
                if (_envio.fechaCompletado != null)
                  _buildInfoRow('Completado', _formatearFecha(_envio.fechaCompletado!)),
                if (_envio.observaciones != null)
                  _buildInfoRow('Notas', _envio.observaciones!),
              ],
            ),

            const SizedBox(height: 24),

            // Botones de acción
            _buildBotonesAccion(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado(Color colorEstado) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorEstado.withAlpha(200),
            colorEstado,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorEstado.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconoEstado(),
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _envio.estatusEnvio.etiqueta.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded, size: 18, color: Colors.white.withAlpha(200)),
                const SizedBox(width: 8),
                Text(
                  _envio.numeroGuia,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconoEstado() {
    switch (_envio.estatusEnvio) {
      case EstatusEnvio.asignado:
        return Icons.schedule_rounded;
      case EstatusEnvio.enCamino:
        return Icons.rocket_launch_rounded;
      case EstatusEnvio.completado:
        return Icons.verified_rounded;
      case EstatusEnvio.fallido:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icono, color: ColoresApp.primario),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.textoOscuro,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: ColoresApp.textoMedio,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: ColoresApp.textoOscuro,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Si está pendiente, mostrar botón de iniciar ruta
          if (_envio.estaPendiente) ...[
            _buildBotonAccion(
              onPressed: _procesando ? null : _iniciarRuta,
              icono: _procesando
                  ? null
                  : Icons.play_circle_filled_rounded,
              texto: _procesando ? 'Procesando...' : 'COMENZAR RUTA',
              color: ColoresApp.exito,
              cargando: _procesando,
            ),
            const SizedBox(height: 14),
          ],

          // Si está en camino, mostrar botón de ver mapa
          if (_envio.estaEnCamino || _envio.tieneCoordenadas) ...[
            _buildBotonAccion(
              onPressed: _verMapa,
              icono: Icons.near_me_rounded,
              texto: 'NAVEGAR AL DESTINO',
              color: ColoresApp.primario,
            ),
            const SizedBox(height: 14),
          ],

          // Si está en camino, mostrar botón de registrar entrega
          if (_envio.estaEnCamino) ...[
            _buildBotonAccion(
              onPressed: _registrarEntrega,
              icono: Icons.photo_camera_rounded,
              texto: 'CONFIRMAR ENTREGA',
              color: ColoresApp.secundario,
            ),
          ],

          // Si está completado, mostrar info
          if (_envio.estaCompletado) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColoresApp.exito.withAlpha(20),
                    ColoresApp.exito.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColoresApp.exito.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.exito.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded, color: ColoresApp.exito, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Entrega Exitosa!',
                          style: TextStyle(
                            color: ColoresApp.exito,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Este envío fue completado correctamente',
                          style: TextStyle(
                            color: ColoresApp.exito.withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required VoidCallback? onPressed,
    required IconData? icono,
    required String texto,
    required Color color,
    bool cargando = false,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else if (icono != null)
              Icon(icono, size: 24),
            const SizedBox(width: 12),
            Text(
              texto,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
