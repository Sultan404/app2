import 'dart:async';
import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:math' show cos, sqrt, asin;

import 'package:circular_menu/circular_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:second/main.dart';
import 'package:second/location/model/auto_complete_results.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flip_card/flip_card.dart';
import 'package:geolocator/geolocator.dart';
import 'package:second/location/provider/search_places.dart';
import 'package:second/location/map_service.dart';
import 'package:second/real/VendorFoods.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cart/flutter_cart.dart';

class HomePage extends ConsumerStatefulWidget {
  final FlutterCart flutterCart;
  const HomePage({Key? key, required this.flutterCart}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Completer<GoogleMapController> _controller = Completer();

//Debounce to throttle async calls during search
  Timer? _debounce;

  late FlutterCart flutterCart;
//Toggling UI as we need
  bool searchToggle = false;
  bool radiusSlider = false;
  bool pressdNear = false;
  bool getDirections = false;
  bool cardTapped = false;
//Markers set
  Set<Marker> _markers = Set<Marker>();
  Set<Marker> _markersDupe = Set<Marker>();

  Set<Polyline> _polylines = Set<Polyline>();

  int markerIdCounter = 1;
  int polylineIdCounter = 1;

  var radiusValue = 1000.0;

  var tappedPoint = LatLng(24.728001, 46.620601);

  double x = 0;
  List allFavoritePlaces = [];

  String tokenKey = '';

//Page controller for pageview
  late PageController _pageController;
  int prevPage = 0;
  var tappedPlaceDetail;
  String placeImg = '';
  var photoGalleryIndex = 0;
  bool showBlankCard = false;
  bool isReviews = true;
  bool isPhotos = false;

  final key = 'AIzaSyD_pFxIeBo6B9abCIckiNScTEP3egRSTCY';

  var selectedPlaceDetails;

//Circle
  Set<Circle> _circle = Set<Circle>();

//Text editing Controllers
  TextEditingController searchController = TextEditingController();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  var lat;
  var lng;
  Position? userPosition;
  double? distance;

  void _setMarker(point) {
    var counter = markerIdCounter++;

    final Marker marker = Marker(
      markerId: MarkerId('marker$counter'),
      position: point,
      onTap: () {},
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdValue = 'polyline_$polylineIdCounter';

    polylineIdCounter++;

    _polylines.add(Polyline(
        polylineId: PolylineId(polylineIdValue),
        width: 5,
        color: Colors.blue,
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList()));
  }

  void _setCircle(LatLng point) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 14)));
    setState(() {
      _circle.add(Circle(
          circleId: CircleId('fst'),
          center: point,
          fillColor: Colors.blue.withOpacity(0.1),
          radius: radiusValue,
          strokeColor: Colors.blue,
          strokeWidth: 1));
      getDirections = false;
      searchToggle = false;
      radiusSlider = true;
    });
  }

  var _flipCardPosition;

  void _fetchStoreLocations() async {
    final QuerySnapshot result =
        await FirebaseFirestore.instance.collection('stores').get();
    final List<DocumentSnapshot> documents = result.docs;
    setState(() {
      for (var doc in documents) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['lat'] as double;
        final lng = data['lng'] as double;
        final description =
            data.containsKey('description') ? data['description'] ?? '' : '';
        final rate = data.containsKey('rate') ? data['rate'] ?? '' : '';
        final image = data.containsKey('image')
            ? data['image'] ??
                'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633'
            : 'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633';

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          onTap: () {
            // When marker is tapped, show the custom card
            _showMarkerCard(
                doc, doc['name'], description, rate, image, lat, lng);
          },
        );
        _markers.add(marker);
      }
    });
  }

  void _showMarkerCard(
    DocumentSnapshot<Object?> doc,
    String name,
    String description,
    String rate,
    String image,
    double lat,
    double lng,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                image ??
                    'https://firebasestorage.googleapis.com/v0/b/holek-411821.appspot.com/o/Images%2Fimage.jpg?alt=media&token=293526e5-e6e3-4b8a-bea2-149cb29b2633',
                height: 87,
                width: 190,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              Text(description),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('Rating: '),
                  RatingBarIndicator(
                    rating: rate != null && rate.isNotEmpty
                        ? double.parse(rate)
                        : 0.0,
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 15.0,
                  ),
                ],
              ),
              if (lat != null)
                FutureBuilder<String>(
                  future: calculateDistance(lat, lng),
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
            ],
          ),
          actions: [
            Row(
              children: [
                // Close button on the left
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
                Spacer(), // Spacer between Close button and Order button

                // Order button in the center
                Expanded(
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        // Perform navigation to VendorFoodsPage with required data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorFoodsPage(
                              vendorId: doc['id'],
                              vendorName: doc['name'],
                              flutterCart: flutterCart,
                            ),
                          ),
                        );
                      },
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11.0, // Adjust the font size as needed
                            ),
                          ),
                          Icon(
                            Icons.shopping_bag,
                            color: Colors.blueAccent,
                            size: 36.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Spacer(), // Spacer between Order button and Directions button

                // Directions button on the right
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        // Fetch latitude from Firestore
                        double lat = await FirebaseFirestore.instance
                            .collection('stores')
                            .doc(doc['id'])
                            .get()
                            .then((doc) => doc.data()?['lat'] ?? 0.0);

                        // Retrieve longitude from Firestore
                        double lng = await FirebaseFirestore.instance
                            .collection('stores')
                            .doc(doc['id'])
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
                  ],
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);

    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: 1, viewportFraction: 0.85)
      ..addListener(_onScroll);
    super.initState();
    _fetchStoreLocations();
    flutterCart = widget.flutterCart;
  }

  void _onScroll() {
    if (_pageController.page!.toInt() != prevPage) {
      prevPage = _pageController.page!.toInt();
      cardTapped = false;
      photoGalleryIndex = 1;
      showBlankCard = false;
      goToTappedPlace();
      fetchImage();
    }
  }

