class AlertType {
  final int id;
  final String name;
  final String? icon;

  AlertType({required this.id, required this.name, this.icon});

  factory AlertType.fromJson(Map<String, dynamic> json) {
    return AlertType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
