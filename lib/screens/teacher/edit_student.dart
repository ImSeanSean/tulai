import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/services/student_db.dart';

class EditStudent extends StatefulWidget {
  final Student student;

  const EditStudent({super.key, required this.student});

  @override
  State<EditStudent> createState() => _EditStudentState();
}

class _EditStudentState extends State<EditStudent> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;

  // Controllers for all fields
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _nameExtensionController;
  late TextEditingController _houseStreetSitioController;
  late TextEditingController _barangayController;
  late TextEditingController _municipalityCityController;
  late TextEditingController _provinceController;
  late TextEditingController _placeOfBirthController;
  late TextEditingController _religionController;
  late TextEditingController _ethnicGroupController;
  late TextEditingController _motherTongueController;
  late TextEditingController _contactNumberController;
  late TextEditingController _fatherLastNameController;
  late TextEditingController _fatherFirstNameController;
  late TextEditingController _fatherMiddleNameController;
  late TextEditingController _fatherOccupationController;
  late TextEditingController _motherLastNameController;
  late TextEditingController _motherFirstNameController;
  late TextEditingController _motherMiddleNameController;
  late TextEditingController _motherOccupationController;
  late TextEditingController _lastSchoolAttendedController;
  late TextEditingController _lastGradeLevelCompletedController;
  late TextEditingController _reasonForIncompleteSchoolingController;

  // Dropdown values
  String? _sex;
  String? _civilStatus;
  DateTime? _birthdate;
  bool _isPWD = false;
  bool _hasAttendedALS = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current student data
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _firstNameController =
        TextEditingController(text: widget.student.firstName);
    _middleNameController =
        TextEditingController(text: widget.student.middleName);
    _nameExtensionController =
        TextEditingController(text: widget.student.nameExtension);
    _houseStreetSitioController =
        TextEditingController(text: widget.student.houseStreetSitio);
    _barangayController = TextEditingController(text: widget.student.barangay);
    _municipalityCityController =
        TextEditingController(text: widget.student.municipalityCity);
    _provinceController = TextEditingController(text: widget.student.province);
    _placeOfBirthController =
        TextEditingController(text: widget.student.placeOfBirth);
    _religionController = TextEditingController(text: widget.student.religion);
    _ethnicGroupController =
        TextEditingController(text: widget.student.ethnicGroup);
    _motherTongueController =
        TextEditingController(text: widget.student.motherTongue);
    _contactNumberController =
        TextEditingController(text: widget.student.contactNumber);
    _fatherLastNameController =
        TextEditingController(text: widget.student.fatherLastName);
    _fatherFirstNameController =
        TextEditingController(text: widget.student.fatherFirstName);
    _fatherMiddleNameController =
        TextEditingController(text: widget.student.fatherMiddleName);
    _fatherOccupationController =
        TextEditingController(text: widget.student.fatherOccupation);
    _motherLastNameController =
        TextEditingController(text: widget.student.motherLastName);
    _motherFirstNameController =
        TextEditingController(text: widget.student.motherFirstName);
    _motherMiddleNameController =
        TextEditingController(text: widget.student.motherMiddleName);
    _motherOccupationController =
        TextEditingController(text: widget.student.motherOccupation);
    _lastSchoolAttendedController =
        TextEditingController(text: widget.student.lastSchoolAttended);
    _lastGradeLevelCompletedController =
        TextEditingController(text: widget.student.lastGradeLevelCompleted);
    _reasonForIncompleteSchoolingController = TextEditingController(
        text: widget.student.reasonForIncompleteSchooling);

    _sex = widget.student.sex;
    _civilStatus = widget.student.civilStatus;
    _birthdate = widget.student.birthdate;
    _isPWD = widget.student.isPWD ?? false;
    _hasAttendedALS = widget.student.hasAttendedALS ?? false;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _nameExtensionController.dispose();
    _houseStreetSitioController.dispose();
    _barangayController.dispose();
    _municipalityCityController.dispose();
    _provinceController.dispose();
    _placeOfBirthController.dispose();
    _religionController.dispose();
    _ethnicGroupController.dispose();
    _motherTongueController.dispose();
    _contactNumberController.dispose();
    _fatherLastNameController.dispose();
    _fatherFirstNameController.dispose();
    _fatherMiddleNameController.dispose();
    _fatherOccupationController.dispose();
    _motherLastNameController.dispose();
    _motherFirstNameController.dispose();
    _motherMiddleNameController.dispose();
    _motherOccupationController.dispose();
    _lastSchoolAttendedController.dispose();
    _lastGradeLevelCompletedController.dispose();
    _reasonForIncompleteSchoolingController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.student.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot save: Student ID not found'),
          backgroundColor: TulaiColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedStudent = Student(
        id: widget.student.id,
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        nameExtension: _nameExtensionController.text.trim(),
        houseStreetSitio: _houseStreetSitioController.text.trim(),
        barangay: _barangayController.text.trim(),
        municipalityCity: _municipalityCityController.text.trim(),
        province: _provinceController.text.trim(),
        birthdate: _birthdate,
        sex: _sex,
        placeOfBirth: _placeOfBirthController.text.trim(),
        civilStatus: _civilStatus,
        religion: _religionController.text.trim(),
        ethnicGroup: _ethnicGroupController.text.trim(),
        motherTongue: _motherTongueController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        isPWD: _isPWD,
        fatherLastName: _fatherLastNameController.text.trim(),
        fatherFirstName: _fatherFirstNameController.text.trim(),
        fatherMiddleName: _fatherMiddleNameController.text.trim(),
        fatherOccupation: _fatherOccupationController.text.trim(),
        motherLastName: _motherLastNameController.text.trim(),
        motherFirstName: _motherFirstNameController.text.trim(),
        motherMiddleName: _motherMiddleNameController.text.trim(),
        motherOccupation: _motherOccupationController.text.trim(),
        lastSchoolAttended: _lastSchoolAttendedController.text.trim(),
        lastGradeLevelCompleted: _lastGradeLevelCompletedController.text.trim(),
        reasonForIncompleteSchooling:
            _reasonForIncompleteSchoolingController.text.trim(),
        hasAttendedALS: _hasAttendedALS,
        created_at: widget.student.created_at,
      );

      await _supabase
          .from('students')
          .update(updatedStudent.toMap())
          .eq('id', widget.student.id!);

      if (mounted) {
        Navigator.pop(context, updatedStudent); // Return updated student
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Student information updated successfully'),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TulaiColors.primary,
              onPrimary: Colors.white,
              onSurface: TulaiColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TulaiTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: TulaiColors.textPrimary,
          ),
        ),
        const SizedBox(height: TulaiSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            filled: true,
            fillColor: TulaiColors.backgroundPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.primary, width: 2),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TulaiTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: TulaiColors.textPrimary,
          ),
        ),
        const SizedBox(height: TulaiSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: TulaiColors.backgroundPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              borderSide: BorderSide(color: TulaiColors.primary, width: 2),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TulaiSpacing.md),
      child: Text(
        title,
        style: TulaiTextStyles.heading3.copyWith(
          color: TulaiColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: TulaiColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Student Information',
          style: TulaiTextStyles.heading3,
        ),
        actions: [
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            TulaiResponsive.isLargeScreen(context)
                ? TulaiSpacing.xl
                : TulaiSpacing.lg,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSectionHeader('Personal Information'),
                  _buildTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    required: true,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    required: true,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Middle Name',
                    controller: _middleNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Name Extension',
                    controller: _nameExtensionController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildDropdown(
                    label: 'Sex',
                    value: _sex,
                    items: ['Male', 'Female'],
                    onChanged: (value) => setState(() => _sex = value),
                    required: true,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Birthdate *',
                        style: TulaiTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: TulaiColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TulaiSpacing.xs),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(TulaiSpacing.md),
                          decoration: BoxDecoration(
                            color: TulaiColors.backgroundPrimary,
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.md),
                            border: Border.all(color: TulaiColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthdate != null
                                    ? DateFormat('MMMM dd, yyyy')
                                        .format(_birthdate!)
                                    : 'Select birthdate',
                                style: TulaiTextStyles.bodyMedium.copyWith(
                                  color: _birthdate != null
                                      ? TulaiColors.textPrimary
                                      : TulaiColors.textMuted,
                                ),
                              ),
                              Icon(Icons.calendar_today,
                                  color: TulaiColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Place of Birth',
                    controller: _placeOfBirthController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildDropdown(
                    label: 'Civil Status',
                    value: _civilStatus,
                    items: ['Single', 'Married', 'Widowed', 'Separated'],
                    onChanged: (value) => setState(() => _civilStatus = value),
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Religion',
                    controller: _religionController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Ethnic Group',
                    controller: _ethnicGroupController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Mother Tongue',
                    controller: _motherTongueController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Contact Number',
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  CheckboxListTile(
                    title: Text(
                      'Person with Disability (PWD)',
                      style: TulaiTextStyles.bodyMedium,
                    ),
                    value: _isPWD,
                    onChanged: (value) =>
                        setState(() => _isPWD = value ?? false),
                    activeColor: TulaiColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Address Section
                  _buildSectionHeader('Address'),
                  _buildTextField(
                    label: 'House/Street/Sitio',
                    controller: _houseStreetSitioController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Barangay',
                    controller: _barangayController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Municipality/City',
                    controller: _municipalityCityController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Province',
                    controller: _provinceController,
                  ),

                  // Parents' Information Section
                  _buildSectionHeader("Parents' Information"),
                  _buildTextField(
                    label: "Father's Last Name",
                    controller: _fatherLastNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Father's First Name",
                    controller: _fatherFirstNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Father's Middle Name",
                    controller: _fatherMiddleNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Father's Occupation",
                    controller: _fatherOccupationController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Mother's Last Name",
                    controller: _motherLastNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Mother's First Name",
                    controller: _motherFirstNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Mother's Middle Name",
                    controller: _motherMiddleNameController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: "Mother's Occupation",
                    controller: _motherOccupationController,
                  ),

                  // Educational Background Section
                  _buildSectionHeader('Educational Background'),
                  _buildTextField(
                    label: 'Last School Attended',
                    controller: _lastSchoolAttendedController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Last Grade Level Completed',
                    controller: _lastGradeLevelCompletedController,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  _buildTextField(
                    label: 'Reason for Incomplete Schooling',
                    controller: _reasonForIncompleteSchoolingController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: TulaiSpacing.md),
                  CheckboxListTile(
                    title: Text(
                      'Has Attended ALS Before',
                      style: TulaiTextStyles.bodyMedium,
                    ),
                    value: _hasAttendedALS,
                    onChanged: (value) =>
                        setState(() => _hasAttendedALS = value ?? false),
                    activeColor: TulaiColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: TulaiSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
