import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Propositions de projets et demandes d'extension de temps
/// soumises par les clients (extrait de SupabaseService).
class ProjectProposalService {
  ProjectProposalService._();

  static SupabaseClient get _client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;

  /// Récupérer toutes les propositions de projets (pour les associés)
  static Future<List<Map<String, dynamic>>> getProjectProposals() async {
    try {
      final response = await _client!
          .from('project_proposals')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des propositions: $e');
      return [];
    }
  }

  /// Récupérer les propositions en attente uniquement
  static Future<List<Map<String, dynamic>>> getPendingProjectProposals() async {
    try {
      final response = await _client!
          .from('project_proposals')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des propositions en attente: $e');
      return [];
    }
  }

  /// Récupérer toutes les demandes d'extension de temps
  static Future<List<Map<String, dynamic>>> getTimeExtensionRequests() async {
    try {
      final response = await _client!
          .from('time_extension_requests')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'extension: $e');
      return [];
    }
  }

  /// Récupérer les demandes d'extension en attente uniquement
  static Future<List<Map<String, dynamic>>> getPendingTimeExtensionRequests() async {
    try {
      final response = await _client!
          .from('time_extension_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'extension en attente: $e');
      return [];
    }
  }

  /// Approuver une proposition de projet (crée automatiquement le projet)
  static Future<String?> approveProjectProposal({
    required String proposalId,
    String? responseMessage,
  }) async {
    try {
      final response = await _client!.rpc('approve_project_proposal', params: {
        'p_proposal_id': proposalId,
        'p_response_message': responseMessage,
      });

      return response.toString(); // ID de la nouvelle mission créé
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation de la proposition: $e');
      return null;
    }
  }

  /// Rejeter une proposition de projet
  static Future<bool> rejectProjectProposal({
    required String proposalId,
    String? responseMessage,
  }) async {
    try {
      final updates = {
        'status': 'rejected',
        'reviewed_by': currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (responseMessage != null && responseMessage.isNotEmpty) {
        updates['response_message'] = responseMessage;
      }

      await _client!
          .from('project_proposals')
          .update(updates)
          .eq('id', proposalId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors du rejet de la proposition: $e');
      return false;
    }
  }

  /// Approuver une demande d'extension de temps (met à jour automatiquement le projet)
  static Future<bool> approveTimeExtensionRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    try {
      final response = await _client!.rpc('approve_time_extension', params: {
        'p_request_id': requestId,
        'p_response_message': responseMessage,
      });

      return response == true;
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation de l\'extension: $e');
      return false;
    }
  }

  /// Rejeter une demande d'extension de temps
  static Future<bool> rejectTimeExtensionRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    try {
      final updates = {
        'status': 'rejected',
        'approved_by': currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (responseMessage != null && responseMessage.isNotEmpty) {
        updates['response_message'] = responseMessage;
      }

      await _client!
          .from('time_extension_requests')
          .update(updates)
          .eq('id', requestId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors du rejet de la demande d\'extension: $e');
      return false;
    }
  }

  /// Soumettre une nouvelle proposition de projet (pour les clients)
  static Future<String?> submitProjectProposal({
    required String title,
    required String description,
    double? estimatedBudget,
    double? estimatedDays,
    DateTime? endDate,
    List<Map<String, dynamic>>? documents,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer la company_id de l'utilisateur
      final userProfile = await _client!
          .from('profiles')
          .select('company_id')
          .eq('user_id', currentUser!.id)
          .single();

      final proposalData = {
        'title': title,
        'description': description,
        'estimated_budget': estimatedBudget,
        'estimated_days': estimatedDays,
        'end_date': endDate?.toIso8601String().split('T')[0], // Format DATE
        'client_id': currentUser!.id,
        'company_id': userProfile['company_id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final proposalResponse = await _client!
          .from('project_proposals')
          .insert(proposalData)
          .select()
          .single();

      final proposalId = proposalResponse['id'];

      // Sauvegarder les documents s'il y en a
      debugPrint('💾 Sauvegarde documents en base - Proposal ID: $proposalId');
      if (documents != null && documents.isNotEmpty) {
        debugPrint('📋 ${documents.length} documents à sauvegarder en base');
        for (int i = 0; i < documents.length; i++) {
          final doc = documents[i];
          debugPrint('💾 Sauvegarde document ${i+1}/${documents.length}: ${doc['file_name']}');
          
          try {
            final docData = {
              'proposal_id': proposalId,
              'file_name': doc['file_name'],
              'file_path': doc['file_path'],
              'file_size': doc['file_size'],
              'mime_type': doc['mime_type'],
              'uploaded_at': DateTime.now().toIso8601String(),
            };
            
            debugPrint('📄 Données document: $docData');
            
            await _client!.from('project_proposal_documents').insert(docData);
            debugPrint('✅ Document sauvegardé en base avec succès');
          } catch (docError) {
            debugPrint('❌ Erreur sauvegarde document ${doc['file_name']}: $docError');
          }
        }
        debugPrint('🎉 Tous les documents traités pour la proposition $proposalId');
      } else {
        debugPrint('ℹ️ Aucun document à sauvegarder (documents: $documents)');
      }

      return proposalId;
    } catch (e) {
      debugPrint('Erreur lors de la soumission de la proposition: $e');
      return null;
    }
  }

  /// Soumettre une demande d'extension de temps (pour les clients)
  static Future<bool> submitTimeExtensionRequest({
    required String projectId,
    required double daysRequested,
    required String reason,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final extensionData = {
        'mission_id': projectId,
        'client_id': currentUser!.id,
        'days_requested': daysRequested,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('time_extension_requests').insert(extensionData);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la soumission de la demande d\'extension: $e');
      return false;
    }
  }
}
