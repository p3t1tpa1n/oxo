import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Gestion des entreprises (extrait de SupabaseService).
class CompanyService {
  CompanyService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;

  /// Récupérer toutes les entreprises (pour admins/associés)
  static Future<List<Map<String, dynamic>>> getAllCompanies() async {
    try {
      // Essayer d'abord 'company' (singulier), puis 'companies' (pluriel) en fallback
      try {
        final response = await client
            .from('company')
            .select('id, name')
            .order('name', ascending: true);
        
        final companies = List<Map<String, dynamic>>.from(response);
        debugPrint('✅ ${companies.length} companies récupérées depuis la table "company"');
        return companies;
      } catch (e) {
        debugPrint('⚠️ Table "company" non trouvée, tentative avec "companies"...');
      final response = await client
          .from('companies')
            .select('id, name')
          .order('name', ascending: true);
      
        final companies = List<Map<String, dynamic>>.from(response);
        debugPrint('✅ ${companies.length} companies récupérées depuis la table "companies"');
        return companies;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des entreprises: $e');
      return [];
    }
  }

  /// Récupérer l'entreprise de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getUserCompany() async {
    try {
      final response = await client
          .from('user_company_info')
          .select()
          .eq('user_id', currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'entreprise utilisateur: $e');
      return null;
    }
  }

  /// Créer une nouvelle entreprise
  static Future<Map<String, dynamic>?> createCompany({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
  }) async {
    try {
      final response = await client
          .from('companies')
          .insert({
            'name': name,
            'description': description,
            'address': address,
            'phone': phone,
            'email': email,
            'website': website,
            'status': 'active',
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'entreprise: $e');
      rethrow;
    }
  }

  /// Mettre à jour une entreprise
  static Future<void> updateCompany(int companyId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('companies')
          .update(updates)
          .eq('id', companyId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'entreprise: $e');
      rethrow;
    }
  }

  /// Assigner un utilisateur à une entreprise
  static Future<bool> assignUserToCompany(String userId, int companyId) async {
    try {
      final result = await client.rpc('assign_user_to_company', params: {
        'user_id_param': userId,
        'company_id_param': companyId,
      });
      
      return result as bool;
    } catch (e) {
      debugPrint('Erreur lors de l\'assignation à l\'entreprise: $e');
      rethrow;
    }
  }
}
