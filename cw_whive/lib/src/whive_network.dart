import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

/// Whive Network Parameters
/// Based on chainparams.cpp from https://github.com/whiveio/whive
class WhiveNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration
  static const WhiveNetwork mainnet = WhiveNetwork._("whiveMainnet");

  @override
  final String value;

  const WhiveNetwork._(this.value);

  /// Whive uses Bitcoin's CoinConf as a base since it's a Bitcoin fork.
  /// We override the specific network parameters.
  @override
  CoinConf get conf => CoinsConf.bitcoinMainNet;

  @override
  List<int> get wifNetVer => [0x80 + 73]; // WIF prefix: mainnet (0x80) + pubkey offset (73) = 201

  @override
  List<int> get p2pkhNetVer => [73]; // PUBKEY_ADDRESS prefix 'W'

  @override
  List<int> get p2shNetVer => [10]; // SCRIPT_ADDRESS prefix

  @override
  String get p2wpkhHrp => 'wv'; // Bech32 human-readable part

  @override
  bool get isMainnet => true;

  @override
  List<BitcoinAddressType> get supportedAddress => [
        P2pkhAddressType.p2pkh,
        P2shAddressType.p2pkhInP2sh,
        SegwitAddresType.p2wpkh, // Bech32 SegWit support for sending
      ];

  @override
  List<BipCoins> get coins => [Bip44Coins.bitcoin]; // Use Bitcoin derivation path
}

class WhiveTestNetwork implements BasedUtxoNetwork {
  /// Testnet configuration
  static const WhiveTestNetwork testnet = WhiveTestNetwork._("whiveTestnet");

  @override
  final String value;

  const WhiveTestNetwork._(this.value);

  @override
  CoinConf get conf => CoinsConf.bitcoinTestNet;

  @override
  List<int> get wifNetVer => [0xef]; // Testnet WIF prefix

  @override
  List<int> get p2pkhNetVer => [135]; // Testnet PUBKEY_ADDRESS prefix

  @override
  List<int> get p2shNetVer => [196]; // Testnet SCRIPT_ADDRESS prefix

  @override
  String get p2wpkhHrp => 'tw'; // Testnet Bech32 human-readable part

  @override
  bool get isMainnet => false;

  @override
  List<BitcoinAddressType> get supportedAddress => [
        P2pkhAddressType.p2pkh,
        P2shAddressType.p2pkhInP2sh,
        SegwitAddresType.p2wpkh, // Bech32 SegWit support for sending
      ];

  @override
  List<BipCoins> get coins => [Bip44Coins.bitcoinTestnet];
}
