import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/community_model.dart';

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<CommunityModel>> getAll({int page = 1, int limit = 100}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.communityGetAll,
      queryParameters: {'page': page, 'limit': limit},
    );
    return _extractCommunities(response.data);
  }

  Future<List<CommunityModel>> getPopular({int limit = 10}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.communityPopular,
      queryParameters: {'limit': limit},
    );
    return _extractCommunities(response.data);
  }

  Future<List<CommunityModel>> search(String query, {int limit = 20}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.communitySearch,
      queryParameters: {'q': query, 'limit': limit},
    );
    return _extractCommunities(response.data);
  }

  Future<CommunityModel> getBySlug(String slug) async {
    final response = await _apiClient.dio.get('${ApiEndpoints.communityByName}$slug');
    final map = _extractCommunityMap(response.data);
    return CommunityModel.fromJson(map);
  }

  Future<CommunityModel> getById(String id) async {
    final response = await _apiClient.dio.get('${ApiEndpoints.communityById}$id');
    final map = _extractCommunityMap(response.data);
    return CommunityModel.fromJson(map);
  }

  Future<Map<String, dynamic>> getMembers(String id) async {
    final response = await _apiClient.dio.get('${ApiEndpoints.communityMembers}$id/members');
    final data = _extractData(response.data);
    final members = _extractList(data, preferredKeys: const ['members']);
    return {
      'members': members,
      'total': _asInt(data['total']) ?? members.length,
    };
  }

  Future<bool> checkMembership(String id) async {
    final response = await _apiClient.dio.get('${ApiEndpoints.communityCheckMembership}$id/check-membership');
    final data = _extractData(response.data);
    return data['isMember'] == true;
  }

  Future<List<CommunityModel>> getMyCommunities() async {
    final response = await _apiClient.dio.get(ApiEndpoints.communityMyCommunities);
    final data = _extractData(response.data);
    final list = _extractList(data, preferredKeys: const ['communities']);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(CommunityModel.fromJson)
        .toList();
  }

  Future<void> join(String id) async {
    await _apiClient.dio.post('${ApiEndpoints.communityJoin}$id/join');
  }

  Future<void> leave(String id) async {
    await _apiClient.dio.post('${ApiEndpoints.communityLeave}$id/leave');
  }

  Future<CommunityModel> create({
    required String name,
    required String title,
    required String description,
    required String icon,
    required String category,
    required List<String> tags,
    required bool isPublic,
    String? bannerPath,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'tags': tags,
      'isPublic': isPublic.toString(),
    };

    if (bannerPath != null && bannerPath.isNotEmpty) {
      map['banner'] = await MultipartFile.fromFile(bannerPath);
    }

    final response = await _apiClient.dio.post(
      ApiEndpoints.communityCreate,
      data: FormData.fromMap(map),
      options: Options(contentType: 'multipart/form-data'),
    );

    final mapData = _extractCommunityMap(response.data);
    return CommunityModel.fromJson(mapData);
  }

  Future<CommunityModel> update({
    required String id,
    String? name,
    String? title,
    String? description,
    String? icon,
    String? category,
    List<String>? tags,
    bool? isPublic,
    String? bannerPath,
  }) async {
    final map = <String, dynamic>{};
    if (name != null && name.isNotEmpty) map['name'] = name;
    if (title != null && title.isNotEmpty) map['title'] = title;
    if (description != null) map['description'] = description;
    if (icon != null && icon.isNotEmpty) map['icon'] = icon;
    if (category != null && category.isNotEmpty) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (isPublic != null) map['isPublic'] = isPublic.toString();

    if (bannerPath != null && bannerPath.isNotEmpty) {
      map['banner'] = await MultipartFile.fromFile(bannerPath);
    }

    final response = await _apiClient.dio.put(
      '${ApiEndpoints.community}/$id',
      data: FormData.fromMap(map),
      options: Options(contentType: 'multipart/form-data'),
    );

    final mapData = _extractCommunityMap(response.data);
    return CommunityModel.fromJson(mapData);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.community}/$id');
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractCommunityMap(dynamic raw) {
    final data = _extractData(raw);

    if (data['community'] is Map<String, dynamic>) {
      return data['community'] as Map<String, dynamic>;
    }
    if (data['community'] is Map) {
      return Map<String, dynamic>.from(data['community'] as Map);
    }

    if (data.containsKey('_id') || data.containsKey('name') || data.containsKey('title')) {
      return data;
    }

    return <String, dynamic>{};
  }

  List<CommunityModel> _extractCommunities(dynamic raw) {
    final data = _extractData(raw);
    final list = _extractList(data, preferredKeys: const ['communities', 'items', 'results']);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(CommunityModel.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic source, {List<String> preferredKeys = const []}) {
    if (source is List) return source;
    if (source is! Map) return <dynamic>[];

    for (final key in preferredKeys) {
      final value = source[key];
      if (value is List) return value;
    }

    final nestedData = source['data'];
    if (nestedData is List) return nestedData;
    if (nestedData is Map) {
      for (final key in preferredKeys) {
        final value = nestedData[key];
        if (value is List) return value;
      }
      for (final value in nestedData.values) {
        if (value is List) return value;
      }
    }

    for (final value in source.values) {
      if (value is List) return value;
    }

    return <dynamic>[];
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
