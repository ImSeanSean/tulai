import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/student/enrollment_question.dart';
import 'package:tulai/screens/student/voice_enrollment_page.dart';

class EnrollmentPage extends StatefulWidget {
  final VoidCallback? onBackToTeacherDashboard;

  const EnrollmentPage({
    super.key,
    this.onBackToTeacherDashboard,
  });

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  final _supabase = Supabase.instance.client;
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showPasswordDialog() async {
    _passwordController.clear();
    _isPasswordVisible = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: TulaiColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: TulaiSpacing.sm),
                  Text(
                    'Teacher Access Required',
                    style: TulaiTextStyles.heading3,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please enter your teacher password to return to the dashboard.',
                    style: TulaiTextStyles.bodyMedium.copyWith(
                      color: TulaiColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: TulaiSpacing.lg),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(
                        Icons.password,
                        color: TulaiColors.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: TulaiColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TulaiBorderRadius.md),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TulaiBorderRadius.md),
                        borderSide: BorderSide(
                          color: TulaiColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => Navigator.of(context).pop(true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TulaiTextStyles.bodyMedium.copyWith(
                      color: TulaiColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TulaiColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TulaiSpacing.lg,
                      vertical: TulaiSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                    ),
                  ),
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await _verifyPassword();
    }
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      _showErrorSnackbar('Please enter your password');
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Get current user email
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        if (mounted) Navigator.of(context).pop(); // Close loading
        _showErrorSnackbar('No user logged in');
        return;
      }

      // Attempt to sign in with the provided password to verify it
      await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: _passwordController.text,
      );

      // Password is correct
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Call the callback to go back to teacher dashboard
        if (widget.onBackToTeacherDashboard != null) {
          widget.onBackToTeacherDashboard!();
        } else {
          Navigator.of(context).pop(); // Fallback to regular pop
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                const Text('Access granted'),
              ],
            ),
            backgroundColor: TulaiColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackbar('Incorrect password. Please try again.');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: TulaiSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: TulaiColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
        ),
      ),
    );
  }

  Future<void> _showLanguageSelectionDialog() async {
    final selectedLanguage = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
          ),
          title: Row(
            children: [
              Icon(
                Icons.language,
                color: TulaiColors.primary,
                size: 28,
              ),
              const SizedBox(width: TulaiSpacing.sm),
              Text(
                'Choose Language',
                style: TulaiTextStyles.heading3,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please select your preferred language for voice enrollment:',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // English
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TulaiColors.primary,
                    padding: const EdgeInsets.all(TulaiSpacing.lg),
                  ),
                  child: Text(
                    'English',
                    style: TulaiTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TulaiSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Filipino
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TulaiColors.secondary,
                    padding: const EdgeInsets.all(TulaiSpacing.lg),
                  ),
                  child: Text(
                    'Filipino',
                    style: TulaiTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLanguage != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceEnrollmentPage(
            isFilipino: selectedLanguage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _showPasswordDialog,
          tooltip: 'Back to Dashboard (Password Required)',
        ),
        title: Text(
          'Student Enrollment',
          style: TulaiTextStyles.heading3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TulaiColors.backgroundSecondary,
              Color(0xFFF0F4F8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
              isLargeScreen ? TulaiSpacing.xxl : TulaiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic spacer that adapts to screen size
              SizedBox(
                height: isLargeScreen
                    ? MediaQuery.of(context).size.height * 0.05
                    : TulaiSpacing.xl,
              ),

              // Welcome section with gradient card
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 600 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Welcome card with gradient
                      Container(
                        padding: const EdgeInsets.all(TulaiSpacing.xl),
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
                              BorderRadius.circular(TulaiBorderRadius.lg),
                          boxShadow: TulaiShadows.lg,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.how_to_reg,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: TulaiSpacing.md),
                            Text(
                              'Choose Enrollment Method',
                              style: TulaiTextStyles.heading2.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TulaiSpacing.sm),
                            Text(
                              'Piliin ang Paraan ng Enrollment',
                              style: TulaiTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TulaiSpacing.xl),

                      // Form-based enrollment button
                      SizedBox(
                        width: isLargeScreen ? 450 : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LanguageSelectionPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('Form-Based Enrollment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TulaiColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: TulaiSpacing.xl,
                              vertical: TulaiSpacing.lg,
                            ),
                            textStyle: TulaiTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TulaiSpacing.lg),

                      // Voice-based enrollment button
                      SizedBox(
                        width: isLargeScreen ? 450 : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showLanguageSelectionDialog();
                          },
                          icon: const Icon(Icons.mic),
                          label: const Text('Voice-Powered Enrollment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TulaiColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: TulaiSpacing.xl,
                              vertical: TulaiSpacing.lg,
                            ),
                            textStyle: TulaiTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TulaiSpacing.xl),

                      // Additional help text
                      Container(
                        padding: const EdgeInsets.all(TulaiSpacing.lg),
                        decoration: BoxDecoration(
                          color: TulaiColors.backgroundPrimary,
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.md),
                          border: Border.all(
                            color: TulaiColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: TulaiColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: TulaiSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Choose your preferred method:',
                                    style: TulaiTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: TulaiColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: TulaiSpacing.sm),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: TulaiSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• Form-Based: Fill up traditional forms',
                                    style: TulaiTextStyles.bodySmall.copyWith(
                                      color: TulaiColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Voice-Powered: Speak your answers naturally',
                                    style: TulaiTextStyles.bodySmall.copyWith(
                                      color: TulaiColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom spacing for better scrolling experience
              SizedBox(height: TulaiSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.primary,
        elevation: 0,
        title: Text(
          'Choose Language',
          style: TulaiTextStyles.heading3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TulaiColors.backgroundSecondary,
              Color(0xFFF0F4F8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(
                isLargeScreen ? TulaiSpacing.xxl : TulaiSpacing.lg),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 600 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(TulaiSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TulaiColors.primary, TulaiColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
                      boxShadow: TulaiShadows.lg,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.language,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: TulaiSpacing.md),
                        Text(
                          'Choose Your Language',
                          style: TulaiTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: TulaiSpacing.sm),
                        Text(
                          'Piliin ang Inyong Wika',
                          style: TulaiTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TulaiSpacing.xl),
                  SizedBox(
                    width: isLargeScreen ? 450 : double.infinity,
                    child: TulaiButton(
                      text: 'English',
                      style: TulaiButtonStyle.primary,
                      size: TulaiButtonSize.large,
                      onPressed: () {
                        AppConfig().formLanguage = FormLanguage.english;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnrollmentQuestions(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: TulaiSpacing.lg),
                  SizedBox(
                    width: isLargeScreen ? 450 : double.infinity,
                    child: TulaiButton(
                      text: 'Filipino',
                      style: TulaiButtonStyle.secondary,
                      size: TulaiButtonSize.large,
                      onPressed: () {
                        AppConfig().formLanguage = FormLanguage.filipino;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnrollmentQuestions(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
