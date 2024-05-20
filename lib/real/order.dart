import 'package:second/real/food.dart';

class Order {
  final String orderId;
  final String customerId;
  final List<Food> items;
  final double totalAmount;
  final DateTime createdAt;
  final String status; 

  Order({
    required this.orderId,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.status,
  });
}