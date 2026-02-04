class ChatItem {
  final int postId;
  final int buyerId;
  final String postTitle;
  final String partnerName; // buyer หรือ seller
  final String lastText;
  final DateTime lastTime;

  ChatItem({
    required this.postId,
    required this.buyerId,
    required this.postTitle,
    required this.partnerName,
    required this.lastText,
    required this.lastTime,
  });

  factory ChatItem.fromBuyerJson(Map<String, dynamic> json) {
    return ChatItem(
      postId: int.parse(json['post_id'].toString()),
      buyerId: int.parse(json['buyer_id'].toString()),
      postTitle: (json['post_title'] ?? '') as String,
      partnerName: (json['seller_name'] ?? '') as String,
      lastText: (json['last_text'] ?? '') as String,
      lastTime: DateTime.parse(json['last_time'] as String),
    );
  }

  factory ChatItem.fromSellerJson(Map<String, dynamic> json) {
    return ChatItem(
      postId: int.parse(json['post_id'].toString()),
      buyerId: int.parse(json['buyer_id'].toString()),
      postTitle: (json['post_title'] ?? '') as String,
      partnerName: (json['buyer_name'] ?? '') as String,
      lastText: (json['last_text'] ?? '') as String,
      lastTime: DateTime.parse(json['last_time'] as String),
    );
  }
}
