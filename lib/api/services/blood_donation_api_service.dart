import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/models/blood_donation_model.dart';

class BloodDonationApiService {
  static const String _baseUrl = ApiClient.baseUrl;

  // Get all blood donations
  static Future<BloodDonationResponse> getAllBloodDonations({
    String? applyType,
    String? bloodGroup,
    String? search,
  }) async {
    try {
      String url = '$_baseUrl/api/blood-donation';
      List<String> queryParams = [];

      if (applyType != null) queryParams.add('applyType=$applyType');
      if (bloodGroup != null) queryParams.add('bloodGroup=$bloodGroup');
      if (search != null) queryParams.add('search=$search');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BloodDonationResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load blood donations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching blood donations: $e');
    }
  }

  // Get blood donation by ID
  static Future<BloodDonation> getBloodDonationById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/blood-donation/$id'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return BloodDonation.fromJson(jsonData['data']);
        } else {
          throw Exception('Blood donation not found');
        }
      } else {
        throw Exception(
          'Failed to load blood donation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching blood donation: $e');
    }
  }

  // Create blood donation
  static Future<BloodDonation> createBloodDonation(
    BloodDonation bloodDonation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/blood-donation/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bloodDonation.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return BloodDonation.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to create blood donation');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(
          jsonData['message'] ?? 'Failed to create blood donation',
        );
      }
    } catch (e) {
      throw Exception('Error creating blood donation: $e');
    }
  }

  // Update blood donation
  static Future<BloodDonation> updateBloodDonation(
    int id,
    BloodDonation bloodDonation,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/blood-donation/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bloodDonation.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return BloodDonation.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to update blood donation');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(
          jsonData['message'] ?? 'Failed to update blood donation',
        );
      }
    } catch (e) {
      throw Exception('Error updating blood donation: $e');
    }
  }

  // Delete blood donation
  static Future<bool> deleteBloodDonation(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/blood-donation/delete/$id'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        throw Exception(
          'Failed to delete blood donation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting blood donation: $e');
    }
  }

  // Get blood donations by type
  static Future<BloodDonationResponse> getBloodDonationsByType(
    String type,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/blood-donation/type/$type'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BloodDonationResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load blood donations by type: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching blood donations by type: $e');
    }
  }

  // Get blood donations by blood group
  static Future<BloodDonationResponse> getBloodDonationsByBloodGroup(
    String bloodGroup,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/blood-donation/blood-group/$bloodGroup'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BloodDonationResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load blood donations by blood group: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching blood donations by blood group: $e');
    }
  }
}
