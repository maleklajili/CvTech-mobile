// Flutter imports:
import 'package:flutter/material.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';

/// Section d'expérience avec design timeline comme le frontend Next.js
class ExperienceSection extends StatelessWidget {
  final List<ExperienceModel> experiences;
  final VoidCallback onAdd;
  final Function(ExperienceModel) onEdit;
  final Function(String) onDelete;
  final bool readOnly;

  const ExperienceSection({
    super.key,
    required this.experiences,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.readOnly = false,
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
                Icon(Icons.work_outline, color: Colors.blue[600], size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Expérience',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!readOnly)
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context).add),
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
        if (experiences.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune expérience ajoutée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez vos expériences professionnelles',
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
          // Timeline design
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experiences.length,
            itemBuilder: (context, index) {
              final experience = experiences[index];
              final isFirst = index == 0;
              final isLast = index == experiences.length - 1;
              return _TimelineExperienceCard(
                experience: experience,
                onEdit: () => onEdit(experience),
                onDelete: () => onDelete(experience.id!),
                isFirst: isFirst,
                isLast: isLast,
                readOnly: readOnly,
              );
            },
          ),
      ],
    );
  }
}

/// Widget d'expérience avec design timeline comme le frontend Next.js
class _TimelineExperienceCard extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isFirst;
  final bool isLast;
  final bool readOnly;

  const _TimelineExperienceCard({
    required this.experience,
    required this.onEdit,
    required this.onDelete,
    required this.isFirst,
    required this.isLast,
    required this.readOnly,
  });

  @override
  State<_TimelineExperienceCard> createState() =>
      _TimelineExperienceCardState();
}

class _TimelineExperienceCardState extends State<_TimelineExperienceCard> {
  bool _isExpanded = false;

  String _formatDate(DateTime date) {
    return DateFormat('MMM yyyy', 'fr_FR').format(date);
  }

  Color get _accentColor {
    if (widget.experience.currentPost) {
      return Colors.green[500]!;
    }
    return Colors.blue[500]!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 40,
          child: Column(
            children: [
              // Timeline dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Timeline line
              if (!widget.isLast)
                Container(
                  width: 2,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _accentColor,
                        Colors.grey[300]!,
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Card content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
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
                      colors: widget.experience.currentPost
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
                      // Post title and actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.experience.post,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!widget.readOnly)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context).edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context).delete,
                                          style: const TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  widget.onEdit();
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Company
                      Text(
                        widget.experience.entreprise,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Card body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and location badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            icon: Icons.calendar_today,
                            text:
                                '${_formatDate(widget.experience.startDate)} - ${widget.experience.endDate != null ? _formatDate(widget.experience.endDate!) : 'Présent'}',
                          ),
                          _Badge(
                            icon: Icons.location_on,
                            text: widget.experience.place,
                          ),
                          if (widget.experience.duration.isNotEmpty)
                            _Badge(
                              icon: Icons.access_time,
                              text: widget.experience.duration,
                            ),
                          if (widget.experience.currentPost)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Poste actuel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      if (widget.experience.description.isNotEmpty) ...[
                        Text(
                          _isExpanded ||
                                  widget.experience.description.length < 150
                              ? widget.experience.description
                              : '${widget.experience.description.substring(0, 150)}...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        if (widget.experience.description.length > 150)
                          TextButton(
                            onPressed: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _isExpanded ? 'Voir moins' : 'Voir plus',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                      ],
                      // Key Achievements
                      if (widget.experience.keyAchievements.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 18, color: Colors.amber[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Réalisations clés',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.experience.keyAchievements.map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.star,
                                    size: 14, color: Colors.amber[400]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    achievement,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Skills
                      if (widget.experience.skills.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.experience.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[50]!,
                                    Colors.indigo[50]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                skill.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
  }

  void _showDeleteDialog(BuildContext context) {
    ModernDialog.showDelete(
      context: context,
      itemName: 'l\'expérience "${widget.experience.post}"',
      onConfirm: widget.onDelete,
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({
    required this.icon,
    required this.text,
  });

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
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
