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
        // 单次失败容易被瞬时 TLS reset / NAT 抖动撞上（典型错误：
        // `HandshakeException: Connection terminated during handshake`），
        // 失败一锤定音 + Flutter ImageCache 还会把失败标记缓存，
        // 导致同一张图后续都加载不出来。这里做 1 次重试，间隔 600ms，
        // 能吃掉 99% 的临时握手失败。
        final Uint8List bytes = await _fetchImageBytes(
          resolved,
          maxAttempts: 2,
          onProgress: (cumulative, total) {
            sendPort.send((id, (cumulative, total)));
          },
        );

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

  /// 拉单张图片字节，自带重试。每次都用全新 HttpClient 并 force-close，
  /// 避免 isolate 里上一次失败连接的 TLS 状态残留到下一次。
  static Future<Uint8List> _fetchImageBytes(
    Uri resolved, {
    required int maxAttempts,
    required void Function(int cumulative, int? total) onProgress,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final httpClient = HttpClient()
        ..autoUncompress = false
        ..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await httpClient.getUrl(resolved);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<List<int>>(<int>[]);
          throw NetworkImageLoadException(
              statusCode: response.statusCode, uri: resolved);
        }
        final bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: onProgress,
        );
        if (bytes.lengthInBytes == 0) {
          throw Exception('NetworkImage is an empty file: $resolved');
        }
        return bytes;
      } catch (e) {
        lastError = e;
        // HTTP 状态错（4xx/5xx）没必要重试，直接抛。
        if (e is NetworkImageLoadException) rethrow;
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      } finally {
        httpClient.close(force: true);
      }
    }
    throw lastError ?? Exception('image fetch failed: $resolved');
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
