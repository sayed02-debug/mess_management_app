import 'package:flutter/material.dart';

class ShoppingListSection extends StatelessWidget {
  final List<Map<String, dynamic>> shoppingList;

  const ShoppingListSection({Key? key, required this.shoppingList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: shoppingList.map((item) => _buildNeumorphicCard(item['date']!, item['member']!)).toList(),
    );
  }

  Widget _buildNeumorphicCard(String title, String subtitle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[700])),
      ),
    );
  }
}
