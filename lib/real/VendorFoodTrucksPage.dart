
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:second/real/firestore_service.dart';

class VendorFoodTrucksPage extends StatelessWidget {
  final String vendorId;

  late Future<List<QueryDocumentSnapshot<Object?>>> foodTrucks;

  VendorFoodTrucksPage({required this.vendorId}) {
    foodTrucks = FirestoreService().getFoodTrucksByVendor(vendorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Trucks for Vendor'),
      ),
      body: buildFoodTrucksList(),
    );
  }

  Widget buildFoodTrucksList() {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: foodTrucks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<QueryDocumentSnapshot<Object?>> data = snapshot.data ?? [];
          return GridView.builder(
            itemCount: data.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 197,
            ),
            itemBuilder: (context, i) {
              var itemData = data[i].data() as Map<String, dynamic>;
              return _buildCard(itemData);
            },
          );
        }
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> itemData) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Image.network(
              itemData['image'] ?? 'hear 137',
              height: 100,
              width: 190,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 8),
            Text(
              itemData['name'] ?? '',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
