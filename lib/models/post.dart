class Post {
  final int id;
  final String gameName;
  final String title;
  final String description;
  final double price;
  final String status;
  final String? imageUrl;
  final String? imageBase64;
  final String platform;
  final String rank;
  final String sellerName;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.gameName,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.imageUrl,
    this.imageBase64,
    required this.platform,
    required this.rank,
    required this.sellerName,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: int.parse(json['id'].toString()),
      gameName: json['game_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      status: json['status'] ?? '',
      imageUrl: json['image_url'], // <<< สำคัญ
      imageBase64: json['image_base64'] as String?,
      platform: json['platform'] ?? '',
      rank: json['rank'] ?? '',
      sellerName: json['seller_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
