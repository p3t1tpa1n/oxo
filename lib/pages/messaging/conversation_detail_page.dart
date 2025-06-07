import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../services/messaging_service.dart';

class ConversationDetailPage extends StatefulWidget {
  final String conversationId;
  final String conversationName;
  final bool isGroup;

  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    required this.conversationName,
    required this.isGroup,
  });

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  late final StreamSubscription<List<Map<String, dynamic>>> _messagesSubscription;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  String? _error;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  Future<void> _initMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Marquer les messages comme lus quand on ouvre la conversation
      await _messagingService.markMessagesAsRead(widget.conversationId);
      
      // Écouter les messages
      _messagesSubscription = _messagingService
          .getMessagesStream(widget.conversationId)
          .listen(
            (messages) {
              if (mounted) {
                setState(() {
                  _messages = messages;
                  _isLoading = false;
                });
                
                // Marquer les messages comme lus quand de nouveaux messages arrivent
                _messagingService.markMessagesAsRead(widget.conversationId);
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _error = error.toString();
                  _isLoading = false;
                });
              }
            },
          );
      
      // Charger les messages initiaux
      await _messagingService.loadMessages(widget.conversationId);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des messages: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _messagingService.sendMessage(
        widget.conversationId,
        message,
      );

      if (success) {
        _messageController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de l\'envoi du message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1E3D54),
              child: widget.isGroup
                  ? const Icon(Icons.group, color: Colors.white)
                  : const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isGroup ? 'Conversation de groupe' : 'Conversation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3D54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _messagingService.loadMessages(widget.conversationId);
            },
          ),
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                // TODO: Afficher les membres du groupe
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text('Erreur: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initMessages,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun message',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Envoyez le premier message pour commencer la conversation',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              // Inverser l'index pour afficher les derniers messages en bas
                              final reversedIndex = _messages.length - 1 - index;
                              return _buildMessageBubble(_messages[reversedIndex]);
                            },
                          ),
          ),
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3D54),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String content = message['content'] ?? '';
    final String senderId = message['sender_id'] ?? '';
    final DateTime createdAt = message['created_at'] != null
        ? DateTime.parse(message['created_at'])
        : DateTime.now();
    final bool isCurrentUser = senderId == SupabaseService.currentUser?.id;
    
    // Formatage de la date
    final formattedDate = DateFormat('HH:mm').format(createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Avatar pour les autres utilisateurs
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1E3D54).withOpacity(0.7),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bulle de message
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF1E3D54)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar pour l'utilisateur courant
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 