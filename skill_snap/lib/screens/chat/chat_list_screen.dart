import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<String> _selectedConversations = [];
  String _filter = 'all';
  String _searchQuery = '';
  bool _showSearch = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_showSearch) _buildSearchField(),
          _buildFilterChips(),
          userId == null
              ? SliverFillRemaining(child: _buildLoginPrompt())
              : _buildConversationList(userId),
        ],
      ),
      floatingActionButton: _buildFilterFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title:
            _selectedConversations.isEmpty
                ? _showSearch
                    ? const SizedBox.shrink()
                    : const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                : Text(
                  '${_selectedConversations.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            });
          },
        ),
        if (_selectedConversations.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _deleteSelectedConversations();
            },
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.greenAccent),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged:
                (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = {
      'all': 'All',
      'unread': 'Unread',
      'today': 'Today',
      'week': 'This Week',
      'month': 'This Month',
    };

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final entry = filters.entries.elementAt(index);
              final isSelected = _filter == entry.key;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = entry.key);
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.greenAccent.withOpacity(0.2),
                  checkmarkColor: Colors.greenAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.grey[300],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isSelected ? Colors.greenAccent : Colors.grey[600]!,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view messages',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(String userId) {
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
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }
        if (!snapshot.hasData) {
          return SliverFillRemaining(child: _buildLoadingState());
        }

        final conversations = snapshot.data!;
        if (conversations.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final conversation = conversations[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.3 + (index * 0.1)),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(index * 0.1, 1.0, curve: Curves.elasticOut),
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildConversationTile(conversation),
              ),
            );
          }, childCount: conversations.length),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red[900]!.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red[400]!, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading conversations...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start connecting with others through skill matches',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showFilterDialog();
            },
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            child: const Icon(Icons.filter_list),
          ),
        );
      },
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    final now = DateTime.now();
    return conversations.where((conv) {
      if (_searchQuery.isNotEmpty &&
          !conv.otherUserName.toLowerCase().contains(_searchQuery) &&
          !conv.lastMessage.toLowerCase().contains(_searchQuery)) {
        return false;
      }

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

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = _selectedConversations.contains(conversation.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient:
            isSelected
                ? LinearGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0.2),
                    Colors.green.withOpacity(0.2),
                  ],
                )
                : LinearGradient(
                  colors: [Colors.grey[900]!, Colors.grey[850]!],
                ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.greenAccent : Colors.grey[700]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(conversation.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[800]!, Colors.red[600]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.heavyImpact();
          return await _showDeleteConfirmation(conversation);
        },
        onDismissed: (direction) async {
          await _deleteConversation(conversation.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Conversation with ${conversation.otherUserName} deleted',
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _toggleSelection(conversation.id);
            },
            onTap: () {
              HapticFeedback.lightImpact();
              if (_selectedConversations.isNotEmpty) {
                _toggleSelection(conversation.id);
              } else {
                _navigateToChatScreen(conversation);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_selectedConversations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.greenAccent
                                  : Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : Icons.check_box_outline_blank,
                          color: isSelected ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  _buildAvatar(conversation),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(conversation.lastMessageTime),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
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
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.unreadMessagesCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  conversation.unreadMessagesCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildAvatar(Conversation conversation) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[700],
            backgroundImage:
                conversation.otherUserAvatar != null
                    ? NetworkImage(conversation.otherUserAvatar!)
                    : null,
            child:
                conversation.otherUserAvatar == null
                    ? Text(
                      conversation.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
        ),
        if (conversation.unreadMessagesCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                conversation.unreadMessagesCount > 9
                    ? '9+'
                    : conversation.unreadMessagesCount.toString(),
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
    const filters = {
      'all': 'All Conversations',
      'unread': 'Unread Only',
      'today': 'Today',
      'week': 'This Week',
      'month': 'This Month',
    };

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.greenAccent),
                const SizedBox(width: 12),
                const Text(
                  'Filter Conversations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    filters.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _filter == entry.key
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _filter == entry.key
                                    ? Colors.greenAccent
                                    : Colors.grey[600]!,
                          ),
                        ),
                        child: RadioListTile<String>(
                          value: entry.key,
                          groupValue: _filter,
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              color:
                                  _filter == entry.key
                                      ? Colors.greenAccent
                                      : Colors.white70,
                              fontWeight:
                                  _filter == entry.key
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _filter = val!);
                            Navigator.pop(context);
                          },
                          activeColor: Colors.greenAccent,
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showDeleteConfirmation(Conversation conversation) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[400]),
                const SizedBox(width: 12),
                const Text(
                  'Delete Conversation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete the conversation with ${conversation.otherUserName}? This action cannot be undone.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
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
      final count = _selectedConversations.length;
      setState(() => _selectedConversations.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Deleted $count conversations'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error deleting conversations: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationForMultiple() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[400]),
                const SizedBox(width: 12),
                const Text(
                  'Delete Conversations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete ${_selectedConversations.length} conversations? This action cannot be undone.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      setState(() {
        _selectedConversations.remove(conversationId);
      });

      await _supabase.from('conversations').delete().eq('id', conversationId);
      Provider.of<MessageProvider>(context, listen: false).loadUnreadCount();
    } catch (e) {
      setState(() {
        if (!_selectedConversations.contains(conversationId)) {
          _selectedConversations.add(conversationId);
        }
      });
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
