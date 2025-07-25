// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AdminAudioListenPage extends StatefulWidget {
//   final String userId;

//   const AdminAudioListenPage({Key? key, required this.userId})
//     : super(key: key);

//   @override
//   State<AdminAudioListenPage> createState() => _AdminAudioListenPageState();
// }

// class _AdminAudioListenPageState extends State<AdminAudioListenPage> {
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _remoteStream;
//   final _firestore = FirebaseFirestore.instance;
//   late Timer _videoCheckTimer;
//   bool _isVideoLive = false;

//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   final Set<String> _seenCandidateIds = {};

//   @override
//   void initState() {
//     super.initState();
//     _remoteRenderer.initialize();
//     _setupConnection();

//     _videoCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
//       final videoTracks = _remoteStream?.getVideoTracks() ?? [];
//       if (videoTracks.isNotEmpty && videoTracks.first.enabled) {
//         if (!_isVideoLive) {
//           log("📹 Video stream is active");
//           setState(() => _isVideoLive = true);
//         }
//       } else {
//         if (_isVideoLive) {
//           log("⚠️ Video stream lost");
//           setState(() => _isVideoLive = false);
//         }
//       }
//     });
//   }

//   Future<void> _setupConnection() async {
//     final config = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ],
//     };

//     _peerConnection = await createPeerConnection(config);

//     _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
//       log("🔌 Connection state changed: $state");
//       if ({
//         RTCPeerConnectionState.RTCPeerConnectionStateDisconnected,
//         RTCPeerConnectionState.RTCPeerConnectionStateFailed,
//         RTCPeerConnectionState.RTCPeerConnectionStateClosed,
//       }.contains(state)) {
//         log("🛑 Connection lost, clearing UI...");
//         setState(() {
//           _remoteStream = null;
//           _remoteRenderer.srcObject = null;
//         });
//       }
//     };

//     _peerConnection!.onTrack = (RTCTrackEvent event) {
//       log("📥 Track received: ${event.track.kind}");

//       if (event.streams.isNotEmpty && _remoteStream == null) {
//         _remoteStream = event.streams.first;
//         _remoteRenderer.srcObject = _remoteStream;
//         log("✅ Remote stream set");

//         for (var track in _remoteStream!.getTracks()) {
//           log(
//             "🔊 Track ID: ${track.id}, kind: ${track.kind}, enabled: ${track.enabled}",
//           );
//         }
//       }

//       event.track.onEnded = () {
//         log("🛑 Track ended: ${event.track.kind}");
//       };
//     };

//     _peerConnection!.onIceCandidate = (candidate) {
//       log("❄️ Local ICE candidate: ${candidate.candidate}");
//       _firestore
//           .collection('calls')
//           .doc(widget.userId)
//           .collection('calleeCandidates')
//           .add(candidate.toMap());
//     };

//     // Add both audio and video transceivers
//     await _peerConnection!.addTransceiver(
//       kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
//       init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
//     );
//     await _peerConnection!.addTransceiver(
//       kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
//       init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
//     );

//     // Get offer from Firestore
//     final roomRef = _firestore.collection('calls').doc(widget.userId);
//     final roomSnapshot = await roomRef.get();

//     if (!roomSnapshot.exists || roomSnapshot.data()?['offer'] == null) {
//       log("❌ No offer found in Firestore for user ${widget.userId}");
//       return;
//     }

//     final offer = roomSnapshot.data()!['offer'];
//     await _peerConnection!.setRemoteDescription(
//       RTCSessionDescription(offer['sdp'], offer['type']),
//     );
//     log("📥 Offer set as remote description");

//     final answer = await _peerConnection!.createAnswer();
//     await _peerConnection!.setLocalDescription(answer);
//     await roomRef.update({'answer': answer.toMap()});
//     log("📤 Answer sent to Firestore");

//     // Listen for ICE candidates from caller
//     roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
//       for (var doc in snapshot.docs) {
//         if (_seenCandidateIds.contains(doc.id)) continue;

//         _seenCandidateIds.add(doc.id);
//         final data = doc.data();
//         final candidate = RTCIceCandidate(
//           data['candidate'],
//           data['sdpMid'],
//           data['sdpMLineIndex'],
//         );
//         _peerConnection?.addCandidate(candidate);
//         log("📥 Remote ICE candidate added: ${candidate.candidate}");
//       }
//     });
//   }

//   Future<void> _triggerCameraOnSender() async {
//     final docRef = _firestore.collection('calls').doc(widget.userId);

//     final snapshot = await docRef.get();
//     final currentCamera = snapshot.data()?['camera'] ?? 'front';

//     final newCamera = currentCamera == 'rear' ? 'front' : 'rear';

//     await docRef.update({'camera': newCamera});
//     log("📸 Camera toggled to $newCamera.");
//   }

//   @override
//   void dispose() {
//     _firestore
//         .collection('calls')
//         .doc(widget.userId)
//         .update({'status': 'disconnected'})
//         .then((_) => log("📡 Status set to disconnected"))
//         .catchError((e) => log("⚠️ Failed to update status: $e"));

//     _remoteRenderer.dispose();
//     _peerConnection?.close();
//     _remoteStream?.dispose();
//     _videoCheckTimer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin: Listening & Viewing")),
//       body: Stack(
//         children: [
//           // Background: video or loading
//           _isVideoLive
//               ? SizedBox.expand(
//                   child: AspectRatio(
//                     aspectRatio: 16 / 9,
//                     child: RTCVideoView(
//                       _remoteRenderer,
//                       mirror: true,
//                       objectFit:
//                           RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
//                     ),
//                   ),
//                 )
//               : const Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(),
//                       SizedBox(height: 16),
//                       Text("Waiting for video stream..."),
//                     ],
//                   ),
//                 ),

