import 'package:flutter/material.dart';

class Vendor {
  final String id; 
  final String name;
  final String email;
  final String image;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
  });

  factory Vendor.fromMap(String id, Map<String, dynamic> data) {
    return Vendor(
      id: id,
      name: data['name'],
      email: data['email'],
      image: data['image'],
    );
  }
}
