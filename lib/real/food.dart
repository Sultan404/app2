class Food {
   String? id;
   String? name;
   double? price;
   String? image;
   String? vendorId;
   String? vendorName;
   int? quantity;
   bool userRated ;
   String? category;
   

  Food( {
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.vendorId,
    required this.vendorName,
    required int this.quantity,

     this.userRated= false,
     this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': quantity,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'image': image,
      'userRated': userRated,
      'category': category,
    };
  }

}
