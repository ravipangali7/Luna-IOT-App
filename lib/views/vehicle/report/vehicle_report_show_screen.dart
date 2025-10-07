import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/report_api_service.dart';
import 'package:luna_iot/models/report_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class VehicleReportShowScreen extends StatefulWidget {
  const VehicleReportShowScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  State<VehicleReportShowScreen> createState() =>
      _VehicleReportShowScreenState();
}

class _VehicleReportShowScreenState extends State<VehicleReportShowScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  ReportData? reportData;

  final ReportApiService _reportApiService = ReportApiService(ApiClient());

  @override
  void initState() {
    super.initState();
    _initializeDefaultDates();
  }

  void _initializeDefaultDates() {
    final today = DateTime.now();
    setState(() {
      startDate = DateTime(today.year, today.month, today.day - 1); // Yesterday
      endDate = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ); // Today end of day
    });

    // Automatically fetch report data for yesterday to today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateReport();
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime today = DateTime.now();
    final DateTime threeMonthsAgo = DateTime(
      today.year,
      today.month - 3,
      today.day,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? today.subtract(Duration(days: 1)),
      firstDate: threeMonthsAgo,
      lastDate: today,
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
        // Reset end date if it's before start date
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
        // If end date is same as start date, set it to end of day
        else if (endDate != null &&
            endDate!.year == startDate!.year &&
            endDate!.month == startDate!.month &&
            endDate!.day == startDate!.day) {
          endDate = DateTime(
            startDate!.year,
            startDate!.month,
            startDate!.day,
            23,
            59,
            59,
          );
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime today = DateTime.now();
    DateTime lastDate;

    // Logic for end date selection based on start date
    if (startDate!.isAtSameMomentAs(
      DateTime(today.year, today.month, today.day),
    )) {
      // If start date is today, end date can only be today
      lastDate = today;
    } else {
      // If start date is before today, end date can be up to 3 months after start date
      lastDate = startDate!.add(Duration(days: 90));
      // But not beyond today
      if (lastDate.isAfter(today)) {
        lastDate = today;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate!.add(Duration(days: 1)),
      firstDate: startDate!,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        // If end date is same as start date, set it to end of day
        if (picked.isAtSameMomentAs(
          DateTime(picked.year, picked.month, picked.day),
        )) {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final data = await _reportApiService.generateReport(
        widget.vehicle.imei,
        startDate!,
        endDate!,
      );

      // Validate and fix distance calculation if needed
      final validatedData = _validateAndFixReportData(data);

      setState(() {
        reportData = validatedData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Validate and fix report data if distance calculation is incorrect
  ReportData _validateAndFixReportData(ReportData data) {
    // Check if total distance seems incorrect (0km but has daily data)
    if (data.stats.totalKm == 0.0 && data.dailyData.isNotEmpty) {
      // Recalculate total distance from daily data
      double correctedTotalKm = 0.0;
      for (final daily in data.dailyData) {
        correctedTotalKm += daily.totalKm;
      }

      // Create corrected stats
      final correctedStats = ReportStats(
        totalKm: correctedTotalKm,
        totalTime: data.stats.totalTime,
        averageSpeed: correctedTotalKm > 0
            ? (correctedTotalKm / (data.stats.totalTime / 60))
            : 0.0,
        maxSpeed: data.stats.maxSpeed,
        totalIdleTime: data.stats.totalIdleTime,
        totalRunningTime: data.stats.totalRunningTime,
        totalOverspeedTime: data.stats.totalOverspeedTime,
        totalStopTime: data.stats.totalStopTime,
      );

      return ReportData(stats: correctedStats, dailyData: data.dailyData);
    }

    return data; // Return original data if no correction needed
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report: ${widget.vehicle.vehicleNo}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Vehicle Card
              VehicleCard(givenVehicle: widget.vehicle),

              SizedBox(height: 16),

              // Date Selector
              _buildDateSelector(),

              SizedBox(height: 16),

              // Loading or Report Content
              if (isLoading)
                _buildLoadingWidget()
              else if (reportData != null)
                _buildReportContent()
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Start Date
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            startDate != null
                                ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                : 'Start',
                            style: TextStyle(
                              color: startDate != null
                                  ? AppTheme.titleColor
                                  : AppTheme.subTitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // End Date
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: startDate == null
                            ? AppTheme.secondaryColor.withOpacity(0.5)
                            : AppTheme.secondaryColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: startDate == null
                              ? AppTheme.subTitleColor
                              : AppTheme.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            endDate != null
                                ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                : 'End',
                            style: TextStyle(
                              color: endDate != null
                                  ? AppTheme.titleColor
                                  : AppTheme.subTitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Generate Button
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed:
                      (startDate != null && endDate != null && !isLoading)
                      ? _generateReport
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.analytics, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Generating Report...',
              style: TextStyle(color: AppTheme.subTitleColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.subTitleColor,
            ),
            SizedBox(height: 16),
            Text(
              'Select date range and generate report',
              style: TextStyle(color: AppTheme.subTitleColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (reportData == null) return SizedBox.shrink();

    return Column(
      children: [
        // Stats Cards
        _buildStatsCards(),

        SizedBox(height: 16),

        // Speed Chart
        _buildSpeedChart(),

        SizedBox(height: 16),

        // Distance Chart
        _buildDistanceChart(),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = reportData!.stats;

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Distance',
          '${stats.totalKm.toStringAsFixed(1)} km',
          Icons.route,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Time',
          _formatDuration(stats.totalTime),
          Icons.timer,
          Colors.green,
        ),
        _buildStatCard(
          'Avg Speed',
          '${stats.averageSpeed.toStringAsFixed(1)} km/h',
          Icons.speed,
          Colors.orange,
        ),
        _buildStatCard(
          'Max Speed',
          '${stats.maxSpeed.toStringAsFixed(0)} km/h',
          Icons.trending_up,
          Colors.red,
        ),
        _buildStatCard(
          'Idle Time',
          _formatDuration(stats.totalIdleTime),
          Icons.pause,
          Colors.grey,
        ),
        _buildStatCard(
          'Running Time',
          _formatDuration(stats.totalRunningTime),
          Icons.play_arrow,
          Colors.green,
        ),
        _buildStatCard(
          'Overspeed Time',
          _formatDuration(stats.totalOverspeedTime),
          Icons.warning,
          Colors.red,
        ),
        _buildStatCard(
          'Stop Time',
          _formatDuration(stats.totalStopTime),
          Icons.stop,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChart() {
    if (reportData!.dailyData.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Speed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < reportData!.dailyData.length) {
                          final date =
                              reportData!.dailyData[value.toInt()].date;
                          return Text(
                            '${date.split('-')[2]}', // Show only day
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: reportData!.dailyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.averageSpeed,
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: reportData!.dailyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.maxSpeed);
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 4),
              Text('Average Speed', style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 4),
              Text('Max Speed', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChart() {
    if (reportData!.dailyData.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Distance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < reportData!.dailyData.length) {
                          final date =
                              reportData!.dailyData[value.toInt()].date;
                          return Text(
                            '${date.split('-')[2]}', // Show only day
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: reportData!.dailyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.totalKm);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
