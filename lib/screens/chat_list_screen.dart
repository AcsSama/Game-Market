import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_item.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

enum ChatMode { buyer, seller }

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatItem>> _futureBuyerChats;
  late Future<List<ChatItem>> _futureSellerChats;
  int? _userId;
  ChatMode _mode = ChatMode.buyer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบอีกครั้ง')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _userId = id;
      _futureBuyerChats = ApiService.getChatListBuyer(id);
      _futureSellerChats = ApiService.getChatListSeller(id);
    });
  }

  Future<void> _refresh() async {
    if (_userId == null) return;
    setState(() {
      _futureBuyerChats = ApiService.getChatListBuyer(_userId!);
      _futureSellerChats = ApiService.getChatListSeller(_userId!);
    });
  }

  void _openChat(ChatItem item) {
    final fakePost = Post(
      id: item.postId,
      gameName: '',
      title: item.postTitle,
      description: '',
      price: 0,
      status: 'active',
      imageUrl: null,
      platform: '',
      rank: '',
      sellerName: item.partnerName,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          post: fakePost,
          buyerId: item.buyerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const cardColor = Color(0xFF24103C);
    const accentPink = Color(0xFFFF4E87);

    if (_userId == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: accentPink),
        ),
      );
    }

    final future =
        _mode == ChatMode.buyer ? _futureBuyerChats : _futureSellerChats;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'แชตของฉัน',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: accentPink,
        backgroundColor: cardColor,
        onRefresh: _refresh,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // toggle buyer / seller
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF24103C),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_mode != ChatMode.buyer) {
                            setState(() => _mode = ChatMode.buyer);
                          }
                        },
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: _mode == ChatMode.buyer
                                ? accentPink
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ฉันเป็นผู้ซื้อ',
                            style: TextStyle(
                              color: _mode == ChatMode.buyer
                                  ? Colors.white
                                  : const Color(0xFFB9A9D9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_mode != ChatMode.seller) {
                            setState(() => _mode = ChatMode.seller);
                          }
                        },
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: _mode == ChatMode.seller
                                ? accentPink
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ฉันเป็นผู้ขาย',
                            style: TextStyle(
                              color: _mode == ChatMode.seller
                                  ? Colors.white
                                  : const Color(0xFFB9A9D9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<ChatItem>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentPink),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'โหลดข้อมูลไม่สำเร็จ\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final chats = snapshot.data ?? [];
                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        _mode == ChatMode.buyer
                            ? 'ยังไม่มีแชตในฐานะผู้ซื้อ'
                            : 'ยังไม่มีแชตในฐานะผู้ขาย',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final c = chats[index];
                      return Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _openChat(c),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            'โพสต์: ${c.postTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                _mode == ChatMode.buyer
                                    ? 'ผู้ขาย: ${c.partnerName}'
                                    : 'ผู้ซื้อ: ${c.partnerName}',
                                style: const TextStyle(
                                  color: Color(0xFFB9A9D9),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.lastText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${c.lastTime.hour.toString().padLeft(2, '0')}:${c.lastTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
