import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../services/superbase_service.dart';
import '../../services/gemini_service.dart';
import './course_recommend.dart';
import './course_card.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen>
    with TickerProviderStateMixin {
  final OpenRouterService _openRouterService = OpenRouterService();
  List<CourseRecommendation> _recommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
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

    _loadRecommendations();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await SupabaseService.client
              .from('users')
              .select('skills')
              .eq('id', userId)
              .single();

      final skills =
          (response['skills'] as List<dynamic>?)?.cast<String>() ?? [];

      if (skills.isEmpty) {
        setState(() {
          _errorMessage =
              'Add skills to your profile to get personalized recommendations';
          _isLoading = false;
        });
        return;
      }

      final openRouterResponse = await _openRouterService
          .getLearningRecommendations(userId: userId, userSkills: skills);

      final data = jsonDecode(openRouterResponse);
      final recs =
          (data['recommendations'] as List)
              .map((r) => CourseRecommendation.fromJson(r))
              .toList();

      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<void> _searchCourses(String query) async {
    if (query.isEmpty) {
      _loadRecommendations();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      HapticFeedback.lightImpact();
      final response = await _openRouterService.searchCourses(query: query);
      final data = jsonDecode(response);
      final recs =
          (data['recommendations'] as List)
              .map((r) => CourseRecommendation.fromJson(r))
              .toList();

      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search courses. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [_buildAppBar(), _buildSearchSection(), _buildContent()],
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
        title: const Text(
          'Learning Hub',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
          icon: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const Icon(Icons.refresh, color: Colors.white),
              );
            },
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _loadRecommendations();
          },
          tooltip: 'Refresh Recommendations',
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for courses, skills, or topics...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.greenAccent,
                size: 24,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          _loadRecommendations();
                        },
                      )
                      : IconButton(
                        icon: Icon(Icons.mic, color: Colors.greenAccent),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Voice search functionality can be added here
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[800],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            onSubmitted: _searchCourses,
            onChanged: (value) {
              setState(() {}); // Trigger rebuild for clear button
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverFillRemaining(child: _buildLoadingState());
    }
    if (_errorMessage.isNotEmpty) {
      return SliverFillRemaining(child: _buildErrorState());
    }
    if (_recommendations.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }
    return _buildRecommendationsList();
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Finding perfect courses for you...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[900]!.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red[400]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _loadRecommendations();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[700]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.greenAccent,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'No Courses Found',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try searching for different topics or add more skills to your profile for better recommendations.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final recommendation = _recommendations[index];
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CourseCard(recommendation: recommendation),
            ),
          ),
        );
      }, childCount: _recommendations.length),
    );
  }
}
