import 'package:flutter/material.dart';

class StaffMember {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final int hourlyRate;
  final String imageUrl;
  final int yearsOfExperience;

  StaffMember({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.hourlyRate,
    required this.imageUrl,
    required this.yearsOfExperience,
  });
}
