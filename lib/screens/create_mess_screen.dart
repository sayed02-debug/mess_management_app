import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CreateMessScreen extends StatefulWidget {
  const CreateMessScreen({super.key});

  @override
  _CreateMessScreenState createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends State<CreateMessScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();
  final _rentController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController(); // New for manual location input
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _selectedType = 'Bachelor';
  final List<String> _messTypes = ['Bachelor', 'Family', 'Co-Ed'];
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  LatLng? _selectedLocation;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _rentController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _locationController.text = '${position.latitude}, ${position.longitude}';
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
    }
  }

  void _onTapMap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _locationController.text = '${position.latitude}, ${position.longitude}';
    });
  }

  Future<void> _createMess() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) return;

    final String name = _nameController.text.trim();
    final String address = _addressController.text.trim();
    final String type = _selectedType;
    final String capacity = _capacityController.text.trim();
    final String rent = _rentController.text.trim();
    final String contact = _contactController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Mess Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mess Name: $name'),
            Text('Address: $address'),
            Text('Type: $type'),
            Text('Capacity: $capacity'),
            Text('Monthly Rent: BDT $rent'),
            Text('Contact Number: $contact'),
            Text('Location: ${_selectedLocation?.latitude}, ${_selectedLocation?.longitude}'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to create this mess?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userName = userDoc['name'] ?? 'Unknown';

      final messData = {
        'name': name,
        'address': address,
        'mess_type': type,
        'capacity': int.parse(capacity),
        'monthly_rent': double.parse(rent),
        'contact_number': contact,
        'creator_name': userName,
        'admin_id': userId,
        'members': [userId],
        'created_at': FieldValue.serverTimestamp(),
        'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      };

      final messRef = await FirebaseFirestore.instance.collection('messes').add(messData);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'mess_id': messRef.id});

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 60, color: Colors.green),
              SizedBox(height: 12),
              Text('Mess created successfully!', textAlign: TextAlign.center),
              SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              child: const Text('Go to Home'),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAnimatedField(Widget child) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Mess'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildAnimatedField(Text("Register a New Mess",
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold))),
              _buildAnimatedField(TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Mess Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter mess name' : null,
              )),
              _buildAnimatedField(TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
              )),
              _buildAnimatedField(DropdownButtonFormField<String>(
                value: _selectedType,
                items: _messTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _selectedType = val ?? 'Bachelor'),
                decoration: const InputDecoration(labelText: 'Mess Type', border: OutlineInputBorder()),
              )),
              _buildAnimatedField(TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid number' : null,
              )),
              _buildAnimatedField(TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(labelText: 'Monthly Rent (BDT)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid rent' : null,
              )),
              _buildAnimatedField(TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter contact number' : null,
              )),
              _buildAnimatedField(TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'Location (lat, long) e.g., 23.8103, 90.4125',
                    border: OutlineInputBorder()),
                onFieldSubmitted: (value) { // Changed from onSubmitted to onFieldSubmitted
                  final parts = value.split(',').map((e) => double.tryParse(e.trim())).toList();
                  if (parts.length == 2 && parts[0] != null && parts[1] != null) {
                    setState(() {
                      _selectedLocation = LatLng(parts[0]!, parts[1]!);
                    });
                  }
                },
                validator: (v) => _selectedLocation == null ? 'Select or enter a location' : null,
              )),
              _buildAnimatedField(ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Use Current Location'),
              )),
              _buildAnimatedField(SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(23.8103, 90.4125), // Default: Dhaka
                    zoom: 10,
                  ),
                  onTap: _onTapMap,
                  markers: _selectedLocation == null
                      ? {}
                      : {Marker(markerId: const MarkerId('selected'), position: _selectedLocation!)},
                ),
              )),
              _buildAnimatedField(ElevatedButton.icon(
                onPressed: _createMess,
                icon: const Icon(Icons.add_circle_outline),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('Create Mess', style: TextStyle(fontSize: 16)),
              ))
            ],
          ),
        ),
      ),
    );
  }
}