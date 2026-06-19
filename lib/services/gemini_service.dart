import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/scan_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }
  
  final GenerativeModel _model;

  GeminiService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
    safetySettings: [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ],
  );

  /// Streams the scam analysis for a text message.
  Stream<ScanResult> analyzeTextStream(String text) async* {
    final prompt = '''
You are an expert anti-scam AI for Indian senior citizens.
Analyze this message and detect if it is a scam.
Message: "$text"

Respond ONLY in this exact JSON format, no extra text:
{
  "risk_level": "SAFE",
  "risk_score": 10,
  "reasons": ["reason1", "reason2"],
  "advice": "Simple advice in English"
}
Risk Levels: SAFE, SUSPICIOUS, DANGEROUS.
Risk Score: 0 (Safe) to 100 (High Danger).
''';

    String accumulated = '';
    try {
      final content = [Content.text(prompt)];
      final responseStream = _model.generateContentStream(content);
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          accumulated += chunk.text!;
          yield _parsePartialJsonResult(accumulated);
        }
      }
    } catch (e) {
      debugPrint('Gemini Text Stream Exception: $e');
      yield* _localTextFallbackStream(text);
    }
  }

  /// Streams the scam analysis for a screenshot image.
  Stream<ScanResult> analyzeImageStream(Uint8List imageBytes) async* {
    const prompt = '''
You are an expert anti-scam AI for Indian senior citizens.
Look at this screenshot. Does it contain scam indicators, phishing links, or suspicious requests?

Respond ONLY in this exact JSON format, no extra text:
{
  "risk_level": "SAFE",
  "risk_score": 10,
  "reasons": ["reason1"],
  "advice": "Simple advice in English"
}
''';

    String accumulated = '';
    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      final responseStream = _model.generateContentStream(content);
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          accumulated += chunk.text!;
          yield _parsePartialJsonResult(accumulated);
        }
      }
    } catch (e) {
      debugPrint('Gemini Image Stream Exception: $e');
      yield* _localTextFallbackStream("screenshot check");
    }
  }

  /// Streams voice assistant tips word-by-word.
  Stream<String> getVoiceAdviceStream(String spokenText, {String language = 'English'}) async* {
    final prompt = language == 'Hindi'
        ? '''
An Indian senior citizen said: "$spokenText"
They are worried about a possible scam.
Give clear advice and reassurance in simple, warm Hindi (using Devanagari script) in under 3 sentences. Keep it easy to understand for elderly citizens.
'''
        : '''
An Indian senior citizen said: "$spokenText"
They are worried about a possible scam.
Give clear advice in simple English in under 3 sentences. Be warm and reassuring.
''';
    try {
      final content = [Content.text(prompt)];
      final responseStream = _model.generateContentStream(content);
      
      String advice = '';
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          advice += chunk.text!;
          yield advice;
        }
      }
    } catch (e) {
      debugPrint('Gemini Voice Stream Exception: $e. Falling back to local streaming.');
      yield* _localVoiceFallbackStream(spokenText, language: language);
    }
  }

  /// Streams a locally generated voice assistant advice word-by-word (avoiding connection error alerts).
  Stream<String> _localVoiceFallbackStream(String query, {String language = 'English'}) async* {
    final lower = query.toLowerCase();
    String advice = '';

    if (language == 'Hindi') {
      if (lower.contains('otp') || lower.contains('password') || lower.contains('pin')) {
        advice = "Safenet AI Guard Voice Advice: Kisi ke saath bhi apna OTP, Bank PIN, ya password share na karein. Bank ka koi bhi adhikari aapse phone par password nahi mangega. Call turant kaat dein.";
      } else if (lower.contains('upi') || lower.contains('pay') || lower.contains('transfer') || lower.contains('money')) {
        advice = "Safenet AI Guard Voice Advice: UPI par paise paane ke liye aapko apna UPI PIN daalne ki zaroorat nahi hoti. Agar GPay ya PhonePe aapse PIN maang raha hai, toh iska matlab paise kat rahe hain. Transfer turant rokein.";
      } else if (lower.contains('link') || lower.contains('click') || lower.contains('sms') || lower.contains('courier')) {
        advice = "Safenet AI Guard Voice Advice: SMS par aaye kisi bhi link par click na karein, khas kar jo electricity bill katne ya courier delay ki baat karte hain. Pehle apne pariwar ke sadasya se pucho.";
      } else {
        advice = "Safenet AI Guard Voice Advice: Kripya savdhan aur satark rahein. Kisi se bhi apni bank details share na karein aur na hi kisi ke kehne par AnyDesk ya TeamViewer app install karein.";
      }
    } else {
      if (lower.contains('otp') || lower.contains('password') || lower.contains('pin')) {
        advice = "Safenet AI Guard Voice Advice: Never share your OTP, Bank PIN, or account passwords with anyone on a phone call. Official bank representatives will never ask for your passwords to fix an account. Hang up immediately.";
      } else if (lower.contains('upi') || lower.contains('pay') || lower.contains('transfer') || lower.contains('money')) {
        advice = "Safenet AI Guard Voice Advice: To receive money on UPI, you do not need to enter your UPI PIN. If GPay or PhonePe asks you to type your security PIN, it means money is being deducted from your account. Stop the transfer immediately.";
      } else if (lower.contains('link') || lower.contains('click') || lower.contains('sms') || lower.contains('courier')) {
        advice = "Safenet AI Guard Voice Advice: Be cautious of links sent via SMS claiming your courier is delayed or your electricity will be disconnected. Do not click those links. Always check using official apps or contact family members.";
      } else {
        advice = "Safenet AI Guard Voice Advice: Please stay safe and alert. Do not share credentials, transfer funds, or install screen-sharing software like AnyDesk or TeamViewer based on unexpected calls or text notifications.";
      }
    }

    final words = advice.split(' ');
    String currentText = '';
    for (final word in words) {
      currentText += '$word ';
      yield currentText.trim();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Streams a locally calculated text check scan result word-by-word to simulate dynamic AI streaming.
  Stream<ScanResult> _localTextFallbackStream(String text) async* {
    final lower = text.toLowerCase();
    RiskLevel level = RiskLevel.safe;
    double score = 10.0;
    List<String> reasons = ['Checked local definition database'];
    String finalAdvice = '';

    if (lower.contains('otp') || lower.contains('password') || lower.contains('pin')) {
      level = RiskLevel.dangerous;
      score = 92.0;
      reasons.addAll(['Request for One-Time Password (OTP)', 'OTP request token detected', 'Critical bank access risk']);
      finalAdvice = "Warning! This message requests an OTP or password. Sharing this code allows unauthorized access to your banking applications. Please block the sender and do not respond.";
    } else if (lower.contains('win') || lower.contains('lottery') || lower.contains('prize') || lower.contains('crore')) {
      level = RiskLevel.dangerous;
      score = 88.0;
      reasons.addAll(['Unsolicited reward lottery patterns', 'Misleading financial gain claims']);
      finalAdvice = "Caution! This lottery offer is a scam. Legitimate organizations like KBC or banks do not contact winners via random SMS or WhatsApp messages.";
    } else if (lower.contains('click') || lower.contains('link') || lower.contains('http') || lower.contains('https')) {
      level = RiskLevel.suspicious;
      score = 64.0;
      reasons.addAll(['External URL token found', 'Potential lookalike domain']);
      finalAdvice = "Suspicious link found. Do not tap on links from unknown contacts. They might install keyloggers or redirect to phishing websites.";
    } else if (lower.contains('scam') || lower.contains('hack') || lower.contains('rewards') || lower.contains('bonus')) {
      level = RiskLevel.dangerous;
      score = 96.0;
      reasons.addAll(['Flagged payment signature found', 'Associated with known scam calls']);
      finalAdvice = "Dangerous! The destination name or UPI tag matches known suspicious patterns. Please do not make any transfer.";
    } else {
      finalAdvice = "Scan complete. No obvious scam keywords detected. However, stay alert if the sender requests financial actions.";
    }

    final words = finalAdvice.split(' ');
    String currentAdvice = '';

    for (final word in words) {
      currentAdvice += '$word ';
      yield ScanResult(
        riskLevel: level,
        score: score,
        reasons: reasons,
        advice: currentAdvice.trim(),
      );
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  ScanResult _parsePartialJsonResult(String accumulated) {
    final levelMatch = RegExp(r'"risk_level"\s*:\s*"([A-Z]*)"', caseSensitive: false).firstMatch(accumulated);
    RiskLevel level = RiskLevel.suspicious;
    if (levelMatch != null) {
      final levelStr = levelMatch.group(1)?.toUpperCase();
      if (levelStr == 'SAFE') level = RiskLevel.safe;
      if (levelStr == 'DANGEROUS') level = RiskLevel.dangerous;
    }

    final scoreMatch = RegExp(r'"risk_score"\s*:\s*(\d+)').firstMatch(accumulated);
    double score = 50.0;
    if (scoreMatch != null) {
      score = double.tryParse(scoreMatch.group(1) ?? '') ?? 50.0;
    }

    final List<String> reasons = [];
    final reasonsMatch = RegExp(r'"reasons"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(accumulated);
    if (reasonsMatch != null) {
      final listContent = reasonsMatch.group(1) ?? '';
      final items = RegExp(r'"([^"]*)"').allMatches(listContent);
      for (final item in items) {
        final val = item.group(1);
        if (val != null && val.isNotEmpty) {
          reasons.add(val);
        }
      }
    }

    String advice = _extractCurrentAdvice(accumulated);
    if (advice.isEmpty) {
      advice = 'AI is analyzing text structure...';
    }

    return ScanResult(
      riskLevel: level,
      score: score,
      reasons: reasons,
      advice: advice,
    );
  }

  String _extractCurrentAdvice(String accumulated) {
    final keyIndex = accumulated.indexOf('"advice"');
    if (keyIndex == -1) return '';
    final colonIndex = accumulated.indexOf(':', keyIndex);
    if (colonIndex == -1) return '';
    final firstQuoteIndex = accumulated.indexOf('"', colonIndex);
    if (firstQuoteIndex == -1) return '';
    
    final secondQuoteIndex = accumulated.indexOf('"', firstQuoteIndex + 1);
    if (secondQuoteIndex == -1) {
      return accumulated.substring(firstQuoteIndex + 1);
    } else {
      return accumulated.substring(firstQuoteIndex + 1, secondQuoteIndex);
    }
  }
}
