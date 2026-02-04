import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<User>> _futureUsers;
  String _search = '';
  int? _currentAdminId; // ไว้กันไม่ให้ลบตัวเอง

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
    _futureUsers = _loadUsers();
  }

  Future<void> _loadCurrentAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentAdminId = prefs.getInt('user_id');
    });
  }

  Future<List<User>> _loadUsers() async {
    final all = await ApiService.adminGetUsers();
    if (_search.isEmpty) return all;

    final q = _search.toLowerCase();
    return all.where((u) {
      return u.email.toLowerCase().contains(q) ||
          u.displayName.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureUsers = _loadUsers();
    });
  }

  Future<void> _confirmDelete(User user) async {
    if (_currentAdminId != null && user.id == _currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถลบแอดมินที่ล็อกอินอยู่ได้')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24103C),
        title:
            const Text('ยืนยันลบผู้ใช้', style: TextStyle(color: Colors.white)),
        content: Text(
          'ต้องการลบผู้ใช้ ${user.displayName} (${user.email}) หรือไม่?',
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
      await ApiService.adminDeleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบผู้ใช้สำเร็จ')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _toggleRole(User user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';

    try {
      await ApiService.adminUpdateUserRole(
        userId: user.id,
        role: newRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยน role เป็น $newRole แล้ว')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยน role ไม่สำเร็จ: $e')),
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
        title: const Text('จัดการผู้ใช้'),
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'ค้นหาชื่อ, อีเมล หรือ role...',
                        hintStyle: TextStyle(
                          color: Color(0xFF8E7BB7),
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _search = v.trim();
                          _futureUsers = _loadUsers();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: accentPink,
              backgroundColor: cardColor,
              child: FutureBuilder<List<User>>(
                future: _futureUsers,
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

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'ยังไม่มีผู้ใช้',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final isCurrent =
                          _currentAdminId != null && u.id == _currentAdminId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            u.displayName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.email,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Role: ${u.role}',
                                style: TextStyle(
                                  color: u.role == 'admin'
                                      ? accentPink
                                      : const Color(0xFFB9A9D9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  u.role == 'admin'
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: accentPink,
                                ),
                                tooltip: u.role == 'admin'
                                    ? 'เปลี่ยนเป็น user'
                                    : 'ตั้งเป็น admin',
                                onPressed: isCurrent
                                    ? null // กันเปลี่ยน role ตัวเองได้ (จะทำให้ล็อกอินเพี้ยน)
                                    : () => _toggleRole(u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: 'ลบผู้ใช้',
                                onPressed:
                                    isCurrent ? null : () => _confirmDelete(u),
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
