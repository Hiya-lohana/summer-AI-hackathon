import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';

class CyberCellService {
  static const String portalUrl = 'https://cybercrime.gov.in/';

  /// Generates a standardized complaints text log using details from a scanned threat.
  static String compileEvidence({
    required String scamSource, // e.g. text message, UPI ID, Image scan
    required ScanResult scanResult,
  }) {
    final timestamp = DateTime.now().toLocal().toString().substring(0, 19);
    final riskText = scanResult.riskLevel.name.toUpperCase();
    final reasonsText = scanResult.reasons.isNotEmpty 
        ? scanResult.reasons.map((r) => '- $r').join('\n')
        : '- Suspicious content indicators detected';

    return '''
NATIONAL CYBER CRIME REPORTING EVIDENCE
---------------------------------------
Source / Indicator: "$scamSource"
Threat Level: $riskText (AI Confidence: ${scanResult.score.toStringAsFixed(0)}%)
Timestamp: $timestamp
Tool Assessment: Safenet AI Scam Shield

AI Determination Factors:
$reasonsText

Security Advice Provided:
"${scanResult.advice}"

---------------------------------------
Evidence prepared by Safenet AI Security.
Copy this text to paste into the official portal.
''';
  }

  /// Copies evidence to the clipboard and launches the National Cyber Crime Reporting Portal.
  static Future<bool> reportThreat({
    required String scamSource,
    required ScanResult scanResult,
  }) async {
    final compiledText = compileEvidence(scamSource: scamSource, scanResult: scanResult);
    
    // Copy to clipboard natively (Universal platforms)
    await Clipboard.setData(ClipboardData(text: compiledText));

    final url = Uri.parse(portalUrl);
    
    // 1. Try direct launch to external browser first (bypasses Android 11+ queries restriction)
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint("Direct launchUrl external failed: $e");
    }

    // 2. Try default platform launch
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint("Direct launchUrl platformDefault failed: $e");
    }

    // 3. Fallback to check using legacy queries check
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
    } catch (e) {
      debugPrint("canLaunchUrl fallback failed: $e");
    }

    return false;
  }
}
