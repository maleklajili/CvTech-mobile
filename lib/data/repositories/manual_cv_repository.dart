import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class ManualCvRepository {
  final ApiClient _apiClient;

  ManualCvRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ManualCvModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.manualCvCreate,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(result);
      }

      throw Exception('Échec de la création du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ManualCvModel>> getMyCvs() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.manualCvMyCvs,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        if (data is List) {
          return data.map((e) => ManualCvModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec du chargement des CVs');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> getById(String cvId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvGet}$cvId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(data);
      }

      throw Exception('Échec du chargement du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> update(String cvId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.manualCvUpdate}$cvId',
        data: data,
      );

      if (response.statusCode == 200) {
        final result = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(result);
      }

      throw Exception('Échec de la mise à jour du CV');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> delete(String cvId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.manualCvDelete}$cvId',
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression du CV');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Uint8List> downloadPdf(String cvId, {String? primaryColor, String? accentColor, String? fontFamily, String? format, String? lang}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (primaryColor != null) queryParams['primaryColor'] = primaryColor;
      if (accentColor != null) queryParams['accentColor'] = accentColor;
      if (fontFamily != null) queryParams['fontFamily'] = fontFamily;
      if (format != null) queryParams['format'] = format;
      if (lang != null) queryParams['lang'] = lang;
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvDownloadPdf}$cvId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        if (bytes.isEmpty) {
          throw Exception('Le PDF généré est vide');
        }
        return bytes;
      }

      throw Exception('Échec du téléchargement du PDF');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ManualCvModel> importFromProfile({
    String format = 'standard',
    String language = 'fr',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.manualCvImportProfile,
        data: {'format': format, 'language': language},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ManualCvModel.fromJson(data);
      }

      throw Exception('Échec de l\'import du profil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Build a [ManualCvModel] **locally** by fetching the raw profile data
  /// from individual endpoints in parallel. No DB record is created — the
  /// returned model has `id == null`. Much faster than
  /// [importFromProfile] because it avoids the server-side DB insert and
  /// runs all fetches concurrently straight from the profile
  /// collections (experiences, educations, skills, technical/personal
  /// skills, languages, projects + embedded certifications, user).
  Future<ManualCvModel> buildFromProfile({
    String format = 'standard',
    String language = 'fr',
  }) async {
    Future<List<dynamic>> fetchList(String path) async {
      try {
        final resp = await _apiClient.dio.get(
          path,
          queryParameters: {'limit': 100},
        );
        if (resp.statusCode != 200) return const [];
        final raw = resp.data;
        dynamic payload = raw;
        if (raw is Map && raw.containsKey('data')) payload = raw['data'];
        if (payload is Map && payload.containsKey('data')) {
          payload = payload['data'];
        }
        return payload is List ? payload : const [];
      } catch (_) {
        return const [];
      }
    }

    Future<Map<String, dynamic>> fetchUser() async {
      try {
        final resp = await _apiClient.dio.get(ApiEndpoints.currentUser);
        if (resp.statusCode != 200) return const {};
        final raw = resp.data;
        final payload = raw is Map && raw.containsKey('data')
            ? raw['data']
            : raw;
        return payload is Map
            ? Map<String, dynamic>.from(payload)
            : const {};
      } catch (_) {
        return const {};
      }
    }

    // Fire every profile endpoint concurrently.
    final results = await Future.wait([
      fetchUser(),
      fetchList(ApiEndpoints.experienceGetAll),
      fetchList(ApiEndpoints.educationGetAll),
      fetchList(ApiEndpoints.skillGetAll),
      fetchList(ApiEndpoints.technicalSkillGetAll),
      fetchList(ApiEndpoints.personalSkillGetAll),
      fetchList(ApiEndpoints.languageGetAll),
      fetchList(ApiEndpoints.projectGetAll),
    ]);

    final user = results[0] as Map<String, dynamic>;
    final experiencesRaw = results[1] as List;
    final educationsRaw = results[2] as List;
    final skillsRaw = results[3] as List;
    final technicalSkillsRaw = results[4] as List;
    final personalSkillsRaw = results[5] as List;
    final languagesRaw = results[6] as List;
    final projectsRaw = results[7] as List;

    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    String? toIsoDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      final dt = DateTime.tryParse(s);
      if (dt == null) return s;
      return dt.toIso8601String().split('T').first;
    }

    final firstName = str(user['firstName']) ?? '';
    final lastName = str(user['lastName']) ?? '';
    final fullName = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final userId = str(user['_id']) ?? '';

    final personalInfo = ManualCvPersonalInfo(
      fullName: fullName.isEmpty ? (str(user['userName']) ?? '') : fullName,
      professionalTitle: str(user['professionalTitle']),
      email: str(user['email']),
      phone: str(user['phone']),
      address: str(user['adress']) ?? str(user['address']),
      city: str(user['city']),
      country: str(user['location']) ?? str(user['country']),
      website: str(user['website']),
      photoUrl: str(user['image']) != null && userId.isNotEmpty
          ? '/uploads/images-$userId/${user['image']}'
          : null,
      summary: str(user['bio']),
    );

    final experiences = experiencesRaw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      final endIso = toIsoDate(map['endDate']);
      return ManualCvExperience(
        jobTitle: str(map['post']) ?? str(map['jobTitle']) ?? '',
        company: str(map['entreprise']) ?? str(map['company']) ?? '',
        startDate: toIsoDate(map['startDate']) ?? '',
        endDate: endIso,
        current: (map['currentPost'] ?? map['current'] ?? (endIso == null)) ==
            true,
        description: str(map['description']),
      );
    }).toList();

    final educations = educationsRaw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      final endIso = toIsoDate(map['endDate']);
      return ManualCvEducation(
        degree: str(map['degree']) ?? '',
        school: str(map['school']) ?? '',
        startDate: toIsoDate(map['startDate']) ?? '',
        endDate: endIso,
        current: (map['current'] ?? (endIso == null)) == true,
        description: str(map['description']),
      );
    }).toList();

    // Merge the three skill sources and deduplicate by lower-case name.
    final mergedSkills = <ManualCvSkill>[];
    final seenSkills = <String>{};
    void addSkill(String? name, String? level) {
      if (name == null || name.isEmpty) return;
      final key = name.toLowerCase();
      if (seenSkills.contains(key)) return;
      seenSkills.add(key);
      mergedSkills.add(ManualCvSkill(name: name, level: level));
    }

    for (final s in skillsRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(s);
      addSkill(str(map['name']), str(map['level']));
    }
    for (final s in technicalSkillsRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(s);
      addSkill(str(map['name']), str(map['category']) ?? 'technique');
    }
    for (final s in personalSkillsRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(s);
      addSkill(str(map['name']), str(map['category']) ?? 'personnel');
    }

    final languages = languagesRaw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      return ManualCvLanguage(
        name: str(map['name']) ?? '',
        level: str(map['level']) ?? str(map['fluency']),
      );
    }).toList();

    final projects = projectsRaw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      return ManualCvProject(
        name: str(map['title']) ?? str(map['name']) ?? '',
        description: str(map['description']),
        link: str(map['liveUrl']) ?? str(map['githubUrl']),
        startDate: toIsoDate(map['startDate']),
        endDate: toIsoDate(map['endDate']),
      );
    }).toList();

    // Certifications are embedded in projects via the `certificates`
    // lookup on /projects/getAll. Flatten them into a single list.
    final certifications = <ManualCvCertification>[];
    for (final p in projectsRaw.whereType<Map>()) {
      final certs = p['certificates'];
      if (certs is List) {
        for (final c in certs.whereType<Map>()) {
          final map = Map<String, dynamic>.from(c);
          certifications.add(ManualCvCertification(
            name: str(map['name']) ?? '',
            organization: str(map['organization']),
            date: str(map['date']),
            description: str(map['type']) ?? str(map['description']),
          ));
        }
      }
    }

    return ManualCvModel(
      userId: userId,
      title: 'CV de ${personalInfo.fullName}',
      format: format,
      language: language,
      personalInfo: personalInfo,
      experiences: experiences,
      educations: educations,
      skills: mergedSkills,
      languages: languages,
      projects: projects,
      certifications: certifications,
    );
  }

  /// Get the CV completeness score from backend.
  /// Returns a Map with: totalScore, maxScore, percentage, label, sections.
  Future<Map<String, dynamic>> getScore(String cvId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.manualCvScore}$cvId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }

      throw Exception('Échec du calcul du score');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get the profile CV score aggregated from ALL profile collections.
  /// Does not require a ManualCv — uses real profile data directly.
  /// Returns a Map with: totalScore, maxScore, percentage, label, sections.
  Future<Map<String, dynamic>> getProfileCvScore() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.profileCvScore,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return Map<String, dynamic>.from(data as Map);
      }

      throw Exception('Échec du calcul du score profil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.data is Map) {
      final error = e.response!.data['error'];
      if (error is Map && error['message'] != null) {
        return Exception(error['message']);
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connexion lente, veuillez réessayer');
    }
    return Exception('Erreur réseau: ${e.message}');
  }
}
