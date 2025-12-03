import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/core/constants.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/widgets/appbar.dart';

class EnrollmentReview extends StatelessWidget {
  final Map<String, String> answers;

  const EnrollmentReview({super.key, required this.answers});

  String _getSectionTitle(String key) {
    if (key.startsWith('enrollee:')) return 'Personal Information';
    if (key.startsWith('address:')) return 'Address Information';
    if (key.startsWith('others:')) return 'Additional Information';
    if (key.startsWith('father:')) return 'Father/Guardian Information';
    if (key.startsWith('mother:')) return 'Mother/Guardian Information';
    if (key.startsWith('education:')) return 'Educational Background';
    return 'Other Information';
  }

  String _getFormattedQuestion(String key) {
    return _capitalizeText(key.split(':').last);
  }

  String _capitalizeText(String text) {
    if (text.isEmpty) return text;

    // Split by spaces and capitalize each word
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatAnswer(String answer) {
    if (answer.isEmpty) return 'Not provided';
    if (answer.trim() == 'N/A') return 'N/A';

    // Check if it's a name, address, or text that should be title case
    return _capitalizeText(answer.trim());
  }

  List<String> _getAllExpectedFields() {
    // Determine which language set to use based on form language
    final isFilipino = AppConfig().formLanguage == FormLanguage.filipino;

    List<String> allFields = [];

    if (isFilipino) {
      allFields.addAll(formQuestionsNameFilipino.map((q) => 'enrollee:$q'));
      allFields.addAll(formQuestionsAddressFilipino.map((q) => 'address:$q'));
      allFields.addAll(formQuestionsOthersFilipino.map((q) => 'others:$q'));
      allFields
          .addAll(formQuestionsFatherGuardianFilipino.map((q) => 'father:$q'));
      allFields
          .addAll(formQuestionsMotherGuardianFilipino.map((q) => 'mother:$q'));
      allFields.addAll(
          formQuestionsEducationalInfoFilipino.map((q) => 'education:$q'));
    } else {
      allFields.addAll(formQuestionsName.map((q) => 'enrollee:$q'));
      allFields.addAll(formQuestionsAddress.map((q) => 'address:$q'));
      allFields.addAll(formQuestionsOthers.map((q) => 'others:$q'));
      allFields.addAll(formQuestionsFatherGuardian.map((q) => 'father:$q'));
      allFields.addAll(formQuestionsMotherGuardian.map((q) => 'mother:$q'));
      allFields.addAll(formQuestionsEducationalInfo.map((q) => 'education:$q'));
    }

    return allFields;
  }

  Widget _buildSectionGroup(
      String sectionTitle, List<MapEntry<String, String>> sectionAnswers) {
    return TulaiCard(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TulaiSpacing.md,
              vertical: TulaiSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: TulaiColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(sectionTitle),
                  color: TulaiColors.primary,
                  size: 20,
                ),
                const SizedBox(width: TulaiSpacing.sm),
                Text(
                  sectionTitle,
                  style: TulaiTextStyles.heading3.copyWith(
                    color: TulaiColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TulaiSpacing.md),
          // Section content
          ...sectionAnswers.asMap().entries.map((entry) {
            final index = entry.key;
            final answer = entry.value;
            final isLast = index == sectionAnswers.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnswerItem(
                  _getFormattedQuestion(answer.key),
                  answer.value,
                ),
                if (!isLast)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: TulaiSpacing.sm),
                    height: 1,
                    color: TulaiColors.borderLight,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(String question, String answer) {
    final isEmpty = answer.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TulaiSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                question,
                style: TulaiTextStyles.labelMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              if (isEmpty) ...[
                const SizedBox(width: TulaiSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                  ),
                  child: Text(
                    'Missing',
                    style: TulaiTextStyles.caption.copyWith(
                      color: TulaiColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: TulaiSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TulaiSpacing.sm),
            decoration: BoxDecoration(
              color: isEmpty
                  ? TulaiColors.error.withOpacity(0.05)
                  : TulaiColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
              border: Border.all(
                color: isEmpty
                    ? TulaiColors.error.withOpacity(0.3)
                    : TulaiColors.borderLight,
                width: 1,
              ),
            ),
            child: Text(
              _formatAnswer(answer),
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: isEmpty ? TulaiColors.error : TulaiColors.textPrimary,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String sectionTitle) {
    switch (sectionTitle) {
      case 'Personal Information':
        return Icons.person;
      case 'Address Information':
        return Icons.home;
      case 'Additional Information':
        return Icons.info;
      case 'Father/Guardian Information':
        return Icons.man;
      case 'Mother/Guardian Information':
        return Icons.woman;
      case 'Educational Background':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Get all expected fields and create complete entries
    final allExpectedFields = _getAllExpectedFields();
    final completeAnswers = <String, String>{};

    // Fill in answers for all expected fields
    for (final field in allExpectedFields) {
      completeAnswers[field] =
          answers[field] ?? ''; // Use empty string if no answer
    }

    // Group complete answers by section
    final groupedAnswers = <String, List<MapEntry<String, String>>>{};
    for (final answer in completeAnswers.entries) {
      final sectionTitle = _getSectionTitle(answer.key);
      groupedAnswers.putIfAbsent(sectionTitle, () => []).add(answer);
    }

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Header with back button and title
                Container(
                  padding: const EdgeInsets.all(TulaiSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Back button
                      Container(
                        decoration: BoxDecoration(
                          color: TulaiColors.backgroundPrimary,
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: TulaiColors.primary,
                          ),
                        ),
                      ),
                      // Center: Title
                      Expanded(
                        child: Text(
                          'Review Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TulaiColors.primary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Right: Info icon
                      Container(
                        decoration: BoxDecoration(
                          color: TulaiColors.backgroundPrimary,
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please review all information carefully before submitting.',
                                  style: TulaiTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: TulaiColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.sm),
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.info_outline,
                            size: 28,
                            color: TulaiColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02), // 2vh spacing

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TulaiSpacing.lg),
                    child: Column(
                      children: [
                        // Summary card
                        TulaiCard(
                          margin:
                              const EdgeInsets.only(bottom: TulaiSpacing.lg),
                          backgroundColor:
                              TulaiColors.primary.withOpacity(0.05),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: TulaiColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: TulaiSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enrollment Summary',
                                      style: TulaiTextStyles.heading3.copyWith(
                                        color: TulaiColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: TulaiSpacing.xs),
                                    Text(
                                      'Completed: ${answers.length} of ${completeAnswers.length} fields • '
                                      '${groupedAnswers.length} sections',
                                      style: TulaiTextStyles.caption.copyWith(
                                        color: TulaiColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.summarize,
                                color: TulaiColors.primary,
                                size: 28,
                              ),
                            ],
                          ),
                        ),

                        // Section groups
                        ...groupedAnswers.entries.map(
                          (sectionEntry) => _buildSectionGroup(
                              sectionEntry.key, sectionEntry.value),
                        ),

                        const SizedBox(height: TulaiSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: TulaiSpacing.lg,
          right: TulaiSpacing.lg,
          top: TulaiSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + TulaiSpacing.md,
        ),
        decoration: BoxDecoration(
          color: TulaiColors.backgroundPrimary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: TulaiButton(
            text: 'Confirm and Submit',
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: TulaiButtonStyle.primary,
            size: TulaiButtonSize.large,
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
