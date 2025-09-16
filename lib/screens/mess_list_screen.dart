import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MessListScreen extends StatefulWidget {
  const MessListScreen({super.key});

  @override
  _MessListScreenState createState() => _MessListScreenState();
}

class _MessListScreenState extends State<MessListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _messes = [];
  List<Map<String, dynamic>> _filteredMesses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationSearchController = TextEditingController();
  String _sortBy = 'name';
  LatLng? _currentLocation;
  LatLng? _selectedSearchLocation;
  bool _isLocationBasedSearch = false;
  double _searchRadius = 50000; // Increased to 50 km for broader search

  @override
  void initState() {
    super.initState();
    _fetchMesses();
    _searchController.addListener(_filterMesses);
    _locationSearchController.addListener(_filterMesses);
    _getCurrentLocation();
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
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (_isLocationBasedSearch && _selectedSearchLocation == null) {
        _selectedSearchLocation = _currentLocation;
      }
      _filterMesses();
    });
  }

  Future<void> _fetchMesses() async {
    setState(() => _isLoading = true);
    try {
      final messes = await _firestoreService.getAllMesses();
      setState(() {
        _messes = messes;
        _applySortAndFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching messes: $e')),
      );
    }
  }

  void _filterMesses() {
    _applySortAndFilter();
  }

  void _applySortAndFilter() {
    _filteredMesses = [..._messes];
    final nameQuery = _searchController.text.toLowerCase();
    final locationQuery = _locationSearchController.text;

    _filteredMesses = _filteredMesses.where((mess) {
      final nameMatch = (mess['name'] ?? '').toLowerCase().contains(nameQuery);
      if (!_isLocationBasedSearch || _selectedSearchLocation == null || !mess.containsKey('location')) {
        return nameMatch;
      }

      final messLocation = mess['location'] as GeoPoint;
      final distance = Geolocator.distanceBetween(
        _selectedSearchLocation!.latitude,
        _selectedSearchLocation!.longitude,
        messLocation.latitude,
        messLocation.longitude,
      );
      return nameMatch || distance <= _searchRadius; // Show all messes within radius, name is optional
    }).toList();

    if (_sortBy == 'recent') {
      _filteredMesses.sort((a, b) {
        final aDate = a['created_at']?.toDate() ?? DateTime.now();
        final bDate = b['created_at']?.toDate() ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
    } else {
      _filteredMesses.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    }
  }

  Future<void> _navigateToCreateMess() async {
    if (_auth.currentUser == null) {
      _showLoginDialog();
    } else {
      await Navigator.pushNamed(context, '/create_mess');
      _fetchMesses();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/auth');
          }, child: const Text('Login')),
        ],
      ),
    );
  }

  void _toggleLocationSearch() {
    setState(() {
      _isLocationBasedSearch = !_isLocationBasedSearch;
      if (_isLocationBasedSearch && _selectedSearchLocation == null && _currentLocation != null) {
        _selectedSearchLocation = _currentLocation;
      }
      _filterMesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mess Directory', style: GoogleFonts.poppins()),
        actions: [
          DropdownButton<String>(
            value: _sortBy,
            icon: const Icon(Icons.sort, color: Colors.white),
            dropdownColor: Colors.blueGrey,
            underline: const SizedBox(),
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _applySortAndFilter();
              });
            },
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
              DropdownMenuItem(value: 'recent', child: Text('Sort by Recent')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search mess by name...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateMess,
                      icon: const Icon(Icons.add),
                      label: const Text('New Mess'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationSearchController,
                        decoration: InputDecoration(
                          hintText: 'Enter location (lat, long) e.g., 23.8103, 90.4125...',
                          prefixIcon: const Icon(Icons.location_on),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (value) {
                          final parts = value.split(',').map((e) => double.tryParse(e.trim())).toList();
                          if (parts.length == 2 && parts[0] != null && parts[1] != null) {
                            setState(() {
                              _selectedSearchLocation = LatLng(parts[0]!, parts[1]!);
                              _isLocationBasedSearch = true;
                              _filterMesses();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _toggleLocationSearch,
                      icon: Icon(_isLocationBasedSearch ? Icons.location_off : Icons.location_on),
                      label: Text(_isLocationBasedSearch ? 'Disable Location' : 'Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLocationBasedSearch ? Colors.red : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMesses.isEmpty
                ? const Center(child: Text('No messes found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredMesses.length,
              itemBuilder: (context, index) {
                final mess = _filteredMesses[index];
                final name = mess['name'] ?? 'Unnamed';
                final address = mess['address'] ?? 'No address';
                final createdAt = mess['created_at']?.toDate();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/mess_details',
                        arguments: {'mess': mess},
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          address,
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        trailing: createdAt != null
                            ? Text(
                          DateFormat('dd MMM').format(createdAt),
                          style: GoogleFonts.poppins(color: Colors.white60),
                        )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }
}