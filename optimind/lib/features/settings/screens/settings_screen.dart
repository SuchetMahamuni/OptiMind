import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_card.dart';
import '../../../features/auth/models/user_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: theme.colorScheme.primary),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: (){
            Navigator.pop(context);
          },),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // User Info Section
          _buildUserInfo(context, user),
          const SizedBox(height: 32),

          // Study Goals Section
          _buildSectionHeader(context, 'Study Goals'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildToggleItem(
                  context: context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'Automatic goal setting',
                  subtitle: 'Nudges based on your settings',
                  value: settingsProvider.useAdaptiveGoal,
                  onChanged: (val) => settingsProvider.setUseAdaptiveGoal(val),
                ),
                if (!settingsProvider.useAdaptiveGoal) ...[
                  const Divider(height: 1),
                  _buildActionItem(
                    context: context,
                    icon: Icons.track_changes_rounded,
                    title: 'Daily Study Goal',
                    trailingText: _formatMinutes(settingsProvider.customGoalMinutes),
                    onTap: () => _showGoalPicker(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildToggleItem(
                  context: context,
                  icon: settingsProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  title: 'Dark Mode',
                  value: settingsProvider.isDarkMode,
                  onChanged: (_) => settingsProvider.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: colorScheme.error,
                  onTap: () => _showLogoutDialog(context, authProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionItem(
                  context: context,
                  icon: Icons.delete_forever_outlined,
                  title: 'Clear Local Data',
                  color: colorScheme.error,
                  onTap: () => _showClearDataDialog(context, settingsProvider, authProvider),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Text(
              'OptiMind v1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, UserModel? user) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    user?.username ?? 'Student', style: theme.textTheme.titleMedium?.copyWith(
                    color: settingsProvider.isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight
                  )
                ),
                Text(user?.email ?? 'Not logged in', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: settingsProvider.isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight
                  )
      ),
      subtitle: subtitle != null ? Text(subtitle, style: theme.textTheme.bodySmall) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailingText,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final iconColor = color ?? theme.colorScheme.primary;
    final textColor = color ?? (settingsProvider.isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight);
    
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
            Text(trailingText, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showGoalPicker(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    int currentGoal = settings.customGoalMinutes;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Adjust Daily Goal", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text("${currentGoal ~/ 60}h ${currentGoal % 60}m", 
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              Slider(
                value: currentGoal.toDouble(),
                min: 15,
                max: 1440, // 24 hours for Nikola Teslas
                divisions: (1440 - 15) ~/ 15,
                label: _formatMinutes(currentGoal),
                onChanged: (val) {
                  setModalState(() {
                    currentGoal = val.toInt();
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    settings.setCustomGoal(currentGoal);
                    Navigator.pop(context);
                  },
                  child: const Text("Save Goal"),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h > 0 && m > 0) return "${h}h ${m}m";
    if (h > 0) return "${h}h";
    return "${m}m";
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, SettingsProvider settings, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all local tasks, sessions, and settings. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await settings.clearAllData();
              if (!context.mounted) return;
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Clear Data', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
