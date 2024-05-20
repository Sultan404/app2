import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cart/model/cart_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:second/real/firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:second/real/cart.dart'; 


class VendorFoodsPage extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final FlutterCart flutterCart;

  VendorFoodsPage({required this.vendorId, required this.flutterCart,required this.vendorName});

  @override
  _VendorFoodsPageState createState() => _VendorFoodsPageState();
}

class _VendorFoodsPageState extends State<VendorFoodsPage> {
  late FlutterCart flutterCart;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    flutterCart = widget.flutterCart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
             widget.vendorName,
            style: TextStyle(
              color: Colors.purple, // Set the color to purple
              fontSize: 24, // Optional: set the font size
            ),
          ),
        iconTheme: IconThemeData(size: 30, color: Color.fromARGB(255, 172, 78, 212),),
        actions: [ IconButton(
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
          ),],
      ),
      body: buildFoodsList(),
    );
  }

    Widget buildFoodsList() {
    return StreamBuilder<List<QueryDocumentSnapshot<Object?>>>(
      stream: FirestoreService().getFoodsByVendorStream(widget.vendorId),
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
              return GestureDetector(
                onTap: () {
                  _showOrderDialog(context, itemData);
                },
                child: _buildCard(itemData),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> itemData,) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              itemData['image'] ?? 'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633',
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
                    '${widget.vendorName}' ?? "",
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
          ],
        ),
      ),
    );
  }

  void _showOrderDialog(BuildContext context, Map<String, dynamic> foodData) {
    int quantity = 1;
double price = foodData['price'].toDouble();

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
                      productName:foodData['name'].toString(),
                      productId: foodData['id'].toString(),
                      unitPrice: price,
                      quantity: quantity,
                      productDetailsObject: foodData,
                      vendorID : foodData['storeId'],
                      vendorName : foodData['storeName'],
                      category : foodData['category'],
                      
                    );
                    // Close the dialog
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

  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final CollectionReference orderNumberCollection =
      FirebaseFirestore.instance.collection('order_numbers');

  Future<void> _incrementOrderNumber() async {
    // Get the current order number
    DocumentSnapshot orderNumberDoc =
        await orderNumberCollection.doc('current_order_number').get();
    int currentOrderNumber =
        orderNumberDoc.exists ? orderNumberDoc.get('number') : 0;

    // Increment the order number
    int nextOrderNumber = currentOrderNumber + 1;

    // Update the order number in Firestore
    await orderNumberCollection
        .doc('current_order_number')
        .set({'number': nextOrderNumber});
  }

  Future<void> _confirmOrder(
      Map<String, dynamic> foodData, String quantity) async {
    int qty = int.tryParse(quantity) ?? 0;
    
    if (qty > 0) {
      double price = double.parse(foodData['price'].toString());
      double totalAmount = qty * price;
      String customerId = FirebaseAuth.instance.currentUser!.uid;

      // Increment the order number
      await _incrementOrderNumber();

      // Get the updated order number
      DocumentSnapshot orderNumberDoc =
          await orderNumberCollection.doc('current_order_number').get();
      int orderNumber = orderNumberDoc.get('number');

      Map<String, dynamic> orderData = {
        'orderNumber': orderNumber,
        'customerId': customerId,
        'foodName': foodData['name'],
        'quantity': qty,
        'totalAmount': totalAmount,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save the order data to Firestore
      await ordersCollection.add(orderData);
    } else {
      cath(e) {
        print(e);
      }
    }
  }
}
