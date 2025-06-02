import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tulai/services/student_db.dart';
import 'package:tulai/widgets/appbar.dart';

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

  Widget buildInfoRow(String label, String? value) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.isNotEmpty == true ? value! : 'N/A',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 20),
                Text(getFullName(),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Personal Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Personal Information",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                  const Divider(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow("Last Name", student.lastName),
                      buildInfoRow("First Name", student.firstName),
                      buildInfoRow("Middle Name", student.middleName),
                      buildInfoRow("Name Extension", student.nameExtension),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Address
                  const Text("Address",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Divider(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow(
                          "House/Street/Sitio", student.houseStreetSitio),
                      buildInfoRow("Barangay", student.barangay),
                      buildInfoRow(
                          "Municipality/City", student.municipalityCity),
                      buildInfoRow("Province", student.province),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Others
                  const Text("Other Information",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Divider(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow("Sex", student.sex),
                      buildInfoRow("Birthdate", formatDate(student.birthdate)),
                      buildInfoRow("Place of Birth", student.placeOfBirth),
                      buildInfoRow("Civil Status", student.civilStatus),
                      buildInfoRow("Religion", student.religion),
                      buildInfoRow("Ethnic Group", student.ethnicGroup),
                      buildInfoRow("Mother Tongue", student.motherTongue),
                      buildInfoRow("Contact Number", student.contactNumber),
                      buildInfoRow("PWD", student.isPWD == true ? "Yes" : "No"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Parental Info
                  const Text("Parents' Information",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Divider(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow(
                          "Father's Last Name", student.fatherLastName),
                      buildInfoRow(
                          "Father's First Name", student.fatherFirstName),
                      buildInfoRow(
                          "Father's Middle Name", student.fatherMiddleName),
                      buildInfoRow(
                          "Father's Occupation", student.fatherOccupation),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow(
                          "Mother's Last Name", student.motherLastName),
                      buildInfoRow(
                          "Mother's First Name", student.motherFirstName),
                      buildInfoRow(
                          "Mother's Middle Name", student.motherMiddleName),
                      buildInfoRow(
                          "Mother's Occupation", student.motherOccupation),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Education Info
                  const Text("Educational Background",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                  const Divider(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildInfoRow(
                          "Last School Attended", student.lastSchoolAttended),
                      buildInfoRow("Last Grade Level Completed",
                          student.lastGradeLevelCompleted),
                      buildInfoRow("Reason for Incomplete Schooling",
                          student.reasonForIncompleteSchooling),
                      buildInfoRow("Attended ALS Before",
                          student.hasAttendedALS == true ? "Yes" : "No"),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
