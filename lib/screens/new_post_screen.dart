import 'dart:convert';
import 'dart:io' show File; // ยังคงใช้ได้บน mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

import '../models/post.dart';
import '../services/api_service.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final _gameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _platformCtrl = TextEditingController();
  final _rankCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController(); // ยังเผื่อใช้ลิงก์ได้

  File? _imageFile; // รูปจากเครื่อง
  String? _imageBase64; // base64 ที่จะส่งไป API

  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    debugPrint('PICK_IMAGE start');
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      debugPrint('PICK_IMAGE picked=$picked');

      if (picked == null) {
        debugPrint('PICK_IMAGE user cancelled');
        return;
      }

      Uint8List bytes;

      if (kIsWeb) {
        // บน web ห้ามแปลงเป็น File จาก dart:io [web:88][web:94]
        bytes = await picked.readAsBytes();
        debugPrint('PICK_IMAGE (web) bytes=${bytes.length}');
        setState(() {
          _imageFile = null; // preview ค่อยใช้ Image.memory แทน
        });
      } else {
        // Android / iOS ใช้ File ได้ตามปกติ
        final file = File(picked.path);
        bytes = await file.readAsBytes();
        debugPrint('PICK_IMAGE (mobile) path=${file.path}');
        debugPrint('PICK_IMAGE (mobile) bytes=${bytes.length}');
        setState(() {
          _imageFile = file;
        });
      }

      final b64 = base64Encode(bytes);
      debugPrint('PICK_IMAGE base64 length=${b64.length}');
      debugPrint(
          'PICK_IMAGE base64 preview=${b64.substring(0, b64.length > 200 ? 200 : b64.length)}');

      setState(() {
        _imageBase64 = b64;
        _imageUrlCtrl.text = '';
      });
    } catch (e, st) {
      debugPrint('PICK_IMAGE error=$e');
      debugPrint('PICK_IMAGE stack=$st');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getInt('user_id');

      if (sellerId == null) {
        setState(() {
          _error = 'กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
        });
        return;
      }

      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

      // ถ้าไม่มีรูปจากเครื่อง แต่ใส่ลิงก์ อยากใช้ลิงก์เดิมก็ยังทำได้
      // แต่ในตัวอย่างนี้จะใช้เฉพาะ base64 เป็นหลัก

      debugPrint('SUBMIT imageBase64 length=${_imageBase64?.length ?? 0}');
      if (_imageBase64 != null) {
        debugPrint(
            'SUBMIT imageBase64 preview=${_imageBase64!.substring(0, _imageBase64!.length > 200 ? 200 : _imageBase64!.length)}');
      }

      final Post post = await ApiService.createPost(
        sellerId: sellerId,
        gameName: _gameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        platform: _platformCtrl.text.trim(),
        rank: _rankCtrl.text.trim(),
        imageBase64: _imageBase64,
      );

      if (!mounted) return;
      Navigator.of(context).pop(post);
    } catch (e) {
      setState(() {
        _error = 'สร้างโพสต์ไม่สำเร็จ: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _gameCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _platformCtrl.dispose();
    _rankCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const cardColor = Color(0xFF24103C);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('โพสต์ขายไอดี'),
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _gameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'เกม',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'กรอกชื่อเกม' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'หัวข้อโพสต์',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'กรอกหัวข้อ' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดไอดี',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'กรอกรายละเอียด'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ราคา (บาท)',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'กรอกราคา';
                        }
                        if (double.tryParse(v) == null) {
                          return 'ตัวเลขเท่านั้น';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _platformCtrl,
                      decoration: const InputDecoration(
                        labelText: 'แพลตฟอร์ม (เช่น Steam, Garena)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rankCtrl,
                      decoration: const InputDecoration(
                        labelText: 'แรงค์ / เลเวล',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ปุ่มเลือกรูป + preview
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('PICK_BUTTON PRESSED');
                              _pickImage();
                            },
                            icon: const Icon(Icons.photo),
                            label: const Text('เลือกรูปจากเครื่อง'),
                          ),
                          const SizedBox(width: 12),
                          if (_imageFile != null && !kIsWeb)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFile!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_imageBase64 != null &&
                              _imageBase64!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_imageBase64!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ช่องลิงก์รูป (ถ้าอยากใช้สำรอง)
                    // TextFormField(
                    //   controller: _imageUrlCtrl,
                    //   decoration: const InputDecoration(
                    //     labelText: 'ลิงก์รูป (เว้นว่างหากใช้รูปจากเครื่อง)',
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('โพสต์ขายไอดี'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
