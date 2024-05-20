import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:second/real/food.dart';
import 'package:second/real/food_truck.dart';
import 'package:second/real/vendor.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVendor(Vendor vendor) async {
    await _firestore.collection('vendors').doc(vendor.id).set({
      'name': vendor.name,
      'email': vendor.email,
      'image': vendor.image,
    });
  }

  Future<List<Vendor>> getVendors() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('vendors').get();
      return querySnapshot.docs
          .map((doc) =>
              Vendor.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching vendors: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getVendorsData() async {
    try {
      QuerySnapshot<Object?> querySnapshot =
          await _firestore.collection('stores').get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching vendors data: $e');
      return [];
    }
  }

  Future<void> addFoodTruck(String vendorId, FoodTruck foodTruck) async {
    await _firestore.collection('foodTrucks').doc(foodTruck.id).set({
      'name': foodTruck.name,
      'vendorId': vendorId,
      'id': foodTruck.id,
      'image': foodTruck.image,
    });
  }

  Future<List<FoodTruck>> getFoodTrucksForVendor(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('foodTrucks')
          .where('vendorId', isEqualTo: vendorId) // Filter by vendorId
          .get();
      List<FoodTruck> foodTrucks = [];
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          foodTrucks.add(
            FoodTruck(
              id: doc.id,
              name: (data['name'] as String?) ?? '',
              image: (data['image'] as String?) ?? '',
              vendorId: (data['vendorId'] as String?) ?? '',
            ),
          );
        }
      }
      return foodTrucks;
    } catch (e) {
      print('Error fetching food trucks for vendor: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getFoodTrucksByVendor(
      String vendorId) async {
    try {
      QuerySnapshot<Object?> querySnapshot = await _firestore
          .collection('foodTrucks')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching food trucks for vendor: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getFoodTrucksData() async {
    try {
      QuerySnapshot<Object?> querySnapshot =
          await _firestore.collection('foodTrucks').get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching food trucks: $e');
      return [];
    }
  }

  Future<List<Food>> getFoodsForVendor(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('foods')
          .where('vendorId', isEqualTo: vendorId) // Filter by vendorId
          .get();
      List<Food> food = [];
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          food.add(
            Food(
              id: doc.id,
              name: (data['name'] as String?) ?? '',
              price: (data['price'] ?? '') ?? 0.0,
              image: (data['image'] as String?) ??
                  'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/images%2Fvendor%2Fabo.jpg?alt=media&token=39b18887-7cb2-4f32-aea1-4c423c68f0c0',
              vendorId: (data['vendorId'] as String?) ?? '',
              vendorName: (data['vendorName'] as String?) ?? '',
              quantity: 0,
              userRated: false,
            ),
          );
        }
      }
      return food;
    } catch (e) {
      print('Error fetching food for vendor: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getFoodsByVendor(
      String vendorId) async {
    try {
      QuerySnapshot<Object?> querySnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(vendorId)
          .collection('products')
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching food for vendor: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getFoodsData() async {
    try {
      List<QueryDocumentSnapshot<Object?>> allFoods = [];

      QuerySnapshot<Object?> storesSnapshot =
          await FirebaseFirestore.instance.collection('stores').get();

      for (QueryDocumentSnapshot<Object?> storeDoc in storesSnapshot.docs) {
        QuerySnapshot<Object?> productsSnapshot =
            await storeDoc.reference.collection('products').get();

        allFoods.addAll(productsSnapshot.docs);
      }

      return allFoods;
    } catch (e) {
      print('Error fetching all foods: $e');
      return [];
    }
  }


  // Add stream methods for real-time updates
  Stream<List<QueryDocumentSnapshot<Object?>>> getVendorsStream() {
    return _firestore.collection('stores').orderBy('rate', descending: true).snapshots().map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot<Object?>>> getFoodsStream() {
    return _firestore.collection('stores').orderBy('rate', descending: true).snapshots().asyncMap((storesSnapshot) async {
      List<QueryDocumentSnapshot<Object?>> allFoods = [];

      for (QueryDocumentSnapshot<Object?> storeDoc in storesSnapshot.docs) {
        QuerySnapshot<Object?> productsSnapshot =
            await storeDoc.reference.collection('products').get();

        allFoods.addAll(productsSnapshot.docs);
      }

      return allFoods;
    });
  }


  Stream<List<QueryDocumentSnapshot<Object?>>> getFoodsByVendorStream(String vendorId) {
    return _firestore
        .collection('stores')
        .doc(vendorId)
        .collection('products')
        .orderBy('rate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

 Stream<String?> getOrderStatus(String vendorId, String productId) {
  return _firestore
      .collection('stores')
      .doc(vendorId)
      .collection('products')
      .doc(productId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['order_status'] as String?);
}

Stream<double> getLat(String vendorId){

  return _firestore
      .collection('stores')
      .doc(vendorId).snapshots().map((snapshot) => snapshot.data()?['lat'] as double);

}

Stream<double> getLng(String vendorId){

  return _firestore
      .collection('stores')
      .doc(vendorId).snapshots().map((snapshot) => snapshot.data()?['lng'] as double);

}


  
}
