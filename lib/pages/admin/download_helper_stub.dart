import 'dart:typed_data';
import 'package:flutter/material.dart';

class DownloadHelper {
  static Future<void> downloadFile(
    String fileName, 
    Uint8List fileBytes, 
    BuildContext context
  ) async {
    // Plateforme non supportée
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement non supporté sur cette plateforme'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} 