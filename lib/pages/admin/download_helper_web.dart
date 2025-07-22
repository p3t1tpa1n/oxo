import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';

class DownloadHelper {
  static Future<void> downloadFile(
    String fileName, 
    Uint8List fileBytes, 
    BuildContext context
  ) async {
    try {
      // Créer un Blob avec les données du fichier
      final mimeType = _getMimeType(fileName);
      final blob = html.Blob([fileBytes], mimeType);
      
      // Créer une URL temporaire pour le Blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Créer un élément <a> pour forcer le téléchargement
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      // Ajouter au DOM, cliquer pour déclencher le téléchargement, puis nettoyer
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      // Libérer l'URL temporaire
      html.Url.revokeObjectUrl(url);
      
      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📥 $fileName téléchargé dans votre dossier Téléchargements'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      // Fallback: ouvrir dans un nouvel onglet
      try {
        final base64String = base64Encode(fileBytes);
        final mimeType = _getMimeType(fileName);
        final dataUrl = 'data:$mimeType;base64,$base64String';
        
        html.window.open(dataUrl, '_blank');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📂 $fileName ouvert dans un nouvel onglet\nClic droit > "Enregistrer sous..." pour télécharger'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 6),
          ),
        );
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Impossible de télécharger le fichier: $e2'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
} 