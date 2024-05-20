import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:second/auth/account.dart';
import 'package:second/location/pages/home_page.dart';
import 'package:second/real/cart.dart';
import 'package:second/real/firestore_service.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:second/real/order_hestory.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<QueryDocumentSnapshot<Object?>>> vendors;
  late Future<List<QueryDocumentSnapshot<Object?>>> foods;
  late Future<String> _imageUrlFuture;
  late FlutterCart flutterCart;

  bool showVendors = true;
  final List<String> itemNames = ['ALL', 'PIZZA', 'BURGER', 'SHAWARMA', 'شاهي'];

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    flutterCart = FlutterCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton.icon(
          icon: Icon(Icons.location_pin),
          label: Text(
            'Holek',
            style: TextStyle(
              color: const Color.fromARGB(255, 172, 78, 212),
              fontSize: 30.0,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(flutterCart: flutterCart)), //location
            );
          },
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            style: ButtonStyle(
              iconColor: MaterialStateProperty.resolveWith(
                (states) => Color.fromARGB(255, 150, 60, 189),
              ),
            ),
            onPressed: () {
              // Navigate to CartScreen when cart icon is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(flutterCart: flutterCart),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("login", (route) => false);
              flutterCart.deleteAllCart();
            },
            icon: Icon(Icons.exit_to_app),
            style: ButtonStyle(
              iconColor: MaterialStateProperty.resolveWith(
                (states) => Color.fromARGB(255, 150, 60, 189),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '  HEY! 👋',
              style: TextStyle(
                color: Color.fromARGB(255, 117, 42, 149),
                fontSize: 30.0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '  Lets prepare your order 🍽️ ',
              style: TextStyle(
                color: Color.fromARGB(255, 150, 60, 189),
                fontSize: 16.0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '  Our trucks are waiting to serve you 🚚 ',
              style: TextStyle(
                color: Color.fromARGB(255, 150, 60, 189),
                fontSize: 16.0,
              ),
            ),
          ),
          Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {
                    // Trigger rebuild to update the search results
                  });
                },
                decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(45.0)),
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 150, 60, 189)),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                    height: 0), // Add some space between the text and the list
                Container(
                  height: 50, // Set the height of the ListView
                  child: ListView.builder(
                    scrollDirection:
                        Axis.horizontal, // Make the ListView horizontal
                    itemCount: itemNames.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (itemNames[index] == 'ALL') {
                              _searchController.text = '';
                            } else {
                              _searchController.text = itemNames[index];
                            }
                            ; // Update the text of the controller
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.all(5.0),
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 172, 78, 212),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              itemNames[index],
                              style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Foods'),
              Switch(
                value: showVendors,
                onChanged: (value) {
                  setState(() {
                    showVendors = value;
                  });
                },
              ),
              Text('vendors'),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                showVendors ? _buildVendorGridView() : _buildFoodGridView(),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: SpeedDial(
                    animatedIcon: AnimatedIcons.menu_close,
                    animatedIconTheme: IconThemeData(
                      size: 25.0,
                      color: Color.fromARGB(255, 172, 78, 212),
                    ),
                    children: [
                      SpeedDialChild(
                        child: Icon(Icons.shopping_cart,
                            color: Color.fromARGB(255, 163, 54, 210)),
                        onTap: () {
                          // Navigate to CartScreen when cart icon is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CartScreen(flutterCart: flutterCart),
                            ),
                          );
                        },
                      ),
                      SpeedDialChild(
                        child: Icon(Icons.manage_accounts,
                            color: Color.fromARGB(255, 163, 54, 210)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(),
                            ),
                          );
                        },
                      ),
                      SpeedDialChild(
                        child: Icon(Icons.history,
                            color: Color.fromARGB(255, 163, 54, 210)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderHistoryPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorGridView() {
    return StreamBuilder<List<QueryDocumentSnapshot<Object?>>>(
      stream: _firestoreService.getVendorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<QueryDocumentSnapshot<Object?>> data = snapshot.data ?? [];
          data = _filterData(data);
          return GridView.builder(
            itemCount: data.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 197,
            ),
            itemBuilder: (context, i) {
              var docSnapshot = data[i];
              var itemData = docSnapshot.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    'vendorFoods',
                    arguments: {
                      'id': docSnapshot.id,
                      'name': (docSnapshot?.data()
                          as Map<String, dynamic>?)?['name'],
                      'flutterCart': flutterCart,
                    },
                  );
                },
                child: _buildCard(itemData, context),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildFoodGridView() {
    return StreamBuilder<List<QueryDocumentSnapshot<Object?>>>(
      stream: _firestoreService.getFoodsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<QueryDocumentSnapshot<Object?>> data = snapshot.data ?? [];
          data = _filterData(data);
          return GridView.builder(
            itemCount: data.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 197,
            ),
            itemBuilder: (context, i) {
              var itemData = data[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  String vendorName = itemData.containsKey('storeName')
                      ? itemData['storeName']
                      : 'Unknown Vendor';
                  _showOrderDialog(itemData, context, vendorName);
                },
                child: _buildCard(itemData, context),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> itemData, BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(1),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              itemData['image'] ??
                  'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633',
              height: 87,
              width: 190,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 2),
            Text(
              itemData['name'] ?? '',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                if (itemData['price'] != null) ...[
                  Text(
                    '${itemData['price']}' ?? "",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(' SAR',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
                SizedBox(width: 2),
                Spacer(),
                if (itemData['price'] != null)
                  Text(
                    ' ${itemData['storeName'] ?? 'Unknown'}', // Display the vendor name here
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                RatingBarIndicator(
                  rating: itemData['rate'] != null
                      ? double.parse(itemData['rate'])
                      : 0.0,
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 15.0,
                ),
                SizedBox(width: 5),
                Text(
                  '(${itemData['ratedNumber'] != null ? itemData['ratedNumber'] : 0})',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 2),

            // Calculate distance asynchronously and display it
            if (itemData['lat'] != null)
              FutureBuilder<String>(
                future: calculateDistance(itemData['lat'], itemData['lng']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ); // Show loading indicator while waiting
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  print(snapshot.data);
                  return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${snapshot.data} km' ??
                            '', // Concatenate the distance with 'km'
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold), // Apply bold font weight
                      ));
                  // Display distance if available
                },
              ),

            //for foods
            if (itemData['category'] != null)
              FutureBuilder<String>(
                future: () async {
                  final lat = await _firestoreService
                      .getLat(itemData['storeId'])
                      .first;
                  final lng = await _firestoreService
                      .getLng(itemData['storeId'])
                      .first;
                  return calculateDistance(lat, lng);
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ); // Show loading indicator while waiting
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  print(snapshot.data);
                  return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${snapshot.data} km' ??
                            '', // Concatenate the distance with 'km'
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,fontSize: 10), // Apply bold font weight
                      ));
                  // Display distance if available
                },
              ),
          ],
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Object?>> _filterData(
    List<QueryDocumentSnapshot<Object?>> data,
  ) {
    String searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      return data.where((doc) {
        Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
        String itemName = itemData['name'].toString().toLowerCase();
        return itemName.contains(searchText) ||
            _isArabicMatch(itemName, searchText);
      }).toList();
    }
    return data;
  }

  bool _isArabicMatch(String itemName, String searchText) {
    final arabicRange = RegExp(r'[\u0600-\u06FF\s]');
    String arabicItemName = itemName.split('').where((char) {
      return arabicRange.hasMatch(char);
    }).join('');
    return arabicItemName.contains(searchText);
  }

  void _showOrderDialog(
      Map<String, dynamic> foodData, BuildContext context, String vendorName) {
    int quantity = 1;
    double price = foodData['price'].toDouble();
    print(vendorName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(foodData['name'] ?? ''),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vendor: ${foodData['storeName']}'),

                  Image.network(
              foodData['image'] ??
                  'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633',
              height: 87,
              width: 190,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 5),
                  
                  Text(foodData['Description'] ?? 'Description'),
                  SizedBox(height: 10),
                  Text('category: ${foodData['category']}' ?? 'category'),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                        icon: Icon(Icons.remove),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  Text('Price: ${price * quantity} SAR'),
                  SizedBox(height: 10),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add item to the cart
                    flutterCart.addToCart(
                      productName: foodData['name'].toString(),
                      vendorID: foodData['storeId'].toString(),
                      vendorName: foodData['storeName'].toString(),
                      productId: foodData['id'].toString(),
                      unitPrice: price,
                      quantity: quantity,
                      category: foodData['category'].toString(),
                      productDetailsObject: foodData,
                    );

                    Navigator.of(context).pop();
                  },
                  child: Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Future<String> calculateDistance(double lat, double lng) async {
  Position userPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  double distance = await Geolocator.distanceBetween(
      userPosition.latitude, userPosition.longitude, lat, lng);

  // Convert distance from meters to kilometers
  double distanceInKm = distance / 1000.0;

  return distanceInKm.toStringAsFixed(2);
}

Future<bool> _requestLocationPermission() async {
  LocationPermission permission = await Geolocator.requestPermission();
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}
