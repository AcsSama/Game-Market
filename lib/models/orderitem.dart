class OrderItem {
  final int id;
  final int postId;
  final String gameName;
  final String title;
  final double price;
  final String status;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.postId,
    required this.gameName,
    required this.title,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: int.parse(json['id'].toString()),
      postId: int.parse(json['post_id'].toString()),
      gameName: json['game_name'] as String,
      title: json['title'] as String,
      price: double.parse(json['price'].toString()),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
