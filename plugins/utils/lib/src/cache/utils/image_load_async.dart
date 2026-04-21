import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';
import 'dart:ui' as ui show Codec;

import '../../../utils.dart';
import 'image_decrypt.dart';

_Worker? _worker;
Completer? _completer;

Future<ui.Codec> imageLoadAsync(
  NetworkImage key,
  String cacheKey,
  StreamController<ImageChunkEvent> chunkEvents,
  Future<ui.Codec> Function(Uint8List buffer) decode,
  String hivePath,
  String boxKey,
) async {
  if (_worker == null) {
    if (_completer == null) {
      _completer = Completer();
      _worker = await _Worker.spawn();
      _completer?.complete();
    } else {
      await _completer?.future;
    }
  }

  try {
    final data = await _worker!
        .fetchImage(key.url, cacheKey, hivePath, boxKey, chunkEvents);
    return decode(data);
  } catch (e) {
    scheduleMicrotask(() {
      PaintingBinding.instance.imageCache.evict(key);
    });
    rethrow;
  } finally {
    chunkEvents.close();
  }
}

class _Worker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Uint8List>> _activeRequests = {};
  final Map<int, StreamController<ImageChunkEvent>> _chunkEvents = {};

  int _idCounter = 0;
  bool _closed = false;

  Future<Uint8List> fetchImage(String url, String cacheKey, String hivePath,
      String boxKey, StreamController<ImageChunkEvent> chunkEventsStream) {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Uint8List>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _chunkEvents[id] = chunkEventsStream;
    _commands.send((id, cacheKey, hivePath, boxKey, url));
    return completer.future;
  }

  static Future<_Worker> spawn() async {
    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return _Worker._(receivePort, sendPort);
  }

  _Worker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is (int, (int, int?))) {
      final (int id, (int cumulative, int? total)) = message;
      final chunkEvents = _chunkEvents[id]!;

      chunkEvents.add(ImageChunkEvent(
        cumulativeBytesLoaded: cumulative,
        expectedTotalBytes: total,
      ));
      return;
    }

    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;
    _chunkEvents.remove(id)!;
    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response as Uint8List);
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (
        int id,
        String cacheKey,
        String hivePath,
        String boxKey,
        String url
      ) = message as (int, String, String, String, String);
      try {
        final Uri resolved = Uri.base.resolve(url);

        final httpClient = HttpClient()..autoUncompress = false;

        final HttpClientRequest request = await httpClient.getUrl(resolved);

        final HttpClientResponse response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<List<int>>(<int>[]);
          throw NetworkImageLoadException(
              statusCode: response.statusCode, uri: resolved);
        }

        final Uint8List bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (int cumulative, int? total) {
            sendPort.send((id, (cumulative, total)));
          },
        );
        if (bytes.lengthInBytes == 0) {
          throw Exception('NetworkImage is an empty file: $resolved');
        }
        final decrypted = await imageDecrypt(bytes);

        try {
          Hive.init(hivePath);
          final cacheBox = await Hive.openLazyBox(boxKey);
          await cacheBox.put(cacheKey, decrypted);
        } catch (_) {}

        sendPort.send((id, decrypted));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
    }
  }
}
