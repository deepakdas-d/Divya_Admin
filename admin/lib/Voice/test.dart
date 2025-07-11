import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioTestPage extends StatelessWidget {
  final AudioPlayer _player = AudioPlayer();

  AudioTestPage({super.key});

  void _playTestAudio() async {
    // Play a public MP3 test file from the internet
    const url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    await _player.play(UrlSource(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Playback Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: _playTestAudio,
          child: const Text("🔊 Play Test Audio"),
        ),
      ),
    );
  }
}
