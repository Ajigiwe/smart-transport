import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'api_client.dart';

/// Extract a user-friendly message from an exception (especially DioException).
String _friendlyErrorMessage(Object e) {
  if (e is DioException) {
    // Log the full error for debugging
    developer.log('DioError: type=${e.type}, url=${e.requestOptions.uri}, message=${e.message}', name: 'ApiClient');
    if (e.error != null) developer.log('DioError detail: ${e.error}', name: 'ApiClient');
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. URL: ${e.requestOptions.uri} — ${e.message ?? "unknown error"}';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        // Try to extract the backend's detail message from response body
        String? detail;
        try {
          final data = e.response?.data;
          if (data is Map && data['detail'] is String) {
            detail = data['detail'] as String;
          }
        } catch (_) {}
        if (statusCode == 401) return detail ?? 'Session expired. Please log in again.';
        if (statusCode == 403) return detail ?? 'You do not have permission for this action.';
        if (statusCode == 404) return detail ?? 'The requested resource was not found.';
        if (statusCode != null && statusCode >= 500) return detail ?? 'Server error. Please try again later.';
        return detail ?? 'Request failed (status $statusCode). Please try again.';
      default:
        return 'A network error occurred. Please try again.';
    }
  }
  return e.toString();
}

/// SmartTransport GH Auth State
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  
  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  bool get isAuthenticated => user != null && token != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isDriver => user?.isDriver ?? false;
  bool get isPassenger => user?.isPassenger ?? false;
}

/// SmartTransport GH Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  
  AuthNotifier(this._apiClient) : super(AuthState()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final token = await _apiClient.getToken();
      if (token != null) {
        final userData = await _apiClient.getMe();
        final user = User.fromJson(userData);
        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyErrorMessage(e),
      );
    }
  }
  
  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiClient.login(phone, password);
      final token = response['access_token'];
      final userId = response['user_id'];
      
      await _apiClient.saveToken(token);
      
      User user;
      try {
        final userData = await _apiClient.getMe();
        user = User.fromJson(userData);
      } catch (_) {
        // Fallback: build user from login response
        user = User(
          id: response['user_id'] ?? 0,
          name: '',
          phone: phone,
          role: UserRole.fromString(response['role'] ?? 'passenger'),
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
      
      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
      
      return true;
    } catch (e) {      state = state.copyWith(
        isLoading: false,
        error: _friendlyErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiClient.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
      );
      
      // Auto-login after registration
      return await login(phone, password);
    } catch (e) {      state = state.copyWith(
        isLoading: false,
        error: _friendlyErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
    state = AuthState();
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// SmartTransport GH Auth Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
