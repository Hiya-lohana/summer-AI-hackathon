import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../services/cyber_cell_service.dart';
import '../services/notification_service.dart';
import '../models/scan_result.dart';
import 'scan_screen.dart';
import 'payment_screen.dart';
import 'voice_screen.dart';
import 'family_screen.dart';
import 'tips_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  bool _showNotificationPanel = false;
  bool _blinkState = true;
  Timer? _blinkTimer;
  bool _isInitialized = false;
  int _prevNotificationsLength = 0;

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _blinkState = !_blinkState;
        });
      }
    });

    _prevNotificationsLength = NotificationService.notifications.length;
    NotificationService.notificationsNotifier.addListener(_onNotificationsChanged);
    _checkAndPushDailyFact();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    NotificationService.notificationsNotifier.removeListener(_onNotificationsChanged);
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _quickReportCyberCrime() async {
    final mockResult = ScanResult(
      riskLevel: RiskLevel.suspicious,
      score: 75.0,
      reasons: ['Suspicious payment link', 'Unregistered telecom sender'],
      advice: 'Avoid clicking unknown links or sharing financial tokens.',
    );

    final success = await CyberCellService.reportThreat(
      scamSource: "Suspicious SMS message received on mobile device",
      scanResult: mockResult,
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

  void _showProfileStatusDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.cardRadius),
          topRight: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, color: AppTheme.safeGreen, size: 54),
              const SizedBox(height: 12),
              Text(
                'Citizen Protection Active',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Safenet AI is running background scans for unverified payment gateways, phishing links, and audio anomalies.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1527) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isDark ? const Color(0xFF0052CC) : AppTheme.primaryBlue.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF007AFF), // Vibrant blue icon color
              size: 42.0,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimary,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070D19) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFF5252).withOpacity(isDark ? 0.35 : 0.2),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF5252),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indian Cyber Crime Cell Portal',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'National Emergency Announcement',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you have encountered this message, tap the button below to generate a formatted incident dossier and upload it to the National Cybercrime portal.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252), // Coral red button color
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _quickReportCyberCrime,
              icon: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Report Threat & File Dossier',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyFactCard() {
    final day = DateTime.now().day;
    final dailyFacts = [
      "You NEVER need to enter your UPI PIN to receive money. If someone asks you to enter your PIN, it is a scam!",
      "Never share your OTP with anyone on a phone call. Official bank representatives will never ask for your OTP.",
      "Scammers can spoof official bank numbers. Hang up and call the official number printed on your debit card.",
      "Do not install apps like AnyDesk, TeamViewer, or UltraViewer on a caller's request. They can see and control your phone.",
      "Fake delivery SMS claims your address is incomplete to make you click a link and pay Rs. 5. This is a credential theft scam.",
      "KBC or lottery programs do not send WhatsApp messages claiming you won Rs. 25 Lakhs. Do not pay any processing fee.",
      "Double-check sender IDs of bank messages. Real bank SMS has sender IDs like 'AD-HDFCBK' or 'JZ-SBIIN', not normal mobile numbers.",
      "Electricity cut-off warnings claiming your power will be cut tonight unless you call a personal number are scams. Real companies give advance notice.",
      "Banks do not suspend accounts suddenly via SMS links. Walk into your local branch to verify KYC requests.",
      "Scanning a QR code sent by a buyer online means money is leaving your account, not coming in. Never scan a code to receive payments."
    ];
    final fact = dailyFacts[day % dailyFacts.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAILY CYBER SHIELD FACT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndPushDailyFact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastPushDate = prefs.getString('last_daily_fact_push_date');

      if (lastPushDate != todayStr) {
        final day = DateTime.now().day;
        final dailyFacts = [
          "💡 You NEVER need to enter your UPI PIN to receive money. If someone asks you to enter your PIN to receive funds, it is a scam!",
          "Never share your OTP with anyone on a phone call. Official bank representatives will never ask for your OTP. 🔒",
          "Scammers can spoof official bank numbers. Hang up and call the official number printed on your debit card. 📞",
          "Do not install apps like AnyDesk or TeamViewer on a caller's request. They can see and control your phone screens. 📱",
          "Fake delivery SMS claims your address is incomplete to make you click a link and pay a fee. This is a scam to steal bank details.",
          "Lottery programs do not send WhatsApp messages claiming you won Rs. 25 Lakhs. Do not pay any processing fee. 💸",
          "Double-check sender IDs of bank messages. Real bank SMS has sender IDs like 'AD-HDFCBK' or 'JZ-SBIIN', not normal mobile numbers.",
          "Electricity cut-off warnings claiming your power will be cut tonight unless you call a personal number are scams.",
          "Banks do not suspend accounts suddenly via SMS links. Walk into your local branch to verify KYC requests. 🏦",
          "Scanning a QR code sent by a buyer online means money is leaving your account, not coming in. Never scan a code to receive payments. 🛡️"
        ];
        final fact = dailyFacts[day % dailyFacts.length];

        // Use the actual current time to notify the user dynamically at the moment they open the app
        NotificationService.addNotification(
          title: "Daily Cyber Tip",
          description: fact,
          icon: Icons.lightbulb_outline,
          iconColor: Colors.amber,
        );

        await prefs.setString('last_daily_fact_push_date', todayStr);
      }
    } catch (e) {
      debugPrint("Error checking or pushing daily fact: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _prevNotificationsLength = NotificationService.notifications.length;
        });
      }
    }
  }

  OverlayEntry? _overlayEntry;

  void _onNotificationsChanged() {
    if (!mounted || !_isInitialized) return;
    
    final currentList = NotificationService.notifications;
    if (currentList.length > _prevNotificationsLength) {
      final newNotif = currentList.first;
      _showSystemOverlayNotification(newNotif);
    }
    _prevNotificationsLength = currentList.length;
  }

  void _showSystemOverlayNotification(SafenetNotification notification) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _overlayEntry?.remove();
                _overlayEntry = null;
                setState(() {
                  _showNotificationPanel = true;
                  NotificationService.unreadCount.value = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Premium dark slate background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: notification.iconColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(notification.icon, color: notification.iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'now',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    Timer(const Duration(seconds: 4), () {
      if (mounted && _overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navBar,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const AppLogo(size: 28, showText: true),
            const SizedBox(width: 8),
            AnimatedOpacity(
              opacity: _blinkState ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.safeGreen, width: 1),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 2, backgroundColor: AppTheme.safeGreen),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: AppTheme.safeGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppTheme.textPrimary,
              size: 22,
            ),
            onPressed: () {
              AppTheme.themeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: AppTheme.textPrimary,
              size: 22,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_none, color: AppTheme.textPrimary, size: 22),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unreadCount,
                  builder: (context, count, child) {
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.dangerRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showNotificationPanel = !_showNotificationPanel;
                NotificationService.unreadCount.value = 0; // Mark notifications as read
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 20.0,
              bottom: 95.0, // Substantial bottom padding to avoid bottom navigation clutter
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.25,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDashboardCard(
                      icon: Icons.shield_outlined,
                      label: 'My Sheild', // Typo matched exactly from mockup
                      onTap: _showProfileStatusDialog,
                    ),
                    _buildDashboardCard(
                      icon: Icons.qr_code_scanner,
                      label: 'UPI Guard',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      icon: Icons.chat_bubble_outline,
                      label: 'SMS Scan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      icon: Icons.mic_none_outlined,
                      label: 'Voice AI',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VoiceScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      icon: Icons.people_outline,
                      label: 'Guardians',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FamilyScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      icon: Icons.lightbulb_outline,
                      label: 'Cyber Tips',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TipsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAnnouncementCard(),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showNotificationPanel ? 0 : -620,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor, width: 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Security Alerts',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ValueListenableBuilder<List<SafenetNotification>>(
                            valueListenable: NotificationService.notificationsNotifier,
                            builder: (context, list, child) {
                              if (list.isEmpty) return const SizedBox.shrink();
                              return TextButton(
                                onPressed: () {
                                  NotificationService.clearNotifications();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: AppTheme.dangerRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                            onPressed: () {
                              setState(() {
                                _showNotificationPanel = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: AppTheme.dividerColor),
                  
                  // Dynamic Notifications List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ValueListenableBuilder<List<SafenetNotification>>(
                      valueListenable: NotificationService.notificationsNotifier,
                      builder: (context, list, child) {
                        if (list.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Safenet Active & Secure',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'No recent security threats detected.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => Divider(color: AppTheme.dividerColor),
                          itemBuilder: (context, index) {
                            final notification = list[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: notification.iconColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(notification.icon, color: notification.iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              notification.time,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notification.description,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (notification.onAction != null && notification.actionLabel != null) ...[
                                          const SizedBox(height: 6),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryBlue,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showNotificationPanel = false;
                                              });
                                              notification.onAction!();
                                            },
                                            child: Text(
                                              notification.actionLabel!,
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
