import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';
import '../config/azure_config.dart';

/// Azure Authentication Service
/// Handles user authentication, token management, and secure storage
class AzureAuthService {
  static final AzureAuthService _instance = AzureAuthService._internal();
  factory AzureAuthService() => _instance;
  AzureAuthService._internal();

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  String? _currentUserId;
  String? _currentUserName;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired(_accessToken!);

  /// Initialize the authentication service
  Future<void> initialize() async {
    await _loadStoredTokens();
    _setupDioInterceptors();
  }

  /// Setup Dio interceptors for automatic token refresh
  void _setupDioInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              // Retry the original request
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              try {
                final response = await _dio.fetch(opts);
                handler.resolve(response);
                return;
              } catch (e) {
                // If retry fails, continue with original error
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Login with email and password (simplified for demo)
  Future<AzureResponse<Map<String, dynamic>>> login(String email, String password) async {
    try {
      // For demo purposes, we'll create a mock user
      // In production, this would integrate with Azure AD B2C
      final userId = _uuid.v4();
      final userName = email.split('@')[0];

      // Mock token generation (in production, this comes from Azure)
      final mockToken = _generateMockToken(userId, userName);
      final mockRefreshToken = _uuid.v4();

      await _storeTokens(mockToken, mockRefreshToken, userId, userName);

      return AzureResponse.success({
        'userId': userId,
        'userName': userName,
        'accessToken': mockToken,
        'refreshToken': mockRefreshToken,
      });
    } catch (e) {
      return AzureResponse.error('Login failed: ${e.toString()}');
    }
  }

  /// Register new user (simplified for demo)
  Future<AzureResponse<Map<String, dynamic>>> register(String email, String password, String displayName) async {
    try {
      // For demo purposes, we'll create a mock user
      // In production, this would integrate with Azure AD B2C
      final userId = _uuid.v4();

      // Mock token generation
      final mockToken = _generateMockToken(userId, displayName);
      final mockRefreshToken = _uuid.v4();

      await _storeTokens(mockToken, mockRefreshToken, userId, displayName);

      return AzureResponse.success({
        'userId': userId,
        'userName': displayName,
        'accessToken': mockToken,
        'refreshToken': mockRefreshToken,
      });
    } catch (e) {
      return AzureResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _clearStoredTokens();
    _currentUserId = null;
    _currentUserName = null;
    _accessToken = null;
    _refreshToken = null;
  }

  /// Get Azure Communication Services token for video calling
  Future<AzureResponse<String>> getACSToken() async {
    if (!isAuthenticated) {
      return AzureResponse.error('User not authenticated');
    }

    try {
      // In production, this would call Azure Functions to get ACS token
      // For demo, we'll return a mock token
      final acsToken = _generateMockACSToken();
      return AzureResponse.success(acsToken);
    } catch (e) {
      return AzureResponse.error('Failed to get ACS token: ${e.toString()}');
    }
  }

  /// Refresh access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      // In production, this would call Azure AD B2C refresh endpoint
      // For demo, we'll generate a new mock token
      final newToken = _generateMockToken(_currentUserId!, _currentUserName!);
      await _storeTokens(newToken, _refreshToken!, _currentUserId!, _currentUserName!);
      return true;
    } catch (e) {
      await logout(); // Clear invalid tokens
      return false;
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens(String accessToken, String refreshToken, String userId, String userName) async {
    await _secureStorage.write(key: AzureConfig.accessTokenKey, value: accessToken);
    await _secureStorage.write(key: AzureConfig.refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: AzureConfig.userIdKey, value: userId);
    await _secureStorage.write(key: AzureConfig.userNameKey, value: userName);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Load stored tokens
  Future<void> _loadStoredTokens() async {
    _accessToken = await _secureStorage.read(key: AzureConfig.accessTokenKey);
    _refreshToken = await _secureStorage.read(key: AzureConfig.refreshTokenKey);
    _currentUserId = await _secureStorage.read(key: AzureConfig.userIdKey);
    _currentUserName = await _secureStorage.read(key: AzureConfig.userNameKey);

    // Check if token is expired
    if (_accessToken != null && _isTokenExpired(_accessToken!)) {
      await _refreshAccessToken();
    }
  }

  /// Clear stored tokens
  Future<void> _clearStoredTokens() async {
    await _secureStorage.delete(key: AzureConfig.accessTokenKey);
    await _secureStorage.delete(key: AzureConfig.refreshTokenKey);
    await _secureStorage.delete(key: AzureConfig.userIdKey);
    await _secureStorage.delete(key: AzureConfig.userNameKey);
  }

  /// Check if token is expired
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true; // If we can't decode, consider it expired
    }
  }

  /// Generate mock JWT token for demo purposes
  String _generateMockToken(String userId, String userName) {
    final header = base64Url.encode(utf8.encode(json.encode({
      'alg': 'HS256',
      'typ': 'JWT'
    })));

    final payload = base64Url.encode(utf8.encode(json.encode({
      'sub': userId,
      'name': userName,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    })));

    final signature = base64Url.encode(utf8.encode('mock-signature'));

    return '$header.$payload.$signature';
  }

  /// Generate mock Azure Communication Services token
  String _generateMockACSToken() {
    // This is a simplified mock token for demo purposes
    // In production, this would be a real ACS token from Azure
    return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1yNS1BVWliZkJpaTdOZDFqQmViYXhib1hXMCIsImtpZCI6Ik1yNS1BVWliZkJpaTdOZDFqQmViYXhib1hXMCJ9.mock-acs-token';
  }
}

/// User model for Azure authentication
class AzureUser {
  final String id;
  final String email;
  final String displayName;
  final String? profilePicture;
  final DateTime createdAt;

  const AzureUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.profilePicture,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AzureUser.fromJson(Map<String, dynamic> json) {
    return AzureUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      profilePicture: json['profilePicture'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}