import 'package:flutter/material.dart';

class MealSection extends StatelessWidget {
  final String meal;

  const MealSection({Key? key, required this.meal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        title: Text("Today's Meal", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        subtitle: Text(meal, style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[700])),
      ),
    );
  }
}
