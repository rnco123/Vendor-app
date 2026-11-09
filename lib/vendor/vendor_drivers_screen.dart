// lib/screens/vendor_drivers_screen.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_colors.dart';
import 'vendor_success_screen.dart';
import '../shared/app_log.dart';

class VendorDriversScreen extends StatefulWidget {
  const VendorDriversScreen({super.key});

  @override
  State<VendorDriversScreen> createState() => _VendorDriversScreenState();
}

class _VendorDriversScreenState extends State<VendorDriversScreen> {
  final List<DriverData> _drivers = [];
  bool _isSubmitting = false;

  void _addDriver() {
    setState(() {
      _drivers.add(DriverData());
    });
  }

  void _removeDriver(int index) {
    setState(() {
      _drivers[index].dispose();
      _drivers.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _addDriver();
  }

  @override
  void dispose() {
    for (final d in _drivers) {
      d.dispose();
    }
    super.dispose();
  }

  // ─── Generates a simple password: Name + 4-digit random number ───────────
  String _generatePassword(String fullName) {
    final base = fullName.trim().replaceAll(' ', '').toLowerCase();
    final suffix = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return '${base}@$suffix';
  }

  // ─── Send credentials email via SMTP ─────────────────────────────────────
  // Replace smtpUsername / smtpPassword with your real SMTP credentials,
  // or swap for any other mailer package / Firebase Extension you prefer.
Future<void> _sendCredentialsEmail({
  required String toEmail,
  required String driverName,
  required String password,
}) async {
  try {
    await FirebaseFirestore.instance.collection('mail').add({
      'to': toEmail,
      'message': {
        'subject': 'Your Driver Account Credentials',
        'text': '''
Hello $driverName,

Your driver account has been created by your vendor.

Login Email : $toEmail
Password    : $password

Please sign in to the Driver App and change your password after first login.

Best regards,
Vendor App Team
''',
      },
    });
    debugPrint('Credentials email queued for $toEmail');
  } catch (e) {
    debugPrint('Email queue failed: $e');
  }
}
  // ─── Core submit logic ────────────────────────────────────────────────────
  Future<void> _submitProfile() async {
    // Basic validation
    for (int i = 0; i < _drivers.length; i++) {
      final d = _drivers[i];
      if (d.nameController.text.trim().isEmpty ||
          d.emailController.text.trim().isEmpty ||
          d.licenseController.text.trim().isEmpty ||
          d.phoneController.text.trim().isEmpty) {
        _showError('Please fill all required fields for Driver ${i + 1}.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current vendor's UID & secondary FirebaseAuth instance so we
      // don't accidentally sign the vendor out while creating driver accounts.
      final vendorUid = FirebaseAuth.instance.currentUser?.uid;
      if (vendorUid == null) throw Exception('Vendor not signed in.');

      // Secondary app to create driver accounts without disturbing the vendor session
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('driverCreation');
      } catch (e, st) { AppLog.caught('lib/vendor/vendor_drivers_screen.dart', e, st); secondaryApp = await Firebase.initializeApp(
          name: 'driverCreation',
          options: Firebase.app().options,
        ); }
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      for (final driver in _drivers) {
        final email    = driver.emailController.text.trim();
        final fullName = driver.nameController.text.trim();
        final password = _generatePassword(fullName);

        // 1. Create Firebase Auth account for the driver
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final driverUid = credential.user!.uid;

        // 2. Write to `users` collection (mirrors your existing user schema)
        await FirebaseFirestore.instance.collection('users').doc(driverUid).set({
          'firebase_uid'       : driverUid,
          'vendor_id'          : vendorUid,          // ← links driver to vendor
          'full_name'          : fullName,
          'email'              : email,
          'phone_number'       : driver.phoneController.text.trim(),
          'license_number'     : driver.licenseController.text.trim(),
          'years_of_experience': driver.experienceController.text.trim(),
          'background_check'   : driver.backgroundCheck,
          'role'               : 'driver',
          'status'             : 'active',
          'profile_complete'   : false,
          'documents_submitted': false,
          'is_available'       : false,
          'average_rating'     : 0,
          'total_rides'        : 0,
          'approval_status'    : 'pending',
          'created_at'         : FieldValue.serverTimestamp(),
          'documents': {
            'license'     : false,
            'registration': false,
            'insurance'   : false,
          },
          'availability': {
            'days_of_week'        : '',
            'preferred_route_from': '',
            'preferred_route_to'  : '',
          },
        });

        // 3. Also write to `drivers` collection (mirrors your existing driver schema)
        await FirebaseFirestore.instance.collection('drivers').doc(driverUid).set({
          'firebase_uid'    : driverUid,
          'vendor_id'       : vendorUid,
          'approval_status' : 'approved',
          'is_available'    : false,
          'updated_at'      : FieldValue.serverTimestamp(),
          'availability': {
            'days_of_week'        : '',
            'preferred_route_from': '',
            'preferred_route_to'  : '',
          },
        });

        // 4. Send credentials to the driver's email
        await _sendCredentialsEmail(
          toEmail    : email,
          driverName : fullName,
          password   : password,
        );
      }

      // Sign out secondary app session (cleanup)
      await secondaryAuth.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Submission failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(
          bottom: BorderSide(color: Color.fromARGB(255, 179, 178, 178), width: 1),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(230, 231, 242, 1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vendor Profile Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Drivers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  onPressed: _addDriver,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 32),
          ..._drivers.asMap().entries.map((entry) {
            return _buildDriverCard(entry.key, entry.value);
          }),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Submit Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(int index, DriverData driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textPrimary),
                  onPressed: () => _removeDriver(index),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Fields ───────────────────────────────────────────────────────
          _buildTextField(
            label: 'Full Name',
            hint: "Enter driver's full name",
            controller: driver.nameController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',           // ← NEW field for login email
            hint: "Enter driver's email",
            controller: driver.emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Driver's License Number",
            hint: 'Enter license number',
            controller: driver.licenseController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            hint: 'Enter phone number',
            controller: driver.phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Years of Experience',
            hint: 'Enter years of experience',
            controller: driver.experienceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // ── Background check toggle ──────────────────────────────────────
          InkWell(
            onTap: () {
              setState(() {
                driver.backgroundCheck = !driver.backgroundCheck;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: driver.backgroundCheck
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: driver.backgroundCheck
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: driver.backgroundCheck
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Background check completed',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────
class DriverData {
  final TextEditingController nameController       = TextEditingController();
  final TextEditingController emailController      = TextEditingController(); // ← NEW
  final TextEditingController licenseController    = TextEditingController();
  final TextEditingController phoneController      = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  bool backgroundCheck = false;

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    licenseController.dispose();
    phoneController.dispose();
    experienceController.dispose();
  }
}