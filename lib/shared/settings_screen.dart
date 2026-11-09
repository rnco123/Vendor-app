import 'package:poolx_partner/app_colors.dart';
import 'package:poolx_partner/shared/edit_profile.dart';
import 'package:poolx_partner/shared/profile_image_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../vendor/vendor_help_support_screen.dart';
import '../vendor/vendor_notification.dart';
import 'poolx_logo.dart';

export 'logout_sheet.dart' show showLogoutSheet;

// ─────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const SettingsScreen({
    super.key,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _role = '';
  String _name = '';
  String _email = '';
  String? _profileImageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final role = userData['role'] as String? ?? '';

    final d = await _firestore.collection('vendors').doc(uid).get();
    final Map<String, dynamic> profileData = d.data() ?? {};

    if (mounted) {
      setState(() {
        _role = role;
        _name = profileData['full_name'] ??
            profileData['business_name'] ??
            profileData['name'] ??
            'User';
        _email = _auth.currentUser?.email?.trim() ??
            (userData['email'] as String?)?.trim() ??
            (profileData['email'] as String?)?.trim() ??
            '';
        _profileImageUrl = profileImageUrlFrom(profileData);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: widget.drawer,
      bottomNavigationBar: widget.bottomNavigationBar,
      appBar: widget.appBar ?? AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 10),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const PoolxLogo(),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // ── Avatar (display only — change photo in Edit Profile) ──
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                      image: _profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person_outline,
                            size: 42, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Name ──────────────────────────────────────
                  Text(_name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),

                  // ── Role badge ────────────────────────────────
                  if (_role.isNotEmpty && _role != 'passenger')
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role[0].toUpperCase() + _role.substring(1),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                  // ── Email ─────────────────────────────────────
                  if (_email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_email,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary)),
                    ),
                  const SizedBox(height: 28),

                  // ── Menu items ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _menuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen()),
                            );
                            await _loadUser();
                          },
                        ),
                        _menuItem(
                          icon: Icons.credit_card_outlined,
                          title: 'Manage Payment',
                          onTap: () {},
                        ),
                        _menuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () => _push(const VendorHelpSupportScreen()),
                        ),
                        _menuItem(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notification Settings',
                          onTap: () =>
                              _push(const VendorNotificationSettingsScreen()),
                        ),
                        _menuItem(
                          icon: Icons.business_outlined,
                          title: 'Business Settings',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _menuItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_right,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}