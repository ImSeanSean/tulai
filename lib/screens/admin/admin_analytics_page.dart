import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final genderData = [
      _ChartData('Male', 120, TulaiColors.primary),
      _ChartData('Female', 130, TulaiColors.secondary),
    ];
    final enrollData = [
      _ChartData('This Month', 50, TulaiColors.primary),
      _ChartData('Last Month', 40, TulaiColors.secondary),
    ];
    return Padding(
      padding:
          EdgeInsets.all(isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics', style: TulaiTextStyles.heading2),
          const SizedBox(height: TulaiSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TulaiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender Breakdown',
                      style: TulaiTextStyles.heading3),
                  const SizedBox(height: TulaiSpacing.md),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      legend: const Legend(
                          isVisible: true, position: LegendPosition.right),
                      series: <PieSeries<_ChartData, String>>[
                        PieSeries<_ChartData, String>(
                          dataSource: genderData,
                          xValueMapper: (_ChartData data, _) => data.label,
                          yValueMapper: (_ChartData data, _) => data.value,
                          pointColorMapper: (_ChartData data, _) => data.color,
                          dataLabelMapper: (_ChartData data, _) => data.label,
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TulaiSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TulaiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enrollment Rate',
                      style: TulaiTextStyles.heading3),
                  const SizedBox(height: TulaiSpacing.md),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      series: <CartesianSeries<_ChartData, String>>[
                        ColumnSeries<_ChartData, String>(
                          dataSource: enrollData,
                          xValueMapper: (_ChartData data, _) => data.label,
                          yValueMapper: (_ChartData data, _) => data.value,
                          pointColorMapper: (_ChartData data, _) => data.color,
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ); // Padding
  } // build
} // AdminAnalyticsPage

class _ChartData {
  final String label;
  final int value;
  final Color color;
  _ChartData(this.label, this.value, this.color);
}
