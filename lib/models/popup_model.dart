class Popup {
  final int id;
  final String title;
  final String message;
  final String? image;
  final String? imageUrl; // Full URL for display
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Popup({
    required this.id,
    required this.title,
    required this.message,
    this.image,
    this.imageUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Popup.fromJson(Map<String, dynamic> json) {
    return Popup(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      image: json['image'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
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
      'message': message,
      'image': image,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Popup copyWith({
    int? id,
    String? title,
    String? message,
    String? image,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Popup(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}