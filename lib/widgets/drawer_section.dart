import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawerSection extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final String messId;

  const DrawerSection({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.messId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              child: profileImageUrl != null
                  ? ClipOval(
                child: Image.network(
                  profileImageUrl!,
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              )
                  : const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2A44),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Your Mess'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/yourMess');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}