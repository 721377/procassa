// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:procassa/main.dart';
import 'package:procassa/screens/cert_error_screen.dart';

class APIs {
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 5);
  
  static const String baseUrl = 'https://procassa.dicotec.it/api/v1';
  static String? _bearerToken;

  static void setToken(String? token) {
    _bearerToken = token;
  }

  // --- Generic Request Helper ---

  static Future<http.Response> _makeRequest({
    required String path,
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    final bool isAbsolute = path.startsWith('http');
    final Uri url = isAbsolute ? Uri.parse(path) : Uri.parse('$baseUrl$path');
     print('Preparing $method request to $url');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
    };

    print('API :: $method $url');
    if (body != null) print('Body :: ${jsonEncode(body)}');

    Future<http.Response> request;
    try {
      if (method == 'POST') {
        request = _client.post(url, headers: headers, body: jsonEncode(body));
      } else {
        request = _client.get(url, headers: headers);
      }

      final response = await request.timeout(_timeout);
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('Error :: ${response.statusCode} - ${response.body}');
      }
      
      return response;
    } on HandshakeException catch (e) {
      _handleCertError();
      rethrow;
    } on TlsException catch (e) {
      _handleCertError();
      rethrow;
    }
  }

  static void _handleCertError() {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CertErrorScreen()),
      );
    }
  }

  // --- Authentication APIs ---

  static Future<http.Response> login({
    required String username,
    required String password,
  }) async {
    final response = await _makeRequest(
      path: '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['accessToken']);
    }
    return response;
  }

  static Future<http.Response> refreshToken(String refreshToken) async {
    final response = await _makeRequest(
      path: '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['accessToken']);
    }
    return response;
  }

  static Future<http.Response> fetchProfile() async {
    return await _makeRequest(path: '/users/me', method: 'GET');
  }

  // --- Client Registration ---

  static Future<http.Response> registerClient({
    required String companyName,
    String? nome,
    required String email,
    required String password,
    String? piva,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? contactPerson,
    String? country = 'IT',
  }) async {
    return await _makeRequest(
      path: '/clients/register',
      body: {
        'company_name': companyName,
        'nome': nome ?? companyName,
        'email': email,
        'password': password,
        'piva': piva,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'contact_person': contactPerson ?? nome ?? companyName,
        'country': country,
      },
    );
  }

  // --- Payment APIs ---

  static Future<http.Response> createSatispayPayment({
    required String pv,
    required double importo,
  }) async {
    return await _makeRequest(
      path: 'http://192.168.0.8/sviluppo/mohamed/proweb/ecomeapi/route.php',
      body: {
        'api': 'satispayCreatePayment',
        'db':'dicotec',
        'pv': pv,
        'importo': importo,
      },
    );
  }
}
