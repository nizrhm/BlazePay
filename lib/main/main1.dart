import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solana_pay/main/balance.dart';
import 'package:solana_pay/main/crptoscreen.dart';
import 'package:solana_pay/main/cryptoexchnage.dart';
import 'package:solana_pay/main/paytocontact.dart';
import 'package:solana_pay/main/peoples.dart';
import 'package:solana_pay/main/profile.dart';
import 'package:solana_pay/main/qrscreen.dart';
import 'package:solana_pay/main/transactionhistory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> uniqueRecipients = [];
  bool _isExpanded = false;
  List<Map<String, dynamic>> searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final userPhone = await _getCurrentUserPhone();

      if (userPhone != null) {
        final response = await supabase
            .from('history')
            .select('transactions')
            .eq('phon_number', userPhone)
            .single();
        print('Response: $response');

        if (response != null) {
          if (response['transactions'] is List) {
            Set<String> uniqueAddresses = Set<String>();
            List<Map<String, dynamic>> allTransactions = [];

            for (var transaction in response['transactions']) {
              if (transaction is String &&
                  !uniqueAddresses.contains(transaction)) {
                uniqueAddresses.add(transaction);
                allTransactions.add({
                  'address': transaction,
                  'amount': 'N/A',
                });
              }
            }

            setState(() {
              uniqueRecipients = allTransactions;
            });
          } else if (response['transactions'] is String) {
            print(
                'Unexpected format for transactions: ${response['transactions']}');
          } else {
            print(
                'Unexpected type for transactions: ${response['transactions'].runtimeType}');
          }
        }
      }
    } catch (e) {
      print('Error fetching transaction history: $e');
    }
  }

  Future<String?> _getCurrentUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number');

      if (phoneNumber == null) {
        throw Exception('Phone number not found in SharedPreferences');
      }

      return phoneNumber;
    } catch (e) {
      print('Error fetching current user phone: $e');
    }
    return null;
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final response = await supabase
          .from('profile')
          .select('phone_number, wallet_address')
          .ilike('phone_number', '%$query%');

      if (response != null) {
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error searching for contacts: $e');
    }
  }

  void _openPayToContactScreen(String walletAddress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayToContactScreen(
          initialRecipientAddress: walletAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF414B59),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20),
        ),
        actions: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Container(
                    alignment: Alignment.center,
                    height: 50,
                    margin: const EdgeInsets.only(left: 20, right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Pay to contact',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 5),
                          child: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  _searchController.text.isNotEmpty && searchResults.isNotEmpty
                      ? _buildSearchResults()
                      : _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final contact = searchResults[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          )),
          child: ListTile(
            title: Text(
              contact['phone_number'],
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              contact['wallet_address'],
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => _openPayToContactScreen(contact['wallet_address']),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                buildIcon(context, Icons.qr_code_scanner, "Scan and Pay"),
                buildIcon(context, Icons.contact_page, "Pay To Address"),
                buildIcon(context, Icons.account_balance, "Balance"),
                buildIcon(context, Icons.money, "Crpto Prices"),
                buildIcon(context, Icons.receipt_long, "History"),
                buildIcon(context, Icons.phone_iphone, "Crypto Exchange"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peoples',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _scaleController,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (_isExpanded) {
                      _scaleController.forward();
                    } else {
                      _scaleController.reverse();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded
                ? _buildExpandedPeopleGrid()
                : _buildCollapsedPeopleGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPeopleGrid() {
    return GridView.builder(
      key: ValueKey<bool>(true),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: uniqueRecipients.length,
      itemBuilder: (context, index) => _buildRecipientAvatar(index),
    );
  }

  Widget _buildCollapsedPeopleGrid() {
    return GridView.builder(
      key: ValueKey<bool>(false),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: min(8, uniqueRecipients.length),
      itemBuilder: (context, index) => _buildRecipientAvatar(index),
    );
  }

  Widget _buildRecipientAvatar(int index) {
    final recipient = uniqueRecipients[index];
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _scaleController,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                address: recipient['address'],
                amount: recipient['amount'],
              ),
            ),
          );
        },
        child: Hero(
          tag: 'recipient_${recipient['address']}',
          child: CircleAvatar(
            backgroundColor:
                Colors.primaries[Random().nextInt(Colors.primaries.length)],
            radius: 24,
            child: Text(
              recipient['address'][0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildIcon(BuildContext context, IconData iconData, String text) {
    return GestureDetector(
      onTap: () {
        _handleIconTap(context, text);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: Colors.white.withOpacity(0.9),
              size: 32,
            ),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            )
          ],
        ),
      ),
    );
  }

  void _handleIconTap(BuildContext context, String text) {
    Widget? screen;
    switch (text) {
      case "Pay To Address":
        screen = const PayToContactScreen();
        break;
      case "Balance":
        screen = const BalanceDisplayScreen();
        break;
      case "Scan and Pay":
        screen = QRScannerScreen();
        break;
      case "History":
        screen = TransactionHistoryScreen();
        break;
      case "Crpto Prices":
        screen = CryptoPricesScreen(); 
        break;
      // case "Crypto Exchange":
      //   screen = CryptoExchangeScreen();
      //   break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.ease;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
