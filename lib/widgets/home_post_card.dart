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

String _normalizeBase64(String s) {
  final idx = s.indexOf('base64,');
  if (idx != -1) {
    s = s.substring(idx + 'base64,'.length);
  }
  s = s.trim();
  s = s.replaceAll(' ', '+');
  final mod4 = s.length % 4;
  if (mod4 > 0) {
    s += '=' * (4 - mod4);
  }
  return s;
}

Widget _buildThumbImage(Post post, String? fullImageUrl) {
  // 1) base64 ก่อน
  if (post.imageBase64 != null &&
      post.imageBase64!.isNotEmpty &&
      post.imageBase64 != 'null') {
    try {
      final normalized = _normalizeBase64(post.imageBase64!);
      final bytes = base64Decode(normalized);
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          bytes,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _fallbackThumb(),
        ),
      );
    } catch (_) {
      // fall through to URL
    }
  }

  // 2) URL (เผื่ออนาคตไม่ใช้ ngrok)
  if (fullImageUrl != null && fullImageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        fullImageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _fallbackThumb(),
      ),
    );
  }

  // 3) ไม่มีรูป
  return _fallbackThumb();
}

Widget _fallbackThumb() {
  return Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF2B1846),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(
      Icons.videogame_asset,
      color: Colors.white54,
      size: 32,
    ),
  );
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final bool isOwnerView; // true เมื่อใช้บนหน้า Home ของเจ้าของโพสต์

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1A062E);
    const accentPink = Color(0xFFFF4E87);
    const accentOrange = Color(0xFFFFA000);

    final isSold = post.status.toLowerCase() == 'soldout';

    final subtitleText = isOwnerView
        ? (isSold ? 'สถานะ: มีคนซื้อแล้ว' : 'สถานะ: กำลังประกาศขาย')
        : 'ผู้ขาย: ${post.sellerName}';

    final subtitleColor =
        isOwnerView && isSold ? Colors.redAccent : const Color(0xFFB9A9D9);

    final fullImageUrl = buildImageUrl(post.imageUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildThumbImage(post, fullImageUrl),
            const SizedBox(width: 12),

            // ข้อมูลหลัก
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อโพสต์ + ราคา
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${post.price.toStringAsFixed(0)} ฿',
                        style: const TextStyle(
                          color: accentOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.gameName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            if (!isOwnerView)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSold
                      ? Colors.red.withOpacity(0.25)
                      : accentPink.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSold ? 'Sold' : 'Active',
                  style: TextStyle(
                    color: isSold ? Colors.redAccent : accentPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
