import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../config/app_theme.dart';
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
      await _messagingService.markMessagesAsRead(widget.conversationId);

      _messagesSubscription = _messagingService
          .getMessagesStream(widget.conversationId)
          .listen(
            (messages) {
              if (mounted) {
                setState(() {
                  _messages = messages;
                  _isLoading = false;
                });
                _messagingService.markMessagesAsRead(widget.conversationId);
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

    setState(() { _isSending = true; });

    try {
      final success = await _messagingService.sendMessage(widget.conversationId, message);
      if (success) {
        _messageController.clear();
      } else {
        if (mounted) _showError('Échec de l\'envoi du message');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      if (mounted) _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() { _isSending = false; });
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(msg),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
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
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        title: Text(widget.conversationName),
        backgroundColor: AppTheme.colors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _messagingService.loadMessages(widget.conversationId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.colors.primary, strokeWidth: 2))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.colors.error),
                            const SizedBox(height: 16),
                            Text('Erreur', style: AppTheme.typography.h3),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(_error!, style: AppTheme.typography.bodyMedium, textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _initMessages,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary),
                              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.colors.textSecondary),
                                const SizedBox(height: 16),
                                Text('Aucun message', style: AppTheme.typography.h3),
                                const SizedBox(height: 8),
                                Text(
                                  'Envoyez le premier message pour\ncommencer la conversation',
                                  style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.colors.surface,
              border: Border(top: BorderSide(color: AppTheme.colors.border, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.colors.inputBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: AppTheme.typography.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: AppTheme.colors.primary, shape: BoxShape.circle),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
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
    final formattedDate = DateFormat('HH:mm').format(createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.colors.textSecondary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.colors.primary : AppTheme.colors.inputBackground,
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
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: isCurrentUser ? Colors.white : AppTheme.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: AppTheme.typography.caption.copyWith(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.colors.primary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
