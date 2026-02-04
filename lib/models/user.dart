class User {
  final int id;
  final String email;
  final String password;
  final String displayName;
  final String role;
  final double balance;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    required this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    double doubleBalance;

    if (rawBalance == null) {
      doubleBalance = 0.0; // หรือค่าที่คุณอยากตั้งเป็น default
    } else if (rawBalance is int) {
      doubleBalance = rawBalance.toDouble();
    } else {
      doubleBalance = double.parse(rawBalance.toString());
    }

    return User(
      id: int.parse(json['id'].toString()),
      email: json['email'] as String,
      password: '',
      displayName: json['display_name'] as String,
      role: (json['role'] ?? 'user') as String,
      balance: doubleBalance,
    );
  }
}
