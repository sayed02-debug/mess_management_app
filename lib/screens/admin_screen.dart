import 'package:flutter/material.dart';
import 'package:mess_management_app/services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  final String messId;

  const AdminScreen({super.key, required this.messId});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _joinRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJoinRequests();
  }

  Future<void> _fetchJoinRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final joinRequests = await _firestoreService.getJoinRequests(widget.messId);
      setState(() {
        _joinRequests = joinRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching join requests: $e')),
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
      _fetchJoinRequests();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
      _fetchJoinRequests();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join Requests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _joinRequests.isEmpty
                ? const Center(child: Text('No join requests.'))
                : Expanded(
              child: ListView.builder(
                itemCount: _joinRequests.length,
                itemBuilder: (context, index) {
                  final request = _joinRequests[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(request['name'] ?? 'Unknown'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveRequest(request['user_id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectRequest(request['user_id']),
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