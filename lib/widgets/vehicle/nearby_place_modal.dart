// Nearby Places Modal Widget
import 'package:flutter/material.dart';
import 'package:luna_iot/services/geo_service.dart';

class NearbyPlacesModal extends StatelessWidget {
  const NearbyPlacesModal({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Nearby Places',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 20),

          // Places Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
            children: [
              _buildPlaceCard(
                context,
                Icons.hotel,
                'Hotels',
                Colors.blue.shade700,
                'hotels',
              ),
              _buildPlaceCard(
                context,
                Icons.local_gas_station,
                'Fuel Stations',
                Colors.orange.shade700,
                'fuel+stations',
              ),
              _buildPlaceCard(
                context,
                Icons.ev_station,
                'EV Charging',
                Colors.green.shade700,
                'ev+charging+stations',
              ),
              _buildPlaceCard(
                context,
                Icons.account_balance,
                'Bank ATM',
                Colors.purple.shade700,
                'bank+atm',
              ),
              _buildPlaceCard(
                context,
                Icons.local_police,
                'Police Station',
                Colors.red.shade700,
                'police+station',
              ),
              _buildPlaceCard(
                context,
                Icons.local_hospital,
                'Hospitals',
                Colors.teal.shade700,
                'hospitals',
              ),
            ],
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String placeType,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        GeoService.openNearbyPlace(latitude, longitude, placeType);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
