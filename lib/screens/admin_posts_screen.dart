import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart'; // ตัวที่ใช้ในหน้า Home (owner view ได้)

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  late Future<List<Post>> _futurePosts;
  String _search = '';
  String? _statusFilter; // null=ทั้งหมด, 'active', 'soldout'

  @override
  void initState() {
    super.initState();
    _futurePosts = _loadPosts();
  }

  Future<List<Post>> _loadPosts() async {
    final all = await ApiService.getPosts(); // ดึงทุกโพสต์อยู่แล้ว

    var list = all;

    // กรอง search ตามชื่อเกม, title, คนขาย
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        return p.gameName.toLowerCase().contains(q) ||
            p.title.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q);
      }).toList();
    }

    // กรองตามสถานะ
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      list = list
          .where((p) => p.status.toLowerCase() == _statusFilter!.toLowerCase())
          .toList();
    }

    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePosts = _loadPosts();
    });
  }

  Future<void> _openStatusFilterSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF24103C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'กรองตามสถานะโพสต์',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text('ทั้งหมด',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop(''),
              ),
              ListTile(
                title:
                    const Text('Active', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('active'),
              ),
              ListTile(
                title: const Text('Soldout',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('soldout'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _statusFilter = selected.isEmpty ? null : selected;
      _futurePosts = _loadPosts();
    });
  }

  Future<void> _confirmDelete(Post post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24103C),
        title:
            const Text('ยืนยันลบโพสต์', style: TextStyle(color: Colors.white)),
        content: Text(
          'ต้องการลบโพสต์ "${post.title}" ของ ${post.sellerName} หรือไม่?',
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
            child: const Text('ลบ', style: TextStyle(color: Color(0xFFFF4E87))),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ApiService.deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบโพสต์สำเร็จ')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบโพสต์ไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _toggleStatus(Post post) async {
    final newStatus =
        post.status.toLowerCase() == 'active' ? 'soldout' : 'active';

    try {
      await ApiService.updatePostStatus(postId: post.id, status: newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนสถานะเป็น $newStatus แล้ว')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนสถานะไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const cardColor = Color(0xFF24103C);
    const accentPink = Color(0xFFFF4E87);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('จัดการโพสต์'),
      ),
      body: Column(
        children: [
          // แถบค้นหา + filter status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    height: 44,
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF8E7BB7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'ค้นหาชื่อเกม, หัวข้อ หรือผู้ขาย...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8E7BB7),
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _search = value.trim();
                                _futurePosts = _loadPosts();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: accentPink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _openStatusFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          // list posts
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: accentPink,
              backgroundColor: cardColor,
              child: FutureBuilder<List<Post>>(
                future: _futurePosts,
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

                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        'ยังไม่มีโพสต์',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return Dismissible(
                        key: ValueKey(post.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await _confirmDelete(post);
                          return false; // เรา handle เองใน _confirmDelete
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // ใช้ PostCard owner view เพื่อไม่โชว์ badge ซ้ำ
                              Expanded(
                                child: PostCard(
                                  post: post,
                                  onTap: () {}, // หรือเปิด detail ถ้าต้องการ
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      post.status.toLowerCase() == 'active'
                                          ? Icons.check_circle
                                          : Icons.refresh,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'สลับสถานะ Active/Soldout',
                                    onPressed: () => _toggleStatus(post),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    tooltip: 'ลบโพสต์',
                                    onPressed: () => _confirmDelete(post),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
