import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/home_post_card.dart';
import 'edit_post_screen.dart';

class UserPostsScreen extends StatefulWidget {
  const UserPostsScreen({super.key});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  static const Color bgColor = Color(0xFF070018);
  static const Color cardColor = Color(0xFF1A062E);
  static const Color accentColor = Color(0xFFFF4E87);

  int? userId;
  late Future<List<Post>> _futureMyPosts;

  @override
  void initState() {
    super.initState();
    _loadUserAndPosts();
  }

  Future<void> _loadUserAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    setState(() {
      userId = id;
    });

    if (id != null) {
      setState(() {
        _futureMyPosts = ApiService.getMyPosts(id);
      });
    }
  }

  Future<void> _refresh() async {
    if (userId == null) return;
    final posts = await ApiService.getMyPosts(userId!);
    setState(() {
      _futureMyPosts = Future.value(posts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'โพสต์ของฉัน',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: accentColor,
          backgroundColor: cardColor,
          child: FutureBuilder<List<Post>>(
            future: _futureMyPosts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: accentColor),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'โหลดโพสต์ไม่สำเร็จ\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    'คุณยังไม่มีโพสต์',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: PostCard(
                      post: post,
                      isOwnerView: true,
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditPostScreen(post: post),
                          ),
                        );
                        if (updated == true) {
                          await _refresh();
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
