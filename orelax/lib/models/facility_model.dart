class Facility {
  String id;
  String name;
  String description;
  int capacity;
  String hours;
  List<String> imagesBase64; // Store Base64 strings instead of URLs
  List<String> features;
  List<String> rules;
  double pricePerHour;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Facility({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
    required this.hours,
    required this.imagesBase64,
    required this.features,
    required this.rules,
    required this.pricePerHour,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
      'hours': hours,
      'imagesBase64': imagesBase64,
      'features': features,
      'rules': rules,
      'pricePerHour': pricePerHour,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Facility.fromMap(Map<String, dynamic> map) {
    return Facility(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      capacity: map['capacity']?.toInt() ?? 0,
      hours: map['hours'] ?? '',
      imagesBase64: List<String>.from(map['imagesBase64'] ?? []),
      features: List<String>.from(map['features'] ?? []),
      rules: List<String>.from(map['rules'] ?? []),
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Facility copyWith({
    String? id,
    String? name,
    String? description,
    int? capacity,
    String? hours,
    List<String>? imagesBase64,
    List<String>? features,
    List<String>? rules,
    double? pricePerHour,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Facility(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      hours: hours ?? this.hours,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
      features: features ?? this.features,
      rules: rules ?? this.rules,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}