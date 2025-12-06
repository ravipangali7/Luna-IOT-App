import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/vehicle_tag_api_service.dart';
import 'package:luna_iot/models/vehicle_tag_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class VehicleTagDetailScreen extends StatefulWidget {
  const VehicleTagDetailScreen({Key? key}) : super(key: key);

  @override
  State<VehicleTagDetailScreen> createState() => _VehicleTagDetailScreenState();
}

class _VehicleTagDetailScreenState extends State<VehicleTagDetailScreen> {
  VehicleTag? _tag;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicleTag();
  }

  Future<void> _loadVehicleTag() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final vtid = args?['vtid'] as String?;

    if (vtid == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid vehicle tag ID';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Get API service directly to avoid updating controller observables
      final apiClient = Get.find<ApiClient>();
      final apiService = VehicleTagApiService(apiClient);
      final tag = await apiService.getVehicleTagByVtid(vtid);

      setState(() {
        _tag = tag;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load vehicle tag: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Vehicle Tag Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.titleColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingWidget();
    }

    if (_error != null || _tag == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Vehicle tag not found',
              style: TextStyle(
                color: AppTheme.subTitleColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final tag = _tag!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (tag.isActive ?? true)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: (tag.isActive ?? true) ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${(tag.isActive ?? true) ? "Active" : "Inactive"}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Visits',
                        value: '${tag.visitCount ?? 0}',
                        icon: Icons.visibility,
                        color: Colors.blue,
                      ),
                      _StatItem(
                        label: 'Alerts',
                        value: '${tag.alertCount ?? 0}',
                        icon: Icons.notifications,
                        color: Colors.orange,
                      ),
                      _StatItem(
                        label: 'SMS Alerts',
                        value: '${tag.smsAlertCount ?? 0}',
                        icon: Icons.sms,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'VTID',
                    value: tag.vtid,
                  ),
                  if (tag.registrationNo != null && tag.registrationNo!.isNotEmpty)
                    _DetailRow(
                      label: 'Registration No',
                      value: tag.registrationNo!,
                    ),
                  if (tag.vehicleModel != null && tag.vehicleModel!.isNotEmpty)
                    _DetailRow(
                      label: 'Vehicle Model',
                      value: tag.vehicleModel!,
                    ),
                  if (tag.registerType != null && tag.registerType!.isNotEmpty)
                    _DetailRow(
                      label: 'Register Type',
                      value: tag.registerType!,
                    ),
                  if (tag.vehicleCategory != null && tag.vehicleCategory!.isNotEmpty)
                    _DetailRow(
                      label: 'Vehicle Category',
                      value: tag.vehicleCategory!,
                    ),
                  if (tag.sosNumber != null && tag.sosNumber!.isNotEmpty)
                    _DetailRow(
                      label: 'SOS Number',
                      value: tag.sosNumber!,
                    ),
                  if (tag.smsNumber != null && tag.smsNumber!.isNotEmpty)
                    _DetailRow(
                      label: 'SMS Number',
                      value: tag.smsNumber!,
                    ),
                  _DetailRow(
                    label: 'Downloaded',
                    value: (tag.isDownloaded ?? false) ? 'Yes' : 'No',
                  ),
                  if (tag.userInfo != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tag.userInfo!['name'] != null)
                      _DetailRow(
                        label: 'Name',
                        value: tag.userInfo!['name'],
                      ),
                    if (tag.userInfo!['phone'] != null)
                      _DetailRow(
                        label: 'Phone',
                        value: tag.userInfo!['phone'],
                      ),
                  ] else
                    _DetailRow(
                      label: 'User',
                      value: 'Unassigned',
                    ),
                  if (tag.createdAt != null)
                    _DetailRow(
                      label: 'Created At',
                      value: tag.createdAt!.toString().split('.')[0],
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.subTitleColor,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.subTitleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

