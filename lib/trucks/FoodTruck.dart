class FoodTruck {
  final String name;
  final String description;
  final String image;

  FoodTruck(this.image, {required this.name, required this.description});
}

class FoodCategory {
  final String name;
  final double price;
  final String image;

  FoodCategory({required this.name, required this.price, required this.image});
}
