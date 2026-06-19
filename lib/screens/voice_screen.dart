import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import '../widgets/pulse_orb_widget.dart';
import '../services/gemini_service.dart';

enum VoiceState { idle, listening, processing, response }

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with TickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  String _typedResponse = '';
  String _transcribedText = '';
  Timer? _listeningTimer;
  StreamSubscription<String>? _voiceSubscription;

  final GeminiService _gemini = GeminiService();
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;

  // TTS & Language configurations
  late FlutterTts _flutterTts;
  String _selectedLanguage = 'English';
  bool _isTalkBackEnabled = true;

  // Waveform bars animation
  late AnimationController _waveformController;
  final List<double> _barHeights = [10.0, 10.0, 10.0, 10.0, 10.0];
  final Random _random = Random();

  List<String> get _suggestions {
    if (_selectedLanguage == 'Hindi') {
      return [
        'यूपीआई कैसे ब्लॉक करें?',
        'क्या यह ओटीपी अनुरोध घोटाला है?',
        'संदिग्ध नंबरों की पहचान करें',
        'ऑनलाइन नकद धोखाधड़ी की रिपोर्ट करें',
        'लॉटरी एसएमएस सुरक्षा की जांच करें',
      ];
    }
    return [
      'How do I block UPI?',
      'Is this OTP request a scam?',
      'Identify suspicious numbers',
      'Report online cash fraud',
      'Check lottery SMS security',
    ];
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeechRecognizer();
    _initTts();

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _waveformController.addListener(() {
      if (_state == VoiceState.listening) {
        setState(() {
          for (int i = 0; i < 5; i++) {
            _barHeights[i] = 8.0 + _random.nextDouble() * 32.0;
          }
        });
      }
    });
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS Initialization Error: $e');
    }
  }

  void _initSpeechRecognizer() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech Status: $status'),
        onError: (error) => debugPrint('Speech Error: $error'),
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _waveformController.dispose();
    _voiceSubscription?.cancel();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _startListening({String? preSelectedQuery}) async {
    await _flutterTts.stop();

    // Request microphone permission natively
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission is required for Voice Assistant.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
      return;
    }

    setState(() {
      _state = VoiceState.listening;
      _typedResponse = '';
      _transcribedText = preSelectedQuery ?? '';
    });
    _waveformController.repeat(reverse: true);

    // If preselected, skip speech recognition and directly process
    if (preSelectedQuery != null) {
      _listeningTimer = Timer(const Duration(seconds: 2), () {
        _stopListeningAndProcess(preSelectedQuery);
      });
      return;
    }

    if (_speechEnabled) {
      try {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _transcribedText = result.recognizedWords;
            });
          },
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 30),
          localeId: _selectedLanguage == 'Hindi' ? 'hi_IN' : 'en_IN',
        );
      } catch (e) {
        debugPrint('Speech listen error: $e');
      }
    }
  }

  void _stopListeningAndProcess(String userSpeech) async {
    _listeningTimer?.cancel();
    _waveformController.stop();
    if (_speechEnabled) {
      await _speech.stop();
    }
    await _flutterTts.stop();

    if (!mounted) return;

    setState(() {
      _state = VoiceState.processing;
    });

    // If user didn't speak anything (e.g. emulator, or silent), pick a suggestion
    final finalQuery = userSpeech.trim().isNotEmpty
        ? userSpeech
        : _suggestions[_random.nextInt(_suggestions.length)];

    setState(() {
      _transcribedText = finalQuery;
    });

    // Cancel old stream subscription if any
    await _voiceSubscription?.cancel();

    // Listen to real-time streaming response from Gemini
    _voiceSubscription = _gemini.getVoiceAdviceStream(finalQuery, language: _selectedLanguage).listen(
      (chunk) {
        setState(() {
          _typedResponse = chunk;
          _state = VoiceState.response;
        });
      },
      onError: (e) {
        setState(() {
          _typedResponse = _selectedLanguage == 'Hindi'
              ? 'एआई कनेक्शन विफल रहा। कृपया पुन: प्रयास करें।'
              : 'AI connection failed. Please try again.';
          _state = VoiceState.response;
        });
      },
      onDone: () {
        setState(() {
          _state = VoiceState.response;
        });
        if (_isTalkBackEnabled && _typedResponse.isNotEmpty) {
          _flutterTts.speak(_typedResponse);
        }
      },
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6,
            height: _state == VoiceState.listening ? _barHeights[index] : 8.0,
            decoration: BoxDecoration(
              color: AppTheme.dangerRed,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'Hindi' ? 'आवाज सुरक्षा सहायक' : 'Voice Safety Assistant',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.horizontalPadding),
        child: Column(
          children: [
            // Language Selector & Talkback Controls Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor.withOpacity(0.4), width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language Dropdown
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: AppTheme.surfaceCard,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                              });
                              _flutterTts.setLanguage(newValue == 'Hindi' ? 'hi-IN' : 'en-IN');
                            }
                          },
                          items: <String>['English', 'Hindi']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  // Talkback Switch
                  Row(
                    children: [
                      Text(
                        _selectedLanguage == 'Hindi' ? 'आवाज बोलें' : 'Talk Back',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          _isTalkBackEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: _isTalkBackEnabled ? AppTheme.safeGreen : AppTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isTalkBackEnabled = !_isTalkBackEnabled;
                          });
                          if (!_isTalkBackEnabled) {
                            _flutterTts.stop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Large pulsing mic orb
            Center(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _state == VoiceState.response
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: PulseOrbWidget(
                  type: _state == VoiceState.listening
                      ? PulseOrbType.voiceListening
                      : PulseOrbType.voiceIdle,
                  onTap: () {
                    if (_state == VoiceState.idle) {
                      _startListening();
                    } else if (_state == VoiceState.listening) {
                      _stopListeningAndProcess(_transcribedText);
                    }
                  },
                  child: Icon(
                    _state == VoiceState.listening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                secondChild: InkWell(
                  onTap: () {
                    _flutterTts.stop();
                    setState(() {
                      _state = VoiceState.idle;
                      _typedResponse = '';
                      _transcribedText = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppTheme.dividerColor, width: 1.0),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Middle state indicators & transcript bubble
            if (_state == VoiceState.idle) ...[
              Text(
                _selectedLanguage == 'Hindi'
                    ? 'सुरक्षा सहायक से बात करने के लिए माइक दबाएं'
                    : 'Tap Mic to Speak with Safenet AI',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (_state == VoiceState.listening) ...[
              Text(
                _selectedLanguage == 'Hindi' ? 'सुरक्षित रूप से सुन रहे हैं...' : 'Listening securely...',
                style: const TextStyle(
                  color: AppTheme.dangerRed,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildWaveform(),
              if (_transcribedText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor, width: 1.0),
                  ),
                  child: Text(
                    '"$_transcribedText"',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ] else if (_state == VoiceState.processing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.safeGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedLanguage == 'Hindi'
                          ? 'प्रोसेसिंग: "$_transcribedText"'
                          : 'Query: "$_transcribedText"',
                      style: const TextStyle(
                        color: AppTheme.safeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (_state == VoiceState.response) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor, width: 1.0),
                ),
                child: Text(
                  _selectedLanguage == 'Hindi' ? 'पूछा गया: "$_transcribedText"' : 'Asked: "$_transcribedText"',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const Spacer(),

            // Response Card or Suggestion chips (Minimalist design)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _state == VoiceState.response
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLanguage == 'Hindi'
                        ? 'अनुशंसित सुरक्षा प्रश्न'
                        : 'RECOMMENDED SAFETY QUERIES',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: AppTheme.surfaceCard,
                            side: BorderSide(
                              color: AppTheme.primaryBlue.withOpacity(0.15),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                            ),
                            label: Text(
                              _suggestions[index],
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () {
                              _startListening(preSelectedQuery: _suggestions[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spoken Problem Summary
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: AppTheme.dangerRed, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedLanguage == 'Hindi' ? 'आपकी समस्या:' : 'Your Query:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _transcribedText,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    // AI Safety Advice Summary
                    Row(
                      children: [
                        const Icon(Icons.assistant_outlined, color: AppTheme.safeGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedLanguage == 'Hindi' ? 'सुरक्षा समाधान और सलाह:' : 'AI Safety Solution:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.safeGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _typedResponse,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 45), // Shifted recommended part & response card up
          ],
        ),
      ),
    );
  }
}
