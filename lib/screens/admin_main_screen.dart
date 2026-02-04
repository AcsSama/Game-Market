import 'package:flutter/material.dart';

import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'profile_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _index = 0;

  final _pages = const [
    AdminUsersScreen(), // จัดการ user
    AdminPostsScreen(), // จัดการ posts
    ProfileScreen(), // profile ไว้ logout อย่างเดียว
  ];

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        backgroundColor: const Color(0xFF24103C),
        selectedItemColor: const Color(0xFFFF4E87),
        unselectedItemColor: Colors.white70,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
