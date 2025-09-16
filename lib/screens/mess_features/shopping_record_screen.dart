// Modernized Shopping Record Screen with animated record list UI and date/month filter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'shopping_summary_screen.dart';

class ShoppingRecordScreen extends StatefulWidget {
  final String messId;

  const ShoppingRecordScreen({super.key, required this.messId});

  @override
  _ShoppingRecordScreenState createState() => _ShoppingRecordScreenState();
}

class _ShoppingRecordScreenState extends State<ShoppingRecordScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _shoppingRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _firestoreService.getShoppingRecords(widget.messId);
      setState(() {
        _shoppingRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addShoppingRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final item = _itemController.text;
    final amount = _amountController.text;

    await _animationController.forward();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm Submission'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.shopping_bag, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Item: $item")
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.attach_money, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Amount: BDT $amount")
                ]),
                const SizedBox(height: 20),
                const Text("Are you sure you want to add this shopping record?"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );

    await _animationController.reverse();

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userName = userDoc['name'] ?? 'Unknown';

      final recordData = {
        'item': item,
        'amount': double.parse(amount),
        'date': DateTime.now().toIso8601String(),
        'added_by': userName,
      };

      await _firestoreService.addShoppingRecord(widget.messId, recordData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shopping record added successfully!')));

      _itemController.clear();
      _amountController.clear();

      final records = await _firestoreService.getShoppingRecords(widget.messId);
      setState(() {
        _shoppingRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Track Shopping Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Filter by Date'),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    final formatted = DateFormat('yyyy-MM-dd').format(selectedDate);
                    setState(() {
                      _filteredRecords = _shoppingRecords.where(
                            (rec) => rec['date'].toString().startsWith(formatted),
                      ).toList();
                    });
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Filter by Month'),
                onTap: () async {
                  final selectedMonth = await showMonthPicker(
                    context: context,
                    initialDate: DateTime.now(),
                  );
                  if (selectedMonth != null) {
                    final prefix = DateFormat('yyyy-MM').format(selectedMonth);
                    setState(() {
                      _filteredRecords = _shoppingRecords.where(
                            (rec) => rec['date'].toString().startsWith(prefix),
                      ).toList();
                    });
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Filters'),
                onTap: () {
                  setState(() => _filteredRecords = _shoppingRecords);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCard(Map<String, dynamic> record, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, double opacity, child) => Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, (1 - opacity) * 20),
          child: child,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: ListTile(
          leading: const Icon(Icons.shopping_cart, color: Colors.teal),
          title: Text(record['item'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("Amount: BDT ${record['amount']?.toStringAsFixed(2) ?? '0.0'}"),
              Text("Added by: ${record['added_by'] ?? 'Unknown'}"),
            ],
          ),
          trailing: Text(record['date']?.substring(0, 10) ?? 'N/A'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Records'),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            tooltip: 'Track Shopping Record',
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Summary',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingSummaryScreen(
                    messId: widget.messId,
                    shoppingRecords: _shoppingRecords,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Shopping Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _itemController,
                        decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: const InputDecoration(labelText: 'Amount (BDT)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _addShoppingRecord,
                          label: const Text('Add Record', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shopping Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.track_changes, size: 18),
                  label: const Text('Track Shopping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _showFilterOptions,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _filteredRecords.isEmpty
                ? const Text('No shopping records found.')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) => _buildAnimatedCard(_filteredRecords[index], index),
            ),
          ],
        ),
      ),
    );
  }
}
