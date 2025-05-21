// group_chat_service.dart
import 'dart:convert';
import 'package:cliente_flutter/models.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GroupChatService with ChangeNotifier {
  WebSocketChannel? _channel;
  int? _currentGroupId;
  final List<GroupMessage> _messages = [];

  List<GroupMessage> get messages => List.unmodifiable(_messages);

  void connect(String senderName, String groupId, String groupName) {
    _channel = WebSocketChannel.connect(Uri.parse("ws://localhost:3000"));
    print('conectando al WebSocket grupo...');
    _channel!.sink.add(jsonEncode({
      'type': 'group-init',
      'senderName': senderName,
      'groupId': groupId,
      'groupName': groupName,
    }));

    _channel!.stream.listen((event) {
      print('Mensaje recibido del WebSocket grupo: $event');
      final data = jsonDecode(event);
      final incoming = IncomingGroupData.fromJson(data);

      if (incoming.type == 'group-history' && incoming.messages != null) {
        _currentGroupId = incoming.groupId;
        _messages.clear();
        _messages.addAll(incoming.messages!);
        notifyListeners();
        print("Mensajes del grupo: ${incoming.messages}");
      } else if (incoming.type == 'group-message' && incoming.message != null) {
        _messages.add(incoming.message!);
        notifyListeners();
      }
    }, onDone: () {
      print('WebSocket grupo cerrado');
    }, onError: (error) {
      print('WebSocket error grupo: $error');
    });
  }

  void sendMessage(String content, String senderName) {
    if (_channel == null || _currentGroupId == null) {
      print("WebSocket no conectado o grupo no iniciado");
      return;
    }

    final message = {
      'type': 'group-message',
      'groupId': _currentGroupId,
      'content': content,
      'senderName': senderName,
      'groupName': 'grupo-general', // si es dinámico, cámbialo
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void closeConnection() {
    _channel?.sink.close();
  }
}
