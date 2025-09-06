import 'package:flutter/material.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/trip_model.dart';
import 'package:luna_iot/services/trip_service.dart';
import 'package:luna_iot/services/geo_service.dart';

class TripDrawer extends StatelessWidget {
  final List<Trip> trips;
  final Function(Trip)? onTripSelected;

  const TripDrawer({super.key, required this.trips, this.onTripSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trip Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${trips.length} trips found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trips List
          Expanded(
            child: trips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No trips found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Select a date range to view trips',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _buildTripCard(trip, context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip, BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onTripSelected?.call(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Point
              _buildLocationPoint(
                context,
                'Start',
                trip.startTime,
                trip.startLatitude,
                trip.startLongitude,
                Colors.green,
              ),

              SizedBox(height: 12),

              // End Point
              _buildLocationPoint(
                context,
                'End',
                trip.endTime,
                trip.endLatitude,
                trip.endLongitude,
                Colors.red,
              ),

              SizedBox(height: 16),

              // Trip Stats
              _buildTripStats(trip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPoint(
    BuildContext context,
    String label,
    DateTime time,
    double latitude,
    double longitude,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppTheme.subTitleColor),
              SizedBox(width: 4),
              Text(
                _formatDateTime(time),
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          FutureBuilder<String>(
            future: GeoService.getReverseGeoCode(latitude, longitude),
            builder: (context, snapshot) {
              return Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.subTitleColor,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      snapshot.data ?? 'Loading location...',
                      style: TextStyle(
                        color: AppTheme.subTitleColor,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripStats(Trip trip) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.straighten,
                  value: TripService.formatDistance(trip.distance),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  value: TripService.formatDuration(trip.duration),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed,
                  value: TripService.formatSpeed(trip.averageSpeed),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed_outlined,
                  value: TripService.formatSpeed(trip.maxSpeed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
