// mess_stats.dart with modern UI design across sections
import 'package:flutter/material.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MessStatsScreen extends StatefulWidget {
  final String messId;

  const MessStatsScreen({super.key, required this.messId});

  @override
  _MessStatsScreenState createState() => _MessStatsScreenState();
}

class _MessStatsScreenState extends State<MessStatsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _shoppingRecords = [];
  List<Map<String, dynamic>> _meals = [];
  double _totalShoppingCost = 0.0;
  int _totalMeals = 0;
  double _mealRate = 0.0;
  Map<String, int> _memberMealCounts = {};
  Map<String, double> _memberCosts = {};
  bool _isLoading = true;
  bool _showMembers = true;
  bool _showStats = false;
  bool _showCosts = false;

  @override
  void initState() {
    super.initState();
    _fetchMessData();
  }

  Future<void> _fetchMessData() async {
    setState(() => _isLoading = true);
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('mess_id', isEqualTo: widget.messId)
          .get();

      final members = userSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'user_id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'role': data['role'] ?? 'Member',
        };
      }).toList();

      final shoppingRecords = await _firestoreService.getShoppingRecords(widget.messId);
      final totalShoppingCost = shoppingRecords.fold(0.0, (sum, r) => sum + (r['amount']?.toDouble() ?? 0.0));
      final meals = await _firestoreService.getMealRecords(widget.messId);
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      Map<String, int> memberMealCounts = {};
      int totalMeals = 0;
      for (var member in members) {
        final snapshot = await _firestore
            .collection('meal_preferences')
            .where('userId', isEqualTo: member['user_id'])
            .where('messId', isEqualTo: widget.messId)
            .where('isLeave', isEqualTo: false)
            .get();

        final mealsData = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        final count = mealsData.where((m) {
          try {
            final date = DateTime.parse(m['date'].split('T')[0]);
            return DateFormat('yyyy-MM').format(date) == currentMonth;
          } catch (_) {
            return false;
          }
        }).fold<int>(0, (sum, m) => sum + ((m['totalMeals'] ?? 0) as int));

        memberMealCounts[member['name']] = count;
        totalMeals += count;
      }

      final mealRate = totalMeals > 0 ? totalShoppingCost / totalMeals : 0.0;
      final memberCosts = {
        for (var entry in memberMealCounts.entries) entry.key: entry.value * mealRate
      };

      setState(() {
        _members = members;
        _shoppingRecords = shoppingRecords;
        _meals = meals;
        _totalShoppingCost = totalShoppingCost;
        _totalMeals = totalMeals;
        _mealRate = mealRate;
        _memberMealCounts = memberMealCounts;
        _memberCosts = memberCosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching stats: $e')));
    }
  }

  Widget _sectionCard(String title, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      color: Colors.white,
      margin: EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool selected, VoidCallback onPressed) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? Colors.teal.shade700 : Colors.grey.shade200,
            boxShadow: selected ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: Center(
            child: Text(label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Mess Statistics", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildToggleButton("Members", _showMembers, () {
                  setState(() => {_showMembers = true, _showStats = false, _showCosts = false});
                }),
                _buildToggleButton("Statistics", _showStats, () {
                  setState(() => {_showMembers = false, _showStats = true, _showCosts = false});
                }),
                _buildToggleButton("Per-Member Cost", _showCosts, () {
                  setState(() => {_showMembers = false, _showStats = false, _showCosts = true});
                }),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_showMembers)
                  _sectionCard(
                    "Members",
                    Column(
                      children: _members
                          .map((m) => ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                        leading: Icon(Icons.person_outline_rounded, color: Colors.teal),
                        title: Text(m['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        subtitle: Text('Role: ${m['role']}', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      ))
                          .toList(),
                    ),
                  ),
                if (_showStats)
                  _sectionCard(
                    "Statistics",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Shopping Cost: BDT ${_totalShoppingCost.toStringAsFixed(2)}', style: GoogleFonts.poppins()),
                        Text('Total Meals: $_totalMeals', style: GoogleFonts.poppins()),
                        Text('Meal Rate: BDT ${_mealRate.toStringAsFixed(2)} per meal', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                if (_showCosts)
                  _sectionCard(
                    "Per-Member Cost",
                    Column(
                      children: _memberCosts.entries
                          .map((e) => ListTile(
                        leading: Icon(Icons.attach_money, color: Colors.teal),
                        title: Text(e.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        subtitle: Text('Meals: ${_memberMealCounts[e.key]}', style: GoogleFonts.poppins()),
                        trailing: Text('BDT ${e.value.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
