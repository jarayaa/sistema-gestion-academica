import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  /// Muestra el diálogo de actualización
  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateService updateService,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return UpdateDialog(
          updateInfo: updateInfo,
          updateService: updateService,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFF007AFF), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Actualización disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionInfo(),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF3A3A3C)),
            const SizedBox(height: 16),
            _buildDescripcion(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Más tarde',
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _abrirUrl(context),
          child: const Text('Actualizar ahora'),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Versión actual:',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
            Text(
              'v${updateInfo.versionActual}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Versión nueva:',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF34C759), width: 1),
              ),
              child: Text(
                'v${updateInfo.versionNueva}',
                style: const TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Novedades:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          updateInfo.descripcion.isNotEmpty
              ? updateInfo.descripcion
              : 'Nueva versión disponible con mejoras y correcciones.',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFAAAAAA),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _abrirUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(updateInfo.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
