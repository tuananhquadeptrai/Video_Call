import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import './participant_tile.dart';
import './meeting_controls.dart'; // 👈 nhớ import file này nếu chưa

class MeetingScreen extends StatefulWidget {
  final String meetingId;
  final String token;
  final String userName;

  const MeetingScreen({
    super.key,
    required this.meetingId,
    required this.token,
    required this.userName,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late Room _room;
  bool micEnabled = true;
  bool camEnabled = true;

  Map<String, Participant> participants = {};

  @override
  void initState() {
    super.initState(); // 👈 best practice: gọi trước

    // create room
    _room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: widget.userName,
      micEnabled: micEnabled,
      camEnabled: camEnabled,
      defaultCameraIndex: kIsWeb ? 0 : 1,
    );

    setMeetingEventListener();

    // Join room
    _room.join();
  }

  // listening to meeting events
  void setMeetingEventListener() {
    _room.on(Events.roomJoined, () {
      setState(() {
        participants[_room.localParticipant.id] = _room.localParticipant;
      });
    });

    _room.on(Events.participantJoined, (Participant participant) {
      setState(() {
        participants[participant.id] = participant;
      });
    });

    _room.on(Events.participantLeft, (
      String participantId,
      Map<String, dynamic> reason,
    ) {
      if (participants.containsKey(participantId)) {
        setState(() {
          participants.remove(participantId);
        });
      }
    });

    _room.on(Events.roomLeft, () {
      participants.clear();
      Navigator.popUntil(context, ModalRoute.withName('/'));
    });
  }

  // on back button pressed -> leave the room
  Future<bool> _onWillPop() async {
    _room.leave();
    return true;
  }

  // Calculate optimal grid layout based on participant count
  int _getCrossAxisCount() {
    int count = participants.length;
    if (count <= 1) return 1;
    if (count <= 4) return 2;
    if (count <= 9) return 3;
    return 4; // Maximum 4 columns for very large meetings
  }

  double _getAspectRatio() {
    int count = participants.length;
    if (count == 1) return 9 / 16; // Portrait for single participant
    if (count <= 4) return 4 / 3;  // Slightly taller for small groups
    return 1.0; // Square for larger groups
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _room.leave(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Video Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${participants.length} người tham gia',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    Colors.black,
                  ],
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60), // Space for AppBar
                  
                  // Participants grid
                  Expanded(
                    child: participants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Đang chờ người tham gia...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getCrossAxisCount(),
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: _getAspectRatio(),
                              ),
                              itemBuilder: (context, index) {
                                final participant = participants.values.elementAt(index);
                                return ParticipantTile(
                                  key: Key(participant.id),
                                  participant: participant,
                                );
                              },
                              itemCount: participants.length,
                            ),
                          ),
                  ),
                  
                  // Controls at bottom
                  MeetingControls(
                    meetingId: widget.meetingId,
                    micEnabled: micEnabled,
                    camEnabled: camEnabled,
                    onToggleMicButtonPressed: () {
                      setState(() {
                        micEnabled ? _room.muteMic() : _room.unmuteMic();
                        micEnabled = !micEnabled;
                      });
                    },
                    onToggleCameraButtonPressed: () {
                      setState(() {
                        camEnabled ? _room.disableCam() : _room.enableCam();
                        camEnabled = !camEnabled;
                      });
                    },
                    onLeaveButtonPressed: () {
                      _room.leave();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
