import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tulai/utils/download_helper.dart' as download_helper;

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  // Analytics data
  int _totalEnrollees = 0;
  int _maleCount = 0;
  int _femaleCount = 0;
  int _pwdCount = 0;
  Map<String, int> _ageGroups = {};
  Map<String, int> _civilStatus = {};
  Map<String, int> _barangayDistribution = {};
  Map<String, int> _monthlyEnrollments = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all students
      final response = await _supabase.from('students').select('*');
      final students = List<Map<String, dynamic>>.from(response);

      _totalEnrollees = students.length;
      _maleCount = students
          .where((e) => e['sex']?.toString().toLowerCase() == 'male')
          .length;
      _femaleCount = students
          .where((e) => e['sex']?.toString().toLowerCase() == 'female')
          .length;
      _pwdCount = students.where((e) => e['is_pwd'] == true).length;

      // Calculate age groups
      _ageGroups = {
        '15-20': 0,
        '21-30': 0,
        '31-40': 0,
        '41-50': 0,
        '51+': 0,
      };

      for (var student in students) {
        if (student['birthdate'] != null) {
          final birthdate = DateTime.parse(student['birthdate']);
          final age = DateTime.now().year - birthdate.year;

          if (age <= 20)
            _ageGroups['15-20'] = (_ageGroups['15-20'] ?? 0) + 1;
          else if (age <= 30)
            _ageGroups['21-30'] = (_ageGroups['21-30'] ?? 0) + 1;
          else if (age <= 40)
            _ageGroups['31-40'] = (_ageGroups['31-40'] ?? 0) + 1;
          else if (age <= 50)
            _ageGroups['41-50'] = (_ageGroups['41-50'] ?? 0) + 1;
          else
            _ageGroups['51+'] = (_ageGroups['51+'] ?? 0) + 1;
        }
      }

      // Civil status distribution
      _civilStatus = {};
      for (var student in students) {
        final status = student['civil_status']?.toString() ?? 'Not specified';
        _civilStatus[status] = (_civilStatus[status] ?? 0) + 1;
      }

      // Barangay distribution (top 5)
      Map<String, int> allBarangays = {};
      for (var student in students) {
        final barangay = student['barangay']?.toString() ?? 'Not specified';
        allBarangays[barangay] = (allBarangays[barangay] ?? 0) + 1;
      }
      var sortedBarangays = allBarangays.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _barangayDistribution = Map.fromEntries(sortedBarangays.take(5));

      // Monthly enrollments (last 6 months)
      _monthlyEnrollments = {};
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${_getMonthName(month.month)}';
        _monthlyEnrollments[monthKey] = 0;
      }

      for (var student in students) {
        if (student['created_at'] != null) {
          final createdDate = DateTime.parse(student['created_at']);
          final monthKey = '${_getMonthName(createdDate.month)}';
          if (_monthlyEnrollments.containsKey(monthKey)) {
            _monthlyEnrollments[monthKey] =
                (_monthlyEnrollments[monthKey] ?? 0) + 1;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  Future<void> _downloadAnalyticsReport() async {
    try {
      // Create Excel workbook
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['ALS Analytics Report'];

      int currentRow = 0;

      // Header Section - DepEd Format
      final headerStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      final titleStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      final sectionHeaderStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: excel_lib.ExcelColor.blue,
      );

      // Title
      var titleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      titleCell.value = excel_lib.TextCellValue('Republic of the Philippines');
      titleCell.cellStyle = headerStyle;
      currentRow++;

      var deptCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      deptCell.value = excel_lib.TextCellValue('Department of Education');
      deptCell.cellStyle = headerStyle;
      currentRow++;

      var alsCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      alsCell.value =
          excel_lib.TextCellValue('Alternative Learning System (ALS)');
      alsCell.cellStyle = titleStyle;
      currentRow += 2;

      var reportTitleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      reportTitleCell.value =
          excel_lib.TextCellValue('ENROLLMENT ANALYTICS REPORT');
      reportTitleCell.cellStyle = titleStyle;
      currentRow += 2;

      // Report Details
      final dateFormatter = DateFormat('MMMM dd, yyyy');
      var dateCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      dateCell.value = excel_lib.TextCellValue(
          'Report Generated: ${dateFormatter.format(DateTime.now())}');
      currentRow++;

      var periodCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      periodCell.value = excel_lib.TextCellValue(
          'School Year: ${DateTime.now().year}-${DateTime.now().year + 1}');
      currentRow += 2;

      // SUMMARY STATISTICS
      var summaryHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      summaryHeaderCell.value =
          excel_lib.TextCellValue('I. ENROLLMENT SUMMARY');
      summaryHeaderCell.cellStyle = sectionHeaderStyle;
      currentRow++;

      final summaryData = [
        ['Total Enrolled Learners', _totalEnrollees.toString()],
        ['Male Learners', _maleCount.toString()],
        ['Female Learners', _femaleCount.toString()],
        ['Persons with Disabilities (PWD)', _pwdCount.toString()],
        [
          'Male Percentage',
          '${(_totalEnrollees > 0 ? (_maleCount / _totalEnrollees * 100).toStringAsFixed(1) : '0')}%'
        ],
        [
          'Female Percentage',
          '${(_totalEnrollees > 0 ? (_femaleCount / _totalEnrollees * 100).toStringAsFixed(1) : '0')}%'
        ],
      ];

      for (var row in summaryData) {
        var labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ));
        labelCell.value = excel_lib.TextCellValue(row[0]);

        var valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: currentRow,
        ));
        valueCell.value = excel_lib.TextCellValue(row[1]);
        currentRow++;
      }
      currentRow++;

      // AGE GROUP DISTRIBUTION
      var ageHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      ageHeaderCell.value =
          excel_lib.TextCellValue('II. AGE GROUP DISTRIBUTION');
      ageHeaderCell.cellStyle = sectionHeaderStyle;
      currentRow++;

      for (var entry in _ageGroups.entries) {
        var labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ));
        labelCell.value = excel_lib.TextCellValue('Age ${entry.key}');

        var valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: currentRow,
        ));
        valueCell.value = excel_lib.TextCellValue('${entry.value} learners');
        currentRow++;
      }
      currentRow++;

      // CIVIL STATUS DISTRIBUTION
      var civilHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      civilHeaderCell.value =
          excel_lib.TextCellValue('III. CIVIL STATUS DISTRIBUTION');
      civilHeaderCell.cellStyle = sectionHeaderStyle;
      currentRow++;

      for (var entry in _civilStatus.entries) {
        var labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ));
        labelCell.value = excel_lib.TextCellValue(entry.key);

        var valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: currentRow,
        ));
        valueCell.value = excel_lib.TextCellValue('${entry.value} learners');
        currentRow++;
      }
      currentRow++;

      // TOP BARANGAYS
      var barangayHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      barangayHeaderCell.value =
          excel_lib.TextCellValue('IV. TOP 5 BARANGAYS BY ENROLLMENT');
      barangayHeaderCell.cellStyle = sectionHeaderStyle;
      currentRow++;

      int rank = 1;
      for (var entry in _barangayDistribution.entries) {
        var labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ));
        labelCell.value = excel_lib.TextCellValue('${rank++}. ${entry.key}');

        var valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: currentRow,
        ));
        valueCell.value = excel_lib.TextCellValue('${entry.value} learners');
        currentRow++;
      }
      currentRow++;

      // MONTHLY ENROLLMENT TREND
      var monthlyHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      monthlyHeaderCell.value = excel_lib.TextCellValue(
          'V. MONTHLY ENROLLMENT TREND (Last 6 Months)');
      monthlyHeaderCell.cellStyle = sectionHeaderStyle;
      currentRow++;

      for (var entry in _monthlyEnrollments.entries) {
        var labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ));
        labelCell.value = excel_lib.TextCellValue(entry.key);

        var valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: currentRow,
        ));
        valueCell.value =
            excel_lib.TextCellValue('${entry.value} new enrollees');
        currentRow++;
      }
      currentRow += 2;

      // Footer
      var footerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      footerCell.value =
          excel_lib.TextCellValue('Prepared by: ALS Enrollment System (TULAI)');
      currentRow++;

      var preparedDateCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: currentRow,
      ));
      preparedDateCell.value = excel_lib.TextCellValue(
          'Date: ${dateFormatter.format(DateTime.now())}');

      // Save and download
      var fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName =
            'ALS_Analytics_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';

        // Platform-specific save
        if (kIsWeb) {
          // Web: Use browser download
          await download_helper.downloadBytes(fileBytes, fileName);
        } else {
          // Mobile/Desktop: Save to Downloads directory
          Directory? directory;
          if (Platform.isAndroid) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } else if (Platform.isIOS) {
            directory = await getApplicationDocumentsDirectory();
          } else {
            directory = await getDownloadsDirectory();
          }

          if (directory != null) {
            final filePath = '${directory.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(fileBytes);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analytics report saved: $fileName'),
              backgroundColor: TulaiColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error downloading analytics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading report: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TulaiColors.primary),
      );
    }

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(
                isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            color: TulaiColors.backgroundPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: isLargeScreen ? 40 : 32,
                      color: TulaiColors.primary,
                    ),
                    const SizedBox(width: TulaiSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics Dashboard',
                            style: TulaiTextStyles.heading2.copyWith(
                              color: TulaiColors.primary,
                              fontSize: isLargeScreen ? 28 : 24,
                            ),
                          ),
                          Text(
                            'Enrollment insights and statistics',
                            style: TulaiTextStyles.bodyMedium.copyWith(
                              color: TulaiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadAnalytics,
                      icon: const Icon(Icons.refresh),
                      color: TulaiColors.primary,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Download Button
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
              right: isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
              top: TulaiSpacing.sm,
              bottom: TulaiSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _downloadAnalyticsReport,
                icon: const Icon(Icons.download, size: 18),
                label: Text(isLargeScreen ? 'Download Report' : 'Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TulaiColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.md,
                    vertical: TulaiSpacing.xs,
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ),

        // Key Statistics Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(
                isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            child: isLargeScreen
                ? Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                        '$_totalEnrollees',
                        'Total Enrollees',
                        Icons.people,
                        TulaiColors.primary,
                      )),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                          child: _buildStatCard(
                        '$_maleCount',
                        'Male',
                        Icons.male,
                        TulaiColors.info,
                      )),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                          child: _buildStatCard(
                        '$_femaleCount',
                        'Female',
                        Icons.female,
                        TulaiColors.secondary,
                      )),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                          child: _buildStatCard(
                        '$_pwdCount',
                        'PWD',
                        Icons.accessible,
                        TulaiColors.warning,
                      )),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                            '$_totalEnrollees',
                            'Total Enrollees',
                            Icons.people,
                            TulaiColors.primary,
                          )),
                          const SizedBox(width: TulaiSpacing.md),
                          Expanded(
                              child: _buildStatCard(
                            '$_pwdCount',
                            'PWD',
                            Icons.accessible,
                            TulaiColors.warning,
                          )),
                        ],
                      ),
                      const SizedBox(height: TulaiSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                            '$_maleCount',
                            'Male',
                            Icons.male,
                            TulaiColors.info,
                          )),
                          const SizedBox(width: TulaiSpacing.md),
                          Expanded(
                              child: _buildStatCard(
                            '$_femaleCount',
                            'Female',
                            Icons.female,
                            TulaiColors.secondary,
                          )),
                        ],
                      ),
                    ],
                  ),
          ),
        ),

        // Charts Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLargeScreen ? 2 : 1,
              crossAxisSpacing: TulaiSpacing.lg,
              mainAxisSpacing: TulaiSpacing.lg,
              childAspectRatio: isLargeScreen ? 1.3 : 0.9,
            ),
            delegate: SliverChildListDelegate([
              _buildChartCard(
                'Gender Distribution',
                Icons.wc,
                _buildGenderChart(),
              ),
              _buildChartCard(
                'Age Group Distribution',
                Icons.cake,
                _buildAgeGroupChart(),
              ),
              _buildChartCard(
                'Monthly Enrollments',
                Icons.trending_up,
                _buildMonthlyEnrollmentsChart(),
              ),
              _buildChartCard(
                'Civil Status',
                Icons.family_restroom,
                _buildCivilStatusChart(),
              ),
            ]),
          ),
        ),

        // Top Barangays
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(
                isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            child: _buildChartCard(
              'Top 5 Barangays',
              Icons.location_city,
              _buildBarangayChart(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: TulaiSpacing.xl)),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(TulaiSpacing.lg),
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        boxShadow: TulaiShadows.md,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(TulaiSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: TulaiSpacing.md),
          Text(
            value,
            style: TulaiTextStyles.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TulaiTextStyles.bodyMedium.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(TulaiSpacing.lg),
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        boxShadow: TulaiShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TulaiSpacing.xs),
                decoration: BoxDecoration(
                  color: TulaiColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                ),
                child: Icon(icon, color: TulaiColors.primary, size: 20),
              ),
              const SizedBox(width: TulaiSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: TulaiTextStyles.heading3.copyWith(
                    color: TulaiColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TulaiSpacing.md),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildGenderChart() {
    final data = [
      _ChartData('Male', _maleCount, TulaiColors.info),
      _ChartData('Female', _femaleCount, TulaiColors.secondary),
    ];

    return SfCircularChart(
      key: const ValueKey('gender_chart'),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TulaiTextStyles.bodySmall,
      ),
      series: <PieSeries<_ChartData, String>>[
        PieSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          dataLabelMapper: (_ChartData data, _) => '${data.value}',
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TulaiTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }

  Widget _buildAgeGroupChart() {
    final data = _ageGroups.entries.map((e) {
      Color color;
      switch (e.key) {
        case '15-20':
          color = TulaiColors.primary;
          break;
        case '21-30':
          color = TulaiColors.secondary;
          break;
        case '31-40':
          color = TulaiColors.tertiary;
          break;
        case '41-50':
          color = TulaiColors.warning;
          break;
        default:
          color = TulaiColors.error;
      }
      return _ChartData(e.key, e.value, color);
    }).toList();

    return SfCartesianChart(
      key: const ValueKey('age_group_chart'),
      primaryXAxis: CategoryAxis(
        labelStyle: TulaiTextStyles.caption,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TulaiTextStyles.caption,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<_ChartData, String>>[
        ColumnSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle:
                TulaiTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyEnrollmentsChart() {
    final data = _monthlyEnrollments.entries
        .map((e) => _ChartData(e.key, e.value, TulaiColors.primary))
        .toList();

    return SfCartesianChart(
      key: const ValueKey('monthly_enrollments_chart'),
      primaryXAxis: CategoryAxis(
        labelStyle: TulaiTextStyles.caption,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TulaiTextStyles.caption,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<_ChartData, String>>[
        SplineAreaSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          color: TulaiColors.primary.withOpacity(0.3),
          borderColor: TulaiColors.primary,
          borderWidth: 3,
          markerSettings: const MarkerSettings(
            isVisible: true,
            color: TulaiColors.primary,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle:
                TulaiTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCivilStatusChart() {
    final data = _civilStatus.entries.map((e) {
      Color color;
      switch (e.key.toLowerCase()) {
        case 'single':
          color = TulaiColors.primary;
          break;
        case 'married':
          color = TulaiColors.secondary;
          break;
        case 'separated':
          color = TulaiColors.warning;
          break;
        case 'widowed':
          color = TulaiColors.error;
          break;
        default:
          color = TulaiColors.textMuted;
      }
      return _ChartData(e.key, e.value, color);
    }).toList();

    return SfCircularChart(
      key: const ValueKey('civil_status_chart'),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TulaiTextStyles.caption,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: <PieSeries<_ChartData, String>>[
        PieSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          dataLabelMapper: (_ChartData data, _) => '${data.value}',
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TulaiTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            labelPosition: ChartDataLabelPosition.inside,
          ),
          radius: '90%',
        ),
      ],
    );
  }

  Widget _buildBarangayChart() {
    final data = _barangayDistribution.entries
        .map((e) => _ChartData(e.key, e.value, TulaiColors.primary))
        .toList();

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        key: const ValueKey('barangay_chart'),
        primaryXAxis: CategoryAxis(
          labelStyle: TulaiTextStyles.caption,
          labelRotation: -45,
        ),
        primaryYAxis: NumericAxis(
          labelStyle: TulaiTextStyles.caption,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<_ChartData, String>>[
          BarSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData data, _) => data.label,
            yValueMapper: (_ChartData data, _) => data.value,
            color: TulaiColors.primary,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: TulaiTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;
  _ChartData(this.label, this.value, this.color);
}
