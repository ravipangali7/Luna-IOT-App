import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/alert_history_controller.dart';
import 'package:luna_iot/models/alert_history_model.dart';
import 'package:luna_iot/models/alert_type_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load alert history when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<AlertHistoryController>();
      controller.loadAlertHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AlertHistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Alert History'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return LoadingWidget();
        }

        if (controller.alertHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No alerts found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadAlertHistory();
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.alertHistory.length,
            itemBuilder: (context, index) {
              final alert = controller.alertHistory[index];
              return _buildAlertCard(alert);
            },
          ),
        );
      }),
    );
  }

  Widget _buildAlertCard(AlertHistory alert) {
    // Get alert type info for icon
    final alertType = _getAlertTypeForId(alert.alertType);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildAlertIcon(alertType),
        title: Text(
          alert.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Phone: ${alert.primaryPhone}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Location: ${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Status: ${alert.status.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(alert.status),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDate(alert.datetime),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // TODO: Navigate to alert details screen
        },
      ),
    );
  }

  Widget _buildAlertIcon(AlertType? alertType) {
    final controller = Get.find<AlertHistoryController>();
    final iconPath = controller.getAlertIconPath(alertType?.id ?? 0);

    if (iconPath.isEmpty) {
      return Icon(Icons.emergency, size: 40, color: Colors.red);
    }

    return Image.asset(
      iconPath,
      width: 40,
      height: 40,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.emergency, size: 40, color: Colors.red);
      },
    );
  }

  AlertType? _getAlertTypeForId(int alertTypeId) {
    final controller = Get.find<AlertHistoryController>();
    return controller.getAlertTypeById(alertTypeId);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
