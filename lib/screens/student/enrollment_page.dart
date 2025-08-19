import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/student/enrollment_question.dart';
import 'package:tulai/widgets/appbar.dart';

class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({super.key});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: const CustomAppBar(),
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
              // Back button with design system styling
              Container(
                decoration: BoxDecoration(
                  color: TulaiColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  boxShadow: TulaiShadows.sm,
                ),
                child: IconButton(
                  iconSize: 24,
                  icon: Icon(
                    Icons.arrow_back,
                    color: TulaiColors.primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Dynamic spacer that adapts to screen size
              SizedBox(
                height: isLargeScreen
                    ? MediaQuery.of(context).size.height * 0.05
                    : TulaiSpacing.xxl,
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

                      // Language buttons with enhanced styling
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
                                builder: (context) =>
                                    const EnrollmentQuestions(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: TulaiSpacing.lg),

                      SizedBox(
                        width: isLargeScreen ? 450 : double.infinity,
                        child: TulaiButton(
                          text: 'Filipino o Tagalog',
                          style: TulaiButtonStyle.secondary,
                          size: TulaiButtonSize.large,
                          onPressed: () {
                            AppConfig().formLanguage = FormLanguage.filipino;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EnrollmentQuestions(),
                              ),
                            );
                          },
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
                                'Your language choice will be used throughout the enrollment process.',
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
