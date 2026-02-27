// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/education_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';

/// Section de formation avec design amélioré comme le frontend Next.js
class EducationSection extends StatelessWidget {
  final List<EducationModel> educations;
  final VoidCallback onAdd;
  final Function(EducationModel) onEdit;
  final Function(String) onDelete;

  const EducationSection({
    super.key,
    required this.educations,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec design amélioré
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined,
                    color: Colors.purple[600], size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Formation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (educations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune formation ajoutée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez vos diplômes et certifications',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: educations.length,
            itemBuilder: (context, index) {
              final education = educations[index];
              return _EducationCard(
                education: education,
                onEdit: () => onEdit(education),
                onDelete: () => onDelete(education.id!),
              );
            },
          ),
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  final EducationModel education;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EducationCard({
    required this.education,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM yyyy', 'fr_FR').format(date);
  }

  Color _getTypeColor(EducationType type) {
    switch (type) {
      case EducationType.diploma:
        return const Color(0xFF3B82F6);
      case EducationType.certification:
        return const Color(0xFF10B981);
      case EducationType.course:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getTypeIcon(EducationType type) {
    switch (type) {
      case EducationType.diploma:
        return Icons.school;
      case EducationType.certification:
        return Icons.verified;
      case EducationType.course:
        return Icons.book;
    }
  }

  String _getEducationTypeLabel(EducationType type) {
    switch (type) {
      case EducationType.diploma:
        return 'Diplôme';
      case EducationType.certification:
        return 'Certification';
      case EducationType.course:
        return 'Cours';
    }
  }

  String _getEducationLevelLabel(EducationLevel level) {
    switch (level) {
      case EducationLevel.beginner:
        return 'Débutant';
      case EducationLevel.intermediate:
        return 'Intermédiaire';
      case EducationLevel.advanced:
        return 'Avancé';
      case EducationLevel.expert:
        return 'Expert';
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return _getTypeColor(education.type);
    }
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _getTypeColor(education.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(education.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                // Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(education.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and school
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        education.degree,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        education.school,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Badges row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(education.type),
                          size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        _getEducationTypeLabel(education.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Level badge
                if (education.level != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEducationLevelLabel(education.level!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Grade badge
                if (education.grade != null && education.grade!.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          education.grade!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Current badge
                if (education.current)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Location and dates
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  education.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(education.startDate)} - ${education.endDate != null ? _formatDate(education.endDate!) : 'En cours'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Description
            if (education.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                education.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            // Skills
            if (education.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: education.skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple[50]!,
                          Colors.indigo[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.purple[200]!,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      skill.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Progress bar (if available)
            if (education.progress != null && education.progress! > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: education.progress! / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${education.progress}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    ModernDialog.showDelete(
      context: context,
      itemName: 'la formation "${education.degree}"',
      onConfirm: onDelete,
    );
  }
}
