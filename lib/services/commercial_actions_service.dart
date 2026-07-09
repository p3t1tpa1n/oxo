import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Gestion des actions commerciales (extrait de SupabaseService).
class CommercialActionsService {
  CommercialActionsService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;

  static Future<Map<String, dynamic>?> getUserCompany() =>
      SupabaseService.getUserCompany();

  /// Récupérer toutes les actions commerciales pour l'entreprise de l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getCommercialActions() async {
    try {
      debugPrint('🏢 Récupération des actions commerciales...');
      final userId = currentUser?.id;
      debugPrint('👤 User ID: $userId');
      
      // Essayer d'abord avec la fonction RPC
      try {
        final response = await client.rpc('get_commercial_actions_for_company');
        final actions = List<Map<String, dynamic>>.from(response);
        debugPrint('🏢 ${actions.length} actions commerciales récupérées via RPC');
        
        if (actions.isNotEmpty) {
          return actions;
        }
      } catch (rpcError) {
        debugPrint('⚠️ Erreur RPC, fallback sur requête directe: $rpcError');
      }
      
      // Fallback 1 : récupérer par company_id si disponible
      debugPrint('🔄 Fallback 1: récupération par company_id...');
      final userCompany = await getUserCompany();
      if (userCompany != null && userCompany['company_id'] != null) {
        final companyId = userCompany['company_id'];
        debugPrint('🏢 Company ID: $companyId');
        
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('company_id', companyId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par company_id');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par company_id: $e');
        }
      }
      
      // Fallback 2 : récupérer les actions créées par l'utilisateur
      if (userId != null) {
        debugPrint('🔄 Fallback 2: récupération par created_by...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('created_by', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par created_by');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par created_by: $e');
        }
      }
      
      // Fallback 3 : récupérer les actions assignées à l'utilisateur
      if (userId != null) {
        debugPrint('🔄 Fallback 3: récupération par assigned_to...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('assigned_to', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par assigned_to');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par assigned_to: $e');
        }
      }
      
      // Fallback 4 : récupérer les actions où l'utilisateur est partenaire
      if (userId != null) {
        debugPrint('🔄 Fallback 4: récupération par partner_id...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('partner_id', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par partner_id');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par partner_id: $e');
        }
      }
      
      debugPrint('❌ Aucune action commerciale trouvée avec aucun des fallbacks');
      return [];
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des actions commerciales: $e');
      return [];
    }
  }
  
  /// Transformer les actions pour correspondre au format attendu
  static List<Map<String, dynamic>> _transformActions(List<Map<String, dynamic>> actions) {
    return actions.map((action) {
      return {
        'id': action['id'],
        'title': action['title'],
        'description': action['description'],
        'type': action['type'],
        'status': action['status'],
        'priority': action['priority'],
        'client_name': action['client_name'] ?? '',
        'contact_person': action['contact_person'],
        'contact_email': action['contact_email'],
        'contact_phone': action['contact_phone'],
        'estimated_value': action['estimated_value'],
        'actual_value': action['actual_value'],
        'due_date': action['due_date'],
        'completed_date': action['completed_date'],
        'created_at': action['created_at'],
        'updated_at': action['updated_at'],
        'assigned_to_email': null,
        'assigned_to_name': null,
        'partner_email': null,
        'partner_name': null,
        'notes': action['notes'],
      };
    }).toList();
  }

  /// Créer une nouvelle action commerciale
  static Future<Map<String, dynamic>?> createCommercialAction({
    required String title,
    required String description,
    required String type,
    required String clientName,
    required String priority,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    double? estimatedValue,
    DateTime? dueDate,
    String? assignedTo,
    String? partnerId,
    String? notes,
  }) async {
    try {
      debugPrint('🏢 Création d\'une action commerciale: $title');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'entreprise de l'utilisateur
      final userProfile = await client
          .from('profiles')
          .select('company_id')
          .eq('user_id', currentUser.id)
          .single();

      final actionData = {
        'title': title,
        'description': description,
        'type': type,
        'status': 'planned',
        'priority': priority,
        'client_name': clientName,
        'contact_person': contactPerson,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'estimated_value': estimatedValue,
        'due_date': dueDate?.toIso8601String(),
        'assigned_to': assignedTo,
        'partner_id': partnerId,
        'company_id': userProfile['company_id'],
        'created_by': currentUser.id,
        'notes': notes,
      };

      // Supprimer les valeurs nulles
      actionData.removeWhere((key, value) => value == null);

      final response = await client
          .from('commercial_actions')
          .insert(actionData)
          .select()
          .single();

      debugPrint('✅ Action commerciale créée avec l\'ID: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'action commerciale: $e');
      return null;
    }
  }

  /// Mettre à jour une action commerciale
  static Future<bool> updateCommercialAction({
    required String actionId,
    String? title,
    String? description,
    String? type,
    String? status,
    String? priority,
    String? clientName,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    double? estimatedValue,
    double? actualValue,
    DateTime? dueDate,
    DateTime? completedDate,
    String? assignedTo,
    String? partnerId,
    String? notes,
    String? outcome,
  }) async {
    try {
      debugPrint('🏢 Mise à jour de l\'action commerciale: $actionId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (type != null) updateData['type'] = type;
      if (status != null) updateData['status'] = status;
      if (priority != null) updateData['priority'] = priority;
      if (clientName != null) updateData['client_name'] = clientName;
      if (contactPerson != null) updateData['contact_person'] = contactPerson;
      if (contactEmail != null) updateData['contact_email'] = contactEmail;
      if (contactPhone != null) updateData['contact_phone'] = contactPhone;
      if (estimatedValue != null) updateData['estimated_value'] = estimatedValue;
      if (actualValue != null) updateData['actual_value'] = actualValue;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (completedDate != null) updateData['completed_date'] = completedDate.toIso8601String();
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (partnerId != null) updateData['partner_id'] = partnerId;
      if (notes != null) updateData['notes'] = notes;
      if (outcome != null) updateData['outcome'] = outcome;

      await client
          .from('commercial_actions')
          .update(updateData)
          .eq('id', actionId);

      debugPrint('✅ Action commerciale mise à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de l\'action commerciale: $e');
      return false;
    }
  }

  /// Supprimer une action commerciale
  static Future<bool> deleteCommercialAction(String actionId) async {
    try {
      debugPrint('🏢 Suppression de l\'action commerciale: $actionId');

      await client
          .from('commercial_actions')
          .delete()
          .eq('id', actionId);

      debugPrint('✅ Action commerciale supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de l\'action commerciale: $e');
      return false;
    }
  }

  /// Marquer une action commerciale comme terminée
  static Future<bool> completeCommercialAction({
    required String actionId,
    double? actualValue,
    String? outcome,
  }) async {
    return updateCommercialAction(
      actionId: actionId,
      status: 'completed',
      completedDate: DateTime.now(),
      actualValue: actualValue,
      outcome: outcome,
    );
  }
}
