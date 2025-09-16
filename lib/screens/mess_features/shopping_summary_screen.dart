// shopping_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ShoppingSummaryScreen extends StatefulWidget {
  final String messId;
  final List<Map<String, dynamic>> shoppingRecords;

  const ShoppingSummaryScreen({
    super.key,
    required this.messId,
    required this.shoppingRecords,
  });

  @override
  State<ShoppingSummaryScreen> createState() => _ShoppingSummaryScreenState();
}

class _ShoppingSummaryScreenState extends State<ShoppingSummaryScreen> {
  late List<Map<String, dynamic>> _records;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _records = widget.shoppingRecords;
    _isLoading = false;
  }

  Map<String, double> _calculateMonthlyTotals() {
    Map<String, double> totals = {};
    for (var record in _records) {
      String month = DateFormat('yyyy-MM').format(DateTime.parse(record['date']));
      totals[month] = (totals[month] ?? 0) + (record['amount'] ?? 0);
    }
    return totals;
  }

  Future<void> _exportCSV() async {
    List<List<dynamic>> rows = [
      ['Item', 'Amount', 'Date', 'Added By']
    ];
    for (var rec in _records) {
      rows.add([
        rec['item'],
        rec['amount'],
        rec['date'],
        rec['added_by'] ?? 'Unknown'
      ]);
    }
    String csvData = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/shopping_records.csv");
    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CSV exported to ${file.path}")));
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Shopping Records", style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Item', 'Amount', 'Date', 'Added By'],
                data: _records.map((e) => [e['item'], e['amount'], e['date'], e['added_by'] ?? 'Unknown']).toList(),
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _calculateMonthlyTotals();
    final months = monthlyTotals.keys.toList();
    final values = monthlyTotals.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Summary'),
        backgroundColor: Colors.teal.shade100,
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _exportPDF),
          IconButton(icon: Icon(Icons.table_chart), onPressed: _exportCSV),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Monthly Total Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()].substring(5));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    months.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(toY: values[index], color: Colors.teal, width: 18)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