//           // Overlay: Trigger Camera Button (bottom-right)
//           Positioned(
//             bottom: 20,
//             right: 20,
//             child: ElevatedButton.icon(
//               onPressed: _triggerCameraOnSender,
//               icon: Icon(Icons.videocam),
//               label: Text("Trigger Camera"),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 textStyle: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminAudioListenPage extends StatefulWidget {
  final String userId;

  const AdminAudioListenPage({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AdminAudioListenPage> createState() => _AdminAudioListenPageState();
}

class _AdminAudioListenPageState extends State<AdminAudioListenPage> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  final _firestore = FirebaseFirestore.instance;
  static const _channel = MethodChannel('audio_record_channel');
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String _recordingStatus = 'Not Recording';
  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _setupConnection();
  }

  //listening method.
  Future<void> _setupConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      log("🔌 PeerConnection state: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        log("🛑 Connection lost. Stopping playback.");
        setState(() {
          _remoteStream = null;
          _remoteRenderer.srcObject = null;
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      log("📥 Track event received: ${event.track.kind}");

      if (event.track.kind == 'audio') {
        event.track.onEnded = () {
          log("🛑 Audio track ended");
          setState(() {
            _remoteStream = null;
            _remoteRenderer.srcObject = null;
          });
        };

        setState(() {
          _remoteStream = event.streams.first;
          _remoteRenderer.srcObject = _remoteStream;
        });

        // 🔎 Log audio track info
        log(
          "🎧 Remote stream has ${_remoteStream!.getAudioTracks().length} audio tracks",
        );
        for (var track in _remoteStream!.getAudioTracks()) {
          log(
            "🔊 Track ID: ${track.id}, Enabled: ${track.enabled}, Muted: ${track.muted}",
          );
        }

        _peerConnection?.getReceivers().then((receivers) {
          for (var receiver in receivers) {
            log(
              "🔍 Receiver: ${receiver.track?.kind}, enabled: ${receiver.track?.enabled}",
            );
          }
        });
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      _firestore
          .collection('calls')
          .doc(widget.userId)
          .collection('calleeCandidates')
          .add(candidate.toMap());
    };

    // Read the user's offer
    final roomRef = _firestore.collection('calls').doc(widget.userId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists || roomSnapshot.data()?['offer'] == null) {
      log("❌ No offer found from user.");
      return;
    }

    final offer = roomSnapshot.data()!['offer'];

    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    log("✅ Offer set as remote description");

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await roomRef.update({'answer': answer.toMap()});
    log("✅ Sent answer to Firestore");

    // Listen for caller's ICE candidates
    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        _peerConnection?.addCandidate(
          RTCIceCandidate(
            doc['candidate'],
            doc['sdpMid'],
            doc['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  //storing methode call.
  Future<void> startRecording() async {
    final micStatus = await Permission.microphone.request();

    // Handle Android version-specific permissions
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus storageStatus;
    if (Platform.isAndroid && sdkInt >= 33) {
      storageStatus = await Permission.audio.request(); // Android 13+
    } else {
      storageStatus = await Permission.storage
          .request(); // Android 12 and below
    }

    // 🔌 Bluetooth (Android 12+)
    PermissionStatus bluetoothStatus = PermissionStatus.granted;
    if (Platform.isAndroid && sdkInt >= 31) {
      bluetoothStatus = await Permission.bluetoothConnect.request();
    }

    log('🎤 Microphone permission: $micStatus');
    log('💽 Storage/Audio permission: $storageStatus');
    log('🎧 Bluetooth permission: $bluetoothStatus');

    // All permissions granted
    if (micStatus.isGranted &&
        storageStatus.isGranted &&
        bluetoothStatus.isGranted) {
      final savePath = await _getSavePath();
      log("💾 Saving to: $savePath");

      await _channel.invokeMethod("startRecording", {"path": savePath});
      setState(() {
        _recordingStatus = "🔴 Recording started...";
      });
    }
    // Any permission permanently denied
    else if (micStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied ||
        bluetoothStatus.isPermanentlyDenied) {
      setState(() {
        _recordingStatus = "⚠️ Permission denied.";
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text(
            "Please grant microphone, storage/audio, and Bluetooth permissions from settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
    }
    // Denied (but not permanently)
    else {
      log("🙅 Permissions denied (not permanently)");
    }
  }

  Future<void> stopRecording() async {
    await _channel.invokeMethod("stopRecording");
    log("Recording stopped.");
    setState(() {
      _recordingStatus = "⏹️ Recording stopped.";
    });
  }

  Future<String> _getSavePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/my_audio.wav";
  }

  @override
  void dispose() {
    // 🔴 Mark as disconnected in Firestore
    _firestore
        .collection('calls')
        .doc(widget.userId)
        .update({'status': 'disconnected'})
        .then((_) {
          log("📡 Status updated to disconnected");
        })
        .catchError((error) {
          log("⚠️ Failed to update status: $error");
        });

    _remoteRenderer.dispose();
    _peerConnection?.close();
    _remoteStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Listening")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🎙️ Admin Audio Listener"),
          const SizedBox(height: 20),
          _remoteStream != null
              ? Center(child: Lottie.asset('assets/lottie/microphone.json'))
              : Center(
                  child: Lottie.asset(
                    'assets/lottie/No internet connection.json',
                  ),
                ),
          const SizedBox(height: 20),

          // 🔈 This invisible widget plays the audio
          SizedBox(width: 0, height: 0, child: RTCVideoView(_remoteRenderer)),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => startRecording(),
                child: const Text("Start Recording"),
              ),
              ElevatedButton(
                onPressed: () => stopRecording(),
                child: const Text("Stop Recording"),
              ),
            ],
          ),
          if (_recordingStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                _recordingStatus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
