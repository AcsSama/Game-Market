// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../models/chat_item.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/message.dart';
import '../models/orderitem.dart';

class ApiService {
  static const String baseUrl =
      'https://expressless-reena-suably.ngrok-free.dev/app_api/';

  static Map<String, String> _defaultHeaders() {
    return {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  // ---------- LOGIN ----------
  static Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('LOGIN status=${res.statusCode}');
      debugPrint('LOGIN raw body(first 200)='
          '${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        String message = 'Login failed (${res.statusCode})';
        try {
          final data = jsonDecode(res.body);
          if (data is Map && data['error'] != null) {
            message = data['error'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e, st) {
      debugPrint('LOGIN exception=$e');
      debugPrint('LOGIN stack=$st');
      rethrow;
    }
  }

  // ---------- REGISTER ----------
  static Future<User> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final url = Uri.parse('$baseUrl/register.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'email': email,
      'password': password,
      'display_name': displayName,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        try {
          final data = jsonDecode(res.body);
          final msg = data['error']?.toString() ?? 'Register failed';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Register failed (${res.statusCode})');
        }
      }
    } catch (e, st) {
      rethrow;
    }
  }

  // ---------- POSTS ----------
  static Future<List<Post>> getPosts() async {
    final url = Uri.parse('$baseUrl/get_posts.php');
    final res = await http.get(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load posts (${res.statusCode})');
    }
  }

  // ---------- UPDATE POST WITH IMAGE DATA ----------
  static Future<void> updatePostWithImageData({
    required int id,
    required String gameName,
    required String title,
    required String description,
    required double price,
    required String platform,
    required String rank,
    required String imageBase64,
  }) async {
    final url = Uri.parse('${baseUrl}update_post.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'id': id,
      'game_name': gameName,
      'title': title,
      'description': description,
      'price': price,
      'platform': platform,
      'rank': rank,
      'image_data': imageBase64,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode})');
    }
  }

  // ------- Get MESSAGES -------
  static Future<List<Message>> getMessages({
    required int postId,
    required int buyerId,
  }) async {
    final url = Uri.parse(
        '$baseUrl/get_messages.php?post_id=$postId&buyer_id=$buyerId');
    final res = await http.get(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load messages (${res.statusCode})');
    }
  }

  // ------ Send MESSAGES -------
  static Future<Message> sendMessage({
    required int postId,
    required int buyerId,
    required int senderId,
    required String text,
  }) async {
    final url = Uri.parse('$baseUrl/send_message.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'post_id': postId,
        'buyer_id': buyerId,
        'sender_id': senderId,
        'text': text,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Message.fromJson(data);
    } else {
      throw Exception('Failed to send message (${res.statusCode})');
    }
  }

