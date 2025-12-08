class PaymentTransaction {
  final int id;
  final int user;
  final String userName;
  final String userPhone;
  final int wallet;
  final String txnId;
  final String referenceId;
  final double amount;
  final int amountPaisa;
  final String status; // 'PENDING' | 'SUCCESS' | 'FAILED' | 'ERROR' | 'CANCELLED'
  final String statusDisplay;
  final int? connectipsTxnId;
  final int? connectipsBatchId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.user,
    required this.userName,
    required this.userPhone,
    required this.wallet,
    required this.txnId,
    required this.referenceId,
    required this.amount,
    required this.amountPaisa,
    required this.status,
    required this.statusDisplay,
    this.connectipsTxnId,
    this.connectipsBatchId,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] is int ? json['id'] : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
      user: json['user'] is int ? json['user'] : (json['user'] is String ? int.tryParse(json['user']) ?? 0 : 0),
      userName: json['user_name']?.toString() ?? '',
      userPhone: json['user_phone']?.toString() ?? '',
      wallet: json['wallet'] is int ? json['wallet'] : (json['wallet'] is String ? int.tryParse(json['wallet']) ?? 0 : 0),
      txnId: json['txn_id']?.toString() ?? '',
      referenceId: json['reference_id']?.toString() ?? '',
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] is num ? json['amount'].toDouble() : 0.0),
      amountPaisa: json['amount_paisa'] is int ? json['amount_paisa'] : (json['amount_paisa'] is String ? int.tryParse(json['amount_paisa']) ?? 0 : 0),
      status: json['status']?.toString() ?? 'PENDING',
      statusDisplay: json['status_display']?.toString() ?? 'Pending',
      connectipsTxnId: json['connectips_txn_id'] != null
          ? (json['connectips_txn_id'] is int ? json['connectips_txn_id'] : int.tryParse(json['connectips_txn_id'].toString()))
          : null,
      connectipsBatchId: json['connectips_batch_id'] != null
          ? (json['connectips_batch_id'] is int ? json['connectips_batch_id'] : int.tryParse(json['connectips_batch_id'].toString()))
          : null,
      errorMessage: json['error_message']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'user_name': userName,
      'user_phone': userPhone,
      'wallet': wallet,
      'txn_id': txnId,
      'reference_id': referenceId,
      'amount': amount,
      'amount_paisa': amountPaisa,
      'status': status,
      'status_display': statusDisplay,
      'connectips_txn_id': connectipsTxnId,
      'connectips_batch_id': connectipsBatchId,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isError => status == 'ERROR';
  bool get isCancelled => status == 'CANCELLED';
}

class PaymentFormData {
  final String merchantId;
  final String appId;
  final String appName;
  final String txnId;
  final String txnDate;
  final String txnCrncy;
  final String txnAmt;
  final String referenceId;
  final String remarks;
  final String particulars;
  final String token;
  final String gatewayUrl;
  final String successUrl;
  final String failureUrl;

  PaymentFormData({
    required this.merchantId,
    required this.appId,
    required this.appName,
    required this.txnId,
    required this.txnDate,
    required this.txnCrncy,
    required this.txnAmt,
    required this.referenceId,
    required this.remarks,
    required this.particulars,
    required this.token,
    required this.gatewayUrl,
    required this.successUrl,
    required this.failureUrl,
  });

  factory PaymentFormData.fromJson(Map<String, dynamic> json) {
    return PaymentFormData(
      merchantId: json['MERCHANTID']?.toString() ?? '',
      appId: json['APPID']?.toString() ?? '',
      appName: json['APPNAME']?.toString() ?? '',
      txnId: json['TXNID']?.toString() ?? '',
      txnDate: json['TXNDATE']?.toString() ?? '',
      txnCrncy: json['TXNCRNCY']?.toString() ?? 'NPR',
      txnAmt: json['TXNAMT']?.toString() ?? '',
      referenceId: json['REFERENCEID']?.toString() ?? '',
      remarks: json['REMARKS']?.toString() ?? '',
      particulars: json['PARTICULARS']?.toString() ?? '',
      token: json['TOKEN']?.toString() ?? '',
      gatewayUrl: json['gateway_url']?.toString() ?? '',
      successUrl: json['success_url']?.toString() ?? '',
      failureUrl: json['failure_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MERCHANTID': merchantId,
      'APPID': appId,
      'APPNAME': appName,
      'TXNID': txnId,
      'TXNDATE': txnDate,
      'TXNCRNCY': txnCrncy,
      'TXNAMT': txnAmt,
      'REFERENCEID': referenceId,
      'REMARKS': remarks,
      'PARTICULARS': particulars,
      'TOKEN': token,
      'gateway_url': gatewayUrl,
      'success_url': successUrl,
      'failure_url': failureUrl,
    };
  }
}

class PaymentInitiateRequest {
  final double amount;
  final String? remarks;
  final String? particulars;

  PaymentInitiateRequest({
    required this.amount,
    this.remarks,
    this.particulars,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toStringAsFixed(2), // Send as string to match DecimalField
      'remarks': remarks ?? '',
      'particulars': particulars ?? '',
    };
  }
}

class PaymentCallbackParams {
  final String? txnId;
  final String? status; // 'success' | 'failure'

  PaymentCallbackParams({
    this.txnId,
    this.status,
  });

  factory PaymentCallbackParams.fromUrl(String url) {
    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;
    
    return PaymentCallbackParams(
      txnId: queryParams['txn_id'] ?? queryParams['TXNID'],
      status: queryParams['status']?.toLowerCase(),
    );
  }
}

class PaymentValidateRequest {
  final String txnId;

  PaymentValidateRequest({
    required this.txnId,
  });

  Map<String, dynamic> toJson() {
    return {
      'txn_id': txnId,
    };
  }
}

