// import 'package:flutter/material.dart';
// import 'package:skill_snap/screens/skills/data/conversation_repository.dart';
// import 'package:timeago/timeago.dart' as timeago;
// import '../../services/superbase_service.dart';
// import '../../screens/skills/data/conversation_model.dart';
// import 'chat_screen.dart';

// class MessagesScreen extends StatefulWidget {
//   const MessagesScreen({super.key});

//   @override
//   State<MessagesScreen> createState() => _MessagesScreenState();
// }

// class _MessagesScreenState extends State<MessagesScreen> {
//   late Stream<List<Conversation>> _conversationsStream;
//   final String? userId = SupabaseService.client.auth.currentUser?.id;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (userId != null) {
//       _conversationsStream = ConversationRepository().getConversations(userId!);
//     }
//   }

//   Future<void> _refreshConversations() async {
//     if (userId == null) return;
//     setState(() {
//       _isLoading = true;
//       _conversationsStream = ConversationRepository().getConversations(userId!);
//     });
//     await Future.delayed(
//       const Duration(milliseconds: 500),
//     ); // Simulate network delay
//     if (mounted) setState(() => _isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (userId == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Messages',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//             ),
//           ),
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.black, Colors.greenAccent, Colors.black87],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 stops: [0.0, 0.5, 1.0],
//               ),
//             ),
//           ),
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.black,
//                 Colors.grey,
//                 Colors.white12,
//                 Colors.greenAccent,
//               ],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               stops: [0.0, 0.4, 0.8, 1.0],
//             ),
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       colors: [
//                         Colors.greenAccent.withOpacity(0.3),
//                         Colors.grey[850]!,
//                       ],
//                       center: Alignment.center,
//                       radius: 0.8,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.lock_outline,
//                     color: Colors.white70,
//                     size: 48,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Please log in to view messages',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 18,
//                     fontStyle: FontStyle.italic,
//                     shadows: [Shadow(color: Colors.greenAccent, blurRadius: 2)],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.transparent,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: const BorderSide(
//                         color: Colors.greenAccent,
//                         width: 2,
//                       ),
//                     ),
//                     elevation: 4,
//                     shadowColor: Colors.greenAccent.withOpacity(0.5),
//                   ),
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/login');
//                   },
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.greenAccent, Colors.black87],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     child: const Text(
//                       'Log In',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Messages',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//             shadows: [Shadow(color: Colors.greenAccent, blurRadius: 2)],
//           ),
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.black, Colors.greenAccent, Colors.black87],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               stops: [0.0, 0.5, 1.0],
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Container(
//               padding: const EdgeInsets.all(6),
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: RadialGradient(
//                   colors: [Colors.greenAccent, Colors.black87],
//                   center: Alignment.center,
//                   radius: 0.8,
//                 ),
//               ),
//               child: const Icon(Icons.refresh, color: Colors.white, size: 20),
//             ),
//             onPressed: _refreshConversations,
//             tooltip: 'Refresh Messages',
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.black,
//               Colors.grey,
//               Colors.white12,
//               Colors.greenAccent,
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             stops: [0.0, 0.4, 0.8, 1.0],
//           ),
//         ),
//         child: RefreshIndicator(
//           onRefresh: _refreshConversations,
//           color: Colors.greenAccent,
//           backgroundColor: Colors.black87,
//           child:
//               _isLoading
//                   ? Center(
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: RadialGradient(
//                           colors: [
//                             Colors.greenAccent.withOpacity(0.3),
//                             Colors.black87,
//                           ],
//                           center: Alignment.center,
//                           radius: 0.8,
//                         ),
//                       ),
//                       child: const CircularProgressIndicator(
//                         color: Colors.greenAccent,
//                       ),
//                     ),
//                   )
//                   : StreamBuilder<List<Conversation>>(
//                     stream: _conversationsStream,
//                     builder: (context, snapshot) {
//                       if (snapshot.hasError) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   gradient: RadialGradient(
//                                     colors: [
//                                       Colors.redAccent.withOpacity(0.3),
//                                       Colors.grey[850]!,
//                                     ],
//                                     center: Alignment.center,
//                                     radius: 0.8,
//                                   ),
//                                 ),
//                                 child: const Icon(
//                                   Icons.error_outline,
//                                   color: Colors.redAccent,
//                                   size: 48,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Error: ${snapshot.error}',
//                                 style: const TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 18,
//                                   shadows: [
//                                     Shadow(
//                                       color: Colors.redAccent,
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 16),
//                               ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.transparent,
//                                   foregroundColor: Colors.white,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 24,
//                                     vertical: 12,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     side: const BorderSide(
//                                       color: Colors.greenAccent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                   elevation: 4,
//                                   shadowColor: Colors.greenAccent.withOpacity(
//                                     0.5,
//                                   ),
//                                 ),
//                                 onPressed: _refreshConversations,
//                                 child: Container(
//                                   decoration: const BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [
//                                         Colors.greenAccent,
//                                         Colors.black87,
//                                       ],
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                     ),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                   child: const Text(
//                                     'Retry',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                       if (!snapshot.hasData) {
//                         return Center(
//                           child: Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               gradient: RadialGradient(
//                                 colors: [
//                                   Colors.greenAccent.withOpacity(0.3),
//                                   Colors.black87,
//                                 ],
//                                 center: Alignment.center,
//                                 radius: 0.8,
//                               ),
//                             ),
//                             child: const CircularProgressIndicator(
//                               color: Colors.greenAccent,
//                             ),
//                           ),
//                         );
//                       }
//                       final conversations = snapshot.data!;
//                       if (conversations.isEmpty) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   gradient: RadialGradient(
//                                     colors: [
//                                       Colors.greenAccent.withOpacity(0.3),
//                                       Colors.grey[850]!,
//                                     ],
//                                     center: Alignment.center,
//                                     radius: 0.8,
//                                   ),
//                                 ),
//                                 child: const Icon(
//                                   Icons.message_outlined,
//                                   color: Colors.white70,
//                                   size: 48,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               const Text(
//                                 'No messages yet',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 18,
//                                   fontStyle: FontStyle.italic,
//                                   shadows: [
//                                     Shadow(
//                                       color: Colors.greenAccent,
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Start a conversation from a skill!',
//                                 style: Theme.of(
//                                   context,
//                                 ).textTheme.bodySmall!.copyWith(
//                                   color: Colors.white60,
//                                   shadows: const [
//                                     Shadow(
//                                       color: Colors.greenAccent,
//                                       blurRadius: 1,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }

//                       return ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: conversations.length,
//                         itemBuilder: (context, index) {
//                           final conversation = conversations[index];
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             child: Card(
//                               elevation: 8,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Colors.black87,
//                                       Colors.grey[850]!,
//                                       Colors.greenAccent.withOpacity(0.2),
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                     stops: const [0.0, 0.7, 1.0],
//                                   ),
//                                   borderRadius: BorderRadius.circular(16),
//                                   border: Border.all(
//                                     color: Colors.greenAccent.withOpacity(0.4),
//                                     width: 1.5,
//                                   ),
//                                 ),
//                                 child: ListTile(
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 12,
//                                   ),
//                                   leading: CircleAvatar(
//                                     radius: 28,
//                                     backgroundColor: Colors.transparent,
//                                     backgroundImage:
//                                         conversation.otherUserAvatar != null
//                                             ? NetworkImage(
//                                               conversation.otherUserAvatar!,
//                                             )
//                                             : null,
//                                     child:
//                                         conversation.otherUserAvatar == null
//                                             ? Container(
//                                               decoration: BoxDecoration(
//                                                 shape: BoxShape.circle,
//                                                 gradient: RadialGradient(
//                                                   colors: [
//                                                     Colors.greenAccent,
//                                                     Colors.grey[700]!,
//                                                   ],
//                                                   center: Alignment.center,
//                                                   radius: 0.8,
//                                                 ),
//                                               ),
//                                               child: const Icon(
//                                                 Icons.person,
//                                                 color: Colors.white70,
//                                                 size: 28,
//                                               ),
//                                             )
//                                             : null,
//                                   ),
//                                   title: Text(
//                                     conversation.otherUserName,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 18,
//                                       shadows: [
//                                         Shadow(
//                                           color: Colors.greenAccent,
//                                           blurRadius: 2,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   subtitle: Text(
//                                     conversation.lastMessage,
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: const TextStyle(
//                                       color: Colors.white70,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   trailing: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           gradient: LinearGradient(
//                                             colors: [
//                                               Colors.greenAccent.withOpacity(
//                                                 0.3,
//                                               ),
//                                               Colors.black87,
//                                             ],
//                                             begin: Alignment.topLeft,
//                                             end: Alignment.bottomRight,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           timeago.format(
//                                             conversation.lastMessageTime,
//                                           ),
//                                           style: const TextStyle(
//                                             color: Colors.white60,
//                                             fontSize: 12,
//                                             shadows: [
//                                               Shadow(
//                                                 color: Colors.greenAccent,
//                                                 blurRadius: 1,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (_) => ChatScreen(
//                                               conversationId: conversation.id,
//                                               otherUserId:
//                                                   conversation.otherUserId,
//                                               otherUserName:
//                                                   conversation.otherUserName,
//                                               otherUserAvatar:
//                                                   conversation.otherUserAvatar,
//                                             ),
//                                       ),
//                                     );
//                                   },
//                                   splashColor: Colors.greenAccent.withOpacity(
//                                     0.5,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.transparent,
//         shape: const CircleBorder(),
//         onPressed: _refreshConversations,
//         tooltip: 'Refresh Messages',
//         child: Container(
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: RadialGradient(
//               colors: [Colors.greenAccent, Colors.black87],
//               center: Alignment.center,
//               radius: 0.8,
//             ),
//           ),
//           child: const Icon(Icons.refresh, color: Colors.white, size: 28),
//         ),
//       ),
//     );
//   }
// }
