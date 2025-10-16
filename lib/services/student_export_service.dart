import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Export a single student's information to PDF
  static Future<String> exportStudentToPdf(Student student) async {
    final pdf = pw.Document();

    // Get full name
    final fullName = [
      student.firstName,
      student.middleName,
      student.lastName,
      student.nameExtension
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT INFORMATION',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    displayName,
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.blue),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Personal Information Section
            _buildPdfSection('PERSONAL INFORMATION', [
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
            ]),

            pw.SizedBox(height: 16),

            // Address Section
            _buildPdfSection('ADDRESS', [
              ['House/Street/Sitio', student.houseStreetSitio ?? 'N/A'],
              ['Barangay', student.barangay ?? 'N/A'],
              ['Municipality/City', student.municipalityCity ?? 'N/A'],
              ['Province', student.province ?? 'N/A'],
            ]),

            pw.SizedBox(height: 16),

            // Parents' Information Section
            _buildPdfSection("PARENTS' INFORMATION", [
              ["Father's Last Name", student.fatherLastName ?? 'N/A'],
              ["Father's First Name", student.fatherFirstName ?? 'N/A'],
              ["Father's Middle Name", student.fatherMiddleName ?? 'N/A'],
              ["Father's Occupation", student.fatherOccupation ?? 'N/A'],
              ["Mother's Last Name", student.motherLastName ?? 'N/A'],
              ["Mother's First Name", student.motherFirstName ?? 'N/A'],
              ["Mother's Middle Name", student.motherMiddleName ?? 'N/A'],
              ["Mother's Occupation", student.motherOccupation ?? 'N/A'],
            ]),

            pw.SizedBox(height: 16),

            // Educational Background Section
            _buildPdfSection('EDUCATIONAL BACKGROUND', [
              ['Last School Attended', student.lastSchoolAttended ?? 'N/A'],
              [
                'Last Grade Level Completed',
                student.lastGradeLevelCompleted ?? 'N/A'
              ],
              [
                'Reason for Incomplete Schooling',
                student.reasonForIncompleteSchooling ?? 'N/A'
              ],
              [
                'Has Attended ALS Before',
                student.hasAttendedALS == true ? 'Yes' : 'No'
              ],
            ]),

            pw.SizedBox(height: 16),

            // Enrollment Information
            _buildPdfSection('ENROLLMENT INFORMATION', [
              [
                'Date Enrolled',
                student.created_at != null
                    ? DateFormat('MMMM dd, yyyy').format(student.created_at!)
                    : 'N/A'
              ],
            ]),

            pw.SizedBox(height: 32),

            // Footer
            pw.Divider(),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
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
    final filename = 'student_${studentName}_$timestamp.pdf';

    // Save PDF
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // For web, trigger download
      await downloadBytes(pdfBytes, filename);
      return filename;
    } else {
      // For mobile/desktop, save to documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(pdfBytes);

      return filePath;
    }
  }

  /// Helper to build PDF section
  static pw.Widget _buildPdfSection(String title, List<List<String>> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: data.map((row) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    row[1],
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Preview PDF before saving (for mobile/desktop)
  static Future<void> previewStudentPdf(Student student) async {
    final pdf = pw.Document();

    // Get full name
    final fullName = [
      student.firstName,
      student.middleName,
      student.lastName,
      student.nameExtension
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Same content as exportStudentToPdf
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT INFORMATION',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    displayName,
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.blue),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _buildPdfSection('PERSONAL INFORMATION', [
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
            ]),
            pw.SizedBox(height: 16),
            _buildPdfSection('ADDRESS', [
              ['House/Street/Sitio', student.houseStreetSitio ?? 'N/A'],
              ['Barangay', student.barangay ?? 'N/A'],
              ['Municipality/City', student.municipalityCity ?? 'N/A'],
              ['Province', student.province ?? 'N/A'],
            ]),
            pw.SizedBox(height: 16),
            _buildPdfSection("PARENTS' INFORMATION", [
              ["Father's Last Name", student.fatherLastName ?? 'N/A'],
              ["Father's First Name", student.fatherFirstName ?? 'N/A'],
              ["Father's Middle Name", student.fatherMiddleName ?? 'N/A'],
              ["Father's Occupation", student.fatherOccupation ?? 'N/A'],
              ["Mother's Last Name", student.motherLastName ?? 'N/A'],
              ["Mother's First Name", student.motherFirstName ?? 'N/A'],
              ["Mother's Middle Name", student.motherMiddleName ?? 'N/A'],
              ["Mother's Occupation", student.motherOccupation ?? 'N/A'],
            ]),
            pw.SizedBox(height: 16),
            _buildPdfSection('EDUCATIONAL BACKGROUND', [
              ['Last School Attended', student.lastSchoolAttended ?? 'N/A'],
              [
                'Last Grade Level Completed',
                student.lastGradeLevelCompleted ?? 'N/A'
              ],
              [
                'Reason for Incomplete Schooling',
                student.reasonForIncompleteSchooling ?? 'N/A'
              ],
              [
                'Has Attended ALS Before',
                student.hasAttendedALS == true ? 'Yes' : 'No'
              ],
            ]),
            pw.SizedBox(height: 16),
            _buildPdfSection('ENROLLMENT INFORMATION', [
              [
                'Date Enrolled',
                student.created_at != null
                    ? DateFormat('MMMM dd, yyyy').format(student.created_at!)
                    : 'N/A'
              ],
            ]),
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    // Show print preview dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
