import 'dart:convert';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class WalletService {
  static const _balanceKey = 'wallet_balance';

  static String get _updateBalanceUrl =>
      '${ApiService.baseUrl}update_balance.php';
  static String get _getBalanceUrl => '${ApiService.baseUrl}get_balance.php';

  // ดึงจาก server แล้ว cache
  static Future<double> getBalanceFromServer(int userId) async {
    final url = Uri.parse('$_getBalanceUrl?user_id=$userId');
    // debugPrint('[Wallet] GET balance url=$url userId=$userId');

    final res = await http.get(url, headers: {
      'ngrok-skip-browser-warning': 'true',
    });

    // debugPrint('[Wallet] GET balance status=${res.statusCode}');
    // debugPrint('[Wallet] GET balance body=${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final balance = (data['balance'] ?? 0).toDouble();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_balanceKey, balance);
      // debugPrint('[Wallet] GET balance parsed=$balance');
      return balance;
    } else {
      throw Exception('Failed to get balance (${res.statusCode})');
    }
  }

  // ใช้ local cache เวลาแสดงทันที
  static Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_balanceKey) ?? 0.0;
    // debugPrint('[Wallet] Local cached balance=$b');
    return b;
  }

  // ปรับยอด + อัปเดต cache
  static Future<double> adjustBalance({
    required int userId,
    required double delta,
  }) async {
    final url = Uri.parse(_updateBalanceUrl);
    // debugPrint('[Wallet] Adjust balance url=$url userId=$userId delta=$delta');

    final body = jsonEncode({'user_id': userId, 'delta': delta});
    // debugPrint('[Wallet] Adjust body=$body');

    final res = await http.post(
      url,
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // debugPrint('[Wallet] Adjust status=${res.statusCode}');
    // debugPrint('[Wallet] Adjust raw body=${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newBalance = (data['balance'] ?? 0).toDouble();
      // debugPrint('[Wallet] Adjust newBalance=$newBalance');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_balanceKey, newBalance);

      return newBalance;
    } else {
      throw Exception('ปรับยอดไม่สำเร็จ (${res.statusCode})');
    }
  }

  // เซ็ตค่า balance ตรง ๆ แล้ว cache ไว้
  static Future<void> setBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, balance);
  }
}
