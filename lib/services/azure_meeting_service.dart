import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/azure_config.dart';
import 'azure_auth_service.dart';

/// Azure Meeting Service
/// Handles meeting creation, joining, and management through Azure Communication Services
class AzureMeetingService {
  static final AzureMeetingService _instance = AzureMeetingService._internal();
  factory AzureMeetingService() => _instance;
  AzureMeetingService._internal();

  final Dio _dio = Dio();
  final AzureAuthService _authService = AzureAuthService();
  final Uuid _uuid = const Uuid();

  /// Initialize the meeting service
  Future<void> initialize() async {
    _setupDioInterceptors();
  }

  /// Setup Dio interceptors
  void _setupDioInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authService.accessToken != null) {
            options.headers['Authorization'] = 'Bearer ${_authService.accessToken}';
          }
          options.headers['Content-Type'] = 'application/json';
          handler.next(options);
        },
      ),
    );
  }

  /// Create a new meeting
  Future<AzureResponse<MeetingInfo>> createMeeting({
    String? meetingTitle,
    bool recordingEnabled = false,
    int maxParticipants = 50,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // Call Azure Functions to create meeting
      final response = await _dio.post(
        '${AzureConfig.functionsBaseUrl}/meetings/create',
        data: {
          'title': meetingTitle ?? 'Video Call Meeting',
          'recordingEnabled': recordingEnabled,
          'maxParticipants': maxParticipants,
          'hostId': _authService.currentUserId,
          'hostName': _authService.currentUserName,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        final meetingInfo = MeetingInfo(
          meetingId: data['meetingId'],
          title: data['title'],
          hostId: _authService.currentUserId!,
          hostName: _authService.currentUserName!,
          acsToken: data['token'],
          createdAt: DateTime.parse(data['createdAt']),
          maxParticipants: data['maxParticipants'],
          recordingEnabled: data['recordingEnabled'],
          status: MeetingStatus.waiting,
        );

        return AzureResponse.success(meetingInfo);
      } else {
        return AzureResponse.error(response.data['error'] ?? 'Failed to create meeting');
      }
    } catch (e) {
      // Fallback to mock meeting for development
      final meetingId = _generateMeetingId();
      final acsTokenResponse = await _authService.getACSToken();

      if (!acsTokenResponse.success) {
        return AzureResponse.error('Failed to create meeting: ${e.toString()}');
      }

      final meetingInfo = MeetingInfo(
        meetingId: meetingId,
        title: meetingTitle ?? 'Video Call Meeting',
        hostId: _authService.currentUserId!,
        hostName: _authService.currentUserName!,
        acsToken: acsTokenResponse.data!,
        createdAt: DateTime.now(),
        maxParticipants: maxParticipants,
        recordingEnabled: recordingEnabled,
        status: MeetingStatus.waiting,
      );

      return AzureResponse.success(meetingInfo);
    }
  }

  /// Join an existing meeting
  Future<AzureResponse<MeetingInfo>> joinMeeting(String meetingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // Validate meeting ID format
      if (!_isValidMeetingId(meetingId)) {
        return AzureResponse.error('Invalid meeting ID format');
      }

      // Call Azure Functions to join meeting
      final response = await _dio.post(
        '${AzureConfig.functionsBaseUrl}/meetings/join',
        data: {
          'meetingId': meetingId,
          'userName': _authService.currentUserName,
          'userId': _authService.currentUserId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        final meetingInfo = MeetingInfo(
          meetingId: data['meetingId'],
          title: 'Video Call Meeting',
          hostId: _authService.currentUserId!,
          hostName: _authService.currentUserName!,
          acsToken: data['token'],
          createdAt: DateTime.parse(data['joinedAt']),
          maxParticipants: 50,
          recordingEnabled: false,
          status: MeetingStatus.active,
        );

        return AzureResponse.success(meetingInfo);
      } else {
        return AzureResponse.error(response.data['error'] ?? 'Failed to join meeting');
      }
    } catch (e) {
      // Fallback to mock meeting for development
      final acsTokenResponse = await _authService.getACSToken();

      if (!acsTokenResponse.success) {
        return AzureResponse.error('Failed to join meeting: ${e.toString()}');
      }

      final meetingInfo = MeetingInfo(
        meetingId: meetingId,
        title: 'Video Call Meeting',
        hostId: 'host-id',
        hostName: 'Host',
        acsToken: acsTokenResponse.data!,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        maxParticipants: 50,
        recordingEnabled: false,
        status: MeetingStatus.active,
      );

      return AzureResponse.success(meetingInfo);
    }
  }

  /// End a meeting
  Future<AzureResponse<void>> endMeeting(String meetingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // In production, this would call Azure Functions to end the meeting
      // For demo, we'll just return success
      return AzureResponse.success(null);
    } catch (e) {
      return AzureResponse.error('Failed to end meeting: ${e.toString()}');
    }
  }

  /// Get meeting participants
  Future<AzureResponse<List<MeetingParticipant>>> getMeetingParticipants(String meetingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // For demo purposes, return mock participants
      // In production, this would call Azure Functions to get real participants
      final participants = <MeetingParticipant>[
        MeetingParticipant(
          id: _authService.currentUserId!,
          displayName: _authService.currentUserName!,
          isHost: true,
          isMuted: false,
          isCameraOn: true,
          joinedAt: DateTime.now(),
        ),
      ];

      return AzureResponse.success(participants);
    } catch (e) {
      return AzureResponse.error('Failed to get participants: ${e.toString()}');
    }
  }

  /// Start recording
  Future<AzureResponse<String>> startRecording(String meetingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // In production, this would call Azure Functions to start recording
      final recordingId = _uuid.v4();
      return AzureResponse.success(recordingId);
    } catch (e) {
      return AzureResponse.error('Failed to start recording: ${e.toString()}');
    }
  }

  /// Stop recording
  Future<AzureResponse<String>> stopRecording(String meetingId, String recordingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      // In production, this would call Azure Functions to stop recording
      final recordingUrl = 'https://your-storage.blob.core.windows.net/recordings/$recordingId.mp4';
      return AzureResponse.success(recordingUrl);
    } catch (e) {
      return AzureResponse.error('Failed to stop recording: ${e.toString()}');
    }
  }

  /// Generate a meeting ID
  String _generateMeetingId() {
    // Generate a meeting ID in the format: XXXX-XXXX-XXXX
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final id = random.substring(random.length - 12);
    return '${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8, 12)}';
  }

  /// Validate meeting ID format
  bool _isValidMeetingId(String meetingId) {
    final regex = RegExp(r'^\d{4}-\d{4}-\d{4}$');
    return regex.hasMatch(meetingId);
  }
}

