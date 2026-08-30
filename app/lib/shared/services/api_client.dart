import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// SmartTransport GH API Client
/// Handles HTTP requests with automatic token injection
class ApiClient {
  static const String _defaultUrl = 'https://smarttransport-api.onrender.com';
  static const String _customUrlKey = 'custom_server_url';
  static String? _customUrl;
  static final FlutterSecureStorage _staticStorage = const FlutterSecureStorage();

  /// Load custom URL from storage (call once at app startup)
  static Future<void> loadCustomUrl() async {
    try {
      _customUrl = await _staticStorage.read(key: _customUrlKey);
    } catch (_) {}
  }

  /// Save a custom server URL
  static Future<void> setCustomUrl(String url) async {
    _customUrl = url.isNotEmpty ? url : null;
    try {
      if (url.isNotEmpty) {
        await _staticStorage.write(key: _customUrlKey, value: url);
      } else {
        await _staticStorage.delete(key: _customUrlKey);
      }
    } catch (_) {}
  }

  /// Get the current server URL
  static String get currentUrl => _customUrl ?? _defaultUrl;

  static String get _baseUrl {
    // User-configured URL takes priority
    if (_customUrl != null) return _customUrl!;
    // Build-time override
    const prodUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (prodUrl.isNotEmpty) return prodUrl;
    // Web: use Render production URL
    if (kIsWeb) return _defaultUrl;
    // Android: use Render production URL
    if (Platform.isAndroid) return _defaultUrl;
    // iOS simulator / desktop: use localhost
    return 'http://localhost:8000';
  }

  String get baseUrl => _baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final Dio _dio;
  final FlutterSecureStorage _storage;
  String? _inMemoryToken;

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? _baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _storage = const FlutterSecureStorage() {
    // ignore: avoid_print
    print('[ApiClient] Base URL: ${baseUrl ?? _baseUrl}');
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // ignore: avoid_print
          print('[ApiClient] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('[ApiClient] ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) async {
          // Follow 307 redirects — Dio doesn't follow them for POST requests
          if (error.response?.statusCode == 307 || error.response?.statusCode == 308) {
            final redirectUrl = error.response?.headers.value('location');
            if (redirectUrl != null) {
              try {
                final redirectResponse = await _dio.fetch(RequestOptions(
                  path: redirectUrl.startsWith('http') ? redirectUrl : redirectUrl,
                  method: error.requestOptions.method,
                  data: error.requestOptions.data,
                  headers: Map<String, dynamic>.from(error.requestOptions.headers),
                ));
                return handler.resolve(redirectResponse);
              } catch (_) {}
            }
          }
          // ignore: avoid_print
          print('[ApiClient] ERROR: ${error.type} ${error.requestOptions.uri} ${error.response?.statusCode} ${error.message}');
          if (error.response?.statusCode == 401) {
            await clearTokens();
          }
          handler.next(error);
        },
      ),
    );
  }

  // ============================================================================
  // Token Management
  // ============================================================================

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: user.toJson().toString());
  }

  Future<User?> getSavedUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return null;
    }
    return null;
  }

  // ============================================================================
  // Dashboard Stats
  // ============================================================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/dashboard/stats');
    return response.data;
  }

  // ============================================================================
  // Auth Endpoints
  // ============================================================================

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  // ============================================================================
  // User Endpoints
  // ============================================================================

  Future<List<dynamic>> getUsers({String? role}) async {
    final queryParams = <String, dynamic>{};
    if (role != null) queryParams['role'] = role;
    final response = await _dio.get('/users', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/$userId', data: data);
    return response.data;
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete('/users/$userId');
  }

  // ============================================================================
  // Route Endpoints
  // ============================================================================

  Future<List<dynamic>> getRoutes() async {
    final response = await _dio.get('/routes');
    return response.data;
  }

  Future<Map<String, dynamic>> getRoute(int routeId) async {
    final response = await _dio.get('/routes/$routeId');
    return response.data;
  }

  Future<Map<String, dynamic>> createRoute(Map<String, dynamic> data) async {
    final response = await _dio.post('/routes', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRoute(int routeId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/routes/$routeId', data: data);
    return response.data;
  }

  Future<void> deleteRoute(int routeId) async {
    await _dio.delete('/routes/$routeId');
  }

  // ============================================================================
  // Vehicle Endpoints
  // ============================================================================

  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/vehicles');
    return response.data;
  }

  Future<Map<String, dynamic>> getVehicle(int vehicleId) async {
    final response = await _dio.get('/vehicles/$vehicleId');
    return response.data;
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await _dio.post('/vehicles', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateVehicle(int vehicleId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/vehicles/$vehicleId', data: data);
    return response.data;
  }

  Future<void> deleteVehicle(int vehicleId) async {
    await _dio.delete('/vehicles/$vehicleId');
  }

  // ============================================================================
  // Trip Endpoints
  // ============================================================================

  Future<List<dynamic>> getTrips({String? status, int? routeId}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status_filter'] = status;
    if (routeId != null) params['route_id'] = routeId;
    final response = await _dio.get('/trips', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getTrip(int tripId) async {
    final response = await _dio.get('/trips/$tripId');
    return response.data;
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> data) async {
    final response = await _dio.post('/trips', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTrip(int tripId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/trips/$tripId', data: data);
    return response.data;
  }

  Future<List<dynamic>> getTripLocations(int tripId) async {
    final response = await _dio.get('/trips/$tripId/locations');
    return response.data;
  }

  // ============================================================================
  // Booking Endpoints
  // ============================================================================

  Future<List<dynamic>> getBookings() async {
    final response = await _dio.get('/bookings');
    return response.data;
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    return response.data;
  }

  Future<Map<String, dynamic>> createBooking(int tripId) async {
    final response = await _dio.post('/bookings', data: {'trip_id': tripId});
    return response.data;
  }

  Future<Map<String, dynamic>> updateBooking(int bookingId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/bookings/$bookingId', data: data);
    return response.data;
  }

  Future<void> deleteBooking(int bookingId) async {
    await _dio.delete('/bookings/$bookingId');
  }

  Future<List<dynamic>> getBookingsForTrip(int tripId) async {
    final response = await _dio.get('/bookings/trip/$tripId');
    return response.data;
  }

  // ============================================================================
  // Vehicle (Driver) Endpoints
  // ============================================================================

  Future<Map<String, dynamic>> getMyVehicle() async {
    final response = await _dio.get('/vehicles/driver/me');
    return response.data;
  }

  // ============================================================================
  // Trip Details
  // ============================================================================

  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    final response = await _dio.get('/trips/$tripId/details');
    return response.data;
  }

  // ============================================================================
  // Profile Update
  // ============================================================================

  Future<Map<String, dynamic>> updateProfile(int userId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/$userId', data: data);
    return response.data;
  }

  // ============================================================================
  // WebSocket Connection
  // ============================================================================

  Future<WebSocket> connectToTrip(int tripId) async {
    final wsUrl = _baseUrl.replaceFirst('http', 'ws');
    return await WebSocket.connect('$wsUrl/trips/ws/$tripId');
  }
}
