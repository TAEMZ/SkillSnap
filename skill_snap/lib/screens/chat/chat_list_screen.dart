import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_screen.dart';
import '../chat/message_provider.dart';
import '../skills/data/conversation_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<String> _selectedConversations = [];
  String _filter = 'all'; // 'all', 'today', 'week', 'month', 'unread'
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          if (_showSearch) _buildSearchField(colorScheme),
          _buildFilterChips(colorScheme),
          Expanded(
            child:
                userId == null
                    ? _buildLoginPrompt()
                    : _buildConversationList(userId, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.filter_list, color: colorScheme.onPrimary),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title:
          _selectedConversations.isEmpty
              ? _showSearch
                  ? const SizedBox.shrink()
                  : const Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
              : Text('${_selectedConversations.length} selected'),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          onPressed:
              () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              }),
        ),
        if (_selectedConversations.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelectedConversations,
          ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                  : null,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged:
            (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    const filters = {
      'all': 'All',
      'unread': 'Unread',
      'today': 'Today',
      'week': 'This Week',
      'month': 'This Month',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children:
            filters.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: _filter == entry.key,
                  onSelected: (selected) => setState(() => _filter = entry.key),
                  selectedColor: colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        _filter == entry.key
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color:
                          _filter == entry.key
                              ? colorScheme.primary
                              : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Please log in to view messages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(String userId, ThemeData theme) {
    return StreamBuilder<List<Conversation>>(
      stream: _supabase
          .from('conversations_with_users')
          .stream(primaryKey: ['id'])
          .order('last_message_at', ascending: false)
          .map(
            (data) =>
                _filterConversations(data.map(Conversation.fromJson).toList()),
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _buildErrorState(snapshot.error.toString());
        if (!snapshot.hasData) return _buildLoadingState();

        final conversations = snapshot.data!;
        if (conversations.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(conversation, theme);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 120, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 200, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation by matching with someone',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    final now = DateTime.now();
    return conversations.where((conv) {
      // Apply search filter
      if (_searchQuery.isNotEmpty &&
          !conv.otherUserName.toLowerCase().contains(_searchQuery) &&
          !conv.lastMessage.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      // Apply time/unread filters
      switch (_filter) {
        case 'unread':
          return conv.unreadMessagesCount > 0;
        case 'today':
          return conv.lastMessageTime.isAfter(
            now.subtract(const Duration(days: 1)),
          );
        case 'week':
          return conv.lastMessageTime.isAfter(
            now.subtract(const Duration(days: 7)),
          );
        case 'month':
          return conv.lastMessageTime.isAfter(
            now.subtract(const Duration(days: 30)),
          );
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildConversationTile(Conversation conversation, ThemeData theme) {
    final isSelected = _selectedConversations.contains(conversation.id);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        final shouldDelete = await _showDeleteConfirmation(conversation);
        return shouldDelete; // Must return bool (true to dismiss, false to cancel)
      },
      onDismissed: (direction) async {
        final confirmed = await _showDeleteConfirmation(conversation);
        if (confirmed == true) {}

        // Delete from the database (Supabase or wherever you're storing them)
        await Supabase.instance.client
            .from('conversations')
            .delete()
            .eq('match_id', conversation.matchId);

        // Optionally show a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${conversation.otherUserName} dismissed')),
        );
      },

      child: InkWell(
        onLongPress: () => _toggleSelection(conversation.id),
        onTap: () {
          if (_selectedConversations.isNotEmpty) {
            _toggleSelection(conversation.id);
          } else {
            _navigateToChatScreen(conversation);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_selectedConversations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(conversation.id),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              _buildAvatar(conversation, colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUserName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'h:mm a',
                          ).format(conversation.lastMessageTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadMessagesCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.unreadMessagesCount.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Conversation conversation, ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.2),
                colorScheme.secondary.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child:
              conversation.otherUserAvatar != null
                  ? ClipOval(
                    child: Image.network(
                      conversation.otherUserAvatar!,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Center(
                    child: Text(
                      conversation.otherUserName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
        ),
        if (conversation.unreadMessagesCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                conversation.unreadMessagesCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Conversations'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildFilterOption('All Conversations', 'all'),
                  _buildFilterOption('Unread Only', 'unread'),
                  _buildFilterOption('Today', 'today'),
                  _buildFilterOption('This Week', 'week'),
                  _buildFilterOption('This Month', 'month'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _filter = result['value']);
    }
  }

  Widget _buildFilterOption(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Radio<String>(
        value: value,
        groupValue: _filter,
        onChanged: (val) => Navigator.pop(context, {'value': val}),
      ),
      onTap: () => Navigator.pop(context, {'value': value}),
    );
  }

  Future<bool?> _showDeleteConfirmation(Conversation conversation) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: Text(
              'Are you sure you want to delete the conversation with ${conversation.otherUserName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _toggleSelection(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  Future<void> _deleteSelectedConversations() async {
    final confirmed = await _showDeleteConfirmationForMultiple();
    if (confirmed != true) return;

    try {
      for (final id in _selectedConversations) {
        await _deleteConversation(id);
      }
      setState(() => _selectedConversations.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${_selectedConversations.length} conversations',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversations: $e')),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationForMultiple() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Conversations'),
            content: Text(
              'Are you sure you want to delete ${_selectedConversations.length} conversations?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      // Optimistically update the UI first
      setState(() {
        _selectedConversations.remove(conversationId);
      });

      // Then perform the actual deletion
      await _supabase.from('conversations').delete().eq('id', conversationId);

      // Refresh the unread count
      Provider.of<MessageProvider>(context, listen: false).loadUnreadCount();
    } catch (e) {
      // If deletion fails, show error and revert UI
      setState(() {
        if (!_selectedConversations.contains(conversationId)) {
          _selectedConversations.add(conversationId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversation: $e')),
      );
      rethrow;
    }
  }

  void _navigateToChatScreen(Conversation conversation) {
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
    ).then((_) {
      Provider.of<MessageProvider>(context, listen: false).loadUnreadCount();
    });
  }
}
