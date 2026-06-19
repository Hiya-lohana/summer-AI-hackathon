import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/risk_ring_widget.dart';

class PaymentScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const PaymentScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  final TextEditingController _upiController = TextEditingController();
  bool _isLoading = false;
  ScanResult? _scanResult;
  bool _showUpiInput = false;
  StreamSubscription<ScanResult>? _scanSubscription;

  final List<String> _paymentTips = [
    'Always verify the payee name on the bank screen before entering your UPI PIN.',
    'No genuine merchant or lottery will ask you to scan a QR code to RECEIVE money.',
    'Avoid scanning QR codes sent over WhatsApp or SMS by unknown accounts.',
    'Keep your UPI PIN confidential; it is only required for making payments, never for receiving them.',
    'Check if the payment portal has secure HTTPS locks before scanning or filling bank cards.',
    'Report any fraudulent transactions immediately to your bank or the Cyber Cell at 1930.',
    'Beware of "Refund" or "Cashback" links that redirect you to UPI apps to authorize transactions.',
  ];
  int _currentTipIndex = 0;

  void _refreshTip() {
    setState(() {
      _currentTipIndex = Random().nextInt(_paymentTips.length);
    });
  }

  // Wave dots controllers
  late AnimationController _waveController;
  final List<Animation<double>> _dotAnimations = [];

  // Form Key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _upiController.dispose();
    _waveController.dispose();
    _scanSubscription?.cancel();
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

  Future<void> _pickQrImage(ImageSource source) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Native Mobile Android/iOS interface required. Web QR scanning is disabled.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }
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
            content: Text('Error picking QR image: $e'),
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

  void _showQrSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCAN QR CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue),
                title: const Text('Capture using Camera', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _pickQrImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppTheme.primaryBlue),
                title: const Text('Select from Photo Library', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _pickQrImage(ImageSource.gallery);
                },
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
            'Analyzing Payment Target...',
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

        // Advice Card (Minimalist flat design)
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
            'UPI REGISTRAR FACTORS',
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

        if (result.riskLevel != RiskLevel.safe)
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
                'ALERT TRUSTED CONTACTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

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
                _upiController.clear();
                _showUpiInput = false;
              });
            },
            child: Text(
              'Perform New Payment Scan',
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

  Widget _buildSafetyTipCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.warningOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Safety Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: _refreshTip,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _paymentTips[_currentTipIndex],
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('UPI & QR Payment Guard'),
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
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _showQrSourceDialog,
                        child: Container(
                          height: 135,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_scanner,
                                  color: AppTheme.primaryBlue, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Scan QR Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check camera or library',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showUpiInput = !_showUpiInput;
                          });
                        },
                        child: Container(
                          height: 135,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.alternate_email,
                                  color: AppTheme.primaryBlue, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Check UPI ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verify handler names',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // UPI Slide down box using AnimatedContainer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showUpiInput ? 90.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _upiController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., name@okbank',
                                    hintStyle: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                    filled: true,
                                    fillColor: AppTheme.surfaceCard,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.content_paste, color: AppTheme.primaryBlue, size: 18),
                                      onPressed: () async {
                                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                                        if (data != null && data.text != null) {
                                          setState(() {
                                            _upiController.text = data.text!;
                                          });
                                        }
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.buttonRadius),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a UPI ID';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Invalid UPI ID format';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.buttonRadius),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _triggerScan(ScanService.checkUpiIdStream(
                                        _upiController.text));
                                  }
                                },
                                child: const Text(
                                  'Verify',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Safety Tip Card
                _buildSafetyTipCard(),
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
