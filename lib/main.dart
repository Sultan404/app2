import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:second/auth/login.dart';
import 'package:second/auth/signup.dart';
import 'package:second/cat/food.dart';
import 'package:second/real/VendorFoodTrucksPage.dart';
import 'package:second/real/VendorFoods.dart';
import 'package:second/real/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _requestLocationPermission();
   
runApp(const ProviderScope(child: MyApp()));}

class MyApp extends StatefulWidget {
const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print(
            '=======================================User is currently signed out!');
      } else {
        print('=======================================User is signed in!');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          appBarTheme: AppBarTheme(
              backgroundColor: Color.fromARGB(255, 255, 255, 255),
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(size: 30, color: Color.fromARGB(255, 255, 255, 255)))),
      debugShowCheckedModeBanner: false,
      home: 
      (FirebaseAuth.instance.currentUser != null &&
              FirebaseAuth.instance.currentUser!.emailVerified)
          ? MyHomePage()
          : login(),
      routes: {
        "signup": (context) => signup(),
        "login": (context) => login(),
        "addFood": (context) => addFood(),
        'home': (context) => MyHomePage(),
        'vendorFoods': (context) {
          final Map<String, dynamic>? args = ModalRoute.of(context)
              ?.settings
              .arguments as Map<String, dynamic>?;
          final String vendorId = args?['id'] ?? '';
          final String vendorName = args?['name'] ?? '';
          final FlutterCart flutterCart = args?['flutterCart'] ?? '';
          return VendorFoodsPage(vendorId: vendorId, flutterCart: flutterCart, vendorName: vendorName,);
        },

      },
    );
  }
}