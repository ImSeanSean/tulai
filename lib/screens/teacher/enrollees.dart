import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:tulai/utils/download_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/teacher/enrolee_information.dart';
import 'package:tulai/services/student_db.dart';
import 'package:tulai/services/batch_db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper widget for batch divider
class _BatchDivider extends StatelessWidget {
  final String label;
  const _BatchDivider({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: TulaiColors.primary, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              label,
              style: TulaiTextStyles.heading3.copyWith(
                color: TulaiColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: TulaiColors.primary, thickness: 2)),
        ],
      ),
    );
  }
}

enum SortMode { alphabetical, createdAt }

class Enrollees extends StatefulWidget {
  final bool showAllBatches;
  const Enrollees({super.key, this.showAllBatches = false});

  @override
  State<Enrollees> createState() => _EnrolleesState();
}

class _EnrolleesState extends State<Enrollees>
    with SingleTickerProviderStateMixin {
  List<Batch> batches = [];
  String? selectedBatchId;
  TabController? _tabController;
  List<Student> students = [];
  List<Student> filteredStudents = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  // Sorting modes
  SortMode currentSortMode = SortMode.alphabetical;

  @override
  void initState() {
    super.initState();
    fetchBatches();
    fetchStudents();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterAndSortStudents();
      setState(() {
        isSearching = false;
      });
    });
  }

  void _clearSearch() {
    searchController.clear();
    _filterAndSortStudents();
  }

  void _filterAndSortStudents() {
    final query = searchController.text.toLowerCase().trim();

    List<Student> filtered = students.where((student) {
      // If no search query, just filter by batch
      if (query.isEmpty) {
        return selectedBatchId == null || student.batchId == selectedBatchId;
      }

      final matchesBatch =
          selectedBatchId == null || student.batchId == selectedBatchId;

      if (!matchesBatch) return false;

      // Search across multiple fields
      final fullName = [student.lastName, student.firstName, student.middleName]
          .where((part) => part != null && part.isNotEmpty)
          .join(' ')
          .toLowerCase();

      final barangay = (student.barangay ?? '').toLowerCase();
      final contactNumber = (student.contactNumber ?? '').toLowerCase();
      final municipalityCity = (student.municipalityCity ?? '').toLowerCase();
      final province = (student.province ?? '').toLowerCase();
      final houseStreetSitio = (student.houseStreetSitio ?? '').toLowerCase();

      // Match any of these fields
      return fullName.contains(query) ||
          barangay.contains(query) ||
          contactNumber.contains(query) ||
          municipalityCity.contains(query) ||
          province.contains(query) ||
          houseStreetSitio.contains(query);
    }).toList();

    // Sort filtered list based on currentSortMode
    if (currentSortMode == SortMode.alphabetical) {
      filtered.sort((a, b) {
        final nameA = [a.lastName, a.firstName, a.middleName]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ')
            .toLowerCase();
        final nameB = [b.lastName, b.firstName, b.middleName]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ')
            .toLowerCase();

        // Handle empty names in sorting
        final sortNameA = nameA.isNotEmpty ? nameA : 'zzz_unknown';
        final sortNameB = nameB.isNotEmpty ? nameB : 'zzz_unknown';
        return sortNameA.compareTo(sortNameB);
      });
    } else if (currentSortMode == SortMode.createdAt) {
      filtered.sort((a, b) {
        // Handle null dates
        final dateA = a.created_at ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.created_at ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    }

    setState(() {
      filteredStudents = filtered;
    });
  }

  Future<void> fetchBatches() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('batches')
        .select('id, start_year, end_year')
        .order('start_year', ascending: true); // oldest to newest
    setState(() {
      batches = (response as List).map((e) => Batch.fromMap(e)).toList();
      if (batches.isNotEmpty) {
        selectedBatchId = batches.first.id;
        _tabController = TabController(length: batches.length, vsync: this);
        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) return;
          setState(() {
            selectedBatchId = batches[_tabController!.index].id;
            _filterAndSortStudents();
          });
        });
      }
    });
  }

  Future<void> fetchStudents() async {
    try {
      List<Student> fetchedStudents;
      if (widget.showAllBatches) {
        // Super admin: fetch all students
        fetchedStudents = await StudentDatabase.getStudents();
      } else {
        // Teacher: fetch only assigned students (customize as needed)
        fetchedStudents = await StudentDatabase.getStudentsForCurrentTeacher();
      }
      students = fetchedStudents;
      _filterAndSortStudents();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching students: $e");
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // Show loading dialog
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

      // Create Excel workbook
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheetObject = excel['Student Records'];

      // Remove the default sheet that Excel.createExcel() creates
      excel.delete('Sheet1');

      // Define header row with styling
      final headerStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.blue,
        fontColorHex: excel_lib.ExcelColor.white,
      );

      // Add headers
      final headers = [
        'Last Name',
        'First Name',
        'Middle Name',
        'Name Extension',
        'Sex',
        'Birthdate',
        'Place of Birth',
        'Civil Status',
        'Religion',
        'Ethnic Group',
        'Mother Tongue',
        'Contact Number',
        'PWD',
        'House/Street/Sitio',
        'Barangay',
        'Municipality/City',
        'Province',
        "Father's Last Name",
        "Father's First Name",
        "Father's Middle Name",
        "Father's Occupation",
        "Mother's Last Name",
        "Mother's First Name",
        "Mother's Middle Name",
        "Mother's Occupation",
        'Last School Attended',
        'Last Grade Level Completed',
        'Reason for Incomplete Schooling',
        'Has Attended ALS',
        'Date Enrolled',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = excel_lib.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add student data
      for (var rowIndex = 0; rowIndex < filteredStudents.length; rowIndex++) {
        final student = filteredStudents[rowIndex];
        final dataRow = rowIndex + 1;

        final rowData = [
          student.lastName ?? 'N/A',
          student.firstName ?? 'N/A',
          student.middleName ?? 'N/A',
          student.nameExtension ?? 'N/A',
          student.sex ?? 'N/A',
          student.birthdate != null
              ? DateFormat('MM/dd/yyyy').format(student.birthdate!)
              : 'N/A',
          student.placeOfBirth ?? 'N/A',
          student.civilStatus ?? 'N/A',
          student.religion ?? 'N/A',
          student.ethnicGroup ?? 'N/A',
          student.motherTongue ?? 'N/A',
          student.contactNumber ?? 'N/A',
          student.isPWD == true ? 'Yes' : 'No',
          student.houseStreetSitio ?? 'N/A',
          student.barangay ?? 'N/A',
          student.municipalityCity ?? 'N/A',
          student.province ?? 'N/A',
          student.fatherLastName ?? 'N/A',
          student.fatherFirstName ?? 'N/A',
          student.fatherMiddleName ?? 'N/A',
          student.fatherOccupation ?? 'N/A',
          student.motherLastName ?? 'N/A',
          student.motherFirstName ?? 'N/A',
          student.motherMiddleName ?? 'N/A',
          student.motherOccupation ?? 'N/A',
          student.lastSchoolAttended ?? 'N/A',
          student.lastGradeLevelCompleted ?? 'N/A',
          student.reasonForIncompleteSchooling ?? 'N/A',
          student.hasAttendedALS == true ? 'Yes' : 'No',
          student.created_at != null
              ? DateFormat('MM/dd/yyyy').format(student.created_at!)
              : 'N/A',
        ];

        for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
          var cell = sheetObject.cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: dataRow));
          // Replace empty strings with N/A
          final cellValue =
              rowData[colIndex].trim().isEmpty ? 'N/A' : rowData[colIndex];
          cell.value = excel_lib.TextCellValue(cellValue);
        }
      }

      // Auto-size columns (set reasonable widths)
      for (var i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      // Save file
      final fileBytes = excel.encode();

      if (fileBytes != null) {
        if (kIsWeb) {
          // For web, use helper to trigger browser download
          try {
            final timestamp =
                DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final filename = 'student_records_$timestamp.xlsx';
            await downloadBytes(fileBytes, filename);

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Exported ${filteredStudents.length} records as $filename'),
                  backgroundColor: TulaiColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error exporting on web: $e'),
                  backgroundColor: TulaiColors.error,
                ),
              );
            }
          }
        } else {
          // For mobile/desktop
          final directory = await getApplicationDocumentsDirectory();
          final timestamp =
              DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final filePath = '${directory.path}/student_records_$timestamp.xlsx';

          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);

          if (mounted) {
            Navigator.pop(context); // Close loading dialog

            // Show success dialog with file location
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: TulaiColors.success),
                    const SizedBox(width: TulaiSpacing.sm),
                    const Text('Export Successful'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Exported ${filteredStudents.length} student records to:'),
                    const SizedBox(height: TulaiSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(TulaiSpacing.sm),
                      decoration: BoxDecoration(
                        color: TulaiColors.backgroundSecondary,
                        borderRadius:
                            BorderRadius.circular(TulaiBorderRadius.sm),
                      ),
                      child: SelectableText(
                        filePath,
                        style: TulaiTextStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
      debugPrint('Export error: $e');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? TulaiColors.error : TulaiColors.success,
      ),
    );
  }

  Future<bool?> _showImportPreviewDialog(
    List<Student> students,
    int errorCount,
    List<String> errors,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportPreviewDialog(
        students: students,
        errorCount: errorCount,
        errors: errors,
      ),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      // Pick Excel file - force withData for all platforms
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;

      // Get file bytes
      List<int>? fileBytes;

      try {
        debugPrint('=== FILE READING DEBUG ===');
        debugPrint('Platform: ${kIsWeb ? "Web" : "Desktop/Mobile"}');
        debugPrint('File name: ${result.files.first.name}');
        debugPrint('File size: ${result.files.first.size} bytes');
        debugPrint('File extension: ${result.files.first.extension}');
        debugPrint('Has bytes: ${result.files.first.bytes != null}');

        fileBytes = result.files.first.bytes;
        debugPrint('Bytes from picker: ${fileBytes?.length ?? 0}');

        // Only try reading from path on non-web platforms
        if (!kIsWeb && (fileBytes == null || fileBytes.isEmpty)) {
          debugPrint('Attempting to read from file path (non-web only)...');
          final path = result.files.first.path;
          if (path != null) {
            final file = File(path);
            debugPrint('File path: ${file.path}');
            debugPrint('File exists: ${await file.exists()}');
            if (await file.exists()) {
              debugPrint('File length: ${await file.length()} bytes');
              fileBytes = await file.readAsBytes();
              debugPrint(
                  'Successfully read ${fileBytes.length} bytes from file path');
            }
          }
        }

        debugPrint('Final fileBytes length: ${fileBytes?.length ?? 0}');
        debugPrint('=== END DEBUG ===');
      } catch (e, stackTrace) {
        debugPrint('Error reading file: $e');
        debugPrint('Stack trace: $stackTrace');
        _showMessage('Error reading file: $e', isError: true);
        return;
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        debugPrint('ERROR: fileBytes is null or empty!');
        debugPrint('fileBytes == null: ${fileBytes == null}');
        debugPrint('fileBytes.isEmpty: ${fileBytes?.isEmpty}');
        _showMessage(
            'Failed to read file - file is empty (see console for details)',
            isError: true);
        return;
      }

      // Show loading dialog
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(TulaiSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: TulaiColors.primary),
                      const SizedBox(height: TulaiSpacing.md),
                      const Text('Importing students...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Parse Excel file
      debugPrint('Attempting to decode Excel file...');
      final excel = excel_lib.Excel.decodeBytes(fileBytes);
      debugPrint('Excel decoded successfully');
      debugPrint('Available sheets: ${excel.tables.keys.join(", ")}');

      if (excel.tables.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showMessage('Excel file has no sheets', isError: true);
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];
      debugPrint('Sheet name: ${excel.tables.keys.first}');
      debugPrint('Total rows: ${sheet?.rows.length ?? 0}');

      if (sheet == null || sheet.rows.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showMessage('No data found in Excel file', isError: true);
        return;
      }

      // Check if there's at least a header row
      if (sheet.rows.length < 2) {
        if (mounted) Navigator.pop(context);
        _showMessage('Excel file only contains headers, no data rows',
            isError: true);
        return;
      }

      debugPrint('Header row columns: ${sheet.rows[0].length}');

      // Get active batch
      final batches = await BatchDatabase.getBatches();

      // Check if batches exist
      if (batches.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showMessage(
            'No batch available for import. Please create a batch first.',
            isError: true);
        return;
      }

      // Use selectedBatchId if available, otherwise use first batch
      final activeBatch = selectedBatchId != null
          ? batches.firstWhere(
              (b) => b.id == selectedBatchId,
              orElse: () => batches.first,
            )
          : batches.first;

      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];
      final List<Student> studentsToImport = [];

      // Skip header row, start from row 1
      for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];

        try {
          debugPrint('Processing row ${rowIndex + 1}, columns: ${row.length}');

          // Extract data from columns matching the exported Excel format
          // Column indices based on exported headers
          final lastName = row[0]?.value?.toString().trim() ?? '';
          final firstName = row[1]?.value?.toString().trim() ?? '';
          final middleName = row[2]?.value?.toString().trim() ?? '';
          final nameExtension = row[3]?.value?.toString().trim() ?? '';
          final sex = row[4]?.value?.toString().trim() ?? '';
          final birthdateStr = row[5]?.value?.toString().trim() ?? '';
          final placeOfBirth = row[6]?.value?.toString().trim() ?? '';
          final civilStatus = row[7]?.value?.toString().trim() ?? '';
          final religion = row[8]?.value?.toString().trim() ?? '';
          final ethnicGroup = row[9]?.value?.toString().trim() ?? '';
          final motherTongue = row[10]?.value?.toString().trim() ?? '';
          final contactNumber = row[11]?.value?.toString().trim() ?? '';
          final pwdStr = row[12]?.value?.toString().trim() ?? '';
          final houseStreetSitio = row[13]?.value?.toString().trim() ?? '';
          final barangay = row[14]?.value?.toString().trim() ?? '';
          final municipalityCity = row[15]?.value?.toString().trim() ?? '';
          final province = row[16]?.value?.toString().trim() ?? '';
          final fatherLastName = row[17]?.value?.toString().trim() ?? '';
          final fatherFirstName = row[18]?.value?.toString().trim() ?? '';
          final fatherMiddleName = row[19]?.value?.toString().trim() ?? '';
          final fatherOccupation = row[20]?.value?.toString().trim() ?? '';
          final motherLastName = row[21]?.value?.toString().trim() ?? '';
          final motherFirstName = row[22]?.value?.toString().trim() ?? '';
          final motherMiddleName = row[23]?.value?.toString().trim() ?? '';
          final motherOccupation = row[24]?.value?.toString().trim() ?? '';
          final lastSchoolAttended = row[25]?.value?.toString().trim() ?? '';
          final lastGradeLevelCompleted =
              row[26]?.value?.toString().trim() ?? '';
          final reasonForIncompleteSchooling =
              row[27]?.value?.toString().trim() ?? '';
          final hasAttendedALSStr = row[28]?.value?.toString().trim() ?? '';

          // Validate required fields
          if (lastName.isEmpty || firstName.isEmpty) {
            errorCount++;
            errors.add('Row ${rowIndex + 1}: Missing name');
            continue;
          }

          // Parse birthdate if provided
          DateTime? birthdate;
          if (birthdateStr.isNotEmpty && birthdateStr != 'N/A') {
            try {
              // Try parsing ISO format first
              birthdate = DateTime.parse(birthdateStr);
            } catch (e) {
              // Try alternate date formats (MM/dd/yyyy)
              try {
                final parts = birthdateStr.split('/');
                if (parts.length == 3) {
                  birthdate = DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                  );
                }
              } catch (_) {
                // Skip invalid date
              }
            }
          }

          // Parse boolean fields
          final isPWD = pwdStr.toLowerCase() == 'yes' ||
              pwdStr == '1' ||
              pwdStr.toLowerCase() == 'true';
          final hasAttendedALS = hasAttendedALSStr.toLowerCase() == 'yes' ||
              hasAttendedALSStr == '1' ||
              hasAttendedALSStr.toLowerCase() == 'true';

          // Normalize sex field to English (Male/Female)
          String? normalizedSex;
          if (sex.isNotEmpty && sex != 'N/A') {
            final sexLower = sex.toLowerCase();
            if (sexLower == 'male' || sexLower == 'lalaki' || sexLower == 'm') {
              normalizedSex = 'Male';
            } else if (sexLower == 'female' ||
                sexLower == 'babae' ||
                sexLower == 'f') {
              normalizedSex = 'Female';
            } else {
              normalizedSex = sex; // Keep original if unrecognized
            }
          }

          // Create student record with all fields
          final student = Student(
            lastName: lastName,
            firstName: firstName,
            middleName: middleName.isNotEmpty && middleName != 'N/A'
                ? middleName
                : null,
            nameExtension: nameExtension.isNotEmpty && nameExtension != 'N/A'
                ? nameExtension
                : null,
            birthdate: birthdate,
            placeOfBirth: placeOfBirth.isNotEmpty && placeOfBirth != 'N/A'
                ? placeOfBirth
                : null,
            sex: normalizedSex,
            civilStatus: civilStatus.isNotEmpty && civilStatus != 'N/A'
                ? civilStatus
                : null,
            religion:
                religion.isNotEmpty && religion != 'N/A' ? religion : null,
            ethnicGroup: ethnicGroup.isNotEmpty && ethnicGroup != 'N/A'
                ? ethnicGroup
                : null,
            motherTongue: motherTongue.isNotEmpty && motherTongue != 'N/A'
                ? motherTongue
                : null,
            contactNumber: contactNumber.isNotEmpty && contactNumber != 'N/A'
                ? contactNumber
                : null,
            isPWD: isPWD,
            houseStreetSitio:
                houseStreetSitio.isNotEmpty && houseStreetSitio != 'N/A'
                    ? houseStreetSitio
                    : null,
            barangay:
                barangay.isNotEmpty && barangay != 'N/A' ? barangay : null,
            municipalityCity:
                municipalityCity.isNotEmpty && municipalityCity != 'N/A'
                    ? municipalityCity
                    : null,
            province:
                province.isNotEmpty && province != 'N/A' ? province : null,
            fatherLastName: fatherLastName.isNotEmpty && fatherLastName != 'N/A'
                ? fatherLastName
                : null,
            fatherFirstName:
                fatherFirstName.isNotEmpty && fatherFirstName != 'N/A'
                    ? fatherFirstName
                    : null,
            fatherMiddleName:
                fatherMiddleName.isNotEmpty && fatherMiddleName != 'N/A'
                    ? fatherMiddleName
                    : null,
            fatherOccupation:
                fatherOccupation.isNotEmpty && fatherOccupation != 'N/A'
                    ? fatherOccupation
                    : null,
            motherLastName: motherLastName.isNotEmpty && motherLastName != 'N/A'
                ? motherLastName
                : null,
            motherFirstName:
                motherFirstName.isNotEmpty && motherFirstName != 'N/A'
                    ? motherFirstName
                    : null,
            motherMiddleName:
                motherMiddleName.isNotEmpty && motherMiddleName != 'N/A'
                    ? motherMiddleName
                    : null,
            motherOccupation:
                motherOccupation.isNotEmpty && motherOccupation != 'N/A'
                    ? motherOccupation
                    : null,
            lastSchoolAttended:
                lastSchoolAttended.isNotEmpty && lastSchoolAttended != 'N/A'
                    ? lastSchoolAttended
                    : null,
            lastGradeLevelCompleted: lastGradeLevelCompleted.isNotEmpty &&
                    lastGradeLevelCompleted != 'N/A'
                ? lastGradeLevelCompleted
                : null,
            reasonForIncompleteSchooling:
                reasonForIncompleteSchooling.isNotEmpty &&
                        reasonForIncompleteSchooling != 'N/A'
                    ? reasonForIncompleteSchooling
                    : null,
            hasAttendedALS: hasAttendedALS,
            batchId: activeBatch.id,
          );

          studentsToImport.add(student);
        } catch (e) {
          errorCount++;
          final errorMsg = 'Row ${rowIndex + 1}: $e';
          errors.add(errorMsg);
          debugPrint('Error processing row ${rowIndex + 1}: $e');
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show preview dialog
      if (mounted && studentsToImport.isNotEmpty) {
        final confirm = await _showImportPreviewDialog(
            studentsToImport, errorCount, errors);

        if (confirm == true) {
          // Import the students
          for (var student in studentsToImport) {
            try {
              await StudentDatabase.insertStudent(student);
              successCount++;
              debugPrint(
                  'Successfully imported: ${student.lastName}, ${student.firstName}');
            } catch (e) {
              errorCount++;
              errors.add(
                  'Failed to save ${student.lastName}, ${student.firstName}: $e');
              debugPrint('Error importing: $e');
            }
          }

          // Reload students
          await fetchStudents();

          // Show result
          if (mounted) {
            _showMessage(
                'Successfully imported $successCount students${errorCount > 0 ? " ($errorCount failed)" : ""}');
          }
        }
      } else if (mounted) {
        _showMessage('No valid students found to import', isError: true);
      }
    } catch (e, stackTrace) {
      // Try to close loading dialog if it's open
      try {
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (_) {
        // Dialog might not be open, ignore
      }

      debugPrint('Import error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showMessage('Import failed: $e', isError: true);
    }
  }

  void _toggleSortMode() {
    setState(() {
      currentSortMode = currentSortMode == SortMode.alphabetical
          ? SortMode.createdAt
          : SortMode.alphabetical;
    });

    // Re-apply filter and sort when toggling
    _filterAndSortStudents();
  }

  // Helper method to build the search and filter section
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(TulaiSpacing.lg),
      decoration: const BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        boxShadow: TulaiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TulaiTextField(
                  controller: searchController,
                  hint: 'Search by name, barangay, contact, address...',
                  prefixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TulaiColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.search,
                          color: TulaiColors.primary,
                          size: 24,
                        ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: TulaiColors.textSecondary,
                          ),
                          onPressed: _clearSearch,
                          tooltip: 'Clear search',
                        )
                      : null,
                ),
              ),
              const SizedBox(width: TulaiSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: TulaiColors.primary,
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                child: IconButton(
                  tooltip: currentSortMode == SortMode.alphabetical
                      ? 'Sort by Date Created'
                      : 'Sort Alphabetically',
                  icon: Icon(
                    currentSortMode == SortMode.alphabetical
                        ? Icons.sort_by_alpha
                        : Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleSortMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: TulaiSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TulaiSpacing.md,
                  vertical: TulaiSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TulaiColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.xl),
                  border: Border.all(
                    color: TulaiColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${filteredStudents.length} ${filteredStudents.length == 1 ? 'enrollee' : 'enrollees'} found',
                  style: TulaiTextStyles.labelSmall.copyWith(
                    color: TulaiColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: TulaiSpacing.sm),
              OutlinedButton.icon(
                onPressed: filteredStudents.isEmpty ? null : _exportToExcel,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.md,
                    vertical: TulaiSpacing.xs,
                  ),
                  side: BorderSide(color: TulaiColors.primary.withOpacity(0.5)),
                  foregroundColor: TulaiColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Sorted ${currentSortMode == SortMode.alphabetical ? 'alphabetically' : 'by date'}',
                style: TulaiTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build student cards
  Widget _buildStudentCard(Student student, BuildContext context) {
    final fullName = [
      student.firstName,
      student.middleName,
      student.lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    // Fallback for empty names
    final displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';
    final initials = _getInitials(displayName);

    return TulaiCard(
      margin: const EdgeInsets.symmetric(
        horizontal: TulaiSpacing.lg,
        vertical: TulaiSpacing.xs,
      ),
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EnrolleeInformation(student: student),
          ),
        );

        // If student was deleted, refresh the list
        if (deleted == true) {
          fetchStudents();
        }
      },
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TulaiColors.primary, TulaiColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(TulaiBorderRadius.round),
            ),
            child: Center(
              child: Text(
                initials,
                style: TulaiTextStyles.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: TulaiSpacing.md),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TulaiTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TulaiSpacing.xs),
                if (student.municipalityCity != null)
                  Text(
                    student.municipalityCity!,
                    style: TulaiTextStyles.bodySmall,
                  ),
                const SizedBox(height: TulaiSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.sm,
                    vertical: TulaiSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  ),
                  child: Text(
                    student.created_at != null
                        ? 'Enrolled ${_getRelativeTime(student.created_at!)}'
                        : 'Recently enrolled',
                    style: TulaiTextStyles.caption.copyWith(
                      color: TulaiColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chevron icon
          const Icon(
            Icons.chevron_right,
            color: TulaiColors.textMuted,
            size: 24,
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
      return 'Just now';
    }
  }

  // Helper method to build empty state
  Widget _buildEmptyState() {
    final hasSearchQuery = searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TulaiSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: TulaiColors.textMuted,
            ),
            const SizedBox(height: TulaiSpacing.lg),
            Text(
              hasSearchQuery ? 'No results found' : 'No enrollees yet',
              style: TulaiTextStyles.heading3.copyWith(
                color: TulaiColors.textSecondary,
              ),
            ),
            const SizedBox(height: TulaiSpacing.sm),
            Text(
              hasSearchQuery
                  ? 'No enrollees match "${searchController.text}"\nTry different search terms or clear the search'
                  : 'Enrollees will appear here once students complete their enrollment',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearchQuery) ...[
              const SizedBox(height: TulaiSpacing.lg),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear, size: 20),
                label: const Text('Clear Search'),
                onPressed: _clearSearch,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.lg,
                    vertical: TulaiSpacing.md,
                  ),
                  side: const BorderSide(color: TulaiColors.primary),
                  foregroundColor: TulaiColors.primary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.md),
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.md),
                decoration: BoxDecoration(
                  color: TulaiColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  border: Border.all(color: TulaiColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: TulaiColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: TulaiSpacing.xs),
                        Text(
                          'Search Tips',
                          style: TulaiTextStyles.labelMedium.copyWith(
                            color: TulaiColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TulaiSpacing.sm),
                    Text(
                      '• Search by name (first, middle, or last)\n'
                      '• Search by barangay or municipality\n'
                      '• Search by contact number\n'
                      '• Search by address or province',
                      style: TulaiTextStyles.bodySmall.copyWith(
                        color: TulaiColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper for fallback grouped list if no batches (legacy/unassigned)
  List<Widget> _buildBatchGroupedList() {
    if (filteredStudents.isEmpty) return [];
    return [
      _BatchDivider(label: 'Enrollees'),
      ...filteredStudents.map((s) => _buildStudentCard(s, context)),
    ];
  }

  // Fix for firstWhere: return a dummy Batch if not found
  List<Widget> _buildBatchGroupedListFor(String batchId) {
    final studentsForBatch =
        filteredStudents.where((s) => s.batchId == batchId).toList();
    final batch = batches.firstWhere(
      (b) => b.id == batchId,
      orElse: () => Batch(id: batchId, startYear: 0, endYear: 0),
    );
    String label = (batch.startYear != 0 && batch.endYear != 0)
        ? 'Batch ${batch.startYear} - ${batch.endYear}'
        : 'Unassigned Batch';
    if (studentsForBatch.isEmpty) {
      return [_BatchDivider(label: label), _buildEmptyState()];
    }
    return [
      _BatchDivider(label: label),
      ...studentsForBatch.map((s) => _buildStudentCard(s, context)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a large screen (web/tablet)
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: TulaiColors.backgroundPrimary,
        title: const Text(
          'Enrollees',
          style: TulaiTextStyles.heading2,
        ),
        actions: [
          // Import button
          IconButton(
            icon: const Icon(Icons.upload_file, color: TulaiColors.primary),
            tooltip: 'Import from Excel',
            onPressed: _importFromExcel,
          ),
          // Export button
          IconButton(
            icon: const Icon(Icons.download, color: TulaiColors.primary),
            tooltip: 'Export to Excel',
            onPressed: filteredStudents.isEmpty ? null : _exportToExcel,
          ),
          if (isLargeScreen)
            Padding(
              padding: const EdgeInsets.only(right: TulaiSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.md,
                    vertical: TulaiSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.xl),
                  ),
                  child: Text(
                    'Total: ${students.length}',
                    style: TulaiTextStyles.labelMedium.copyWith(
                      color: TulaiColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TulaiColors.primary),
              ),
            )
          : Column(
              children: [
                _buildSearchAndFilter(),
                if (batches.isNotEmpty && _tabController != null)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: TulaiColors.primary,
                    unselectedLabelColor: TulaiColors.textMuted,
                    indicatorColor: TulaiColors.primary,
                    tabs: [
                      for (final batch in batches)
                        Tab(text: 'Batch ${batch.startYear} - ${batch.endYear}')
                    ],
                  ),
                if (batches.isNotEmpty && _tabController != null)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        for (final batch in batches)
                          RefreshIndicator(
                            onRefresh: () async {
                              await fetchBatches();
                              await fetchStudents();
                            },
                            color: TulaiColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: TulaiSpacing.md),
                              children: _buildBatchGroupedListFor(batch.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (batches.isEmpty)
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: fetchStudents,
                            color: TulaiColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: TulaiSpacing.md),
                              children: _buildBatchGroupedList(),
                            ),
                          ),
                  ),
              ],
            ),
    );
  }
}

