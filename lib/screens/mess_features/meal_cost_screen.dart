import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealCostScreen extends StatefulWidget {
  final String messId;

  const MealCostScreen({super.key, required this.messId});

  @override
  _MealCostScreenState createState() => _MealCostScreenState();
}

class _MealCostScreenState extends State<MealCostScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _mealRecords = [];
  double _totalShoppingCost = 0.0;
  int _totalMeals = 0;
  double _mealRate = 0.0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final totalShoppingCost = await _firestoreService.getTotalShoppingCostForMonth(widget.messId, _selectedMonth);
      final totalMeals = await _firestoreService.getTotalMealsInMonth(widget.messId, _selectedMonth);
      final mealRate = totalMeals > 0 ? totalShoppingCost / totalMeals : 0.0;

      final mealRecordsSnapshot = await FirebaseFirestore.instance
          .collection('messes')
          .doc(widget.messId)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: DateTime(_selectedMonth.year, _selectedMonth.month, 1).toIso8601String().substring(0, 10))
          .where('date', isLessThanOrEqualTo: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).toIso8601String().substring(0, 10))
          .get();

      final mealRecords = mealRecordsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _mealRecords = mealRecords;
        _totalShoppingCost = totalShoppingCost;
        _totalMeals = totalMeals;
        _mealRate = mealRate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      await _initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Cost Overview'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meal Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Month: ${_selectedMonth.year}-${_selectedMonth.month}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectMonth(context),
                          child: const Text('Select Month'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Total Shopping Cost: BDT ${_totalShoppingCost.toStringAsFixed(2)}'),
                    Text('Total Meals: $_totalMeals'),
                    Text('Meal Rate: BDT ${_mealRate.toStringAsFixed(2)} per meal'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Meal Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _mealRecords.isEmpty
                ? const Text('No meal records found for this month.')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mealRecords.length,
              itemBuilder: (context, index) {
                final record = _mealRecords[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(record['user_name'] ?? 'Unknown User'),
                    subtitle: Text('Meals: ${record['meal_count']?.toString() ?? '0'}'),
                    trailing: Text(record['date']?.substring(0, 10) ?? 'N/A'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}