import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Nanobot webchat client over WebSocket.
///
/// Connects to the nanobot webchat channel and sends/receives messages.
/// All incoming messages are emitted on [responses]; the UI decides how to
/// display them (progress vs final answer are both chat bubbles).
class LlmService {
  WebSocketChannel? _channel;
  final StreamController<String> _responses =
      StreamController<String>.broadcast();

  /// WebSocket URL path (appended to the page origin).
  final String wsUrl;

  LlmService({this.wsUrl = '/ws/chat'});

  /// Probe the WebSocket endpoint before entering the chat UI.
  ///
  /// The webchat server rejects invalid access keys by closing the socket
  /// immediately, so a short grace period is enough to distinguish a bad key
  /// from a healthy connection.
  static Future<void> validateAccessKey(
    String accessKey, {
    String wsUrl = '/ws/chat',
    Duration gracePeriod = const Duration(milliseconds: 1500),
  }) async {
    final origin = Uri.base;
    final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
    final query = '?access_key=${Uri.encodeComponent(accessKey)}';
    final uri = Uri.parse('$scheme://${origin.host}:${origin.port}$wsUrl$query');
    final channel = WebSocketChannel.connect(uri);
    final completer = Completer<void>();
    var settled = false;
    Timer? timer;

    void succeed() {
      if (settled) return;
      settled = true;
      timer?.cancel();
      channel.sink.close();
      completer.complete();
    }

    void fail([Object? _]) {
      if (settled) return;
      settled = true;
      timer?.cancel();
      channel.sink.close();
      completer.completeError(
        Exception('Invalid access key or WebSocket connection failed'),
      );
    }

    channel.stream.listen(
      (_) {},
      onError: fail,
      onDone: fail,
      cancelOnError: true,
    );

    timer = Timer(gracePeriod, succeed);
    return completer.future;
  }

  /// Connect to the nanobot webchat WebSocket.
  /// Derives the WS URL from the page origin (works when served by Caddy).
  /// When [accessKey] is provided it is sent as a query parameter so the
  /// channel can validate access to the deployment.
  void connect({String? accessKey}) {
    final origin = Uri.base;
    final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
    final query = accessKey != null
        ? '?access_key=${Uri.encodeComponent(accessKey)}'
        : '';
    final uri = Uri.parse('$scheme://${origin.host}:${origin.port}$wsUrl$query');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          final type = msg['type'] as String? ?? 'text';
          if (type == 'choice' || type == 'confirm' || type == 'composite') {
            // Forward the full JSON so the UI can render interactive widgets.
            _responses.add(jsonEncode(msg));
          } else {
            final content = msg['content'] as String? ?? '';
            if (content.isNotEmpty) {
              _responses.add(content);
            }
          }
        } catch (_) {}
      },
      onError: (error) {
        _responses.addError(error);
      },
      onDone: () {
        _responses.addError(Exception('WebSocket closed'));
      },
    );
  }

  /// Send a message to nanobot.
  void send(String message) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({'content': message}));
  }

  /// Stream of all incoming response messages from nanobot.
  Stream<String> get responses => _responses.stream;

  bool get isConnected => _channel != null;

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _responses.close();
  }
}
