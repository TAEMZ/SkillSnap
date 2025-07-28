import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/superbase_service.dart';
import '../../screens/skills/data/skill_match_model.dart';
import '../../screens/skills/data/sklil_repository.dart';
import '../chat/chat_screen.dart';
import '../../screens/skills/data/conversation_repository.dart';

class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  late Future<List<SkillMatch>> _pendingRequests;

  @override
  void initState() {
    super.initState();
    final userId = SupabaseService.client.auth.currentUser?.id;
    _pendingRequests = SkillRepository().getPendingRequests(userId!);
  }

  Future<void> _refreshRequests() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    setState(() {
      _pendingRequests = SkillRepository().getPendingRequests(userId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRequests,
          ),
        ],
      ),
      body: FutureBuilder<List<SkillMatch>>(
        future: _pendingRequests,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final request = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        request.requesterAvatar != null
                            ? NetworkImage(request.requesterAvatar!)
                            : null,
                    child:
                        request.requesterAvatar == null
                            ? const Icon(Icons.person)
                            : null,
                  ),
                  title: Text(request.requesterName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.message),
                      if (request.offerSkillName != null)
                        Text(
                          'Offering: ${request.offerSkillName}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeago.format(request.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      if (request.status == 'pending')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed:
                                  () => _respondToRequest(request.id, false),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => _respondToRequest(request.id, true),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // In MatchRequestsScreen's _respondToRequest method
  // In match_requests_screen.dart, update the _respondToRequest method:
  Future<void> _respondToRequest(String matchId, bool accept) async {
    try {
      await SkillRepository().updateMatchStatus(
        matchId,
        accept ? 'accepted' : 'rejected',
      );

      if (accept && mounted) {
        final request = (await _pendingRequests).firstWhere(
          (r) => r.id == matchId,
        );

        // Use ConversationRepository instead of MessageRepository
        final conversationId = await ConversationRepository()
            .createConversation(
              matchId: matchId,
              user1: request.requesterId,
              user2: request.providerId,
            );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ChatScreen(
                conversationId: conversationId,
                otherUserId: request.requesterId,
                otherUserName: request.requesterName,
                otherUserAvatar: request.requesterAvatar,
              );
            },
          ),
        );
      }

      _refreshRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
