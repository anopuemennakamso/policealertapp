import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL setup:
  // - Chrome / Flutter Web / Windows Desktop: 'http://127.0.0.1:8000'
  // - Android Emulator: 'http://10.0.2.2:8000'
  // - Physical Phone: 'http://<YOUR_COMPUTER_LOCAL_IP>:8000'
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Register user POST -> /api/auth/register
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String role = 'citizen',
    String? badgeCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'role': role,
          'badge_code': badgeCode,
        }),
      );

      debugPrint('REGISTER Status Code: ${response.statusCode}');
      debugPrint('REGISTER Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        String message = 'Registration failed.';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('detail')) {
            message = data['detail'].toString();
          }
        } catch (_) {}
        return {'success': false, 'message': message};
      }
    } catch (e) {
      debugPrint('REGISTER Network Exception: $e');
      return {
        'success': false,
        'message': 'Network error. Please check server connection.'
      };
    }
  }

  /// Login user POST -> /api/auth/login
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('LOGIN Status Code: ${response.statusCode}');
      debugPrint('LOGIN Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('LOGIN Network Exception: $e');
      return null;
    }
  }

  /// Trigger alert POST -> /api/alerts/{user_id}
  static Future<bool> triggerAlert({
    required int userId,
    required double latitude,
    required double longitude,
    String emergencyType = 'General SOS',
    String? description,
  }) async {
    final url = Uri.parse('$baseUrl/api/alerts/$userId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'emergency_type': emergencyType,
          'description': description,
        }),
      );

      debugPrint('TRIGGER ALERT Status Code: ${response.statusCode}');
      debugPrint('TRIGGER ALERT Response Body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('TRIGGER ALERT Network Exception: $e');
      return false;
    }
  }

  /// Fetch user alerts GET -> /api/alerts/{user_id}
  static Future<List<Map<String, dynamic>>> fetchUserAlerts(int userId) async {
    final url = Uri.parse('$baseUrl/api/alerts/$userId');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('FETCH ALERTS Status Code: ${response.statusCode}');
      debugPrint('FETCH ALERTS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('FETCH ALERTS Exception: $e');
      return [];
    }
  }

  /// Fetch all active alerts for law enforcement GET -> /api/responder/alerts
  static Future<List<Map<String, dynamic>>> fetchAllActiveAlerts() async {
    final url = Uri.parse('$baseUrl/api/responder/alerts');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('FETCH RESPONDER ALERTS Status Code: ${response.statusCode}');
      debugPrint('FETCH RESPONDER ALERTS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('FETCH RESPONDER ALERTS Exception: $e');
      return [];
    }
  }

  /// Acknowledge an active alert PATCH -> /api/responder/alerts/{alert_id}/acknowledge
  static Future<bool> acknowledgeAlert(int alertId) async {
    final url = Uri.parse('$baseUrl/api/responder/alerts/$alertId/acknowledge');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'DISPATCHED',
          'message': 'Unit en route to location.',
        }),
      );

      debugPrint('ACKNOWLEDGE ALERT Status Code: ${response.statusCode}');
      debugPrint('ACKNOWLEDGE ALERT Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error acknowledging alert: $e');
      return false;
    }
  }

  /// Resolve an active alert PATCH -> /api/responder/alerts/{alert_id}/resolve
  static Future<bool> resolveAlert(int alertId) async {
    final url = Uri.parse('$baseUrl/api/responder/alerts/$alertId/resolve');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('RESOLVE ALERT Status Code: ${response.statusCode}');
      debugPrint('RESOLVE ALERT Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('RESOLVE ALERT Exception: $e');
      return false;
    }
  }

  /// Fetch User Profile GET -> /api/users/{user_id}
  static Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    return null;
  }

  /// Update User Profile PUT -> /api/users/{user_id}
  static Future<bool> updateUserProfile(int userId, String name, String phone) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': name, 'phone_number': phone}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Add Emergency Contact POST -> /api/users/{user_id}/contacts
  static Future<bool> addContact(int userId, String name, String phone, String relation) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/contacts');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
          'relationship_type': relation,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  /// Delete Emergency Contact DELETE -> /api/users/contacts/{contact_id}
  static Future<bool> deleteContact(int contactId) async {
    final url = Uri.parse('$baseUrl/api/users/contacts/$contactId');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }
}