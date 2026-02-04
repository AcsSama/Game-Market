import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../services/api_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController gameCtrl;
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController platformCtrl;
  late final TextEditingController rankCtrl;

  bool loading = false;
  String? error;

  String? _oldImageUrl; // รูปเดิมจาก post (กรณีโพสต์เก่าที่ใช้ URL)
  Uint8List? _newImageBytes; // bytes รูปใหม่ที่เลือก
  String? _newImageBase64; // base64 สำหรับส่งไป backend
  bool _removeImage = false; // ถ้า true = ลบรูป

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    gameCtrl = TextEditingController(text: p.gameName);
    titleCtrl = TextEditingController(text: p.title);
    descCtrl = TextEditingController(text: p.description);
    priceCtrl = TextEditingController(text: p.price.toStringAsFixed(0));
    platformCtrl = TextEditingController(text: p.platform);
    rankCtrl = TextEditingController(text: p.rank);

    // เก็บ URL เดิม (สำหรับโพสต์เก่าที่เคยใช้ URL)
    _oldImageUrl =
        (p.imageUrl != null && p.imageUrl != '-' && p.imageUrl!.isNotEmpty)
            ? p.imageUrl
            : null;
  }

  @override
  void dispose() {
    gameCtrl.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    platformCtrl.dispose();
    rankCtrl.dispose();
    super.dispose();
  }

  Uint8List? _base64ToBytes(String? b64) {
    if (b64 == null || b64.isEmpty || b64 == 'null') return null;
    try {
      String s = b64.trim();

      // ตัด prefix data:image/...;base64, ถ้ามี
      final idx = s.indexOf('base64,');
      if (idx != -1) {
        s = s.substring(idx + 'base64,'.length);
      }

      s = s.replaceAll(' ', '+');

      final mod4 = s.length % 4;
      if (mod4 > 0) {
        s += '=' * (4 - mod4);
      }

      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
        _newImageBase64 = base64Encode(bytes);
        _removeImage = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF24103C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ลบโพสต์นี้?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'คุณต้องการลบโพสต์นี้จริง ๆ หรือไม่?\nการลบไม่สามารถย้อนกลับได้',
            style: TextStyle(color: Colors.white70),
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
                'ลบโพสต์',
                style: TextStyle(color: Color(0xFFFF4E87)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deletePost();
    }
  }

  Future<void> _deletePost() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ApiService.deletePost(widget.post.id);
      if (!mounted) return;
      // ส่งค่ากลับให้หน้าเดิมรู้ว่าโพสต์ถูกลบแล้ว
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

      // 1) กรณีลบรูป
      if (_removeImage) {
        await ApiService.updatePost(
          id: widget.post.id,
          gameName: gameCtrl.text.trim(),
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: price,
          platform: platformCtrl.text.trim(),
          rank: rankCtrl.text.trim(),
          imageUrl: '-', // ลบรูป (ทั้ง base64 / url)
        );
      }
      // 2) กรณีเลือกรูปใหม่
      else if (_newImageBase64 != null && _newImageBase64!.isNotEmpty) {
        await ApiService.updatePostWithImageData(
          id: widget.post.id,
          gameName: gameCtrl.text.trim(),
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: price,
          platform: platformCtrl.text.trim(),
          rank: rankCtrl.text.trim(),
          imageBase64: _newImageBase64!,
        );
      }
      // 3) ไม่ได้เปลี่ยนรูป
      else {
        // ถ้าโพสต์เดิมมี base64 อยู่แล้ว ให้ใช้ base64 เดิม
        if (widget.post.imageBase64 != null &&
            widget.post.imageBase64!.isNotEmpty &&
            widget.post.imageBase64 != 'null') {
          await ApiService.updatePostWithImageData(
            id: widget.post.id,
            gameName: gameCtrl.text.trim(),
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
            price: price,
            platform: platformCtrl.text.trim(),
            rank: rankCtrl.text.trim(),
            imageBase64: widget.post.imageBase64!,
          );
        } else {
          // กรณีโพสต์เก่าที่ใช้ URL
          await ApiService.updatePost(
            id: widget.post.id,
            gameName: gameCtrl.text.trim(),
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
            price: price,
            platform: platformCtrl.text.trim(),
            rank: rankCtrl.text.trim(),
            imageUrl: _oldImageUrl ?? '-',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF120023);
    const cardColor = Color(0xFF24103C);

    // preview รูป:
    // 1) ถ้ามีรูปใหม่ที่เพิ่งเลือก -> ใช้ _newImageBytes
    // 2) ถ้าไม่ได้ลบรูป -> ลองจาก base64 เดิม
    // 3) ถ้า base64 ไม่มี/พัง -> fallback ไปใช้ URL เดิม (สำหรับโพสต์เก่า)
    ImageProvider? previewImage;
    if (_newImageBytes != null) {
      previewImage = MemoryImage(_newImageBytes!);
    } else if (!_removeImage) {
      final bytes = _base64ToBytes(widget.post.imageBase64);
      if (bytes != null) {
        previewImage = MemoryImage(bytes);
      } else if (_oldImageUrl != null && _oldImageUrl != '-') {
        previewImage = NetworkImage(
          _oldImageUrl!.startsWith('http')
              ? _oldImageUrl!
              : '${ApiService.baseUrl}${_oldImageUrl!}',
        );
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('แก้ไขโพสต์'),
        actions: [
          IconButton(
            onPressed: loading ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            color: Colors.redAccent,
            tooltip: 'ลบโพสต์',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (error != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // ส่วนจัดการรูป
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'รูปประกอบ',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: previewImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image(
                                      image: previewImage,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2F1847),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo),
                                label: const Text('เลือกรูปใหม่'),
                              ),
                              const SizedBox(width: 8),
                              if (_oldImageUrl != null ||
                                  _newImageBytes != null ||
                                  (widget.post.imageBase64 != null &&
                                      widget.post.imageBase64!.isNotEmpty &&
                                      widget.post.imageBase64 != 'null'))
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _newImageBytes = null;
                                      _newImageBase64 = null;
                                      _oldImageUrl = null;
                                      _removeImage = true;
                                    });
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  label: const Text(
                                    'ลบรูป',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                            ],
                          ),
                          if (_removeImage)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'โพสต์นี้จะไม่มีรูปประกอบ',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: gameCtrl,
                      decoration: const InputDecoration(labelText: 'ชื่อเกม'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'กรุณากรอกชื่อเกม'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleCtrl,
                      decoration:
                          const InputDecoration(labelText: 'หัวข้อโพสต์'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'กรุณากรอกหัวข้อ'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'รายละเอียด'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'กรุณากรอกรายละเอียด'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'ราคา'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'กรุณากรอกราคา';
                        }
                        if (double.tryParse(v) == null) {
                          return 'รูปแบบราคาไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: platformCtrl,
                      decoration: const InputDecoration(
                        labelText: 'แพลตฟอร์ม (เช่น Steam)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rankCtrl,
                      decoration:
                          const InputDecoration(labelText: 'แรงค์/เลเวล'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('บันทึกการแก้ไข'),
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
