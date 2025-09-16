import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Create a new mess
  Future<String> createMess({
    required String name,
    required String address,
  }) async {
    try {
      String userId = getCurrentUserId()!;
      DocumentReference messRef = await _firestore.collection('messes').add({
        'name': name,
        'address': address,
        'admin_id': userId,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Add the creator as an admin member
      await messRef.collection('members').doc(userId).set({
        'role': 'admin',
        'joined_at': FieldValue.serverTimestamp(),
      });

      // Update the user's mess_id
      await _firestore.collection('users').doc(userId).set({
        'mess_id': messRef.id,
        'role': 'admin',
      }, SetOptions(merge: true));

      return messRef.id;
    } catch (e) {
      throw Exception('Error creating mess: $e');
    }
  }

  // Fetch all messes (for mess list)
  Future<List<Map<String, dynamic>>> getAllMesses() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('messes').get();
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching messes: $e');
    }
  }

  // Send a join request
  Future<void> sendJoinRequest(String messId) async {
    try {
      String userId = getCurrentUserId()!;
      await _firestore.collection('join_requests').add({
        'user_id': userId,
        'mess_id': messId,
        'status': 'pending',
        'requested_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending join request: $e');
    }
  }

  // Fetch shopping records for a specific mess
  Future<List<Map<String, dynamic>>> getShoppingRecords(String messId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('shopping_records')
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching shopping records: $e');
    }
  }

  // Fetch meal costs for a specific mess
  Future<List<Map<String, dynamic>>> getMealCosts(String messId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meal_costs')
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching meal costs: $e');
    }
  }

  // Meal join function (Mess-specific)
  Future<void> joinMeal(String messId, String mealType, DateTime date) async {
    try {
      String userId = getCurrentUserId()!;
      String formattedDate = "${date.year}-${date.month}-${date.day}";

      DocumentSnapshot userMealDoc = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(userId)
          .collection('dates')
          .doc(formattedDate)
          .get();

      Map<String, dynamic> mealData = userMealDoc.exists
          ? (userMealDoc.data() as Map<String, dynamic>)
          : {'breakfast': false, 'lunch': false, 'dinner': false, 'total': 0};

      mealData[mealType] = true;
      mealData['total'] = (mealData['breakfast'] ? 1 : 0) +
          (mealData['lunch'] ? 1 : 0) +
          (mealData['dinner'] ? 1 : 0);

      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(userId)
          .collection('dates')
          .doc(formattedDate)
          .set(mealData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error joining meal: $e');
    }
  }

  // Meal leave function (Mess-specific)
  Future<void> leaveMeal(String messId, String mealType, DateTime date) async {
    try {
      String userId = getCurrentUserId()!;
      String formattedDate = "${date.year}-${date.month}-${date.day}";

      DocumentSnapshot userMealDoc = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(userId)
          .collection('dates')
          .doc(formattedDate)
          .get();

      Map<String, dynamic> mealData = userMealDoc.exists
          ? (userMealDoc.data() as Map<String, dynamic>)
          : {'breakfast': false, 'lunch': false, 'dinner': false, 'total': 0};

      mealData[mealType] = false;
      mealData['total'] = (mealData['breakfast'] ? 1 : 0) +
          (mealData['lunch'] ? 1 : 0) +
          (mealData['dinner'] ? 1 : 0);

      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(userId)
          .collection('dates')
          .doc(formattedDate)
          .set(mealData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error leaving meal: $e');
    }
  }

  // Fetch user's meal data (Mess-specific)
  Future<List<Map<String, dynamic>>> getUserMeals(String messId) async {
    try {
      String userId = getCurrentUserId()!;
      QuerySnapshot snapshot = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(userId)
          .collection('dates')
          .get();
      return snapshot.docs.map((doc) {
        return {
          'date': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching user meals: $e');
    }
  }

  // Add a shopping record
  Future<void> addShoppingRecord(String messId, Map<String, dynamic> record) async {
    try {
      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('shopping_records')
          .add({
        ...record,
        'added_by': getCurrentUserId(),
        'added_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding shopping record: $e');
    }
  }

  // Add a meal cost record
  Future<void> addMealCost(String messId, Map<String, dynamic> cost) async {
    try {
      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('meal_costs')
          .add({
        ...cost,
        'added_by': getCurrentUserId(),
        'added_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding meal cost: $e');
    }
  }
}