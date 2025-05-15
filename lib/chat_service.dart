// chat_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models.dart';

class ChatService with ChangeNotifier {
  WebSocketChannel? _channel;
  int? _currentChatId;
  final List<Message> _messages = [];

  List<Message> get messages => List.unmodifiable(_messages);

  void connect(String senderName, String receiverName) {
    _channel = WebSocketChannel.connect(Uri.parse("ws://localhost:3000"));

    _channel!.sink.add(jsonEncode({
      'type': 'init',
      'senderName': senderName,
      'receiverName': receiverName,
    }));

    _channel!.stream.listen((event) {
      final data = jsonDecode(event);
      final incoming = IncomingData.fromJson(data);

      if (incoming.type == 'history' && incoming.messages != null) {
        _currentChatId = incoming.chatId;
        _messages.clear();
        _messages.addAll(incoming.messages!);
        notifyListeners();
      } else if (incoming.type == 'message' && incoming.message != null) {
        _messages.add(incoming.message!);
        notifyListeners();
      }
    }, onDone: () {
      print('WebSocket cerrado');
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  void sendMessage(String content, String senderName) {
    if (_channel == null || _currentChatId == null) {
      print("No WebSocket o chat no iniciado");
      return;
    }

    final message = {
      'type': 'message',
      'chatId': _currentChatId,
      'content': content,
      'senderName': senderName,
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void closeConnection() {
    _channel?.sink.close();
  }
}
