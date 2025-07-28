import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/skill_model.dart';
import '../data/rating_model.dart';
import '../../../services/superbase_service.dart';
import '../data/sklil_repository.dart';
import '../data/skill_match_model.dart';
import '../../profile/profile_repository.dart';
import '../../profile/profile_screen.dart';
import '../../chat/chat_screen.dart';
import '../data/conversation_repository.dart';

class SkillDetailScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailScreen({super.key, required this.skill});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  late Future<List<Rating>> _ratingsFuture;
  final _ratingController = TextEditingController();
  int _userRating = 0;
  bool _isSubmittingRating = false;
  String? _selectedSkillName;

  @override
  void initState() {
    super.initState();
    _ratingsFuture = _fetchRatings();
    timeago.setLocaleMessages('en', timeago.EnMessages());
  }

  Future<List<Rating>> _fetchRatings() async {
    try {
      return await SkillRepository().getSkillRatings(widget.skill.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ratings: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshRatings() async {
    setState(() {
      _ratingsFuture = _fetchRatings();
    });
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmittingRating = true);

    try {
      await SkillRepository().addRating(
        skillId: widget.skill.id,
        toUser: widget.skill.userId,
        rating: _userRating,
        feedback:
            _ratingController.text.isNotEmpty ? _ratingController.text : null,
      );

      _ratingController.clear();
      _userRating = 0;
      await _refreshRatings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00796B);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Skill Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeaderImage()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkillTypeChip(),
                  const SizedBox(height: 20),
                  _buildSkillTitle(),
                  const SizedBox(height: 16),
                  _buildUserInfo(),
                  const SizedBox(height: 24),
                  if (widget.skill.description != null) _buildDescription(),
                  if (widget.skill.evidenceUrls?.isNotEmpty ?? false)
                    _buildEvidenceSection(),
                  _buildMatchSection(),
                  _buildRatingInputSection(),
                  const SizedBox(height: 32),
                  _buildRatingsHeader(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildRatingsList(),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (widget.skill.evidenceUrls?.isNotEmpty ?? false) {
      return Image.network(
        widget.skill.evidenceUrls!.first,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildDefaultHeader(),
      );
    }
    return _buildDefaultHeader();
  }

  Widget _buildDefaultHeader() {
    return Container(
      color: const Color(0xFF00796B),
      child: const Center(
        child: Icon(Icons.work_outline, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildSkillTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            widget.skill.type == 'offer'
                ? Colors.tealAccent.withOpacity(0.2)
                : Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.skill.type == 'offer' ? Colors.tealAccent : Colors.amber,
          width: 1,
        ),
      ),
      child: Text(
        widget.skill.type == 'offer' ? 'OFFERING SERVICE' : 'REQUESTING HELP',
        style: TextStyle(
          color:
              widget.skill.type == 'offer' ? Colors.tealAccent : Colors.amber,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSkillTitle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      widget.skill.title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.grey[900],
      ),
    );
  }

  Widget _buildUserInfo() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00796B), width: 2),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundImage:
                widget.skill.userAvatar != null
                    ? NetworkImage(widget.skill.userAvatar!)
                    : null,
            child:
                widget.skill.userAvatar == null
                    ? Icon(
                      Icons.person,
                      size: 24,
                      color: const Color(0xFF00796B),
                    )
                    : null,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.skill.userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.grey[900],
              ),
            ),
            Text(
              timeago.format(widget.skill.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this skill:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.skill.description!,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Evidence:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.skill.evidenceUrls!.length,
            itemBuilder: (context, index) {
              final url = widget.skill.evidenceUrls![index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _launchUrl(url),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url.endsWith('.jpg') || url.endsWith('.png'))
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                ), // Added missing closing parenthesis here
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link,
                                size: 40,
                                color: const Color(0xFF00796B),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'View Document',
                                style: TextStyle(
                                  color: const Color(0xFF00796B),
                                ),
                              ),
                            ],
                          ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              url.split('.').last.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRatingInputSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your Experience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  iconSize: 40,
                  icon: Icon(
                    index < _userRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _userRating = index + 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ratingController,
            decoration: InputDecoration(
              labelText: 'Write your feedback...',
              labelStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
            ),
            maxLines: 4,
            minLines: 3,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingRating ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF00796B),
                elevation: 3,
              ),
              child:
                  _isSubmittingRating
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          'Community Feedback',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey[900],
          ),
        ),
        const Spacer(),
        FutureBuilder<List<Rating>>(
          future: _ratingsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final avgRating =
                  snapshot.data!.map((r) => r.rating).reduce((a, b) => a + b) /
                  snapshot.data!.length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildRatingsList() {
    return FutureBuilder<List<Rating>>(
      future: _ratingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load ratings',
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            ),
          );
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.reviews_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ratings yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share your experience!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildRatingItem(snapshot.data![index]),
            childCount: snapshot.data!.length,
          ),
        );
      },
    );
  }

  Widget _buildRatingItem(Rating rating) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00796B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 0,
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          rating.fromUserAvatar != null
                              ? NetworkImage(rating.fromUserAvatar!)
                              : null,
                      child:
                          rating.fromUserAvatar == null
                              ? Icon(
                                Icons.person,
                                size: 20,
                                color: primaryColor,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating.fromUserName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        Text(
                          timeago.format(rating.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating.rating.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  rating.feedback!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // In skill_details_screen.dart
  Widget _buildMatchSection() {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    final isOwner = currentUserId == widget.skill.userId;

    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOwner ? 'Match Requests' : 'Request Skill Match',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (!isOwner) _buildMatchRequestForm(),
              if (isOwner) _buildMatchRequestsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchRequestForm() {
    final _formKey = GlobalKey<FormState>();
    final _messageController = TextEditingController();

    // Different behavior for offer vs request
    final isRequest = widget.skill.type == 'request';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRequest) ...[
            Text(
              'Requested Skill: ${widget.skill.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText:
                  isRequest
                      ? 'Your message to the requester'
                      : 'Your proposal message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          if (!isRequest) ...[
            const Text('Select a skill to offer in return:'),
            FutureBuilder<Map<String, dynamic>?>(
              future: ProfileRepository().getProfile(
                SupabaseService.client.auth.currentUser!.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final profile = snapshot.data;
                final skills =
                    (profile?['skills'] as List<dynamic>? ?? []).cast<String>();

                if (skills.isEmpty) {
                  return Column(
                    children: [
                      const Text(
                        'You need to add skills to your profile first!',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProfileScreen(
                                    userId:
                                        SupabaseService
                                            .client
                                            .auth
                                            .currentUser!
                                            .id,
                                  ),
                            ),
                          );
                        },
                        child: const Text('Go to Profile to Add Skills'),
                      ),
                    ],
                  );
                }

                return DropdownButtonFormField<String>(
                  items:
                      skills
                          .map(
                            (skillName) => DropdownMenuItem(
                              value: skillName,
                              child: Text(skillName),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => _selectedSkillName = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value == null ? 'Please select a skill' : null,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  setState(() => _isSubmittingRating = true);

                  // For offers, ensure a skill is selected
                  if (!isRequest &&
                      (_selectedSkillName == null ||
                          _selectedSkillName!.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a skill to offer'),
                      ),
                    );
                    return;
                  }

                  await SkillRepository().createSkillMatch(
                    skillId: widget.skill.id,
                    receiverId: widget.skill.userId,
                    message: _messageController.text.trim(),
                    offerSkillName:
                        isRequest ? null : _selectedSkillName?.trim(),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request sent!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSubmittingRating = false);
                }
              }
            },
            child:
                _isSubmittingRating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      isRequest ? 'Send Help Request' : 'Send Match Request',
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRequestsList() {
    return FutureBuilder<List<SkillMatch>>(
      future: SkillRepository().getSkillMatches(widget.skill.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No match requests yet');
        }

        return Column(
          children: [
            ...snapshot.data!
                .map(
                  (match) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  match.requesterAvatar != null
                                      ? NetworkImage(match.requesterAvatar!)
                                      : null,
                            ),
                            title: Text(match.requesterName),
                            subtitle: Text(timeago.format(match.createdAt)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(match.message),
                                if (match.offerSkillTitle != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Offering: ${match.offerSkillTitle}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (match.status == 'pending') ...[
                                TextButton(
                                  onPressed:
                                      () => _updateMatch(match.id, 'rejected'),
                                  child: const Text('Decline'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _updateMatch(match.id, 'accepted');

                                    // Create conversation first
                                    final conversationId =
                                        await ConversationRepository()
                                            .createConversation(
                                              matchId: match.id,
                                              user1:
                                                  SupabaseService
                                                      .client
                                                      .auth
                                                      .currentUser!
                                                      .id,
                                              user2: match.requesterId,
                                            );

                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ChatScreen(
                                                conversationId: conversationId,
                                                otherUserId: match.requesterId,
                                                otherUserName:
                                                    match.requesterName,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Accept & Chat'),
                                ),
                              ] else ...[
                                Chip(
                                  label: Text(
                                    match.status.toUpperCase(),
                                    style: TextStyle(
                                      color:
                                          match.status == 'accepted'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }

  Future<void> _updateMatch(String matchId, String status) async {
    await SkillRepository().updateMatchStatus(matchId, status);
    // Refresh the UI
    setState(() {});
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }
}
