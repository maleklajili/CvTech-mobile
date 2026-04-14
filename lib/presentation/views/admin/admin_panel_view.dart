import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/views/main/settings_view.dart';
import 'package:cv_tech/presentation/views/notification/notification_view.dart';
import 'package:cv_tech/presentation/views_models/admin/admin_view_model.dart';
import 'package:cv_tech/presentation/views/admin/admin_dashboard_tab.dart';
import 'package:cv_tech/presentation/views/admin/admin_reports_tab.dart';
import 'package:cv_tech/presentation/views/admin/admin_payments_tab.dart';
import 'package:cv_tech/presentation/views/admin/admin_moderation_tab.dart';
import 'package:cv_tech/presentation/views/admin/admin_companies_tab.dart';

class AdminPanelView extends StatelessWidget {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel()..init(),
      child: const _AdminPanelBody(),
    );
  }
}

class _AdminPanelBody extends StatelessWidget {
  const _AdminPanelBody();

  static const _tabs = <_TabDef>[
    _TabDef(AdminTab.dashboard, Icons.dashboard_rounded, 'Dashboard'),
    _TabDef(AdminTab.reports, Icons.flag_rounded, 'Signalements'),
    _TabDef(AdminTab.payments, Icons.payments_rounded, 'Paiements'),
    _TabDef(AdminTab.moderation, Icons.shield_rounded, 'Modération'),
    _TabDef(AdminTab.companies, Icons.business_rounded, 'Entreprises'),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Pas de bouton retour
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  size: 20, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 10),
            const Text('Administration'),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Déconnexion',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern tab bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children:
                    _tabs.map((t) => _buildTab(context, vm, t)).toList(),
              ),
            ),
          ),
          Expanded(child: _buildTabContent(vm)),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, AdminViewModel vm, _TabDef tab) {
    final isActive = vm.currentTab == tab.tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => vm.switchTab(tab.tab),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 18,
                  color: isActive
                      ? AppColors.primaryColor
                      : AppTheme.textMutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primaryColor
                        : AppTheme.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AdminViewModel vm) {
    switch (vm.currentTab) {
      case AdminTab.dashboard:
        return const AdminDashboardTab();
      case AdminTab.reports:
        return const AdminReportsTab();
      case AdminTab.payments:
        return const AdminPaymentsTab();
      case AdminTab.moderation:
        return const AdminModerationTab();
      case AdminTab.companies:
        return const AdminCompaniesTab();
    }
  }
}

class _TabDef {
  final AdminTab tab;
  final IconData icon;
  final String label;
  const _TabDef(this.tab, this.icon, this.label);
}
