import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class ManageSecurityScreen extends StatefulWidget {
  final String currentEmail;

  const ManageSecurityScreen({super.key, required this.currentEmail});

  @override
  State<ManageSecurityScreen> createState() => _ManageSecurityScreenState();
}

class _ManageSecurityScreenState extends State<ManageSecurityScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _emailPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _obscureEmailPassword = true;
  bool _updatingPassword = false;
  bool _updatingEmail = false;

  bool get _isEmailPasswordUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _newEmailCtrl.dispose();
    _emailPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'requires-recent-login':
        return 'Please sign out and sign in again, then retry';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email change is turned off right now. Please contact support';
      case 'network-request-failed':
        return 'No internet connection. Please try again';
      default:
        return e.message ?? 'Something went wrong. Please try again';
    }
  }

  void _showSnack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (!_isEmailPasswordUser) {
      _showSnack('Password change is not available for this sign-in method');
      return;
    }

    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty) {
      _showSnack('Enter your current password');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match');
      return;
    }

    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnack('No email on this account');
      return;
    }

    setState(() => _updatingPassword = true);
    try {
      await _reauthenticate(email, current);
      await _auth.currentUser!.updatePassword(newPass);
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showSnack('Password updated successfully', success: true);
    } on FirebaseAuthException catch (e) {
      _showSnack(_authErrorMessage(e));
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _updatingPassword = false);
    }
  }

  Future<void> _updateEmail() async {
    if (!_isEmailPasswordUser) {
      _showSnack('Email change is not available for this sign-in method');
      return;
    }

    final newEmail = _newEmailCtrl.text.trim();
    final password = _emailPasswordCtrl.text;

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showSnack('Enter a valid new email address');
      return;
    }
    if (newEmail.toLowerCase() == widget.currentEmail.toLowerCase()) {
      _showSnack('New email must be different from your current email');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Enter your current password to change email');
      return;
    }

    final currentEmail = _auth.currentUser?.email;
    if (currentEmail == null || currentEmail.isEmpty) {
      _showSnack('No email on this account');
      return;
    }

    setState(() => _updatingEmail = true);
    try {
      await _reauthenticate(currentEmail, password);
      await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'pending_email': newEmail,
            'email_pending_verification': true,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('pending email save error: $e');
        }
      }

      _newEmailCtrl.clear();
      _emailPasswordCtrl.clear();
      _showSnack(
        'Verification link sent to $newEmail. Check your inbox and spam folder. After you open the link, sign in again with your new email.',
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_authErrorMessage(e));
    } catch (e) {
      debugPrint('update email error: $e');
      _showSnack('Could not send the verification email. Please try again');
    } finally {
      if (mounted) setState(() => _updatingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
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
          'Manage Security',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEmailPasswordUser)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'Your account uses a sign-in method other than email and password. '
                    'Contact support to update security settings.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              _sectionTitle('Change password'),
              const SizedBox(height: 12),
              _passwordField(
                label: 'Current password',
                controller: _currentPasswordCtrl,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 16),
              _passwordField(
                label: 'New password',
                controller: _newPasswordCtrl,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _passwordField(
                label: 'Retype new password',
                controller: _confirmPasswordCtrl,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 20),
              _primaryButton(
                label: 'Update password',
                loading: _updatingPassword,
                onPressed: _isEmailPasswordUser && !_updatingPassword
                    ? _updatePassword
                    : null,
              ),
              const SizedBox(height: 32),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 32),
              _sectionTitle('Change email address'),
              const SizedBox(height: 8),
              Text(
                'Current: ${widget.currentEmail.isEmpty ? '—' : widget.currentEmail}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _textField(
                label: 'New email address',
                controller: _newEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                hint: 'Enter new email',
              ),
              const SizedBox(height: 16),
              _passwordField(
                label: 'Current password',
                controller: _emailPasswordCtrl,
                obscure: _obscureEmailPassword,
                onToggle: () => setState(
                    () => _obscureEmailPassword = !_obscureEmailPassword),
              ),
              const SizedBox(height: 12),
              const Text(
                'We will send a verification link to your new email. '
                'Your sign-in email updates after you confirm it.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _primaryButton(
                label: 'Update email',
                loading: _updatingEmail,
                onPressed:
                    _isEmailPasswordUser && !_updatingEmail ? _updateEmail : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autocorrect: false,
          cursorColor: AppColors.primary,
          decoration: _inputDecoration(hint),
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          cursorColor: AppColors.primary,
          decoration: _inputDecoration('••••••••').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
