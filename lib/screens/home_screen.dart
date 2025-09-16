import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mess_features/shopping_record_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'mess_features/quick_options_screen.dart';

import '../widgets/drawer_section.dart';
import '../widgets/meal_section.dart';
import '../widgets/shopping_list_section.dart';
import '../widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Guest";
  String userEmail = "guest@example.com";
  String? profileImageUrl;
  String? messId;
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        userName = "Guest";
        userEmail = "guest@example.com";
        messId = null;
        _isAdmin = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) throw Exception('User document does not exist in Firestore');

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'] ?? "Guest";
        userEmail = user.email ?? "guest@example.com";
        profileImageUrl = userData['profile_image'];
        messId = userData['mess_id'];
        _isLoading = false;
      });

      if (messId != null && messId!.isNotEmpty) {
        DocumentSnapshot messDoc = await FirebaseFirestore.instance.collection('messes').doc(messId).get();
        if (messDoc.exists) {
          Map<String, dynamic> messData = messDoc.data() as Map<String, dynamic>;
          _isAdmin = messData['admin_id'] == uid;
          setState(() {});
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  void _checkLoginAndNavigate(String route) {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You should login first.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            }, child: const Text('OK')),
          ],
        ),
      );
    } else {
      if (route == '/yourMess' && messId != null) {
        Navigator.pushNamed(context, route, arguments: {'messId': messId});
      } else if (route == '/yourMess' && messId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No mess assigned to your account.')));
      } else {
        Navigator.pushNamed(context, route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2A44), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                "$userName's Hub",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    FirebaseAuth.instance.currentUser != null ? Icons.logout : Icons.login,
                    color: Colors.white70,
                  ),
                  onPressed: () async {
                    if (FirebaseAuth.instance.currentUser != null) {
                      await FirebaseAuth.instance.signOut();
                      setState(() {
                        userName = "Guest";
                        userEmail = "guest@example.com";
                        messId = null;
                        _isAdmin = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                    } else {
                      Navigator.pushNamed(context, '/auth');
                    }
                  },
                ),
              ],
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Manage your mess with ease.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Options",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildFeatureCard("Create Mess", Icons.add_home, const Color(0xFFF43F5E),
                                  () => _checkLoginAndNavigate('/create_mess')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard("Mess List", Icons.list, const Color(0xFF00E676),
                                  () => Navigator.pushNamed(context, '/messList')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard("Your Mess", Icons.home, const Color(0xFF3B82F6),
                                  () => _checkLoginAndNavigate('/yourMess')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Tip: Use the options above to create a new mess, browse existing ones, or manage your current mess efficiently.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: DrawerSection(
          userName: userName,
          userEmail: userEmail,
          profileImageUrl: profileImageUrl,
          messId: messId ?? "",
        ),
      ),
      bottomNavigationBar: BottomNavigationBarSection(
        messId: messId ?? "",
        isAdmin: _isAdmin,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        backgroundColor: const Color(0xFF00E676),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        hoverElevation: 12,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFeatureCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), const Color(0xFF2A3448)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
