part of 'whive.dart';

class CWWhive extends Whive {
  @override
  WalletService createWhiveWalletService(Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return WhiveWalletService(unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createWhiveNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      WhiveNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createWhiveRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      WhiveRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password, passphrase: passphrase);

  @override
  TransactionPriority deserializeWhiveTransactionPriority(int raw) =>
      WhiveTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() => WhiveTransactionPriority.medium;

  @override
  List<TransactionPriority> getTransactionPriorities() => WhiveTransactionPriority.all;

  @override
  TransactionPriority getWhiveTransactionPrioritySlow() => WhiveTransactionPriority.slow;
}
