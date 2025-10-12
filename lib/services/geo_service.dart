import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/vehicle/nearby_place_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class GeoService {
  static final Map<String, String> _addressCache = {};
  static final Map<String, String> _altitudeCache = {};
  static final Map<String, Future<String>> _pendingRequests = {};

  // Get Reverse geo code
  static Future<String> getReverseGeoCode(
    double latitude,
    double longitude,
  ) async {
    // Round coordinates to 4 decimal places (about 11 meters precision) for better caching
    final roundedLat = double.parse(latitude.toStringAsFixed(4));
    final roundedLon = double.parse(longitude.toStringAsFixed(4));
    final cacheKey = '${roundedLat}_${roundedLon}';

    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    // Check if there's already a pending request for these coordinates
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!;
    }

    // Create new request
    final future = _fetchReverseGeoCode(latitude, longitude, cacheKey);
    _pendingRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  static Future<String> _fetchReverseGeoCode(
    double latitude,
    double longitude,
    String cacheKey,
  ) async {
    try {
      final dio = Dio();
      dynamic response = await dio.get(
        kIsWeb
            ? 'https://www.geo.mylunago.com/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
            : 'http://5.189.159.178:3838/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
        options: Options(
          headers: {'User-Agent': 'Luna IoT Reverse Geo Code'},
          receiveTimeout: Duration(seconds: 10),
          sendTimeout: Duration(seconds: 10),
        ),
      );

      response = json.decode(response.toString());

      // Extract all available address components
      final addressData = response['address'] ?? {};
      final List<String> addressParts = [];

      // Add all possible address components if they exist
      final addressFields = [
        'house_number',
        'road',
        'neighbourhood',
        'suburb',
        'city_district',
        'city',
        'town',
        'village',
        'hamlet',
        'county',
        'state',
        'state_district',
        'postcode',
        'country',
      ];

      // Build address string with all available components
      for (String field in addressFields) {
        if (addressData[field] != null &&
            addressData[field].toString().isNotEmpty) {
          addressParts.add(addressData[field].toString());
        }
      }

      // Join all parts with comma and space, remove empty parts
      final address = addressParts
          .where((part) => part.trim().isNotEmpty)
          .join(', ');

      _addressCache[cacheKey] = address;
      return address;
    } catch (e) {
      // If rate limited or any error, return default value and cache it
      print('Reverse geocoding API error: $e');
      _addressCache[cacheKey] = 'Location unavailable';
      return 'Location unavailable';
    }
  }

  // Get Altitude
  static Future<String> getAltitude(double latitude, double longitude) async {
    // Round coordinates to 4 decimal places (about 11 meters precision) for better caching
    final roundedLat = double.parse(latitude.toStringAsFixed(4));
    final roundedLon = double.parse(longitude.toStringAsFixed(4));
    final cacheKey = 'altitude_${roundedLat}_${roundedLon}';

    // Check cache first
    if (_altitudeCache.containsKey(cacheKey)) {
      return _altitudeCache[cacheKey]!;
    }

    // Check if there's already a pending request for these coordinates
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!;
    }

    // Create new request
    final future = _fetchAltitude(latitude, longitude, cacheKey);
    _pendingRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  static Future<String> _fetchAltitude(
    double latitude,
    double longitude,
    String cacheKey,
  ) async {
    try {
      final dio = Dio();
      dynamic response = await dio.get(
        'https://api.open-elevation.com/api/v1/lookup?locations=$latitude,$longitude',
        options: Options(
          headers: {'User-Agent': 'Luna IoT Altitude'},
          receiveTimeout: Duration(seconds: 10),
          sendTimeout: Duration(seconds: 10),
        ),
      );

      response = json.decode(response.toString());
      final altitude = '${response['results'][0]['elevation']}';
      _altitudeCache[cacheKey] = altitude;
      return altitude;
    } catch (e) {
      // If rate limited or any error, return default value and cache it
      print('Altitude API error: $e');
      _altitudeCache[cacheKey] = '0';
      return '0';
    }
  }

  // Get Weather Data
  static Future<Map<String, String>> getWeatherData(
    double latitude,
    double longitude,
  ) async {
    // Default weather data
    Map<String, String> defaultWeather = {
      'temperature': 'N/A',
      'description': 'Weather data unavailable',
      'humidity': 'N/A',
      'pressure': 'N/A',
      'wind_speed': 'N/A',
    };

    try {
      // Using Open-Meteo API (free, no API key required)
      final response = await Dio().get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current_weather': 'true',
          'hourly':
              'temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m',
          'timezone': 'auto',
        },
        options: Options(
          headers: {'User-Agent': 'Luna IoT Weather'},
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return {
          'temperature':
              '${(data['current_weather']['temperature'] ?? 0).round()}°C',
          'description': _getWeatherDescription(
            data['current_weather']['weathercode'] ?? 0,
          ),
          'humidity': '${data['hourly']['relative_humidity_2m'][0] ?? 'N/A'}%',
          'pressure': '${(data['hourly']['pressure_msl'][0] ?? 0).round()} hPa',
          'wind_speed':
              '${(data['current_weather']['windspeed'] ?? 0).round()} km/h',
        };
      }
    } catch (e) {
      print('Weather API error: $e');
    }

    return defaultWeather;
  }

  // Get Weather Description from WMO weather codes
  static String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow fall';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  // Find Veihicle
  static Future<void> findVehicle(BuildContext context, Vehicle vehicle) async {
    try {
      // Check if vehicle has location data
      if (vehicle.latestLocation?.latitude == null ||
          vehicle.latestLocation?.longitude == null) {
        Get.snackbar(
          'Warning',
          'Vehicle location not available',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Get current mobile location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show Get snackbar with action to open settings
        Get.snackbar(
          'Location Services Disabled',
          'Location services are currently disabled. Tap to open settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 5),
          onTap: (_) async {
            await Geolocator.openLocationSettings();
          },
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission denied',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permissions are permanently denied. Please enable in settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 5),
          onTap: (_) async {
            await Geolocator.openAppSettings();
          },
        );
        return;
      }

      // Get current position
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps URL with directions
      final String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${vehicle.latestLocation!.latitude},${vehicle.latestLocation!.longitude}&travelmode=driving';

      // Launch Google Maps
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not launch Google Maps',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Show Nearby Places Modal
  static Future<void> showNearbyPlacesModal(
    BuildContext context,
    Vehicle vehicle,
  ) async {
    try {
      // Check if vehicle has location data
      if (vehicle.latestLocation?.latitude == null ||
          vehicle.latestLocation?.longitude == null) {
        Get.snackbar(
          'Warning',
          'Vehicle location not available',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => NearbyPlacesModal(
          latitude: vehicle.latestLocation!.latitude!,
          longitude: vehicle.latestLocation!.longitude!,
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Open Google Maps for nearby places
  static Future<void> openNearbyPlace(
    double latitude,
    double longitude,
    String placeType,
  ) async {
    try {
      // Create Google Maps URL for nearby search
      final String googleMapsUrl =
          'https://www.google.com/maps/search/$placeType/@$latitude,$longitude,15z';

      // Launch Google Maps
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not launch Google Maps',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
