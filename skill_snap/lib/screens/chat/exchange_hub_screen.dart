class ExchangeHubScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ExchangeHubScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ExchangeHubScreen> createState() => _ExchangeHubScreenState();
}

class _ExchangeHubScreenState extends State<ExchangeHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.otherUserAvatar != null
                      ? NetworkImage(widget.otherUserAvatar!)
                      : null,
              child:
                  widget.otherUserAvatar == null
                      ? const Icon(Icons.person)
                      : null,
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat)),
            Tab(icon: Icon(Icons.attach_file)),
            Tab(icon: Icon(Icons.video_call)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Existing ChatScreen as first tab
          ChatScreen(
            conversationId: widget.conversationId,
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName,
            otherUserAvatar: widget.otherUserAvatar,
          ),

          // Files Tab
          _buildFilesTab(),

          // Video Call Tab
          _buildCallTab(),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return Center(child: Text("Files will appear here")); // Placeholder
  }

  Widget _buildCallTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Your meeting room is ready"),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final meetLink =
                  "https://meet.jit.si/skillsnap-${widget.conversationId}";
              Clipboard.setData(ClipboardData(text: meetLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard")),
              );
              launchUrl(Uri.parse(meetLink));
            },
            child: const Text("Start Video Call"),
          ),
        ],
      ),
    );
  }
}
