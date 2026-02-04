import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';
import '../services/wallet_service.dart';

// ใช้ baseUrl เดียวกับ PostCard
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

Uint8List? _base64ToBytes(String? b64) {
  if (b64 == null || b64.isEmpty || b64 == 'null') return null;
  try {
    String s = b64.trim();

    // ตัด prefix data:image/...;base64, ถ้ามี
    final idx = s.indexOf('base64,');
    if (idx != -1) {
      s = s.substring(idx + 'base64,'.length);
    }

    s = s.replaceAll(' ', '+');

    final mod4 = s.length % 4;
    if (mod4 > 0) {
      s += '=' * (4 - mod4);
    }

    return base64Decode(s);
  } catch (_) {
    return null;
  }
}

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  Future<void> _buyPost(BuildContext context) async {
    const cardColor = Color(0xFF24103C);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบอีกครั้ง')),
        );
      }
      return;
    }

    // ดึง balance ล่าสุด (ใช้ของเดิมได้)
    double balance;
    try {
      balance = await WalletService.getBalanceFromServer(userId);
    } catch (_) {
      balance = await WalletService.getBalance();
    }

    if (balance < post.price) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              const Text('ยอดเงินไม่พอ', style: TextStyle(color: Colors.white)),
          content: const Text(
            'กรุณาเติมเงินก่อนซื้อไอดี',
            style: TextStyle(color: Color(0xFFDBCFF5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ปิด', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('ยืนยันการซื้อ', style: TextStyle(color: Colors.white)),
        content: Text(
          'ต้องการซื้อไอดีนี้ในราคา ${post.price.toStringAsFixed(0)} บาทหรือไม่?',
          style: const TextStyle(color: Color(0xFFDBCFF5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('ยกเลิก', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('ซื้อ', style: TextStyle(color: Color(0xFFFF4E87))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // เรียก API ซื้อ (ตัดเงิน + เปลี่ยนสถานะ + บันทึก orders)
      final newBalance = await ApiService.purchasePost(
        buyerId: userId,
        postId: post.id,
      );

      // อัปเดต balance ใน local
      await WalletService.setBalance(newBalance);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('ซื้อสำเร็จ! ยอดคงเหลือ ${newBalance.toStringAsFixed(0)} ฿'),
        ),
      );

      // ส่ง true กลับไปให้หน้า list รีโหลดโพสต์ (จะได้เห็นว่า soldout)
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ซื้อไม่สำเร็จ: $msg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const cardColor = Color(0xFF24103C);
    const accentPink = Color(0xFFFF4E87);
    const accentOrange = Color(0xFFFFA000);

    final fullImageUrl = buildImageUrl(post.imageUrl);
    final base64Bytes = _base64ToBytes(post.imageBase64);

    debugPrint(
        'DETAIL id=${post.id} rawUrl="${post.imageUrl}" hasBase64=${post.imageBase64 != null && post.imageBase64!.isNotEmpty} full=$fullImageUrl');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C0733),
        elevation: 0,
        centerTitle: true,
        title: Text(
          post.gameName.isEmpty ? 'รายละเอียดไอดี' : post.gameName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // รูปใหญ่ด้านบน: base64 ก่อน, ถ้าไม่มีค่อยใช้ URL
            AspectRatio(
              aspectRatio: 16 / 9,
              child: base64Bytes != null
                  ? Image.memory(
                      base64Bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: const Color(0xFF2F1847),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : (fullImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fullImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF2F1847),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentPink,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF2F1847),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2F1847),
                          child: const Icon(
                            Icons.videogame_asset,
                            color: Colors.white54,
                          ),
                        )),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อโพสต์ + ราคา
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${post.price.toStringAsFixed(0)}฿',
                          style: const TextStyle(
                            color: accentOrange,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ผู้ขาย + แท็กเกม + status badge
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 18, color: Color(0xFFB9A9D9)),
                        const SizedBox(width: 4),
                        Text(
                          post.sellerName,
                          style: const TextStyle(
                            color: Color(0xFFB9A9D9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF352052),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            post.gameName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: post.status == 'soldout'
                                ? Colors.red.withOpacity(0.16)
                                : accentPink.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.status == 'soldout' ? 'ขายแล้ว' : 'ขายอยู่',
                            style: TextStyle(
                              color: post.status == 'soldout'
                                  ? Colors.redAccent
                                  : accentPink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // หัวข้อรายละเอียด
                    const Text(
                      'รายละเอียดไอดี',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        post.description,
                        style: const TextStyle(
                          color: Color(0xFFDBCFF5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // แสดง platform / rank
                    Row(
                      children: [
                        const Icon(Icons.videogame_asset,
                            size: 18, color: Color(0xFFB9A9D9)),
                        const SizedBox(width: 4),
                        Text(
                          'แพลตฟอร์ม: ${post.platform.isEmpty ? '-' : post.platform}',
                          style: const TextStyle(
                            color: Color(0xFFB9A9D9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (post.rank.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 18, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 4),
                          Text(
                            'แรงค์ / เลเวล: ${post.rank}',
                            style: const TextStyle(
                              color: Color(0xFFB9A9D9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // สถานะตัวหนังสือ
                    Row(
                      children: [
                        const Text(
                          'สถานะ: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          post.status == 'active' ? 'ขายอยู่' : post.status,
                          style: const TextStyle(
                            color: accentOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1C0733),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: accentPink),
                  foregroundColor: accentPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt('user_id');
                  if (userId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('กรุณาเข้าสู่ระบบอีกครั้ง')),
                      );
                    }
                    return;
                  }

                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        post: post,
                        buyerId: userId, // buyer = ผู้ใช้ที่กำลังดูโพสต์
                      ),
                    ),
                  );
                },
                child: const Text('แชทกับผู้ขาย'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      post.status == 'soldout' ? Colors.grey : accentPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onPressed:
                    post.status == 'soldout' ? null : () => _buyPost(context),
                child: Text(
                  post.status == 'soldout' ? 'ขายแล้ว' : 'Buy now',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
