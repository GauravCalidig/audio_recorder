// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:audio_recorder_nullsafety/audio_recorder_nullsafety.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<MethodCall> log = <MethodCall>[];
  const fileName = 'audio_file';
  const extension = '.m4a';
  const duration = 1000;
  Directory tempDirectory;
  String? path;
  bool isRecording = false;
  File? file;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp();
    path = '${tempDirectory.path}/$fileName';

    const MethodChannel('audio_recorder').setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'start':
          isRecording = true;
          return null;
        case 'stop':
          isRecording = false;
          return {
            'duration': duration,
            'path': path,
            'audioOutputFormat': extension,
          };
        case 'isRecording':
          return isRecording;
        case 'hasPermissions':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    log.clear();
    if (file != null && await file!.exists()) await file!.delete();
  });

  test('should start audio recorder', () async {
    await AudioRecorder.start(
      path: path,
      audioOutputFormat: AudioOutputFormat.AAC,
    );
    expect(log, <Matcher>[
      isMethodCall(
        'start',
        arguments: <String, dynamic>{'path': path! + extension, 'extension': extension},
      ),
    ]);
    expect(isRecording, isTrue);
  });

  test('should start audio recorder with supported extension from path', () async {
    for (final supportedExtension in ['.mp4', '.aac', '.m4a']) {
      await AudioRecorder.start(
        path: path! + supportedExtension,
      );
      expect(log, <Matcher>[
        isMethodCall(
          'start',
          arguments: <String, dynamic>{'path': path! + supportedExtension, 'extension': supportedExtension},
        ),
      ]);
      expect(isRecording, isTrue);
      log.clear();
    }
  });

  test('should start audio recorder with no extension from path', () async {
    await AudioRecorder.start(
      path: path,
    );
    expect(log, <Matcher>[
      isMethodCall(
        'start',
        arguments: <String, dynamic>{'path': path! + extension, 'extension': extension},
      ),
    ]);
    expect(isRecording, isTrue);
  });

  test('should start audio recorder with unknown extension from path', () async {
    const unknownExtension = '.xxx';
    await AudioRecorder.start(
      path: path! + unknownExtension,
    );
    expect(log, <Matcher>[
      isMethodCall(
        'start',
        arguments: <String, dynamic>{'path': path! + unknownExtension + extension, 'extension': extension},
      ),
    ]);
    expect(isRecording, isTrue);
  });

  test('should throw when starting audio recorder with existing file', () async {
    file = File(path! + extension);
    await file!.writeAsString('audio content', flush: true);
    Future<void> startAudioRecorder() async {
      await AudioRecorder.start(
        path: path,
        audioOutputFormat: AudioOutputFormat.AAC,
      );
    }

    expect(startAudioRecorder(), throwsA(isInstanceOf<Exception>()));
  });

  test('should throw when starting audio recorder with no parent directory', () async {
    const badPathParent = '/xxx/$fileName$extension';
    Future<void> startAudioRecorder() async {
      await AudioRecorder.start(
        path: badPathParent,
        audioOutputFormat: AudioOutputFormat.AAC,
      );
    }

    expect(startAudioRecorder(), throwsA(isInstanceOf<Exception>()));
  });

  test('should stop audio recorder', () async {
    isRecording = true;
    final Recording recording = await AudioRecorder.stop();
    expect(recording, isInstanceOf<Recording>());
    expect(recording.path, path);
    expect(recording.duration, const Duration(milliseconds: duration));
    expect(recording.audioOutputFormat, AudioOutputFormat.AAC);
    expect(isRecording, isFalse);
  });

  test('should check recording status', () async {
    await AudioRecorder.start(
      path: path,
      audioOutputFormat: AudioOutputFormat.AAC,
    );
    expect(await AudioRecorder.isRecording, true);

    await AudioRecorder.stop();
    expect(await AudioRecorder.isRecording, false);
  });

  test('should check permissions', () async {
    final bool? hasPermissions = await AudioRecorder.hasPermissions;
    expect(hasPermissions, true);
  });
}
