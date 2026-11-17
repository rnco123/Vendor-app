import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'shared/app_log.dart';
import 'shared/network_check.dart';
import 'shared/poolx_logo.dart';
import 'vendor/vendor_business_info_screen.dart';

class VendorSignUpScreen extends StatefulWidget {
  const VendorSignUpScreen({super.key});

  @override
  State<VendorSignUpScreen> createState() => _VendorSignUpScreenState();
}

class _VendorSignUpScreenState extends State<VendorSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static final _pwdLower = RegExp(r'[a-z]');
  static final _pwdUpper = RegExp(r'[A-Z]');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _pkMobileDigits(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('92')) d = d.substring(2);
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  String? _validatePkMobile(String? value) {
    final d = _pkMobileDigits(value ?? '');
    if (d.isEmpty) return 'Please enter your phone number';
    if (d.length != 10) return 'Enter 10 digits (3 + 9 after +92)';
    if (!d.startsWith('3')) return 'Mobile must start with 3';
    return null;
  }

  String _phoneE164() => '+92${_pkMobileDigits(_phoneController.text)}';

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!_pwdLower.hasMatch(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!_pwdUpper.hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await hasInternet()) {
      _showSnack(offlineMessage);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = credential.user!.uid;
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneE164();

      await _firestore.collection('users').doc(uid).set({
        'firebase_uid': uid,
        'full_name': name,
        'email': email,
        'phone_number': phone,
        'role': 'vendor',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('vendors').doc(uid).set({
        'firebase_uid': uid,
        'full_name': name,
        'email': email,
        'contact_number': phone,
        'approval_status': 'pending',
        'profile_step': 'signup',
        'created_at': FieldValue.serverTimestamp(),
      });

      try {
        await Future<void>.delayed(const Duration(seconds: 2));
        await credential.user?.getIdToken(true);
      } catch (e, st) {
        AppLog.caught('lib/vendor_sign_up_screen.dart:getIdToken', e, st);
      }

      if (!mounted) return;
      _showSnack('Account created successfully!', success: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VendorBusinessInfoScreen()),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'This email is already registered',
        'invalid-email' => 'Invalid email address',
        'weak-password' => 'Password is too weak',
        _ => e.message ?? 'An error occurred',
      };
      _showSnack(message);
    } catch (e, st) {
      AppLog.caught('lib/vendor_sign_up_screen.dart:signUp', e, st);
      try {
        await _auth.currentUser?.delete();
      } catch (cleanupErr, st2) {
        AppLog.caught('lib/vendor_sign_up_screen.dart:cleanup', cleanupErr, st2);
      }
      _showSnack('Could not create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToSignIn() => Navigator.maybePop(context);

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).height -
        MediaQuery.viewPaddingOf(context).vertical;
    final t = ((available - 672) / 117).clamp(0.0, 1.0);
    double gap(double min, double max) => min + (max - min) * t;
    final fieldGap = gap(10, 22);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: PoolxAuthLogo()),
                SizedBox(height: gap(12, 30)),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hello\n',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'there!',
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
                const Text(
                  'Enter Your credentials to access your account',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                SizedBox(height: gap(16, 35)),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: fieldGap),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldGap),
                _buildPhoneField(),
                SizedBox(height: fieldGap),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Create Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: _eye(
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: _validatePassword,
                ),
                SizedBox(height: fieldGap),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'Re-type your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: _eye(
                    _obscureConfirmPassword,
                    () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: gap(32, 64)),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      disabledBackgroundColor: AppColors.primary.withAlpha(153),
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
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: gap(8, 12)),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _goToSignIn,
                        child: const Text(
                          'Sign In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eye(bool obscured, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }

  static const _fieldTextStyle = TextStyle(
    fontSize: 15,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  OutlineInputBorder _fieldBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldDecoration({
    required Widget prefix,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.fromLTRB(0, 13, 18, 13),
      border: _fieldBorder(AppColors.divider, 1),
      enabledBorder: _fieldBorder(AppColors.divider, 1),
      focusedBorder: _fieldBorder(AppColors.primary, 1.5),
      errorBorder: _fieldBorder(AppColors.error, 1),
      focusedErrorBorder: _fieldBorder(AppColors.error, 1.5),
    );
  }

  Widget _fieldIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Icon(icon, color: AppColors.textSecondary, size: 20),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      cursorColor: AppColors.primary,
      cursorHeight: 20,
      controller: _phoneController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: _fieldDecoration(
        prefix: Padding(
          padding: const EdgeInsets.only(left: 20, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇵🇰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 28,
                color: AppColors.textSecondary.withAlpha(90),
              ),
              const SizedBox(width: 12),
              const Text(
                '+92',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      style: _fieldTextStyle,
      validator: _validatePkMobile,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      cursorColor: AppColors.primary,
      cursorHeight: 20,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(
        prefix: _fieldIcon(icon),
        hint: hint,
        suffix: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8, right: 18),
                child: suffixIcon,
              )
            : null,
      ),
      style: _fieldTextStyle,
      validator: validator,
    );
  }
}
