// models.dart

class User {
  final int? id;
  final String userName;

  User({this.id, required this.userName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'userName': userName,
  };
}

class Chat {
  final int id;
  final User user1;
  final User user2;

  Chat({required this.id, required this.user1, required this.user2});

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      user1: User.fromJson(json['user1']),
      user2: User.fromJson(json['user2']),
    );
  }
}

class Message {
  final int id;
  final String content;
  final DateTime createdAt;
  final String senderName;
  final int? chatId;

  Message({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.senderName,
    this.chatId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      senderName: json['senderName'],
      chatId: json['chatId'],
    );
  }
}

class IncomingData {
  final String type;
  final List<Message>? messages;
  final Message? message;
  final int? chatId;

  IncomingData({
    required this.type,
    this.messages,
    this.message,
    this.chatId,
  });

  factory IncomingData.fromJson(Map<String, dynamic> json) {
    return IncomingData(
      type: json['type'],
      messages: json['messages'] != null
          ? List<Message>.from(
          json['messages'].map((msg) => Message.fromJson(msg)))
          : null,
      message:
      json['message'] != null ? Message.fromJson(json['message']) : null,
      chatId: json['chatId'],
    );
  }
}
