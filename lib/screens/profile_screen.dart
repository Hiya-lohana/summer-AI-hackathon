import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _userName = 'Safenet Defender';
  String _userPhone = 'Not Configured';
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Safenet Defender';
        _userPhone = prefs.getString('user_phone') ?? 'Not Configured';
        _nameController.text = _userName;
        _phoneController.text = _userPhone == 'Not Configured' ? '' : _userPhone;
      });
    } catch (e) {
      debugPrint("Failed to load local profile cache: $e");
    }

    // Sync from Firestore if available
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = data['name'] as String? ?? 'Safenet Defender';
          final phone = data['phone'] as String? ?? 'Not Configured';
          
          setState(() {
            _userName = name;
            _userPhone = phone;
            _nameController.text = name;
            _phoneController.text = phone == 'Not Configured' ? '' : phone;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', name);
          await prefs.setString('user_phone', phone);
        }
      }
    } catch (e) {
      debugPrint("Failed to sync profile from cloud: $e");
    }
  }

  Future<void> _saveProfileDetails() async {
    final newName = _nameController.text.trim().isEmpty ? 'Safenet Defender' : _nameController.text.trim();
    final newPhone = _phoneController.text.trim().isEmpty ? 'Not Configured' : _phoneController.text.trim();

    setState(() {
      _userName = newName;
      _userPhone = newPhone;
      _isEditing = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newName);
      await prefs.setString('user_phone', newPhone);
    } catch (e) {
      debugPrint("Failed to save profile cache locally: $e");
    }

    try {
      await _dbService.saveUserProfile(newName, newPhone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully!'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to save profile cloud backup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile & History'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Profile Card
            _buildProfileCard(isDark),
            const SizedBox(height: 24),

            // User Manual Card
            _buildUserManualCard(isDark),
            const SizedBox(height: 24),

            // Scan History Header
            Text(
              'MY SCAN HISTORY',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 12),

            // Realtime Scan History Stream
            _buildScanHistoryList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Cosmic Avatar
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B2CBF), // Cosmic Purple
                      Color(0xFF3C096C), // Deep Indigo
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Name and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: $_userPhone',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: AppTheme.primaryBlue),
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
            ],
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F1424) : const Color(0xFFF1EDE4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F1424) : const Color(0xFFF1EDE4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveProfileDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
                child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 0.1, curve: Curves.easeOutQuad, duration: 400.ms).fadeIn();
  }

  Widget _buildScanHistoryList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getScanHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'History load failed. Offline scans are active.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_outlined, color: AppTheme.textSecondary, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Aapka history abhi khaali hai.',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perform verification scans from dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index];
            final String type = data['type'] ?? 'SCAN';
            final String input = data['input'] ?? '';
            final String riskLevelName = data['risk_level'] ?? 'safe';
            final double score = (data['risk_score'] as num?)?.toDouble() ?? 0.0;
            final String advice = data['advice'] ?? '';
            
            String dateStr = 'Just now';
            try {
              if (data['timestamp'] != null) {
                final dt = DateTime.parse(data['timestamp']);
                dateStr = '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }
            } catch (_) {}

            // Risk configurations
            Color riskColor;
            IconData riskIcon;
            if (riskLevelName.toLowerCase() == 'dangerous') {
              riskColor = AppTheme.dangerRed;
              riskIcon = Icons.report_gmailerrorred_rounded;
            } else if (riskLevelName.toLowerCase() == 'suspicious') {
              riskColor = AppTheme.warningOrange;
              riskIcon = Icons.warning_amber_rounded;
            } else {
              riskColor = AppTheme.safeGreen;
              riskIcon = Icons.check_circle_outline_rounded;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(riskIcon, size: 14, color: riskColor),
                            const SizedBox(width: 4),
                            Text(
                              '${riskLevelName.toUpperCase()} (${score.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Input type: $type',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    input,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 16),
                  Text(
                    advice,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, delay: (index * 50).ms, curve: Curves.easeOutQuad, duration: 300.ms).fadeIn();
          },
        );
      },
    );
  }

  Widget _buildUserManualCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _showUserManual(context, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Manual / निर्देशिका',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick guide on how to use Safenet AI features',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, delay: 100.ms, curve: Curves.easeOutQuad, duration: 400.ms).fadeIn();
  }

  void _showUserManual(BuildContext context, bool isDark) {
    String manualLanguage = 'English';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.cardRadius),
          topRight: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isHindi = manualLanguage == 'Hindi';

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pull handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header with Title and Language Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isHindi ? 'सुरक्षा निर्देशिका' : 'User Manual',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Custom Toggle Row
                          Row(
                            children: [
                              _buildLangToggleItem(
                                'EN',
                                manualLanguage == 'English',
                                () => setModalState(() => manualLanguage = 'English'),
                              ),
                              const SizedBox(width: 8),
                              _buildLangToggleItem(
                                'हिन्दी',
                                manualLanguage == 'Hindi',
                                () => setModalState(() => manualLanguage = 'Hindi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHindi 
                            ? 'सेफनेट एआई का उपयोग कैसे करें' 
                            : 'How to use Safenet AI to stay protected',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(height: 24),

                      // Manual Content
                      _buildManualSection(
                        icon: Icons.mic_none_outlined,
                        title: isHindi ? '🎙️ १. वॉयस असिस्टेंट' : '🎙️ 1. Voice Assistant',
                        subtitle: isHindi ? 'बोलकर सलाह लें' : 'Get verbal safety advice',
                        steps: isHindi
                            ? 'भाषा चुनें ➔ माइक्रोफोन दबाएं ➔ समस्या बोलें ➔ काम खत्म होने पर दोबारा माइक्रोफोन बटन दबाएं।\n\nपरिणाम: ऐप जांच करेगा कि यह कोई धोखाधड़ी है या नहीं और सुरक्षा सलाह जोर से बोलकर सुनाएगा।'
                            : 'Select language ➔ Tap Microphone ➔ Speak your problem ➔ Tap Microphone again to finish.\n\nResult: The app checks if it\'s a scam and reads the safety advice out loud.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildManualSection(
                        icon: Icons.sms_outlined,
                        title: isHindi ? '✉️ २. मैसेज और लिंक स्कैनर' : '✉️ 2. SMS & Link Scanner',
                        subtitle: isHindi ? 'संदिग्ध मैसेज की जांच' : 'Check text/SMS logs',
                        steps: isHindi
                            ? 'संदिग्ध मैसेज को यहां पेस्ट करें (या स्क्रीनशॉट अपलोड करें) और मैसेज स्कैन करें दबाएं।\n\nपरिणाम: ऐप मैसेज की जांच करेगा और सुरक्षा स्तर (सुरक्षित 🟢 या खतरनाक 🔴) दिखाएगा।'
                            : 'Paste a suspicious message (or upload a screenshot of it) and tap Scan Message.\n\nResult: The app checks the text and displays a Risk Score (Safe 🟢 or Warning 🔴).',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildManualSection(
                        icon: Icons.qr_code_scanner_outlined,
                        title: isHindi ? '💳 ३. यूपीआई और क्यूआर स्कैनर' : '💳 3. UPI & QR Scanner',
                        subtitle: isHindi ? 'पेमेंट की जांच करें' : 'Verify payee before paying',
                        steps: isHindi
                            ? 'पेमेंट क्यूआर कोड स्कैन करें (या यूपीआई आईडी टाइप करें) और पता सत्यापित करें दबाएं।\n\nपरिणाम: यदि प्राप्तकर्ता संदिग्ध है तो आपको पैसे भेजने से पहले चेतावनी मिल जाएगी।'
                            : 'Scan a payment QR code (or type a UPI ID) and tap Verify Address.\n\nResult: Warns you before you pay if the recipient is suspicious.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildManualSection(
                        icon: Icons.sos_outlined,
                        title: isHindi ? '🚨 ४. आपातकालीन एसओएस' : '🚨 4. Emergency SOS',
                        subtitle: isHindi ? 'मदद के लिए अलार्म' : 'Broadcast emergency alerts',
                        steps: isHindi
                            ? 'सबसे पहले गार्जियन नेटवर्क में अपने परिवार के नंबर जोड़ें। किसी भी आपातकाल में लाल एसओएस बटन को ३ सेकंड तक दबाकर रखें।\n\nपरिणाम: आपके परिवार को आपके जीपीएस लोकेशन के साथ तुरंत आपातकालीन एसएमएस चला जाएगा।'
                            : 'Add family member numbers first in the Guardian Network. In an emergency, hold the red SOS button for 3 seconds.\n\nResult: Automatically sends an emergency SMS with your GPS location to your family.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildManualSection(
                        icon: Icons.report_outlined,
                        title: isHindi ? '📋 ५. साइबर सेल रिपोर्ट' : '📋 5. Cyber Cell Report',
                        subtitle: isHindi ? 'शिकायत दर्ज करें' : 'File reports instantly',
                        steps: isHindi
                            ? 'होम स्क्रीन पर खतरे की रिपोर्ट करें बटन दबाएं।\n\nपरिणाम: धोखाधड़ी का विवरण कॉपी हो जाएगा और सरकार की साइबर क्राइम वेबसाइट (cybercrime.gov.in) खुल जाएगी, जहाँ आप इसे पेस्ट कर सकते हैं।'
                            : 'Tap Report Threat on the home screen.\n\nResult: Copies scam details automatically and opens the official government website (cybercrime.gov.in) to paste and report it.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                            ),
                          ),
                          child: Text(
                            isHindi ? 'बंद करें' : 'Close Manual',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLangToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.dividerColor,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildManualSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String steps,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 12),
                const SizedBox(height: 4),
                Text(
                  steps,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
