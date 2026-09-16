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
      debugShowCheckedModeBanner: false,
      home: GPSSampleScreen(),
    );
  }
}

class GPSSampleScreen extends StatefulWidget {
  const GPSSampleScreen({super.key});

  @override
  _GPSSampleScreenState createState() => _GPSSampleScreenState();
}

class _GPSSampleScreenState extends State<GPSSampleScreen> {
  String _selectedType = 'Sewer Line';
  final TextEditingController _customerKeyController = TextEditingController();
  
  Position? _currentPosition;
  double? _accuracy;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _detectGPSPoint() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'GPS አልበራም። እባክዎን Location ያብሩ።';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'የLocation ፍቃድ አልተሰጠም።';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _currentPosition = position;
        _accuracy = position.accuracy;
        _isLoading = false;

        if (position.accuracy > 5.0) {
          _errorMessage = 'GPS accuracy (${position.accuracy.toStringAsFixed(1)}m) too low. Need ≤5.0m. Try again in an open area.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ቦታውን ማግኘት አልተቻለም፦ $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSaveEnabled = _currentPosition != null && _accuracy != null && _accuracy! <= 5.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Sample GPS Point'),
        backgroundColor: Colors.indigo[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['Sewer Line', 'Water Line', 'Customer Point']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerKeyController,
              decoration: const InputDecoration(labelText: 'Customer Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text('Line types can use one or more detected locations.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _detectGPSPoint,
                icon: const Icon(Icons.my_location),
                label: Text(_isLoading ? 'Detecting...' : 'Detect GPS Point'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isSaveEnabled ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('የGPS መረጃው በትክክል ተመዝግቧል!')),
                  );
                } : null,
                child: const Text('Save'),
              ),
            ),
            const Spacer(),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
