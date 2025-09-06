import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/geofence_controller.dart';
import 'package:luna_iot/models/geofence_model.dart';

class GeofenceEditScreen extends GetView<GeofenceController> {
  final GeofenceModel geofence;

  const GeofenceEditScreen({super.key, required this.geofence});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Geofence',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Geofence Edit Screen - Coming Soon\nEditing: ${geofence.title}',
                  style: TextStyle(color: AppTheme.subTitleColor, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
