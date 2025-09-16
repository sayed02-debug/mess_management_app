import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuickOptionsScreen extends StatefulWidget {
  final String messId;

  const QuickOptionsScreen({super.key, required this.messId});

  @override
  _QuickOptionsScreenState createState() => _QuickOptionsScreenState();
}

class _QuickOptionsScreenState extends State<QuickOptionsScreen> {
  int breakfastCount = 0;
  int lunchCount = 0;
  int dinnerCount = 0;
  DateTime selectedDate = DateTime.now(); // Added for date selection
  List<DateTime> selectedDates = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  int get totalMeals => breakfastCount + lunchCount + dinnerCount;

  @override
  void initState() {
    super.initState();
    _loadMealData();
  }

  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      String userId = user.uid;
      String formattedDate = selectedDate.toIso8601String().substring(0, 10);

      QuerySnapshot snapshot = await _firestore
          .collection('meal_preferences')
          .where('userId', isEqualTo: userId)
          .where('messId', isEqualTo: widget.messId)
          .where('date', isEqualTo: formattedDate)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          breakfastCount = data['breakfast'] ?? 0;
          lunchCount = data['lunch'] ?? 0;
          dinnerCount = data['dinner'] ?? 0;
        });
      } else {
        setState(() {
          breakfastCount = 0;
          lunchCount = 0;
          dinnerCount = 0;
        });
      }

      // Load leave dates
      QuerySnapshot leaveSnapshot = await _firestore
          .collection('meal_preferences')
          .where('userId', isEqualTo: userId)
          .where('messId', isEqualTo: widget.messId)
          .where('isLeave', isEqualTo: true)
          .get();

      List<DateTime> leaveDates = [];
      for (var doc in leaveSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['leaveDate'] != null) {
          leaveDates.add(DateTime.parse(data['leaveDate']));
        }
      }

      setState(() {
        selectedDates = leaveDates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading meal data: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
  }

  void _incrementMeal(String meal) {
    setState(() {
      if (meal == 'breakfast') breakfastCount++;
      else if (meal == 'lunch') lunchCount++;
      else if (meal == 'dinner') dinnerCount++;
    });
  }

  void _decrementMeal(String meal) {
    setState(() {
      if (meal == 'breakfast' && breakfastCount > 0) breakfastCount--;
      else if (meal == 'lunch' && lunchCount > 0) lunchCount--;
      else if (meal == 'dinner' && dinnerCount > 0) dinnerCount--;
    });
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00695C),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _loadMealData(); // Reload data for the newly selected date
    }
  }

  void _selectFutureLeaveMeals() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00695C),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && !selectedDates.any((date) =>
    date.day == pickedDate.day &&
        date.month == pickedDate.month &&
        date.year == pickedDate.year)) {
      setState(() {
        selectedDates.add(pickedDate);
      });
    }
  }

  Future<void> _submitMealChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      String userId = user.uid;
      String formattedDate = selectedDate.toIso8601String().substring(0, 10);

      // Save meal preferences for the selected date
      QuerySnapshot existingMeal = await _firestore
          .collection('meal_preferences')
          .where('userId', isEqualTo: userId)
          .where('messId', isEqualTo: widget.messId)
          .where('date', isEqualTo: formattedDate)
          .limit(1)
          .get();

      if (existingMeal.docs.isNotEmpty) {
        await existingMeal.docs.first.reference.update({
          'breakfast': breakfastCount,
          'lunch': lunchCount,
          'dinner': dinnerCount,
          'totalMeals': totalMeals,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('meal_preferences').add({
          'userId': userId,
          'messId': widget.messId,
          'date': formattedDate,
          'breakfast': breakfastCount,
          'lunch': lunchCount,
          'dinner': dinnerCount,
          'totalMeals': totalMeals,
          'isLeave': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Save leave dates
      for (DateTime date in selectedDates) {
        String formattedLeaveDate = date.toIso8601String().substring(0, 10);
        QuerySnapshot existingLeave = await _firestore
            .collection('meal_preferences')
            .where('userId', isEqualTo: userId)
            .where('messId', isEqualTo: widget.messId)
            .where('leaveDate', isEqualTo: formattedLeaveDate)
            .limit(1)
            .get();

        if (existingLeave.docs.isEmpty) {
          await _firestore.collection('meal_preferences').add({
            'userId': userId,
            'messId': widget.messId,
            'leaveDate': formattedLeaveDate,
            'breakfast': 0,
            'lunch': 0,
            'dinner': 0,
            'totalMeals': 0,
            'isLeave': true,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to User Profile after saving
      Navigator.pushNamed(
        context,
        '/userProfile',
        arguments: {'userId': userId, 'messId': widget.messId},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        title: Text(
          'Meal Planner',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF00695C),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF004D40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildMealCard('Breakfast', breakfastCount, Icons.breakfast_dining),
            SizedBox(height: 12),
            _buildMealCard('Lunch', lunchCount, Icons.lunch_dining),
            SizedBox(height: 12),
            _buildMealCard('Dinner', dinnerCount, Icons.dinner_dining),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Meals (${DateFormat('dd-MM-yyyy').format(selectedDate)})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$totalMeals',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectFutureLeaveMeals,
              icon: Icon(Icons.calendar_today, size: 18, color: Colors.white),
              label: Text(
                'Add Leave Dates',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                backgroundColor: Color(0xFF00897B),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedDates.map((date) => Chip(
                label: Text(
                  DateFormat('MMM d').format(date),
                  style: TextStyle(fontSize: 12, color: Color(0xFF00695C)),
                ),
                backgroundColor: Color(0xFFE0F2F1),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              )).toList(),
            ),
            SizedBox(height: 28),
            ElevatedButton(
              onPressed: _submitMealChanges,
              child: Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(0xFF00695C),
                minimumSize: Size(double.infinity, 0),
                shadowColor: Color(0xFF00695C).withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String meal, int count, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF00695C), size: 26),
              SizedBox(width: 14),
              Text(
                meal,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _decrementMeal(meal.toLowerCase()),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: Icon(Icons.remove, color: Colors.grey[600], size: 18),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _incrementMeal(meal.toLowerCase()),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00695C),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}