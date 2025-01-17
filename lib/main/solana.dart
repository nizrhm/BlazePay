import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:bip39/bip39.dart' as bip39;

class SolanaWalletService {
  static const String _rpcUrl = 'https://api.devnet.solana.com';
  late final SolanaClient _client;

  static final SolanaWalletService _instance = SolanaWalletService._internal();
  factory SolanaWalletService() => _instance;

  SolanaWalletService._internal() {
    _client = SolanaClient(
      rpcUrl: Uri.parse(_rpcUrl),
      websocketUrl: Uri.parse(_rpcUrl.replaceFirst('https', 'wss')),
    );
  }

  // Validate if a string is a valid Solana address
  bool isValidSolanaAddress(String address) {
    try {
      Ed25519HDPublicKey.fromBase58(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get phone number associated with a wallet address
  Future<String?> getPhoneNumberByAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAddress = prefs.getString('wallet_address');
      final storedPhoneNumber = prefs.getString('phone_number');

      if (storedAddress == address && storedPhoneNumber != null) {
        return storedPhoneNumber;
      }

      return null;
    } catch (e) {
      throw WalletException('Failed to lookup phone number: $e');
    }
  }

  Future<WalletData> createWallet(String phoneNumber) async {
    try {
      // Check if wallet already exists for this phone number
      final existingWallet = await getWallet(phoneNumber);
      if (existingWallet != null) {
        return existingWallet;
      }

      final mnemonic = bip39.generateMnemonic();
      final seed = bip39.mnemonicToSeed(mnemonic);

      final keyData = await ED25519_HD_KEY.derivePath(
        "m/44'/501'/0'/0'",
        seed,
      );

      final keypair = await Ed25519HDKeyPair.fromSeedWithHdPath(
        seed: keyData.key,
        hdPath: "m/44'/501'/0'/0'",
      );

      // Save both mnemonic and public key
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_mnemonic_${phoneNumber}', mnemonic);
      await prefs.setString('wallet_address_${phoneNumber}', keypair.address);

      return WalletData(
        publicKey: keypair.address,
        mnemonic: mnemonic,
      );
    } catch (e) {
      throw WalletException('Failed to create wallet: $e');
    }
  }

  Future<WalletData?> getWallet(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mnemonic = prefs.getString('wallet_mnemonic_${phoneNumber}');
      final address = prefs.getString('wallet_address_${phoneNumber}');

      if (mnemonic == null || address == null) return null;

      return WalletData(
        publicKey: address,
        mnemonic: mnemonic,
      );
    } catch (e) {
      throw WalletException('Failed to retrieve wallet: $e');
    }
  }

  Future<String> sendSol({
    required String senderAddress,
    required String recipientAddress,
    required double amount,
  }) async {
    try {
      // Validate addresses
      if (!isValidSolanaAddress(senderAddress)) {
        throw WalletException('Invalid sender address');
      }
      if (!isValidSolanaAddress(recipientAddress)) {
        throw WalletException('Invalid recipient address');
      }

      // Get sender's phone number from address
      final senderPhone = await getPhoneNumberByAddress(senderAddress);
      if (senderPhone == null) {
        throw WalletException('Sender wallet not found in local storage');
      }

      // Get sender's wallet data
      final senderWallet = await getWallet(senderPhone);
      if (senderWallet == null) {
        throw WalletException('Sender wallet data not found');
      }

      final seed = bip39.mnemonicToSeed(senderWallet.mnemonic);
      final keyData = await ED25519_HD_KEY.derivePath(
        "m/44'/501'/0'/0'",
        seed,
      );

      final keypair = await Ed25519HDKeyPair.fromSeedWithHdPath(
        seed: keyData.key,
        hdPath: "m/44'/501'/0'/0'",
      );

      // Verify we have the correct keypair
      if (keypair.address != senderAddress) {
        throw WalletException('Wallet address mismatch');
      }

      final recipientPubKey =
          await Ed25519HDPublicKey.fromBase58(recipientAddress);
      final lamports = (amount * 1e9).toInt();

      // Check balance before sending
      final balance = await getBalance(senderAddress);
      if (balance < amount) {
        throw WalletException('Insufficient balance');
      }

      final latestBlockhashResult =
          await _client.rpcClient.getLatestBlockhash();
      final blockhash = latestBlockhashResult.value.blockhash;

      final instruction = SystemInstruction.transfer(
        fundingAccount: keypair.publicKey,
        recipientAccount: recipientPubKey,
        lamports: lamports,
      );

      final message = Message(instructions: [instruction]);
      final compiledMessage = message.compile(
        recentBlockhash: blockhash,
        feePayer: keypair.publicKey,
      );

      final signedTx = SignedTx(
        compiledMessage: compiledMessage,
        signatures: [await keypair.sign(compiledMessage.toByteArray())],
      );

      final signature = await _client.rpcClient.sendTransaction(
        signedTx.encode(),
        preflightCommitment: Commitment.confirmed,
      );

      return signature;
    } catch (e) {
      throw TransactionException('Failed to send SOL: $e');
    }
  }

  Future<double> getBalance(String address) async {
    try {
      if (!isValidSolanaAddress(address)) {
        throw WalletException('Invalid address');
      }

      final balance = await _client.rpcClient.getBalance(address);
      return balance.value / 1e9;
    } catch (e) {
      throw WalletException('Failed to get balance: $e');
    }
  }

  Future<String> requestAirdrop(String address, {double amount = 1.0}) async {
    try {
      final lamports = (amount * 1e9).toInt();
      final signature = await _client.rpcClient.requestAirdrop(
        address,
        lamports,
        commitment: Commitment.confirmed,
      );
      return signature;
    } catch (e) {
      throw WalletException('Failed to request airdrop: $e');
    }
  }
}

class WalletData {
  final String publicKey;
  final String mnemonic;

  WalletData({
    required this.publicKey,
    required this.mnemonic,
  });
}

class WalletException implements Exception {
  final String message;
  WalletException(this.message);

  @override
  String toString() => message;
}

class TransactionException implements Exception {
  final String message;
  TransactionException(this.message);

  @override
  String toString() => message;
}
