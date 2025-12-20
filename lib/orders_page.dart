import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'bottom_nav.dart'; // Import your navigation bar
import 'secrets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // --- CONFIGURATION ---
  final String googleApiKey = kGoogleApiKey;
  final Completer<GoogleMapController> _mapController = Completer();

  final TextEditingController _pickupController = TextEditingController(
    text: "Detecting location...",
  );
  final TextEditingController _dropoffController = TextEditingController();

  Timer? _debounce;
  Timer? _simulationTimer; // To control the moving driver

  // --- STATE ---
  LatLng pickup = const LatLng(5.3547, 100.3014); // Default USM
  LatLng? dropoff;
  LatLng? driverLatLng;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<dynamic> suggestions = [];
  List<LatLng> driverRoutePoints = [];

  bool isPickupActive = true;
  bool isRideConfirmed = false;
  bool isSimulationLoading = false;

  String travelKmText = "0.0 km";
  String travelMinText = "0 min";
  double numericDistanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentUserLocation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel(); // Clean up timer on exit
    super.dispose();
  }

  // --- 1. GPS & REVERSE GEOCODING ---
  Future<void> _getCurrentUserLocation() async {
    setState(() => _pickupController.text = "Detecting current location...");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() => pickup = currentLatLng);
    await _getAddressFromLatLng(currentLatLng);

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 16));
    _updateMarkers();
  }

  Future<void> _getAddressFromLatLng(LatLng coords) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${coords.latitude},${coords.longitude}&key=$googleApiKey";
    try {
      var res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (data['results'].isNotEmpty) {
          setState(
            () => _pickupController.text =
                data['results'][0]['formatted_address'].split(',')[0],
          );
        }
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
  }

  // --- 2. DRIVER SIMULATION & CANCEL LOGIC ---
  Future<void> _startAdvancedDriverSimulation() async {
    if (dropoff == null) return;
    setState(() {
      isSimulationLoading = true;
      isRideConfirmed = true;
    });

    Random random = Random();
    double offsetLat = (random.nextDouble() - 0.5) * 0.015;
    double offsetLng = (random.nextDouble() - 0.5) * 0.015;
    LatLng startRandomPoint = LatLng(
      pickup.latitude + offsetLat,
      pickup.longitude + offsetLng,
    );

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
          startRandomPoint.latitude,
          startRandomPoint.longitude,
        ),
        destination: PointLatLng(pickup.latitude, pickup.longitude),
        mode: TravelMode.driving,
      ),
      googleApiKey: googleApiKey,
    );

    if (result.points.isNotEmpty) {
      driverRoutePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      setState(() {
        isSimulationLoading = false;
        driverLatLng = driverRoutePoints[0];
      });
      _animateDriverMovement();
    } else {
      setState(() {
        driverLatLng = startRandomPoint;
        isSimulationLoading = false;
      });
      _startLegacySimulation();
    }
  }

  void _animateDriverMovement() {
    int currentIndex = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 600), (
      timer,
    ) {
      if (currentIndex >= driverRoutePoints.length - 1) {
        timer.cancel();
        setState(() {
          driverLatLng = pickup;
          travelMinText = "Driver Arrived";
        });
        _updateMarkers();
        _showArrivalDialog();
      } else {
        setState(() {
          currentIndex++;
          driverLatLng = driverRoutePoints[currentIndex];
          int remainingMins = ((driverRoutePoints.length - currentIndex) / 4)
              .ceil();
          travelMinText = remainingMins > 0
              ? "$remainingMins min away"
              : "Arriving...";
        });
        _updateMarkers();
      }
    });
  }

  void _startLegacySimulation() {
    int steps = 15;
    int currentStep = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      if (currentStep >= steps) {
        timer.cancel();
        _showArrivalDialog();
      } else {
        setState(() {
          currentStep++; /* Linear logic here */
        });
        _updateMarkers();
      }
    });
  }

  void _cancelRide() {
    _simulationTimer?.cancel();
    setState(() {
      isRideConfirmed = false;
      driverLatLng = null;
      driverRoutePoints = [];
      travelMinText =
          "${(numericDistanceKm * 5).ceil()} min"; // Reset to original estimate
    });
    _updateMarkers();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ride Cancelled")));
  }

  // --- 3. UI CONTROLS ---
  Future<void> _zoomIn() async {
    (await _mapController.future).animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    (await _mapController.future).animateCamera(CameraUpdate.zoomOut());
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Driver Arrived!"),
        content: const Text(
          "Your UniPool driver is waiting at the pickup point.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- 4. SEARCH & ROUTING ---
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.length < 3) return;
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&location=${pickup.latitude},${pickup.longitude}&radius=5000&key=$googleApiKey";
      var res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() => suggestions = json.decode(res.body)['predictions']);
      }
    });
  }

  void _selectPlace(dynamic suggestion) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${suggestion['place_id']}&key=$googleApiKey";
    var res = await http.get(Uri.parse(url));
    var loc = json.decode(res.body)['result']['geometry']['location'];
    LatLng newPoint = LatLng(loc['lat'], loc['lng']);

    setState(() {
      if (isPickupActive) {
        pickup = newPoint;
        _pickupController.text = suggestion['description'].split(',')[0];
      } else {
        dropoff = newPoint;
        _dropoffController.text = suggestion['description'].split(',')[0];
      }
      suggestions = [];
    });
    (await _mapController.future).animateCamera(
      CameraUpdate.newLatLngZoom(newPoint, 15),
    );
    _updateMarkers();
    if (dropoff != null) _fetchRoute();
  }

  void _fetchRoute() async {
    if (dropoff == null) return;
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickup.latitude, pickup.longitude),
        destination: PointLatLng(dropoff!.latitude, dropoff!.longitude),
        mode: TravelMode.driving,
      ),
      googleApiKey: googleApiKey,
    );

    if (result.points.isNotEmpty) {
      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blueAccent,
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            width: 5,
          ),
        );
      });
    }

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${pickup.latitude},${pickup.longitude}&destination=${dropoff!.latitude},${dropoff!.longitude}&key=$googleApiKey";
    var res = await http.get(Uri.parse(url));
    var leg = json.decode(res.body)['routes'][0]['legs'][0];
    setState(() {
      travelKmText = leg['distance']['text'];
      travelMinText = leg['duration']['text'];
      numericDistanceKm = leg['distance']['value'] / 1000.0;
    });
  }

  void _updateMarkers() {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId("p"),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
      if (dropoff != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("d"),
            position: dropoff!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
      if (driverLatLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("driver"),
            position: driverLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
            infoWindow: const InfoWindow(title: "Driver arriving..."),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double price = (numericDistanceKm * 1.50) + 3.00;
    return Scaffold(
      // --- INTEGRATE BOTTOM NAV BAR ---
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
            onMapCreated: (c) => _mapController.complete(c),
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // ZOOM BUTTONS
          Positioned(
            right: 15,
            top: 230,
            child: Column(
              children: [
                _circularBtn(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _circularBtn(Icons.remove, _zoomOut),
                const SizedBox(height: 10),
                _circularBtn(Icons.my_location, _getCurrentUserLocation),
              ],
            ),
          ),

          // SEARCH PANEL
          if (!isRideConfirmed)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _row(
                            _pickupController,
                            "Pickup",
                            Icons.circle,
                            Colors.blue,
                            true,
                          ),
                          const Divider(height: 20),
                          _row(
                            _dropoffController,
                            "Destination",
                            Icons.location_on,
                            Colors.red,
                            false,
                          ),
                        ],
                      ),
                    ),
                    if (suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          itemBuilder: (c, i) => ListTile(
                            title: Text(suggestions[i]['description']),
                            onTap: () => _selectPlace(suggestions[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // BOTTOM INFO & BUTTONS
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRideConfirmed
                                ? "Driver coming to you"
                                : "UniPool Economy",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "$travelMinText • $travelKmText",
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      Text(
                        numericDistanceKm == 0
                            ? "RM --"
                            : "RM ${price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (!isRideConfirmed)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (dropoff == null)
                            ? null
                            : _startAdvancedDriverSimulation,
                        child: isSimulationLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Confirm Ride"),
                      ),
                    )
                  else
                    // CANCEL BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _cancelRide,
                        child: const Text(
                          "Cancel Ride",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    TextEditingController ctrl,
    String h,
    IconData i,
    Color c,
    bool p,
  ) {
    return Row(
      children: [
        Icon(i, color: c, size: 18),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: ctrl,
            onChanged: _onSearchChanged,
            onTap: () => setState(() => isPickupActive = p),
            decoration: InputDecoration(
              hintText: h,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _circularBtn(IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
