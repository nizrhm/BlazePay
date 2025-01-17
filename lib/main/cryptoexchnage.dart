// import 'package:flutter/material.dart';
// import 'package:solana/dto.dart';
// import 'package:solana/solana.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class CryptoExchangeScreen extends StatefulWidget {
//   @override
//   _CryptoExchangeScreenState createState() => _CryptoExchangeScreenState();
// }

// class _CryptoExchangeScreenState extends State<CryptoExchangeScreen> {
//   final SolanaClient _solanaClient = SolanaClient(
//     rpcUrl: Uri.parse('https://api.devnet.solana.com'),
//     websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
//   );

//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _recipientController = TextEditingController();
//   double _currentSolanaPrice = 0.0;
//   double _userSolanaBalance = 0.0;
//   String _selectedCrypto = 'BTC';

//   @override
//   void initState() {
//     super.initState();
//     _fetchSolanaBalance();
//     _fetchCryptoExchangeRate();
//   }

//   Future<void> _fetchSolanaBalance() async {
//     final walletAddress = await _getSavedWalletAddress();
//     final balance = await _solanaClient.rpcClient
//         .getBalance(Ed25519HDPublicKey.fromBase58(walletAddress));
//     setState(() {
//       _userSolanaBalance = balance.value / 1e9;
//     });
//   }

//   Future<void> _fetchCryptoExchangeRate() async {
//     final url = Uri.parse(
//         'https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=btc,eth');
//     final response = await http.get(url);
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         _currentSolanaPrice = _selectedCrypto == 'BTC'
//             ? data['solana']['btc']
//             : data['solana']['eth'];
//       });
//     } else {
//       print('Failed to fetch crypto exchange rate: ${response.statusCode}');
//     }
//   }

//   Future<String> _getSavedWalletAddress() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getString('wallet_address') ?? '';
//     } catch (e) {
//       print(e);
//       return '';
//     }
//   }

//   Future<void> _exchangeSolana() async {
//     final amount = double.parse(_amountController.text);
//     final recipientAddress = _recipientController.text.trim();

//     if (amount > _userSolanaBalance) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Insufficient Solana balance.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (recipientAddress.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please enter a recipient wallet address.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       // Calculating the amount of BTC or ETH to send based on the current exchange rate
//       final exchangeAmount = amount * _currentSolanaPrice;

//       // Sending the Solana to the recipient address
//       final walletAddress = await _getSavedWalletAddress();
//       final walletPubKey = Ed25519HDPublicKey.fromBase58(walletAddress);
//       final recipientPubKey = Ed25519HDPublicKey.fromBase58(recipientAddress);

//       // Creating a transaction
//       final transaction = Transaction(instructions: [
//         SystemInstruction.transfer(
//           fundingAccount: walletPubKey,
//           recipientAccount: recipientPubKey,
//           lamports: (amount * 1e9).toInt(),
//         ),
//       ]);

//       // Assuming you have a signer for the wallet (from a private key or seed phrase)
//       // You need to replace `yourSigner` with your actual signer.
//       final signature = await _solanaClient.rpcClient
//           .sendTransaction(transaction, [/* yourSigner here */]);

//       print(
//           'Exchanged $amount SOL for $exchangeAmount $_selectedCrypto. Sent to $recipientAddress. Signature: $signature');

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Exchange successful.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       print('Failed to exchange Solana: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to exchange Solana.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Crypto Exchange'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Your Solana Balance: $_userSolanaBalance SOL',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Current Solana Price: $_currentSolanaPrice $_selectedCrypto',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 32),
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: 'Amount to Exchange',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _recipientController,
//               decoration: InputDecoration(
//                 labelText: 'Recipient Wallet Address',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),
//             DropdownButton<String>(
//               value: _selectedCrypto,
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCrypto = value!;
//                   _fetchCryptoExchangeRate();
//                 });
//               },
//               items: ['BTC', 'ETH'].map((crypto) {
//                 return DropdownMenuItem<String>(
//                   value: crypto,
//                   child: Text(crypto),
//                 );
//               }).toList(),
//             ),
//             SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: _exchangeSolana,
//               child: Text('Exchange Solana'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _amountController.dispose();
//     _recipientController.dispose();
//     super.dispose();
//   }
// }
