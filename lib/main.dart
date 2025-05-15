import 'dart:convert';
import 'dart:io';

import 'package:cliente_flutter/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatService(),
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
  final _messageController = TextEditingController();

  WebSocketChannel? _channel;
  List<Map<String, dynamic>> messages = [];

  String? sessionUser;
  String? currentUser;

  void startChat() {
    final sender = _senderController.text.trim();
    final receiver = _receiverController.text.trim();

    if (sender.isEmpty || receiver.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.connect(sender, receiver);


    setState(() {
      sessionUser = sender;
      currentUser = receiver;
    });

  }

  void sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || sessionUser == null) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(content, sessionUser!);

    _messageController.clear();
  }


  void logoutChat() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.closeConnection();
    setState(() {
      sessionUser = null;
      currentUser = null;
    });
  }

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final messages = chatService.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(sessionUser != null ? 'Chat con $currentUser' : 'Iniciar Chat'),
        actions: [
          if (sessionUser != null)
            Padding(padding: EdgeInsets.only(right: 25, top: 20),
            child: TextButton(
                onPressed: logoutChat,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                ),
                child: const Text('Salir', style: TextStyle(color: Colors.white)),
              ),
            ),

        ],
      ),
      body: sessionUser == null
          ? Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(labelText: 'Tu nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _receiverController,
              decoration: const InputDecoration(labelText: 'Nombre del receptor'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startChat,
              child: const Text('Iniciar Chat'),
            ),
          ],
        ),
      )
          : Column(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.content,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
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
                  child:
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),

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
      ),
    );
  }
}