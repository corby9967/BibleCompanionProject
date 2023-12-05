import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/home.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;

  LatLng center = const LatLng(36.103255, 129.388849);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      center = LatLng(position.latitude, position.longitude);
    });

    print(position);
    print(center);
  }

  @override
  void initState() {
    _determinePosition();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Get.to(() => HomePage(groupCode: widget.groupCode),
                  transition: Transition.leftToRight);
            },
          ),
          title: const Text(
            '지도',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 14.0,
          ),
          markers: {
            const Marker(
              markerId: MarkerId('1'),
              position: LatLng(36.1021, 129.3912),
              infoWindow: InfoWindow(
                title: "1",
                snippet: "나야",
              ),
            ),
            const Marker(
              markerId: MarkerId('2'),
              position: LatLng(36.1029, 129.3912),
              infoWindow: InfoWindow(
                title: "2",
                snippet: "너야",
              ),
            )
          },
        ),
      ),
    );
  }
}
