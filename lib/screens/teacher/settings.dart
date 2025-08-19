import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';

class TeacherSettings extends StatelessWidget {
  const TeacherSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: TulaiColors.backgroundPrimary,
        title: Text(
          'Settings',
          style: TulaiTextStyles.heading2,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            TulaiCard(
              margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TulaiColors.primary, TulaiColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(TulaiBorderRadius.round),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Account',
                          style: TulaiTextStyles.heading3,
                        ),
                        const SizedBox(height: TulaiSpacing.xs),
                        Text(
                          'Manage your account settings and preferences',
                          style: TulaiTextStyles.bodyMedium.copyWith(
                            color: TulaiColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Settings Sections
            _buildSettingsSection(
              context,
              'Account',
              [
                _buildSettingsItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile Information',
                  subtitle: 'View and edit your profile details',
                  onTap: () {
                    // TODO: Navigate to profile page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile page coming soon!'),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // TODO: Navigate to notifications settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              context,
              'Application',
              [
                _buildSettingsItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Learn more about Tulai ALS System',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              context,
              'Session',
              [
                _buildSettingsItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  iconColor: TulaiColors.error,
                  titleColor: TulaiColors.error,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> items) {
    return TulaiCard(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TulaiTextStyles.heading3.copyWith(
              color: TulaiColors.primary,
            ),
          ),
          const SizedBox(height: TulaiSpacing.md),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
        border: Border.all(color: TulaiColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(TulaiSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (iconColor ?? TulaiColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? TulaiColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: TulaiSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TulaiTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? TulaiColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TulaiSpacing.xs),
                      Text(
                        subtitle,
                        style: TulaiTextStyles.bodySmall.copyWith(
                          color: TulaiColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: TulaiColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: TulaiColors.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
          ),
          title: Text(
            'Logout',
            style: TulaiTextStyles.heading3,
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
            style: TulaiTextStyles.bodyMedium,
          ),
          actions: [
            TulaiButton(
              text: 'Cancel',
              style: TulaiButtonStyle.ghost,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: TulaiSpacing.sm),
            TulaiButton(
              text: 'Logout',
              style: TulaiButtonStyle.primary,
              onPressed: () {
                AppConfig().userType = UserType.none;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: TulaiColors.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
          ),
          title: Text(
            'Help & Support',
            style: TulaiTextStyles.heading3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help with the Tulai ALS Enrollment System?',
                style: TulaiTextStyles.bodyMedium,
              ),
              const SizedBox(height: TulaiSpacing.md),
              Text(
                '• Contact your system administrator\n• Check the user manual\n• Report technical issues',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TulaiButton(
              text: 'Close',
              style: TulaiButtonStyle.primary,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: TulaiColors.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
          ),
          title: Text(
            'About Tulai',
            style: TulaiTextStyles.heading3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tulai ALS Enrollment System',
                style: TulaiTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TulaiSpacing.sm),
              Text(
                'Version 1.0.0',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.md),
              Text(
                'An AI-powered enrollment system for the Philippine Alternative Learning System (ALS). Designed to make education accessible for everyone.',
                style: TulaiTextStyles.bodyMedium,
              ),
            ],
          ),
          actions: [
            TulaiButton(
              text: 'Close',
              style: TulaiButtonStyle.primary,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
