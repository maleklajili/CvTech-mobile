import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/education_model.dart';
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/data/models/profile/project_model.dart';
import 'package:cv_tech/data/models/profile/skill_model.dart';
import 'package:cv_tech/presentation/views/chat/conversation_view.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/profile/widgets/education_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/experience_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/projects_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/skills_section.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

/// Vue du profil d'un autre utilisateur
/// Design identique à ProfileView (lecture seule)
class UserProfileView extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userImage;

  const UserProfileView({
    super.key,
    required this.userId,
    this.userName,
    this.userImage,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  bool _showFullBio = false;

  // Follow state
  bool _isFollowing = false;
  bool _isFollowedBy = false;
  bool _isMutualFriend = false;
  bool _allowMessagesFromNonFriends = true;
  bool _isFollowLoading = false;
  int _followerCount = 0;
  int _followingCount = 0;

  late TabController _tabController;

  final List<_TabItem> _tabs = [
    _TabItem(label: 'Expérience', icon: Icons.work_outline),
    _TabItem(label: 'Formation', icon: Icons.school_outlined),
    _TabItem(label: 'Compétences', icon: Icons.psychology_outlined),
    _TabItem(label: 'Projets', icon: Icons.folder_outlined),
    _TabItem(label: 'Posts', icon: Icons.article_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProfile();
    _loadFollowStatus();
    _loadRelationshipStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileData = await _loadProfileFromUserEndpoints();
      if (!_isValidProfilePayload(profileData)) {
        throw DioException(
          requestOptions: RequestOptions(path: '${ApiEndpoints.userById}${widget.userId}'),
          type: DioExceptionType.badResponse,
          error: 'Invalid profile payload',
        );
      }

      final allowMessages = _extractAllowMessagesFromNonFriends(profileData);
      if (mounted) {
        setState(() {
          _profile = profileData;
          _allowMessagesFromNonFriends = allowMessages;
          _isLoading = false;
          _error = null;
        });
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (mounted) {
        setState(() {
          if (status == 404) {
            _error = 'Profil introuvable';
          } else if (status == 401 || status == 403) {
            _error = 'Session expirée. Reconnectez-vous.';
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            _error = 'Le serveur ne répond pas. Vérifiez votre connexion.';
          } else {
            _error = 'Erreur de connexion';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger ce profil pour le moment.';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadProfileFromUserEndpoints() async {
    final userResponse = await _apiClient.dio.get('${ApiEndpoints.userById}${widget.userId}');
    final userData = _extractProfilePayload(userResponse.data);

    final futures = await Future.wait([
      _safeGetList('${ApiEndpoints.experience}/user/${widget.userId}'),
      _safeGetList('${ApiEndpoints.educationByUser}${widget.userId}'),
      _safeGetList('${ApiEndpoints.projectByUser}${widget.userId}'),
      _safeGetList('${ApiEndpoints.skill}/user/${widget.userId}'),
      _safeGetList('${ApiEndpoints.language}/user/${widget.userId}'),
      _safeGetList('${ApiEndpoints.technicalSkill}/user/${widget.userId}'),
      _safeGetList('${ApiEndpoints.personalSkill}/user/${widget.userId}'),
    ]);

    final experiences = futures[0];
    final education = futures[1];
    final projects = futures[2];
    final skills = futures[3];
    final languages = futures[4];
    final technicalSkills = futures[5];
    final personalSkills = futures[6];

    return _mapUserPayloadToProfile(
      userData,
      experiences: experiences,
      education: education,
      projects: projects,
      skills: skills,
      languages: languages,
      technicalSkills: technicalSkills,
      personalSkills: personalSkills,
    );
  }

  Future<List<dynamic>> _safeGetList(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      final payload = response.data;
      if (payload is List) return payload;
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is List) return data;
        if (data is Map<String, dynamic>) {
          for (final key in ['items', 'results', 'skills', 'languages']) {
            final value = data[key];
            if (value is List) return value;
          }
        }
      }
    } catch (_) {
      return <dynamic>[];
    }
    return <dynamic>[];
  }

  Map<String, dynamic> _extractProfilePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final success = raw['success'];
      if (success is bool && success == false) {
        return <String, dynamic>{};
      }
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (raw.containsKey('_id') || raw.containsKey('name') || raw.containsKey('userName')) {
        return raw;
      }
      return raw;
    }
    return <String, dynamic>{};
  }

  bool _isValidProfilePayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return false;
    final id = payload['_id']?.toString() ?? '';
    final name = payload['name']?.toString().trim() ?? '';
    final userName = payload['userName']?.toString().trim() ?? '';
    return id.isNotEmpty || name.isNotEmpty || userName.isNotEmpty;
  }

  Map<String, dynamic> _mapUserPayloadToProfile(
    Map<String, dynamic> userPayload, {
    List<dynamic> experiences = const <dynamic>[],
    List<dynamic> education = const <dynamic>[],
    List<dynamic> projects = const <dynamic>[],
    List<dynamic> skills = const <dynamic>[],
    List<dynamic> languages = const <dynamic>[],
    List<dynamic> technicalSkills = const <dynamic>[],
    List<dynamic> personalSkills = const <dynamic>[],
  }) {
    String name = (userPayload['name'] ?? '').toString().trim();
    if (name.isEmpty) {
      final firstName = (userPayload['firstName'] ?? '').toString().trim();
      final lastName = (userPayload['lastName'] ?? '').toString().trim();
      final composed = '$firstName $lastName'.trim();
      if (composed.isNotEmpty) {
        name = composed;
      }
    }
    if (name.isEmpty) {
      name = (userPayload['userName'] ?? widget.userName ?? '').toString();
    }

    final mergedSkills = <String>{};
    for (final raw in [...skills, ...technicalSkills, ...personalSkills]) {
      if (raw is Map<String, dynamic>) {
        final nameValue = (raw['name'] ?? '').toString().trim();
        if (nameValue.isNotEmpty) mergedSkills.add(nameValue);
      } else if (raw is Map) {
        final nameValue = (raw['name'] ?? '').toString().trim();
        if (nameValue.isNotEmpty) mergedSkills.add(nameValue);
      } else {
        final nameValue = raw.toString().trim();
        if (nameValue.isNotEmpty && nameValue != 'null') mergedSkills.add(nameValue);
      }
    }

    List<Map<String, dynamic>> normalizeExperiences() {
      return experiences.map((item) {
        final map = item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{});
        final rawSkills = map['skills'];
        final mappedSkills = rawSkills is List
            ? rawSkills.map((s) {
                if (s is Map<String, dynamic>) return (s['name'] ?? '').toString();
                if (s is Map) return (s['name'] ?? '').toString();
                return s.toString();
              }).where((s) => s.trim().isNotEmpty && s.trim() != 'null').toList()
            : <String>[];

        return <String, dynamic>{
          'title': (map['title'] ?? map['post'] ?? '').toString(),
          'company': (map['company'] ?? map['entreprise'] ?? '').toString(),
          'location': (map['location'] ?? map['place'] ?? '').toString(),
          'startDate': _formatDateText(map['startDate']),
          'endDate': _formatDateText(map['endDate']),
          'current': map['current'] == true || map['currentPost'] == true,
          'description': (map['description'] ?? map['KeyAchievements'] ?? '').toString(),
          'skills': mappedSkills,
        };
      }).toList();
    }

    List<Map<String, dynamic>> normalizeEducation() {
      return education
          .map((item) => item is Map<String, dynamic>
              ? item
              : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}))
          .map((map) => <String, dynamic>{
                'degree': (map['degree'] ?? '').toString(),
                'school': (map['school'] ?? '').toString(),
                'location': (map['location'] ?? '').toString(),
                'startDate': _formatDateText(map['startDate']),
                'endDate': _formatDateText(map['endDate']),
                'current': map['current'] == true,
                'description': (map['description'] ?? '').toString(),
                'type': (map['type'] ?? '').toString(),
              })
          .where((map) => map['type'] == '' || map['type'] == 'diploma')
          .toList();
    }

    List<Map<String, dynamic>> normalizeProjects() {
      return projects.map((item) {
        final map = item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{});
        final technologies = map['technologies'] is List
            ? (map['technologies'] as List).map((e) => e.toString()).toList()
            : <String>[];
        return <String, dynamic>{
          'title': (map['title'] ?? '').toString(),
          'description': (map['description'] ?? '').toString(),
          'startDate': _formatDateText(map['startDate']),
          'endDate': _formatDateText(map['endDate']),
          'current': map['current'] == true,
          'technologies': technologies,
          'image': (map['image'] ?? '').toString(),
          'liveUrl': (map['liveUrl'] ?? '').toString(),
          'githubUrl': (map['githubUrl'] ?? '').toString(),
        };
      }).toList();
    }

    List<Map<String, dynamic>> normalizeLanguages() {
      return languages.map((item) {
        final map = item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{});
        return <String, dynamic>{
          'name': (map['name'] ?? map['nativeName'] ?? '').toString(),
          'level': (map['level'] ?? map['fluency'] ?? '').toString(),
        };
      }).toList();
    }

    return <String, dynamic>{
      '_id': (userPayload['_id'] ?? widget.userId).toString(),
      'name': name,
      'title': (userPayload['professionalTitle'] ?? userPayload['title'] ?? '').toString(),
      'bio': (userPayload['bio'] ?? '').toString(),
      'location': (userPayload['location'] ?? userPayload['city'] ?? '').toString(),
      'email': (userPayload['email'] ?? '').toString(),
      'phone': (userPayload['phone'] ?? userPayload['phoneNumber'] ?? '').toString(),
      'website': (userPayload['website'] ?? '').toString(),
      'image': (userPayload['image'] ?? '').toString(),
      'skills': mergedSkills.toList(),
      'languages': normalizeLanguages(),
      'experiences': normalizeExperiences(),
      'education': normalizeEducation(),
      'projects': normalizeProjects(),
    };
  }

  String _formatDateText(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  bool _extractAllowMessagesFromNonFriends(Map<String, dynamic> payload) {
    final direct = payload['allowMessagesFromNonFriends'];
    if (direct is bool) return direct;

    final canMessage = payload['canReceiveMessagesFromNonFriends'];
    if (canMessage is bool) return canMessage;

    final privacySettings = payload['privacySettings'];
    if (privacySettings is Map<String, dynamic>) {
      final fromNonFriends = privacySettings['messagesFromNonFriends'];
      if (fromNonFriends is bool) return fromNonFriends;
    }

    return true;
  }

  Future<void> _loadRelationshipStatus() async {
    try {
      final currentUserId = await _apiClient.getUserId();
      if (currentUserId == null || currentUserId.isEmpty) return;

      final responses = await Future.wait([
        _apiClient.dio.get(ApiEndpoints.friends),
        _apiClient.dio.get('${ApiEndpoints.followers}/$currentUserId'),
      ]);

      final friendsResponse = responses[0];
      final followersResponse = responses[1];

      final friendsData = friendsResponse.data;
      final friendsList = friendsData is Map
          ? (friendsData['friends'] ??
              (friendsData['data'] is Map
                  ? friendsData['data']['friends']
                  : friendsData['data']) ??
              [])
          : [];

      final followersData = followersResponse.data;
      final followersList = followersData is Map
          ? (followersData['followers'] ?? followersData['data'] ?? [])
          : [];

      bool isMutual = false;
      if (friendsList is List) {
        isMutual = friendsList.any((u) {
          if (u is Map<String, dynamic>) {
            return u['_id']?.toString() == widget.userId;
          }
          if (u is Map) {
            return u['_id']?.toString() == widget.userId;
          }
          return false;
        });
      }

      bool isFollowedBy = false;
      if (followersList is List) {
        isFollowedBy = followersList.any((u) {
          if (u is Map<String, dynamic>) {
            return u['_id']?.toString() == widget.userId;
          }
          if (u is Map) {
            return u['_id']?.toString() == widget.userId;
          }
          return false;
        });
      }

      if (mounted) {
        setState(() {
          _isMutualFriend = isMutual;
          _isFollowedBy = isFollowedBy;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading relationship status: $e');
    }
  }

  Future<void> _loadFollowStatus() async {
    if (!mounted) return;
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.followStatus}${widget.userId}',
      );

      if (response.statusCode == 200 && response.data is Map) {
        if (mounted) {
          setState(() {
            _isFollowing = response.data['isFollowing'] == true;
            _followerCount = response.data['followerCount'] ?? 0;
            _followingCount = response.data['followingCount'] ?? 0;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (!mounted) return;
    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        await _apiClient.dio.delete(
          '${ApiEndpoints.unfollow}${widget.userId}',
        );
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followerCount = (_followerCount - 1).clamp(0, 999999);
            _isMutualFriend = false;
          });
        }
      } else {
        await _apiClient.dio.post(
          '${ApiEndpoints.follow}${widget.userId}',
        );
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followerCount++;
            _isMutualFriend = _isFollowedBy;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling follow: $e');
    }

    if (mounted) {
      setState(() => _isFollowLoading = false);
    }

    await _loadRelationshipStatus();
  }

  bool get _canSendMessage {
    if (_isMutualFriend) return true;
    return _allowMessagesFromNonFriends;
  }

  String get _relationshipButtonLabel {
    if (_isMutualFriend) return 'Amis';
    if (_isFollowing && !_isMutualFriend) return 'En attente';
    if (!_isFollowing && _isFollowedBy) return 'Accepter';
    return 'Ajouter';
  }

  IconData get _relationshipButtonIcon {
    if (_isMutualFriend) return Icons.people_alt_outlined;
    if (_isFollowing && !_isMutualFriend) return Icons.hourglass_top_outlined;
    if (!_isFollowing && _isFollowedBy) return Icons.person_add_alt_1_outlined;
    return Icons.person_add_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.userName ?? 'Profil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadProfile(),
          _loadFollowStatus(),
          _loadRelationshipStatus(),
        ]);
      },
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: _buildCoverSection()),
            SliverToBoxAdapter(child: _buildProfileCard()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppTheme.textMutedColor,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 3,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExperienceTab(),
            _buildEducationTab(),
            _buildSkillsTab(),
            _buildProjectsTab(),
            _buildPostsTab(),
          ],
        ),
      ),
    );
  }

  // ──────────────────── COVER ────────────────────
  Widget _buildCoverSection() {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────── PROFILE CARD ────────────────────
  Widget _buildProfileCard() {
    final p = _profile!;
    final name = p['name'] ?? widget.userName ?? '';
    final title = p['title'] ?? '';
    final bio = p['bio'] ?? '';
    final location = p['location'] ?? '';
    final email = p['email'] ?? '';
    final phone = p['phone'] ?? '';
    final website = p['website'] ?? '';
    final image = p['image'] ?? '';
    final skills = (p['skills'] as List?)?.cast<String>() ?? [];

    final imageUrl = (image is String && image.isNotEmpty)
        ? ImageUrlHelper.getImageUrlSync(image, widget.userId)
        : widget.userImage;

    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar with Followers/Following stats on sides
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Followers (left side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_followerCount',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Followers',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar (center)
                  _buildAvatar(name, imageUrl),

                  // Following (right side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_followingCount',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Following',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Location
              if (location.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: AppTheme.textMutedColor),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Professional Title
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),

              // Bio
              if (bio.isNotEmpty) _buildBioSection(bio),
              const SizedBox(height: 16),

              // Skills badges
              if (skills.isNotEmpty) _buildSkillsBadges(skills),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 16),

              // Contact Info
              _buildContactSection(email, phone, location, website),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(name),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : _buildDefaultAvatar(name),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
        : 'U';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ──────────────────── BIO ────────────────────
  Widget _buildBioSection(String bio) {
    final isLongBio = bio.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bio,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            height: 1.6,
          ),
          maxLines: _showFullBio ? null : 2,
          overflow: _showFullBio ? null : TextOverflow.ellipsis,
        ),
        if (isLongBio)
          GestureDetector(
            onTap: () => setState(() => _showFullBio = !_showFullBio),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showFullBio ? 'Voir moins' : 'Voir plus',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    _showFullBio
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ──────────────────── SKILLS BADGES ────────────────────
  Widget _buildSkillsBadges(List<String> skills) {
    final displayed = skills.take(7).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayed.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.isLight
                ? Colors.grey.shade100
                : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            skill,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.isLight
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────── ACTION BUTTONS ────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _canSendMessage
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationView(
                          otherUserId: widget.userId,
                          otherUserName:
                              _profile?['name'] ?? widget.userName ?? '',
                          otherUserImage:
                              _profile?['image'] ?? widget.userImage,
                        ),
                      ),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cette personne n\'accepte pas les messages hors amis.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.message_outlined, size: 18),
            label: Text(_canSendMessage ? 'Message' : 'Message indisponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canSendMessage ? AppColors.primaryColor : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.isLight
                ? Colors.grey.shade100
                : Colors.grey.shade800,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            color: AppTheme.isLight
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isFollowing
              ? OutlinedButton.icon(
                  onPressed: _isFollowLoading ? null : _toggleFollow,
                  icon: _isFollowLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_relationshipButtonIcon, size: 18),
                  label: Text(_relationshipButtonLabel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _isFollowLoading ? null : _toggleFollow,
                  icon: _isFollowLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_relationshipButtonIcon, size: 18),
                  label: Text(_relationshipButtonLabel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
        ),
      ],
    );
  }

  // ──────────────────── CONTACT ────────────────────
  Widget _buildContactSection(
      String email, String phone, String location, String website) {
    final contacts = <_ContactInfo>[
      if (email.isNotEmpty)
        _ContactInfo(icon: Icons.email_outlined, value: email),
      if (phone.isNotEmpty)
        _ContactInfo(icon: Icons.phone_outlined, value: phone),
      if (location.isNotEmpty)
        _ContactInfo(icon: Icons.location_on_outlined, value: location),
      if (website.isNotEmpty)
        _ContactInfo(icon: Icons.link_outlined, value: website),
    ];

    if (contacts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de contact',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 8),
        ...contacts.map(
          (info) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(info.icon, size: 16, color: AppTheme.textMutedColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(info.value, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //                    TAB CONTENT
  // ══════════════════════════════════════════════════════════

  // ──────────────────── EXPERIENCE TAB ────────────────────
  Widget _buildExperienceTab() {
    final experiences = _asMapList(_profile?['experiences'])
        .map(_toExperienceModel)
        .where((e) => e.post.trim().isNotEmpty || e.entreprise.trim().isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ExperienceSection(
        experiences: experiences,
        onAdd: () {},
        onEdit: (_) {},
        onDelete: (_) {},
        readOnly: true,
      ),
    );
  }

  // ──────────────────── EDUCATION TAB ────────────────────
  Widget _buildEducationTab() {
    final education = _asMapList(_profile?['education'])
        .map(_toEducationModel)
        .where((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EducationSection(
        educations: education,
        onAdd: () {},
        onEdit: (_) {},
        onDelete: (_) {},
        readOnly: true,
      ),
    );
  }

  // ──────────────────── SKILLS TAB ────────────────────
  Widget _buildSkillsTab() {
    final skills = _toSkillModels();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SkillsSection(
        skills: skills,
        onAdd: () {},
        onEdit: (_) {},
        onDelete: (_) {},
        readOnly: true,
      ),
    );
  }

  // ──────────────────── PROJECTS TAB ────────────────────
  Widget _buildProjectsTab() {
    final projects = _asMapList(_profile?['projects'])
        .map(_toProjectModel)
        .where((p) => p.title.trim().isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProjectsSection(
        projects: projects,
        onAdd: () {},
        onEdit: (_) {},
        onDelete: (_) {},
        readOnly: true,
      ),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<dynamic>()
        .map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is Map) return Map<String, dynamic>.from(item);
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return DateTime.now();
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    final monthYear = RegExp(r'^(\d{2})\/(\d{4})$').firstMatch(raw);
    if (monthYear != null) {
      final month = int.tryParse(monthYear.group(1)!);
      final year = int.tryParse(monthYear.group(2)!);
      if (month != null && year != null) {
        return DateTime(year, month, 1);
      }
    }
    return DateTime.now();
  }

  ExperienceModel _toExperienceModel(Map<String, dynamic> data) {
    final keyAchievementsRaw = data['keyAchievements'] ?? data['KeyAchievements'];

    return ExperienceModel(
      id: data['_id']?.toString(),
      userId: widget.userId,
      post: (data['post'] ?? data['title'] ?? '').toString(),
      entreprise: (data['entreprise'] ?? data['company'] ?? '').toString(),
      place: (data['place'] ?? data['location'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      startDate: _parseDate(data['startDate']),
      endDate: (data['endDate'] == null || data['endDate'].toString().isEmpty)
          ? null
          : _parseDate(data['endDate']),
      currentPost: data['currentPost'] == true || data['current'] == true,
      keyAchievements: keyAchievementsRaw is List
          ? keyAchievementsRaw.map((e) => e.toString()).toList()
          : <String>[],
        skills: const [],
    );
  }

  EducationModel _toEducationModel(Map<String, dynamic> data) {
    return EducationModel(
      id: data['_id']?.toString(),
      userId: widget.userId,
      degree: (data['degree'] ?? '').toString(),
      school: (data['school'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      startDate: _parseDate(data['startDate']),
      endDate: (data['endDate'] == null || data['endDate'].toString().isEmpty)
          ? null
          : _parseDate(data['endDate']),
      description: (data['description'] ?? '').toString(),
      current: data['current'] == true,
      type: EducationType.diploma,
    );
  }

  ProjectModel _toProjectModel(Map<String, dynamic> data) {
    final technologies = data['technologies'] is List
        ? (data['technologies'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return ProjectModel(
      id: data['_id']?.toString(),
      userId: widget.userId,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      startDate: _parseDate(data['startDate']),
      endDate: (data['endDate'] == null || data['endDate'].toString().isEmpty)
          ? null
          : _parseDate(data['endDate']),
      technologies: technologies,
      category: (data['category'] ?? 'Projet').toString(),
      projectType: (data['projectType'] ?? 'Personnel').toString(),
      image: data['image']?.toString(),
      liveUrl: data['liveUrl']?.toString(),
      githubUrl: data['githubUrl']?.toString(),
      current: data['current'] == true,
      featured: data['featured'] == true,
      color: data['color']?.toString(),
    );
  }

  List<SkillModel> _toSkillModels() {
    final items = <SkillModel>[];
    final skills = (_profile?['skills'] as List?) ?? [];
    final languages = (_profile?['languages'] as List?) ?? [];

    for (final raw in skills) {
      final name = raw.toString().trim();
      if (name.isEmpty || name == 'null') continue;
      items.add(
        SkillModel(
          userId: widget.userId,
          category: 'Compétences',
          subcategory: '',
          name: name,
          percentage: 70,
        ),
      );
    }

    for (final raw in languages) {
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      final name = (map['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final level = (map['level'] ?? '').toString().toLowerCase();
      items.add(
        SkillModel(
          userId: widget.userId,
          category: 'Langues',
          subcategory: (map['level'] ?? '').toString(),
          name: name,
          percentage: _languageLevelToPercent(level),
        ),
      );
    }

    return items;
  }

  int _languageLevelToPercent(String level) {
    if (level.contains('native') || level.contains('natif')) return 95;
    if (level.contains('fluent') || level.contains('courant')) return 85;
    if (level.contains('advanced') || level.contains('avance')) return 75;
    if (level.contains('intermediate') || level.contains('intermediaire')) return 60;
    if (level.contains('beginner') || level.contains('debutant')) return 40;
    return 65;
  }

  // ──────────────────── POSTS TAB ────────────────────
  Widget _buildPostsTab() {
    return ChangeNotifierProvider(
      create: (_) => FeedViewModel()..loadUserPosts(widget.userId),
      child: Builder(
        builder: (context) {
          return Consumer<FeedViewModel>(
            builder: (context, vm, _) {
              if (vm.state == FeedState.loading && vm.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.state == FeedState.error && vm.posts.isEmpty) {
                return _buildScrollablePlaceholder(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(vm.errorMessage ?? 'Erreur',
                          style: TextStyle(color: AppTheme.textMutedColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => vm.loadUserPosts(widget.userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              if (vm.posts.isEmpty) {
                return _buildScrollablePlaceholder(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Aucune publication pour l\'instant',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              final visiblePosts = _isMutualFriend
                  ? vm.posts
                      .where((p) =>
                          p.privacy == 'public' ||
                          p.privacy == 'friends' ||
                          p.privacy.isEmpty)
                      .toList()
                  : vm.posts
                      .where((p) => p.privacy == 'public' || p.privacy.isEmpty)
                      .toList();

              if (visiblePosts.isEmpty) {
                return _buildScrollablePlaceholder(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 52, color: Colors.grey[350]),
                      const SizedBox(height: 12),
                      Text(
                        _isMutualFriend
                            ? 'Aucune publication visible pour le moment'
                            : 'Seules les publications publiques sont visibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => vm.refreshFeed(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: visiblePosts.length,
                  itemBuilder: (context, index) {
                    final post = visiblePosts[index];
                    return FeedPostCard(
                      post: post,
                      currentUserId: null,
                      showSharedBadge: true,
                      sharedByUserId: widget.userId,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: vm,
                            child: PostDetailView(post: post),
                          ),
                        ),
                      ).then((_) => vm.syncPostById(post.id!)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    return _buildScrollablePlaceholder(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScrollablePlaceholder(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────── HELPERS ────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  _TabItem({required this.label, required this.icon});
}

class _ContactInfo {
  final IconData icon;
  final String value;
  _ContactInfo({required this.icon, required this.value});
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

// ──── Badge widget (same as ExperienceSection._Badge) ────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

// ──── Skill category card (same style as SkillsSection._CategoryCard) ────
class _SkillCategoryCard extends StatefulWidget {
  final String categoryName;
  final int count;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  const _SkillCategoryCard({
    required this.categoryName,
    required this.count,
    required this.color,
    required this.icon,
    required this.children,
  });

  @override
  State<_SkillCategoryCard> createState() => _SkillCategoryCardState();
}

class _SkillCategoryCardState extends State<_SkillCategoryCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: widget.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.categoryName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${widget.count}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.color)),
                  ),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: widget.children),
            ),
        ],
      ),
    );
  }
}

// ──── Read-only skill item ────
class _ReadOnlySkillItem extends StatelessWidget {
  final String name;
  final String? sublabel;
  final IconData? icon;

  const _ReadOnlySkillItem({
    required this.name,
    this.sublabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon ?? Icons.code, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (sublabel != null && sublabel!.isNotEmpty)
                  Text(sublabel!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
