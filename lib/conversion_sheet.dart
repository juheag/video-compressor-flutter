import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'format_converter.dart';

class ConversionSheet extends StatefulWidget {
  final String compressedPath;

  const ConversionSheet({super.key, required this.compressedPath});

  static Future<void> show(BuildContext context, String compressedPath) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConversionSheet(compressedPath: compressedPath),
    );
  }

  @override
  State<ConversionSheet> createState() => _ConversionSheetState();
}

class _ConversionSheetState extends State<ConversionSheet> {
  bool _isConverting = false;
  String _statusText = '';

  Future<void> _startConversion(String format) async {
    setState(() {
      _isConverting = true;
      _statusText = 'Convirtiendo a .$format...';
    });

    final newPath = await FormatConverter.convert(
      inputPath: widget.compressedPath,
      targetFormat: format,
    );

    if (!mounted) return;

    setState(() {
      _isConverting = false;
    });

    if (newPath != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Conversión a .$format completada!')),
      );
      // Abre la hoja nativa para guardar o compartir el nuevo archivo
      await Share.shareXFiles([XFile(newPath)], text: 'Archivo convertido con Videocomprime');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al convertir el video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _isConverting
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_statusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Convertir archivo comprimido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona el formato de exportación que necesitas:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  _buildOption(
                    title: 'MOV (Formato Apple)',
                    subtitle: 'Ideal para QuickTime y edición en Mac o Final Cut',
                    icon: Icons.movie_creation_outlined,
                    onTap: () => _startConversion('mov'),
                  ),
                  _buildOption(
                    title: 'MP4 (Video estándar)',
                    subtitle: 'Máxima compatibilidad para redes y Android',
                    icon: Icons.video_file_outlined,
                    onTap: () => _startConversion('mp4'),
                  ),
                  _buildOption(
                    title: 'MP3 (Extraer solo audio)',
                    subtitle: 'Conserva solo la pista de sonido sin imagen',
                    icon: Icons.audiotrack_outlined,
                    onTap: () => _startConversion('mp3'),
                  ),
                  _buildOption(
                    title: 'GIF Animado',
                    subtitle: 'Convierte el clip en una animación corta',
                    icon: Icons.gif_box_outlined,
                    onTap: () => _startConversion('gif'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(icon, color: Colors.blue.shade800),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
