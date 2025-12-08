class DueTransaction {
  final int id;
  final int user;
  final UserInfo userInfo;
  final int? paidBy;
  final UserInfo? paidByInfo;
  final double subtotal;
  final double vat;
  final double total;
  final double? displaySubtotal;
  final double? displayVat;
  final double? displayTotal;
  final bool? showVat;
  final bool? showDealerPrice;
  final DateTime renewDate;
  final DateTime expireDate;
  final bool isPaid;
  final DateTime? payDate;
  final List<DueTransactionParticular> particulars;
  final DateTime createdAt;
  final DateTime updatedAt;

  DueTransaction({
    required this.id,
    required this.user,
    required this.userInfo,
    this.paidBy,
    this.paidByInfo,
    required this.subtotal,
    required this.vat,
    required this.total,
    this.displaySubtotal,
    this.displayVat,
    this.displayTotal,
    this.showVat,
    this.showDealerPrice,
    required this.renewDate,
    required this.expireDate,
    required this.isPaid,
    this.payDate,
    required this.particulars,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DueTransaction.fromJson(Map<String, dynamic> json) {
    return DueTransaction(
      id: json['id'] ?? 0,
      user: json['user'] ?? 0,
      userInfo: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'])
          : UserInfo(id: 0, name: '', phone: '', isActive: false),
      paidBy: json['paid_by'],
      paidByInfo: json['paid_by_info'] != null
          ? UserInfo.fromJson(json['paid_by_info'])
          : null,
      subtotal: (json['subtotal'] is String)
          ? double.tryParse(json['subtotal']) ?? 0.0
          : (json['subtotal'] ?? 0.0).toDouble(),
      vat: (json['vat'] is String)
          ? double.tryParse(json['vat']) ?? 0.0
          : (json['vat'] ?? 0.0).toDouble(),
      total: (json['total'] is String)
          ? double.tryParse(json['total']) ?? 0.0
          : (json['total'] ?? 0.0).toDouble(),
      displaySubtotal: json['display_subtotal'] != null
          ? ((json['display_subtotal'] is String)
              ? double.tryParse(json['display_subtotal'])
              : (json['display_subtotal'] as num).toDouble())
          : null,
      displayVat: json['display_vat'] != null
          ? ((json['display_vat'] is String)
              ? double.tryParse(json['display_vat'])
              : (json['display_vat'] as num).toDouble())
          : null,
      displayTotal: json['display_total'] != null
          ? ((json['display_total'] is String)
              ? double.tryParse(json['display_total'])
              : (json['display_total'] as num).toDouble())
          : null,
      showVat: json['show_vat'],
      showDealerPrice: json['show_dealer_price'],
      renewDate: json['renew_date'] != null
          ? DateTime.parse(json['renew_date'])
          : DateTime.now(),
      expireDate: json['expire_date'] != null
          ? DateTime.parse(json['expire_date'])
          : DateTime.now(),
      isPaid: json['is_paid'] ?? false,
      payDate: json['pay_date'] != null
          ? DateTime.parse(json['pay_date'])
          : null,
      particulars: json['particulars'] != null
          ? (json['particulars'] as List)
              .map((p) => DueTransactionParticular.fromJson(p))
              .toList()
          : [],
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
      'user': user,
      'user_info': userInfo.toJson(),
      'paid_by': paidBy,
      'paid_by_info': paidByInfo?.toJson(),
      'subtotal': subtotal,
      'vat': vat,
      'total': total,
      'display_subtotal': displaySubtotal,
      'display_vat': displayVat,
      'display_total': displayTotal,
      'show_vat': showVat,
      'show_dealer_price': showDealerPrice,
      'renew_date': renewDate.toIso8601String(),
      'expire_date': expireDate.toIso8601String(),
      'is_paid': isPaid,
      'pay_date': payDate?.toIso8601String(),
      'particulars': particulars.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get effectiveTotal => displayTotal ?? total;
  double get effectiveSubtotal => displaySubtotal ?? subtotal;
  double? get effectiveVat => displayVat ?? (showVat == true ? vat : null);
}

class DueTransactionListItem {
  final int id;
  final int user;
  final String userName;
  final String userPhone;
  final double subtotal;
  final double vat;
  final double total;
  final double? displayTotal;
  final bool? showVat;
  final DateTime renewDate;
  final DateTime expireDate;
  final bool isPaid;
  final DateTime? payDate;
  final int particularsCount;
  final DateTime createdAt;

  DueTransactionListItem({
    required this.id,
    required this.user,
    required this.userName,
    required this.userPhone,
    required this.subtotal,
    required this.vat,
    required this.total,
    this.displayTotal,
    this.showVat,
    required this.renewDate,
    required this.expireDate,
    required this.isPaid,
    this.payDate,
    required this.particularsCount,
    required this.createdAt,
  });

  factory DueTransactionListItem.fromJson(Map<String, dynamic> json) {
    return DueTransactionListItem(
      id: json['id'] ?? 0,
      user: json['user'] ?? 0,
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      subtotal: (json['subtotal'] is String)
          ? double.tryParse(json['subtotal']) ?? 0.0
          : (json['subtotal'] ?? 0.0).toDouble(),
      vat: (json['vat'] is String)
          ? double.tryParse(json['vat']) ?? 0.0
          : (json['vat'] ?? 0.0).toDouble(),
      total: (json['total'] is String)
          ? double.tryParse(json['total']) ?? 0.0
          : (json['total'] ?? 0.0).toDouble(),
      displayTotal: json['display_total'] != null
          ? ((json['display_total'] is String)
              ? double.tryParse(json['display_total'])
              : (json['display_total'] as num).toDouble())
          : null,
      showVat: json['show_vat'],
      renewDate: json['renew_date'] != null
          ? DateTime.parse(json['renew_date'])
          : DateTime.now(),
      expireDate: json['expire_date'] != null
          ? DateTime.parse(json['expire_date'])
          : DateTime.now(),
      isPaid: json['is_paid'] ?? false,
      payDate: json['pay_date'] != null
          ? DateTime.parse(json['pay_date'])
          : null,
      particularsCount: json['particulars_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'user_name': userName,
      'user_phone': userPhone,
      'subtotal': subtotal,
      'vat': vat,
      'total': total,
      'display_total': displayTotal,
      'show_vat': showVat,
      'renew_date': renewDate.toIso8601String(),
      'expire_date': expireDate.toIso8601String(),
      'is_paid': isPaid,
      'pay_date': payDate?.toIso8601String(),
      'particulars_count': particularsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get effectiveTotal => displayTotal ?? total;
}

class VehicleRenewalPrice {
  final double customerPrice;
  final double? dealerPrice;
  final double displayPrice;
  final double vatPercent;
  final double vatAmount;
  final double totalAmount;

  VehicleRenewalPrice({
    required this.customerPrice,
    this.dealerPrice,
    required this.displayPrice,
    required this.vatPercent,
    required this.vatAmount,
    required this.totalAmount,
  });

  factory VehicleRenewalPrice.fromJson(Map<String, dynamic> json) {
    return VehicleRenewalPrice(
      customerPrice: (json['customer_price'] is String)
          ? double.tryParse(json['customer_price']) ?? 0.0
          : (json['customer_price'] ?? 0.0).toDouble(),
      dealerPrice: json['dealer_price'] != null
          ? ((json['dealer_price'] is String)
              ? double.tryParse(json['dealer_price'])
              : (json['dealer_price'] as num).toDouble())
          : null,
      displayPrice: (json['display_price'] is String)
          ? double.tryParse(json['display_price']) ?? 0.0
          : (json['display_price'] ?? 0.0).toDouble(),
      vatPercent: (json['vat_percent'] is String)
          ? double.tryParse(json['vat_percent']) ?? 0.0
          : (json['vat_percent'] ?? 0.0).toDouble(),
      vatAmount: (json['vat_amount'] is String)
          ? double.tryParse(json['vat_amount']) ?? 0.0
          : (json['vat_amount'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] is String)
          ? double.tryParse(json['total_amount']) ?? 0.0
          : (json['total_amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_price': customerPrice,
      'dealer_price': dealerPrice,
      'display_price': displayPrice,
      'vat_percent': vatPercent,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
    };
  }
}

class DueTransactionParticular {
  final int id;
  final String particular;
  final String type; // 'vehicle' | 'parent'
  final int? institute;
  final String? instituteName;
  final int? vehicle;
  final int? vehicleId;
  final VehicleInfo? vehicleInfo;
  final double amount;
  final double? dealerAmount;
  final double? displayAmount;
  final bool? isDealerView;
  final int quantity;
  final double total;
  final DateTime createdAt;

  DueTransactionParticular({
    required this.id,
    required this.particular,
    required this.type,
    this.institute,
    this.instituteName,
    this.vehicle,
    this.vehicleId,
    this.vehicleInfo,
    required this.amount,
    this.dealerAmount,
    this.displayAmount,
    this.isDealerView,
    required this.quantity,
    required this.total,
    required this.createdAt,
  });

  factory DueTransactionParticular.fromJson(Map<String, dynamic> json) {
    return DueTransactionParticular(
      id: json['id'] ?? 0,
      particular: json['particular'] ?? '',
      type: json['type'] ?? 'vehicle',
      institute: json['institute'],
      instituteName: json['institute_name'],
      vehicle: json['vehicle'],
      vehicleId: json['vehicle_id'],
      vehicleInfo: json['vehicle_info'] != null
          ? VehicleInfo.fromJson(json['vehicle_info'])
          : null,
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] ?? 0.0).toDouble(),
      dealerAmount: json['dealer_amount'] != null
          ? ((json['dealer_amount'] is String)
              ? double.tryParse(json['dealer_amount'])
              : (json['dealer_amount'] as num).toDouble())
          : null,
      displayAmount: json['display_amount'] != null
          ? ((json['display_amount'] is String)
              ? double.tryParse(json['display_amount'])
              : (json['display_amount'] as num).toDouble())
          : null,
      isDealerView: json['is_dealer_view'],
      quantity: json['quantity'] ?? 1,
      total: (json['total'] is String)
          ? double.tryParse(json['total']) ?? 0.0
          : (json['total'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'particular': particular,
      'type': type,
      'institute': institute,
      'institute_name': instituteName,
      'vehicle': vehicle,
      'vehicle_id': vehicleId,
      'vehicle_info': vehicleInfo?.toJson(),
      'amount': amount,
      'dealer_amount': dealerAmount,
      'display_amount': displayAmount,
      'is_dealer_view': isDealerView,
      'quantity': quantity,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get effectiveAmount => displayAmount ?? amount;
  bool get isVehicle => type == 'vehicle';
  bool get isParent => type == 'parent';
}

class VehicleInfo {
  final int id;
  final String imei;
  final String name;
  final String vehicleNo;

  VehicleInfo({
    required this.id,
    required this.imei,
    required this.name,
    required this.vehicleNo,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['id'] ?? 0,
      imei: json['imei'] ?? '',
      name: json['name'] ?? '',
      vehicleNo: json['vehicleNo'] ?? json['vehicle_no'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'name': name,
      'vehicleNo': vehicleNo,
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

