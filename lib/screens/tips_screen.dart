import 'package:flutter/material.dart';
import '../models/tip.dart';
import '../theme/app_theme.dart';
import '../widgets/scam_tip_card.dart';
import '../data/tips_data.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'OTP',
    'UPI',
    'Phishing',
    'Calls',
    'Links',
    'Malware',
    'Jobs',
    'Shopping',
    'Identity',
    'Social'
  ];

  final List<Tip> _tipsList = officialTipsList;

  List<Tip> get _filteredTips {
    return _tipsList.where((tip) {
      final matchesSearch = tip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip.fullAdvice.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || 
          tip.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Defense Insights & Tips'),
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
      body: Column(
        children: [
          // Sticky search bar and category chips
          Container(
            color: AppTheme.background,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                TextField(
                  style: TextStyle(color: AppTheme.textPrimary),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                    hintText: 'Search safety topics...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          backgroundColor: AppTheme.surfaceCard,
                          selectedColor: AppTheme.primaryBlue,
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : AppTheme.dividerColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                          ),
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable Tips list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
              itemCount: _filteredTips.length,
              itemBuilder: (context, index) {
                return ScamTipCard(tip: _filteredTips[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
