import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/post.dart';

/// ถ้ามี image_base64 จะใช้ Image.memory
/// ถ้าไม่มีค่อย fallback ไป URL หรือ icon เปล่า
class PostImage extends StatelessWidget {
  final Post post;
  final String? fullImageUrl; // URL ที่ build แล้ว (ถ้ามี)
  final BoxFit fit;

  const PostImage({
    super.key,
    required this.post,
    this.fullImageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // 1) base64 มาก่อน
    if (post.imageBase64 != null &&
        post.imageBase64!.isNotEmpty &&
        post.imageBase64 != 'null') {
      try {
        Uint8List bytes = base64Decode(post.imageBase64!);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (ctx, err, stack) {
            return _fallback();
          },
        );
      } catch (_) {
        // ถ้า decode fail ให้ลอง fallback URL ต่อ
      }
    }

    // 2) fallback URL (ยังใช้ได้ในอนาคต)
    if (fullImageUrl != null && fullImageUrl!.isNotEmpty) {
      return Image.network(
        fullImageUrl!,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _fallback(),
      );
    }

    // 3) ไม่มีรูปเลย
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF2F1847),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.white54,
      ),
    );
  }
}
