import 'package:flutter/foundation.dart';

/// Azure Configuration for Video Call App
/// This class contains all Azure service endpoints and configuration
class AzureConfig {
  // Azure Communication Services Configuration
  static const String communicationServicesEndpoint =
      'https://acs-videocall-app.communication.azure.com';

  // Azure Functions Backend URL
  static const String functionsBaseUrl =
      'https://func-videocall-backend.azurewebsites.net/api';

  // Azure SignalR Service Configuration
  static const String signalRHubUrl =
      'https://signalr-videocall-chat.service.signalr.net';

  // Azure AD B2C Configuration
  static const String tenantId = 'your-tenant-id';
  static const String clientId = 'your-client-id';
  static const String redirectUri = 'msauth://com.example.videocallapp/auth';

  // API Endpoints
  static const String createMeetingEndpoint = '$functionsBaseUrl/meetings/create';
  static const String joinMeetingEndpoint = '$functionsBaseUrl/meetings/join';
  static const String getTokenEndpoint = '$functionsBaseUrl/auth/token';
  static const String refreshTokenEndpoint = '$functionsBaseUrl/auth/refresh';

  // SignalR Hub Names
  static const String chatHubName = 'ChatHub';
  static const String meetingHubName = 'MeetingHub';

  // Storage Keys
  static const String accessTokenKey = 'azure_access_token';
  static const String refreshTokenKey = 'azure_refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';

  // Meeting Configuration
  static const int maxParticipants = 50;
  static const int tokenExpirationMinutes = 60;
  static const int refreshTokenExpirationDays = 30;

  // Video Quality Settings
  static const String defaultVideoQuality = '720p';
  static const int defaultFrameRate = 30;
  static const int defaultBitrate = 1000; // kbps

  // Development vs Production
  static bool get isProduction => kReleaseMode;

  // Get environment-specific configuration
  static String get environment => isProduction ? 'production' : 'development';

  // Validate configuration
  static bool validateConfig() {
    return communicationServicesEndpoint.isNotEmpty &&
           functionsBaseUrl.isNotEmpty &&
           signalRHubUrl.isNotEmpty &&
           tenantId.isNotEmpty &&
           clientId.isNotEmpty;
  }

  // Get full endpoint URL
  static String getEndpointUrl(String endpoint) {
    return endpoint.startsWith('http') ? endpoint : '$functionsBaseUrl$endpoint';
  }
}

/// Azure Service Response Models
class AzureResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const AzureResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory AzureResponse.success(T data, {int statusCode = 200}) {
    return AzureResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory AzureResponse.error(String error, {int statusCode = 400}) {
    return AzureResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// Meeting Configuration Model
class MeetingConfig {
  final String meetingId;
  final String token;
  final String userId;
  final String displayName;
  final bool micEnabled;
  final bool cameraEnabled;
  final String videoQuality;

  const MeetingConfig({
    required this.meetingId,
    required this.token,
    required this.userId,
    required this.displayName,
    this.micEnabled = true,
    this.cameraEnabled = true,
    this.videoQuality = AzureConfig.defaultVideoQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'token': token,
      'userId': userId,
      'displayName': displayName,
      'micEnabled': micEnabled,
      'cameraEnabled': cameraEnabled,
      'videoQuality': videoQuality,
    };
  }

  factory MeetingConfig.fromJson(Map<String, dynamic> json) {
    return MeetingConfig(
      meetingId: json['meetingId'] ?? '',
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      micEnabled: json['micEnabled'] ?? true,
      cameraEnabled: json['cameraEnabled'] ?? true,
      videoQuality: json['videoQuality'] ?? AzureConfig.defaultVideoQuality,
    );
  }
}