import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:second/real/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderHistoryPage extends StatelessWidget {
  bool v = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order History',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 136, 37, 186),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('order history')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot orderDocument = snapshot.data!.docs[index];
              Map<String, dynamic> orderData =
                  orderDocument.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(
                        'Order number: ${orderData['orderNumber']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: StreamBuilder<String?>(
                        stream: getOrderStatus(
                            orderData['storeId'], orderData['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              'Loading...', // Placeholder text while waiting for data
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                          // Extract the status from the snapshot
                          var status = snapshot.data ?? 'Unknown';
                          return Text(
                            'Order status: $status',
                            style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                          );
                        },
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: orderData['foods'].length,
                      itemBuilder: (context, foodIndex) {
                        Map<String, dynamic> foodData =
                            orderData['foods'][foodIndex];

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                          title: Text(
                            '${foodData['name']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'vendor: ${foodData['vendorName']}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'Price: ${foodData['price']} SAR',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'Quantity: ${foodData['qty'] ?? foodData['quantity']}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (foodData['userRated'] == null ||
                                  !foodData['userRated'])
                                RatingBar.builder(
                                  initialRating: 0,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: false,
                                  itemCount: 5,
                                  itemSize: 20,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    /// Check if the user has already rated this food item
                                    if (foodData['userRated'] == null ||
                                        !foodData['userRated']) {
                                      // If the user has not rated, proceed to update the rating
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Confirm Rating'),
                                            content: Text(
                                                'Are you sure you want to rate this item as $rating stars?'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Cancel'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog
                                                },
                                              ),
                                              TextButton(
                                                child: Text('Confirm'),
                                                onPressed: () async {
                                                  DocumentReference
                                                      orderHistoryRef =
                                                      FirebaseFirestore.instance
                                                          .collection('Users')
                                                          .doc(FirebaseAuth
                                                              .instance
                                                              .currentUser!
                                                              .uid)
                                                          .collection(
                                                              'order history')
                                                          .doc(
                                                              orderDocument.id);

                                                  // Clone the 'foods' array
                                                  List<dynamic> foodsArray =
                                                      List.from(
                                                          orderData['foods']);

                                                  // Create a new food item with the user rating
                                                  Map<String, dynamic>
                                                      newFoodItem = {
                                                    'userRated': true,
                                                    'id': foodData['id'],
                                                    'image': foodData['image'],
                                                    'name': foodData['name'],
                                                    'price': foodData['price'],
                                                    'quantity': foodData['qty'],
                                                    'vendorId':
                                                        foodData['vendorId'],
                                                    'vendorName':
                                                        foodData['vendorName']
                                                  };

                                                  // Replace the old food item with the new one
                                                  foodsArray[foodIndex] =
                                                      newFoodItem;

                                                  // Update the 'foods' array field
                                                  await orderHistoryRef.update(
                                                      {'foods': foodsArray});

                                                  // Fetch current product rating and number of ratings
                                                  String R =
                                                      await getrate(foodData);
                                                  int N = await getrateNumber(
                                                      foodData);

                                                  // Calculate new product rating
                                                  double newR =
                                                      ((double.parse(R) * N) +
                                                              rating) /
                                                          (N + 1);

                                                  // Update the rate and ratedNumber fields in the product document
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('stores')
                                                      .doc(foodData['vendorId'])
                                                      .collection('products')
                                                      .doc(foodData['id'])
                                                      .set(
                                                    {
                                                      'rate': newR.toString(),
                                                      'ratedNumber': N + 1,
                                                    },
                                                    SetOptions(merge: true),
                                                  );

                                                  // Fetch current store rating and number of ratings
                                                  String storeRate =
                                                      await getStoreRate(
                                                          foodData['vendorId']);
                                                  int storeRatedNumber =
                                                      await getStoreRatedNumber(
                                                          foodData['vendorId']);

                                                  // Calculate new store rating
                                                  double newStoreRate = ((double
                                                                  .parse(
                                                                      storeRate) *
                                                              storeRatedNumber) +
                                                          rating) /
                                                      (storeRatedNumber + 1);

                                                  // Update the rate and ratedNumber fields in the store document
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('stores')
                                                      .doc(foodData['vendorId'])
                                                      .set(
                                                    {
                                                      'rate': newStoreRate
                                                          .toString(),
                                                      'ratedNumber':
                                                          storeRatedNumber + 1,
                                                    },
                                                    SetOptions(merge: true),
                                                  );

                                                  print(
                                                      'Rating updated successfully: $rating');
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      // If the user has already rated, show a message indicating that they can't rate again
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Already Rated'),
                                            content: Text(
                                                'You have already rated this item. You cannot rate it again.'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('OK'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () async {
                        // Fetch latitude from Firestore
                        double lat = await FirebaseFirestore.instance
                            .collection('stores')
                            .doc(orderData['storeId'])
                            .get()
                            .then((doc) => doc.data()?['lat'] ?? 0.0);

                        // Retrieve longitude from allFavoritePlaces
                        double lng = await FirebaseFirestore.instance
                            .collection('stores')
                            .doc(orderData['storeId'])
                            .get()
                            .then((doc) => doc.data()?['lng'] ?? 0.0);

                        // Open Google Maps with the appropriate coordinates
                        if (lat == 0.0 && lng == 0.0) {
                          print('error');
                        } else {
                          openGoogleMap(lat, lng);
                        }
                      },
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12.0, // Adjust the font size as needed
                            ),
                          ),
                          Icon(
                            Icons.directions,
                            color: Colors.blueAccent,
                            size: 36.0,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<int> getrateNumber(Map<String, dynamic> foodData) async {
  final docRef = FirebaseFirestore.instance
      .collection('stores')
      .doc(foodData['vendorId'])
      .collection('products')
      .doc(foodData['id']);

  try {
    DocumentSnapshot documentSnapshot = await docRef.get();
    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('ratedNumber')) {
        await docRef.set({'ratedNumber': 0}, SetOptions(merge: true));
        return 0;
      } else {
        return data?['ratedNumber'] ?? 0;
      }
    } else {
      print('Document does not exist.');
      return 0;
    }
  } catch (error) {
    print('Error checking document: $error');
    return 0;
  }
}

Future<String> getrate(Map<String, dynamic> foodData) async {
  final docRef = FirebaseFirestore.instance
      .collection('stores')
      .doc(foodData['vendorId'])
      .collection('products')
      .doc(foodData['id']);

  try {
    DocumentSnapshot documentSnapshot = await docRef.get();
    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('rate')) {
        await docRef.set({'rate': '0'}, SetOptions(merge: true));
        return '0';
      } else {
        return data?['rate'] ?? '0';
      }
    } else {
      print('Document does not exist.');
      return '0';
    }
  } catch (error) {
    print('Error checking document: $error');
    return '0';
  }
}

Future<int> getStoreRatedNumber(String vendorId) async {
  final docRef = FirebaseFirestore.instance.collection('stores').doc(vendorId);

  try {
    DocumentSnapshot documentSnapshot = await docRef.get();
    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('ratedNumber')) {
        await docRef.set({'ratedNumber': 0}, SetOptions(merge: true));
        return 0;
      } else {
        return data?['ratedNumber'] ?? 0;
      }
    } else {
      print('Document does not exist.');
      return 0;
    }
  } catch (error) {
    print('Error checking document: $error');
    return 0;
  }
}

Future<String> getStoreRate(String vendorId) async {
  final docRef = FirebaseFirestore.instance.collection('stores').doc(vendorId);

  try {
    DocumentSnapshot documentSnapshot = await docRef.get();
    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('rate')) {
        await docRef.set({'rate': '0'}, SetOptions(merge: true));
        return '0';
      } else {
        return data?['rate'] ?? '0';
      }
    } else {
      print('Document does not exist.');
      return '0';
    }
  } catch (error) {
    print('Error checking document: $error');
    return '0';
  }
}

void openGoogleMap(double lat, double lng) async {
  final Uri googleMapsUri = Uri(
    scheme: 'https',
    host: 'www.google.com',
    path: '/maps',
    queryParameters: {
      'q': '$lat,$lng',
    },
  );

  final String googleMapsUrl = googleMapsUri.toString();

  if (await canLaunch(googleMapsUrl)) {
    await launch(googleMapsUrl);
  } else {
    throw 'Could not launch Google Maps';
  }
}

Stream<String?> getOrderStatus(String vendorId, String orderId) {
  return FirebaseFirestore.instance
      .collection('stores')
      .doc(vendorId)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['order_status'] as String?);
}
