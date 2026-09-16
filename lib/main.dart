import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Field Collector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GpsStatusPage(),
    );
  }
}

class GpsStatusPage extends StatefulWidget {
  const GpsStatusPage({super.key});

  @override
  State<GpsStatusPage> createState() => _GpsStatusPageState();
}

class _GpsStatusPageState extends State<GpsStatusPage> {
  String _statusMessage = "GPS Ready to Scan";
  String _lat = "0.000000";
  String _long = "0.000000";
  String _accuracy = "0.0";
  String _altitude = "0.0";
  bool _isFetching = false;

  // Function to fetch high-precision GPS data targeting <= 5.0m
  Future<void> _fetchGpsData() async {
    setState(() {
      _isFetching = true;
      _statusMessage = "Acquiring satellites & fixing position...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "GPS is disabled. Please turn on Location.";
        _isFetching = false;
      });
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permissions are denied.";
          _isFetching = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = "Permissions permanently denied. Enable in settings.";
        _isFetching = false;
      });
      return;
    }

    try {
      // Force high accuracy for <= 5m target
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _lat = position.latitude.toStringAsFixed(6);
        _long = position.longitude.toStringAsFixed(6);
        _accuracy = position.accuracy.toStringAsFixed(1);
        _altitude = position.altitude.toStringAsFixed(1);
        
        if (position.accuracy <= 5.0) {
          _statusMessage = "High Accuracy Fix Achieved (<= 5m)";
        } else {
          _statusMessage = "Low Accuracy. Move to an open sky area.";
        }
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error fetching GPS: $e";
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double accValue = double.tryParse(_accuracy) ?? 99.0;
    bool isGoodAccuracy = accValue <= 5.0 && accValue > 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Field Data Status'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGoodAccuracy ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isGoodAccuracy ? Colors.green : Colors.orange,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isGoodAccuracy ? Colors.green[800] : Colors.orange[900],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow("Latitude:", _lat),
                    const Divider(),
                    _buildInfoRow("Longitude:", _long),
                    const Divider(),
                    _buildInfoRow("Accuracy:", "$_accuracy meters"),
                    const Divider(),
                    _buildInfoRow("Altitude:", "$_altitude meters"),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _isFetching
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _fetchGpsData,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Get Precise GPS Fix'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
