import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/controllers/luna_tag_controller.dart';
import 'package:luna_iot/models/luna_tag_model.dart';
import 'package:luna_iot/widgets/pagination_widget.dart';
import 'package:luna_iot/utils/constants.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:luna_iot/widgets/simple_marquee_widget.dart';

class LunaTagIndexScreen extends StatelessWidget {
  const LunaTagIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LunaTagController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Luna Tags',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        if (controller.userTags.isEmpty) {
          return const Center(child: Text('No Luna Tags found'));
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: controller.userTags.length,
                itemBuilder: (context, index) {
                  return _UserLunaTagCard(tag: controller.userTags[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: CompactPaginationWidget(
                currentPage: controller.pagination.value.currentPage,
                totalPages: controller.pagination.value.totalPages,
                totalCount: controller.pagination.value.count,
                pageSize: controller.pagination.value.pageSize,
                hasNextPage: controller.pagination.value.hasNext,
                hasPreviousPage: controller.pagination.value.hasPrevious,
                isLoading: controller.loading.value,
                onPrevious: () => controller
                    .goToPage(controller.pagination.value.currentPage - 1),
                onNext: () => controller
                    .goToPage(controller.pagination.value.currentPage + 1),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _UserLunaTagCard extends StatelessWidget {
  final UserLunaTag tag;
  const _UserLunaTagCard({required this.tag});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LunaTagController>();
    final isActive = tag.isActive;
    return Obx(() {
      final latest = controller.latestDataByKey[tag.publicKey];
      final battery = latest?.battery;
      final lostMode = tag.isLostMode;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: isActive ? () => _openBottomSheet(tag) : null,
          child: Column(
            children: [
              // Header badges with rounded top
              Row(
                children: [
                  // INACTIVE Badge
                  if (!isActive)
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'INACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),

                  // LOST MODE Badge - Only show for active tags
                  if (isActive)
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: lostMode ? Colors.orange.shade600 : Colors.blueGrey.shade600,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        lostMode ? 'LOST MODE: ON' : 'LOST MODE: OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),

              // Main Part
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: -10,
                      blurRadius: 30,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image
                    _LunaTagImage(
                      imageUrl: tag.image,
                      disabled: !isActive,
                    ),
                    
                    SizedBox(width: 10),
                    
                    // Name and Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tag Name
                          Text(
                            tag.name ?? 'Untitled',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? AppTheme.titleColor : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(height: 2),
                          
                          // Expire Date and Battery in same row
                          Row(
                            children: [
                              // Expire Date
                              if (tag.expireDate != null)
                                Expanded(
                                  child: Text(
                                    'Exp: ${_formatDate(tag.expireDate!)}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isActive ? AppTheme.subTitleColor : Colors.grey,
                                    ),
                                  ),
                                ),
                              
                              // Battery
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.battery_5_bar,
                                    size: 14,
                                    color: isActive ? AppTheme.titleColor : Colors.grey,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    battery == null ? '--%' : '${battery.round()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isActive ? AppTheme.titleColor : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 4),
                          
                          // Reverse Geocode
                          _LunaTagGeocodeWidget(
                            latitude: latest?.latitude,
                            longitude: latest?.longitude,
                            disabled: !isActive,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openBottomSheet(UserLunaTag tag) {
    Get.bottomSheet(
      _LunaTagCardBottomSheet(tag: tag),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

class _LunaTagImage extends StatelessWidget {
  final String? imageUrl;
  final bool disabled;
  const _LunaTagImage({required this.imageUrl, required this.disabled});

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // If URL already starts with http:// or https://, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Otherwise, prepend base URL
    return '${Constants.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade300 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.sell,
        color: disabled ? Colors.grey : Colors.blueGrey,
        size: 25,
      ),
    );
    
    final fullUrl = _getFullImageUrl(imageUrl);
    if (fullUrl.isEmpty) return placeholder;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: disabled ? Colors.grey.shade400 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => placeholder,
          color: disabled ? Colors.grey : null,
          colorBlendMode: disabled ? BlendMode.saturation : BlendMode.src,
        ),
      ),
    );
  }
}

// Geocode Widget for LunaTag Card
class _LunaTagGeocodeWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool disabled;

  const _LunaTagGeocodeWidget({
    required this.latitude,
    required this.longitude,
    required this.disabled,
  });

  @override
  State<_LunaTagGeocodeWidget> createState() => _LunaTagGeocodeWidgetState();
}

class _LunaTagGeocodeWidgetState extends State<_LunaTagGeocodeWidget> {
  String? _cachedAddress;
  String? _lastCoordinates;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasValidLocation = widget.latitude != null && widget.longitude != null;

    if (!hasValidLocation) {
      return Row(
        children: [
          Icon(
            Icons.location_off,
            size: 14,
            color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'No location data',
              style: TextStyle(
                color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final currentCoords = '${widget.latitude}_${widget.longitude}';

    // Only fetch if coordinates changed or no cache exists
    if (_lastCoordinates != currentCoords || (_cachedAddress == null && !_isLoading)) {
      _lastCoordinates = currentCoords;
      _isLoading = true;

      // Fetch geocode asynchronously
      GeoService.getReverseGeoCode(widget.latitude!, widget.longitude!)
          .then((address) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                _cachedAddress = address;
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                if (_cachedAddress == null) {
                  _cachedAddress = 'Location unavailable';
                }
                _isLoading = false;
              });
            }
          });
    }

    // Show loading indicator ONLY if no cached data
    if (_isLoading && _cachedAddress == null) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.disabled ? Colors.grey : AppTheme.subTitleColor,
              ),
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Loading...',
            style: TextStyle(
              color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    if (_cachedAddress == null) {
      return Row(
        children: [
          Icon(
            Icons.location_off,
            size: 14,
            color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Location unavailable',
              style: TextStyle(
                color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: widget.disabled ? Colors.grey : Colors.green.shade700,
        ),
        SizedBox(width: 4),
        Expanded(
          child: SimpleMarqueeText(
            text: _cachedAddress!,
            style: TextStyle(
              color: widget.disabled ? Colors.grey : AppTheme.subTitleColor,
              fontSize: 10,
            ),
            scrollAxisExtent: 200.0,
            scrollDuration: Duration(seconds: 10),
          ),
        ),
      ],
    );
  }
}

class _LunaTagCardBottomSheet extends StatelessWidget {
  final UserLunaTag tag;
  const _LunaTagCardBottomSheet({required this.tag});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text('Track'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.lunaTagShow.replaceFirst(':publicKey', tag.publicKey),
                    arguments: {
                      'action': 'track',
                      'image': tag.image,
                      'name': tag.name,
                    });
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Colors.blueGrey),
              title: const Text('Playback'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.lunaTagShow.replaceFirst(':publicKey', tag.publicKey), arguments: {
                  'action': 'playback',
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.lunaTagEdit.replaceFirst(':id', '${tag.id}'));
              },
            ),
          ],
        ),
      ),
    );
  }
}