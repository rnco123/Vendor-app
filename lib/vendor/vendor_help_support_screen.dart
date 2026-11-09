// lib/screens/vendor_help_support_screen.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';

class VendorHelpSupportScreen extends StatefulWidget {
  const VendorHelpSupportScreen({super.key});

  @override
  State<VendorHelpSupportScreen> createState() => _VendorHelpSupportScreenState();
}

class _VendorHelpSupportScreenState extends State<VendorHelpSupportScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
           backgroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 179, 178, 178),
            width: 1,
          ),
        ),
           titleSpacing: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color.fromRGBO(230, 231, 242, 1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildFAQItem(
              index: 0,
              question: 'How to add a driver?',
              answer: 'Go to Fleet Management, select Drivers tab, and click the + button to add a new driver with their details.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              index: 1,
              question: 'How to manage my fleet?',
              answer: 'Navigate to Fleet Management System to view and manage all your drivers, vehicles, and ride assignments.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              index: 2,
              question: 'How to track payments?',
              answer: 'Visit Payment & Withdrawals section in your profile to view transaction history and request withdrawals.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              index: 3,
              question: 'How to monitor ongoing rides?',
              answer: 'Go to Monitoring Rides to see all active rides in real time, along with driver, passenger, and route details.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              index: 4,
              question: 'How to withdraw earnings?',
              answer: 'Go to Payment & Withdrawals, select your preferred payment method, and submit a withdrawal request.',
            ),
            const SizedBox(height: 32),
            
            // Contact Support Section
            Row(
              children: [
                Icon(
                  Icons.headset_mic_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildContactOption(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '0123 4567 890',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'Chat with our support team',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedIndex == index;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}