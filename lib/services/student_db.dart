import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Student {
  final String? id;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? nameExtension;
  final String? houseStreetSitio;
  final String? barangay;
  final String? municipalityCity;
  final String? province;
  final DateTime? birthdate;
  final String? sex;
  final String? placeOfBirth;
  final String? civilStatus;
  final String? religion;
  final String? ethnicGroup;
  final String? motherTongue;
  final String? contactNumber;
  final bool? isPWD;
  final String? fatherLastName;
  final String? fatherFirstName;
  final String? fatherMiddleName;
  final String? fatherOccupation;
  final String? motherLastName;
  final String? motherFirstName;
  final String? motherMiddleName;
  final String? motherOccupation;
  final String? lastSchoolAttended;
  final String? lastGradeLevelCompleted;
  final String? reasonForIncompleteSchooling;
  final bool? hasAttendedALS;
  // ignore: non_constant_identifier_names
  final DateTime? created_at;
  final String? batchId;

  Student({
    this.id,
    this.lastName,
    this.firstName,
    this.middleName,
    this.nameExtension,
    this.houseStreetSitio,
    this.barangay,
    this.municipalityCity,
    this.province,
    this.birthdate,
    this.sex,
    this.placeOfBirth,
    this.civilStatus,
    this.religion,
    this.ethnicGroup,
    this.motherTongue,
    this.contactNumber,
    this.isPWD,
    this.fatherLastName,
    this.fatherFirstName,
    this.fatherMiddleName,
    this.fatherOccupation,
    this.motherLastName,
    this.motherFirstName,
    this.motherMiddleName,
    this.motherOccupation,
    this.lastSchoolAttended,
    this.lastGradeLevelCompleted,
    this.reasonForIncompleteSchooling,
    this.hasAttendedALS,
    // ignore: non_constant_identifier_names
    this.created_at,
    this.batchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'name_extension': nameExtension,
      'house_street_sitio': houseStreetSitio,
      'barangay': barangay,
      'municipality_city': municipalityCity,
      'province': province,
      'birthdate': birthdate?.toIso8601String(),
      'sex': sex,
      'place_of_birth': placeOfBirth,
      'civil_status': civilStatus,
      'religion': religion,
      'ethnic_group': ethnicGroup,
      'mother_tongue': motherTongue,
      'contact_number': contactNumber,
      'is_pwd': isPWD,
      'father_last_name': fatherLastName,
      'father_first_name': fatherFirstName,
      'father_middle_name': fatherMiddleName,
      'father_occupation': fatherOccupation,
      'mother_last_name': motherLastName,
      'mother_first_name': motherFirstName,
      'mother_middle_name': motherMiddleName,
      'mother_occupation': motherOccupation,
      'last_school_attended': lastSchoolAttended,
      'last_grade_level_completed': lastGradeLevelCompleted,
      'reason_for_incomplete_schooling': reasonForIncompleteSchooling,
      'has_attended_als': hasAttendedALS,
      'batch_id': batchId,
    };
  }

  static Student fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      lastName: map['last_name'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      nameExtension: map['name_extension'],
      houseStreetSitio: map['house_street_sitio'],
      barangay: map['barangay'],
      municipalityCity: map['municipality_city'],
      province: map['province'],
      birthdate:
          map['birthdate'] != null ? DateTime.parse(map['birthdate']) : null,
      sex: map['sex'],
      placeOfBirth: map['place_of_birth'],
      civilStatus: map['civil_status'],
      religion: map['religion'],
      ethnicGroup: map['ethnic_group'],
      motherTongue: map['mother_tongue'],
      contactNumber: map['contact_number'],
      isPWD: map['is_pwd'],
      fatherLastName: map['father_last_name'],
      fatherFirstName: map['father_first_name'],
      fatherMiddleName: map['father_middle_name'],
      fatherOccupation: map['father_occupation'],
      motherLastName: map['mother_last_name'],
      motherFirstName: map['mother_first_name'],
      motherMiddleName: map['mother_middle_name'],
      motherOccupation: map['mother_occupation'],
      lastSchoolAttended: map['last_school_attended'],
      lastGradeLevelCompleted: map['last_grade_level_completed'],
      reasonForIncompleteSchooling: map['reason_for_incomplete_schooling'],
      hasAttendedALS: map['has_attended_als'],
      created_at: DateTime.parse(map['created_at']),
      batchId: map['batch_id'],
    );
  }
}

class StudentDatabase {
  static const _table = 'students';

  /// Create a new student
  static Future<void> insertStudent(Student student) async {
    await supabase.from(_table).insert(student.toMap());
  }

  /// Get all students
  static Future<List<Student>> getStudents() async {
    final response = await supabase.from(_table).select();
    return (response as List).map((data) => Student.fromMap(data)).toList();
  }

  /// Get student by ID
  static Future<Student?> getStudentById(String id) async {
    final response = await supabase.from(_table).select().eq('id', id).single();
    return Student.fromMap(response);
  }

  /// Update a student
  static Future<void> updateStudent(String id, Student student) async {
    await supabase.from(_table).update(student.toMap()).eq('id', id);
  }

  /// Delete a student
  static Future<void> deleteStudent(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
