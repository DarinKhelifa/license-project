class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String photo;
  final String cinId;
  final String address;
  final String phone;
  final String email;
  final String workCategory;
  final String experience;
  final String casierJudiciaire;
  final String status;
  final DateTime hiredDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.photo,
    required this.cinId,
    required this.address,
    required this.phone,
    required this.email,
    required this.workCategory,
    required this.experience,
    required this.casierJudiciaire,
    required this.status,
    required this.hiredDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromMap(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      cinId: json['cinId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      workCategory: json['workCategory'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      casierJudiciaire: json['casierJudiciaire'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      hiredDate: json['hiredDate'] != null
          ? DateTime.parse(json['hiredDate'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    '_id': id,
    'firstName': firstName,
    'lastName': lastName,
    'photo': photo,
    'cinId': cinId,
    'address': address,
    'phone': phone,
    'email': email,
    'workCategory': workCategory,
    'experience': experience,
    'casierJudiciaire': casierJudiciaire,
    'status': status,
    'hiredDate': hiredDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get fullName => '$firstName $lastName';
}