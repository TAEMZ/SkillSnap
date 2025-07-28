import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_snap/screens/skills/data/conversation_repository.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/superbase_service.dart';
import '../../screens/skills/data/conversation_model.dart';
import '../../screens/skills/data/message_repository.dart';
import 'chat_screen.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Stream<List<Conversation>> _conversationsStream;
  final String? userId = SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _conversationsStream = ConversationRepository().getConversations(userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('Please log in to view messages'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final conversation = snapshot.data![index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      conversation.otherUserAvatar != null
                          ? NetworkImage(conversation.otherUserAvatar!)
                          : null,
                  child:
                      conversation.otherUserAvatar == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                title: Text(conversation.otherUserName),
                subtitle: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(timeago.format(conversation.lastMessageTime)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            conversationId: conversation.id,
                            otherUserId: conversation.otherUserId,
                            otherUserName: conversation.otherUserName,
                            otherUserAvatar: conversation.otherUserAvatar,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
