import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/models/profile/cv_theme_model.dart';
import 'package:cv_tech/presentation/views_models/profile/cv_theme_view_model.dart';
import 'package:cv_tech/presentation/widgets/cv/cv_preview_widget.dart';

class CvPreviewScreen extends StatelessWidget {
  final ManualCvModel cv;

  const CvPreviewScreen({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CvThemeViewModel(),
      child: _CvPreviewContent(cv: cv),
    );
  }
}

class _CvPreviewContent extends StatefulWidget {
  final ManualCvModel cv;
  const _CvPreviewContent({required this.cv});

  @override
  State<_CvPreviewContent> createState() => _CvPreviewContentState();
}

class _CvPreviewContentState extends State<_CvPreviewContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _sidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
      if (_sidebarOpen) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu du CV'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _sidebarOpen ? Icons.close : Icons.palette_outlined,
                key: ValueKey(_sidebarOpen),
              ),
            ),
            onPressed: _toggleSidebar,
            tooltip: 'Personnaliser le thème',
          ),
        ],
      ),
      body: Consumer<CvThemeViewModel>(
        builder: (context, themeVm, _) {
          return Stack(
            children: [
              // CV Preview (main area)
              Positioned.fill(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    right: _sidebarOpen
                        ? MediaQuery.of(context).size.width * 0.35
                        : 0,
                  ),
                  child: Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeVm.theme.bgColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CvPreviewWidget(
                            cv: widget.cv,
                            theme: themeVm.theme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Theme sidebar (slides from right)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: MediaQuery.of(context).size.width * 0.35,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _ThemeSidebar(themeVm: themeVm),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeSidebar extends StatelessWidget {
  final CvThemeViewModel themeVm;
  const _ThemeSidebar({required this.themeVm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.palette, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Thème du CV',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Preset themes grid
                const Text(
                  'Thèmes prédéfinis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPresetsGrid(),
                const SizedBox(height: 20),

                // Custom colors
                const Text(
                  'Couleur personnalisée',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildColorRow('Principal', themeVm.theme.primaryColor, (c) {
                  themeVm.setPrimaryColor(c);
                }),
                const SizedBox(height: 8),
                _buildColorRow('Accent', themeVm.theme.accentColor, (c) {
                  themeVm.setAccentColor(c);
                }),
                const SizedBox(height: 20),

                // Quick colors palette
                const Text(
                  'Couleurs rapides',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuickColors(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: CvThemeModel.presets.length,
      itemBuilder: (context, index) {
        final preset = CvThemeModel.presets[index];
        final isSelected = themeVm.selectedPresetIndex == index;

        return GestureDetector(
          onTap: () => themeVm.selectPreset(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? preset.theme.primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: preset.theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: preset.theme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preset.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? preset.theme.primaryColor : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorRow(
      String label, Color current, ValueChanged<Color> onChanged) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showColorPicker(current, onChanged),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: current,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400),
              boxShadow: [
                BoxShadow(
                  color: current.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color current, ValueChanged<Color> onChanged) {
    // Use quick colors instead of a full picker
  }

  Widget _buildQuickColors() {
    const colors = [
      Color(0xFF1E293B),
      Color(0xFF0F766E),
      Color(0xFF6D28D9),
      Color(0xFFDC2626),
      Color(0xFF166534),
      Color(0xFF1E3A5F),
      Color(0xFFBE185D),
      Color(0xFF475569),
      Color(0xFFF26E22),
      Color(0xFFD97706),
      Color(0xFF0369A1),
      Color(0xFF7C3AED),
      Color(0xFFE11D48),
      Color(0xFF059669),
      Color(0xFF4338CA),
      Color(0xFF92400E),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => themeVm.setPrimaryColor(color),
          onDoubleTap: () => themeVm.setAccentColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: themeVm.theme.primaryColor == color
                    ? Colors.white
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: themeVm.theme.primaryColor == color
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
