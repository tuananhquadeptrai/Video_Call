import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeetingControls extends StatelessWidget {
  final void Function() onToggleMicButtonPressed;
  final void Function() onToggleCameraButtonPressed;
  final void Function() onLeaveButtonPressed;
  final void Function()? onCopyMeetingId;
  final bool micEnabled;
  final bool camEnabled;
  final String? meetingId;

  const MeetingControls({
    super.key,
    required this.onToggleMicButtonPressed,
    required this.onToggleCameraButtonPressed,
    required this.onLeaveButtonPressed,
    this.onCopyMeetingId,
    this.micEnabled = true,
    this.camEnabled = true,
    this.meetingId,
  });

  void _copyMeetingId(BuildContext context) {
    if (meetingId != null) {
      Clipboard.setData(ClipboardData(text: meetingId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Meeting ID đã được copy: $meetingId'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Meeting ID row with copy button
          if (meetingId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: $meetingId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _copyMeetingId(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Microphone toggle
              _buildControlButton(
                icon: micEnabled ? Icons.mic : Icons.mic_off,
                onPressed: onToggleMicButtonPressed,
                isActive: micEnabled,
                activeColor: Colors.white,
                inactiveColor: Colors.red,
              ),
              
              // Camera toggle
              _buildControlButton(
                icon: camEnabled ? Icons.videocam : Icons.videocam_off,
                onPressed: onToggleCameraButtonPressed,
                isActive: camEnabled,
                activeColor: Colors.white,
                inactiveColor: Colors.red,
              ),
              
              // Copy meeting ID (if callback provided)
              if (onCopyMeetingId != null)
                _buildControlButton(
                  icon: Icons.copy,
                  onPressed: () => _copyMeetingId(context),
                  isActive: true,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue,
                ),
              
              // Leave meeting
              _buildControlButton(
                icon: Icons.call_end,
                onPressed: onLeaveButtonPressed,
                isActive: true,
                activeColor: Colors.red,
                inactiveColor: Colors.red,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: isActive ? activeColor.withValues(alpha: 0.2) : inactiveColor.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
