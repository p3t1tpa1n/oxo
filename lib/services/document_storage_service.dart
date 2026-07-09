import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Stockage de documents dans Supabase Storage (extrait de SupabaseService).
class DocumentStorageService {
  DocumentStorageService._();

  static SupabaseClient get _client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;
  /// Upload des documents vers Supabase Storage
  static Future<List<Map<String, dynamic>>> uploadDocuments(List<PlatformFile> files) async {
    List<Map<String, dynamic>> uploadedFiles = [];
    
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('🔄 Début upload de ${files.length} fichier(s)...');

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        debugPrint('📁 Upload fichier ${i+1}/${files.length}: ${file.name}');
        
        try {
          if (file.bytes != null) {
            // Web: utiliser les bytes
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = 'project_documents/${currentUser!.id}/$fileName';
            
            debugPrint('🌐 Upload web - Chemin: $filePath');
            
            final response = await _client!.storage
                .from('documents')
                .uploadBinary(filePath, file.bytes!);

            debugPrint('✅ Upload réussi - Réponse: $response');

            uploadedFiles.add({
              'file_name': file.name,
              'file_path': filePath,
              'file_size': file.size,
              'mime_type': _getMimeType(file.name),
            });
            
          } else if (file.path != null) {
            // Mobile/Desktop: utiliser le path
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = 'project_documents/${currentUser!.id}/$fileName';
            
            debugPrint('📱 Upload mobile/desktop - Chemin: $filePath');
            
            final fileBytes = await File(file.path!).readAsBytes();
            debugPrint('📝 Fichier lu: ${fileBytes.length} bytes');
            
            final response = await _client!.storage
                .from('documents')
                .uploadBinary(filePath, fileBytes);

            debugPrint('✅ Upload réussi - Réponse: $response');

            uploadedFiles.add({
              'file_name': file.name,
              'file_path': filePath,
              'file_size': file.size,
              'mime_type': _getMimeType(file.name),
            });
          } else {
            debugPrint('❌ Fichier ${file.name} sans bytes ni path');
          }
        } catch (fileError) {
          debugPrint('❌ Erreur upload fichier ${file.name}: $fileError');
          // Continue avec les autres fichiers
        }
      }
      
      debugPrint('🎉 Upload terminé: ${uploadedFiles.length}/${files.length} fichiers uploadés');
      return uploadedFiles;
    } catch (e) {
      debugPrint('💥 Erreur générale lors de l\'upload des documents: $e');
      return [];
    }
  }

  /// Obtenir le type MIME basé sur l'extension du fichier
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

  /// Récupérer les documents d'une proposition (pour les associés)
  static Future<List<Map<String, dynamic>>> getProposalDocuments(String proposalId) async {
    try {
      debugPrint('📋 Récupération documents pour proposition: $proposalId');
      
      final response = await _client!
          .from('project_proposal_documents')
          .select('*')
          .eq('proposal_id', proposalId)
          .order('uploaded_at', ascending: false);

      debugPrint('📄 ${response.length} document(s) trouvé(s)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur récupération documents: $e');
      return [];
    }
  }

  /// Télécharger l'URL publique d'un document
  static String getDocumentUrl(String filePath) {
    return _client!.storage.from('documents').getPublicUrl(filePath);
  }

  /// Télécharger un document depuis le storage
  static Future<Uint8List?> downloadDocument(String filePath) async {
    try {
      debugPrint('⬇️ Téléchargement document: $filePath');
      
      final response = await _client!.storage
          .from('documents')
          .download(filePath);

      debugPrint('✅ Document téléchargé: ${response.length} bytes');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur téléchargement document: $e');
      return null;
    }
  }
}
