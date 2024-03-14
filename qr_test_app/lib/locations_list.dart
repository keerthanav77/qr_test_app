import 'package:flutter/material.dart';
import 'package:qr_test/local_db_helper.dart';


class LocationsList extends StatefulWidget {
  const LocationsList({super.key});

  @override
  _LocationsListState createState() => _LocationsListState();
}

class _LocationsListState extends State<LocationsList> {
  List<LocationModel> _locations = [];

  @override
  void initState() {
    super.initState();
    _getLocations();
  }

  Future<void> _getLocations() async {
    final locations = await DatabaseHelper.getAllLocations();
    setState(() {
      _locations = locations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Saved Locations'),
      ),
      body: ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return ListTile(
            title: Text('Lat: ${location.latitude}, Lon: ${location.longitude}'),
          );
        },
      ),
    );
  }
}
