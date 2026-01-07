import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/services/mock_analysis_service.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// Demo Analysis Dialog
/// Shows mocked data and analysis functionality
class AnalysisDemoDialog extends StatefulWidget {
  const AnalysisDemoDialog({super.key});

  @override
  State<AnalysisDemoDialog> createState() => _AnalysisDemoDialogState();
}

class _AnalysisDemoDialogState extends State<AnalysisDemoDialog>
    with TickerProviderStateMixin {
  late List<GlucoseReading> _mockReadings;
  late Map<String, dynamic> _stats;
  late String _trend;
  late String _pattern;
  late String _hba1c;
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalysisData();
  }

  void _loadAnalysisData() {
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _mockReadings = MockAnalysisService.generateMockReadings(hours: 24);
        _stats = MockAnalysisService.calculateStatistics(_mockReadings);
        _trend = MockAnalysisService.analyzeTrend(_mockReadings);
        _pattern = MockAnalysisService.analyzeDailyPattern(_mockReadings);
        _hba1c = MockAnalysisService.estimateHbA1c(
          double.parse(_stats['average']),
        );
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing glucose data...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Analysis Demo',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Statistics'),
                      Tab(text: 'Insights'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildStatisticsTab(),
                        _buildInsightsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current stats cards
          _buildStatCard(
            title: 'Average',
            value: '${_stats['average']} mg/dL',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'Range',
            value: '${_stats['min']} - ${_stats['max']} mg/dL',
            icon: Icons.show_chart,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'Readings Today',
            value: '${_stats['readingCount']}',
            icon: Icons.assessment,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          Text(
            'Trend Analysis',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _trend,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailStatRow('Average', '${_stats['average']} mg/dL'),
          _buildDetailStatRow('Minimum', '${_stats['min']} mg/dL'),
          _buildDetailStatRow('Maximum', '${_stats['max']} mg/dL'),
          _buildDetailStatRow('Std Deviation', '${_stats['stdev']} mg/dL'),
          const SizedBox(height: 20),
          Text(
            'Time in Range',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: 'In Range (80-180)',
            value: double.parse(_stats['timeInRange']),
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(
            label: 'High (>180)',
            value: double.parse(_stats['timeHigh']),
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(
            label: 'Low (<80)',
            value: double.parse(_stats['timeLow']),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HbA1c estimate
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated HbA1c',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_hba1c}%',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on average glucose of ${_stats['average']} mg/dL',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily pattern
          Text(
            'Daily Pattern',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _pattern,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Recommendations
          Text(
            'Recommendations',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRecommendation(
            icon: Icons.water_drop,
            title: 'Hydration',
            description: 'Stay well hydrated throughout the day',
          ),
          const SizedBox(height: 8),
          _buildRecommendation(
            icon: Icons.run_circle,
            title: 'Physical Activity',
            description: 'Regular exercise helps glucose management',
          ),
          const SizedBox(height: 8),
          _buildRecommendation(
            icon: Icons.restaurant,
            title: 'Nutrition',
            description: 'Monitor carbohydrate intake and timing',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text('${value.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
