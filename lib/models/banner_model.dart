class Banner {
  final int id;
  final String title;
  final String? image;
  final String? imageUrl; // Full URL for display
  final String? url;
  final bool isActive;
  final int click;
  final int orderPosition;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Banner({
    required this.id,
    required this.title,
    this.image,
    this.imageUrl,
    this.url,
    required this.isActive,
    required this.click,
    this.orderPosition = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'],
      imageUrl: json['imageUrl'],
      url: json['url'],
      isActive: json['isActive'] ?? true,
      click: json['click'] ?? 0,
      orderPosition: json['orderPosition'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'imageUrl': imageUrl,
      'url': url,
      'isActive': isActive,
      'click': click,
      'orderPosition': orderPosition,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Banner copyWith({
    int? id,
    String? title,
    String? image,
    String? imageUrl,
    String? url,
    bool? isActive,
    int? click,
    int? orderPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      isActive: isActive ?? this.isActive,
      click: click ?? this.click,
      orderPosition: orderPosition ?? this.orderPosition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

