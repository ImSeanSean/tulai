import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/services/student_db.dart';

class EnrolleeInformation extends StatelessWidget {
  final Student student;

  const EnrolleeInformation({super.key, required this.student});

  String getFullName() {
    final parts = [
      student.firstName,
      student.middleName,
      student.lastName,
      student.nameExtension,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(' ');
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat.yMMMMd().format(date);
  }

  Widget buildInfoRow(String label, String? value, BuildContext context) {
    return Container(
      width: TulaiResponsive.responsive<double>(
        context: context,
        mobile: double.infinity,
        tablet: 300,
        desktop: 250,
      ),
      margin: const EdgeInsets.symmetric(vertical: TulaiSpacing.xs),
      padding: const EdgeInsets.all(TulaiSpacing.md),
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        border: Border.all(color: TulaiColors.borderLight, width: 1),
        borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
        boxShadow: TulaiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TulaiTextStyles.labelLarge.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
          const SizedBox(height: TulaiSpacing.sm),
          Text(
            value?.isNotEmpty == true ? value! : 'N/A',
            style: TulaiTextStyles.bodyLarge.copyWith(
              color: value?.isNotEmpty == true
                  ? TulaiColors.textPrimary
                  : TulaiColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);
    final fullName = getFullName();
    final displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TulaiColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Student Information',
          style: TulaiTextStyles.heading3,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with student name and avatar
            TulaiCard(
              margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TulaiColors.primary, TulaiColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(TulaiBorderRadius.round),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(displayName),
                        style: TulaiTextStyles.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TulaiTextStyles.heading2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: TulaiSpacing.xs),
                        if (student.municipalityCity != null)
                          Text(
                            student.municipalityCity!,
                            style: TulaiTextStyles.bodyMedium.copyWith(
                              color: TulaiColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: TulaiSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TulaiSpacing.md,
                            vertical: TulaiSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: TulaiColors.success.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.xl),
                            border: Border.all(
                              color: TulaiColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Enrolled ${student.created_at != null ? _getRelativeTime(student.created_at!) : 'Recently'}',
                            style: TulaiTextStyles.labelSmall.copyWith(
                              color: TulaiColors.success,
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

            // Personal Information Section
            _buildSection(
              context,
              'Personal Information',
              [
                buildInfoRow("Last Name", student.lastName, context),
                buildInfoRow("First Name", student.firstName, context),
                buildInfoRow("Middle Name", student.middleName, context),
                buildInfoRow("Name Extension", student.nameExtension, context),
              ],
            ),

            // Address Section
            _buildSection(
              context,
              'Address',
              [
                buildInfoRow(
                    "House/Street/Sitio", student.houseStreetSitio, context),
                buildInfoRow("Barangay", student.barangay, context),
                buildInfoRow(
                    "Municipality/City", student.municipalityCity, context),
                buildInfoRow("Province", student.province, context),
              ],
            ),

            // Other Information Section
            _buildSection(
              context,
              'Other Information',
              [
                buildInfoRow("Sex", student.sex, context),
                buildInfoRow(
                    "Birthdate", formatDate(student.birthdate), context),
                buildInfoRow("Place of Birth", student.placeOfBirth, context),
                buildInfoRow("Civil Status", student.civilStatus, context),
                buildInfoRow("Religion", student.religion, context),
                buildInfoRow("Ethnic Group", student.ethnicGroup, context),
                buildInfoRow("Mother Tongue", student.motherTongue, context),
                buildInfoRow("Contact Number", student.contactNumber, context),
                buildInfoRow(
                    "PWD", student.isPWD == true ? "Yes" : "No", context),
              ],
            ),

            // Parents' Information Section
            _buildSection(
              context,
              "Parents' Information",
              [
                buildInfoRow(
                    "Father's Last Name", student.fatherLastName, context),
                buildInfoRow(
                    "Father's First Name", student.fatherFirstName, context),
                buildInfoRow(
                    "Father's Middle Name", student.fatherMiddleName, context),
                buildInfoRow(
                    "Father's Occupation", student.fatherOccupation, context),
                buildInfoRow(
                    "Mother's Last Name", student.motherLastName, context),
                buildInfoRow(
                    "Mother's First Name", student.motherFirstName, context),
                buildInfoRow(
                    "Mother's Middle Name", student.motherMiddleName, context),
                buildInfoRow(
                    "Mother's Occupation", student.motherOccupation, context),
              ],
            ),

            // Educational Background Section
            _buildSection(
              context,
              'Educational Background',
              [
                buildInfoRow("Last School Attended", student.lastSchoolAttended,
                    context),
                buildInfoRow("Last Grade Level Completed",
                    student.lastGradeLevelCompleted, context),
                buildInfoRow("Reason for Incomplete Schooling",
                    student.reasonForIncompleteSchooling, context),
                buildInfoRow("Attended ALS Before",
                    student.hasAttendedALS == true ? "Yes" : "No", context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build sections
  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

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
          if (isLargeScreen)
            // Grid layout for larger screens
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: TulaiSpacing.md,
              mainAxisSpacing: TulaiSpacing.md,
              childAspectRatio: 2.5,
              children: children,
            )
          else
            // Column layout for mobile
            Column(
              children: children
                  .map((child) => Padding(
                        padding: const EdgeInsets.only(bottom: TulaiSpacing.sm),
                        child: child,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // Helper method to get initials
  String _getInitials(String fullName) {
    final words =
        fullName.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'NA';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'NA';
    }

    final firstInitial = words.first.isNotEmpty ? words.first[0] : '';
    final lastInitial = words.last.isNotEmpty ? words.last[0] : '';

    if (firstInitial.isEmpty && lastInitial.isEmpty) return 'NA';
    if (firstInitial.isEmpty) return lastInitial.toUpperCase();
    if (lastInitial.isEmpty) return firstInitial.toUpperCase();

    return '${firstInitial}${lastInitial}'.toUpperCase();
  }

  // Helper method to get relative time
  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat.yMMMd().format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}
