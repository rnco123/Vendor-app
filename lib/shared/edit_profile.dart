import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import 'manage_security_screen.dart';
import 'profile_image_service.dart';
import '../shared/app_log.dart';
import 'phone_utils.dart';

/// Edit profile for passenger, driver, or vendor — loads/saves the correct Firestore collection.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  String _role = '';
  String _selectedGender = '';
  String _email = '';
  String? _profileImageUrl;
  File? _pendingImageFile;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  String get _collection {
    switch (_role) {
      case 'driver':
        return 'drivers';
      case 'vendor':
        return 'vendors';
      default:
        return 'passengers';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _occupationCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final role = userData['role'] as String? ?? 'passenger';

      final profileDoc =
          await _firestore.collection(_collectionForRole(role)).doc(uid).get();
      final d = profileDoc.data() ?? {};

      setState(() {
        _role = role;
        _nameCtrl.text = d['full_name'] as String? ?? '';
        _dobCtrl.text = d['date_of_birth'] as String? ?? '';
        _occupationCtrl.text = d['occupation'] as String? ?? '';
        _bioCtrl.text = d['bio'] as String? ?? '';
        _phoneCtrl.text = d['phone_number'] as String? ?? '';
        _cityCtrl.text = d['city'] as String? ?? '';
        _selectedGender = d['gender'] as String? ?? '';
        final emergency = d['emergency_contact'];
        _emergencyNameCtrl.text = emergency is Map
            ? (emergency['name'] ?? '').toString().trim()
            : '';
        _emergencyPhoneCtrl.text = emergency is Map
            ? (emergency['phone'] ?? '').toString().trim()
            : '';
        _profileImageUrl = profileImageUrlFrom(d);
        _email = _auth.currentUser?.email?.trim() ??
            (userData['email'] as String?)?.trim() ??
            (d['email'] as String?)?.trim() ??
            '';
        _loading = false;
      });
    } catch (e, st) { AppLog.caught('lib/shared/edit_profile.dart', e, st); setState(() => _loading = false); }
  }

  String _collectionForRole(String role) {
    switch (role) {
      case 'driver':
        return 'drivers';
      case 'vendor':
        return 'vendors';
      default:
        return 'passengers';
    }
  }

  Future<void> _pickProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _role.isEmpty) return;

    final file = await pickProfileImageFile();
    if (file == null) return;

    setState(() {
      _pendingImageFile = file;
      _uploadingPhoto = true;
    });

    try {
      final url = await uploadProfileImage(
        role: _role,
        uid: uid,
        file: file,
      );
      await _firestore.collection(_collection).doc(uid).set(
        {
          'profile_image_url': url,
          'profile_updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() {
          _profileImageUrl = url;
          _pendingImageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profilePhotoUploadErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _role.isEmpty) return;

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    final emergencyName = _emergencyNameCtrl.text.trim();
    final emergencyPhone = _emergencyPhoneCtrl.text.trim();
    if (_role == 'passenger') {
      String? emergencyError;
      if (emergencyName.isEmpty || emergencyPhone.isEmpty) {
        emergencyError = 'Please add your emergency contact name and phone';
      } else if (!RegExp(r'^03\d{9}$').hasMatch(emergencyPhone)) {
        emergencyError =
            'Enter a valid emergency contact number like 03XXXXXXXXX';
      } else if (samePhoneNumber(
            _phoneCtrl.text.trim().isNotEmpty
                ? _phoneCtrl.text.trim()
                : _auth.currentUser?.phoneNumber,
            emergencyPhone,
          )) {
        emergencyError = kEmergencySameAsOwnError;
      }
      if (emergencyError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emergencyError)),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim(),
        'gender': _selectedGender,
        'profile_updated_at': FieldValue.serverTimestamp(),
      };

      if (_role != 'passenger') {
        data['bio'] = _bioCtrl.text.trim();
      }

      if (_role == 'driver') {
        data['phone_number'] = _phoneCtrl.text.trim();
        data['city'] = _cityCtrl.text.trim();
      } else if (_role == 'passenger') {
        data['occupation'] = _occupationCtrl.text.trim();
        data['emergency_contact'] = {
          'name': emergencyName,
          'phone': emergencyPhone,
        };
      }

      await _firestore.collection(_collection).doc(uid).set(
            data,
            SetOptions(merge: true),
          );

      await _firestore.collection('users').doc(uid).set(
        {'full_name': _nameCtrl.text.trim()},
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.cardBackground,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _showGenderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...['Male', 'Female', 'Other'].map(
              (g) => Column(
                children: [
                  ListTile(
                    title: Text(g,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textPrimary)),
                    trailing: _selectedGender == g
                        ? const Icon(Icons.check,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      setState(() => _selectedGender = g);
                      Navigator.pop(context);
                    },
                  ),
                  if (g != 'Other')
                    const Divider(height: 1, color: AppColors.divider),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_pendingImageFile != null) {
      imageProvider = FileImage(_pendingImageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickProfilePhoto,
        child: Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                  : null,
            ),
            if (_uploadingPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 18),
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 1)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap photo to change',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _label('Full Name'),
                    const SizedBox(height: 8),
                    _field(controller: _nameCtrl, hint: 'Enter your full name'),
                    if (_role != 'passenger') ...[
                      const SizedBox(height: 20),
                      _label('Email Address'),
                      const SizedBox(height: 8),
                      _readOnlyField(
                          _email.isEmpty ? 'No email on file' : _email),
                    ],
                    if (_role == 'driver') ...[
                      const SizedBox(height: 20),
                      _label('Phone Number'),
                      const SizedBox(height: 8),
                      _field(
                          controller: _phoneCtrl,
                          hint: 'Enter phone number',
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      _label('City'),
                      const SizedBox(height: 8),
                      _field(controller: _cityCtrl, hint: 'e.g. Karachi'),
                    ],
                    const SizedBox(height: 20),
                    _label('Date of Birth'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _field(
                          controller: _dobCtrl,
                          hint: 'MM/DD/YYYY',
                          suffixIcon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Gender'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showGenderSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedGender.isEmpty
                                    ? 'Select your gender'
                                    : _selectedGender,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedGender.isEmpty
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    if (_role == 'passenger') ...[
                      const SizedBox(height: 20),
                      _label('Occupation'),
                      const SizedBox(height: 8),
                      _field(
                          controller: _occupationCtrl,
                          hint: 'e.g. Student, Engineer'),
                      const SizedBox(height: 28),
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'We will alert this person if you use SOS during a ride',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Contact Name'),
                      const SizedBox(height: 8),
                      _field(
                          controller: _emergencyNameCtrl,
                          hint: 'Enter contact name'),
                      const SizedBox(height: 20),
                      _label('Contact Phone'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _emergencyPhoneCtrl,
                        hint: '03XXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                    ],
                    if (_role != 'passenger') ...[
                      const SizedBox(height: 20),
                      _label('Bio (optional)'),
                      const SizedBox(height: 8),
                      _field(
                          controller: _bioCtrl,
                          hint: 'Tell us a bit about yourself',
                          maxLines: 3),
                      const SizedBox(height: 24),
                      _securityTile(),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Update',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary));

  Widget _securityTile() {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ManageSecurityScreen(currentEmail: _email),
            ),
          );
          if (!mounted) return;
          await _loadProfile();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Security',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Change password or email',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          color: value == 'No email on file'
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 15),
        filled: true,
        fillColor: AppColors.cardBackground,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppColors.textSecondary, size: 18)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
    );
  }
}
