import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String newVersion;
  final String description;
  final String downloadUrl;

  const UpdateDialog({
    super.key,
    required this.newVersion,
    required this.description,
    required this.downloadUrl,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  String _error = '';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _error = '';
    });

    try {
      await UpdateService.downloadAndInstallUpdate(widget.downloadUrl);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mise à jour disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Une nouvelle version (${widget.newVersion}) est disponible.'),
          const SizedBox(height: 16),
          const Text(
            'Notes de version :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(widget.description),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _downloadAndInstall,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1784af),
          ),
          child: _isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Mettre à jour',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
} 