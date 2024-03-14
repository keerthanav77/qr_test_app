import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_test/local_db_helper.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:qrscan/qrscan.dart' as scanner;

import 'locations_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Location Share'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool generatingQr = false;

  void _shareLocation() async {
    if (generatingQr) return;
    setState(() {
      generatingQr = true;
    });
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      _showSnackBar("Location Permission is required, Please allow location permission");
      setState(() {
        generatingQr = false;
      });
      return;
    }
    Location location = Location();
    LocationData locationData = await location.getLocation();
    final barcode = SfBarcodeGenerator(
      value: "Latitude: ${locationData.latitude}, Longitude: ${locationData.longitude}",
      showValue: true,
      symbology: QRCode(),
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Scan the QR code below to share your location",textAlign: TextAlign.center,),
              const SizedBox(
                width: 0,
                height: 25,
              ),
              barcode,
              const SizedBox(
                width: 0,
                height: 30,
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"))
            ],
          ),
        ),
      ),
    ).then((value) {
      setState(() {
        generatingQr = false;
      });
    });
  }

  void _scanLocation() async {
    final hasPermission = await _checkCameraPermission();
    if (!hasPermission) {
      _showSnackBar("Camera Permission is required, Please allow camera permission");
      return;
    }
    String? cameraScanResult = await scanner.scan();
    if(cameraScanResult != null && cameraScanResult.isNotEmpty) {
      try {
        final (lat, long) = _parseLatLong(cameraScanResult);
        _showSnackBar("Latitude: $lat, Longitude: $long");
        _saveLocation(LocationModel(lat, long));
      } on Exception catch (e) {
        _showSnackBar(e.toString());
      }
    }
  }

  Future<void> _saveLocation(LocationModel location)async{
    final result = await DatabaseHelper.saveLocation(location);
    if(result > 0) {
      _showSnackBar("Location saved successfully");
    }
  }

  void _goToSavedLocations() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationsList()));
  }

  @override
  void dispose() {
    DatabaseHelper.closeDatabase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: _shareLocation,
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.sizeOf(context).width/2, 50)
              ),
                child: generatingQr ? const SizedBox(height: 20,width: 20,
                    child: CircularProgressIndicator()) : const Text('Share Location'),
            ),
            const SizedBox(
              width: 0,
              height: 20,
            ),
            ElevatedButton(onPressed: _scanLocation,  style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.sizeOf(context).width/2, 50)
            ), child: const Text('Scan Location QR Code')),
            const SizedBox(
              width: 0,
              height: 20,
            ),
            ElevatedButton(onPressed: _goToSavedLocations,  style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.sizeOf(context).width/2, 50)
            ), child: const Text('Saved Locations')),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    await Permission.camera.request();
    status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    return false;
  }

  Future<bool> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    await Permission.location.request();

    status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    return false;
  }

  void _showSnackBar(String message) {
    _clearSnackBar();
    if (message.isEmpty) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearSnackBar(){
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  (double,double) _parseLatLong(String location){
    try {
      final latLong = location.split(',');
      return (double.parse(latLong[0].split(':').last), double.parse(latLong[1].split(':').last));
    } on Exception catch (e) {
      throw Exception("Unable to parse the latitude and longitude. Error: $e");
    }
  }
}
