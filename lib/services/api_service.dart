import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Import the global navigatorKey from main.dart
import '../models/experiment.dart';

class ApiService {
  late final http.Client _client;

  ApiService() {
    _client = _createUnsecureClient();
  }

  http.Client _createUnsecureClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final auth = base64Encode(utf8.encode('$username:$password'));

    return {
      "accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Basic $auth",
    };
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('base_url') ?? '';
    return "https://${url}/ajax-api/2.0/mlflow";
  }

  Future<List<Experiment>> getExperiments() async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/experiments/search?max_results=20000");
      final headers = await _getHeaders();

      // Log the request
      print("GET Request: $url");
      print("Headers: $headers");

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['experiments'] as List)
            .map((e) => Experiment.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to get experiments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorNotification(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExperimentById(String experimentId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/experiments/get?experiment_id=$experimentId");
      final headers = await _getHeaders();

      // Log the request
      print("GET Request: $url");
      print("Headers: $headers");

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get experiment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorNotification(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLatestRuns(String experimentId, {int maxResults = 100, String? pageToken}) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/runs/search");
      final headers = await _getHeaders();
      final data = {
        "experiment_ids": [experimentId],
        "run_view_type": "ACTIVE_ONLY",
        "max_results": maxResults,
        "order_by": ["attributes.start_time DESC"]
      };

      if (pageToken != null) {
        data["page_token"] = pageToken;
      }

      // Log the request
      print("POST Request: $url");
      print("Headers: $headers");
      print("Body: ${jsonEncode(data)}");

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get runs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorNotification(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNewRuns(String experimentId, String lastTime) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/runs/search");
      final headers = await _getHeaders();
      final data = {
        "experiment_ids": [experimentId],
        "filter": "attributes.start_time > $lastTime",
        "max_results": 26
      };

      // Log the request
      print("POST Request: $url");
      print("Headers: $headers");
      print("Body: ${jsonEncode(data)}");

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get runs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorNotification(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBulkMetrics(List<String> runIds, String metricKey, int maxResults) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? '';
      final headers = await _getHeaders();

      final url = Uri.parse("https://$baseUrl/ajax-api/2.0/mlflow/metrics/get-history-bulk-interval?${runIds.map((id) => 'run_ids=$id').join('&')}&metric_key=$metricKey&max_results=$maxResults");

      // Log the request
      print("GET Request: ${url}");
      print("Headers: $headers");

      // Rate limiting: Add a delay before making the request
      await Future.delayed(const Duration(milliseconds: 300)); // 2 requests per second

      final response = await _client.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get metrics: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorNotification(e.toString());
      rethrow;
    }
  }

  void _showErrorNotification(String message) {
    if (navigatorKey.currentContext != null) { // Use the global navigatorKey
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
