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

  @override
  void initState() {
    super.initState();
    _setupConnection();
  }

  Future<void> _setupConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print("📥 Track event received: ${event.track.kind}");
      if (event.track.kind == 'audio') {
        setState(() {
          _remoteStream = event.streams.first;
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

    // Add transceiver to receive audio
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

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
    _peerConnection?.close();
    _remoteStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Listening")),
      body: Center(
        child: _remoteStream != null
            ? const Text("🔊 Receiving live audio...")
            : const Text("⏳ Waiting for user to start streaming..."),
      ),
    );
  }
}
