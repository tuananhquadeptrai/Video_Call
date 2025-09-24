import 'package:flutter/material.dart';
import 'api_call.dart';
import 'meeting_screen.dart';
import 'services/azure_auth_service.dart';
import 'services/azure_meeting_service.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _meetingIdController = TextEditingController();
  final _nameController = TextEditingController();
  final AzureAuthService _authService = AzureAuthService();
  final AzureMeetingService _meetingService = AzureMeetingService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _authService.initialize();
    await _meetingService.initialize();
  }

  @override
  void dispose() {
    _meetingIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> onCreateButtonPressed(BuildContext context) async {
    String userName = _nameController.text.trim();
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên của bạn"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create meeting - this will return a VideoSDK roomId for now
      print('📞 Creating meeting for user: $userName');
      final meetingId = await createMeeting();
      print('✅ Meeting created with ID: $meetingId');

      if (!context.mounted) return;

      // For VideoSDK meetings, always use the same token
      print('🚀 Navigating to meeting screen...');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeetingScreen(
            meetingId: meetingId,
            token: token, // Always use VideoSDK token for consistency
            userName: userName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi tạo cuộc gọi: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> onJoinButtonPressed(BuildContext context) async {
    String meetingId = _meetingIdController.text.trim();
    String userName = _nameController.text.trim();
    var re = RegExp("\\w{4}\\-\\w{4}\\-\\w{4}");

    // Check if name is entered
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên của bạn"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // check meeting id is not null or invalid
    if (meetingId.isEmpty || !re.hasMatch(meetingId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập Meeting ID hợp lệ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For VideoSDK, we just join with the same meetingId and token
      print('🔗 Joining meeting ID: $meetingId for user: $userName');

      if (!context.mounted) return;

      _meetingIdController.clear();

      print('🚀 Navigating to join meeting screen...');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeetingScreen(
            meetingId: meetingId,
            token: token, // Use consistent VideoSDK token
            userName: userName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi tham gia cuộc gọi: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade700],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_call,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Video Call App',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kết nối và trò chuyện với mọi người',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main actions
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name input for both create and join
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập tên của bạn',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      // Create meeting button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => onCreateButtonPressed(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Tạo cuộc gọi mới',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'HOẶC',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // User input section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Meeting ID input field
                            TextField(
                              controller: _meetingIdController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Nhập Meeting ID (vd: 1234-5678-9012)',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                prefixIcon: Icon(
                                  Icons.meeting_room,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Join button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => onJoinButtonPressed(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue.shade700,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tham gia cuộc gọi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Powered by VideoSDK',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
