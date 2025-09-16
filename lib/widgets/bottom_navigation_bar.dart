import 'package:flutter/material.dart';
import 'package:mess_management_app/screens/mess_features/meal_cost_screen.dart';
import 'package:mess_management_app/screens/mess_features/shopping_record_screen.dart';
import 'package:mess_management_app/screens/admin_screen.dart';

class BottomNavigationBarSection extends StatelessWidget {
  final String messId;
  final bool isAdmin;

  const BottomNavigationBarSection({super.key, required this.messId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    print('BottomNavigationBarSection: messId = $messId, isAdmin = $isAdmin'); // Debug log

    return BottomAppBar(
      color: Colors.blueAccent,
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.dashboard, color: Colors.white),
            onPressed: () {
              print('Dashboard button pressed'); // Debug log
            },
          ),
          IconButton(
            icon: Icon(Icons.group, color: Colors.white),
            onPressed: () {
              print('Members button pressed'); // Debug log
            },
          ),
          SizedBox(width: 40), // Spacing for floating action button
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              print('Shopping button pressed, messId = $messId'); // Debug log
              if (messId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingRecordScreen(messId: messId)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mess ID is missing. Please try again.')),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.receipt, color: Colors.white),
            onPressed: () {
              print('Meal Cost button pressed, messId = $messId'); // Debug log
              if (messId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MealCostScreen(messId: messId)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mess ID is missing. Please try again.')),
                );
              }
            },
          ),
          if (isAdmin) ...[
            IconButton(
              icon: Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                print('Admin Panel button pressed, messId = $messId'); // Debug log
                if (messId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminScreen(messId: messId)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mess ID is missing. Please try again.')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}