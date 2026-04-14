import 'package:flutter/material.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/models/profile/cv_theme_model.dart';

class CvPreviewWidget extends StatelessWidget {
  final ManualCvModel cv;
  final CvThemeModel theme;

  const CvPreviewWidget({
    super.key,
    required this.cv,
    required this.theme,
  });

  String? get _photoUrl {
    final raw = cv.personalInfo.photoUrl;
    if (raw == null || raw.isEmpty) return null;
    // If it's a full URL or contains a path separator, use general resolver
    if (raw.startsWith('http') || raw.contains('/')) {
      return ImageUrlHelper.resolveMaybeUrlSync(raw);
    }
    // Bare filename — construct proper URL with user-specific upload path
    return ImageUrlHelper.getImageUrlSync(raw, cv.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (cv.personalInfo.summary != null &&
                cv.personalInfo.summary!.isNotEmpty)
              _buildSummary(),
            if (cv.experiences.isNotEmpty) _buildExperience(),
            if (cv.educations.isNotEmpty) _buildEducation(),
            if (cv.skills.isNotEmpty) _buildSkills(),
            if (cv.projects.isNotEmpty) _buildProjects(),
            if (cv.languages.isNotEmpty) _buildLanguages(),
            if (cv.certifications.isNotEmpty) _buildCertifications(),
            if (cv.interests.isNotEmpty) _buildInterests(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.headerBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_photoUrl != null) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.headerTextColor, width: 2),
                image: DecorationImage(
                  image: NetworkImage(_photoUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            cv.personalInfo.fullName.isNotEmpty
                ? cv.personalInfo.fullName
                : 'Votre Nom',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.headerTextColor,
              letterSpacing: 1.2,
            ),
          ),
          if (cv.personalInfo.professionalTitle != null &&
              cv.personalInfo.professionalTitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cv.personalInfo.professionalTitle!,
              style: TextStyle(
                fontSize: 14,
                color: theme.headerTextColor.withValues(alpha: 0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              if (cv.personalInfo.email != null &&
                  cv.personalInfo.email!.isNotEmpty)
                _contactItem(Icons.email_outlined, cv.personalInfo.email!),
              if (cv.personalInfo.phone != null &&
                  cv.personalInfo.phone!.isNotEmpty)
                _contactItem(Icons.phone_outlined, cv.personalInfo.phone!),
              if (cv.personalInfo.city != null &&
                  cv.personalInfo.city!.isNotEmpty)
                _contactItem(
                  Icons.location_on_outlined,
                  [cv.personalInfo.city, cv.personalInfo.country]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(', '),
                ),
              if (cv.personalInfo.website != null &&
                  cv.personalInfo.website!.isNotEmpty)
                _contactItem(Icons.language, cv.personalInfo.website!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.headerTextColor.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: theme.headerTextColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.sectionTitleColor),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.sectionTitleColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            color: theme.dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Profil', Icons.person_outline),
          Text(
            cv.personalInfo.summary!,
            style: TextStyle(
              fontSize: 12,
              color: theme.bodyTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperience() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Expérience', Icons.work_outline),
          ...cv.experiences.map(_buildExperienceEntry),
        ],
      ),
    );
  }

  Widget _buildExperienceEntry(ManualCvExperience exp) {
    final dateRange =
        '${exp.startDate} – ${exp.current ? "Présent" : exp.endDate ?? ""}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exp.jobTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Text(
                dateRange,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.bodyTextColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            exp.company,
            style: TextStyle(
              fontSize: 12,
              color: theme.bodyTextColor.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description!,
              style: TextStyle(
                fontSize: 11,
                color: theme.bodyTextColor,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Formation', Icons.school_outlined),
          ...cv.educations.map(_buildEducationEntry),
        ],
      ),
    );
  }

  Widget _buildEducationEntry(ManualCvEducation edu) {
    final dateRange =
        '${edu.startDate} – ${edu.current ? "En cours" : edu.endDate ?? ""}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  edu.degree,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Text(
                dateRange,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.bodyTextColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            edu.school,
            style: TextStyle(
              fontSize: 12,
              color: theme.bodyTextColor.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Compétences', Icons.star_outline),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: cv.skills.map((s) => _buildSkillChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(ManualCvSkill skill) {
    final level = _skillLevelToFraction(skill.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.skillBarColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.skillBarColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.bodyTextColor,
            ),
          ),
          if (level > 0) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 30,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: level,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation(theme.skillBarColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _skillLevelToFraction(String? level) {
    if (level == null || level.isEmpty) return 0;
    final lower = level.toLowerCase();
    if (lower.contains('expert')) return 1.0;
    if (lower.contains('avancé') || lower.contains('advanced')) return 0.8;
    if (lower.contains('intermédiaire') || lower.contains('intermediate')) {
      return 0.6;
    }
    if (lower.contains('débutant') || lower.contains('beginner')) return 0.3;
    return 0.5;
  }

  Widget _buildProjects() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Projets', Icons.folder_outlined),
          ...cv.projects.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.bodyTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLanguages() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Langues', Icons.translate),
          ...cv.languages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lang.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.bodyTextColor,
                      ),
                    ),
                    if (lang.level != null && lang.level!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '— ${lang.level}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.bodyTextColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCertifications() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Certifications', Icons.verified_outlined),
          ...cv.certifications.map((cert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: theme.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.bodyTextColor,
                            ),
                          ),
                          if (cert.organization != null &&
                              cert.organization!.isNotEmpty)
                            Text(
                              cert.organization!,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    theme.bodyTextColor.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Centres d'intérêt", Icons.favorite_outline),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: cv.interests
              .map((interest) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.bodyTextColor,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
