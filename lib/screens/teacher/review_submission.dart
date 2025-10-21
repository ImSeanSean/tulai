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
              'Widower',
              'Solo Parent'
            ]),
        FieldInfo('religion', 'Religion'),
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    for (var group in _fieldGroups) {
      for (var field in group.fields) {
        final value = widget.submission[field.key];
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
          'Review Submission',
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
