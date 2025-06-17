import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/constants/api_constants.dart';

class ApiClient {
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response from server');
        }

        final decoded = jsonDecode(responseBody);
        if (decoded == null) {
          throw Exception('Invalid JSON response');
        }

        return decoded;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format: ${e.message}');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response from server');
        }

        final decoded = jsonDecode(responseBody);
        if (decoded == null) {
          throw Exception('Invalid JSON response');
        }

        return decoded;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format: ${e.message}');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response from server');
        }

        final decoded = jsonDecode(responseBody);
        if (decoded == null) {
          throw Exception('Invalid JSON response');
        }

        return decoded;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format: ${e.message}');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response from server');
        }

        final decoded = jsonDecode(responseBody);
        if (decoded == null) {
          throw Exception('Invalid JSON response');
        }

        return decoded;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format: ${e.message}');
      }
      rethrow;
    }
  }
}
