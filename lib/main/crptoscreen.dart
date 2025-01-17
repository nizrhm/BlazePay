import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoPricesScreen extends StatefulWidget {
  @override
  _CryptoPricesScreenState createState() => _CryptoPricesScreenState();
}

class _CryptoPricesScreenState extends State<CryptoPricesScreen> {
  List<dynamic> _cryptoCoins = [];

  @override
  void initState() {
    super.initState();
    _fetchCryptoPrices();
  }

  Future<void> _fetchCryptoPrices() async {
    try {
      final coins = await CoinGeckoApiClient.getCryptoCoins();
      setState(() {
        _cryptoCoins = coins;
      });
    } catch (e) {
      print('Error fetching crypto prices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crypto Prices',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF414B59),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF414B59),
              Color(0xFF121928),
              Color(0xFF101726),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _cryptoCoins.isNotEmpty
            ? ListView.builder(
                itemCount: _cryptoCoins.length,
                itemBuilder: (context, index) {
                  final coin = _cryptoCoins[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4.0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading:
                            Image.network(coin['image'], width: 32, height: 32),
                        title: Text(
                          coin['name'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '\$${coin['current_price'].toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class CoinGeckoApiClient {
  static Future<List<dynamic>> getCryptoCoins() async {
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch crypto coins');
    }
  }
}
