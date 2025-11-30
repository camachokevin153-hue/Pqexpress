// ============================================================
// PQEXPRESS - Provider de Envíos
// Gestiona el estado de los envíos/paquetes
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/envio.dart';
import '../models/confirmacion_entrega.dart';
import '../services/api_service.dart';

/// Estados de carga
enum EstadoCarga {
  inicial,
  cargando,
  completado,
  error,
}

/// Provider para gestionar los envíos
class EnviosProvider with ChangeNotifier {
  // Servicio de API (se inyecta)
  ApiService? _apiService;
  
  // Estado de carga
  EstadoCarga _estado = EstadoCarga.inicial;
  
  // Listas de envíos
  List<Envio> _enviosPendientes = [];
  List<Envio> _enviosEnRuta = [];
  List<Envio> _historial = [];
  
  // Envío seleccionado actualmente
  Envio? _envioSeleccionado;
  
  // Mensaje de error
  String? _errorMensaje;

  // Getters
  EstadoCarga get estado => _estado;
  List<Envio> get enviosPendientes => _enviosPendientes;
  List<Envio> get enviosEnRuta => _enviosEnRuta;
  List<Envio> get historial => _historial;
  Envio? get envioSeleccionado => _envioSeleccionado;
  String? get errorMensaje => _errorMensaje;
  bool get estaCargando => _estado == EstadoCarga.cargando;
  
  /// Total de envíos activos (pendientes + en ruta)
  int get totalActivos => _enviosPendientes.length + _enviosEnRuta.length;

  /// Configura el servicio de API
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  /// Carga todos los envíos del usuario
  Future<void> cargarEnvios() async {
    if (_apiService == null) return;

    _estado = EstadoCarga.cargando;
    _errorMensaje = null;
    notifyListeners();

    try {
      // Cargar en paralelo pendientes y en ruta
      final resultados = await Future.wait([
        _apiService!.obtenerEnviosPendientes(),
        _apiService!.obtenerEnviosEnRuta(),
      ]);

      _enviosPendientes = resultados[0].envios;
      _enviosEnRuta = resultados[1].envios;
      
      _estado = EstadoCarga.completado;
    } catch (e) {
      _errorMensaje = e.toString();
      _estado = EstadoCarga.error;
    }

    notifyListeners();
  }

  /// Carga el historial de entregas
  Future<void> cargarHistorial({int limite = 50}) async {
    if (_apiService == null) return;

    try {
      final resultado = await _apiService!.obtenerHistorial(limite: limite);
      _historial = resultado.envios;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar historial: $e');
    }
  }

  /// Selecciona un envío para ver detalles
  void seleccionarEnvio(Envio envio) {
    _envioSeleccionado = envio;
    notifyListeners();
  }

  /// Limpia el envío seleccionado
  void limpiarSeleccion() {
    _envioSeleccionado = null;
    notifyListeners();
  }

  /// Carga el detalle de un envío específico
  Future<Envio?> cargarDetalleEnvio(int idEnvio) async {
    if (_apiService == null) return null;

    try {
      final envio = await _apiService!.obtenerDetalleEnvio(idEnvio);
      _envioSeleccionado = envio;
      notifyListeners();
      return envio;
    } catch (e) {
      _errorMensaje = e.toString();
      return null;
    }
  }

  /// Inicia la ruta de un envío
  Future<bool> iniciarRuta(int idEnvio, {String? observaciones}) async {
    if (_apiService == null) return false;

    try {
      final envioActualizado = await _apiService!.iniciarRuta(
        idEnvio, 
        observaciones: observaciones,
      );

      // Actualizar listas locales
      _enviosPendientes.removeWhere((e) => e.idEnvio == idEnvio);
      _enviosEnRuta.add(envioActualizado);
      _envioSeleccionado = envioActualizado;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMensaje = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Registra la confirmación de entrega
  Future<bool> confirmarEntrega(
    int idEnvio,
    ConfirmacionEntrega confirmacion,
  ) async {
    if (_apiService == null) return false;

    try {
      await _apiService!.confirmarEntrega(idEnvio, confirmacion);

      // Remover de envíos activos
      _enviosPendientes.removeWhere((e) => e.idEnvio == idEnvio);
      _enviosEnRuta.removeWhere((e) => e.idEnvio == idEnvio);
      _envioSeleccionado = null;

      // Recargar historial
      await cargarHistorial();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMensaje = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    await cargarEnvios();
  }

  /// Busca un envío por número de guía
  Envio? buscarPorGuia(String guia) {
    // Buscar en pendientes
    for (var envio in _enviosPendientes) {
      if (envio.numeroGuia.toLowerCase().contains(guia.toLowerCase())) {
        return envio;
      }
    }
    // Buscar en en ruta
    for (var envio in _enviosEnRuta) {
      if (envio.numeroGuia.toLowerCase().contains(guia.toLowerCase())) {
        return envio;
      }
    }
    return null;
  }

  /// Filtra envíos por estado
  List<Envio> obtenerPorEstado(EstatusEnvio estatus) {
    switch (estatus) {
      case EstatusEnvio.asignado:
        return _enviosPendientes;
      case EstatusEnvio.enCamino:
        return _enviosEnRuta;
      case EstatusEnvio.completado:
      case EstatusEnvio.fallido:
        return _historial.where((e) => e.estatusEnvio == estatus).toList();
    }
  }

  /// Registra la confirmación de entrega con datos directos
  Future<bool> confirmarEntregaConDatos(
    int idEnvio,
    String receptorNombre,
    double latitud,
    double longitud,
    String fotoBase64,
    String? observaciones,
  ) async {
    if (_apiService == null) return false;

    try {
      final confirmacion = ConfirmacionEntrega(
        idEnvio: idEnvio,
        latConfirmacion: latitud,
        lngConfirmacion: longitud,
        imagenEvidencia: fotoBase64,
        nombreReceptor: receptorNombre,
        comentarios: observaciones,
      );
      
      await _apiService!.confirmarEntrega(idEnvio, confirmacion);

      // Remover de envíos activos
      _enviosPendientes.removeWhere((e) => e.idEnvio == idEnvio);
      _enviosEnRuta.removeWhere((e) => e.idEnvio == idEnvio);
      _envioSeleccionado = null;

      // Recargar historial
      await cargarHistorial();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMensaje = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtiene los envíos completados
  List<Envio> get enviosCompletados => _historial
      .where((e) => e.estatusEnvio == EstatusEnvio.completado)
      .toList();

  /// Limpia todos los datos
  void limpiar() {
    _enviosPendientes = [];
    _enviosEnRuta = [];
    _historial = [];
    _envioSeleccionado = null;
    _estado = EstadoCarga.inicial;
    _errorMensaje = null;
    notifyListeners();
  }
}