package com.techfifo.admin

import android.content.Context
import android.media.*
import android.util.Log
import java.io.*

class WavAudioRecorder {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private lateinit var recordingThread: Thread
    private lateinit var wavFile: File
    private lateinit var wavOut: DataOutputStream
    private var totalAudioLen = 0

    private val sampleRate = 44100
    private val channels = 1
    private val bitsPerSample = 16

    fun startRecording(context: Context) {
    Log.d("AudioRecord", "Starting recording...")

    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    val folder = File(context.getExternalFilesDir(null), "salesperson")
    if (!folder.exists()) {
        val created = folder.mkdirs()
        Log.d("AudioRecord", "Created folder: ${folder.absolutePath}, success: $created")
    } else {
        Log.d("AudioRecord", "Using existing folder: ${folder.absolutePath}")
    }

    wavFile = File(folder, "recorded_audio.wav")
    Log.d("AudioRecord", "Output file: ${wavFile.absolutePath}")

    wavOut = DataOutputStream(BufferedOutputStream(FileOutputStream(wavFile)))
    writeWavHeader(wavOut)
    Log.d("AudioRecord", "WAV header written")

    audioRecord = AudioRecord(
        MediaRecorder.AudioSource.MIC, // Use MIC instead
        sampleRate,
        channelConfig,
        audioFormat,
        bufferSize
    )

    isRecording = true
    audioRecord?.startRecording()
    Log.d("AudioRecord", "AudioRecord started")

    recordingThread = Thread {
        val buffer = ByteArray(bufferSize)
        while (isRecording) {
            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
            if (read > 0) {
                totalAudioLen += read
                wavOut.write(buffer, 0, read)
                Log.d("AudioRecord", "Read $read bytes")
            } else {
                Log.e("AudioRecord", "No data read: $read")
            }
        }
        Log.d("AudioRecord", "Recording thread stopped")
    }
    recordingThread.start()
}

fun stopRecording() {
    Log.d("AudioRecord", "Stopping recording...")
    isRecording = false

    try {
        audioRecord?.stop()
        audioRecord?.release()
        recordingThread.join()
        wavOut.close()
        Log.d("AudioRecord", "Total audio length: $totalAudioLen")
        updateWavHeader(wavFile, totalAudioLen)
        Log.d("AudioRecord", "WAV file saved at: ${wavFile.absolutePath}, size: ${wavFile.length()} bytes")
    } catch (e: Exception) {
        Log.e("AudioRecord", "Error during stopRecording: ${e.message}")
    }
}
    
    private fun writeWavHeader(out: DataOutputStream) {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        out.writeBytes("RIFF")
        out.writeIntLE(0) // Placeholder
        out.writeBytes("WAVE")
        out.writeBytes("fmt ")
        out.writeIntLE(16)
        out.writeShortLE(1.toShort()) // PCM
        out.writeShortLE(channels.toShort())
        out.writeIntLE(sampleRate)
        out.writeIntLE(byteRate)
        out.writeShortLE((channels * bitsPerSample / 8).toShort())
        out.writeShortLE(bitsPerSample.toShort())
        out.writeBytes("data")
        out.writeIntLE(0) // Placeholder
    }

    private fun updateWavHeader(file: File, audioDataSize: Int) {
        val randomAccessFile = RandomAccessFile(file, "rw")
        val totalDataLen = 36 + audioDataSize
        randomAccessFile.seek(4)
        randomAccessFile.writeIntLE(totalDataLen)
        randomAccessFile.seek(40)
        randomAccessFile.writeIntLE(audioDataSize)
        randomAccessFile.close()
    }

    private fun DataOutputStream.writeIntLE(value: Int) {
        write(value and 0xff)
        write(value shr 8 and 0xff)
        write(value shr 16 and 0xff)
        write(value shr 24 and 0xff)
    }

    private fun DataOutputStream.writeShortLE(value: Short) {
        write(value.toInt() and 0xff)
        write(value.toInt() shr 8 and 0xff)
    }

    private fun RandomAccessFile.writeIntLE(value: Int) {
        write(value and 0xff)
        write(value shr 8 and 0xff)
        write(value shr 16 and 0xff)
        write(value shr 24 and 0xff)
    }
}
