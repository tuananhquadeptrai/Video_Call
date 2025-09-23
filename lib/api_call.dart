import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/azure_meeting_service.dart';
import 'services/azure_auth_service.dart';

// Auth token used to create/join meetings. Replace with your real token.
// Note: remove any angle brackets and keep it as a plain string.
String token =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiJjNGY1NDk0Yy01YTgzLTRlMTItOTdmOS03YTI0N2I4ODA3MzUiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTc1ODI5MTk5MiwiZXhwIjoxNzU4ODk2NzkyfQ.so7JiiLWczVAL8XVbwhLyP_4IzXZiTjUshii2ubYzro";

// Azure services
final AzureMeetingService _meetingService = AzureMeetingService();
final AzureAuthService _authService = AzureAuthService();

// API call to create meeting using Azure Communication Services
Future<String> createMeeting() async {
  try {
    // Initialize services if not already done
    await _meetingService.initialize();
    await _authService.initialize();

    // Try to create meeting with Azure first
    if (_authService.isAuthenticated) {
      final response = await _meetingService.createMeeting(
        meetingTitle: 'Video Call Meeting',
        recordingEnabled: false,
        maxParticipants: 50,
      );

      if (response.success && response.data != null) {
        return response.data!.meetingId;
      }
    }

    // Fallback to VideoSDK for demo purposes
    return await _createVideoSDKMeeting();
  } catch (e) {
    // Fallback to VideoSDK if Azure fails
    return await _createVideoSDKMeeting();
  }
}

// Fallback VideoSDK meeting creation
Future<String> _createVideoSDKMeeting() async {
  final http.Response httpResponse = await http.post(
    Uri.parse("https://api.videosdk.live/v2/rooms"),
    headers: {'Authorization': token},
  );

  //Destructuring the roomId from the response
  return json.decode(httpResponse.body)['roomId'];
}

// Join meeting using Azure Communication Services
Future<MeetingInfo?> joinAzureMeeting(String meetingId) async {
  try {
    await _meetingService.initialize();
    await _authService.initialize();

    if (_authService.isAuthenticated) {
      final response = await _meetingService.joinMeeting(meetingId);

      if (response.success && response.data != null) {
        return response.data;
      }
    }

    return null;
  } catch (e) {
    return null;
  }
}
