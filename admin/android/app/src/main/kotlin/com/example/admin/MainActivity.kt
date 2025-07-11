package com.techfifo.admin

import android.content.Context
import android.media.AudioManager
import android.media.AudioDeviceInfo
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.techfifo.audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSpeaker" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        
                        // Log initial state
                        logAudioState("BEFORE", audioManager)
                        
                        // Save current state
                        val modeBefore = audioManager.mode
                        val speakerBefore = audioManager.isSpeakerphoneOn
                        
                        // Method 1: Set mode to NORMAL first (reset any previous state)
                        audioManager.mode = AudioManager.MODE_NORMAL
                        Thread.sleep(100) // Small delay to ensure mode change takes effect
                        
                        // Method 2: Set to COMMUNICATION mode for VoIP
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        Thread.sleep(100)
                        
                        // Method 3: Force speakerphone on
                        audioManager.isSpeakerphoneOn = true
                        Thread.sleep(100)
                        
                        // Method 4: Set volume to reasonable level
                        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
                        val targetVolume = (maxVolume * 0.8).toInt() // 80% of max volume
                        
                        if (currentVolume < targetVolume) {
                            audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL, targetVolume, 0)
                            Log.d("AUDIO_ROUTE", "🔊 Volume set to $targetVolume (max: $maxVolume)")
                        }
                        
                        // Method 5: Try setting audio mode to COMMUNICATION_REDIRECT if available
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                            try {
                                // This is a more aggressive approach for newer Android versions
                                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                                audioManager.isSpeakerphoneOn = true
                                Log.d("AUDIO_ROUTE", "🔊 Advanced speaker routing attempted")
                            } catch (e: Exception) {
                                Log.w("AUDIO_ROUTE", "Advanced routing failed: ${e.message}")
                            }
                        }
                        
                        // Method 6: Check available audio devices
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                            Log.d("AUDIO_ROUTE", "Available audio devices:")
                            for (device in audioDevices) {
                                val deviceType = when (device.type) {
                                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "Built-in Speaker"
                                    AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "Built-in Earpiece"
                                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Wired Headphones"
                                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "Bluetooth A2DP"
                                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "Bluetooth SCO"
                                    else -> "Other (${device.type})"
                                }
                                Log.d("AUDIO_ROUTE", "  - $deviceType: ${device.productName}")
                            }
                        }
                        
                        // Get final state
                        val modeAfter = audioManager.mode
                        val speakerAfter = audioManager.isSpeakerphoneOn
                        
                        // Log final state
                        logAudioState("AFTER", audioManager)
                        
                        Log.d("AUDIO_ROUTE", "🔊 AudioManager state changed:")
                        Log.d("AUDIO_ROUTE", "Mode: $modeBefore ➜ $modeAfter")
                        Log.d("AUDIO_ROUTE", "Speakerphone: $speakerBefore ➜ $speakerAfter")
                        
                        // Additional checks
                        if (!speakerAfter) {
                            Log.e("AUDIO_ROUTE", "⚠️ WARNING: Speakerphone is still OFF after attempts!")
                        }
                        
                        if (modeAfter != AudioManager.MODE_IN_COMMUNICATION) {
                            Log.e("AUDIO_ROUTE", "⚠️ WARNING: Audio mode is not COMMUNICATION mode!")
                        }
                        
                        result.success("Speaker enabled successfully")
                    } catch (e: Exception) {
                        Log.e("AUDIO_ROUTE", "❌ Error enabling speakerphone", e)
                        result.error("SPEAKER_ERROR", "Failed to enable speaker: ${e.message}", null)
                    }
                }
                "checkAudioState" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        logAudioState("CURRENT", audioManager)
                        result.success("Audio state logged")
                    } catch (e: Exception) {
                        Log.e("AUDIO_ROUTE", "❌ Error checking audio state", e)
                        result.error("AUDIO_CHECK_ERROR", "Failed to check audio state: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun logAudioState(prefix: String, audioManager: AudioManager) {
        Log.d("AUDIO_ROUTE", "=== $prefix AUDIO STATE ===")
        Log.d("AUDIO_ROUTE", "Mode: ${getAudioModeString(audioManager.mode)}")
        Log.d("AUDIO_ROUTE", "Speakerphone: ${audioManager.isSpeakerphoneOn}")
        Log.d("AUDIO_ROUTE", "Music active: ${audioManager.isMusicActive}")
        Log.d("AUDIO_ROUTE", "Microphone muted: ${audioManager.isMicrophoneMute}")
        
        // Volume levels
        val musicVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val musicMaxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val voiceCallVolume = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
        val voiceCallMaxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
        
        Log.d("AUDIO_ROUTE", "Music volume: $musicVolume / $musicMaxVolume")
        Log.d("AUDIO_ROUTE", "Voice call volume: $voiceCallVolume / $voiceCallMaxVolume")
        
        // Check for audio focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val audioFocusRequest = audioManager.requestAudioFocus(
                    null, AudioManager.STREAM_VOICE_CALL, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
                Log.d("AUDIO_ROUTE", "Audio focus request result: $audioFocusRequest")
            } catch (e: Exception) {
                Log.e("AUDIO_ROUTE", "Failed to request audio focus: ${e.message}")
            }
        }
    }
    
    private fun getAudioModeString(mode: Int): String {
        return when (mode) {
            AudioManager.MODE_NORMAL -> "NORMAL"
            AudioManager.MODE_RINGTONE -> "RINGTONE"
            AudioManager.MODE_IN_CALL -> "IN_CALL"
            AudioManager.MODE_IN_COMMUNICATION -> "IN_COMMUNICATION"
            else -> "UNKNOWN ($mode)"
        }
    }
}