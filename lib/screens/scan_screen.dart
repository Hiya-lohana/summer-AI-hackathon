import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../services/cyber_cell_service.dart';
import '../theme/app_theme.dart';
import '../widgets/risk_ring_widget.dart';

class ScanScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ScanScreen({super.key, this.onNavigate});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  ScanResult? _scanResult;
  int _charCount = 0;
  StreamSubscription<ScanResult>? _scanSubscription;

  // Real-time dynamic probability scoring loop
  final ValueNotifier<double> _liveRiskScore = ValueNotifier<double>(0.0);

  // Wave dots controllers
  late AnimationController _waveController;
  final List<Animation<double>> _dotAnimations = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    for (int i = 0; i < 3; i++) {
      _dotAnimations.add(
        Tween<double>(begin: 0.0, end: -8.0).animate(
          CurvedAnimation(
            parent: _waveController,
            curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
          ),
        ),
      );
    }
    _waveController.repeat(reverse: true);
  }

  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      _charCount = text.length;
    });
    // Calculate live dynamic risk based on real-time token presence
    _liveRiskScore.value = _calculateLiveRiskScore(text);
  }

  double _calculateLiveRiskScore(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return 0.0;

    double score = 10.0; // Base score if text has content
    if (lower.contains('otp') || lower.contains('one time password')) score += 35.0;
    if (lower.contains('link') || lower.contains('click') || lower.contains('http') || lower.contains('https')) score += 25.0;
    if (lower.contains('win') || lower.contains('lottery') || lower.contains('prize') || lower.contains('won') || lower.contains('crore')) score += 40.0;
    if (lower.contains('bank') || lower.contains('blocked') || lower.contains('suspend')) score += 20.0;
    if (lower.contains('pin') || lower.contains('password')) score += 30.0;
    if (lower.contains('collect') || lower.contains('request') || lower.contains('pay')) score += 15.0;

    if (score > 100.0) score = 100.0;
    return score;
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _waveController.dispose();
    _scanSubscription?.cancel();
    _liveRiskScore.dispose();
    super.dispose();
  }

  void _triggerScan(Stream<ScanResult> scanStream) async {
    FocusScope.of(context).unfocus();
    await _scanSubscription?.cancel();

    setState(() {
      _isLoading = true;
      _scanResult = null;
    });

    _scanSubscription = scanStream.listen(
      (result) {
        setState(() {
          _scanResult = result;
          // Synchronize the live score notifier with the actual AI/local scanner output
          _liveRiskScore.value = result.score;
          
          if (result.advice.isNotEmpty && result.advice != 'AI is analyzing text structure...') {
            _isLoading = false;
          }
        });
      },
      onError: (e) {
        setState(() {
          _isLoading = false;
        });
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Native Mobile Android/iOS interface required. Web media scanning is disabled.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }
    // Check permission natively
    Permission permission = source == ImageSource.camera 
        ? Permission.camera 
        : Permission.photos;

    final status = await permission.request();
    if (status.isGranted || status.isLimited) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? file = await picker.pickImage(source: source);
        if (file != null) {
          final bytes = await file.readAsBytes();
          if (source == ImageSource.camera) {
            _triggerScan(ScanService.scanCameraClickStream(imageBytes: bytes));
          } else {
            _triggerScan(ScanService.scanGalleryImageStream(imageBytes: bytes));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission denied to access ${source == ImageSource.camera ? "Camera" : "Gallery"}. Please enable it in Settings.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _reportToCyberCell(ScanResult result) async {
    final success = await CyberCellService.reportThreat(
      scamSource: _textController.text.isNotEmpty ? _textController.text : "Scanned document or image screenshot",
      scanResult: result,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '📋 Complaint Summary Copied! Opening Official Portal...' 
                : 'Copied summary, please open cybercrime.gov.in manually.',
          ),
          backgroundColor: AppTheme.safeGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildLiveRiskIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: _liveRiskScore,
      builder: (context, score, child) {
        if (score == 0.0) return const SizedBox.shrink();

        Color indicatorColor = AppTheme.safeGreen;
        String statusLabel = 'SAFE';

        if (score > 70.0) {
          indicatorColor = AppTheme.dangerRed;
          statusLabel = 'HIGH FRAUD RISK';
        } else if (score > 30.0) {
          indicatorColor = AppTheme.warningOrange;
          statusLabel = 'SUSPICIOUS';
        }

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: indicatorColor.withOpacity(0.3), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE FRAUD RISK INDEX:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$statusLabel (${score.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: indicatorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100.0,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _dotAnimations[index].value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: AppTheme.textSecondary,
          highlightColor: AppTheme.textPrimary,
          child: const Text(
            'Safenet AI is analyzing...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildResult(ScanResult result) {
    Color riskColor;
    switch (result.riskLevel) {
      case RiskLevel.safe:
        riskColor = AppTheme.safeGreen;
        break;
      case RiskLevel.suspicious:
        riskColor = AppTheme.warningOrange;
        break;
      case RiskLevel.dangerous:
        riskColor = AppTheme.dangerRed;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        RiskRingWidget(riskLevel: result.riskLevel, score: result.score),
        const SizedBox(height: 24),

        // Advice Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: riskColor.withOpacity(0.4), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: riskColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Safenet Anti-Scam Verdict',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.advice,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reasons List
        if (result.reasons.isNotEmpty) ...[
          Text(
            'DETERMINATION FACTORS',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(result.reasons.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: riskColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.reasons[index],
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 24),

        // Action buttons
        if (result.riskLevel != RiskLevel.safe) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
              ),
              onPressed: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(4);
                }
              },
              icon: const Icon(Icons.warning, color: Colors.white, size: 18),
              label: const Text(
                'ALERT FAMILY NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dangerRed, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
              ),
              onPressed: () => _reportToCyberCell(result),
              icon: const Icon(Icons.gpp_bad_outlined, color: AppTheme.dangerRed, size: 18),
              label: const Text(
                'REPORT TO INDIAN CYBER CELL',
                style: TextStyle(
                  color: AppTheme.dangerRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
            ),
            onPressed: () {
              setState(() {
                _scanResult = null;
                _textController.clear();
                _liveRiskScore.value = 0.0;
              });
            },
            child: Text(
              'Scan Another Message',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Scan Scam Messages'),
          automaticallyImplyLeading: true,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppTheme.textPrimary,
                size: 22,
              ),
              onPressed: () {
                AppTheme.themeNotifier.value =
                    AppTheme.themeNotifier.value == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              if (_scanResult == null && !_isLoading) ...[
                Text(
                  'PASTE SUSPICIOUS TEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      maxLength: 1000,
                      buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) {
                        return Text(
                          '$currentLength / $maxLength chars',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Enter suspicious text message, links or lottery claims...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryBlue, width: 1.0),
                        ),
                      ),
                    ),
                    if (_charCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () {
                            _textController.clear();
                            _liveRiskScore.value = 0.0;
                          },
                        ),
                      ),
                  ],
                ),
                _buildLiveRiskIndicator(),
                const SizedBox(height: 12),

                // Primary Scan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.buttonRadius),
                      ),
                      disabledBackgroundColor:
                          AppTheme.primaryBlue.withOpacity(0.4),
                    ),
                    onPressed: _charCount == 0
                        ? null
                        : () {
                            _triggerScan(
                                ScanService.scanTextStream(_textController.text));
                          },
                    child: const Text(
                      'Scan Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Row of other actions (Gallery, Camera)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryBlue, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.buttonRadius),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.image_outlined,
                            color: AppTheme.primaryBlue, size: 18),
                        label: const Text(
                          'Upload Gallery',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryBlue, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.buttonRadius),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: AppTheme.primaryBlue, size: 18),
                        label: const Text(
                          'Camera Capture',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // State displaying loading
              if (_isLoading) _buildLoading(),

              // State displaying results
              if (_scanResult != null) _buildResult(_scanResult!),
            ],
          ),
        ),
      ),
    );
  }
}
