import 'package:flutter/material.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/services/geo_service.dart';

class WeatherModalWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeatherModalWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherModalWidget> createState() => _WeatherModalWidgetState();
}

class _WeatherModalWidgetState extends State<WeatherModalWidget> {
  Map<String, String> weatherData = {
    'temperature': 'Loading...',
    'description': 'Loading...',
    'humidity': 'Loading...',
    'pressure': 'Loading...',
    'wind_speed': 'Loading...',
  };
  String locationAddress = 'Loading location...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load weather and location data in parallel
      final results = await Future.wait([
        GeoService.getWeatherData(widget.latitude, widget.longitude),
        GeoService.getReverseGeoCode(widget.latitude, widget.longitude),
      ]);

      setState(() {
        weatherData = results[0] as Map<String, String>;
        locationAddress = results[1] as String;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        weatherData = {
          'temperature': 'Error',
          'description': 'Failed to load weather data',
          'humidity': 'Error',
          'pressure': 'Error',
          'wind_speed': 'Error',
        };
        locationAddress = 'Location unavailable';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Increased height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.cloud, color: AppTheme.primaryColor, size: 30),
                SizedBox(width: 12),
                Text(
                  'Weather Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.titleColor),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Loading weather data...',
                          style: TextStyle(
                            color: AppTheme.subTitleColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Location Address
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locationAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.titleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Temperature and Description
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.1),
                                AppTheme.accentColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                weatherData['temperature'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                weatherData['description'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.subTitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Weather details
                        Row(
                          children: [
                            Expanded(
                              child: _buildWeatherCard(
                                'Humidity',
                                weatherData['humidity'] ?? 'N/A',
                                Icons.water_drop,
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildWeatherCard(
                                'Pressure',
                                weatherData['pressure'] ?? 'N/A',
                                Icons.speed,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildWeatherCard(
                                'Wind Speed',
                                weatherData['wind_speed'] ?? 'N/A',
                                Icons.air,
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildWeatherCard(
                                'Coordinates',
                                '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                                Icons.gps_fixed,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Refresh button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                              });
                              _loadData();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20), // Extra padding at bottom
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.subTitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.titleColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
