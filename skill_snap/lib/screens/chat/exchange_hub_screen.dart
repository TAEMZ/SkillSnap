import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';

class ExchangeHubScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? skillOffered;
  final String? skillRequested;
  final bool isTeacher;

  const ExchangeHubScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.skillOffered,
    this.skillRequested,
    this.isTeacher = false,
  });

  @override
  State<ExchangeHubScreen> createState() => _ExchangeHubScreenState();
}

class _ExchangeHubScreenState extends State<ExchangeHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 24),
                        _buildSkillExchangeInfo(),
                        const SizedBox(height: 32),
                        _buildActionCards(),
                        const SizedBox(height: 24),
                        _buildTipsCard(),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.purple[900]!.withOpacity(0.8),
                Colors.blue[900]!.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  widget.isTeacher ? 'Learning from you' : 'Teaching you',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                ? Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[900]!.withOpacity(0.8),
            Colors.blue[900]!.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            widget.isTeacher ? Icons.school : Icons.lightbulb,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isTeacher ? 'Ready to Teach!' : 'Ready to Learn!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTeacher
                ? 'Share your knowledge and help ${widget.otherUserName.split(' ').first} grow'
                : 'Learn something amazing from ${widget.otherUserName.split(' ').first}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillExchangeInfo() {
    if (widget.skillOffered == null && widget.skillRequested == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.orange[400], size: 24),
              const SizedBox(width: 12),
              Text(
                'Skill Exchange',
                style: TextStyle(
                  color: Colors.orange[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.skillRequested != null) ...[
            _buildSkillItem(
              icon: Icons.school,
              label: widget.isTeacher ? 'You\'re teaching' : 'You\'re learning',
              skill: widget.skillRequested!,
              color: Colors.blue[400]!,
            ),
            if (widget.skillOffered != null) const SizedBox(height: 12),
          ],
          if (widget.skillOffered != null) ...[
            _buildSkillItem(
              icon: Icons.lightbulb,
              label:
                  widget.isTeacher ? 'They\'re offering' : 'You\'re offering',
              skill: widget.skillOffered!,
              color: Colors.green[400]!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillItem({
    required IconData icon,
    required String label,
    required String skill,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                skill,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.chat_bubble_outline,
          title: "Start Chatting",
          subtitle:
              "Send messages, share files, and discuss your learning goals",
          gradient: [Colors.blue[800]!, Colors.blue[600]!],
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChatScreen(
                      conversationId: widget.conversationId,
                      otherUserId: widget.otherUserId,
                      otherUserName: widget.otherUserName,
                      otherUserAvatar: widget.otherUserAvatar,
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.video_call,
          title: "Video Call",
          subtitle: "Meet face-to-face for better learning experience",
          gradient: [Colors.green[800]!, Colors.green[600]!],
          onTap: () {
            HapticFeedback.lightImpact();
            _startVideoCall();
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.screen_share,
          title: "Screen Share",
          subtitle: "Share your screen for hands-on learning",
          gradient: [Colors.purple[800]!, Colors.purple[600]!],
          onTap: () {
            HapticFeedback.lightImpact();
            _startScreenShare();
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withOpacity(0.8)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient.first.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.yellow[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Tips for Success',
                style: TextStyle(
                  color: Colors.yellow[600],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._getTips()
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.yellow[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  List<String> _getTips() {
    if (widget.isTeacher) {
      return [
        'Be patient and encouraging with your student',
        'Break down complex concepts into simple steps',
        'Use practical examples and hands-on exercises',
        'Ask questions to ensure understanding',
        'Provide constructive feedback and celebrate progress',
      ];
    } else {
      return [
        'Come prepared with specific questions',
        'Take notes during your learning sessions',
        'Practice what you learn between sessions',
        'Don\'t hesitate to ask for clarification',
        'Show appreciation for your teacher\'s time',
      ];
    }
  }

  void _startVideoCall() {
    final meetLink = "https://meet.jit.si/skillsnap-${widget.conversationId}";
    launchUrl(Uri.parse(meetLink));
  }

  void _startScreenShare() {
    final meetLink =
        "https://meet.jit.si/skillsnap-screen-${widget.conversationId}";
    launchUrl(Uri.parse(meetLink));
  }
}
