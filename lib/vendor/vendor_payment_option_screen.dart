import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../email_signin_screen.dart';
import '../shared/app_log.dart';
import '../shared/network_check.dart';
import 'vendor_profile_submitted_sheet.dart';
import 'vendor_ui.dart';

class _PayOption {
  final String key;
  final String title;
  final String subtitle;
  final String? asset;
  final IconData icon;

  const _PayOption(this.key, this.title, this.subtitle, this.icon, [this.asset]);
}

const _options = [
  _PayOption('jazzcash', 'JazzCash', 'Mobile wallet · Instant transfer',
      Icons.account_balance_wallet_outlined, 'assets/images/jazzcash.png'),
  _PayOption('easypaisa', 'Easypaisa', 'Mobile wallet · Fast & secure',
      Icons.account_balance_wallet_outlined, 'assets/images/easypaisa.png'),
  _PayOption('bank_transfer', 'Bank Transfer', 'IBFT · Direct to account',
      Icons.account_balance_outlined),
];

class VendorPaymentOptionScreen extends StatefulWidget {
  const VendorPaymentOptionScreen({super.key});

  @override
  State<VendorPaymentOptionScreen> createState() =>
      _VendorPaymentOptionScreenState();
}

class _VendorPaymentOptionScreenState extends State<VendorPaymentOptionScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _complete() async {
    if (_selected == null) {
      showVendorSnack(context, 'Please choose a payment option.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!await hasInternet()) {
      if (mounted) showVendorSnack(context, offlineMessage);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(uid).set({
        'payment_methods': {'active': _selected},
        'profile_step': 'submitted',
        'approval_status': 'pending',
        'submitted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _saving = false);
      await showVendorSubmittedSheet(context);
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
        (_) => false,
      );
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_payment_option_screen.dart:complete', e, st);
      if (mounted) {
        setState(() => _saving = false);
        showVendorSnack(context, 'Could not submit your profile. Please try again.');
      }
    }
  }

  Widget _logo(_PayOption o) {
    final fallback = Icon(o.icon, color: AppColors.textPrimary, size: 22);
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: o.asset == null
          ? fallback
          : Image.asset(
              o.asset!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }

  Widget _card(_PayOption o) {
    final selected = _selected == o.key;
    return GestureDetector(
      onTap: _saving ? null : () => setState(() => _selected = o.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedPaymentBg : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _logo(o),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: vendorSetupAppBar(context, 'Profile Setup'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  const VendorSetupHeading(
                    title: 'Choose Payment Option',
                    subtitle:
                        'Pick your preferred method to receive payments for your services.',
                  ),
                  const SizedBox(height: 24),
                  for (final o in _options) ...[
                    _card(o),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: VendorPrimaryButton(
                label: 'Complete Profile',
                loading: _saving,
                onPressed: _complete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
