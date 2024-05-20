import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:flutter_cart/model/cart_model.dart';
import 'package:second/payment/pay.dart';
import 'package:second/real/food.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:second/payment/key.dart';
import 'package:second/real/order_hestory.dart';

class CartScreen extends StatefulWidget {
  final FlutterCart flutterCart;

  CartScreen({required this.flutterCart}) {
    // Set the Stripe publishable key
    Stripe.publishableKey = ApiKeys.publishableKey;
  }

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double totalAmount = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Color.fromARGB(255, 172, 78, 212),
      ),
      body: _buildCartContents(),
    );
  }

  Widget _buildCartContents() {
    List<CartItem> cartItems = widget.flutterCart.cartItem;
    double totalAmount = widget.flutterCart.getTotalAmount();

    if (cartItems.isEmpty) {
      return Center(
        child: Text('Your cart is empty.'),
      );
    }

    void clearCart() {
      widget.flutterCart.deleteAllCart();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              CartItem cartItem = cartItems[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cartItem.productName ?? ''),
                      Text(
                        'vendor: (${cartItem.vendorName})',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'category: ${cartItem.category}' ?? '',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (cartItem.quantity > 1) {
                                setState(() {
                                  widget.flutterCart
                                      .decrementItemFromCart(index);
                                  updateTotalAmount();
                                });
                              }
                            },
                            icon: Icon(Icons.remove),
                          ),
                          Text('${cartItem.quantity} '),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                widget.flutterCart.incrementItemToCart(index);
                                updateTotalAmount();
                              });
                            },
                            icon: Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Price: ${cartItem.unitPrice * cartItem.quantity}'),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            widget.flutterCart.deleteItemFromCart(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Text('total price ${totalAmount}'),
        ElevatedButton(
          onPressed: () async {
            // Initiate the payment process
            bool paymentSuccess =
                await PaymentManager.makePayment(totalAmount, "SAR");

            // Check if payment was successful
            if (paymentSuccess) {
              // Proceed to confirm the order if payment was successful
              if (cartItems.isNotEmpty) {
                _confirmOrder(cartItems, totalAmount);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                );

                clearCart();
              }
            } else {
              // You can show a message to the user or take other actions
              print('Payment failed');
            }
          },
          child: Text('pay'),
        ),
      ],
    );
  }

  void updateTotalAmount() {
    double newTotalAmount = 0.0;
    for (var item in widget.flutterCart.cartItem) {
      newTotalAmount += item.unitPrice * item.quantity;
    }
    setState(() {
      totalAmount = newTotalAmount;
    });
  }

  final CollectionReference stores =
      FirebaseFirestore.instance.collection('stores');

  Future<void> _incrementOrderNumber(String storeid) async {
    // Reference to the specific document using the provided docId
    DocumentReference storeref = stores.doc(storeid);

    // Fetch the current document
    DocumentSnapshot orderNumberDoc = await stores.doc(storeid).get();

    // Initialize the current order number to 0
    int currentOrderNumber = 0;

    // Get the document data
    Map<String, dynamic>? data = orderNumberDoc.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('OrderNumber')) {
      currentOrderNumber = data['OrderNumber'];
    } else {
      // If 'OrderNumber' does not exist, set it to 0 with merge to avoid overwriting other fields
      await storeref.set({'OrderNumber': 0}, SetOptions(merge: true));
    }

    // Increment the order number
    int nextOrderNumber = currentOrderNumber + 1;

    // Update the order number in Firestore
    await storeref.update({'OrderNumber': nextOrderNumber});
  }

  Future<void> _confirmOrder(
      List<CartItem> foodData, double totalAmount) async {
    try {
      // Ensure user is authenticated
      if (FirebaseAuth.instance.currentUser != null) {
        String customerId = FirebaseAuth.instance.currentUser!.uid;

        // Increment the order number

        // Group items by vendor ID
        Map<String, List<CartItem>> groupedItems = {};
        foodData.forEach((item) {
          groupedItems.putIfAbsent(item.vendorID ?? '', () => []).add(item);
        });

        // Iterate over grouped items
        for (var entry in groupedItems.entries) {
          String vendorId = entry.key;
          List<CartItem> items = entry.value;
          for (var item in items) {
            print(item.quantity);
          }
          List<Food> foods = items
              .map((item) => Food(
                    id: item.productId,
                    category: item.category,
                    name: item.productName,
                    price: item.unitPrice,
                    quantity: item.quantity,
                    vendorId: item.vendorID,
                    vendorName: item.vendorName,
                    image:
                        'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2F1715962572970-Rutab009.jpg?alt=media&token=2d2dacf6-2c1d-41fd-bd55-13ce48d3309f',
                    userRated: false,
                  ))
              .toList();

          await _incrementOrderNumber(vendorId);

          // Get the current order number
          DocumentSnapshot orderNumberDoc = await stores.doc(vendorId).get();
          int orderNumber = orderNumberDoc.get('OrderNumber');

          print(orderNumberDoc);
          print(orderNumber);

          // Save the order data to vendors
          DocumentReference docRef = FirebaseFirestore.instance
              .collection('stores')
              .doc(vendorId)
              .collection('orders')
              .doc();

          // Use the document ID from docRef.id and set the document data
          await docRef.set({
            'orderNumber': orderNumber,
            'id': docRef.id, // Store the document ID here
            'customerId': customerId,
            'orderItems': foods.map((food) => food.toMap()).toList(),
            'createdAt': FieldValue.serverTimestamp(),
            'storeId': vendorId,
            'isPaid': true,
            'order_status': 'Processing',
            'totalPrice': totalAmount,
          });

          // Save the order data to user hestory
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(customerId)
              .collection('order history')
              .add({
            'orderNumber': orderNumber,
            'customerId': customerId,
            'foods': foods.map((food) => food.toMap()).toList(),
            'createdAt': FieldValue.serverTimestamp(),
            'storeId': vendorId,
            'totalPrice': totalAmount,
            'id':  docRef.id,
          });
        }
      } else {
        print('User not authenticated');
      }
    } catch (e) {
      print(e);
    }
  }
}
