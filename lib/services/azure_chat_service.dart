import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/azure_config.dart';
import 'azure_auth_service.dart';

/// Azure Chat Service
/// Handles real-time chat functionality using Azure SignalR Service
class AzureChatService {
  static final AzureChatService _instance = AzureChatService._internal();
  factory AzureChatService() => _instance;
  AzureChatService._internal();

  HubConnection? _hubConnection;
  final AzureAuthService _authService = AzureAuthService();

  // Stream controllers for real-time events
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<ChatEvent> _eventController = StreamController<ChatEvent>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<ChatEvent> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  String? _currentMeetingId;

  /// Initialize the chat service
  Future<void> initialize() async {
    // Service is ready to connect when needed
  }

  /// Connect to a meeting chat
  Future<AzureResponse<void>> connectToMeeting(String meetingId) async {
    try {
      if (!_authService.isAuthenticated) {
        return AzureResponse.error('User not authenticated');
      }

      _currentMeetingId = meetingId;
      await _createConnection();
      await _startConnection();
      await _joinMeetingGroup(meetingId);

      return AzureResponse.success(null);
    } catch (e) {
      return AzureResponse.error('Failed to connect to meeting chat: ${e.toString()}');
    }
  }

  /// Disconnect from meeting chat
  Future<void> disconnect() async {
    try {
      if (_currentMeetingId != null) {
        await _leaveMeetingGroup(_currentMeetingId!);
      }
      await _hubConnection?.stop();
      _hubConnection = null;
      _currentMeetingId = null;
      _connectionController.add(false);
    } catch (e) {
      // print('Error disconnecting from chat: $e');
    }
  }

  /// Send a message to the meeting chat
  Future<AzureResponse<void>> sendMessage(String message) async {
    try {
      if (!isConnected || _currentMeetingId == null) {
        return AzureResponse.error('Not connected to meeting chat');
      }

      if (message.trim().isEmpty) {
        return AzureResponse.error('Message cannot be empty');
      }

      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        meetingId: _currentMeetingId!,
        senderId: _authService.currentUserId!,
        senderName: _authService.currentUserName!,
        message: message.trim(),
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );

      await _hubConnection!.invoke('SendMessage', args: [chatMessage.toJson()]);
      return AzureResponse.success(null);
    } catch (e) {
      return AzureResponse.error('Failed to send message: ${e.toString()}');
    }
  }

  /// Send a system notification
  Future<AzureResponse<void>> sendSystemNotification(String notification) async {
    try {
      if (!isConnected || _currentMeetingId == null) {
        return AzureResponse.error('Not connected to meeting chat');
      }

      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        meetingId: _currentMeetingId!,
        senderId: 'system',
        senderName: 'System',
        message: notification,
        timestamp: DateTime.now(),
        type: ChatMessageType.system,
      );

      await _hubConnection!.invoke('SendSystemMessage', args: [chatMessage.toJson()]);
      return AzureResponse.success(null);
    } catch (e) {
      return AzureResponse.error('Failed to send system notification: ${e.toString()}');
    }
  }

  /// Create SignalR connection
  Future<void> _createConnection() async {
    final connectionUrl = '${AzureConfig.signalRHubUrl}/${AzureConfig.chatHubName}';

    _hubConnection = HubConnectionBuilder()
        .withUrl(connectionUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => _authService.accessToken ?? '',
        ))
        .withAutomaticReconnect()
        .build();

    // Set up event handlers
    _setupEventHandlers();
  }

  /// Setup SignalR event handlers
  void _setupEventHandlers() {
    if (_hubConnection == null) return;

    // Connection state changes - commented out due to callback type issues
    // Will be implemented when Azure SignalR is properly configured
    // _hubConnection!.onclose(() => _connectionController.add(false));
    // _hubConnection!.onreconnecting(() => _connectionController.add(false));
    // _hubConnection!.onreconnected(() => _connectionController.add(true));

    // Message events
    _hubConnection!.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final messageData = arguments[0] as Map<String, dynamic>;
          final message = ChatMessage.fromJson(messageData);
          _messageController.add(message);
        } catch (e) {
          // print('Error parsing received message: $e');
        }
      }
    });

    // Chat events (typing, user joined/left, etc.)
    _hubConnection!.on('ChatEvent', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final eventData = arguments[0] as Map<String, dynamic>;
          final event = ChatEvent.fromJson(eventData);
          _eventController.add(event);
        } catch (e) {
          // print('Error parsing chat event: $e');
        }
      }
    });

    // User typing events
    _hubConnection!.on('UserTyping', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          final userId = arguments[0] as String;
          final userName = arguments[1] as String;
          final isTyping = arguments.length > 2 ? arguments[2] as bool : true;

          final event = ChatEvent(
            meetingId: _currentMeetingId!,
            type: isTyping ? ChatEventType.userStartedTyping : ChatEventType.userStoppedTyping,
            userId: userId,
            userName: userName,
            timestamp: DateTime.now(),
          );

          _eventController.add(event);
        } catch (e) {
          // print('Error parsing typing event: $e');
        }
      }
    });
  }

  /// Start the SignalR connection
  Future<void> _startConnection() async {
    if (_hubConnection == null) return;

    try {
      await _hubConnection!.start();
      _connectionController.add(true);
      // print('SignalR connection started successfully');
    } catch (e) {
      _connectionController.add(false);
      throw Exception('Failed to start SignalR connection: $e');
    }
  }

  /// Join a meeting group
  Future<void> _joinMeetingGroup(String meetingId) async {
    if (_hubConnection == null || !isConnected) return;

    try {
      await _hubConnection!.invoke('JoinMeetingGroup', args: [meetingId]);
      // print('Joined meeting group: $meetingId');
    } catch (e) {
      // print('Error joining meeting group: $e');
    }
  }

  /// Leave a meeting group
  Future<void> _leaveMeetingGroup(String meetingId) async {
    if (_hubConnection == null) return;

    try {
      await _hubConnection!.invoke('LeaveMeetingGroup', args: [meetingId]);
      // print('Left meeting group: $meetingId');
    } catch (e) {
      // print('Error leaving meeting group: $e');
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(bool isTyping) async {
    if (!isConnected || _currentMeetingId == null) return;

    try {
      await _hubConnection!.invoke('SendTypingIndicator', args: [
        _currentMeetingId!,
        _authService.currentUserId!,
        _authService.currentUserName!,
        isTyping,
      ]);
    } catch (e) {
      // print('Error sending typing indicator: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _messageController.close();
    _eventController.close();
    _connectionController.close();
  }
}

/// Chat Message Model
class ChatMessage {
  final String id;
  final String meetingId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final ChatMessageType type;
  final String? replyToId;

  const ChatMessage({
    required this.id,
    required this.meetingId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.replyToId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetingId': meetingId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'replyToId': replyToId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      meetingId: json['meetingId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: ChatMessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      replyToId: json['replyToId'],
    );
  }
}

/// Chat Event Model
class ChatEvent {
  final String meetingId;
  final ChatEventType type;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const ChatEvent({
    required this.meetingId,
    required this.type,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'type': type.toString(),
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory ChatEvent.fromJson(Map<String, dynamic> json) {
    return ChatEvent(
      meetingId: json['meetingId'] ?? '',
      type: ChatEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ChatEventType.unknown,
      ),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      data: json['data'],
    );
  }
}

/// Chat Message Types
enum ChatMessageType {
  text,
  system,
  file,
  image,
}

/// Chat Event Types
enum ChatEventType {
  userJoined,
  userLeft,
  userStartedTyping,
  userStoppedTyping,
  messageDeleted,
  messageEdited,
  unknown,
}