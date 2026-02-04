import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  static const bgColor = Color(0xFF120023);
  static const cardColor = Color(0xFF24103C);
  static const accentPink = Color(0xFFFF4E87);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  int? _userId;
  bool _loading = false;
  String? _error;

  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      _originalEmail = prefs.getString('email') ?? '';
      _emailCtrl.text = _originalEmail;
      _nameCtrl.text = prefs.getString('display_name') ?? '';
    });
  }

  Future<String?> _askPasswordIfNeeded() async {
    // ถ้าอีเมลไม่เปลี่ยน ไม่ต้องถามรหัส
    if (_emailCtrl.text.trim() == _originalEmail.trim()) {
      return null;
    }

    final controller = TextEditingController();
    final pwd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ยืนยันรหัสผ่าน',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'รหัสผ่านปัจจุบัน',
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
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(color: Color(0xFFFF4E87)),
            ),
          ),
        ],
      ),
    );

    if (pwd == null || pwd.isEmpty) {
      return ''; // ถือว่าไม่ได้กรอก
    }
    return pwd;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      setState(() => _error = 'พบปัญหา กรุณาเข้าสู่ระบบใหม่อีกครั้ง');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ถ้าอีเมลเปลี่ยน ต้องขอรหัสผ่าน
      String? password;
      if (_emailCtrl.text.trim() != _originalEmail.trim()) {
        final pwd = await _askPasswordIfNeeded();
        if (pwd == null) {
          // dialog กดปิด
          setState(() {
            _loading = false;
          });
          return;
        }
        if (pwd.isEmpty) {
          setState(() {
            _loading = false;
            _error = 'กรุณากรอกรหัสผ่านเพื่อเปลี่ยนอีเมล';
          });
          return;
        }
        password = pwd;
      }

      final updatedUser = await ApiService.updateUser(
        userId: _userId!,
        displayName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: password, // null ถ้าไม่ต้องเช็กรหัส
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('display_name', updatedUser.displayName);
      await prefs.setString('email', updatedUser.email);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('ตั้งค่าบัญชี'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_error != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้ (Display name)',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'กรอกชื่อผู้ใช้'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'อีเมล',
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'กรอกอีเมล';
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'รูปแบบอีเมลไม่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentPink,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('บันทึกการเปลี่ยนแปลง'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
