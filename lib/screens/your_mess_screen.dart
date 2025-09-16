// Full updated code with back button in AppBar for YourMessScreen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:mess_management_app/widgets/drawer_section.dart';
import 'package:mess_management_app/widgets/bottom_navigation_bar.dart';

class YourMessScreen extends StatefulWidget {
  final String messId;
  const YourMessScreen({super.key, required this.messId});

  @override
  _YourMessScreenState createState() => _YourMessScreenState();
}

class _YourMessScreenState extends State<YourMessScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _yourMess;
  bool _isLoading = true;
  bool _isAdmin = false;
  String userName = "User";
  String userEmail = "user@example.com";
  String? profileImageUrl;
  List<Map<String, dynamic>> _joinRequests = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await _fetchYourMess();
    await _getUserData();
  }

  Future<void> _fetchYourMess() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      DocumentSnapshot messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(widget.messId)
          .get();

      if (!messDoc.exists) throw Exception('Mess does not exist');

      Map<String, dynamic> messData = messDoc.data() as Map<String, dynamic>;
      messData['id'] = messDoc.id;

      bool isAdmin = messData['admin_id'] == userId;
      List<dynamic> members = messData['members'] ?? [];
      bool isMember = members.contains(userId);

      if (!isAdmin && !isMember) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists && userDoc['mess_id'] == widget.messId) {
          await FirebaseFirestore.instance
              .collection('messes')
              .doc(widget.messId)
              .update({
            'members': FieldValue.arrayUnion([userId]),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are not a member or admin of this mess.')));
          Navigator.pop(context);
          return;
        }
      }

      if (isAdmin) {
        QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
            .collection('messes')
            .doc(widget.messId)
            .collection('join_requests')
            .get();

        _joinRequests = requestsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['request_id'] = doc.id;
          return data;
        }).toList();
      }

      setState(() {
        _yourMess = messData;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching mess: $e')));
    }
  }

  Future<void> _getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'] ?? "User";
        userEmail = user.email ?? "user@example.com";
        profileImageUrl = userData['profile_image'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching user: $e')));
    }
  }

  Future<void> _handleJoinRequest(String requestId, String userId, bool approve) async {
    try {
      if (approve) {
        await FirebaseFirestore.instance
            .collection('messes')
            .doc(widget.messId)
            .update({'members': FieldValue.arrayUnion([userId])});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'mess_id': widget.messId});
      }

      await FirebaseFirestore.instance
          .collection('messes')
          .doc(widget.messId)
          .collection('join_requests')
          .doc(requestId)
          .delete();

      setState(() =>
          _joinRequests.removeWhere((req) => req['request_id'] == requestId));

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Request approved!' : 'Request rejected!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildQuickOptionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade50,
          foregroundColor: Colors.purple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
        ),
        onPressed: () => Navigator.pushNamed(context, '/quick_options', arguments: {'messId': widget.messId}),
        icon: const Icon(Icons.bolt),
        label: const Text("Quick Option (Meal ON/OFF)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGridButton({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("$userName's Hub", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _yourMess == null
          ? Center(child: Text('You are not part of any mess.', style: TextStyle(color: Colors.grey[700])))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_yourMess!['name'] ?? "Mess Family", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Your daily essentials, redefined.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),

              _buildQuickOptionButton(),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridButton(icon: Icons.bar_chart, label: 'Stats', color: Colors.indigo, onTap: () => Navigator.pushNamed(context, '/mess_stats', arguments: {'messId': widget.messId})),
                  _buildGridButton(icon: Icons.add_shopping_cart, label: 'Shopping', color: Colors.orange, onTap: () => Navigator.pushNamed(context, '/shopping_record', arguments: {'messId': widget.messId})),
                  _buildGridButton(icon: Icons.person, label: 'Profile', color: Colors.teal, onTap: () => Navigator.pushNamed(context, '/userProfile', arguments: {
                    'userId': _auth.currentUser?.uid,
                    'messId': widget.messId,
                  })),
                ],
              ),

              const SizedBox(height: 30),
              const Text("Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Text("Join Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _isAdmin
                  ? (_joinRequests.isEmpty
                  ? const Text('No pending join requests.', style: TextStyle(color: Colors.black54))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _joinRequests.length,
                itemBuilder: (context, index) {
                  var request = _joinRequests[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(request['user_name'] ?? 'Unknown'),
                      subtitle: Text(request['user_email'] ?? ''),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _handleJoinRequest(request['request_id'], request['user_id'], true)),
                          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _handleJoinRequest(request['request_id'], request['user_id'], false)),
                        ],
                      ),
                    ),
                  );
                },
              ))
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      drawer: DrawerSection(
        userName: userName,
        userEmail: userEmail,
        profileImageUrl: profileImageUrl,
        messId: widget.messId,
      ),
      bottomNavigationBar: BottomNavigationBarSection(
        messId: widget.messId,
        isAdmin: _isAdmin,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
