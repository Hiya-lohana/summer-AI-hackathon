enum RiskLevel { safe, suspicious, dangerous }

class ScanResult {
  final RiskLevel riskLevel;
  final double score; // 0.0 to 1.0 (or 0 to 100)
  final String advice;
  final List<String> reasons;

  ScanResult({
    required this.riskLevel,
    required this.score,
    required this.advice,
    required this.reasons,
  });
}
