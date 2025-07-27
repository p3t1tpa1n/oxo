import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../services/messaging_service.dart';

class IOSConversationDetailPage extends StatefulWidget {
  final String conversationId;
  final String conversationName;
  final bool isGroup;

  const IOSConversationDetailPage({
    super.key,
    required this.conversationId,
    required this.conversationName,
    required this.isGroup,
  });

  @override
  State<IOSConversationDetailPage> createState() => _IOSConversationDetailPageState();
}

class _IOSConversationDetailPageState extends State<IOSConversationDetailPage> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
                
                // Défiler vers le bas automatiquement
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
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
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Erreur'),
              content: const Text('Échec de l\'envoi du message'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
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
    _scrollController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: widget.conversationName,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await _messagingService.loadMessages(widget.conversationId);
            },
            child: const Icon(
              CupertinoIcons.refresh,
              color: IOSTheme.primaryBlue,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 64,
                              color: IOSTheme.systemRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur',
                              style: IOSTheme.title2,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _error!,
                                style: IOSTheme.body,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            CupertinoButton.filled(
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
                              children: [
                                const Icon(
                                  CupertinoIcons.chat_bubble,
                                  size: 64,
                                  color: IOSTheme.systemGray3,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun message',
                                  style: IOSTheme.title2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Envoyez le premier message pour\ncommencer la conversation',
                                  style: IOSTheme.footnote,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessageBubble(_messages[index]);
                            },
                          ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: IOSTheme.systemBackground,
              border: Border(
                top: BorderSide(
                  color: IOSTheme.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: IOSTheme.systemGray6,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CupertinoTextField(
                        controller: _messageController,
                        placeholder: 'Message...',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: IOSTheme.body,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: IOSTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CupertinoActivityIndicator(color: Colors.white),
                            )
                          : const Icon(
                              CupertinoIcons.paperplane_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Avatar pour les autres utilisateurs
            CircleAvatar(
              radius: 16,
              backgroundColor: IOSTheme.systemGray,
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bulle de message
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? IOSTheme.primaryBlue
                    : IOSTheme.systemGray6,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: IOSTheme.body.copyWith(
                      color: isCurrentUser ? Colors.white : IOSTheme.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: IOSTheme.caption2.copyWith(
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : IOSTheme.labelTertiary,
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
              backgroundColor: IOSTheme.primaryBlue,
              child: const Icon(
                CupertinoIcons.person_fill,
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