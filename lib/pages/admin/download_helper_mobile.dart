import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DownloadHelper {
  static Future<void> downloadFile(
    String fileName, 
    Uint8List fileBytes, 
    BuildContext context
  ) async {
    try {
      // Pour mobile/desktop, sauvegarder dans le dossier Documents
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(fileBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📥 $fileName téléchargé avec succès'),
              Text(
                'Emplacement: ${file.path}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D5B),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 