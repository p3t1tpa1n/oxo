import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  static final _encryptionKey = encrypt.Key.fromUtf8('12345678901234567890123456789012');
  RealtimeChannel? _channel;

  String _encryptMessage(String message) {
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final encrypted = encrypter.encrypt(message, iv: iv);
      final combined = {
        'iv': base64Encode(iv.bytes),
        'content': base64Encode(encrypted.bytes)
      };
      return json.encode(combined);
    } catch (e) {
      debugPrint('Erreur de chiffrement: $e');
      return message;
    }
  }

  String _decryptMessage(String encryptedMessage) {
    try {
      // Vérifier si le message est au format JSON (nouveau format)
      try {
        final Map<String, dynamic> combined = json.decode(encryptedMessage);
        if (combined.containsKey('iv') && combined.containsKey('content')) {
          final iv = encrypt.IV(base64Decode(combined['iv']));
          final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
          return encrypter.decrypt(encrypt.Encrypted(base64Decode(combined['content'])), iv: iv);
        }
      } catch (jsonError) {
        debugPrint('Message au format non-JSON: $jsonError');
      }
      
      // Essayer de déchiffrer comme un message encodé en base64 (format intermédiaire)
      try {
        final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
        return encrypter.decrypt64(encryptedMessage);
      } catch (base64Error) {
        debugPrint('Message non encodé en base64: $base64Error');
      }
      
      // Si aucun déchiffrement ne fonctionne, retourner le message tel quel
      return encryptedMessage;
      
    } catch (e) {
      debugPrint('Erreur générale de déchiffrement: $e');
      return encryptedMessage;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeRealtimeSubscription();
  }

  void _initializeRealtimeSubscription() {
    _channel = SupabaseService.client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: null,
          ),
          callback: (payload) {
            if (!mounted) return;
            _handleRealtimeMessage(payload.newRecord);
          },
        )
        .subscribe((status, [err]) {
          if (err != null) {
            debugPrint('Erreur de souscription Realtime: $err');
          } else {
            debugPrint('Souscription Realtime réussie avec statut: $status');
          }
        });
  }

  void _handleRealtimeMessage(Map<String, dynamic> newMessage) async {
    if (!mounted) return;

    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select('email, role')
          .eq('id', newMessage['sender_id'])
          .single();

      final decryptedContent = _decryptMessage(newMessage['content'] as String);

      final messageWithProfile = {
        ...newMessage,
        'content': decryptedContent,
        'profiles': profile,
      };

      setState(() {
        _messages.insert(0, messageWithProfile);
      });
    } catch (e) {
      debugPrint('Erreur lors du traitement du message temps réel: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .filter('receiver_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(50);

      final messagesWithProfiles = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((message) async {
          try {
            final profile = await SupabaseService.client
                .from('profiles')
                .select('email, role')
                .eq('id', message['sender_id'])
                .single();

            final decryptedContent = _decryptMessage(message['content'] as String);

            return {
              ...message,
              'content': decryptedContent,
              'profiles': profile
            };
          } catch (e) {
            return {
              ...message,
              'profiles': {'email': 'Utilisateur inconnu', 'role': 'unknown'}
            };
          }
        })
      );

      if (mounted) {
        setState(() {
          _messages = messagesWithProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final messageContent = _messageController.text.trim();
      _messageController.clear();

      final encryptedContent = _encryptMessage(messageContent);

      final response = await SupabaseService.client.from('messages').insert({
        'content': encryptedContent,
        'sender_id': SupabaseService.currentUser!.id,
        'receiver_id': null,
        'is_read': false,
      }).select().single();

      // Ajouter le message localement immédiatement
      final profile = await SupabaseService.client
          .from('profiles')
          .select('email, role')
          .eq('id', SupabaseService.currentUser!.id)
          .single();

      final newMessage = {
        ...response,
        'content': messageContent, // On utilise le contenu non chiffré
        'profiles': profile,
      };

      if (mounted) {
        setState(() {
          _messages.insert(0, newMessage);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1784af),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.message, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Icon(Icons.lock, size: 14, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['sender_id'] == SupabaseService.currentUser!.id;
                final senderProfile = message['profiles'];
                final senderEmail = senderProfile != null ? senderProfile['email'] : 'Utilisateur inconnu';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderEmail,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? const Color(0xFF1784af)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message['content'],
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(
                                      DateTime.parse(message['created_at']),
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCurrentUser
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.lock,
                                    size: 10,
                                    color: isCurrentUser
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1784af)),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    super.dispose();
  }
} 