import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onSkip;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final esForzosa = updateInfo.esForzosa || 
                      updateInfo.tipo == UpdateType.critical;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            esForzosa ? Icons.warning_amber_rounded : Icons.system_update,
            color: esForzosa ? Colors.orange : const Color(0xFF3B82F6),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              esForzosa ? 'Actualización Requerida' : 'Nueva Versión Disponible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Versiones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Actual',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        'v${updateInfo.versionActual}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white38),
                  Column(
                    children: [
                      const Text(
                        'Nueva',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        'v${updateInfo.versionNueva}',
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Changelog
            if (updateInfo.changelog.isNotEmpty) ...[
              const Text(
                'Novedades:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...updateInfo.changelog.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFF3B82F6)),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            if (esForzosa) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta actualización es obligatoria para continuar usando la app.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!esForzosa && onSkip != null)
          TextButton(
            onPressed: onSkip,
            child: const Text(
              'Más tarde',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Actualizar Ahora'),
        ),
      ],
    );
  }

  /// Muestra el diálogo de actualización
  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateService updateService,
  ) async {
    final esForzosa = updateInfo.esForzosa || 
                      updateInfo.tipo == UpdateType.critical;

    await showDialog(
      context: context,
      barrierDismissible: !esForzosa,
      builder: (context) => WillPopScope(
        onWillPop: () async => !esForzosa,
        child: UpdateDialog(
          updateInfo: updateInfo,
          onUpdate: () async {
            if (updateInfo.urlDescarga != null) {
              await updateService.abrirActualizacion(updateInfo.urlDescarga!);
            }
            if (!esForzosa) {
              Navigator.of(context).pop();
            }
          },
          onSkip: esForzosa ? null : () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}