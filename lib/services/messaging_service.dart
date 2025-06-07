import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'supabase_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  // Streams pour les mises à jour en temps réel
  final StreamController<List<Map<String, dynamic>>> _conversationsController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, StreamController<List<Map<String, dynamic>>>> _messageControllers = {};

  // Getters pour les streams
  Stream<List<Map<String, dynamic>>> get conversationsStream => _conversationsController.stream;
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<List<Map<String, dynamic>>>.broadcast();
      _subscribeToMessages(conversationId);
    }
    return _messageControllers[conversationId]!.stream;
  }

  // Initialiser les abonnements en temps réel
  Future<void> initialize() async {
    await _subscribeToConversations();
    debugPrint('MessagingService initialisé');
  }

  // S'abonner aux mises à jour des conversations
  Future<void> _subscribeToConversations() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté pour s\'abonner aux conversations');
        return;
      }

      // Charger les conversations initiales
      await loadConversations();

      // S'abonner aux changements sur les conversations
      SupabaseService.client
          .channel('public:conversations')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (payload) {
              debugPrint('Mise à jour conversation reçue: $payload');
              loadConversations();
            },
          )
          .subscribe();

      // S'abonner aux changements sur les messages (pour les compteurs non lus)
      SupabaseService.client
          .channel('public:messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              debugPrint('Nouveau message reçu: $payload');
              loadConversations();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Erreur lors de l\'abonnement aux conversations: $e');
    }
  }

  // S'abonner aux messages d'une conversation spécifique
  Future<void> _subscribeToMessages(String conversationId) async {
    try {
      // Charger les messages initiaux
      await loadMessages(conversationId);

      // S'abonner aux nouveaux messages
      SupabaseService.client
          .channel('messages:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              debugPrint('Nouveau message dans la conversation: $payload');
              loadMessages(conversationId);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Erreur lors de l\'abonnement aux messages: $e');
    }
  }

  // Helper pour obtenir les IDs des conversations de l'utilisateur
  String _getUserConversationIds() {
    return ''; // Sera rempli dynamiquement après le premier chargement
  }

  // Charger les conversations d'un utilisateur
  Future<List<Map<String, dynamic>>> loadConversations() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté pour charger les conversations');
        return [];
      }

      final response = await SupabaseService.client.rpc(
        'get_user_conversations',
        params: {'p_user_id': currentUser.id},
      );
      debugPrint('Conversations chargées: $response');

      final conversations = List<Map<String, dynamic>>.from(response);
      debugPrint('Conversations chargées: ${conversations.length}');
      
      // Mettre à jour le stream
      _conversationsController.add(conversations);
      
      return conversations;
    } catch (e) {
      debugPrint('Erreur lors du chargement des conversations: $e');
      return [];
    }
  }

  // Charger les messages d'une conversation
  Future<List<Map<String, dynamic>>> loadMessages(String conversationId) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');

      final messages = List<Map<String, dynamic>>.from(response);
      debugPrint('Messages chargés: ${messages.length} pour la conversation $conversationId');
      
      // Mettre à jour le stream
      if (_messageControllers.containsKey(conversationId)) {
        _messageControllers[conversationId]!.add(messages);
      }
      
      return messages;
    } catch (e) {
      debugPrint('Erreur lors du chargement des messages: $e');
      return [];
    }
  }

  // Créer ou récupérer une conversation entre deux utilisateurs
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      debugPrint('getOrCreateConversation appelé avec: $otherUserId');
      final currentUserId = SupabaseService.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('Utilisateur actuel: $currentUserId');

      // CONTOURNER la vérification des tables pour éviter la récursion infinie
      // Aller directement à l'appel RPC

      // Appeler la fonction RPC pour créer/récupérer la conversation
      final response = await SupabaseService.client.rpc('create_conversation', params: {
        'p_user_id1': currentUserId,
        'p_user_id2': otherUserId,
      });
      
      debugPrint('Réponse de create_conversation: $response');
      
      if (response != null) {
        return response.toString();
      } else {
        throw Exception('Impossible de créer la conversation');
      }
    } catch (e) {
      debugPrint('Erreur lors de la création/récupération de la conversation: $e');
      rethrow;
    }
  }

  Future<void> _ensureTablesExist() async {
    // MÉTHODE DÉSACTIVÉE pour éviter la récursion infinie
    // Les tables sont supposées exister maintenant
    debugPrint('Vérification des tables contournée');
    return;
  }

  Future<void> _createTables() async {
    // Cette méthode n'est plus utilisée car Supabase ne permet pas l'exécution SQL arbitraire
    throw Exception('Création automatique des tables non supportée. Veuillez utiliser l\'interface web de Supabase.');
  }

  Future<void> _createFunctions() async {
    // Cette méthode n'est plus utilisée car Supabase ne permet pas l'exécution SQL arbitraire
    throw Exception('Création automatique des fonctions non supportée. Veuillez utiliser l\'interface web de Supabase.');
  }

  // Envoyer un message
  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté pour envoyer un message');
        return false;
      }

      await SupabaseService.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Message envoyé avec succès dans la conversation $conversationId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      return false;
    }
  }

  // Marquer les messages comme lus
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté pour marquer les messages comme lus');
        return false;
      }

      await SupabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);

      debugPrint('Messages marqués comme lus dans la conversation $conversationId');
      
      // Recharger les conversations pour mettre à jour les compteurs
      await loadConversations();
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du marquage des messages comme lus: $e');
      return false;
    }
  }

  // Créer une conversation de groupe
  Future<String?> createGroupConversation(String name, List<String> userIds) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté pour créer une conversation de groupe');
        return null;
      }

      // Ajouter l'utilisateur courant à la liste s'il n'y est pas déjà
      if (!userIds.contains(currentUser.id)) {
        userIds.add(currentUser.id);
      }

      // Créer la conversation
      final conversationResponse = await SupabaseService.client
          .from('conversations')
          .insert({
            'name': name,
            'is_group': true,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'] as String;

      // Ajouter les participants
      for (final userId in userIds) {
        await SupabaseService.client.from('conversation_participants').insert({
          'conversation_id': conversationId,
          'user_id': userId,
        });
      }

      debugPrint('Conversation de groupe créée: $conversationId');
      
      // Recharger les conversations
      await loadConversations();
      
      return conversationId;
    } catch (e) {
      debugPrint('Erreur lors de la création de la conversation de groupe: $e');
      return null;
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _conversationsController.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }
} 