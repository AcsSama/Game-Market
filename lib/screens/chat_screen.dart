import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Post post;
  final int buyerId;

  const ChatScreen({
    super.key,
    required this.post,
    required this.buyerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final List<Message> _messages = [];
  bool _loading = true;
  int? _currentUserId;
  late int _buyerId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบอีกครั้ง')),
      );
      Navigator.of(context).pop();
      return;
    }

    _currentUserId = userId;
    _buyerId = widget.buyerId;

    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final msgs = await ApiService.getMessages(
        postId: widget.post.id,
        buyerId: _buyerId,
      );
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อความไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _textCtrl.clear();

    try {
      final msg = await ApiService.sendMessage(
        postId: widget.post.id,
        buyerId: _buyerId,
        senderId: _currentUserId!,
        text: text,
      );

      setState(() {
        _messages.add(msg);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const appBarColor = Color(0xFF1C0733);
    const infoBarColor = Color(0xFF24103C);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        // เอา titleSpacing=0 ออกก็ได้ จะได้เว้นระยะกับปุ่ม back อัตโนมัติ
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF352052),
              child:
                  Icon(Icons.videogame_asset, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ผู้ขาย: ${widget.post.sellerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFDBCFF5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'ปิดและลบแชตนี้',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF24103C),
                  title: const Text(
                    'ลบห้องแชตนี้?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'การลบจะลบข้อความทั้งหมดในห้องนี้ ทั้งฝั่งผู้ซื้อและผู้ขาย',
                    style: TextStyle(color: Color(0xFFDBCFF5)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'ลบแชต',
                        style: TextStyle(color: Color(0xFFFF4E87)),
                      ),
                    ),
                  ],
                ),
              );

              if (ok != true) return;

              try {
                await ApiService.closeDm(
                  postId: widget.post.id,
                  buyerId: _buyerId,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบห้องแชตไม่สำเร็จ: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // แถบข้อมูลโพสต์ด้านบน
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: infoBarColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.gameName.isEmpty
                      ? widget.post.title
                      : widget.post.gameName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'แพลตฟอร์ม: ${widget.post.platform.isEmpty ? '-' : widget.post.platform}',
                  style: const TextStyle(
                    color: Color(0xFFB9A9D9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF4E87),
                    ),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'เริ่มต้นสนทนากับผู้ขายได้เลย',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _currentUserId;

                          final displayName = isMe
                              ? 'คุณ'
                              : (msg.senderName.isNotEmpty
                                  ? msg.senderName
                                  : 'คู่สนทนา');

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Color(0xFFB9A9D9),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ChatBubble(message: msg, isMe: isMe),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          // แถบพิมพ์ด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: appBarColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        hintStyle: const TextStyle(color: Color(0xFF8E7BB7)),
                        filled: true,
                        fillColor: const Color(0xFF24103C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4E87),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
