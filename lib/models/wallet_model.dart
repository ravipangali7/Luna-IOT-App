import 'transaction_model.dart' show Transaction;

class Wallet {
  final int id;
  final double balance;
  final int user;
  final UserInfo userInfo;
  final double? callPrice;
  final double? smsPrice;
  final List<Transaction>? recentTransactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.balance,
    required this.user,
    required this.userInfo,
    this.callPrice,
    this.smsPrice,
    this.recentTransactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? 0,
      balance: (json['balance'] is String)
          ? double.tryParse(json['balance']) ?? 0.0
          : (json['balance'] ?? 0.0).toDouble(),
      user: json['user'] ?? 0,
      userInfo: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'])
          : UserInfo(id: 0, name: '', phone: '', isActive: false),
      callPrice: json['call_price'] != null
          ? ((json['call_price'] is String)
              ? double.tryParse(json['call_price'])
              : (json['call_price'] as num).toDouble())
          : null,
      smsPrice: json['sms_price'] != null
          ? ((json['sms_price'] is String)
              ? double.tryParse(json['sms_price'])
              : (json['sms_price'] as num).toDouble())
          : null,
      recentTransactions: json['recent_transactions'] != null
          ? (json['recent_transactions'] as List)
              .map((t) => Transaction.fromJson(t))
              .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'user': user,
      'user_info': userInfo.toJson(),
      'call_price': callPrice,
      'sms_price': smsPrice,
      'recent_transactions': recentTransactions?.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WalletListItem {
  final int id;
  final double balance;
  final String userName;
  final String userPhone;
  final double? callPrice;
  final double? smsPrice;
  final DateTime createdAt;

  WalletListItem({
    required this.id,
    required this.balance,
    required this.userName,
    required this.userPhone,
    this.callPrice,
    this.smsPrice,
    required this.createdAt,
  });

  factory WalletListItem.fromJson(Map<String, dynamic> json) {
    return WalletListItem(
      id: json['id'] ?? 0,
      balance: (json['balance'] is String)
          ? double.tryParse(json['balance']) ?? 0.0
          : (json['balance'] ?? 0.0).toDouble(),
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      callPrice: json['call_price'] != null
          ? ((json['call_price'] is String)
              ? double.tryParse(json['call_price'])
              : (json['call_price'] as num).toDouble())
          : null,
      smsPrice: json['sms_price'] != null
          ? ((json['sms_price'] is String)
              ? double.tryParse(json['sms_price'])
              : (json['sms_price'] as num).toDouble())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'user_name': userName,
      'user_phone': userPhone,
      'call_price': callPrice,
      'sms_price': smsPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserInfo {
  final int id;
  final String name;
  final String phone;
  final bool isActive;

  UserInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.isActive,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'is_active': isActive,
    };
  }
}

