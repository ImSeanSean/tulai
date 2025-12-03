import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tulai/services/student_db.dart';
import 'package:tulai/utils/download_helper.dart';

class StudentExportService {
  /// Export a single student's information to Excel
  static Future<String> exportStudentToExcel(Student student) async {
    // Create Excel workbook
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheetObject = excel['Student Information'];
    excel.delete('Sheet1'); // Remove default sheet

    // Define header style
    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue,
      fontColorHex: excel_lib.ExcelColor.white,
    );

    // Define data with labels and values
    final data = [
      ['PERSONAL INFORMATION', ''],
      ['Last Name', student.lastName ?? 'N/A'],
      ['First Name', student.firstName ?? 'N/A'],
      ['Middle Name', student.middleName ?? 'N/A'],
      ['Name Extension', student.nameExtension ?? 'N/A'],
      ['Sex', student.sex ?? 'N/A'],
      [
        'Birthdate',
        student.birthdate != null
            ? DateFormat('MMMM dd, yyyy').format(student.birthdate!)
            : 'N/A'
      ],
      ['Place of Birth', student.placeOfBirth ?? 'N/A'],
      ['Civil Status', student.civilStatus ?? 'N/A'],
      ['Religion', student.religion ?? 'N/A'],
      ['Ethnic Group', student.ethnicGroup ?? 'N/A'],
      ['Mother Tongue', student.motherTongue ?? 'N/A'],
      ['Contact Number', student.contactNumber ?? 'N/A'],
      ['PWD', student.isPWD == true ? 'Yes' : 'No'],
      ['', ''],
      ['ADDRESS', ''],
      ['House/Street/Sitio', student.houseStreetSitio ?? 'N/A'],
      ['Barangay', student.barangay ?? 'N/A'],
      ['Municipality/City', student.municipalityCity ?? 'N/A'],
      ['Province', student.province ?? 'N/A'],
      ['', ''],
      ["PARENTS' INFORMATION", ''],
      ["Father's Last Name", student.fatherLastName ?? 'N/A'],
      ["Father's First Name", student.fatherFirstName ?? 'N/A'],
      ["Father's Middle Name", student.fatherMiddleName ?? 'N/A'],
      ["Father's Occupation", student.fatherOccupation ?? 'N/A'],
      ["Mother's Last Name", student.motherLastName ?? 'N/A'],
      ["Mother's First Name", student.motherFirstName ?? 'N/A'],
      ["Mother's Middle Name", student.motherMiddleName ?? 'N/A'],
      ["Mother's Occupation", student.motherOccupation ?? 'N/A'],
      ['', ''],
      ['EDUCATIONAL BACKGROUND', ''],
      ['Last School Attended', student.lastSchoolAttended ?? 'N/A'],
      ['Last Grade Level Completed', student.lastGradeLevelCompleted ?? 'N/A'],
      [
        'Reason for Incomplete Schooling',
        student.reasonForIncompleteSchooling ?? 'N/A'
      ],
      [
        'Has Attended ALS Before',
        student.hasAttendedALS == true ? 'Yes' : 'No'
      ],
      ['', ''],
      ['ENROLLMENT INFORMATION', ''],
      [
        'Date Enrolled',
        student.created_at != null
            ? DateFormat('MMMM dd, yyyy').format(student.created_at!)
            : 'N/A'
      ],
    ];

    // Add data to sheet
    for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final row = data[rowIndex];

      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        var cell = sheetObject.cell(excel_lib.CellIndex.indexByColumnRow(
            columnIndex: colIndex, rowIndex: rowIndex));

        final value = row[colIndex].trim().isEmpty ? 'N/A' : row[colIndex];
        cell.value = excel_lib.TextCellValue(value);