/// Meeting Information Model
class MeetingInfo {
  final String meetingId;
  final String title;
  final String hostId;
  final String hostName;
  final String acsToken;
  final DateTime createdAt;
  final int maxParticipants;
  final bool recordingEnabled;
  final MeetingStatus status;
  final String? recordingUrl;

  const MeetingInfo({
    required this.meetingId,
    required this.title,
    required this.hostId,
    required this.hostName,
    required this.acsToken,
    required this.createdAt,
    required this.maxParticipants,
    required this.recordingEnabled,
    required this.status,
    this.recordingUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'title': title,
      'hostId': hostId,
      'hostName': hostName,
      'acsToken': acsToken,
      'createdAt': createdAt.toIso8601String(),
      'maxParticipants': maxParticipants,
      'recordingEnabled': recordingEnabled,
      'status': status.toString(),
      'recordingUrl': recordingUrl,
    };
  }

  factory MeetingInfo.fromJson(Map<String, dynamic> json) {
    return MeetingInfo(
      meetingId: json['meetingId'] ?? '',
      title: json['title'] ?? '',
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      acsToken: json['acsToken'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      maxParticipants: json['maxParticipants'] ?? 50,
      recordingEnabled: json['recordingEnabled'] ?? false,
      status: MeetingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => MeetingStatus.waiting,
      ),
      recordingUrl: json['recordingUrl'],
    );
  }
}

/// Meeting Participant Model
class MeetingParticipant {
  final String id;
  final String displayName;
  final bool isHost;
  final bool isMuted;
  final bool isCameraOn;
  final DateTime joinedAt;
  final String? profilePicture;

  const MeetingParticipant({
    required this.id,
    required this.displayName,
    required this.isHost,
    required this.isMuted,
    required this.isCameraOn,
    required this.joinedAt,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'isHost': isHost,
      'isMuted': isMuted,
      'isCameraOn': isCameraOn,
      'joinedAt': joinedAt.toIso8601String(),
      'profilePicture': profilePicture,
    };
  }

  factory MeetingParticipant.fromJson(Map<String, dynamic> json) {
    return MeetingParticipant(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      isHost: json['isHost'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isCameraOn: json['isCameraOn'] ?? true,
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      profilePicture: json['profilePicture'],
    );
  }
}

/// Meeting Status Enum
enum MeetingStatus {
  waiting,
  active,
  ended,
  cancelled,
}

/// Meeting Events for real-time updates
class MeetingEvent {
  final String meetingId;
  final MeetingEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const MeetingEvent({
    required this.meetingId,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MeetingEvent.fromJson(Map<String, dynamic> json) {
    return MeetingEvent(
      meetingId: json['meetingId'] ?? '',
      type: MeetingEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MeetingEventType.unknown,
      ),
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Meeting Event Types
enum MeetingEventType {
  participantJoined,
  participantLeft,
  participantMuted,
  participantUnmuted,
  participantCameraOn,
  participantCameraOff,
  recordingStarted,
  recordingStopped,
  meetingEnded,
  unknown,
}