  // ---------- CHAT LIST BUYER ----------
  static Future<List<ChatItem>> getChatListBuyer(int userId) async {
    final url = Uri.parse('$baseUrl/get_chat_list_buyer.php?user_id=$userId');
    final res =
        await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => ChatItem.fromBuyerJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load chat list (${res.statusCode})');
    }
  }

  // ---------- CHAT LIST SELLER ----------
  static Future<List<ChatItem>> getChatListSeller(int userId) async {
    final url = Uri.parse('$baseUrl/get_chat_list_seller.php?user_id=$userId');
    final res =
        await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => ChatItem.fromSellerJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load chat list (${res.statusCode})');
    }
  }

  // ----------- CLOSE DM ----------------
  static Future<void> closeDm({
    required int postId,
    required int buyerId,
  }) async {
    final url = Uri.parse('$baseUrl/close_dm.php');
    final res = await http.post(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'post_id': postId,
        'buyer_id': buyerId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to close DM (${res.statusCode})');
    }
  }

  // -------- Create Post -------
  static Future<Post> createPost({
    required int sellerId,
    required String gameName,
    required String title,
    required String description,
    required double price,
    required String platform,
    required String rank,
    String? imageBase64,
  }) async {
    final url = Uri.parse('$baseUrl/create_post.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final bodyMap = <String, dynamic>{
      'user_id': sellerId,
      'game_name': gameName,
      'title': title,
      'description': description,
      'price': price,
      'platform': platform,
      'rank': rank,
    };

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      bodyMap['image_data'] = imageBase64;
    }

    final body = jsonEncode(bodyMap);

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return Post.fromJson(data);
      } else {
        try {
          final data = jsonDecode(res.body);
          final msg = data['error']?.toString() ?? 'สร้างโพสต์ไม่สำเร็จ';
          throw Exception(msg);
        } catch (_) {
          throw Exception('สร้างโพสต์ไม่สำเร็จ (${res.statusCode})');
        }
      }
    } catch (e, st) {
      debugPrint('CREATE exception=$e');
      debugPrint('CREATE stack=$st');
      rethrow;
    }
  }

  // ---------- DELETE POST ----------
  static Future<void> deletePost(int postId) async {
    final url = Uri.parse('$baseUrl/delete_post.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({'post_id': postId});

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 200) {
      try {
        final data = jsonDecode(res.body);
        final msg = data['error']?.toString() ?? 'Delete failed';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Delete failed (${res.statusCode})');
      }
    }
  }

  // ---------- UPDATE POST ----------
  static Future<void> updatePost({
    required int id,
    required String gameName,
    required String title,
    required String description,
    required double price,
    required String platform,
    required String rank,
    String? imageUrl,
  }) async {
    final url = Uri.parse('$baseUrl/update_post.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'id': id,
      'game_name': gameName,
      'title': title,
      'description': description,
      'price': price,
      'platform': platform,
      'rank': rank,
      'image_url':
          (imageUrl == null || imageUrl.trim().isEmpty) ? '-' : imageUrl.trim(),
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode})');
    }
  }

  // ---------- UPDATE POST STATUS ----------
  static Future<void> updatePostStatus({
    required int postId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/update_post_status.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'post_id': postId, 'status': status});

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 200) {
      throw Exception('Update status failed (${res.statusCode})');
    }
  }

  // ---------- GET MY POST  ----------
  static Future<List<Post>> getMyPosts(int userId) async {
    final url = Uri.parse('$baseUrl/get_my_posts.php?user_id=$userId');
    final res = await http.get(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load my posts (${res.statusCode})');
    }
  }

  // ---------- UPDATE USER PROFILE ----------
  static Future<User> updateUser({
    required int userId,
    required String displayName,
    String? password,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/update_user.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'user_id': userId,
      'display_name': displayName,
      if (password != null && password.isNotEmpty) 'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      String message = 'Update failed (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        message = data['error']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  // ---------- UPDATE USER PASSWORD -----------
  static Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/change_password.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      String message = 'Change password failed (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  // ---------- ADMIN: GET ALL USERS ----------
  static Future<List<User>> adminGetUsers() async {
    final url = Uri.parse('$baseUrl/admin_get_users.php');
    final res = await http.get(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load users (${res.statusCode})');
    }
  }

  // ---------- ADMIN: UPDATE USER ROLE ----------
  static Future<void> adminUpdateUserRole({
    required int userId,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/admin_update_user_role.php');
    final res = await http.post(
      url,
      headers: _defaultHeaders(),
      body: jsonEncode({
        'user_id': userId,
        'role': role,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update role (${res.statusCode})');
    }
  }

  // ---------- ADMIN: DELETE USER ----------
  static Future<void> adminDeleteUser(int userId) async {
    final url = Uri.parse('$baseUrl/admin_delete_user.php');
    final res = await http.post(
      url,
      headers: _defaultHeaders(),
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete user (${res.statusCode})');
    }
  }

  // ---------- GET ORDER HISTORY -------------
  static Future<List<OrderItem>> getOrderHistory(int userId) async {
    final url = Uri.parse('$baseUrl/get_order_history.php?user_id=$userId');
    final res = await http.get(
      url,
      headers: {'ngrok-skip-browser-warning': 'true'},
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load order history (${res.statusCode})');
    }
  }

  //----------- PURCHASE POST ----------------
  static Future<double> purchasePost({
    required int buyerId,
    required int postId,
  }) async {
    final url = Uri.parse('$baseUrl/purchase_post.php');
    final headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'buyer_id': buyerId,
        'post_id': postId,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return double.parse(data['new_balance'].toString());
    } else {
      String message = 'Purchase failed (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
