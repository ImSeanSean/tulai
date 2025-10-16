import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: TulaiColors.warning),
            const SizedBox(width: TulaiSpacing.sm),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: TulaiColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: TulaiColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        boxShadow: TulaiShadows.md,
        border: Border(
          bottom: BorderSide(
            color: TulaiColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(TulaiSpacing.sm),
          padding: const EdgeInsets.all(TulaiSpacing.xs),
          decoration: BoxDecoration(
            color: TulaiColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
            border: Border.all(
              color: TulaiColors.borderLight,
              width: 1,
            ),
          ),
          child: Image.asset(
            'assets/images/deped-logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TulaiSpacing.md,
            vertical: TulaiSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
            border: Border.all(
              color: TulaiColors.borderLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen ? 28 : 20,
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Color(0x40000000),
                  ),
                ],
              ),
              children: const [
                TextSpan(
                  text: 'ALS ',
                  style: TextStyle(
                    color: Color(0xFFE53E3E), // Enhanced red
                  ),
                ),
                TextSpan(
                  text: 'Enrollment ',
                  style: TextStyle(
                    color: Color(0xFF38A169), // Enhanced green
                  ),
                ),
                TextSpan(
                  text: 'System',
                  style: TextStyle(
                    color: Color(0xFF3182CE), // Enhanced blue
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Logout Button
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: TulaiSpacing.xs,
              vertical: TulaiSpacing.sm,
            ),
            child: IconButton(
              onPressed: () => _handleLogout(context),
              icon: Icon(
                Icons.logout,
                color: TulaiColors.error,
                size: isLargeScreen ? 28 : 24,
              ),
              tooltip: 'Logout',
              style: IconButton.styleFrom(
                backgroundColor: TulaiColors.error.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  side: BorderSide(
                    color: TulaiColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: TulaiSpacing.xs),
          // ALS Logo
          Container(
            margin: const EdgeInsets.all(TulaiSpacing.sm),
            padding: const EdgeInsets.all(TulaiSpacing.xs),
            decoration: BoxDecoration(
              color: TulaiColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              border: Border.all(
                color: TulaiColors.borderLight,
                width: 1,
              ),
            ),
            child: Image.asset(
              'assets/images/als-logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
