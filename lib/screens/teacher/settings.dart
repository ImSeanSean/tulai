import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';

class TeacherSettings extends StatefulWidget {
  const TeacherSettings({super.key});

  @override
  State<TeacherSettings> createState() => _TeacherSettingsState();
}

class _TeacherSettingsState extends State<TeacherSettings> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response =
            await _supabase.from('users').select().eq('id', user.id).single();

        setState(() {
          _userInfo = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                Text('Error loading user info: $e'),
              ],
            ),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);
    final user = _supabase.auth.currentUser;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                  isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  TulaiCard(
                    margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                TulaiColors.primary,
                                TulaiColors.secondary
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.round),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: TulaiSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userInfo?['name'] ?? 'Teacher',
                                style: TulaiTextStyles.heading2,
                              ),
                              const SizedBox(height: TulaiSpacing.xs),
                              Text(
                                user?.email ?? 'No email',
                                style: TulaiTextStyles.bodyMedium.copyWith(
                                  color: TulaiColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: TulaiSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TulaiSpacing.sm,
                                  vertical: TulaiSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: TulaiColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.sm),
                                ),
                                child: Text(
                                  _userInfo?['role']?.toUpperCase() ??
                                      'TEACHER',
                                  style: TulaiTextStyles.bodySmall.copyWith(
                                    color: TulaiColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account Information Section
                  TulaiCard(
                    margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: TulaiTextStyles.heading3.copyWith(
                            color: TulaiColors.primary,
                          ),
                        ),
                        const SizedBox(height: TulaiSpacing.md),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'User ID',
                          value: _userInfo?['id']?.toString().substring(0, 8) ??
                              'N/A',
                        ),
                        const Divider(height: TulaiSpacing.lg),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: user?.email ?? 'N/A',
                        ),
                        const Divider(height: TulaiSpacing.lg),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _userInfo?['name'] ?? 'N/A',
                        ),
                        const Divider(height: TulaiSpacing.lg),
                        _buildInfoRow(
                          icon: Icons.work_outline,
                          label: 'Role',
                          value: _userInfo?['role']?.toUpperCase() ?? 'TEACHER',
                        ),
                        const Divider(height: TulaiSpacing.lg),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Account Created',
                          value: user?.createdAt ?? 'N/A',
                        ),
                        const SizedBox(height: TulaiSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(TulaiSpacing.md),
                          decoration: BoxDecoration(
                            color: TulaiColors.info.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.md),
                            border: Border.all(
                              color: TulaiColors.info.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: TulaiColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: TulaiSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Only administrators can edit account information. Please contact your admin for any changes.',
                                  style: TulaiTextStyles.bodySmall.copyWith(
                                    color: TulaiColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logout Button
                  TulaiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session',
                          style: TulaiTextStyles.heading3.copyWith(
                            color: TulaiColors.primary,
                          ),
                        ),
                        const SizedBox(height: TulaiSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showLogoutDialog(context);
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TulaiColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: TulaiSpacing.lg,
                                horizontal: TulaiSpacing.xl,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(TulaiBorderRadius.md),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: TulaiColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
          ),
          child: Icon(
            icon,
            color: TulaiColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: TulaiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TulaiTextStyles.bodySmall.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.xs),
              Text(
                value,
                style: TulaiTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: TulaiColors.error,
                size: 28,
              ),
              const SizedBox(width: TulaiSpacing.sm),
              Text(
                'Logout',
                style: TulaiTextStyles.heading3,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
            style: TulaiTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _supabase.auth.signOut();
                  AppConfig().userType = UserType.none;
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                            const SizedBox(width: TulaiSpacing.sm),
                            Text('Error logging out: $e'),
                          ],
                        ),
                        backgroundColor: TulaiColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TulaiColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: TulaiSpacing.lg,
                  vertical: TulaiSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
