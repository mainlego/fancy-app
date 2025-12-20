import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// FAQ data model
class FAQItem {
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// FAQ Screen
class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<FAQItem> _faqItems = [
    // Getting Started
    FAQItem(
      category: 'Getting Started',
      question: 'How do I create an account?',
      answer: 'You can create an account by signing up with your email address or using Google Sign-In. Follow the onboarding process to set up your profile with photos and preferences.',
    ),
    FAQItem(
      category: 'Getting Started',
      question: 'How do I verify my profile?',
      answer: 'Go to Settings > Photo Verification. You\'ll need to take two selfies with specific poses (thumbs up and wave). Our AI will compare these photos with your profile to verify your identity.',
    ),
    FAQItem(
      category: 'Getting Started',
      question: 'What information do I need to complete my profile?',
      answer: 'To complete your profile, you need at least one photo, your name, birth date, and dating preferences. Adding more details like interests, bio, and additional photos increases your chances of finding matches.',
    ),

    // Matching & Discovery
    FAQItem(
      category: 'Matching',
      question: 'How does matching work?',
      answer: 'When you like someone and they like you back, it\'s a match! You can then start chatting with each other. Use the discovery screen to browse profiles and swipe right to like or left to pass.',
    ),
    FAQItem(
      category: 'Matching',
      question: 'What is a Super Like?',
      answer: 'A Super Like lets someone know you\'re especially interested in them. When you Super Like someone, they\'ll see a special notification and your profile will stand out from others.',
    ),
    FAQItem(
      category: 'Matching',
      question: 'Can I undo a swipe?',
      answer: 'Currently, swipes cannot be undone. Take your time when reviewing profiles to make sure you\'re making the right choice.',
    ),
    FAQItem(
      category: 'Matching',
      question: 'How do filters work?',
      answer: 'Use filters to narrow down profiles based on age, distance, interests, and other preferences. Tap the filter icon on the discovery screen to customize your search.',
    ),

    // Messaging
    FAQItem(
      category: 'Messaging',
      question: 'How do I start a conversation?',
      answer: 'Once you have a match, go to the Chats tab and select the person you want to message. Send a thoughtful first message to make a good impression!',
    ),
    FAQItem(
      category: 'Messaging',
      question: 'Can I send photos and videos?',
      answer: 'Yes! You can send photos and videos in chat. Tap the attachment icon to select media from your gallery or take a new photo/video.',
    ),
    FAQItem(
      category: 'Messaging',
      question: 'What are voice messages?',
      answer: 'Voice messages let you send audio recordings to your matches. Press and hold the microphone icon to record, then release to send.',
    ),
    FAQItem(
      category: 'Messaging',
      question: 'Can I delete messages?',
      answer: 'Yes, you can delete messages from your side of the conversation. Long press on a message to see deletion options.',
    ),

    // Privacy & Safety
    FAQItem(
      category: 'Privacy & Safety',
      question: 'How do I block someone?',
      answer: 'You can block a user from their profile or chat screen. Tap the menu icon and select "Block". Blocked users won\'t be able to see your profile or contact you.',
    ),
    FAQItem(
      category: 'Privacy & Safety',
      question: 'How do I report inappropriate behavior?',
      answer: 'If you encounter inappropriate behavior, tap the menu icon on their profile or in chat and select "Report". Provide details about the issue and our team will review it.',
    ),
    FAQItem(
      category: 'Privacy & Safety',
      question: 'What is Incognito Mode?',
      answer: 'Incognito Mode lets you browse profiles privately. When enabled, only people you\'ve liked will be able to see your profile.',
    ),
    FAQItem(
      category: 'Privacy & Safety',
      question: 'How is my data protected?',
      answer: 'We take your privacy seriously. Your data is encrypted and stored securely. You can manage your privacy settings and download or delete your data anytime from Settings > Privacy & Data.',
    ),

    // Premium
    FAQItem(
      category: 'Premium',
      question: 'What features are included in Premium?',
      answer: 'Premium includes unlimited likes, ability to see who liked you, 1 boost per month, Passport mode to match anywhere, Incognito mode, and an ad-free experience.',
    ),
    FAQItem(
      category: 'Premium',
      question: 'How do I upgrade to Premium?',
      answer: 'Go to Settings and tap on the Premium card, or tap the crown icon in the app. Choose your preferred subscription plan and complete the payment.',
    ),
    FAQItem(
      category: 'Premium',
      question: 'Can I cancel my subscription?',
      answer: 'Yes, you can cancel anytime. Go to Settings > Subscription > Cancel subscription. You\'ll keep Premium features until the end of your current billing period.',
    ),
    FAQItem(
      category: 'Premium',
      question: 'How do I restore my purchase?',
      answer: 'If you\'ve previously purchased Premium, go to Settings > Subscription > Restore purchase. Make sure you\'re signed in with the same account used for the original purchase.',
    ),

    // Account
    FAQItem(
      category: 'Account',
      question: 'How do I change my email?',
      answer: 'Currently, email changes require contacting support. Please reach out to us through Settings > Support > Contact us.',
    ),
    FAQItem(
      category: 'Account',
      question: 'How do I delete my account?',
      answer: 'Go to Settings > Privacy & Data > Delete Account. This action is permanent and will remove all your data, matches, and messages.',
    ),
    FAQItem(
      category: 'Account',
      question: 'Can I temporarily hide my profile?',
      answer: 'Yes, you can pause your profile from appearing in discovery by enabling Incognito Mode in Settings > Security.',
    ),
  ];

  List<String> get _categories {
    final categories = _faqItems.map((item) => item.category).toSet().toList();
    return ['All', ...categories];
  }

  List<FAQItem> get _filteredItems {
    return _faqItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search questions...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      category,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // FAQ list
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.vGapMd,
                        Text(
                          'No results found',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Try different keywords or category',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _FAQExpansionTile(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FAQExpansionTile extends StatefulWidget {
  final FAQItem item;

  const _FAQExpansionTile({required this.item});

  @override
  State<_FAQExpansionTile> createState() => _FAQExpansionTileState();
}

class _FAQExpansionTileState extends State<_FAQExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.item.answer,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
