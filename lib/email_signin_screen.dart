import 'package:poolx_partner/partner/partner_shell.dart';
import 'package:poolx_partner/vendor/vendor_documents_screen.dart';
import 'package:poolx_partner/vendor/vendor_payment_option_screen.dart';
import 'package:poolx_partner/vendor/vendor_profile_submitted_sheet.dart';
import 'package:poolx_partner/vendor_sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'shared/network_check.dart';
import 'shared/poolx_logo.dart';
import 'vendor/vendor_business_info_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }
    if (!await hasInternet()) {
      _showError(offlineMessage);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Step 2: Get role from Firestore users collection
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        if (!mounted) return;
        _showError('Account not found. Please sign up.');
        await _auth.signOut();
        return;
      }

      final role = userDoc.data()?['role'] as String? ?? 'passenger';

      // Step 3: Upsert last login (set+merge so missing docs don't throw)
      await _firestore.collection('users').doc(uid).set({
        'last_login': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final authEmail = userCredential.user!.email?.trim() ?? '';
      final savedEmail = (userDoc.data()?['email'] as String?)?.trim() ?? '';
      if (authEmail.isNotEmpty &&
          authEmail.toLowerCase() != savedEmail.toLowerCase()) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'email': authEmail,
            'email_pending_verification': false,
            'pending_email': FieldValue.delete(),
          }, SetOptions(merge: true));
          final roleCollection = switch (role.toLowerCase()) {
            'passenger' => 'passengers',
            'driver' => 'drivers',
            'vendor' => 'vendors',
            _ => null,
          };
          if (roleCollection != null) {
            await _firestore.collection(roleCollection).doc(uid).set({
              'email': authEmail,
            }, SetOptions(merge: true));
          }
        } catch (e) {
          debugPrint('email sync error: $e');
        }
      }

      if (role.toLowerCase() != 'vendor') {
        await _auth.signOut();
        if (!mounted) return;
        _showError('This app is for PoolX partners only.');
        return;
      }

      final nextScreen = await partnerHomeFor(uid);

      if (nextScreen == null) {
        await _auth.signOut();
        if (!mounted) return;
        await showVendorSubmittedSheet(context);
        return;
      }

      if (!mounted) return;
      _showSuccess('Welcome back!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = 'Invalid email or password';
      }
      _showError(message);
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter your email first');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSuccess('Password reset email sent! Check your inbox and spam folder.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-email' => 'Please enter a valid email address',
        'user-not-found' => 'No account found with this email',
        'too-many-requests' => 'Too many attempts. Please try again later',
        'network-request-failed' => 'No internet connection. Please try again',
        _ => 'Could not send reset email. Please try again',
      };
      _showError(message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
              child: const Center(child: PoolxAuthLogo()),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Heading ───────────────────────────────────────
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome\n',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'Back!',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter Your credentials to access your account',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Email Field ───────────────────────────────────
                    _buildField(
                      controller: _emailController,
                      hint: 'Enter your email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    // ── Password Field ────────────────────────────────
                    _buildField(
                      controller: _passwordController,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _forgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Sign In Button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          disabledBackgroundColor:
                              AppColors.primary.withAlpha(153),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'New to PoolX? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VendorSignUpScreen(),
                              ),
                            ),
                            child: const Text(
                              'Sign Up as a PoolX Partner',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable Field ───────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: TextField(
        cursorColor: AppColors.primary,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffixIcon,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

Future<Widget?> partnerHomeFor(String uid) async {
  final vendorDoc =
      await FirebaseFirestore.instance.collection('vendors').doc(uid).get();
  final data = vendorDoc.data() ?? {};
  final profileStep = data['profile_step'] as String? ?? '';
  final approval = (data['approval_status'] as String? ?? '').toLowerCase();
  if (profileStep == 'fleet_complete' || profileStep == 'profile_complete') {
    return const PartnerShell();
  }
  if (profileStep == 'submitted') {
    return approval == 'approved' ? const PartnerShell() : null;
  }
  if (profileStep == 'documents_complete') {
    return const VendorPaymentOptionScreen();
  }
  if (profileStep == 'business_info_complete') {
    return const VendorDocumentsScreen();
  }
  return const VendorBusinessInfoScreen();
}
