import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to update meal counts in the "meal_preferences" collection and store totalMeals
  Future<void> updateMealCounts(String mealType) async {
    String uid = _auth.currentUser!.uid;
    String todayDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD format

    // Reference to the meal document for today
    DocumentReference mealRef = _firestore
        .collection('meal_preferences')
        .doc('$uid-$todayDate'); // Unique document for each user and date

    DocumentSnapshot mealDoc = await mealRef.get();

    if (mealDoc.exists) {
      // If meal entry exists for today, update it
      Map<String, dynamic> mealData = mealDoc.data() as Map<String, dynamic>;

      int breakfastCount = (mealData['breakfast'] as num? ?? 0).toInt();
      int lunchCount = (mealData['lunch'] as num? ?? 0).toInt();
      int dinnerCount = (mealData['dinner'] as num? ?? 0).toInt();

      // Update the appropriate meal count based on the meal type
      if (mealType == 'breakfast') {
        breakfastCount++;
      } else if (mealType == 'lunch') {
        lunchCount++;
      } else if (mealType == 'dinner') {
        dinnerCount++;
      }

      // Calculate total meals
      int totalMeals = breakfastCount + lunchCount + dinnerCount;

      // Update Firestore with the new counts
      await mealRef.update({
        'breakfast': breakfastCount,
        'lunch': lunchCount,
        'dinner': dinnerCount,
        'totalMeals': totalMeals, // Store totalMeals in Firestore
      });

      print('Meal count updated successfully for today');
    } else {
      // If no meal entry for today, create a new one
      await mealRef.set({
        'userId': uid,
        'date': todayDate,
        'breakfast': mealType == 'breakfast' ? 1 : 0,
        'lunch': mealType == 'lunch' ? 1 : 0,
        'dinner': mealType == 'dinner' ? 1 : 0,
        'totalMeals': 1, // Start with 1 meal
      });

      print('New meal record created for today');
    }

    // Optionally, update total meals for the user in another collection (like users)
    await _updateUserTotalMeals(uid);
  }

  // Function to update total meals count in the "users" collection
  Future<void> _updateUserTotalMeals(String uid) async {
    QuerySnapshot userMealsSnapshot = await _firestore
        .collection('meal_preferences')
        .where('userId', isEqualTo: uid)
        .get();

    int totalMeals = 0;
    for (var doc in userMealsSnapshot.docs) {
      var mealData = doc.data() as Map<String, dynamic>;
      totalMeals += (mealData['totalMeals'] as num? ?? 0).toInt();
    }

    // Store the total meals count inside the "users" collection
    await _firestore.collection('users').doc(uid).update({
      'totalMeals': totalMeals,
    });

    print('User total meals updated: $totalMeals');
  }

  // Function to fetch total meals for the current user (for profile screen)
  Stream<int> getUserTotalMeals() {
    String uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      return (snapshot.data()?['totalMeals'] as num? ?? 0).toInt();
    });
  }

  // Function to fetch total meals of all users (for admin screen)
  Stream<List<Map<String, dynamic>>> getAllUsersTotalMeals() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'userId': doc.id,
          'totalMeals': (doc.data()['totalMeals'] as num? ?? 0).toInt(),
        };
      }).toList();
    });
  }
}
