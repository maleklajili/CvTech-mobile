import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'user_profile_view.dart';

class UserSearchView extends StatefulWidget {
  const UserSearchView({super.key});

  @override
  State<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends State<UserSearchView> {
  final _searchController = TextEditingController();
  final _apiClient = ApiClient();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _searched = false;

  // Follow state per userId
  final Map<String, bool> _followingMap = {};
  final Map<String, bool> _loadingMap = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searched = true;
    });

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.userSearch,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        final results = List<Map<String, dynamic>>.from(
          (data['results'] ?? data ?? []),
        );

        // Pre-populate follow state
        for (final u in results) {
          final id = u['_id']?.toString() ?? '';
          if (id.isNotEmpty) {
            _followingMap[id] = u['isFollowing'] == true;
          }
        }

        setState(() {
          _results = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la recherche';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (kDebugMode) print('Search error: $e');
      setState(() {
        _error = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final isFollowing = _followingMap[userId] ?? false;
    setState(() => _loadingMap[userId] = true);

    try {
      if (isFollowing) {
        await _apiClient.dio.delete('${ApiEndpoints.unfollow}$userId');
        setState(() => _followingMap[userId] = false);
      } else {
        await _apiClient.dio.post('${ApiEndpoints.follow}$userId');
        setState(() => _followingMap[userId] = true);
      }
    } catch (_) {
      // revert
      setState(() => _followingMap[userId] = isFollowing);
    } finally {
      setState(() => _loadingMap[userId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher des personnes...',
            hintStyle: TextStyle(color: AppTheme.textMutedColor, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.textMutedColor),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppTheme.textMutedColor)),
          ],
        ),
      );
    }

    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: AppTheme.textMutedColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Recherchez des personnes par nom ou pseudo',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: AppTheme.textMutedColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        indent: 80,
        color: AppTheme.dividerColor,
      ),
      itemBuilder: (context, index) => _buildUserCard(_results[index]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['_id']?.toString() ?? '';
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final title = user['professionalTitle'] ?? '';
    final location = user['location'] ?? user['city'] ?? '';
    final image = user['image'];
    final mutualCount = (user['mutualFriendsCount'] as num?)?.toInt() ?? 0;
    final isMutual = user['isMutual'] == true;
    final isFollowing = _followingMap[userId] ?? (user['isFollowing'] == true);
    final isFollowedBy = user['isFollowedBy'] == true;
    final isLoadingFollow = _loadingMap[userId] == true;

    final relationLabel = isMutual
      ? 'Amis'
      : isFollowing
        ? 'En attente'
        : isFollowedBy
          ? 'Accepter'
          : 'Ajouter';

    // Build image URL
    String? imageUrl;
    if (image != null && image.toString().isNotEmpty) {
      imageUrl = ImageUrlHelper.getImageUrlSync(image.toString(), userId);
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileView(userId: userId)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitials(fullName),
                      )
                    : _buildInitials(fullName),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isMutual) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ami',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 11, color: AppTheme.textMutedColor),
                        const SizedBox(width: 2),
                        Text(
                          location,
                          style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                        ),
                      ],
                    ),
                  ],
                  if (mutualCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$mutualCount ami${mutualCount > 1 ? 's' : ''} en commun',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Follow button
            if (userId.isNotEmpty)
              SizedBox(
                width: 90,
                child: isLoadingFollow
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _toggleFollow(userId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFollowing
                              ? AppTheme.textMutedColor
                              : AppColors.primaryColor,
                          side: BorderSide(
                            color: isFollowing
                                ? Colors.grey.shade300
                                : AppColors.primaryColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          relationLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
