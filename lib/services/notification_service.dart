import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Notifications applicatives (extrait de SupabaseService).
class NotificationService {
  NotificationService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;

  /// Obtenir les notifications de l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return [];

      final response = await client
          .from('user_notifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  /// Marquer une notification comme lue
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      await client.from('user_notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId).eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage de notification: $e');
      return false;
    }
  }

  /// Obtenir le nombre de notifications non lues
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return 0;

      final response = await client
          .from('unread_notifications_count')
          .select('unread_count')
          .eq('user_id', currentUser.id)
          .single();

      return response['unread_count'] ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur lors du comptage des notifications: $e');
      return 0;
    }
  }

  /// Fonction privée pour créer une notification utilisateur
  static Future<void> createUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? missionAssignmentId,
    String? notificationId,
  }) async {
    try {
      await client.rpc('create_user_notification', params: {
        'p_user_id': userId,
        'p_title': title,
        'p_message': message,
        'p_type': type,
        'p_mission_assignment_id': missionAssignmentId,
        'p_notification_id': notificationId,
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de notification: $e');
    }
  }

  static Future<bool> sendNotificationToPartner(String partnerId, String title, String message) async {
    try {
      debugPrint('🔔 Envoi de notification au partenaire: $partnerId');
      debugPrint('📝 Titre: $title');
      debugPrint('📝 Message: $message');
      
      final notificationData = {
        'user_id': partnerId,
        'title': title,
        'message': message,
        'type': 'mission_assignment',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await client
          .from('notifications')
          .insert(notificationData);
      
      debugPrint('✅ Notification envoyée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de la notification: $e');
      return false;
    }
  }

}
