import 'dart:convert';
import 'dart:typed_data';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:bitcoin_base/bitcoin_base.dart';

abstract class BaseBitcoinAddressRecord {
  BaseBitcoinAddressRecord(
    this.address, {
    required this.index,
    this.isHidden = false,
    int txCount = 0,
    int balance = 0,
    String name = '',
    bool isUsed = false,
    required this.type,
    required this.network,
  })  : _txCount = txCount,
        _balance = balance,
        _name = name,
        _isUsed = Observable(isUsed);

  @override
  bool operator ==(Object o) => o is BaseBitcoinAddressRecord && address == o.address;

  final String address;
  bool isHidden;
  final int index;
  int _txCount;
  int _balance;
  String _name;
  final Observable<bool> _isUsed;
  BasedUtxoNetwork? network;

  int get txCount => _txCount;

  String get name => _name;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed.value;

  void setAsUsed() => _isUsed.value = true;
  void setNewName(String label) => _name = label;

  int get hashCode => address.hashCode;

  BitcoinAddressType type;

  String toJSON();
}

class BitcoinAddressRecord extends BaseBitcoinAddressRecord {
  BitcoinAddressRecord(
    super.address, {
    required super.index,
    super.isHidden = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required super.type,
    String? scriptHash,
    required super.network,
  })  {
    try {
      this.scriptHash = scriptHash ??
        (network != null ? BitcoinAddressUtils.scriptHash(address, network: network!) : null);
    } catch (e) {
      printV(e);
    }
}

  factory BitcoinAddressRecord.fromJSON(String jsonSource, {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(
      decoded['address'] as String,
      index: decoded['index'] as int,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SegwitAddresType.p2wpkh,
      scriptHash: decoded['scriptHash'] as String?,
      network: network,
    );
  }

  String? scriptHash;

  String getScriptHash(BasedUtxoNetwork network) {
    if (scriptHash != null) return scriptHash!;
    try {
      scriptHash = BitcoinAddressUtils.scriptHash(address, network: network);
    } catch (e) {
      // Fallback for P2PKH addresses on networks with custom version bytes (like Whive)
      try {
        scriptHash = _computeP2PKHScriptHash(address, network);
      } catch (e2) {
        printV('Failed to compute script hash for $address: $e2');
        return '';
      }
    }
    return scriptHash!;
  }

  /// Manually compute script hash for P2PKH addresses
  /// This is needed for networks with non-standard version bytes (e.g., Whive)
  String? _computeP2PKHScriptHash(String address, BasedUtxoNetwork network) {
    // Decode Base58Check address to get the pubkey hash
    final decoded = Base58Decoder.checkDecode(address);
    if (decoded.isEmpty) return null;

    // The decoded data is: version_byte (1 byte) + pubkey_hash (20 bytes)
    // Verify the version byte matches the network's P2PKH version
    final versionByte = decoded[0];
    if (network.p2pkhNetVer.isNotEmpty && versionByte != network.p2pkhNetVer[0]) {
      return null;
    }

    // Extract the 20-byte pubkey hash
    final pubkeyHash = decoded.sublist(1);
    if (pubkeyHash.length != 20) return null;

    // Build P2PKH script: OP_DUP OP_HASH160 <20 bytes> OP_EQUALVERIFY OP_CHECKSIG
    // Hex: 76 a9 14 <pubkeyhash> 88 ac
    final script = Uint8List(25);
    script[0] = 0x76;  // OP_DUP
    script[1] = 0xa9;  // OP_HASH160
    script[2] = 0x14;  // Push 20 bytes
    script.setRange(3, 23, pubkeyHash);
    script[23] = 0x88; // OP_EQUALVERIFY
    script[24] = 0xac; // OP_CHECKSIG

    // SHA256 hash of the script
    final hash = QuickCrypto.sha256Hash(script);

    // Reverse bytes for little-endian (Electrum protocol requirement)
    final reversed = Uint8List.fromList(hash.reversed.toList());

    // Return hex string
    return BytesUtils.toHexString(reversed);
  }

  @override
  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'scriptHash': scriptHash,
      });
}

class BitcoinSilentPaymentAddressRecord extends BaseBitcoinAddressRecord {
  BitcoinSilentPaymentAddressRecord(
    super.address, {
    required super.index,
    super.isHidden = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required this.silentPaymentTweak,
    required super.network,
    required super.type,
    this.spendDerivationPath = SILENT_PAYMENTS_SPEND_PATH_TESTNET,
  });

  factory BitcoinSilentPaymentAddressRecord.fromJSON(String jsonSource,
      {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinSilentPaymentAddressRecord(
      decoded['address'] as String,
      index: decoded['index'] as int,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      network: (decoded['network'] as String?) == null
          ? network
          : BasedUtxoNetwork.fromName(decoded['network'] as String),
      silentPaymentTweak: decoded['silent_payment_tweak'] as String?,
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SilentPaymentsAddresType.p2sp,
      spendDerivationPath:
          decoded['spend_derivation_path'] as String? ?? SILENT_PAYMENTS_SPEND_PATH_TESTNET,
    );
  }

  final String? silentPaymentTweak;
  final String spendDerivationPath;

  @override
  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'network': network?.value,
        'silent_payment_tweak': silentPaymentTweak,
        'spend_derivation_path': spendDerivationPath,
      });
}
