import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update base URL depending on your environment:
  // - Chrome / Flutter Web / Windows Desktop: 'http://127.0.0.1:8000'
  // - Android Emulator: 'http://10.0.2.2:8000'
  // - Physical Phone: 'http://<YOUR_COMPUTER_LOCAL_IP>:8000'
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Register user POST -> /api/auth/register
  static Future<bool> registerUser({
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

      print('REGISTER Status Code: ${response.statusCode}');
      print('REGISTER Response Body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('REGISTER Network Exception: $e');
      return false;
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

      print('LOGIN Status Code: ${response.statusCode}');
      print('LOGIN Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('LOGIN Network Exception: $e');
      return null;
    }
  }

  /// Trigger alert POST -> /api/alerts/{user_id}
  static Future<bool> triggerAlert({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/api/alerts/$userId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('TRIGGER ALERT Status Code: ${response.statusCode}');
      print('TRIGGER ALERT Response Body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('TRIGGER ALERT Network Exception: $e');
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

      print('FETCH ALERTS Status Code: ${response.statusCode}');
      print('FETCH ALERTS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('FETCH ALERTS Exception: $e');
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

      print('FETCH RESPONDER ALERTS Status Code: ${response.statusCode}');
      print('FETCH RESPONDER ALERTS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('FETCH RESPONDER ALERTS Exception: $e');
      return [];
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

      print('RESOLVE ALERT Status Code: ${response.statusCode}');
      print('RESOLVE ALERT Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('RESOLVE ALERT Exception: $e');
      return false;
    }
  }
}