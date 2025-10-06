import 'package:budgetlisting/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddLocationPage extends StatefulWidget {
  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _locationNameController = TextEditingController();

  LatLng? _selectedLocation;
  LatLng? _initialLocation;
  bool _locationReady = false;
  late String _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null)
        return;

      final currentLatLng = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        _initialLocation = currentLatLng;
        _selectedLocation = currentLatLng;
        _locationReady = true;
      });

      // Tunggu widget selesai render sebelum move
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _mapController.move(currentLatLng, 15.0);
        }
      });
    } catch (e) {
      print("Gagal mendapatkan lokasi pengguna: $e");
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  void _onSave() async {
    if (_selectedLocation == null || _locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon pilih lokasi dan isi nama lokasi')),
      );
      return;
    }

    final locationService = TransactionAPI();
    final result = await locationService.addLocation(
      token: _token, // Gunakan token yang sudah kamu ambil sebelumnya
      name: _locationNameController.text,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['success']) {
      Navigator.pop(context); // atau reset form jika ingin tetap di halaman
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pilih Lokasi'), centerTitle: true),
      body:
          _locationReady && _initialLocation != null
              ? Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _initialLocation,
                        zoom: 15.0,
                        maxZoom: 18.0, // JANGAN LEBIH DARI 19 UNTUK OSM
                        minZoom: 3.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=tPvxm10M5jq3xNufZHTF',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80,
                                height: 80,
                                point: _selectedLocation!,
                                builder:
                                    (ctx) => Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        if (_selectedLocation != null) ...[
                          Text(
                            'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                        SizedBox(height: 12),
                        TextField(
                          controller: _locationNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lokasi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onSave,
                            child: Text('Simpan Lokasi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Center(child: CircularProgressIndicator()),
    );
  }
}
