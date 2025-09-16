import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added this import

class AdminScreen extends StatefulWidget {
  final String messId;

  const AdminScreen({super.key, required this.messId});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _joinRequests = [];
  Map<String, dynamic>? _messData;

  @override
  void initState() {
    super.initState();
    _checkAdminAndFetchRequests();
  }

  Future<void> _checkAdminAndFetchRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('User not logged in'); // Debug log
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      // Fetch mess data to check if the current user is the admin
      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(widget.messId)
          .get();
      final messData = messDoc.data();
      if (messData == null) {
        throw Exception('Mess not found');
      }

      final isAdmin = messData['admin_id'] == userId;
      print('Admin check: isAdmin=$isAdmin'); // Debug log

      if (!isAdmin) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      // Fetch join requests
      final joinRequests = await _firestoreService.getJoinRequests(widget.messId);

      setState(() {
        _isAdmin = isAdmin;
        _messData = messData;
        _joinRequests = joinRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _checkAdminAndFetchRequests: $e'); // Debug log
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _approveRequest(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.approveJoinRequest(widget.messId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request approved!')),
      );
      await _checkAdminAndFetchRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectRequest(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.rejectJoinRequest(widget.messId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request rejected!')),
      );
      await _checkAdminAndFetchRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_messData != null ? '${_messData!['name']} Admin Panel' : 'Admin Panel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
          ? const Center(child: Text('You are not the admin of this mess.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Join Requests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _joinRequests.isEmpty
                ? const Center(child: Text('No join requests available.'))
                : Expanded(
              child: ListView.builder(
                itemCount: _joinRequests.length,
                itemBuilder: (context, index) {
                  final request = _joinRequests[index];
                  final userName = request['name'] ?? 'Unknown';
                  final userId = request['user_id'];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Request from: $userName'),
                      subtitle: Text('User ID: $userId'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveRequest(userId),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectRequest(userId),
                            tooltip: 'Reject',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}