import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'company_service.dart';

/// Gestion des factures (extrait de SupabaseService).
class InvoiceService {
  InvoiceService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;

  static Future<Map<String, dynamic>?> getUserCompany() =>
      CompanyService.getUserCompany();
  static Future<Map<String, dynamic>?> getUserProfile(String userId) =>
      SupabaseService.getUserProfile(userId);

  /// Récupérer toutes les factures (pour admins/associés)
  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    try {
      final response = await client
          .from('invoice_details')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de toutes les factures: $e');
      return [];
    }
  }

  /// Récupérer les factures d'un client spécifique
  static Future<List<Map<String, dynamic>>> getClientInvoices([String? clientUserId]) async {
    try {
      var query = client.from('invoice_details').select('*');
      
      // Si un clientUserId est fourni, filtrer par ce client
      // Sinon, utiliser l'utilisateur connecté (pour les clients qui consultent leurs propres factures)
      final targetUserId = clientUserId ?? currentUser?.id;
      if (targetUserId != null) {
        query = query.eq('client_user_id', targetUserId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des factures client: $e');
      return [];
    }
  }

  /// Créer une nouvelle facture
  static Future<Map<String, dynamic>?> createInvoice({
    required String clientUserId,
    required String title,
    required String description,
    required double amount,
    required DateTime dueDate,
    String? projectId,
    double? taxRate,
    DateTime? invoiceDate,
    String status = 'draft',
  }) async {
    try {
      // Récupérer l'entreprise de l'utilisateur connecté (admin/associé)
      debugPrint('Tentative de récupération de l\'entreprise pour l\'utilisateur: ${currentUser?.id}');
      
      final userCompany = await getUserCompany();
      debugPrint('Entreprise récupérée: $userCompany');
      
      if (userCompany == null) {
        // Diagnostic plus détaillé
        debugPrint('❌ Aucune entreprise trouvée pour l\'utilisateur');
        
        // Vérifier si l'utilisateur existe dans profiles
        try {
          final userProfile = await getUserProfile(currentUser!.id);
          debugPrint('Profil utilisateur: $userProfile');
          
          if (userProfile == null) {
            throw Exception('Profil utilisateur non trouvé. Contactez l\'administrateur.');
          }
          
          final userRole = userProfile['user_role'] ?? userProfile['role'];
          final companyId = userProfile['company_id'];
          
          debugPrint('Rôle utilisateur: $userRole, company_id: $companyId');
          
          if (companyId == null || companyId == 0) {
            throw Exception(
              'Utilisateur non assigné à une entreprise.\n\n'
              'Solutions:\n'
              '1. Exécutez le script SQL de diagnostic dans Supabase\n'
              '2. Ou contactez l\'administrateur pour vous assigner à une entreprise\n\n'
              'Votre rôle: $userRole\n'
              'Votre ID: ${currentUser?.id}'
            );
          } else {
            throw Exception('Entreprise trouvée (ID: $companyId) mais vue user_company_info inaccessible');
          }
        } catch (e) {
          throw Exception('Erreur lors du diagnostic utilisateur: $e');
        }
      }
      
      if (userCompany['company_id'] == null) {
        throw Exception(
          'Données d\'entreprise incohérentes.\n'
          'Entreprise: ${userCompany['company_name']}\n'
          'ID: ${userCompany['company_id']}\n'
          'Contactez l\'administrateur.'
        );
      }

      debugPrint('✅ Création de facture pour l\'entreprise: ${userCompany['company_name']} (ID: ${userCompany['company_id']})');

      final invoiceData = {
        'company_id': userCompany['company_id'],
        'client_user_id': clientUserId,
        'title': title,
        'description': description,
        'amount': amount,
        'due_date': dueDate.toIso8601String().split('T')[0], // Format YYYY-MM-DD
        'invoice_date': (invoiceDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'status': status,
        'created_by': currentUser!.id,
      };

      if (projectId != null) {
        invoiceData['mission_id'] = projectId;
      }
      if (taxRate != null) {
        invoiceData['tax_rate'] = taxRate;
      }

      debugPrint('Données de la facture à insérer: $invoiceData');

      final response = await client
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();
      
      debugPrint('✅ Facture créée avec succès: ${response['invoice_number']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la facture: $e');
      rethrow;
    }
  }

  /// Mettre à jour une facture
  static Future<void> updateInvoice(int invoiceId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('invoices')
          .update(updates)
          .eq('id', invoiceId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la facture: $e');
      rethrow;
    }
  }

  /// Supprimer une facture
  static Future<void> deleteInvoice(int invoiceId) async {
    try {
      await client
          .from('invoices')
          .delete()
          .eq('id', invoiceId);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la facture: $e');
      rethrow;
    }
  }

  /// Marquer une facture comme payée
  static Future<void> markInvoiceAsPaid(int invoiceId, {
    String? paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
  }) async {
    try {
      final updates = {
        'status': 'paid',
        'payment_date': (paymentDate ?? DateTime.now()).toIso8601String().split('T')[0],
      };

      if (paymentMethod != null) {
        updates['payment_method'] = paymentMethod;
      }
      if (paymentReference != null) {
        updates['payment_reference'] = paymentReference;
      }

      await updateInvoice(invoiceId, updates);
    } catch (e) {
      debugPrint('Erreur lors du marquage de la facture comme payée: $e');
      rethrow;
    }
  }

}
