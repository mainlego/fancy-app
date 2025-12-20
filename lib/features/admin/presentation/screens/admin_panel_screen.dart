import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_ai_profiles_screen.dart';
import 'admin_verifications_screen.dart';

/// Main admin panel with sidebar navigation
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedIndex = 0;

  final List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      screen: const AdminDashboardScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.people,
      label: 'Users',
      screen: const AdminUsersScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.card_membership,
      label: 'Subscriptions',
      screen: const AdminSubscriptionsScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.report,
      label: 'Reports',
      screen: const AdminReportsScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.smart_toy,
      label: 'AI Profiles',
      screen: const AdminAIProfilesScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.verified_user,
      label: 'Verifications',
      screen: const AdminVerificationsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You do not have admin privileges',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64557),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Row(
            children: [
              // Sidebar
              _buildSidebar(),
              // Content
              Expanded(
                child: _menuItems[_selectedIndex].screen,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD64557),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64557),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FANCY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2D2D2D), height: 1),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _selectedIndex;
                return _buildMenuItem(item, isSelected, () {
                  setState(() => _selectedIndex = index);
                });
              },
            ),
          ),
          // Footer
          const Divider(color: Color(0xFF2D2D2D), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to App',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () {
                    ref.invalidate(adminStatsProvider);
                    ref.invalidate(adminReportsProvider('pending'));
                  },
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_AdminMenuItem item, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFD64557).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? const Color(0xFFD64557) : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String label;
  final Widget screen;

  _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