        // Style section headers
        if (colIndex == 0 &&
            row[1].isEmpty &&
            value.isNotEmpty &&
            value != 'N/A') {
          cell.cellStyle = headerStyle;
        } else if (colIndex == 0) {
          // Bold the label column
          cell.cellStyle = excel_lib.CellStyle(bold: true);
        }
      }
    }

    // Set column widths
    sheetObject.setColumnWidth(0, 30);
    sheetObject.setColumnWidth(1, 40);

    // Encode to bytes
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    // Generate filename
    final studentName = [student.firstName, student.lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join('_')
        .replaceAll(' ', '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'student_${studentName}_$timestamp.xlsx';

    if (kIsWeb) {
      // For web, trigger download
      await downloadBytes(fileBytes, filename);
      return filename;
    } else {
      // For mobile/desktop, save to documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      return filePath;
    }
  }

  /// Export a single student's information to PDF using official ALS Form 2 template
  static Future<String> exportStudentToPdf(Student student) async {
    final pdf = pw.Document();

    // Load logo images
    final depedLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/deped-logo.png'))
          .buffer
          .asUint8List(),
    );
    final alsLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/als-logo.png'))
          .buffer
          .asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with logos and title
            _buildHeader(depedLogo, alsLogo),

            pw.SizedBox(height: 10),

            // Date and LRN fields
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: __________', style: pw.TextStyle(fontSize: 9)),
                pw.Row(
                  children: [
                    pw.Text('LRN (if available)',
                        style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(width: 10),
                    ..._buildLrnBoxes(),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Personal Information (Part I)
            _buildSectionTitle('Personal Information (Part I)'),
            _buildPersonalInfoTable(student),

            pw.SizedBox(height: 10),

            // Parent/Guardian Information
            _buildParentGuardianTable(student),

            pw.SizedBox(height: 10),

            // Educational Information (Part II)
            _buildSectionTitle('Educational Information (Part II)'),
            _buildEducationalInfoTable(student),
          ];
        },
      ),
    );

    // Generate filename
    final studentName = [student.firstName, student.lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join('_')
        .replaceAll(' ', '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'ALS_Form2_${studentName}_$timestamp.pdf';

    // Save PDF
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await downloadBytes(pdfBytes, filename);
      return filename;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(pdfBytes);
      return filePath;
    }
  }

  // Build header with logos and department info
  static pw.Widget _buildHeader(
      pw.ImageProvider depedLogo, pw.ImageProvider alsLogo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left DepEd logo
        pw.Container(
          width: 55,
          height: 55,
          child: pw.Image(depedLogo),
        ),
        pw.SizedBox(width: 10),
        // Center text
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text('Republic of the Philippines',
                  style: pw.TextStyle(fontSize: 9)),
              pw.Text('Department of Education',
                  style: pw.TextStyle(fontSize: 9)),
              pw.Text('ALTERNATIVE LEARNING SYSTEM',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('MOBILE TEACHER/COMMUNITY LEARNING CENTER',
                  style: pw.TextStyle(fontSize: 8)),
              pw.Text('(AFS) Learner\'s Basic Profile',
                  style: pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        // Right ALS logo
        pw.Container(
          width: 55,
          height: 55,
          child: pw.Image(alsLogo),
        ),
      ],
    );
  }

  // Build LRN boxes
  static List<pw.Widget> _buildLrnBoxes() {
    return List.generate(
      12,
      (index) => pw.Container(
        width: 12,
        height: 15,
        margin: const pw.EdgeInsets.only(right: 2),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      ),
    );
  }

  // Build section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        color: PdfColors.grey200,
      ),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  // Build personal information table matching the exact form layout
  static pw.Widget _buildPersonalInfoTable(Student student) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Row 1: Last Name, First Name, Middle Name, Name Extension
        pw.TableRow(children: [
          _buildTableCell('Last Name', student.lastName ?? ''),
          _buildTableCell('First Name', student.firstName ?? ''),
          _buildTableCell('Middle Name', student.middleName ?? ''),
          _buildTableCell('Name Extension', student.nameExtension ?? ''),
        ]),
        // Row 2: CURRENT ADDRESS
        pw.TableRow(children: [
          _buildTableCell('CURRENT ADDRESS\nHouse No./Street/Sitio',
              student.houseStreetSitio ?? ''),
          _buildTableCell('Barangay', student.barangay ?? ''),
          _buildTableCell('Municipality/City', student.municipalityCity ?? ''),
          _buildTableCell('Province', student.province ?? ''),
        ]),
        // Row 3: PERMANENT ADDRESS (same as current)
        pw.TableRow(children: [
          _buildTableCell('PERMANENT ADDRESS\nHouse No./Street/Sitio',
              student.houseStreetSitio ?? '',
              hasCheckbox: true),
          _buildTableCell('Barangay', student.barangay ?? ''),
          _buildTableCell('Municipality/City', student.municipalityCity ?? ''),
          _buildTableCell('Province', student.province ?? ''),
        ]),
        // Row 4: Birthdate, Sex, Place of Birth, Civil Status
        pw.TableRow(children: [
          _buildTableCell(
              'Birthdate (mm/dd/yyyy)',
              student.birthdate != null
                  ? DateFormat('MM/dd/yyyy').format(student.birthdate!)
                  : '',
              hasBoxes: true),
          _buildTableCell('Sex', student.sex ?? '',
              hasCheckbox: true, checkboxOptions: ['Male', 'Female']),
          _buildTableCell(
              'Place of Birth (Municipality/City)', student.placeOfBirth ?? ''),
          _buildTableCell('Civil Status', student.civilStatus ?? '',
              hasCheckbox: true,
              checkboxOptions: [
                'Single',
                'Married',
                'Separated',
                'Widowed',
                'Solo Parent'
              ]),
        ]),
        // Row 5: Religion, IP, Mother Tongue, Contact Number
        pw.TableRow(children: [
          _buildTableCell('Religion', student.religion ?? ''),
          _buildTableCell(
              'IP (Specify ethnic group)', student.ethnicGroup ?? ''),
          _buildTableCell('Mother Tongue', student.motherTongue ?? ''),
          _buildTableCell('Contact Number/s', student.contactNumber ?? ''),
        ]),
        // Row 6: PWD and disability types
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PWD:',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Row(
                  children: [
                    _buildCheckbox(student.isPWD == true, 'Yes'),
                    pw.SizedBox(width: 10),
                    _buildCheckbox(student.isPWD == false, 'No'),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('If Yes, specify the type of disability:',
                    style: pw.TextStyle(fontSize: 6)),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Chronic Illness'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Orthopedic/Musculoskeletal Disorder'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Communication Disorder'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Autism Spectrum Disorder'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Intellectual Disability'),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('',
                    style:
                        pw.TextStyle(fontSize: 6)), // Empty space for alignment
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Hearing Impairment'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Visual Impairment'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Learning Disability'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Multiple Disabilities'),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('',
                    style:
                        pw.TextStyle(fontSize: 6)), // Empty space for alignment
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Physical Disability'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Others'),
              ],
            ),
          ),
        ]),
        // Row 7: 4Ps beneficiary - single cell spanning width
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Wrap(
              spacing: 5,
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              children: [
                pw.Text('Is your family a beneficiary of 4Ps?',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                _buildCheckbox(false, 'Yes'),
                _buildCheckbox(false, 'No'),
                pw.SizedBox(width: 10),
                pw.Text('If Yes, write the 4Ps Household ID Number below',
                    style: pw.TextStyle(fontSize: 7)),
                ...List.generate(
                    10,
                    (i) => pw.Container(
                          width: 12,
                          height: 14,
                          margin: const pw.EdgeInsets.only(right: 1),
                          decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 0.5),
                              color: PdfColors.white),
                        )),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _buildParentGuardianTable(Student student) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(children: [
          _buildTableCell('Name of Father/Legal Guardian\nLast Name',
              student.fatherLastName ?? ''),
          _buildTableCell('First Name', student.fatherFirstName ?? ''),
          _buildTableCell('Middle Name', student.fatherMiddleName ?? ''),
          _buildTableCell('Occupation', student.fatherOccupation ?? ''),
        ]),
        pw.TableRow(children: [
          _buildTableCell(
              'Mother\'s Maiden Name\nLast Name', student.motherLastName ?? ''),
          _buildTableCell('First Name', student.motherFirstName ?? ''),
          _buildTableCell('Middle Name', student.motherMiddleName ?? ''),
          _buildTableCell('Occupation', student.motherOccupation ?? ''),
        ]),
      ],
    );
  }

  // Build educational information table
  static pw.Widget _buildEducationalInfoTable(Student student) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    'What was the highest grade level completed (Check only the highest level reached):',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Elementary:',
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          children: [
                            _buildCheckbox(
                                student.lastGradeLevelCompleted
                                        ?.toLowerCase()
                                        .contains('kinder') ??
                                    false,
                                'Kinder'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 1',
                                'Grade 1'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 2',
                                'Grade 2'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 3',
                                'Grade 3'),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          children: [
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 4',
                                'Grade 4'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 5',
                                'Grade 5'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 6',
                                'Grade 6'),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Junior High School',
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          children: [
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 7',
                                'Grade 7'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 8',
                                'Grade 8'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 9',
                                'Grade 9'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 10',
                                'Grade 10'),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Senior High School',
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          children: [
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 11',
                                'Grade 11'),
                            _buildCheckbox(
                                student.lastGradeLevelCompleted == 'Grade 12',
                                'Grade 12'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    'Why did you not attend/complete schooling? (For OSY only)',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                _buildCheckbox(
                    student.reasonForIncompleteSchooling
                            ?.toLowerCase()
                            .contains('no school in barangay') ??
                        false,
                    'No school in Barangay'),
                pw.SizedBox(height: 2),
                _buildCheckbox(
                    student.reasonForIncompleteSchooling
                            ?.toLowerCase()
                            .contains('school too far') ??
                        false,
                    'School too far from home'),
                pw.SizedBox(height: 2),
                _buildCheckbox(
                    student.reasonForIncompleteSchooling
                            ?.toLowerCase()
                            .contains('help family') ??
                        false,
                    'Needed to help family'),
                pw.SizedBox(height: 2),
                _buildCheckbox(
                    student.reasonForIncompleteSchooling
                            ?.toLowerCase()
                            .contains('unable to pay') ??
                        false,
                    'Unable to pay for school expenses and other expenses'),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    _buildCheckbox(
                        student.reasonForIncompleteSchooling != null &&
                            !student.reasonForIncompleteSchooling!
                                .toLowerCase()
                                .contains('no school in barangay') &&
                            !student.reasonForIncompleteSchooling!
                                .toLowerCase()
                                .contains('school too far') &&
                            !student.reasonForIncompleteSchooling!
                                .toLowerCase()
                                .contains('help family') &&
                            !student.reasonForIncompleteSchooling!
                                .toLowerCase()
                                .contains('unable to pay'),
                        'Others:'),
                    pw.SizedBox(width: 3),
                    pw.Text(
                        student.reasonForIncompleteSchooling != null &&
                                !student.reasonForIncompleteSchooling!
                                    .toLowerCase()
                                    .contains('no school in barangay') &&
                                !student.reasonForIncompleteSchooling!
                                    .toLowerCase()
                                    .contains('school too far') &&
                                !student.reasonForIncompleteSchooling!
                                    .toLowerCase()
                                    .contains('help family') &&
                                !student.reasonForIncompleteSchooling!
                                    .toLowerCase()
                                    .contains('unable to pay')
                            ? student.reasonForIncompleteSchooling!
                            : '_________________',
                        style: pw.TextStyle(fontSize: 6)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Have you been a student before?',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Wrap(
                  spacing: 5,
                  children: [
                    _buildCheckbox(student.hasAttendedALS == true, 'Yes'),
                    _buildCheckbox(student.hasAttendedALS == false, 'No'),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text('If Yes, check the appropriate program:',
                    style: pw.TextStyle(fontSize: 6)),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'Basic Literacy'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'A&E Elementary'),
                pw.SizedBox(height: 2),
                _buildCheckbox(false, 'A&E JHS'),
              ],
            ),
          ),
        ]),
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Have you completed the program?',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Wrap(
                  spacing: 5,
                  children: [
                    _buildCheckbox(false, 'Yes'),
                    _buildCheckbox(false, 'No'),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text('If No, state the reason:',
                    style: pw.TextStyle(fontSize: 6)),
                pw.Text('_________________________________',
                    style: pw.TextStyle(fontSize: 6)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  // Helper to build table cell
  static pw.Widget _buildTableCell(String label, String value,
      {bool hasCheckbox = false,
      List<String>? checkboxOptions,
      bool hasBoxes = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
          if (hasCheckbox && checkboxOptions != null)
            pw.Wrap(
              spacing: 5,
              runSpacing: 2,
              children: checkboxOptions.map((option) {
                final isChecked = value.toLowerCase() == option.toLowerCase();
                return _buildCheckbox(isChecked, option);
              }).toList(),
            )
          else if (hasBoxes)
            pw.Row(
              children: [
                // MM boxes
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 1),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.isNotEmpty && value.length > 0 ? value[0] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 2),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 1 ? value[1] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Text('/', style: pw.TextStyle(fontSize: 8)),
                // DD boxes
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 3 ? value[3] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 2),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 4 ? value[4] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Text('/', style: pw.TextStyle(fontSize: 8)),
                // YYYY boxes
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 6 ? value[6] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 1),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 7 ? value[7] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Container(
                  width: 12,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 1),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 8 ? value[8] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Container(
                  width: 12,
                  height: 14,
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(
                    child: pw.Text(
                      value.length > 9 ? value[9] : '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            )
          else
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.only(top: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom:
                        pw.BorderSide(width: 0.5, color: PdfColors.grey400)),
              ),
              child: pw.Text(value, style: pw.TextStyle(fontSize: 8)),
            ),
        ],
      ),
    );
  }

  // Helper to build checkbox
  static pw.Widget _buildCheckbox(bool checked, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: checked
              ? pw.Center(child: pw.Text('✓', style: pw.TextStyle(fontSize: 6)))
              : null,
        ),
        pw.SizedBox(width: 2),
        pw.Text(label, style: pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  // Remove old helper methods

  /// Preview PDF before saving (for mobile/desktop) - Using ALS Form 2 format
  static Future<void> previewStudentPdf(Student student) async {
    final pdf = pw.Document();

    // Load logo images
    final depedLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/deped-logo.png'))
          .buffer
          .asUint8List(),
    );
    final alsLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/als-logo.png'))
          .buffer
          .asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(depedLogo, alsLogo),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: __________', style: pw.TextStyle(fontSize: 9)),
                pw.Row(
                  children: [
                    pw.Text('LRN (if available)',
                        style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(width: 10),
                    ..._buildLrnBoxes(),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Personal Information (Part I)'),
            _buildPersonalInfoTable(student),
            pw.SizedBox(height: 10),
            _buildParentGuardianTable(student),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Educational Information (Part II)'),
            _buildEducationalInfoTable(student),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
