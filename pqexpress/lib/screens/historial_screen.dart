// ============================================================
// PQEXPRESS - Pantalla de Historial de Entregas
// Lista de envíos completados
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/envios_provider.dart';
import '../models/envio.dart';
import '../config/theme.dart';
import 'envio_detalle_screen.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics_rounded, size: 22),
            const SizedBox(width: 10),
            const Text('Mi Historial'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EnviosProvider>(
        builder: (context, enviosProvider, _) {
          final completados = enviosProvider.enviosCompletados;

          if (completados.isEmpty) {
            return _buildEstadoVacio(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            itemCount: completados.length,
            itemBuilder: (context, index) {
              return _buildTarjetaEnvio(context, completados[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEstadoVacio(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: ColoresApp.primario.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: ColoresApp.primario.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Aún no hay entregas! 📦',
            style: TextStyle(
              fontSize: 20,
              color: ColoresApp.textoOscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tus entregas completadas aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: ColoresApp.textoMedio,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEnvio(BuildContext context, Envio envio) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ColoresApp.exito.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.exito.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColoresApp.exito.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 20,
                            color: ColoresApp.exito,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    if (envio.fechaCompletado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ColoresApp.primario.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: ColoresApp.primario),
                            const SizedBox(width: 6),
                            Text(
                              _formatearFecha(envio.fechaCompletado!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColoresApp.primario,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 14),
                Divider(color: ColoresApp.textoClaro.withAlpha(60)),
                const SizedBox(height: 10),
                
                // Destinatario
                Row(
                  children: [
                    Icon(Icons.account_circle_rounded, size: 18, color: ColoresApp.secundario),
                    const SizedBox(width: 10),
                    Text(
                      envio.receptorNombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoOscuro,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Dirección
                Row(
                  children: [
                    Icon(Icons.pin_drop_rounded, size: 18, color: ColoresApp.primario.withAlpha(180)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        envio.direccionFormateada,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColoresApp.textoMedio,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
