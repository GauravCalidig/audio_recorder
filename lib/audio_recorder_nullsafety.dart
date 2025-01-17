// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

// ignore: avoid_classes_with_only_static_members
class AudioRecorder {
  static const MethodChannel _channel = MethodChannel('audio_recorder');

  /// use [LocalFileSystem] to permit widget testing
  static LocalFileSystem fs = const LocalFileSystem();

  static Future start({
    String? path,
    AudioOutputFormat? audioOutputFormat,
  }) async {
    String extension;
    if (path != null) {
      if (audioOutputFormat != null) {
        if (_convertStringInAudioOutputFormat(p.extension(path)) != audioOutputFormat) {
          extension = _convertAudioOutputFormatInString(audioOutputFormat);
          path += extension;
        } else {
          extension = p.extension(path);
        }
      } else {
        if (_isAudioOutputFormat(p.extension(path))) {
          extension = p.extension(path);
        } else {
          extension = '.m4a'; // default value
          path += extension;
        }
      }
      final File file = fs.file(path);
      if (await file.exists()) {
        throw Exception('A file already exists at the path :$path');
      } else if (!await file.parent.exists()) {
        throw Exception('The specified parent directory does not exist');
      }
    } else {
      extension = '.m4a'; // default value
    }
    return _channel.invokeMethod('start', {'path': path, 'extension': extension});
  }

  static Future<Recording> stop() async {
    final Map<String, Object> response =
        Map.from(await (_channel.invokeMethod('stop') as FutureOr<Map<dynamic, dynamic>>));
    final duration = (response['duration'] ?? 1) as int;
    final Recording recording = Recording(
      duration: Duration(milliseconds: duration),
      path: response['path'].toString(),
      audioOutputFormat: _convertStringInAudioOutputFormat(response['audioOutputFormat'].toString()),
      extension: response['audioOutputFormat'].toString(),
    );
    return recording;
  }

  static Future<bool?> get isRecording async {
    final bool? isRecording = await _channel.invokeMethod('isRecording');
    return isRecording;
  }

  static Future<bool?> get hasPermissions async {
    final bool? hasPermission = await _channel.invokeMethod('hasPermissions');
    return hasPermission;
  }

  static AudioOutputFormat? _convertStringInAudioOutputFormat(String extension) {
    switch (extension) {
      case '.wav':
        return AudioOutputFormat.WAV;
      case '.mp4':
      case '.aac':
      case '.m4a':
        return AudioOutputFormat.AAC;
      default:
        return null;
    }
  }

  static bool _isAudioOutputFormat(String extension) {
    switch (extension) {
      case '.wav':
      case '.mp4':
      case '.aac':
      case '.m4a':
        return true;
      default:
        return false;
    }
  }

  static String _convertAudioOutputFormatInString(AudioOutputFormat outputFormat) {
    switch (outputFormat) {
      case AudioOutputFormat.WAV:
        return '.wav';
      case AudioOutputFormat.AAC:
        return '.m4a';
      default:
        return '.m4a';
    }
  }
}

// ignore: constant_identifier_names
enum AudioOutputFormat { AAC, WAV }

class Recording {
  // File path
  String? path;
  // File extension
  String? extension;
  // Audio duration in milliseconds
  Duration? duration;
  // Audio output format
  AudioOutputFormat? audioOutputFormat;

  Recording({this.duration, this.path, this.audioOutputFormat, this.extension});
}
