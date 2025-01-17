import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactionHistory = [];
  bool isLoading = true;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTransactionHistory();
  }

  Future<void> fetchTransactionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number');

      if (phoneNumber == null) {
        throw Exception('Phone number not found in SharedPreferences');
      }

      final response = await supabase
          .from('history')
          .select('transactions, amounts')
          .eq('phon_number', phoneNumber)
          .single();

      if (response != null) {
        List<String> transactions = List<String>.from(response['transactions']);
        List<String> amounts = List<String>.from(response['amounts']);

        double total = 0.0;
        List<Map<String, dynamic>> history = List.generate(
          transactions.length,
          (index) {
            double amount = double.tryParse(amounts[index]) ?? 0.0;
            total += amount;
            return {
              'address': transactions[index],
              'amounts': amounts[index],
            };
          },
        );

        setState(() {
          transactionHistory = history;
          totalAmount = total;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transaction history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF414B59),
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Text(
          "History",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF414B59),
              Color(0xFF121928),
              Color(0xFF101726),
            ],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : transactionHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No transaction history found',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: transactionHistory.length,
                    itemBuilder: (context, index) {
                      final transaction = transactionHistory[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To: ${transaction['address']}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Amount: ${transaction['amounts']} SOL',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
