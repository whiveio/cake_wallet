import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class WhiveNewWalletCredentials extends WalletCredentials {
  WhiveNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    super.passphrase,
    this.mnemonic,
  });
  final String? mnemonic;
}

class WhiveRestoreWalletFromSeedCredentials extends WalletCredentials {
  WhiveRestoreWalletFromSeedCredentials({
    required super.name,
    required String super.password,
    required this.mnemonic,
    super.walletInfo,
    super.passphrase,
  });

  final String mnemonic;
}

class WhiveRestoreWalletFromWIFCredentials extends WalletCredentials {
  WhiveRestoreWalletFromWIFCredentials(
      {required super.name, required String super.password, required this.wif, super.walletInfo});

  final String wif;
}
