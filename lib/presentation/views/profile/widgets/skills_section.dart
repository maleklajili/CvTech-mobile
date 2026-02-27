// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/skill_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';

/// Section de compétences avec design amélioré comme le frontend Next.js
class SkillsSection extends StatefulWidget {
  final List<SkillModel> skills;
  final VoidCallback onAdd;
  final Function(SkillModel) onEdit;
  final Function(String) onDelete;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final Set<String> _expandedCategories = {};
  String _searchQuery = '';
  String _activeFilter = 'all';

  // Regrouper les compétences par catégorie
  Map<String, List<SkillModel>> get _groupedSkills {
    final Map<String, List<SkillModel>> grouped = {};
    // Filtrer par recherche
    final filteredSkills = widget.skills.where((skill) {
      if (_searchQuery.isEmpty) return true;
      return skill.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skill.category.toLowerCase().contains(_searchQuery.toLowerCase());
    });

    for (final skill in filteredSkills) {
      final category = skill.category.isNotEmpty ? skill.category : 'Autres';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(skill);
    }
    return grouped;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Frontend': const Color(0xFF3B82F6),
      'Backend': const Color(0xFF10B981),
      'Database': const Color(0xFF8B5CF6),
      'DevOps': const Color(0xFFF59E0B),
      'Mobile': const Color(0xFFEC4899),
      'Design': const Color(0xFF6366F1),
      'Autres': const Color(0xFF64748B),
    };
    return colors[category] ?? const Color(0xFF64748B);
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('front')) {
      return Icons.web;
    } else if (category.toLowerCase().contains('back')) {
      return Icons.dns;
    } else if (category.toLowerCase().contains('data')) {
      return Icons.storage;
    } else if (category.toLowerCase().contains('devops')) {
      return Icons.settings_suggest;
    } else if (category.toLowerCase().contains('mobile')) {
      return Icons.phone_android;
    } else if (category.toLowerCase().contains('design')) {
      return Icons.brush;
    }
    return Icons.code;
  }

  Color _getProgressColor(int level) {
    if (level >= 90) return const Color(0xFF10B981);
    if (level >= 75) return const Color(0xFF3B82F6);
    if (level >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getLevelText(int level) {
    if (level >= 90) return 'Expert';
    if (level >= 75) return 'Avancé';
    if (level >= 60) return 'Intermédiaire';
    if (level >= 40) return 'Basique';
    return 'Débutant';
  }

  @override
  Widget build(BuildContext context) {
    final groupedSkills = _groupedSkills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and Filters
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une compétence...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),
              // Filter buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterButton(
                      label: 'Tous',
                      isActive: _activeFilter == 'all',
                      onTap: () => setState(() => _activeFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ...groupedSkills.keys.map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterButton(
                            label: category,
                            isActive: _activeFilter == category,
                            onTap: () =>
                                setState(() => _activeFilter = category),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Colors.blue[600], size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Compétences',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.onAdd,
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
        const SizedBox(height: 16),

        // Skills by Category
        if (widget.skills.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.code_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune compétence ajoutée',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...groupedSkills.entries
              .where((e) => _activeFilter == 'all' || e.key == _activeFilter)
              .map((entry) => _CategoryCard(
                    categoryName: entry.key,
                    skills: entry.value,
                    color: _getCategoryColor(entry.key),
                    icon: _getCategoryIcon(entry.key),
                    isExpanded: _expandedCategories.contains(entry.key),
                    onToggle: () {
                      setState(() {
                        if (_expandedCategories.contains(entry.key)) {
                          _expandedCategories.remove(entry.key);
                        } else {
                          _expandedCategories.add(entry.key);
                        }
                      });
                    },
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                    onAdd: widget.onAdd,
                    getProgressColor: _getProgressColor,
                    getLevelText: _getLevelText,
                  )),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange[500] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? Colors.orange[500]! : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final List<SkillModel> skills;
  final Color color;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(SkillModel) onEdit;
  final Function(String) onDelete;
  final VoidCallback onAdd;
  final Color Function(int) getProgressColor;
  final String Function(int) getLevelText;

  const _CategoryCard({
    required this.categoryName,
    required this.skills,
    required this.color,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    required this.getProgressColor,
    required this.getLevelText,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${skills.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  ...skills.map((skill) => _SkillItem(
                        skill: skill,
                        color: color,
                        onEdit: () => onEdit(skill),
                        onDelete: () => _showDeleteDialog(context, skill),
                        getProgressColor: getProgressColor,
                        getLevelText: getLevelText,
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une compétence'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SkillModel skill) {
    ModernDialog.showDelete(
      context: context,
      itemName: 'la compétence "${skill.name}"',
      onConfirm: () => onDelete(skill.id!),
    );
  }
}

class _SkillItem extends StatelessWidget {
  final SkillModel skill;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(int) getProgressColor;
  final String Function(int) getLevelText;

  const _SkillItem({
    required this.skill,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    required this.getProgressColor,
    required this.getLevelText,
  });

  @override
  Widget build(BuildContext context) {
    final level = skill.percentage ?? 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.code, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (skill.isFavorite == true) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.favorite,
                              size: 16, color: Colors.red[400]),
                        ],
                        if (skill.certified == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Certifié',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (skill.subcategory.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            skill.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 14, color: Colors.grey[400]),
                          Text(
                            skill.subcategory,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.grey[500]),
                onPressed: onEdit,
                splashRadius: 20,
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: Colors.grey[500]),
                onPressed: onDelete,
                splashRadius: 20,
              ),
              // Level display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$level%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: getProgressColor(level),
                    ),
                  ),
                  Text(
                    getLevelText(level),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(getProgressColor(level)),
            ),
          ),

          // Stars rating
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = i < (level / 20).round();
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: filled ? Colors.amber[400] : Colors.grey[300],
                  );
                }),
              ),
              Row(
                children: [
                  if (skill.yearsOfExperience != null) ...[
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${skill.yearsOfExperience} ans',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (skill.projectsCount != null) ...[
                    Icon(Icons.folder, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${skill.projectsCount} projets',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Description
          if (skill.description != null && skill.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              skill.description!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],

          // Certifications
          if (skill.certifications.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skill.certifications.map((cert) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        cert,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
