class CommunitySirenInstitute {
  final int id;
  final String name;
  final String? logo;
  final String? phone;
  final String? address;

  CommunitySirenInstitute({
    required this.id,
    required this.name,
    this.logo,
    this.phone,
    this.address,
  });

  factory CommunitySirenInstitute.fromJson(Map<String, dynamic> json) {
    return CommunitySirenInstitute(
      id: json['id'],
      name: json['name'] ?? '',
      logo: json['logo'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}

class CommunitySirenBuzzer {
  final int id;
  final String title;
  final int? device;
  final String deviceImei;
  final String devicePhone;
  final int institute;
  final String instituteName;
  final String? instituteLogo;
  final int delay;
  final BuzzerStatus? buzzerStatus;
  final String createdAt;
  final String updatedAt;

  CommunitySirenBuzzer({
    required this.id,
    required this.title,
    this.device,
    required this.deviceImei,
    required this.devicePhone,
    required this.institute,
    required this.instituteName,
    this.instituteLogo,
    required this.delay,
    this.buzzerStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunitySirenBuzzer.fromJson(Map<String, dynamic> json) {
    return CommunitySirenBuzzer(
      id: json['id'],
      title: json['title'] ?? '',
      device: json['device'],
      deviceImei: json['device_imei'] ?? '',
      devicePhone: json['device_phone'] ?? '',
      institute: json['institute'],
      instituteName: json['institute_name'] ?? '',
      instituteLogo: json['institute_logo'],
      delay: json['delay'] ?? 0,
      buzzerStatus: json['buzzer_status'] != null
          ? BuzzerStatus.fromJson(json['buzzer_status'])
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class BuzzerStatus {
  final int battery;
  final int signal;
  final bool ignition;
  final bool charging;
  final bool relay;
  final String? lastUpdated;

  BuzzerStatus({
    required this.battery,
    required this.signal,
    required this.ignition,
    required this.charging,
    required this.relay,
    this.lastUpdated,
  });

  factory BuzzerStatus.fromJson(Map<String, dynamic> json) {
    return BuzzerStatus(
      battery: json['battery'] ?? 0,
      signal: json['signal'] ?? 0,
      ignition: json['ignition'] ?? false,
      charging: json['charging'] ?? false,
      relay: json['relay'] ?? false,
      lastUpdated: json['last_updated'],
    );
  }
}

class CommunitySirenAccess {
  final bool hasAccess;
  final bool hasModuleAccess;
  final CommunitySirenInstitute? institute;
  final CommunitySirenBuzzer? buzzer;
  final List<CommunitySirenSwitch> switches;

  CommunitySirenAccess({
    required this.hasAccess,
    required this.hasModuleAccess,
    this.institute,
    this.buzzer,
    this.switches = const [],
  });

  factory CommunitySirenAccess.fromJson(Map<String, dynamic> json) {
    return CommunitySirenAccess(
      hasAccess: json['has_access'] ?? false,
      hasModuleAccess: json['has_module_access'] ?? false,
      institute: json['institute'] != null
          ? CommunitySirenInstitute.fromJson(json['institute'])
          : null,
      buzzer: json['buzzer'] != null
          ? CommunitySirenBuzzer.fromJson(json['buzzer'])
          : null,
      switches: json['switches'] != null
          ? (json['switches'] as List)
              .map((item) => CommunitySirenSwitch.fromJson(item))
              .toList()
          : [],
    );
  }
}

class CommunitySirenSwitch {
  final int id;
  final String title;
  final int? device;
  final String deviceImei;
  final String devicePhone;
  final int institute;
  final String instituteName;
  final String? instituteLogo;
  final double latitude;
  final double longitude;
  final int trigger;
  final String primaryPhone;
  final String? secondaryPhone;
  final String? image;
  final BuzzerStatus? switchStatus;
  final String createdAt;
  final String updatedAt;

  CommunitySirenSwitch({
    required this.id,
    required this.title,
    this.device,
    required this.deviceImei,
    required this.devicePhone,
    required this.institute,
    required this.instituteName,
    this.instituteLogo,
    required this.latitude,
    required this.longitude,
    required this.trigger,
    required this.primaryPhone,
    this.secondaryPhone,
    this.image,
    this.switchStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunitySirenSwitch.fromJson(Map<String, dynamic> json) {
    return CommunitySirenSwitch(
      id: json['id'],
      title: json['title'] ?? '',
      device: json['device'],
      deviceImei: json['device_imei'] ?? '',
      devicePhone: json['device_phone'] ?? '',
      institute: json['institute'],
      instituteName: json['institute_name'] ?? '',
      instituteLogo: json['institute_logo'],
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      trigger: json['trigger'] ?? 0,
      primaryPhone: json['primary_phone'] ?? '',
      secondaryPhone: json['secondary_phone'],
      image: json['image'],
      switchStatus: json['switch_status'] != null
          ? BuzzerStatus.fromJson(json['switch_status'])
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class CommunitySirenHistoryCreate {
  final String source;
  final String name;
  final String primaryPhone;
  final String? secondaryPhone;
  final double latitude;
  final double longitude;
  final String datetime;
  final String? remarks;
  final String status;
  final int institute;
  final int? member;

  CommunitySirenHistoryCreate({
    required this.source,
    required this.name,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.latitude,
    required this.longitude,
    required this.datetime,
    this.remarks,
    required this.status,
    required this.institute,
    this.member,
  });

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'name': name,
      'primary_phone': primaryPhone,
      if (secondaryPhone != null) 'secondary_phone': secondaryPhone,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'datetime': datetime,
      if (remarks != null) 'remarks': remarks,
      'status': status,
      'institute': institute,
      if (member != null) 'member': member,
    };
  }
}

