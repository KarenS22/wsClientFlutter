import 'dart:convert';
import 'dart:io';

import 'package:cliente_flutter/chat_service.dart';
import 'package:cliente_flutter/group_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => GroupChatService()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  final _groupIdController = TextEditingController();
  final _messageController = TextEditingController();

  WebSocketChannel? _channel;
  List<Map<String, dynamic>> messages = [];

  String? sessionUser;
  String? currentUser;

  bool isGroupChat = false;
  String groupIdInput = '';
  int? currentGroupId;
  String? groupName = '';

  String newMessage = '';

  void setChatMode(bool isGroup) {
    setState(() {
      logoutChat();
      isGroupChat = isGroup;

    });
  }


  void startChat() {
    final sender = _senderController.text.trim();
    final receiver = _receiverController.text.trim();
    if (sender.isEmpty || receiver.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.connect(sender, receiver);

    setState(() {
      sessionUser = sender;
      currentUser = receiver;
      groupName = null;
      isGroupChat = false;
    });
  }

  void startGroupChat() {
    final sender = _senderController.text.trim();
    final groupId = _groupIdController.text.trim();
    if (sender.isEmpty || groupId.isEmpty) return;

    final groupChatService = Provider.of<GroupChatService>(context, listen: false);
    groupChatService.connect(sender, groupId, "Grupo: $groupId");

    setState(() {
      sessionUser = sender;
      currentUser = null;
      groupName = "Grupo: $groupId";
      isGroupChat = true;
    });
  }


  void sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || sessionUser == null) return;

    if (isGroupChat) {
      final groupChatService =
      Provider.of<GroupChatService>(context, listen: false);
      groupChatService.sendMessage(content, sessionUser!);
    } else {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.sendMessage(content, sessionUser!);
    }

    _messageController.clear();
  }

  void logoutChat() {
    if (isGroupChat) {
      Provider.of<GroupChatService>(context, listen: false).closeConnection();
    } else {
      Provider.of<ChatService>(context, listen: false).closeConnection();
    }
    setState(() {
      sessionUser = null;
      currentUser = null;
      groupName = null;
      isGroupChat = false;
      messages = [];
      _senderController.clear();
      _receiverController.clear();
      _groupIdController.clear();
      _messageController.clear();
    });
  }



  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    _groupIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final groupChatService = Provider.of<GroupChatService>(context);

    final List messages = isGroupChat ? groupChatService.messages : chatService.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(sessionUser == null
            ? 'Selector de chat'
            : isGroupChat
            ? groupName ?? ''
            : 'Chat con $currentUser'),
        actions: sessionUser != null
            ? [
          Padding(
            padding: EdgeInsets.only(right: 100),
            child: Text(sessionUser ?? '', style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logoutChat,
            tooltip: 'Cerrar sesión',
          ),
        ]
            : null,
      ),
      body: sessionUser == null
          ? buildStartChatForm()
          : buildChatUI(messages),
    );
  }

  Widget buildStartChatForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selector modo chat y formularios (tu código actual)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setChatMode(false),
                child: Text(
                  'Chat Privado',
                  style: TextStyle(
                    fontWeight: isGroupChat ? FontWeight.normal : FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () => setChatMode(true),
                child: Text(
                  'Chat Grupal',
                  style: TextStyle(
                    fontWeight: isGroupChat ? FontWeight.bold : FontWeight.normal,
                    decoration: TextDecoration.underline,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isGroupChat) ...[
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receiverController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la persona con quien chatear',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: startChat,
              child: const Text('Iniciar chat privado'),
            ),
          ] else ...[
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: 'ID o nombre del grupo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: startGroupChat,
              child: const Text('Iniciar chat grupal'),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildChatUI(List messages) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.senderName == sessionUser;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isGroupChat)
                        Text(
                          msg.senderName,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.blueAccent,
                            fontSize: 12
                          ),
                        ),
                      Text(
                        msg.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(80)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: sendMessage,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

}