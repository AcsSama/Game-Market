import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'new_post_screen.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late Future<List<Post>> _futurePosts;
  String _searchQuery = '';
  String? _platformFilter;

  @override
  void initState() {
    super.initState();
    _futurePosts = _loadPosts();
  }

  Future<List<Post>> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getInt('user_id');
    final myName = prefs.getString('display_name');

    final all = await ApiService.getPosts();

    for (final p in all) {
      debugPrint(
        'DBG_POST id=${p.id} hasBase64=${p.imageBase64 != null && p.imageBase64!.isNotEmpty} '
        'len=${p.imageBase64?.length} url=${p.imageUrl}',
      );
    }

    // กรองโพสต์ของตัวเองออก
    var list = all;
    if (myId != null && myName != null) {
      list = list.where((p) => p.sellerName != myName).toList();
    }

    // กรองตาม search (ชื่อเกม / title / ชื่อผู้ขาย)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.gameName.toLowerCase().contains(q) ||
            p.title.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q);
      }).toList();
    }

    // กรองตาม platform (ถ้ามีเลือกไว้)
    if (_platformFilter != null && _platformFilter!.isNotEmpty) {
      list = list
          .where(
              (p) => p.platform.toLowerCase() == _platformFilter!.toLowerCase())
          .toList();
    }

    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePosts = _loadPosts();
    });
  }

  Future<void> _openFilterSheet() async {
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
                'เลือกแพลตฟอร์ม',
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
                    const Text('Steam', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('Steam'),
              ),
              ListTile(
                title:
                    const Text('Garena', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('Garena'),
              ),
              ListTile(
                title:
                    const Text('อื่น ๆ', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('อื่น ๆ'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _platformFilter = selected.isEmpty ? null : selected;
      _futurePosts = _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Game ID Market',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ==== แถบค้นหา / header ด้านบน ====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF24103C), Color(0xFF2D1546)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                                hintText: 'ค้นหาเกมหรือไอดี...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF8E7BB7),
                                  fontSize: 14,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim();
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
                      color: const Color(0xFFFF4E87),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _openFilterSheet,
                    ),
                  ),
                ],
              ),
            ),

            // chip แสดง platform filter (ถ้ามี)
            if (_platformFilter != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _platformFilter = null;
                        _futurePosts = _loadPosts();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4E87).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_alt,
                              color: Color(0xFFFF4E87), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'แพลตฟอร์ม: $_platformFilter  ×',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ==== เนื้อหา (list) ====
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFFFF4E87),
                backgroundColor: const Color(0xFF24103C),
                child: FutureBuilder<List<Post>>(
                  future: _futurePosts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF4E87),
                        ),
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
                          'ยังไม่มีประกาศขายไอดี',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // แสดงจำนวนรายการ
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'พบทั้งหมด ${posts.length} รายการ',
                              style: const TextStyle(
                                color: Color(0xFF8E7BB7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return Column(
                                children: [
                                  PostCard(
                                    post: post,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PostDetailScreen(post: post),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 1,
                                    color: Colors.white10,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 220,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF4E87),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          onPressed: () async {
            final newPost = await Navigator.of(context).push<Post?>(
              MaterialPageRoute(builder: (_) => const NewPostScreen()),
            );

            if (newPost != null) {
              await _refresh();
            }
          },
          label: const Text(
            'โพสต์ขายไอดี',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
