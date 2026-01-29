import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class ApiLogger {
  static void logRequest(String method, String url, {Map<String, String>? headers, String? body}) {
    developer.log('=== API REQUEST ===');
    developer.log('Method: $method');
    developer.log('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      developer.log('Headers: $headers');
    }
    if (body != null && body.isNotEmpty) {
      developer.log('Body: $body');
    }
    developer.log('==================');
  }

  static void logResponse(http.Response response) {
    developer.log('=== API RESPONSE ===');
    developer.log('Status Code: ${response.statusCode}');
    developer.log('URL: ${response.request?.url}');
    if (response.headers.isNotEmpty) {
      developer.log('Headers: ${response.headers}');
    }
    developer.log('Body: ${response.body}');
    developer.log('===================');
  }

  static void logError(String method, String url, dynamic error, {http.Response? response}) {
    developer.log('=== API ERROR ===');
    developer.log('Method: $method');
    developer.log('URL: $url');
    developer.log('Error: $error');
    if (response != null) {
      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');
    }
    developer.log('================');
  }
}
