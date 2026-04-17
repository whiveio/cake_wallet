import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

class WhiveTransactionPriority extends BitcoinTransactionPriority {
  const WhiveTransactionPriority({required super.title, required super.raw});

  static const List<WhiveTransactionPriority> all = [fast, medium, slow];
  static const WhiveTransactionPriority slow =
      WhiveTransactionPriority(title: 'Slow', raw: 0);
  static const WhiveTransactionPriority medium =
      WhiveTransactionPriority(title: 'Medium', raw: 1);
  static const WhiveTransactionPriority fast =
      WhiveTransactionPriority(title: 'Fast', raw: 2);

  static WhiveTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for WhiveTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'sat'; // satoshis

  @override
  String toString() {
    var label = '';

    switch (this) {
      case WhiveTransactionPriority.slow:
        label = 'Slow';
        break;
      case WhiveTransactionPriority.medium:
        label = 'Medium';
        break;
      case WhiveTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }
}
