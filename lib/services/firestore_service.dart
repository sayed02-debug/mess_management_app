import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user data by userId
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data() ?? {};
    data['id'] = userDoc.id;
    return data;
  }

  // Get all messes
  Future<List<Map<String, dynamic>>> getAllMesses() async {
    final querySnapshot = await _db.collection('messes').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Check if user is a member of a mess
  Future<bool> isUserMemberOfMess(String messId, String userId) async {
    final doc = await _db
        .collection('messes')
        .doc(messId)
        .collection('members')
        .doc(userId)
        .get();
    return doc.exists;
  }

  // Check if user has already joined a mess or created a mess
  Future<Map<String, dynamic>> checkUserMessStatus(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data() ?? {};
    return {
      'mess_id': data['mess_id'],
      'created_mess_id': data['created_mess_id'],
    };
  }

  // Create a new mess
  Future<void> createMess(Map<String, dynamic> messData, String userId) async {
    final userStatus = await checkUserMessStatus(userId);
    if (userStatus['created_mess_id'] != null || userStatus['mess_id'] != null) {
      throw Exception('You can only create or join one mess.');
    }

    final messRef = _db.collection('messes').doc();
    messData['id'] = messRef.id;
    messData['admin_id'] = userId;

    await messRef.set(messData);
    await messRef.collection('members').doc(userId).set({
      'name': messData['creator_name'] ?? 'Unknown',
    });

    await _db.collection('users').doc(userId).update({
      'created_mess_id': messRef.id,
      'mess_id': messRef.id,
    });
  }

  // Send join request
  Future<void> sendJoinRequest(String messId, String userId) async {
    final userStatus = await checkUserMessStatus(userId);
    if (userStatus['created_mess_id'] != null || userStatus['mess_id'] != null) {
      throw Exception('You can only create or join one mess.');
    }

    final userDoc = await _db.collection('users').doc(userId).get();
    final userName = userDoc['name'] ?? 'Unknown';
    await _db
        .collection('messes')
        .doc(messId)
        .collection('join_requests')
        .doc(userId)
        .set({
      'name': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get join requests for a mess
  Future<List<Map<String, dynamic>>> getJoinRequests(String messId) async {
    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('join_requests')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['user_id'] = doc.id;
      return data;
    }).toList();
  }

  // Approve join request
  Future<void> approveJoinRequest(String messId, String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final userName = userDoc['name'] ?? 'Unknown';

    await _db
        .collection('messes')
        .doc(messId)
        .collection('members')
        .doc(userId)
        .set({
      'name': userName,
    });

    await _db.collection('users').doc(userId).update({
      'mess_id': messId,
    });

    await _db
        .collection('messes')
        .doc(messId)
        .collection('join_requests')
        .doc(userId)
        .delete();
  }

  // Reject join request
  Future<void> rejectJoinRequest(String messId, String userId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('join_requests')
        .doc(userId)
        .delete();
  }

  // Get mess members
  Future<List<Map<String, dynamic>>> getMessMembers(String messId) async {
    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('members')
        .get();
    final members = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['user_id'] = doc.id;
      return data;
    }).toList();

    // Add role for admin
    final messDoc = await _db.collection('messes').doc(messId).get();
    final adminId = messDoc['admin_id'];

    for (var member in members) {
      if (member['user_id'] == adminId) {
        member['role'] = 'Admin';
      } else {
        member['role'] = 'Member';
      }
    }

    return members;
  }

  // Get shopping records for a mess
  Future<List<Map<String, dynamic>>> getShoppingRecords(String messId) async {
    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('shopping_records')
        .orderBy('date', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Add a shopping record
  Future<void> addShoppingRecord(String messId, Map<String, dynamic> recordData) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('shopping_records')
        .add(recordData);
  }

  // Get meal records for a mess
  Future<List<Map<String, dynamic>>> getMealRecords(String messId) async {
    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('meals')
        .orderBy('date', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Get total shopping cost for a specific month
  Future<double> getTotalShoppingCostForMonth(String messId, DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1).toIso8601String().substring(0, 10);
    final endOfMonth = DateTime(date.year, date.month + 1, 0).toIso8601String().substring(0, 10);

    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('shopping_records')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    double totalCost = 0.0;
    for (var doc in querySnapshot.docs) {
      totalCost += (doc['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return totalCost;
  }

  // Get total meals in a specific month
  Future<int> getTotalMealsInMonth(String messId, DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1).toIso8601String().substring(0, 10);
    final endOfMonth = DateTime(date.year, date.month + 1, 0).toIso8601String().substring(0, 10);

    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    int totalMeals = 0;
    for (var doc in querySnapshot.docs) {
      totalMeals += (doc['meal_count'] as num?)?.toInt() ?? 0;
    }
    return totalMeals;
  }

  // Get total meals for a specific user in a specific month
  Future<int> getTotalMealsForUserInMonth(String messId, String userId, DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1).toIso8601String().substring(0, 10);
    final endOfMonth = DateTime(date.year, date.month + 1, 0).toIso8601String().substring(0, 10);

    final querySnapshot = await _db
        .collection('messes')
        .doc(messId)
        .collection('meals')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    int totalMeals = 0;
    for (var doc in querySnapshot.docs) {
      totalMeals += (doc['meal_count'] as num?)?.toInt() ?? 0;
    }
    return totalMeals;
  }
}