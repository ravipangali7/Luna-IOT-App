import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/geofence_controller.dart';
import 'package:luna_iot/models/geofence_model.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';

class GeofenceIndexScreen extends GetView<GeofenceController> {
  const GeofenceIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'Geofences',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),

      // Add Button in Floating Action
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.geofenceCreate);
        },
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Add Geofence',
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // Main Body Start
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }

        if (controller.geofences.isEmpty) {
          return Center(
            child: Text(
              'No geofences found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return ListView(
          children: [
            for (var geofence in controller.geofences)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.secondaryColor,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getGeofenceTypeColor(
                        geofence.type,
                      ).withOpacity(0.1),
                      child: Icon(
                        _getGeofenceTypeIcon(geofence.type),
                        color: _getGeofenceTypeColor(geofence.type),
                      ),
                    ),
                    title: Text(
                      geofence.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Geofence Type
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 12,
                                color: AppTheme.subTitleColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                geofence.type.toString().split('.').last,
                                style: TextStyle(
                                  color: AppTheme.subTitleColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Boundary Points
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.subTitleColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${geofence.boundary.length} boundary points',
                                style: TextStyle(
                                  color: AppTheme.subTitleColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Assigned Vehicles
                        if (geofence.vehicles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${geofence.vehicles.length} vehicles',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Assigned Users
                        if (geofence.users.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${geofence.users.length} users',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Created Date
                        if (geofence.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Created: ${_formatDate(geofence.createdAt!)}',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: AppTheme.primaryColor.withOpacity(0.12),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: IconButton(
                        //     tooltip: 'Edit Geofence',
                        //     onPressed: () {
                        //       Get.toNamed(
                        //         AppRoutes.geofenceEdit.replaceAll(
                        //           ':id',
                        //           geofence.id.toString(),
                        //         ),
                        //         arguments: geofence,
                        //       );
                        //     },
                        //     icon: Icon(
                        //       Icons.edit,
                        //       color: AppTheme.primaryColor,
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            tooltip: 'Delete Geofence',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmDialouge(
                                  title: 'Confirm Delete Geofence',
                                  message:
                                      'Are you sure you want to delete "${geofence.title}"? This action cannot be undone.',
                                  onConfirm: () {
                                    controller.deleteGeofence(geofence.id!);
                                  },
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Color _getGeofenceTypeColor(GeofenceType type) {
    switch (type) {
      case GeofenceType.Entry:
        return Colors.green;
      case GeofenceType.Exit:
        return Colors.red;
    }
  }

  IconData _getGeofenceTypeIcon(GeofenceType type) {
    switch (type) {
      case GeofenceType.Entry:
        return Icons.login;
      case GeofenceType.Exit:
        return Icons.logout;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
