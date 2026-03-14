import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/presentation/views/chat/conversation_view.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
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
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.profileById}${widget.userId}',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _profile = response.data is Map<String, dynamic>
                ? response.data
                : <String, dynamic>{};
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Erreur lors du chargement du profil';
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          if (e.response?.statusCode == 404) {
            _error = 'Profil introuvable';
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
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling follow: $e');
    }

    if (mounted) {
      setState(() => _isFollowLoading = false);
    }
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
        await Future.wait([_loadProfile(), _loadFollowStatus()]);
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationView(
                    otherUserId: widget.userId,
                    otherUserName: _profile?['name'] ?? widget.userName ?? '',
                    otherUserImage: _profile?['image'] ?? widget.userImage,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.message_outlined, size: 18),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
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
                      : const Icon(Icons.person_remove_outlined, size: 18),
                  label: const Text('Abonné'),
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
                      : const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Suivre'),
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
    final experiences = (_profile?['experiences'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Icons.work_outline, color: Colors.blue[600], size: 22),
              const SizedBox(width: 8),
              const Text('Expérience',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          if (experiences.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Aucune expérience ajoutée',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ...experiences.asMap().entries.map((entry) {
              final idx = entry.key;
              final exp = entry.value as Map<String, dynamic>;
              final isCurrent = exp['current'] == true;
              final accentColor = isCurrent ? Colors.green[500]! : Colors.blue[500]!;
              final isLast = idx == experiences.length - 1;
              final skills = (exp['skills'] as List?)?.cast<String>() ?? [];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline column
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 6)],
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [accentColor, Colors.grey[300]!],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gradient header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCurrent
                                    ? [Colors.green[400]!, Colors.teal[500]!]
                                    : [Colors.blue[400]!, Colors.indigo[500]!],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exp['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(exp['company'] ?? '',
                                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          // Card body
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badges row
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _Badge(icon: Icons.calendar_today,
                                        text: '${exp['startDate'] ?? ''} - ${isCurrent ? 'Présent' : (exp['endDate'] ?? '')}'),
                                    if ((exp['location'] ?? '').toString().isNotEmpty)
                                      _Badge(icon: Icons.location_on, text: exp['location'].toString()),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                            const SizedBox(width: 4),
                                            Text('Poste actuel',
                                                style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                // Description
                                if ((exp['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(exp['description'].toString(),
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                // Skills
                                if (skills.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: skills.map((s) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              colors: [Colors.blue[50]!, Colors.indigo[50]!]),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.blue[200]!, width: 0.5),
                                        ),
                                        child: Text(s,
                                            style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ──────────────────── EDUCATION TAB ────────────────────
  Widget _buildEducationTab() {
    final education = (_profile?['education'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.purple[600], size: 22),
              const SizedBox(width: 8),
              const Text('Formation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          if (education.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Aucune formation ajoutée',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ...education.map((edu) {
              final e = edu as Map<String, dynamic>;
              final isCurrent = e['current'] == true;
              const color = Color(0xFF3B82F6); // blue

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['degree'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(e['school'] ?? '',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Badges row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school, size: 14, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  Text('En cours',
                                      style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Location + dates
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(e['location'] ?? '',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${e['startDate'] ?? ''} - ${isCurrent ? 'En cours' : (e['endDate'] ?? '')}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      // Description
                      if ((e['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(e['description'].toString(),
                            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ──────────────────── SKILLS TAB ────────────────────
  Widget _buildSkillsTab() {
    final skills = (_profile?['skills'] as List?)?.cast<String>() ?? [];
    final languages = (_profile?['languages'] as List?) ?? [];

    if (skills.isEmpty && languages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.code_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucune compétence ajoutée',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.code, color: Colors.blue[600], size: 22),
              const SizedBox(width: 8),
              const Text('Compétences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Skills category card
          if (skills.isNotEmpty) ...[
            _SkillCategoryCard(
              categoryName: 'Compétences',
              count: skills.length,
              color: const Color(0xFF3B82F6),
              icon: Icons.code,
              children: skills.map((skill) => _ReadOnlySkillItem(name: skill)).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Languages category card
          if (languages.isNotEmpty) ...[
            _SkillCategoryCard(
              categoryName: 'Langues',
              count: languages.length,
              color: const Color(0xFF8B5CF6),
              icon: Icons.language,
              children: languages.map((lang) {
                final l = lang is Map<String, dynamic> ? lang : <String, dynamic>{};
                return _ReadOnlySkillItem(
                  name: l['name'] ?? '',
                  sublabel: l['level'] ?? '',
                  icon: Icons.translate,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────── PROJECTS TAB ────────────────────
  Widget _buildProjectsTab() {
    final projects = (_profile?['projects'] as List?) ?? [];
    if (projects.isEmpty) {
      return _buildEmptyTab(Icons.folder_outlined, 'Aucun projet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index] as Map<String, dynamic>;
        final technologies =
            (p['technologies'] as List?)?.cast<String>() ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.teal.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder_outlined,
                          color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            '${p['startDate'] ?? ''} - ${p['current'] == true ? 'En cours' : (p['endDate'] ?? '')}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((p['description'] ?? '').toString().isNotEmpty) ...[
                      Text(p['description'].toString(),
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMutedColor,
                              height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                    ],
                    if (technologies.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: technologies.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.green)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
                return Center(
                  child: Column(
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
                return Center(
                  child: Column(
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
              return RefreshIndicator(
                onRefresh: () => vm.refreshFeed(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: vm.posts.length,
                  itemBuilder: (context, index) {
                    final post = vm.posts[index];
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    return Center(
      child: Column(
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
