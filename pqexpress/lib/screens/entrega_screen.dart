// ============================================================
// PQEXPRESS - Pantalla de Registro de Entrega
// Captura foto, ubicación GPS y firma de confirmación
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/envio.dart';
import '../providers/auth_provider.dart';
import '../providers/envios_provider.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../config/theme.dart';

class EntregaScreen extends StatefulWidget {
  final Envio envio;

  const EntregaScreen({
    super.key,
    required this.envio,
  });

  @override
  State<EntregaScreen> createState() => _EntregaScreenState();
}

class _EntregaScreenState extends State<EntregaScreen> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _receptorNombreController = TextEditingController();
  final _observacionesController = TextEditingController();

  FotoResultado? _fotoResultado;
  double? _latitudEntrega;
  double? _longitudEntrega;
  bool _obteniendoUbicacion = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _receptorNombreController.text = widget.envio.receptorNombre;
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _receptorNombreController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoUbicacion = true);

    final posicion = await _locationService.obtenerUbicacionActual();

    if (posicion != null && mounted) {
      setState(() {
        _latitudEntrega = posicion.latitud;
        _longitudEntrega = posicion.longitud;
        _obteniendoUbicacion = false;
      });
    } else if (mounted) {
      setState(() => _obteniendoUbicacion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación GPS'),
          backgroundColor: ColoresApp.advertencia,
        ),
      );
    }
  }

  Future<void> _tomarFoto() async {
    final foto = await _cameraService.tomarFoto();
    if (foto != null && mounted) {
      setState(() => _fotoResultado = foto);
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    final foto = await _cameraService.seleccionarDeGaleria();
    if (foto != null && mounted) {
      setState(() => _fotoResultado = foto);
    }
  }

  void _eliminarFoto() {
    setState(() => _fotoResultado = null);
  }

  Future<void> _confirmarEntrega() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoResultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tomar una foto de evidencia'),
          backgroundColor: ColoresApp.error,
        ),
      );
      return;
    }

    if (_latitudEntrega == null || _longitudEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes obtener la ubicación GPS'),
          backgroundColor: ColoresApp.error,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enviosProvider = Provider.of<EnviosProvider>(context, listen: false);
    
    enviosProvider.setApiService(authProvider.apiService);

    final exito = await enviosProvider.confirmarEntregaConDatos(
      widget.envio.idEnvio,
      _receptorNombreController.text.trim(),
      _latitudEntrega!,
      _longitudEntrega!,
      _fotoResultado!.base64,
      _observacionesController.text.trim().isEmpty 
          ? null 
          : _observacionesController.text.trim(),
    );

    setState(() => _enviando = false);

    if (exito && mounted) {
      // Mostrar diálogo de éxito
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColoresApp.exito.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: ColoresApp.exito,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Entrega Registrada!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El envío ${widget.envio.numeroGuia} ha sido marcado como entregado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColoresApp.textoMedio,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ACEPTAR'),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enviosProvider.errorMensaje ?? 'Error al registrar entrega'),
          backgroundColor: ColoresApp.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, size: 22),
            const SizedBox(width: 10),
            const Text('Confirmar Entrega'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info del envío
                _buildInfoEnvio(),

                const SizedBox(height: 24),

                // Sección de foto
                _buildSeccionFoto(),

                const SizedBox(height: 24),

                // Sección de ubicación
                _buildSeccionUbicacion(),

                const SizedBox(height: 24),

                // Formulario
                _buildFormulario(),

                const SizedBox(height: 32),

                // Botón de confirmar
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: ColoresApp.exito.withAlpha(60),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _confirmarEntrega,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.exito,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_enviando)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          const Icon(Icons.verified_rounded, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _enviando ? 'Procesando...' : 'FINALIZAR ENTREGA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoEnvio() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresApp.primario.withAlpha(15),
            ColoresApp.primario.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.primario.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColoresApp.primario.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.confirmation_number_rounded, color: ColoresApp.primario, size: 24),
              ),
              const SizedBox(width: 14),
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
                    widget.envio.numeroGuia,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.textoOscuro,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: ColoresApp.primario.withAlpha(30)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.account_circle_rounded, color: ColoresApp.secundario, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.envio.receptorNombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.pin_drop_rounded, color: ColoresApp.primario.withAlpha(180), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.envio.direccionFormateada,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColoresApp.textoMedio,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColoresApp.secundario.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.photo_camera_rounded, color: ColoresApp.secundario, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Foto de Evidencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColoresApp.textoOscuro,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ColoresApp.error.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Requerido',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        if (_fotoResultado == null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColoresApp.textoClaro.withAlpha(100),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColoresApp.primario.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 40,
                    color: ColoresApp.primario.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera),
                      label: const Text('Cámara'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _seleccionarDeGaleria,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _fotoResultado!.bytes,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // Retomar foto
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: ColoresApp.primario),
                        onPressed: _tomarFoto,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Eliminar foto
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete, color: ColoresApp.error),
                        onPressed: _eliminarFoto,
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

  Widget _buildSeccionUbicacion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.primario.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.primario.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.satellite_alt_rounded, color: ColoresApp.primario, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ubicación GPS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoOscuro,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ColoresApp.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Requerido',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_obteniendoUbicacion)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColoresApp.primario.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ColoresApp.primario,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Localizando tu posición...',
                    style: TextStyle(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (_latitudEntrega != null && _longitudEntrega != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColoresApp.exito.withAlpha(20),
                        ColoresApp.exito.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColoresApp.exito.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColoresApp.exito.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded, color: ColoresApp.exito, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Ubicación capturada!',
                              style: TextStyle(
                                color: ColoresApp.exito,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_latitudEntrega!.toStringAsFixed(6)}, Lng: ${_longitudEntrega!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: ColoresApp.exito.withAlpha(180),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColoresApp.advertencia.withAlpha(20),
                        ColoresApp.advertencia.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColoresApp.advertencia.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColoresApp.advertencia.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.gps_off_rounded, color: ColoresApp.advertencia, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ubicación no disponible',
                          style: TextStyle(
                            color: ColoresApp.advertencia,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _obtenerUbicacion,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Obtener Ubicación'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColoresApp.acento.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_note_rounded, color: ColoresApp.acento, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Datos Adicionales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColoresApp.textoOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Nombre del receptor
        TextFormField(
          controller: _receptorNombreController,
          decoration: InputDecoration(
            labelText: 'Nombre de quien recibe',
            prefixIcon: Icon(Icons.badge_rounded, color: ColoresApp.primario),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa el nombre de quien recibe';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Observaciones
        TextFormField(
          controller: _observacionesController,
          decoration: InputDecoration(
            labelText: 'Observaciones (opcional)',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Icon(Icons.sticky_note_2_rounded, color: ColoresApp.secundario),
            ),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
