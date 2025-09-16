import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String messId;

  const UserProfileScreen({super.key, required this.userId, required this.messId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userName = "User";
  String userEmail = "user@example.com";
  String? profileImageUrl;
  int totalMeals = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> allMealData = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAllMealData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = userData['name'] ?? "User";
          userEmail = userData['email'] ?? "user@example.com";
          profileImageUrl = userData['profile_image'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<void> _fetchAllMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('meal_preferences')
          .where('userId', isEqualTo: widget.userId)
          .where('messId', isEqualTo: widget.messId)
          .where('isLeave', isEqualTo: false)
          .get();

      allMealData = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'] ?? '',
          'breakfast': data['breakfast'] ?? 0,
          'lunch': data['lunch'] ?? 0,
          'dinner': data['dinner'] ?? 0,
          'totalMeals': data['totalMeals'] ?? 0,
        };
      }).toList();

      int total = allMealData.fold(0, (sum, item) => sum + (item['totalMeals'] as int));
      setState(() {
        totalMeals = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meal data: $e')),
      );
    }
  }

  void _showMealDetailsSheet() {
    String selectedMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
    List<Map<String, dynamic>> filteredMeals = [];
    int totalMealsInMonth = 0;

    final List<String> monthYearOptions = [
      '2025-01', '2025-02', '2025-03', '2025-04', '2025-05', '2025-06',
      '2025-07', '2025-08', '2025-09', '2025-10', '2025-11', '2025-12',
    ];

    void filterMeals() {
      filteredMeals = allMealData.where((meal) {
        try {
          DateTime mealDate = DateTime.parse(meal['date'].split('T')[0]);
          String mealMonthYear = DateFormat('yyyy-MM').format(mealDate);
          return mealMonthYear == selectedMonthYear;
        } catch (e) {
          print('Error parsing date ${meal['date']}: $e');
          return false;
        }
      }).toList();

      totalMealsInMonth = filteredMeals.fold(0, (sum, meal) => sum + (meal['totalMeals'] as int));
    }

    filterMeals();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with Dropdown
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF00695C),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Meal Details - ${DateFormat('MMMM yyyy').format(DateTime.parse('$selectedMonthYear-01'))}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            DropdownButton<String>(
                              value: selectedMonthYear,
                              dropdownColor: Color(0xFF00695C),
                              style: TextStyle(color: Colors.white),
                              iconEnabledColor: Colors.white,
                              items: monthYearOptions.map((String monthYear) {
                                return DropdownMenuItem<String>(
                                  value: monthYear,
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(DateTime.parse('$monthYear-01')),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setModalState(() {
                                    selectedMonthYear = newValue;
                                  });
                                  filterMeals();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Meal Details Content
                      Expanded(
                        child: filteredMeals.isEmpty
                            ? Center(
                          child: Text(
                            'No meal data for this month.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: filteredMeals.length,
                          itemBuilder: (context, index) {
                            var meal = filteredMeals[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.grey[50],
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  DateFormat('dd-MM-yyyy')
                                      .format(DateTime.parse(meal['date'])),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                      'Breakfast: ${meal['breakfast']}',
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      'Lunch: ${meal['lunch']}',
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      'Dinner: ${meal['dinner']}',
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Total Meals on this day: ${meal['totalMeals']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Total Meals
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[100],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Meals in this month:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '$totalMealsInMonth',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$userName\'s Profile',
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Icon(Icons.person, size: 45, color: Colors.grey[600])
                        : null,
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Total Meals Section
            GestureDetector(
              onTap: _showMealDetailsSheet,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Meals Consumed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$totalMeals',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00695C),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}