// Import Preview Dialog
class _ImportPreviewDialog extends StatefulWidget {
  final List<Student> students;
  final int errorCount;
  final List<String> errors;

  const _ImportPreviewDialog({
    required this.students,
    required this.errorCount,
    required this.errors,
  });

  @override
  State<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<_ImportPreviewDialog> {
  late List<Student> editableStudents;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    editableStudents = List.from(widget.students);
  }

  bool _hasEmptyFields(Student student) {
    return student.sex == null ||
        student.birthdate == null ||
        student.barangay == null ||
        student.municipalityCity == null ||
        student.province == null;
  }

  void _updateField(String field, dynamic value) {
    final current = editableStudents[selectedIndex];
    setState(() {
      editableStudents[selectedIndex] = Student(
        id: current.id,
        lastName: field == 'lastName' ? value : current.lastName,
        firstName: field == 'firstName' ? value : current.firstName,
        middleName: field == 'middleName' ? value : current.middleName,
        nameExtension: field == 'nameExtension' ? value : current.nameExtension,
        houseStreetSitio:
            field == 'houseStreetSitio' ? value : current.houseStreetSitio,
        barangay: field == 'barangay' ? value : current.barangay,
        municipalityCity:
            field == 'municipalityCity' ? value : current.municipalityCity,
        province: field == 'province' ? value : current.province,
        birthdate: field == 'birthdate' ? value : current.birthdate,
        sex: field == 'sex' ? value : current.sex,
        placeOfBirth: field == 'placeOfBirth' ? value : current.placeOfBirth,
        civilStatus: field == 'civilStatus' ? value : current.civilStatus,
        religion: field == 'religion' ? value : current.religion,
        ethnicGroup: field == 'ethnicGroup' ? value : current.ethnicGroup,
        motherTongue: field == 'motherTongue' ? value : current.motherTongue,
        contactNumber: field == 'contactNumber' ? value : current.contactNumber,
        isPWD: field == 'isPWD' ? value : current.isPWD,
        fatherLastName:
            field == 'fatherLastName' ? value : current.fatherLastName,
        fatherFirstName:
            field == 'fatherFirstName' ? value : current.fatherFirstName,
        fatherMiddleName:
            field == 'fatherMiddleName' ? value : current.fatherMiddleName,
        fatherOccupation:
            field == 'fatherOccupation' ? value : current.fatherOccupation,
        motherLastName:
            field == 'motherLastName' ? value : current.motherLastName,
        motherFirstName:
            field == 'motherFirstName' ? value : current.motherFirstName,
        motherMiddleName:
            field == 'motherMiddleName' ? value : current.motherMiddleName,
        motherOccupation:
            field == 'motherOccupation' ? value : current.motherOccupation,
        lastSchoolAttended:
            field == 'lastSchoolAttended' ? value : current.lastSchoolAttended,
        lastGradeLevelCompleted: field == 'lastGradeLevelCompleted'
            ? value
            : current.lastGradeLevelCompleted,
        reasonForIncompleteSchooling: field == 'reasonForIncompleteSchooling'
            ? value
            : current.reasonForIncompleteSchooling,
        hasAttendedALS:
            field == 'hasAttendedALS' ? value : current.hasAttendedALS,
        created_at: current.created_at,
        batchId: current.batchId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final currentStudent = editableStudents[selectedIndex];
    final hasWarnings = _hasEmptyFields(currentStudent);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 900 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.lg),
              decoration: const BoxDecoration(
                color: TulaiColors.backgroundPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(TulaiBorderRadius.lg),
                  topRight: Radius.circular(TulaiBorderRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview, color: TulaiColors.primary, size: 28),
                  const SizedBox(width: TulaiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Preview',
                          style: TulaiTextStyles.heading3.copyWith(
                            color: TulaiColors.primary,
                          ),
                        ),
                        Text(
                          '${editableStudents.length} students ready to import',
                          style: TulaiTextStyles.bodySmall.copyWith(
                            color: TulaiColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Student Navigator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TulaiSpacing.lg,
                vertical: TulaiSpacing.md,
              ),
              color: TulaiColors.backgroundSecondary,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: selectedIndex > 0
                        ? () => setState(() => selectedIndex--)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      'Student ${selectedIndex + 1} of ${editableStudents.length}',
                      textAlign: TextAlign.center,
                      style: TulaiTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedIndex < editableStudents.length - 1
                        ? () => setState(() => selectedIndex++)
                        : null,
                  ),
                ],
              ),
            ),

            // Warnings
            if (hasWarnings)
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.md),
                margin: const EdgeInsets.all(TulaiSpacing.md),
                decoration: BoxDecoration(
                  color: TulaiColors.warning.withOpacity(0.1),
                  border: Border.all(color: TulaiColors.warning),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: TulaiColors.warning, size: 20),
                    const SizedBox(width: TulaiSpacing.sm),
                    Expanded(
                      child: Text(
                        'Some required fields are empty',
                        style: TulaiTextStyles.bodyMedium.copyWith(
                          color: TulaiColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Student Details Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TulaiSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditableField(
                      'Last Name',
                      currentStudent.lastName ?? '',
                      (value) => _updateField('lastName', value),
                      required: true,
                    ),
                    _buildEditableField(
                      'First Name',
                      currentStudent.firstName ?? '',
                      (value) => _updateField('firstName', value),
                      required: true,
                    ),
                    _buildEditableField(
                      'Middle Name',
                      currentStudent.middleName ?? '',
                      (value) => _updateField(
                          'middleName', value.isEmpty ? null : value),
                    ),
                    _buildDropdownField(
                      'Sex',
                      currentStudent.sex,
                      ['Male', 'Female'],
                      (value) => _updateField('sex', value),
                      hasWarning: currentStudent.sex == null,
                    ),
                    _buildEditableField(
                      'Place of Birth',
                      currentStudent.placeOfBirth ?? '',
                      (value) => _updateField(
                          'placeOfBirth', value.isEmpty ? null : value),
                    ),
                    _buildDropdownField(
                      'Civil Status',
                      currentStudent.civilStatus,
                      [
                        'Single',
                        'Married',
                        'Separated',
                        'Widowed',
                        'Solo Parent'
                      ],
                      (value) => _updateField('civilStatus', value),
                    ),
                    _buildEditableField(
                      'Birthdate (MM/DD/YYYY)',
                      currentStudent.birthdate != null
                          ? DateFormat('MM/dd/yyyy')
                              .format(currentStudent.birthdate!)
                          : '',
                      (value) {
                        if (value.isEmpty) {
                          _updateField('birthdate', null);
                        } else {
                          try {
                            final parts = value.split('/');
                            if (parts.length == 3) {
                              final date = DateTime(int.parse(parts[2]),
                                  int.parse(parts[0]), int.parse(parts[1]));
                              _updateField('birthdate', date);
                            }
                          } catch (_) {}
                        }
                      },
                      hasWarning: currentStudent.birthdate == null,
                    ),
                    _buildEditableField(
                      'Barangay',
                      currentStudent.barangay ?? '',
                      (value) => _updateField(
                          'barangay', value.isEmpty ? null : value),
                      hasWarning: currentStudent.barangay == null,
                    ),
                    _buildEditableField(
                      'Municipality/City',
                      currentStudent.municipalityCity ?? '',
                      (value) => _updateField(
                          'municipalityCity', value.isEmpty ? null : value),
                      hasWarning: currentStudent.municipalityCity == null,
                    ),
                    _buildEditableField(
                      'Province',
                      currentStudent.province ?? '',
                      (value) => _updateField(
                          'province', value.isEmpty ? null : value),
                      hasWarning: currentStudent.province == null,
                    ),
                    _buildEditableField(
                      'House/Street/Sitio',
                      currentStudent.houseStreetSitio ?? '',
                      (value) => _updateField(
                          'houseStreetSitio', value.isEmpty ? null : value),
                    ),
                    _buildEditableField(
                      'Contact Number',
                      currentStudent.contactNumber ?? '',
                      (value) => _updateField(
                          'contactNumber', value.isEmpty ? null : value),
                    ),
                    _buildDropdownField(
                      'PWD',
                      currentStudent.isPWD == true
                          ? 'Yes'
                          : currentStudent.isPWD == false
                              ? 'No'
                              : null,
                      ['Yes', 'No'],
                      (value) => _updateField('isPWD', value == 'Yes'),
                    ),
                    _buildDropdownField(
                      'Religion',
                      currentStudent.religion,
                      [
                        'Roman Catholic',
                        'Islam',
                        'Iglesia ni Cristo',
                        'Born Again Christian',
                        'Seventh-day Adventist',
                        'Buddhism',
                        'Other'
                      ],
                      (value) => _updateField('religion', value),
                    ),
                    _buildEditableField(
                      'Mother Tongue',
                      currentStudent.motherTongue ?? '',
                      (value) => _updateField(
                          'motherTongue', value.isEmpty ? null : value),
                    ),
                    _buildEditableField(
                      'Ethnic Group',
                      currentStudent.ethnicGroup ?? '',
                      (value) => _updateField(
                          'ethnicGroup', value.isEmpty ? null : value),
                    ),
                    _buildDropdownField(
                      'Has Attended ALS',
                      currentStudent.hasAttendedALS == true
                          ? 'Yes'
                          : currentStudent.hasAttendedALS == false
                              ? 'No'
                              : null,
                      ['Yes', 'No'],
                      (value) => _updateField('hasAttendedALS', value == 'Yes'),
                    ),
                  ],
                ),
              ),
            ),

            // Error Summary
            if (widget.errorCount > 0)
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.md),
                margin: const EdgeInsets.symmetric(horizontal: TulaiSpacing.lg),
                decoration: BoxDecoration(
                  color: TulaiColors.error.withOpacity(0.1),
                  border: Border.all(color: TulaiColors.error),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.errorCount} rows had errors and were skipped',
                      style: TulaiTextStyles.bodyMedium.copyWith(
                        color: TulaiColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: TulaiColors.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: TulaiSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check),
                    label: Text('Import ${editableStudents.length} Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TulaiColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TulaiSpacing.lg,
                        vertical: TulaiSpacing.md,
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

  Widget _buildEditableField(
    String label,
    String initialValue,
    Function(String) onChanged, {
    bool hasWarning = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TulaiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TulaiTextStyles.labelMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(color: TulaiColors.error, fontSize: 16),
                ),
              ],
              if (hasWarning) ...[
                const SizedBox(width: 4),
                Icon(Icons.warning, size: 16, color: TulaiColors.warning),
              ],
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              hintText:
                  hasWarning ? 'Empty - needs to be filled' : 'Enter $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning
                      ? TulaiColors.warning
                      : TulaiColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning
                      ? TulaiColors.warning
                      : TulaiColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning ? TulaiColors.warning : TulaiColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: hasWarning
                  ? TulaiColors.warning.withOpacity(0.05)
                  : TulaiColors.backgroundPrimary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TulaiSpacing.md,
                vertical: TulaiSpacing.sm,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? currentValue,
    List<String> options,
    Function(String?) onChanged, {
    bool hasWarning = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TulaiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TulaiTextStyles.labelMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(color: TulaiColors.error, fontSize: 16),
                ),
              ],
              if (hasWarning) ...[
                const SizedBox(width: 4),
                Icon(Icons.warning, size: 16, color: TulaiColors.warning),
              ],
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: currentValue?.isEmpty == true ? null : currentValue,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            decoration: InputDecoration(
              hintText:
                  hasWarning ? 'Empty - needs to be filled' : 'Select $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning
                      ? TulaiColors.warning
                      : TulaiColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning
                      ? TulaiColors.warning
                      : TulaiColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                borderSide: BorderSide(
                  color: hasWarning ? TulaiColors.warning : TulaiColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: hasWarning
                  ? TulaiColors.warning.withOpacity(0.05)
                  : TulaiColors.backgroundPrimary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TulaiSpacing.md,
                vertical: TulaiSpacing.sm,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
