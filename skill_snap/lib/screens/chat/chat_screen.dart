import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../services/superbase_service.dart';
import '../skills/data/message_model.dart';
import '../skills/data/message_repository.dart';
import './message_bubble.dart';
import '../../services/file_upload_service.dart';
import '../../services/voice_recorder_service.dart';
import 'dart:async';

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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  late Timer _recordingTimer;
  late Stream<List<Message>> _messagesStream;
  bool _showEmojiPicker = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _messagesStream = MessageRepository().getMessages(widget.conversationId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    await MessageRepository().sendMessage(
      conversationId: widget.conversationId,
      senderId: SupabaseService.client.auth.currentUser!.id,
      content: _messageController.text,
    );
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendFile() async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Uploading file...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    final result = await FileUploadService.uploadFile();
    Navigator.pop(context);

    if (result != null && result.url != null) {
      final prefix = result.isImage ? "[IMAGE]" : "[FILE]";
      await MessageRepository().sendMessage(
        conversationId: widget.conversationId,
        senderId: SupabaseService.client.auth.currentUser!.id,
        content: '$prefix ${result.url}',
      );
    }
  }

  void _toggleEmojiPicker() {
    HapticFeedback.lightImpact();
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _startRecording() async {
    HapticFeedback.mediumImpact();
    final success = await VoiceRecorderService.startRecording();
    if (success && mounted) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
    }
  }

  void _stopRecording() async {
    HapticFeedback.heavyImpact();
    _recordingTimer.cancel();
    final result = await VoiceRecorderService.stopRecording();

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[850],
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              const Text(
                'Uploading voice message...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(minutes: 1),
        ),
      );

      final uploadResult = await FileUploadService.uploadVoiceFile(result.path);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (uploadResult != null && uploadResult.url != null) {
        await MessageRepository().sendMessage(
          conversationId: widget.conversationId,
          senderId: SupabaseService.client.auth.currentUser!.id,
          content: '[VOICE] ${uploadResult.url}',
        );
      }
    }

    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  void _cancelRecording() async {
    HapticFeedback.lightImpact();
    _recordingTimer.cancel();
    await VoiceRecorderService.cancelRecording();
    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey, Colors.white12],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildMessagesList()),
            if (_showEmojiPicker) _buildEmojiPicker(),
            if (_isRecording) _buildRecordingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[700],
                      backgroundImage:
                          widget.otherUserAvatar != null
                              ? NetworkImage(widget.otherUserAvatar!)
                              : null,
                      child:
                          widget.otherUserAvatar == null
                              ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              )
                              : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.video_call, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final meetLink =
                      "https://meet.jit.si/skillsnap-${widget.conversationId}";
                  launchUrl(Uri.parse(meetLink));
                },
                tooltip: 'Start Video Call',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
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
          ),
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
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
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
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
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
            'Loading messages...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _messageController.text += emoji.emoji;
        },
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 32,
            backgroundColor: Colors.grey[900]!,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[800]!, Colors.red[600]!]),
        border: Border(top: BorderSide(color: Colors.red[400]!)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Recording: ${_formatDuration(_recordingDuration)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildInputButton(
            icon: Icons.attach_file,
            onPressed: _sendFile,
            tooltip: 'Attach File',
          ),
          const SizedBox(width: 8),
          _buildInputButton(
            icon: Icons.emoji_emotions,
            onPressed: _toggleEmojiPicker,
            tooltip: 'Emojis',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildInputButton(
            icon: _isRecording ? Icons.stop : Icons.mic,
            onPressed: _isRecording ? _stopRecording : _startRecording,
            tooltip: _isRecording ? 'Stop Recording' : 'Voice Message',
            color: _isRecording ? Colors.red : Colors.greenAccent,
          ),
          const SizedBox(width: 8),
          _buildInputButton(
            icon: Icons.send,
            onPressed: _sendMessage,
            tooltip: 'Send',
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildInputButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? Colors.grey[700])!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.grey[700])!.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color != null ? Colors.black : Colors.white,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
