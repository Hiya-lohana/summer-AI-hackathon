import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon/models/scan_result.dart';
import 'package:hackathon/services/scan_service.dart';

void main() {
  group('Safenet AI Scan Service Tests', () {
    test('Detects OTP fraud text correctly', () async {
      final result = await ScanService.scanTextStream('Dear User, enter OTP 4321 to confirm.').last;
      expect(result.riskLevel, equals(RiskLevel.dangerous));
      expect(result.score, equals(92.0));
      expect(result.reasons, contains('Request for One-Time Password (OTP)'));
    });

    test('Detects prize / lottery claim texts correctly', () async {
      final result = await ScanService.scanTextStream('Congratulations! You won 1 Crore in KBC lottery.').last;
      expect(result.riskLevel, equals(RiskLevel.dangerous));
      expect(result.score, equals(88.0));
    });

    test('Validates UPI format correctly', () async {
      final invalidUpi = await ScanService.checkUpiIdStream('invalidupiid').last;
      expect(invalidUpi.riskLevel, equals(RiskLevel.dangerous));
      expect(invalidUpi.score, equals(100.0));

      final suspiciousUpi = await ScanService.checkUpiIdStream('hack-rewards@paytm').last;
      expect(suspiciousUpi.riskLevel, equals(RiskLevel.dangerous));
      expect(suspiciousUpi.score, equals(96.0));
    });
  });
}