//Fetch image to place inside the pageView
  void fetchImage() async {
    if (_pageController.page !=
        null) if (allFavoritePlaces[_pageController.page!.toInt()]
            ['photos'] !=
        null) {
      setState(() {
        placeImg = allFavoritePlaces[_pageController.page!.toInt()]['photos'][0]
            ['photo_reference'];
      });
    } else {
      placeImg = '';
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //Providers
    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: screenHeight,
                  width: screenWidth,
                  child: FutureBuilder<bool>(
                    future: _requestLocationPermission(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return FutureBuilder<Position>(
                          future: Geolocator.getCurrentPosition(),
                          builder: (context, positionSnapshot) {
                            if (positionSnapshot.hasData) {
                              Position position = positionSnapshot.data!;
                              LatLng userLatLng =
                                  LatLng(position.latitude, position.longitude);

                              if (tappedPoint == null) {
                                tappedPoint = userLatLng;
                              }

                              return GoogleMap(
                                mapType: MapType.normal,
                                markers: {
                                  ..._markers,
                                  Marker(
                                    markerId: MarkerId('initialPositionMarker'),
                                    position: userLatLng,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueViolet),
                                  ),
                                },
                                polylines: _polylines,
                                circles: _circle,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                      position.latitude, position.longitude),
                                  zoom: 15.0,
                                ),
                                onMapCreated: (GoogleMapController controller) {
                                  _controller.complete(controller);
                                  _setCircle(userLatLng);
                                  // _SearchNearby(userLatLng);
                                },
                                onTap: (LatLng point) {
                                  tappedPoint = point;
                                  _setCircle(point);
                                },
                              );
                            } else if (positionSnapshot.hasError) {
                              return Text(
                                  'Error retrieving location: ${positionSnapshot.error}');
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
                searchToggle
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(15.0, 60.0, 15.0, 5.0),
                        child: Column(children: [
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: searchController,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                                border: InputBorder.none,
                                hintText: 'Search',
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        searchToggle = false;
                                        searchController.text = '';
                                        _markers = {};
                                        searchFlag.toggleSearch();
                                      });
                                    },
                                    icon: Icon(Icons.close)),
                              ),
                              onChanged: ((value) {
                                if (_debounce?.isActive ?? false)
                                  _debounce?.cancel();
                                _debounce = Timer(
                                  Duration(milliseconds: 700),
                                  () async {
                                    if (value.length > 2) {
                                      if (!searchFlag.searchToggle) {
                                        searchFlag.toggleSearch();
                                        _markers = {};
                                      }
                                      List<AutoCompleteResult> searchResults =
                                          await MapServices()
                                              .searchPlaces(value);
                                      allSearchResults
                                          .setResults(searchResults);
                                    } else {
                                      List<AutoCompleteResult> emptyList = [];
                                      allSearchResults.setResults(emptyList);
                                    }
                                  },
                                );
                              }),
                            ),
                          )
                        ]),
                      )
                    : Container(),
                searchFlag.searchToggle
                    ? allSearchResults.allReturnedResults.length != 0
                        ? Positioned(
                            top: 100,
                            left: 15,
                            child: Container(
                              height: 200,
                              width: screenWidth - 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: ListView(
                                children: [
                                  ...allSearchResults.allReturnedResults
                                      .map((e) => buildListItem(e, searchFlag))
                                ],
                              ),
                            ),
                          )
                        : Positioned(
                            top: 100,
                            left: 15,
                            child: Container(
                              height: 200,
                              width: screenWidth - 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.6),
                              ),
                              child: Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text('No results to show',
                                          style: TextStyle(
                                              fontFamily: 'Worksans',
                                              fontWeight: FontWeight.w400)),
                                      SizedBox(height: 20),
                                      Container(
                                        width: 200,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            searchFlag.toggleSearch();
                                          },
                                          child: Center(
                                            child: Text(
                                              'Close this',
                                              style: TextStyle(
                                                  color: Colors.black38,
                                                  fontFamily: 'Worksans',
                                                  fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                        ),
                                      )
                                    ]),
                              ),
                            ))
                    : Container(),
                getDirections ? buildDirections() : Container(),
                radiusSlider
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(15, 60, 15, 0),
                        child: Container(
                          height: 50,
                          color: Colors.black.withOpacity(0.3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  max: 7000,
                                  min: 1000,
                                  value: radiusValue,
                                  onChanged: (newVal) {
                                    radiusValue = newVal;
                                    pressdNear = false;
                                    _setCircle(tappedPoint);
                                  },
                                ),
                              ),
                              !pressdNear
                                  ? IconButton(
                                      onPressed: () {
                                        _SearchNearby(tappedPoint);
                                      },
                                      icon: Icon(Icons.near_me))
                                  : IconButton(
                                      onPressed: () {
                                        if (_debounce?.isActive ?? false)
                                          _debounce?.cancel();
                                        _debounce = Timer(Duration(seconds: 2),
                                            () async {
                                          if (tokenKey != 'none') {
                                            var placesResult =
                                                await MapServices()
                                                    .getMorePlaceDetails(
                                                        tokenKey);

                                            List<dynamic> placesWithin =
                                                placesResult['results'] as List;

                                            allFavoritePlaces
                                                .addAll(placesWithin);

                                            tokenKey = placesResult[
                                                    'next_page_token'] ??
                                                'none';

                                            placesWithin.forEach((element) {});
                                          } else {
                                            print('Thats all !!');
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.more)),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      radiusSlider = false;
                                      pressdNear = false;
                                      cardTapped = false;
                                      radiusValue = 1000;
                                      _circle = {};
                                      _markers = {};
                                      allFavoritePlaces = [];
                                    });
                                  },
                                  icon: Icon(Icons.close, color: Colors.red))
                            ],
                          ),
                        ),
                      )
                    : Container(),
                pressdNear
                    ? Positioned(
                        bottom: 20.0,
                        child: Container(
                          height: 200.0,
                          width: MediaQuery.of(context).size.width,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: allFavoritePlaces.length,
                            itemBuilder: (BuildContext context, int index) {
                              return _nearbyPlacesList(index);
                            },
                          ),
                        ))
                    : Container(),
                cardTapped ? buildCard(context) : Container(),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: CircularMenu(
        alignment: Alignment.bottomLeft.add(Alignment(0.15, 0.05)),
        startingAngleInRadian: 0,
        endingAngleInRadian: 4.7,
        radius: 70,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
        toggleButtonColor: Colors.grey.shade50,
        toggleButtonIconColor: Colors.deepPurple,
        toggleButtonBoxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
        items: [
          CircularMenuItem(
            icon: Icons.search,
            onTap: () {
              setState(() {
                searchToggle = true;
                radiusSlider = false;
                pressdNear = false;
                getDirections = false;
              });
            },
          ),
          CircularMenuItem(
            icon: Icons.navigation,
            onTap: () {
              setState(() {
                searchToggle = false;
                radiusSlider = false;
                pressdNear = false;
                getDirections = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildListItem(AutoCompleteResult placeItem, searchFlag) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () async {
          var place = await MapServices().getPlace(placeItem.placeId);
          gotoSearchedPlace(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']);
          searchFlag.toggleSearch();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Colors.purple, size: 25.0),
            SizedBox(width: 4.0),
            Container(
              height: 32.0,
              width: MediaQuery.of(context).size.width - 75.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(placeItem.description ?? ''),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildReviewItem(review) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8),
          child: Row(
            children: [
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(review['profile_photo_url']),
                        fit: BoxFit.cover)),
              ),
              SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    child: Text(
                      review['author_name'],
                      style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 3),
                  RatingStars(
                    value: review['rating'] * 1.0,
                    starCount: 5,
                    starSize: 10,
                    valueLabelColor: const Color(0xff9b9b9b),
                    valueLabelTextStyle: TextStyle(
                        color: Colors.white,
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontSize: 12),
                    valueLabelRadius: 10,
                    maxValue: 5,
                    starSpacing: 2,
                    maxValueVisibility: false,
                    valueLabelVisibility: true,
                    animationDuration: Duration(milliseconds: 1000),
                    valueLabelPadding:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                    valueLabelMargin: const EdgeInsets.only(right: 8),
                    starOffColor: const Color(0xffe7e8ea),
                    starColor: Colors.yellow,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Container(
            child: Text(
              review['text'],
              style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
        Divider(color: Colors.grey.shade600, height: 1)
      ],
    );
  }

  _buildPhotoGallery(photoElement) {
    if (photoElement == null || photoElement.length == 0) {
      showBlankCard = true;
      return Container(
        child: Center(
          child: Text(
            "No Photos",
            style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
    } else {
      var placeImg = photoElement[photoGalleryIndex]['photo_reference'];
      var maxWidth = photoElement[photoGalleryIndex]['width'];
      var maxHeight = photoElement[photoGalleryIndex]['height'];
      var tempDisplayIndex = photoGalleryIndex + 1;

      return Column(
        children: [
          SizedBox(height: 10),
          Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                      image: NetworkImage(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&maxheight=$maxHeight&photo_reference=$placeImg&key=$key'),
                      fit: BoxFit.cover))),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (photoGalleryIndex != 0)
                      photoGalleryIndex = photoGalleryIndex - 1;
                    else
                      photoGalleryIndex = 0;
                  });
                },
                child: Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: photoGalleryIndex != 0
                          ? Colors.purple.shade500
                          : Colors.grey.shade500),
                  child: Center(
                    child: Text(
                      'Prev',
                      style: TextStyle(
                          fontFamily: 'WorkSans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              Text(
                '$tempDisplayIndex/' + photoElement.length.toString(),
                style: TextStyle(
                    fontFamily: 'WonkSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (photoGalleryIndex != photoElement.length - 1)
                      photoGalleryIndex = photoGalleryIndex + 1;
                    else
                      photoGalleryIndex = photoElement.length - 1;
                  });
                },
                child: Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: photoGalleryIndex != photoElement.length - 1
                          ? Colors.purple.shade500
                          : Colors.grey.shade500),
                  child: Center(
                    child: Text(
                      'Next',
                      style: TextStyle(
                          fontFamily: 'WorkSans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  gotoPlace(double lat, double lng, double endLat, double endLng,
      Map<String, dynamic> boundsNE, Map<String, dynamic> boundsSW) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSW['lat'], boundsSW['lng']),
            northeast: LatLng(boundsNE['lat'], boundsNE['lng'])),
        25));

    _setMarker(LatLng(lat, lng));
    _setMarker(LatLng(endLat, endLng));
  }

  Future<void> _moveCamerSlightly() async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lat'] +
                0.00125,
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lng'] +
                0.005),
        zoom: 14,
        bearing: 45,
        tilt: 45)));
  }

  _nearbyPlacesList(index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (BuildContext context, Widget? widget) {
        double value = 1;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page! - index);
          value = (1 - (value.abs() * 0.3) + 0.06).clamp(0, 1);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 150,
            width: Curves.easeInOut.transform(value) * 350,
            child: widget,
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          cardTapped = !cardTapped;
          if (cardTapped) {
            tappedPlaceDetail = await MapServices()
                .getPlace(allFavoritePlaces[index]['place_id']);
            setState(() {});
          }
          _moveCamerSlightly();
        },
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                height: 125,
                width: 265,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0.0, 4.0),
                          blurRadius: 10)
                    ]),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: Row(
                    children: [
                      _pageController.position.haveDimensions
                          ? _pageController.page!.toInt() == index
                              ? Container(
                                  height: 120,
                                  width: 90,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        topLeft: Radius.circular(10),
                                      ),
                                      image: DecorationImage(
                                          image: NetworkImage(placeImg != ''
                                              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                                              : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                                          fit: BoxFit.cover)),
                                )
                              : Container(
                                  height: 90,
                                  width: 20,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        topLeft: Radius.circular(10),
                                      ),
                                      color: Colors.purple),
                                )
                          : Container(),
                      SizedBox(width: 5),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 170,
                            child: Text(
                              allFavoritePlaces[index]['name'],
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontFamily: 'WorkSans',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          RatingStars(
                            value: allFavoritePlaces[index]['rating'] != null
                                ? allFavoritePlaces[index]['rating'] * 1.0
                                : allFavoritePlaces[index]['rating'] ?? 0.0,
                            starCount: 5,
                            starSize: 15,
                            valueLabelColor: const Color(0xff9b9b9b),
                            valueLabelTextStyle: TextStyle(
                                color: Colors.white,
                                fontFamily: 'WorkSans',
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 12),
                            valueLabelRadius: 10,
                            maxValue: 5,
                            starSpacing: 2,
                            maxValueVisibility: false,
                            valueLabelVisibility: true,
                            animationDuration: Duration(milliseconds: 1000),
                            valueLabelPadding: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 8),
                            valueLabelMargin: const EdgeInsets.only(right: 8),
                            starOffColor: const Color(0xffe7e8ea),
                            starColor: Colors.yellow,
                          ),
                          Container(
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 15),
                                  child: FutureBuilder<String>(
                                    future: calculateDistance(
                                      allFavoritePlaces[index]['geometry']
                                          ['location']['lat'],
                                      allFavoritePlaces[index]['geometry']
                                          ['location']['lng'],
                                    ),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<String> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasData) {
                                        return Text(
                                          '${snapshot.data!} km',
                                          style: TextStyle(fontSize: 12),
                                        );
                                      }
                                      return Text(
                                        'N/A',
                                        style: TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    allFavoritePlaces[index]['geometry']
                                            ['location']['lat'] ??
                                        0.0;
                                    allFavoritePlaces[index]['geometry']
                                            ['location']['lng'] ??
                                        0.0;
                                    if (lat == null && lng == null)
                                      openGoogleMap(
                                          allFavoritePlaces[index]['geometry']
                                              ['location']['lat'],
                                          allFavoritePlaces[index]['geometry']
                                              ['location']['lng']);
                                    else
                                      openGoogleMap(lat, lng);
                                  },
                                  icon: Icon(
                                    Icons.directions,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> goToTappedPlace() async {
    final GoogleMapController controller = await _controller.future;

    _markers = {};

    var selectedPlace = allFavoritePlaces[_pageController.page!.toInt()];

    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(selectedPlace['geometry']['location']['lat'],
            selectedPlace['geometry']['location']['lng']),
        zoom: 14,
        bearing: 45,
        tilt: 45,
      ),
    ));
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 14)));
    _setMarker(LatLng(lat, lng));
    _SearchNearby(LatLng(lat, lng));
    _setCircle(LatLng(lat, lng));
  }

  _SearchNearby(tappedPoint) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(seconds: 2), () async {
      var placeResult =
          await MapServices().getPlaceDetails(tappedPoint, radiusValue.toInt());

      List<dynamic> placesWithin = placeResult['results'] as List;

      allFavoritePlaces = placesWithin;

      tokenKey = placeResult['next_page_token'] ?? 'none';
      _markers = {};
      placesWithin.forEach((element) {});
    });
    _markersDupe = _markers;
    pressdNear = true;
  }

  Positioned buildDirections() {
    return Positioned(
      top: 60,
      left: 15,
      right: 15,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: TextFormField(
              controller: _originController,
              readOnly: true,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: InputBorder.none,
                hintText: 'Your location',
              ),
            ),
          ),
          SizedBox(
            height: 3,
          ),
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: TextFormField(
              controller: _destinationController,
              decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: InputBorder.none,
                  hintText: 'Destination',
                  suffixIcon: Container(
                    width: 96,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () async {
                              Position userPosition =
                                  await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );

                              LatLng userLocation = LatLng(
                                  userPosition.latitude,
                                  userPosition.longitude);

                              var directions =
                                  await MapServices().getDirections(
                                "${userLocation.latitude},${userLocation.longitude}",
                                _destinationController.text,
                              );

                              _markers = {};
                              _polylines = {};

                              gotoPlace(
                                directions['start_location']['lat'],
                                directions['start_location']['lng'],
                                directions['end_location']['lat'],
                                directions['end_location']['lng'],
                                directions['bounds_ne'],
                                directions['bounds_sw'],
                              );
                              _setPolyline(directions['polyline_decoded']);
                            },
                            icon: Icon(Icons.search)),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                getDirections = false;
                                _originController.text = '';
                                _destinationController.text = '';
                                _markers = {};
                                _polylines = {};
                              });
                            },
                            icon: Icon(Icons.close)),
                      ],
                    ),
                  )),
            ),
          )
        ],
      ),
    );
  }

  Positioned buildCard(BuildContext context) {
    return Positioned(
      top: 100,
      left: 15,
      child: FlipCard(
        front: Container(
          height: 250,
          width: 175,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 150,
                  width: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(placeImg != ''
                          ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                          : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  width: 175,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        'Contact: ',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tappedPlaceDetail['formatted_phone_number'] ??
                            'none given',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Address: ',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tappedPlaceDetail['formatted_address'] ?? 'none given',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        back: Container(
          height: 300,
          width: 225,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isReviews = true;
                          isPhotos = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeIn,
                        padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: isReviews
                                ? Colors.purple.shade300
                                : Colors.white),
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                              color: isReviews ? Colors.white : Colors.black87,
                              fontFamily: 'WorkSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isReviews = false;
                          isPhotos = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeIn,
                        padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: isPhotos
                                ? Colors.purple.shade300
                                : Colors.white),
                        child: Text(
                          'Photos',
                          style: TextStyle(
                              color: isPhotos ? Colors.white : Colors.black87,
                              fontFamily: 'WorkSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 250,
                child: isReviews
                    ? ListView(
                        children: [
                          if (isReviews && tappedPlaceDetail['reviews'] != null)
                            ...tappedPlaceDetail['reviews']!.map((e) {
                              return _buildReviewItem(e);
                            })
                        ],
                      )
                    : _buildPhotoGallery(tappedPlaceDetail['photos'] ?? []),
              )
            ],
          ),
        ),
      ),
    );
  }

  Positioned _buildCard(BuildContext context) {
    return Positioned(
      top: 150,
      left: 50,
      child: FlipCard(
        front: Container(
            height: 250,
            width: 175,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
                child: Column(
              children: [
                Container(
                  height: 150,
                  width: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(placeImg != ''
                          ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                          : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  width: 175,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        'Contact: ',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tappedPlaceDetail['formatted_phone_number'] ??
                            'none given',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Address: ',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tappedPlaceDetail['formatted_address'] ?? 'none given',
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ))),
        back: Container(
          height: 300,
          width: 225,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isReviews = true;
                          isPhotos = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeIn,
                        padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: isReviews
                                ? Colors.purple.shade300
                                : Colors.white),
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                              color: isReviews ? Colors.white : Colors.black87,
                              fontFamily: 'WorkSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isReviews = false;
                          isPhotos = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeIn,
                        padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: isPhotos
                                ? Colors.purple.shade300
                                : Colors.white),
                        child: Text(
                          'Photos',
                          style: TextStyle(
                              color: isPhotos ? Colors.white : Colors.black87,
                              fontFamily: 'WorkSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 250,
                child: isReviews
                    ? ListView(
                        children: [
                          if (isReviews && tappedPlaceDetail['reviews'] != null)
                            ...tappedPlaceDetail['reviews']!.map((e) {
                              return _buildReviewItem(e);
                            })
                        ],
                      )
                    : _buildPhotoGallery(tappedPlaceDetail['photos'] ?? []),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: NetworkImage(allFavoritePlaces[index]['icon']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allFavoritePlaces[index]['name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  allFavoritePlaces[index]['vicinity'],
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Container(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        allFavoritePlaces[index]['business_status'] ?? 'None',
                        style: TextStyle(
                            //color: allFavoritePlaces[index]['business_status'] ==
                            //'OPERATIONAL'
                            ),
                      ),
                      IconButton(
                        onPressed: () async {},
                        icon: Icon(Icons.directions),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
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
}
