import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';

class EnrollmentWaiting extends StatelessWidget {
  const EnrollmentWaiting({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: TulaiColors.backgroundSecondary,
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
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                    isLargeScreen ? TulaiSpacing.xxl : TulaiSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon with Animation
                    Container(
                      width: isLargeScreen ? 160 : 120,
                      height: isLargeScreen ? 160 : 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [TulaiColors.success, Color(0xFF2ECC71)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TulaiColors.success.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: TulaiSpacing.xxl),

                    // Success Message Card
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 600 : double.infinity,
                      ),
                      child: TulaiCard(
                        child: Column(
                          children: [
                            Text(
                              'Submission Successful!',
                              style: TulaiTextStyles.heading1.copyWith(
                                color: TulaiColors.success,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TulaiSpacing.md),
                            Text(
                              'Matagumpay ang iyong pagsusumite!',
                              style: TulaiTextStyles.heading3.copyWith(
                                color: TulaiColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TulaiSpacing.xl),
                            const Divider(),
                            const SizedBox(height: TulaiSpacing.xl),
                            Icon(
                              Icons.pending_actions,
                              size: 64,
                              color: TulaiColors.primary.withOpacity(0.6),
                            ),
                            const SizedBox(height: TulaiSpacing.lg),
                            Text(
                              'Please Wait for Teacher Review',
                              style: TulaiTextStyles.heading2.copyWith(
                                color: TulaiColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TulaiSpacing.md),
                            Text(
                              'Mangyaring maghintay para sa pagsusuri ng guro',
                              style: TulaiTextStyles.bodyLarge.copyWith(
                                color: TulaiColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TulaiSpacing.xl),
                            // Animated loading indicator
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: TulaiSpacing.xl),
                            Container(
                              padding: const EdgeInsets.all(TulaiSpacing.lg),
                              decoration: BoxDecoration(
                                color: TulaiColors.info.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(TulaiBorderRadius.md),
                                border: Border.all(
                                  color: TulaiColors.info.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
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
                                          'What happens next?',
                                          style: TulaiTextStyles.bodyLarge
                                              .copyWith(
                                            color: TulaiColors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: TulaiSpacing.md),
                                  Text(
                                    '1. The teacher will review your information\n'
                                    '2. They may ask you questions or verify details\n'
                                    '3. Once approved, you\'re officially enrolled!\n'
                                    '4. Please wait here with the device',
                                    style: TulaiTextStyles.bodyMedium.copyWith(
                                      color: TulaiColors.textSecondary,
                                      height: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: TulaiSpacing.sm),
                                  const Divider(),
                                  const SizedBox(height: TulaiSpacing.sm),
                                  Text(
                                    '1. Susuriin ng guro ang iyong impormasyon\n'
                                    '2. Maaari kang tanungin o mag-verify ng detalye\n'
                                    '3. Kapag naaprubahan, opisyal ka nang naka-enroll!\n'
                                    '4. Mangyaring maghintay dito kasama ang device',
                                    style: TulaiTextStyles.bodySmall.copyWith(
                                      color: TulaiColors.textMuted,
                                      height: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: TulaiSpacing.xxl),

                    // Teacher-only button to return to dashboard
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 600 : double.infinity,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showTeacherConfirmation(context);
                        },
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Teacher: Return to Dashboard'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: TulaiSpacing.md,
                            horizontal: TulaiSpacing.lg,
                          ),
                          side: BorderSide(
                            color: TulaiColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTeacherConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: TulaiColors.warning,
                size: 28,
              ),
              const SizedBox(width: TulaiSpacing.sm),
              Text(
                'Teacher Access',
                style: TulaiTextStyles.heading3,
              ),
            ],
          ),
          content: Text(
            'This will return to the teacher dashboard. Only teachers should press this button.\n\n'
            'Make sure the student has handed back the device before proceeding.',
            style: TulaiTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                // Navigate back to root and clear all routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/teacher',
                  (route) => false,
                );
              },
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
              child: const Text('Return to Dashboard'),
            ),
          ],
        );
      },
    );
  }
}
