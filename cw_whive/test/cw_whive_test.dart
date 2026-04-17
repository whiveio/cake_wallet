import 'package:flutter_test/flutter_test.dart';
import 'package:cw_whive/cw_whive.dart';

void main() {
  test('Whive network parameters are correct', () {
    final network = WhiveNetwork.mainnet;
    expect(network.p2pkhNetVer, [73]);
    expect(network.p2shNetVer, [10]);
    expect(network.p2wpkhHrp, 'wv');
  });
}
