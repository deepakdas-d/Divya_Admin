package com.techfifo.admin

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_record_channel"
    private var wavRecorder: WavAudioRecorder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        if (wavRecorder == null) wavRecorder = WavAudioRecorder()
                        wavRecorder?.startRecording(this)
                        result.success("Started WAV recording")
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }

                "stopRecording" -> {
                    wavRecorder?.stopRecording()
                    wavRecorder = null
                    result.success("Stopped recording")
                }

                else -> result.notImplemented()
            }
        }
    }
}
