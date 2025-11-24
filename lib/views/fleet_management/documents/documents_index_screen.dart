import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_document_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_document_api_service.dart';
import 'package:intl/intl.dart';
import 'package:luna_iot/utils/constants.dart';

class DocumentsIndexScreen extends StatelessWidget {
  const DocumentsIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'documents'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
        ],
      ),
      body: Obx(() {
        if (controller.documentsLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        final documentsByVehicle = controller.documentsByVehicle;
        if (documentsByVehicle.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: AppTheme.subTitleColor),
                SizedBox(height: 16),
                Text(
                  'no_documents_records'.tr,
                  style: TextStyle(color: AppTheme.subTitleColor, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadDocuments(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: documentsByVehicle.length,
            itemBuilder: (context, index) {
              final vehicleId = documentsByVehicle.keys.elementAt(index);
              final documents = documentsByVehicle[vehicleId]!;
              final vehicleName = controller.vehicleNames[vehicleId] ?? 'Unknown Vehicle';
              return _buildVehicleGroup(controller, vehicleId, vehicleName, documents);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.fleetManagementDocumentsCreate),
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVehicleGroup(
    FleetManagementController controller,
    int vehicleId,
    String vehicleName,
    List<VehicleDocument> documents,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: EdgeInsets.only(bottom: 12, top: 4),
          backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
          collapsedBackgroundColor: Colors.white,
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: AppTheme.primaryColor,
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.titleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${documents.length} ${documents.length == 1 ? 'record' : 'records'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subTitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${documents.length}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.subTitleColor.withOpacity(0.1),
              indent: 20,
              endIndent: 20,
            ),
            ...documents.map((document) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _buildDocumentCard(controller, vehicleId, document),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(FleetManagementController controller, int vehicleId, VehicleDocument document) {
    final needsRenewal = controller.documentNeedsRenewal[document.id] ?? false;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: needsRenewal 
            ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: needsRenewal 
                ? Colors.orange.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.fleetManagementDocumentsEdit,
            arguments: document,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: needsRenewal 
                            ? Colors.orange.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: needsRenewal ? Colors.orange : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  document.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.titleColor,
                                  ),
                                ),
                              ),
                              if (needsRenewal)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, size: 12, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        'renew'.tr.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.subTitleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: AppTheme.subTitleColor),
                                    SizedBox(width: 3),
                                    Text(
                                      DateFormat('MMM dd').format(document.lastExpireDate),
                                      style: TextStyle(
                                        color: AppTheme.subTitleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, size: 12, color: AppTheme.primaryColor),
                                    SizedBox(width: 3),
                                    Text(
                                      '${document.expireInMonth} ${'months'.tr}',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (needsRenewal)
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: IconButton(
                                  onPressed: () => _showRenewDocumentModal(controller, vehicleId, document),
                                  icon: Icon(Icons.refresh, size: 16),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all(2),
                                  constraints: BoxConstraints(),
                                  iconSize: 16,
                                ),
                              ),
                            IconButton(
                              onPressed: () => Get.toNamed(
                                AppRoutes.fleetManagementDocumentsEdit,
                                arguments: document,
                              ),
                              icon: Icon(Icons.edit_outlined, size: 18),
                              color: AppTheme.primaryColor,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 18,
                            ),
                            SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _deleteDocument(controller, vehicleId, document),
                              icon: Icon(Icons.delete_outline, size: 18),
                              color: Colors.red,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (document.remarks != null && document.remarks!.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 14, color: AppTheme.subTitleColor),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            document.remarks!,
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (document.documentImageOne != null || document.documentImageTwo != null) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      if (document.documentImageOne != null)
                        Expanded(
                          child: _buildImageThumbnail('${Constants.baseUrl}${document.documentImageOne}'),
                        ),
                      if (document.documentImageOne != null && document.documentImageTwo != null)
                        SizedBox(width: 8),
                      if (document.documentImageTwo != null)
                        Expanded(
                          child: _buildImageThumbnail('${Constants.baseUrl}${document.documentImageTwo}'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenewDocumentModal(FleetManagementController controller, int vehicleId, VehicleDocument document) {
    Get.dialog(
      AlertDialog(
        title: Text('renew_document'.tr),
        content: Text('confirm_renew_document'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final documentApiService = Get.find<VehicleDocumentApiService>();
                final imei = controller.vehicleImeis[vehicleId] ?? '';
                if (imei.isEmpty) {
                  final vehicle = controller.vehicles.firstWhere((v) => v.id == vehicleId);
                  await documentApiService.renewVehicleDocument(vehicle.imei, document.id!);
                } else {
                  await documentApiService.renewVehicleDocument(imei, document.id!);
                }
                Get.back();
                await controller.loadDocuments();
                Get.snackbar('success'.tr, 'document_renewed'.tr);
              } catch (e) {
                Get.snackbar('error'.tr, e.toString());
              }
            },
            child: Text('renew'.tr),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(FleetManagementController controller, int vehicleId, VehicleDocument document) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_document'.tr),
        content: Text('confirm_delete_document'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.deleteDocument(vehicleId, document.id!);
                Get.back();
                Get.snackbar('success'.tr, 'document_deleted'.tr);
              } catch (e) {
                Get.snackbar('error'.tr, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String imageUrl) {
    return GestureDetector(
      onTap: () {
        Get.dialog(
          Dialog(
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(Get.context!).size.height * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text('document_image'.tr),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: AppTheme.subTitleColor),
                                SizedBox(height: 8),
                                Text(
                                  'failed_to_load_image'.tr,
                                  style: TextStyle(color: AppTheme.subTitleColor),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.subTitleColor.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.backgroundColor,
                child: Icon(Icons.broken_image, color: AppTheme.subTitleColor, size: 24),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppTheme.backgroundColor,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
