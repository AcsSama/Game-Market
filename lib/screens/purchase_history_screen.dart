import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/orderitem.dart';
import '../models/post.dart';
import 'chat_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  static const bgColor = Color(0xFF120023);
  static const cardColor = Color(0xFF24103C);

  bool _loading = true;
  String? _error;
  List<OrderItem> _items = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        setState(() {
          _error = 'กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
          _loading = false;
        });
        return;
      }

      final data = await ApiService.getOrderHistory(userId);
      setState(() {
        _userId = userId;
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('ประวัติการซื้อ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'ยังไม่มีรายการซื้อ',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final o = _items[i];
                        final dateStr =
                            '${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year} '
                            '${o.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${o.createdAt.minute.toString().padLeft(2, '0')}';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  o.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${o.gameName} • $dateStr • ${o.status}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  '${o.price.toStringAsFixed(0)} ฿',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _userId == null
                                      ? null
                                      : () {
                                          // สร้าง fake Post สำหรับ ChatScreen (เหมือนใน ChatListScreen)
                                          final fakePost = Post(
                                            id: o.postId,
                                            gameName: o.gameName,
                                            title: o.title,
                                            description: '',
                                            price: o.price,
                                            status: 'soldout',
                                            imageUrl: null,
                                            platform: '',
                                            rank: '',
                                            sellerName:
                                                '', // ถ้ามี sellerName ใน OrderItem ค่อยใส่ทีหลัง
                                            createdAt: o.createdAt,
                                          );

                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                post: fakePost,
                                                buyerId: _userId!,
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'แชทกับผู้ขาย',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
