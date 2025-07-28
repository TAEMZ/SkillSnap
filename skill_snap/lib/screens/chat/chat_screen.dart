import 'package:flutter/material.dart';
import '../skills/data/conversation_model.dart';
import '../skills/data/message_repository.dart';
import '../../services/superbase_service.dart';
import '../chat/message_bubble.dart';
import '.././skills/data/message_model.dart';
import '../skills/data/conversation_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late Stream<List<Message>> _messagesStream;
  Conversation? _conversation;
  @override
  void initState() {
    super.initState();
    _loadConversation();
    _messagesStream = MessageRepository().getMessages(widget.conversationId);
    _markMessagesAsRead();
  }

  Future<void> _loadConversation() async {
    try {
      final conversation = await ConversationRepository().getConversationById(
        widget.conversationId,
      );

      if (mounted) {
        setState(() {
          _conversation = conversation;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await MessageRepository().markMessagesAsRead(
      conversationId: widget.conversationId,
      userId: SupabaseService.client.auth.currentUser!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_conversation != null)
              CircleAvatar(
                backgroundImage:
                    _conversation!.otherUserAvatar != null
                        ? NetworkImage(_conversation!.otherUserAvatar!)
                        : null,
                child:
                    _conversation!.otherUserAvatar == null
                        ? const Icon(Icons.person)
                        : null,
              ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    return MessageBubble(
                      message: message,
                      isMe:
                          message.senderId ==
                          SupabaseService.client.auth.currentUser!.id,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await MessageRepository().sendMessage(
      conversationId: widget.conversationId,
      senderId: SupabaseService.client.auth.currentUser!.id,
      content: _messageController.text,
    );
    _messageController.clear();
  }
}
