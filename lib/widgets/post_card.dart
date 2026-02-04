import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/post.dart';

const String apiBaseUrl =
    'https://expressless-reena-suably.ngrok-free.dev/app_api';

String? buildImageUrl(String? imageUrl) {
  if (imageUrl == null) return null;

  imageUrl = imageUrl.trim();

  if (imageUrl.isEmpty || imageUrl == '-' || imageUrl == 'null') {
    return null;
  }

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }

  if (imageUrl.startsWith('/')) {
    return '$apiBaseUrl$imageUrl';
  }
  return '$apiBaseUrl/$imageUrl';
}

/// แสดงรูปจาก base64 ถ้ามี, ถ้าไม่มีค่อย fallback ไป URL, ถ้าไม่มีอีกแสดง icon
Widget _buildPostImage(Post post, String? fullImageUrl) {
  debugPrint(
      'DBG_IMG id=${post.id} base64Len=${post.imageBase64?.length} fullUrl=$fullImageUrl');

  if (post.imageBase64 != null &&
      post.imageBase64!.isNotEmpty &&
      post.imageBase64 != 'null') {
    try {
      Uint8List bytes = base64Decode(post.imageBase64!);
      debugPrint('DBG_IMG decode ok, bytes=${bytes.length}');
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) {
          debugPrint('DBG_IMG Image.memory error=$err');
          return _fallbackImage();
        },
      );
    } catch (e, st) {
      debugPrint('DBG_IMG decode exception=$e\n$st');
    }
  }

  // 2) fallback: URL (ไว้ใช้อนาคตถ้าไม่ได้ใช้ ngrok แล้ว)
  if (fullImageUrl != null && fullImageUrl.isNotEmpty) {
    return Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _fallbackImage(),
    );
  }

  // 3) ไม่มีอะไรเลย
  return _fallbackImage();
}

Widget _fallbackImage() {
  return Container(
    color: const Color(0xFF2F1847),
    child: const Icon(
      Icons.videogame_asset,
      color: Colors.white54,
    ),
  );
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF24103C);
    const accentPink = Color(0xFFFF4E87);
    const accentOrange = Color(0xFFFFA000);

    final fullImageUrl = buildImageUrl(post.imageUrl);
    debugPrint(
      'POST_CARD id=${post.id} raw="${post.imageUrl}" full=$fullImageUrl '
      'hasBase64=${post.imageBase64 != null && post.imageBase64!.isNotEmpty}',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // รูปไอดีเกมด้านซ้าย
            Container(
              width: 130,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPostImage(post, fullImageUrl),
            ),

            // ข้อมูลด้านขวา
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.gameName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.price.toStringAsFixed(0)}฿',
                          style: const TextStyle(
                            color: accentOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(0xFF352052),
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  post.sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB9A9D9),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentPink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'ดูรายละเอียด',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
