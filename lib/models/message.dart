class Message {
  final int id;
  final int postId;
  final int buyerId;
  final int senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.postId,
    required this.buyerId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: int.parse(json['id'].toString()),
      postId: int.parse(json['post_id'].toString()),
      buyerId: int.parse(json['buyer_id'].toString()),
      senderId: int.parse(json['sender_id'].toString()),
      senderName: json['sender_name'] as String? ?? '',
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
