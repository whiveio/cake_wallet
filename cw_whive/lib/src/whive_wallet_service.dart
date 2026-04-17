import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_whive/cw_whive.dart';
import 'package:hive/hive.dart';

class WhiveWalletService extends WalletService<
    WhiveNewWalletCredentials,
    WhiveRestoreWalletFromSeedCredentials,
    WhiveRestoreWalletFromWIFCredentials,
    WhiveNewWalletCredentials> {
  WhiveWalletService(this.unspentCoinsInfoSource, this.isDirect);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.whive;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<WhiveWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final wallet = await WhiveWalletBase.create(
      mnemonic: credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<WhiveWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await WhiveWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await WhiveWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);

    final unspentCoinsToDelete = unspentCoinsInfoSource.values
        .where((unspentCoin) => unspentCoin.walletId == walletInfo.id)
        .toList();

    final keysToDelete = unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final currentWallet = await WhiveWalletBase.open(
        password: password,
        name: currentName,
        walletInfo: currentWalletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect));

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<WhiveWallet> restoreFromHardwareWallet(WhiveNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Whive wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<WhiveWallet> restoreFromKeys(credentials, {bool? isTestnet}) {
    throw UnimplementedError('restoreFromKeys() is not implemented');
  }

  @override
  Future<WhiveWallet> restoreFromSeed(WhiveRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw Exception('Invalid mnemonic: ${credentials.mnemonic}');
    }

    final wallet = await WhiveWalletBase.create(
        password: credentials.password!,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo!,
        derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        passphrase: credentials.passphrase);
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
