import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';

class MessDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> mess;
  const MessDetailsScreen({super.key, required this.mess});

  @override
  _MessDetailsScreenState createState() => _MessDetailsScreenState();
}

class _MessDetailsScreenState extends State<MessDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isMember = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isMember = false;
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }
      final isMember = await _firestoreService.isUserMemberOfMess(widget.mess['id'], userId);
      final isAdmin = widget.mess['admin_id'] == userId;
      setState(() {
        _isMember = isMember;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendJoinRequest() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You should login first.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/auth');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_isMember || _isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already a member or admin.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestoreService.sendJoinRequest(widget.mess['id'], userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending join request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 15))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: Text(widget.mess['name'] ?? 'Mess Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 1,
        backgroundColor: const Color(0xFF00BFA5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mess Overview", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF263238))),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                color: Colors.white,
                shadowColor: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Name", widget.mess['name'] ?? 'N/A'),
                      _buildDetailRow("Address", widget.mess['address'] ?? 'N/A'),
                      _buildDetailRow("Type", widget.mess['mess_type'] ?? 'N/A'),
                      _buildDetailRow("Capacity", widget.mess['capacity']?.toString() ?? 'N/A'),
                      _buildDetailRow("Monthly Rent", "BDT ${widget.mess['monthly_rent'] ?? 'N/A'}"),
                      _buildDetailRow("Contact", widget.mess['contact_number'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _sendJoinRequest,
                  icon: const Icon(Icons.group_add),
                  label: const Text("Send Join Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
