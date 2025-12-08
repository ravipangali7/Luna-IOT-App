class Transaction {
  final int id;
  final int wallet;
  final double amount;
  final String transactionType; // 'CREDIT' | 'DEBIT'
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final PerformedBy? performedBy;
  final String transactionReference;
  final String status; // 'PENDING' | 'COMPLETED' | 'FAILED'
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.wallet,
    required this.amount,
    required this.transactionType,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.performedBy,
    required this.transactionReference,
    required this.status,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Safely parse performed_by - handle both Map and null cases
    PerformedBy? performedBy;
    if (json['performed_by'] != null) {
      if (json['performed_by'] is Map<String, dynamic>) {
        performedBy = PerformedBy.fromJson(json['performed_by'] as Map<String, dynamic>);
      } else if (json['performed_by'] is Map) {
        // Handle case where it's a Map but not explicitly typed
        performedBy = PerformedBy.fromJson(Map<String, dynamic>.from(json['performed_by']));
      }
      // If it's an int or other type, leave as null
    }
    
    return Transaction(
      id: json['id'] is int ? json['id'] : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
      wallet: json['wallet'] is int ? json['wallet'] : (json['wallet'] is String ? int.tryParse(json['wallet']) ?? 0 : 0),
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] is num ? json['amount'].toDouble() : 0.0),
      transactionType: json['transaction_type'] ?? 'CREDIT',
      balanceBefore: (json['balance_before'] is String)
          ? double.tryParse(json['balance_before']) ?? 0.0
          : (json['balance_before'] is num ? json['balance_before'].toDouble() : 0.0),
      balanceAfter: (json['balance_after'] is String)
          ? double.tryParse(json['balance_after']) ?? 0.0
          : (json['balance_after'] is num ? json['balance_after'].toDouble() : 0.0),
      description: json['description']?.toString() ?? '',
      performedBy: performedBy,
      transactionReference: json['transaction_reference']?.toString() ?? '',
      status: json['status']?.toString() ?? 'COMPLETED',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet': wallet,
      'amount': amount,
      'transaction_type': transactionType,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'description': description,
      'performed_by': performedBy?.toJson(),
      'transaction_reference': transactionReference,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => transactionType == 'CREDIT';
  bool get isDebit => transactionType == 'DEBIT';
  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

class TransactionListItem {
  final int id;
  final String userName;
  final String userPhone;
  final double amount;
  final String transactionType;
  final String transactionTypeDisplay;
  final double balanceAfter;
  final String description;
  final String performedByName;
  final String status;
  final String statusDisplay;
  final DateTime createdAt;

  TransactionListItem({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.amount,
    required this.transactionType,
    required this.transactionTypeDisplay,
    required this.balanceAfter,
    required this.description,
    required this.performedByName,
    required this.status,
    required this.statusDisplay,
    required this.createdAt,
  });

  factory TransactionListItem.fromJson(Map<String, dynamic> json) {
    return TransactionListItem(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] ?? 0.0).toDouble(),
      transactionType: json['transaction_type'] ?? 'CREDIT',
      transactionTypeDisplay: json['transaction_type_display'] ?? 'Credit',
      balanceAfter: (json['balance_after'] is String)
          ? double.tryParse(json['balance_after']) ?? 0.0
          : (json['balance_after'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      performedByName: json['performed_by_name'] ?? '',
      status: json['status'] ?? 'COMPLETED',
      statusDisplay: json['status_display'] ?? 'Completed',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_phone': userPhone,
      'amount': amount,
      'transaction_type': transactionType,
      'transaction_type_display': transactionTypeDisplay,
      'balance_after': balanceAfter,
      'description': description,
      'performed_by_name': performedByName,
      'status': status,
      'status_display': statusDisplay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => transactionType == 'CREDIT';
  bool get isDebit => transactionType == 'DEBIT';
  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

class PerformedBy {
  final int id;
  final String name;
  final String phone;

  PerformedBy({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory PerformedBy.fromJson(Map<String, dynamic> json) {
    return PerformedBy(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}

class TransactionSummary {
  final int totalTransactions;
  final double totalCredit;
  final double totalDebit;
  final double netChange;
  final int pendingTransactions;
  final int completedTransactions;
  final int failedTransactions;
  final int dateRangeDays;

  TransactionSummary({
    required this.totalTransactions,
    required this.totalCredit,
    required this.totalDebit,
    required this.netChange,
    required this.pendingTransactions,
    required this.completedTransactions,
    required this.failedTransactions,
    required this.dateRangeDays,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalTransactions: json['total_transactions'] ?? 0,
      totalCredit: (json['total_credit'] is String)
          ? double.tryParse(json['total_credit']) ?? 0.0
          : (json['total_credit'] ?? 0.0).toDouble(),
      totalDebit: (json['total_debit'] is String)
          ? double.tryParse(json['total_debit']) ?? 0.0
          : (json['total_debit'] ?? 0.0).toDouble(),
      netChange: (json['net_change'] is String)
          ? double.tryParse(json['net_change']) ?? 0.0
          : (json['net_change'] ?? 0.0).toDouble(),
      pendingTransactions: json['pending_transactions'] ?? 0,
      completedTransactions: json['completed_transactions'] ?? 0,
      failedTransactions: json['failed_transactions'] ?? 0,
      dateRangeDays: json['date_range_days'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_transactions': totalTransactions,
      'total_credit': totalCredit,
      'total_debit': totalDebit,
      'net_change': netChange,
      'pending_transactions': pendingTransactions,
      'completed_transactions': completedTransactions,
      'failed_transactions': failedTransactions,
      'date_range_days': dateRangeDays,
    };
  }
}

