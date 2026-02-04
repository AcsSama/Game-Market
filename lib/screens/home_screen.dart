import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../services/wallet_service.dart';
import '../widgets/home_post_card.dart';
import 'edit_post_screen.dart';
import 'user_posts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color bgColor = Color(0xFF070018);
  static const Color cardColor = Color(0xFF1A062E);
  static const Color accentColor = Color(0xFFFF4E87);

  String displayName = '';
  double coin = 0;
  int? userId;
  late Future<List<Post>> _futureMyPosts;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    final name = prefs.getString('display_name') ?? '';
    final balance = await WalletService.getBalance();

    setState(() {
      userId = id;
      displayName = name;
      coin = balance;
    });

    if (id != null) {
      _futureMyPosts = _loadMyPosts();
      setState(() {});
    }
  }

  Future<List<Post>> _loadMyPosts() async {
    if (userId == null) return [];
    final myPosts = await ApiService.getMyPosts(userId!);
    return myPosts;
  }

  Future<void> _refresh() async {
    final posts = await _loadMyPosts();
    setState(() {
      _futureMyPosts = Future.value(posts);
    });
  }

  Future<void> _openAdjustBalanceDialog(bool isDeposit) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isDeposit ? 'เติมเงิน' : 'ถอนเงิน',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'จำนวน (บาท)',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.of(ctx).pop(value);
              },
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Color(0xFFFF4E87)),
              ),
            ),
          ],
        );
      },
    );

    // debugPrint('[Home] Dialog result=$result isDeposit=$isDeposit');

    if (result == null || result <= 0) {
      // debugPrint('[Home] Cancel or invalid amount');
      return;
    }
    if (userId == null) {
      // debugPrint('[Home] userId is null, cannot adjust balance');
      return;
    }

    if (!isDeposit && result > coin) {
      // debugPrint(
      //     '[Home] Withdraw > current coin (withdraw=$result, coin=$coin)');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยอดเงินไม่พอถอน')),
        );
      }
      return;
    }

    try {
      final delta = isDeposit ? result : -result;
      // debugPrint('[Home] Call WalletService.adjustBalance delta=$delta');

      final newBalance = await WalletService.adjustBalance(
        userId: userId!,
        delta: delta,
      );

      if (!mounted) return;
      // debugPrint('[Home] New balance from server=$newBalance');

      setState(() {
        coin = newBalance;
      });
    } catch (e) {
      // debugPrint('[Home] adjustBalance error=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ปรับยอดไม่สำเร็จ: $e')),
      );
    }
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Home',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0555), Color(0xFF5A0C8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อ + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName.isEmpty ? 'User' : displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // avatar + balance
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ยอดคงเหลือ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${coin.toStringAsFixed(0)} ฿',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.security, color: Colors.white70, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'ปลอดภัย',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 16),

          // ปุ่ม เติม / ถอน
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openAdjustBalanceDialog(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'เติมเงิน',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openAdjustBalanceDialog(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(
                        color: Color(0xFFFF4E87),
                      ),
                    ),
                    backgroundColor: accentColor.withOpacity(0.18),
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text(
                    'ถอนเงิน',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader({required int totalPosts}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.list_alt, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'รายการโพสต์ของคุณ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (totalPosts > 5)
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserPostsScreen(),
                ),
              );
            },
            child: const Text(
              'เพิ่มเติม',
              style: TextStyle(
                color: Color(0xFFFF4E87),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: accentColor,
          backgroundColor: cardColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildUserCard(),
              const SizedBox(height: 24),
              FutureBuilder<List<Post>>(
                future: _futureMyPosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 4),
                        Text(
                          'รายการโพสต์ของคุณ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPostHeader(totalPosts: 0),
                        const SizedBox(height: 12),
                        Text(
                          'โหลดโพสต์ของคุณไม่สำเร็จ\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  }

                  final posts = snapshot.data ?? [];
                  final total = posts.length;
                  final displayPosts =
                      total > 5 ? posts.take(5).toList() : posts;

                  if (posts.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 4),
                        Text(
                          'รายการโพสต์ของคุณ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'คุณยังไม่มีโพสต์',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostHeader(totalPosts: total),
                      const SizedBox(height: 12),
                      ...displayPosts.map((post) {
                        return Dismissible(
                          key: ValueKey(post.id),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  backgroundColor: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'ลบโพสต์',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'ต้องการลบโพสต์นี้หรือไม่?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text(
                                        'ยกเลิก',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'ลบ',
                                        style:
                                            TextStyle(color: Color(0xFFFF4E87)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true) return false;

                            try {
                              await ApiService.deletePost(post.id);
                              await _refresh();
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
                                );
                              }
                              return false;
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: PostCard(
                              post: post,
                              isOwnerView: true,
                              onTap: () async {
                                final updated =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => EditPostScreen(post: post),
                                  ),
                                );
                                if (updated == true) {
                                  await _refresh();
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                      if (total > 5) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const UserPostsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'ดูโพสต์ทั้งหมด ($total)',
                              style: const TextStyle(
                                color: Color(0xFFFF4E87),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
