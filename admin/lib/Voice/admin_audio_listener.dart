import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _setupConnection();
  }

  Future<void> _setupConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print("🔌 PeerConnection state: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        print("🛑 Connection lost. Stopping playback.");
        setState(() {
          _remoteStream = null;
          _remoteRenderer.srcObject = null;
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print("📥 Track event received: ${event.track.kind}");

      if (event.track.kind == 'audio') {
        event.track.onEnded = () {
          print("🛑 Audio track ended");
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
        print(
          "🎧 Remote stream has ${_remoteStream!.getAudioTracks().length} audio tracks",
        );
        for (var track in _remoteStream!.getAudioTracks()) {
          print(
            "🔊 Track ID: ${track.id}, Enabled: ${track.enabled}, Muted: ${track.muted}",
          );
        }

        _peerConnection?.getReceivers().then((receivers) {
          for (var receiver in receivers) {
            print(
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
      print("❌ No offer found from user.");
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
    print("✅ Offer set as remote description");

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await roomRef.update({'answer': answer.toMap()});
    print("✅ Sent answer to Firestore");

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

  @override
  void dispose() {
    // 🔴 Mark as disconnected in Firestore
    _firestore
        .collection('calls')
        .doc(widget.userId)
        .update({'status': 'disconnected'})
        .then((_) {
          print("📡 Status updated to disconnected");
        })
        .catchError((error) {
          print("⚠️ Failed to update status: $error");
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
              ? const Text("🔊 Receiving live audio...")
              : const Text("⏳ Waiting for user to start streaming..."),
          const SizedBox(height: 20),

          // 🔈 This invisible widget plays the audio
          SizedBox(width: 0, height: 0, child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}
