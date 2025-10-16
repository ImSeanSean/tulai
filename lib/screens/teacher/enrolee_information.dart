import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/services/student_db.dart';
import 'package:tulai/screens/teacher/edit_student.dart';
import 'package:tulai/services/student_export_service.dart';

class EnrolleeInformation extends StatefulWidget {
  final Student student;

  const EnrolleeInformation({super.key, required this.student});

  @override
  State<EnrolleeInformation> createState() => _EnrolleeInformationState();
}

class _EnrolleeInformationState extends State<EnrolleeInformation> {
  final _supabase = Supabase.instance.client;
  late Student _student;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  String getFullName() {
    final parts = [
      _student.firstName,
      _student.middleName,
      _student.lastName,
      _student.nameExtension,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(' ');
  }

  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: TulaiColors.error),
            SizedBox(width: TulaiSpacing.sm),
            Text('Delete Student'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${getFullName()}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_student.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete: Student ID not found'),
            backgroundColor: TulaiColors.error,
          ),
        );
        return;
      }

      try {
        await _supabase.from('students').delete().eq('id', _student.id!);

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${getFullName()} deleted successfully'),
              backgroundColor: TulaiColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting student: $e'),
              backgroundColor: TulaiColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editStudent() async {
    final updatedStudent = await Navigator.push<Student>(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudent(student: _student),
      ),
    );

    // If student was updated, refresh the data
    if (updatedStudent != null) {
      setState(() {
        _student = updatedStudent;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _student = widget.student; // Revert changes
    });
  }

  Future<void> _saveChanges() async {
    if (_student.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save: Student ID not found'),
          backgroundColor: TulaiColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _supabase
          .from('students')
          .update(_student.toMap())
          .eq('id', _student.id!);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student information updated successfully'),
            backgroundColor: TulaiColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating student: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportAsExcel() async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(TulaiSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: TulaiSpacing.md),
                  Text('Exporting to Excel...'),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await StudentExportService.exportStudentToExcel(_student);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully: ${result.split('/').last}'),
            backgroundColor: TulaiColors.success,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportAsPdf() async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(TulaiSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: TulaiSpacing.md),
                  Text('Exporting to PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await StudentExportService.exportStudentToPdf(_student);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully: ${result.split('/').last}'),
            backgroundColor: TulaiColors.success,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _previewPdf() async {
    try {
      await StudentExportService.previewStudentPdf(_student);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview failed: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TulaiBorderRadius.lg)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(TulaiSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: TulaiColors.primary),
              title: const Text('Edit Student Information'),
              onTap: () {
                Navigator.pop(context);
                _editStudent();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.file_download, color: TulaiColors.secondary),
              title: const Text('Export as Excel'),
              subtitle: const Text('Download student data as spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportAsExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf,
                  color: TulaiColors.secondary),
              title: const Text('Export as PDF'),
              subtitle: const Text('Download student data as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPdf();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.print, color: TulaiColors.textSecondary),
              title: const Text('Print Preview'),
              subtitle: const Text('Preview and print student information'),
              onTap: () {
                Navigator.pop(context);
                _previewPdf();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: TulaiColors.error),
              title: const Text('Delete Student'),
              onTap: () {
                Navigator.pop(context);
                _deleteStudent();
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat.yMMMMd().format(date);
  }

  Widget buildInfoRow(String label, String? value, BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Container(
      width: TulaiResponsive.responsive<double>(
        context: context,
        mobile: double.infinity,
        tablet: 240,
        desktop: 220,
      ),
      margin: EdgeInsets.symmetric(
        vertical: isLargeScreen ? TulaiSpacing.xs / 2 : TulaiSpacing.xs,
      ),
      padding: isLargeScreen
          ? const EdgeInsets.fromLTRB(
              TulaiSpacing.sm,
              TulaiSpacing.sm,
              TulaiSpacing.sm,
              TulaiSpacing.xs, // Less padding at bottom
            )
          : const EdgeInsets.all(TulaiSpacing.md),
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
            style: (isLargeScreen
                    ? TulaiTextStyles.labelMedium
                    : TulaiTextStyles.labelLarge)
                .copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
          SizedBox(height: isLargeScreen ? 4 : TulaiSpacing.xs),
          Text(
            value?.isNotEmpty == true ? value! : 'N/A',
            style: (isLargeScreen
                    ? TulaiTextStyles.bodyMedium
                    : TulaiTextStyles.bodyLarge)
                .copyWith(
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
          icon: Icon(
            _isEditing ? Icons.close : Icons.arrow_back,
            color: TulaiColors.textPrimary,
          ),
          onPressed:
              _isEditing ? _cancelEdit : () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Student' : 'Student Information',
          style: TulaiTextStyles.heading3,
        ),
        actions: _isEditing
            ? [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.all(TulaiSpacing.md),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _saveChanges,
                    child: Text(
                      'SAVE',
                      style: TulaiTextStyles.bodyLarge.copyWith(
                        color: TulaiColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: TulaiSpacing.sm),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit, color: TulaiColors.primary),
                  tooltip: 'Edit Student',
                  onPressed: _editStudent,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: TulaiColors.textPrimary),
                  tooltip: 'More Options',
                  onPressed: _showMoreOptions,
                ),
                const SizedBox(width: TulaiSpacing.sm),
              ],
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with student name and avatar
            TulaiCard(
              margin: EdgeInsets.only(
                  bottom: isLargeScreen ? TulaiSpacing.md : TulaiSpacing.lg),
              padding: EdgeInsets.all(
                  isLargeScreen ? TulaiSpacing.md : TulaiSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: isLargeScreen ? 60 : 80,
                    height: isLargeScreen ? 60 : 80,
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
                        style: (isLargeScreen
                                ? TulaiTextStyles.heading3
                                : TulaiTextStyles.heading2)
                            .copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      width: isLargeScreen ? TulaiSpacing.md : TulaiSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: (isLargeScreen
                              ? TulaiTextStyles.heading3
                              : TulaiTextStyles.heading2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isLargeScreen ? 4 : TulaiSpacing.xs),
                        if (_student.municipalityCity != null)
                          Text(
                            _student.municipalityCity!,
                            style: (isLargeScreen
                                    ? TulaiTextStyles.bodyMedium
                                    : TulaiTextStyles.bodyLarge)
                                .copyWith(
                              color: TulaiColors.textSecondary,
                            ),
                          ),
                        SizedBox(
                            height: isLargeScreen
                                ? TulaiSpacing.xs
                                : TulaiSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen
                                ? TulaiSpacing.sm
                                : TulaiSpacing.md,
                            vertical: isLargeScreen ? 4 : TulaiSpacing.xs,
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
                            'Enrolled ${_student.created_at != null ? _getRelativeTime(_student.created_at!) : 'Recently'}',
                            style: (isLargeScreen
                                    ? TulaiTextStyles.labelSmall
                                    : TulaiTextStyles.labelSmall)
                                .copyWith(
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
                buildInfoRow("Last Name", _student.lastName, context),
                buildInfoRow("First Name", _student.firstName, context),
                buildInfoRow("Middle Name", _student.middleName, context),
                buildInfoRow("Name Extension", _student.nameExtension, context),
              ],
            ),

            // Address Section
            _buildSection(
              context,
              'Address',
              [
                buildInfoRow(
                    "House/Street/Sitio", _student.houseStreetSitio, context),
                buildInfoRow("Barangay", _student.barangay, context),
                buildInfoRow(
                    "Municipality/City", _student.municipalityCity, context),
                buildInfoRow("Province", _student.province, context),
              ],
            ),

            // Other Information Section
            _buildSection(
              context,
              'Other Information',
              [
                buildInfoRow("Sex", _student.sex, context),
                buildInfoRow(
                    "Birthdate", formatDate(_student.birthdate), context),
                buildInfoRow("Place of Birth", _student.placeOfBirth, context),
                buildInfoRow("Civil Status", _student.civilStatus, context),
                buildInfoRow("Religion", _student.religion, context),
                buildInfoRow("Ethnic Group", _student.ethnicGroup, context),
                buildInfoRow("Mother Tongue", _student.motherTongue, context),
                buildInfoRow("Contact Number", _student.contactNumber, context),
                buildInfoRow(
                    "PWD", _student.isPWD == true ? "Yes" : "No", context),
              ],
            ),

            // Parents' Information Section
            _buildSection(
              context,
              "Parents' Information",
              [
                buildInfoRow(
                    "Father's Last Name", _student.fatherLastName, context),
                buildInfoRow(
                    "Father's First Name", _student.fatherFirstName, context),
                buildInfoRow(
                    "Father's Middle Name", _student.fatherMiddleName, context),
                buildInfoRow(
                    "Father's Occupation", _student.fatherOccupation, context),
                buildInfoRow(
                    "Mother's Last Name", _student.motherLastName, context),
                buildInfoRow(
                    "Mother's First Name", _student.motherFirstName, context),
                buildInfoRow(
                    "Mother's Middle Name", _student.motherMiddleName, context),
                buildInfoRow(
                    "Mother's Occupation", _student.motherOccupation, context),
              ],
            ),

            // Educational Background Section
            _buildSection(
              context,
              'Educational Background',
              [
                buildInfoRow("Last School Attended",
                    _student.lastSchoolAttended, context),
                buildInfoRow("Last Grade Level Completed",
                    _student.lastGradeLevelCompleted, context),
                buildInfoRow("Reason for Incomplete Schooling",
                    _student.reasonForIncompleteSchooling, context),
                buildInfoRow("Attended ALS Before",
                    _student.hasAttendedALS == true ? "Yes" : "No", context),
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
      margin: EdgeInsets.only(
          bottom: isLargeScreen ? TulaiSpacing.md : TulaiSpacing.lg),
      padding: isLargeScreen ? const EdgeInsets.all(TulaiSpacing.lg) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TulaiTextStyles.heading3.copyWith(
              color: TulaiColors.primary,
              fontSize: isLargeScreen ? 18 : null,
            ),
          ),
          SizedBox(height: isLargeScreen ? TulaiSpacing.sm : TulaiSpacing.md),
          if (isLargeScreen)
            // Grid layout for larger screens - more columns for compact view
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: TulaiSpacing.sm,
              mainAxisSpacing: TulaiSpacing.sm,
              childAspectRatio: 2.2,
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
