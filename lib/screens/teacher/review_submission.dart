import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/services/student_db.dart';

class ReviewSubmission extends StatefulWidget {
  final Map<String, dynamic> submission;

  const ReviewSubmission({super.key, required this.submission});

  @override
  State<ReviewSubmission> createState() => _ReviewSubmissionState();
}

class _ReviewSubmissionState extends State<ReviewSubmission> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isSaving = false;
  List<Map<String, dynamic>> _potentialDuplicates = [];
  bool _isCheckingDuplicates = true;

  final List<FieldGroup> _fieldGroups = [
    FieldGroup(
      title: 'Personal Information',
      icon: Icons.person,
      fields: [
        FieldInfo('last_name', 'Last Name', required: true),
        FieldInfo('first_name', 'First Name', required: true),
        FieldInfo('middle_name', 'Middle Name'),
        FieldInfo('name_extension', 'Name Extension'),
      ],
    ),
    FieldGroup(
      title: 'Address Information',
      icon: Icons.location_on,
      fields: [
        FieldInfo('house_street_sitio', 'House No./Street/Sitio'),
        FieldInfo('barangay', 'Barangay', required: true),
        FieldInfo('municipality_city', 'Municipality/City', required: true),
        FieldInfo('province', 'Province', required: true),
      ],
    ),
    FieldGroup(
      title: 'Personal Details',
      icon: Icons.info,
      fields: [
        FieldInfo('birthdate', 'Birthdate', type: FieldType.date),
        FieldInfo('sex', 'Sex',
            type: FieldType.dropdown, options: ['Male', 'Female']),
        FieldInfo('place_of_birth', 'Place of Birth'),
        FieldInfo('civil_status', 'Civil Status',
            type: FieldType.dropdown,
            options: [
              'Single',
              'Married',
              'Separated',
              'Widowed',
              'Solo Parent'
            ]),
        FieldInfo('religion', 'Religion', type: FieldType.dropdown, options: [
          'Roman Catholic',
          'Islam',
          'Iglesia ni Cristo',
          'Born Again Christian',
          'Seventh-day Adventist',
          'Buddhism',
          'Other'
        ]),
        FieldInfo('ethnic_group', 'Ethnic Group/IP'),
        FieldInfo('mother_tongue', 'Mother Tongue'),
        FieldInfo('contact_number', 'Contact Number'),
        FieldInfo('is_pwd', 'PWD', type: FieldType.checkbox),
      ],
    ),
    FieldGroup(
      title: 'Father/Guardian Information',
      icon: Icons.man,
      fields: [
        FieldInfo('father_last_name', 'Father/Guardian Last Name'),
        FieldInfo('father_first_name', 'Father/Guardian First Name'),
        FieldInfo('father_middle_name', 'Father/Guardian Middle Name'),
        FieldInfo('father_occupation', 'Father/Guardian Occupation'),
      ],
    ),
    FieldGroup(
      title: 'Mother/Guardian Information',
      icon: Icons.woman,
      fields: [
        FieldInfo('mother_last_name', 'Mother/Guardian Last Name'),
        FieldInfo('mother_first_name', 'Mother/Guardian First Name'),
        FieldInfo('mother_middle_name', 'Mother/Guardian Middle Name'),
        FieldInfo('mother_occupation', 'Mother/Guardian Occupation'),
      ],
    ),
    FieldGroup(
      title: 'Educational Background',
      icon: Icons.school,
      fields: [
        FieldInfo('last_school_attended', 'Last School Attended'),
        FieldInfo('last_grade_level_completed', 'Last Grade Level Completed'),
        FieldInfo('reason_for_incomplete_schooling',
            'Reason for Incomplete Schooling',
            maxLines: 3),
        FieldInfo('has_attended_als', 'Has Attended ALS Before',
            type: FieldType.checkbox),
      ],
    ),
  ];

  String? _normalizeSex(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'lalaki' || lower == 'male') return 'Male';
    if (lower == 'babae' || lower == 'female') return 'Female';
    return value;
  }

  String? _normalizeCivilStatus(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'binata' || lower == 'dalaga' || lower == 'single')
      return 'Single';
    if (lower == 'kasal' || lower == 'married') return 'Married';
    if (lower == 'hiwalay' || lower == 'separated') return 'Separated';
    if (lower == 'biyudo/a' ||
        lower == 'balo' ||
        lower == 'widowed' ||
        lower == 'widower') return 'Widowed';
    if (lower.contains('solo parent')) return 'Solo Parent';
    return value;
  }

  String? _normalizeReligion(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower.contains('catholic') || lower == 'katoliko')
      return 'Roman Catholic';
    if (lower.contains('islam') || lower.contains('muslim')) return 'Islam';
    if (lower.contains('iglesia')) return 'Iglesia ni Cristo';
    if (lower.contains('born again')) return 'Born Again Christian';
    if (lower.contains('adventist') || lower.contains('seventh'))
      return 'Seventh-day Adventist';
    if (lower.contains('buddhis')) return 'Buddhism';
    return 'Other';
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkForDuplicates();
  }

  Future<void> _checkForDuplicates() async {
    final firstName = widget.submission['first_name']?.toString().trim();
    final lastName = widget.submission['last_name']?.toString().trim();
    final birthdate = widget.submission['birthdate'];

    if (firstName == null || lastName == null || birthdate == null) {
      setState(() => _isCheckingDuplicates = false);
      return;
    }

    try {
      final existingStudents = await _supabase
          .from('students')
          .select(
              'id, first_name, last_name, middle_name, birthdate, contact_number, barangay, batch_id')
          .ilike('first_name', firstName)
          .ilike('last_name', lastName)
          .eq('birthdate', birthdate);

      setState(() {
        _potentialDuplicates =
            List<Map<String, dynamic>>.from(existingStudents);
        _isCheckingDuplicates = false;
      });
    } catch (e) {
      debugPrint('Error checking duplicates: $e');
      setState(() => _isCheckingDuplicates = false);
    }
  }

  void _initializeControllers() {
    _controllers = {};
    for (var group in _fieldGroups) {
      for (var field in group.fields) {
        var value = widget.submission[field.key];

        // Normalize dropdown fields
        if (field.key == 'sex') {
          value = _normalizeSex(value?.toString());
        } else if (field.key == 'civil_status') {
          value = _normalizeCivilStatus(value?.toString());
        } else if (field.key == 'religion') {
          value = _normalizeReligion(value?.toString());
        }

        if (field.type == FieldType.checkbox) {
          _controllers[field.key] = TextEditingController(
            text: value?.toString() ?? 'false',
          );
        } else if (field.type == FieldType.date && value != null) {
          try {
            final date = DateTime.parse(value.toString());
            _controllers[field.key] = TextEditingController(
              text:
                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}',
            );
          } catch (e) {
            _controllers[field.key] =
                TextEditingController(text: value.toString());
          }
        } else {
          _controllers[field.key] = TextEditingController(
            text: value?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _approveSubmission() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: TulaiSpacing.sm),
              const Text('Please fill all required fields'),
            ],
          ),
          backgroundColor: TulaiColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: TulaiColors.success),
            const SizedBox(width: TulaiSpacing.sm),
            Text('Approve Submission', style: TulaiTextStyles.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to approve this submission? The student will be added to the enrollee database.',
          style: TulaiTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      // Create student record
      final student = Student(
        lastName: _controllers['last_name']!.text.trim(),
        firstName: _controllers['first_name']!.text.trim(),
        middleName: _controllers['middle_name']?.text.trim(),
        nameExtension: _controllers['name_extension']?.text.trim(),
        houseStreetSitio: _controllers['house_street_sitio']?.text.trim(),
        barangay: _controllers['barangay']!.text.trim(),
        municipalityCity: _controllers['municipality_city']!.text.trim(),
        province: _controllers['province']!.text.trim(),
        birthdate: _parseDateString(_controllers['birthdate']?.text),
        sex: _controllers['sex']?.text.trim(),
        placeOfBirth: _controllers['place_of_birth']?.text.trim(),
        civilStatus: _controllers['civil_status']?.text.trim(),
        religion: _controllers['religion']?.text.trim(),
        ethnicGroup: _controllers['ethnic_group']?.text.trim(),
        motherTongue: _controllers['mother_tongue']?.text.trim(),
        contactNumber: _controllers['contact_number']?.text.trim(),
        isPWD: _controllers['is_pwd']?.text == 'true',
        fatherLastName: _controllers['father_last_name']?.text.trim(),
        fatherFirstName: _controllers['father_first_name']?.text.trim(),
        fatherMiddleName: _controllers['father_middle_name']?.text.trim(),
        fatherOccupation: _controllers['father_occupation']?.text.trim(),
        motherLastName: _controllers['mother_last_name']?.text.trim(),
        motherFirstName: _controllers['mother_first_name']?.text.trim(),
        motherMiddleName: _controllers['mother_middle_name']?.text.trim(),
        motherOccupation: _controllers['mother_occupation']?.text.trim(),
        lastSchoolAttended: _controllers['last_school_attended']?.text.trim(),
        lastGradeLevelCompleted:
            _controllers['last_grade_level_completed']?.text.trim(),
        reasonForIncompleteSchooling:
            _controllers['reason_for_incomplete_schooling']?.text.trim(),
        hasAttendedALS: _controllers['has_attended_als']?.text == 'true',
      );

      // Insert into students table
      await StudentDatabase.insertStudent(student);

      // Delete from pending_submissions
      await _supabase
          .from('pending_submissions')
          .delete()
          .eq('id', widget.submission['id']);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                const Text('Student approved and added successfully'),
              ],
            ),
            backgroundColor: TulaiColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving submission: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _reEnrollExistingStudent(
      Map<String, dynamic> existingStudent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: TulaiColors.primary),
            const SizedBox(width: TulaiSpacing.sm),
            const Text('Confirm Re-enrollment'),
          ],
        ),
        content: Text(
          'This will re-enroll the existing student to the active batch and discard this submission. Continue?',
          style: TulaiTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Re-enroll'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      // Get the active batch
      final batchResponse = await _supabase
          .from('batches')
          .select('id')
          .eq('is_active', true)
          .single();

      final activeBatchId = batchResponse['id'];

      // Update the existing student's batch_id to re-enroll them
      await _supabase
          .from('students')
          .update({'batch_id': activeBatchId}).eq('id', existingStudent['id']);

      // Delete the pending submission
      await _supabase
          .from('pending_submissions')
          .delete()
          .eq('id', widget.submission['id']);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                const Expanded(
                  child: Text('Student re-enrolled successfully'),
                ),
              ],
            ),
            backgroundColor: TulaiColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error re-enrolling student: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReEnrollDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: TulaiColors.primary),
            const SizedBox(width: TulaiSpacing.sm),
            const Expanded(
              child: Text('Re-enroll Existing Student'),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select which existing student to re-enroll to the active batch:',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.md),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _potentialDuplicates.length,
                  itemBuilder: (context, index) {
                    final student = _potentialDuplicates[index];
                    final fullName = [
                      student['first_name'],
                      student['middle_name'],
                      student['last_name'],
                    ]
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .join(' ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: TulaiSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TulaiColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: TulaiColors.primary,
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TulaiTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (student['barangay'] != null)
                              Text(
                                'Barangay: ${student['barangay']}',
                                style: TulaiTextStyles.caption,
                              ),
                            if (student['contact_number'] != null)
                              Text(
                                'Contact: ${student['contact_number']}',
                                style: TulaiTextStyles.caption,
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _reEnrollExistingStudent(student);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TulaiColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: TulaiSpacing.md,
                              vertical: TulaiSpacing.sm,
                            ),
                          ),
                          child: const Text('Re-enroll'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Try MM/DD/YYYY format
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      // Try ISO format
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Review Information',
          style: TulaiTextStyles.heading3.copyWith(color: Colors.white),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(TulaiSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.md),
              color: TulaiColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: TulaiColors.warning),
                  const SizedBox(width: TulaiSpacing.sm),
                  Expanded(
                    child: Text(
                      'Review all information carefully before approving. Check for missing or incorrect data.',
                      style: TulaiTextStyles.bodySmall.copyWith(
                        color: TulaiColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Duplicate warning banner
            if (_isCheckingDuplicates)
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.md),
                color: TulaiColors.info.withOpacity(0.1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: TulaiColors.info,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: TulaiSpacing.md),
                    Expanded(
                      child: Text(
                        'Checking for potential duplicates...',
                        style: TulaiTextStyles.bodySmall.copyWith(
                          color: TulaiColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_potentialDuplicates.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.md),
                color: TulaiColors.error.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: TulaiColors.error,
                          size: 24,
                        ),
                        const SizedBox(width: TulaiSpacing.sm),
                        Expanded(
                          child: Text(
                            'Potential Duplicate Enrollment Detected',
                            style: TulaiTextStyles.labelLarge.copyWith(
                              color: TulaiColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TulaiSpacing.sm),
                    Text(
                      'Found ${_potentialDuplicates.length} existing student(s) with the same name and birthdate. You can re-enroll the existing student instead of creating a duplicate.',
                      style: TulaiTextStyles.bodySmall.copyWith(
                        color: TulaiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: TulaiSpacing.md),
                    Wrap(
                      spacing: TulaiSpacing.sm,
                      runSpacing: TulaiSpacing.sm,
                      children: _potentialDuplicates.map((student) {
                        final fullName = [
                          student['first_name'],
                          student['middle_name'],
                          student['last_name'],
                        ]
                            .where((e) => e != null && e.toString().isNotEmpty)
                            .join(' ');

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TulaiSpacing.sm,
                            vertical: TulaiSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: TulaiColors.backgroundPrimary,
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.sm),
                            border: Border.all(
                              color: TulaiColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: TulaiColors.textSecondary,
                              ),
                              const SizedBox(width: TulaiSpacing.xs),
                              Text(
                                fullName,
                                style: TulaiTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (student['barangay'] != null) ...[
                                Text(
                                  ' • ${student['barangay']}',
                                  style: TulaiTextStyles.caption.copyWith(
                                    color: TulaiColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: TulaiSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _showReEnrollDialog,
                        icon: const Icon(Icons.person_add, size: 20),
                        label: const Text('Use Existing Student & Re-enroll'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TulaiColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: TulaiSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                    isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var group in _fieldGroups)
                      _buildFieldGroup(group, isLargeScreen),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(
                  isLargeScreen ? TulaiSpacing.lg : TulaiSpacing.md),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: TulaiSpacing.md,
                        ),
                        side: BorderSide(color: TulaiColors.textSecondary),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _approveSubmission,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve & Add Student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TulaiColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: TulaiSpacing.md,
                        ),
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

  Widget _buildFieldGroup(FieldGroup group, bool isLargeScreen) {
    return TulaiCard(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, color: TulaiColors.primary),
              const SizedBox(width: TulaiSpacing.sm),
              Text(
                group.title,
                style: TulaiTextStyles.heading3.copyWith(
                  color: TulaiColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TulaiSpacing.lg),
          Wrap(
            spacing: TulaiSpacing.md,
            runSpacing: TulaiSpacing.md,
            children: group.fields.map((field) {
              return SizedBox(
                width: isLargeScreen
                    ? (MediaQuery.of(context).size.width -
                            (TulaiSpacing.xl * 2) -
                            (TulaiSpacing.lg * 2) -
                            TulaiSpacing.md) /
                        2
                    : double.infinity,
                child: _buildField(field),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FieldInfo field) {
    if (field.type == FieldType.checkbox) {
      return CheckboxListTile(
        title: Text(field.label),
        value: _controllers[field.key]?.text == 'true',
        onChanged: (value) {
          setState(() {
            _controllers[field.key]?.text = value.toString();
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      );
    }

    if (field.type == FieldType.dropdown) {
      return DropdownButtonFormField<String>(
        value: _controllers[field.key]?.text.isEmpty == true
            ? null
            : _controllers[field.key]?.text,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
          ),
        ),
        items: field.options?.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _controllers[field.key]?.text = value ?? '';
          });
        },
        validator: field.required
            ? (value) => value?.isEmpty == true ? 'Required' : null
            : null,
      );
    }

    return TextFormField(
      controller: _controllers[field.key],
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
          borderSide: BorderSide(color: TulaiColors.primary, width: 2),
        ),
        helperText: _getHelperText(field),
        helperStyle: TextStyle(
          color: _isFieldMissingOrSuspicious(field)
              ? TulaiColors.warning
              : TulaiColors.textMuted,
        ),
      ),
      maxLines: field.maxLines ?? 1,
      validator: field.required
          ? (value) => value?.trim().isEmpty == true ? 'Required' : null
          : null,
      onTap: field.type == FieldType.date
          ? () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _controllers[field.key]?.text =
                      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                });
              }
            }
          : null,
      readOnly: field.type == FieldType.date,
    );
  }

  bool _isFieldMissingOrSuspicious(FieldInfo field) {
    final value = _controllers[field.key]?.text ?? '';
    if (field.required && value.trim().isEmpty) {
      return true;
    }
    // Add more validation logic as needed
    return false;
  }

  String? _getHelperText(FieldInfo field) {
    final value = _controllers[field.key]?.text ?? '';
    if (field.required && value.trim().isEmpty) {
      return '⚠ Missing required field';
    }
    return null;
  }
}

class FieldGroup {
  final String title;
  final IconData icon;
  final List<FieldInfo> fields;

  const FieldGroup({
    required this.title,
    required this.icon,
    required this.fields,
  });
}

class FieldInfo {
  final String key;
  final String label;
  final bool required;
  final FieldType type;
  final List<String>? options;
  final int? maxLines;

  const FieldInfo(
    this.key,
    this.label, {
    this.required = false,
    this.type = FieldType.text,
    this.options,
    this.maxLines,
  });
}

enum FieldType {
  text,
  date,
  dropdown,
  checkbox,
}
