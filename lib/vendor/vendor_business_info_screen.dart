import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../shared/app_log.dart';
import '../shared/network_check.dart';
import '../shared/profile_image_service.dart';
import 'vendor_documents_screen.dart';
import 'vendor_ui.dart';

class VendorBusinessInfoScreen extends StatefulWidget {
  const VendorBusinessInfoScreen({super.key});

  @override
  State<VendorBusinessInfoScreen> createState() =>
      _VendorBusinessInfoScreenState();
}

class _VendorBusinessInfoScreenState extends State<VendorBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _typeController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  File? _logoFile;
  String? _logoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _typeController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final db = FirebaseFirestore.instance;
      final vendor = (await db.collection('vendors').doc(uid).get()).data();
      final user = (await db.collection('users').doc(uid).get()).data();
      if (!mounted) return;
      String pick(String key, [String? alt]) {
        final v = vendor?[key] as String?;
        if (v != null && v.trim().isNotEmpty) return v;
        return (user?[alt ?? key] as String?) ?? '';
      }

      setState(() {
        _companyController.text = pick('business_name');
        _typeController.text = pick('business_type');
        _taxIdController.text = pick('tax_id');
        _addressController.text = pick('business_address');
        _contactController.text = pick('contact_number', 'phone_number');
        _emailController.text = pick('email');
        _logoUrl = profileImageUrlFrom(vendor);
      });
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_business_info_screen.dart:prefill', e, st);
    }
  }

  Future<void> _pickLogo() async {
    final file = await pickProfileImageFile();
    if (file == null || !mounted) return;
    setState(() => _logoFile = file);
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showVendorSnack(context, 'Session expired. Please sign in again.');
      return;
    }
    if (!await hasInternet()) {
      if (mounted) showVendorSnack(context, offlineMessage);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'business_name': _companyController.text.trim(),
        'business_type': _typeController.text.trim(),
        'tax_id': _taxIdController.text.trim(),
        'business_address': _addressController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'approval_status': 'pending',
        'profile_step': 'business_info_complete',
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (_logoFile != null) {
        try {
          final url = await uploadProfileImage(
            role: 'vendor',
            uid: uid,
            file: _logoFile!,
          );
          data['profile_image_url'] = url;
          _logoUrl = url;
        } catch (e, st) {
          AppLog.caught('lib/vendor/vendor_business_info_screen.dart:logo', e, st);
          if (mounted) {
            showVendorSnack(context, profilePhotoUploadErrorMessage(e));
          }
          setState(() => _saving = false);
          return;
        }
      }
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorDocumentsScreen()),
      );
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_business_info_screen.dart:save', e, st);
      if (mounted) {
        showVendorSnack(context, 'Could not save your details. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emailValidator(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'This field is required';
    if (!t.contains('@') || !t.contains('.')) return 'Enter a valid email';
    return null;
  }

  Widget _logoPicker() {
    ImageProvider? image;
    if (_logoFile != null) {
      image = FileImage(_logoFile!);
    } else if (_logoUrl != null) {
      image = NetworkImage(_logoUrl!);
    }
    return Center(
      child: GestureDetector(
        onTap: _saving ? null : _pickLogo,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                  image: image != null
                      ? DecorationImage(image: image, fit: BoxFit.cover)
                      : null,
                ),
                child: image == null
                    ? const Icon(
                        Icons.business_outlined,
                        color: AppColors.primary,
                        size: 36,
                      )
                    : null,
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: vendorSetupAppBar(context, 'Vendor Profile Setup'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VendorSetupHeading(
                        title: 'Business Information',
                        subtitle: 'Enter your business Information.',
                      ),
                      const SizedBox(height: 24),
                      _logoPicker(),
                      const SizedBox(height: 24),
                      VendorLabeledField(
                        label: 'Company Name',
                        hint: 'Enter your business name',
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      VendorLabeledField(
                        label: 'Business Type',
                        hint: 'Enter business type',
                        controller: _typeController,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      VendorLabeledField(
                        label: 'Registration / NTN no.',
                        hint: 'Enter tax ID / registration number',
                        controller: _taxIdController,
                      ),
                      const SizedBox(height: 16),
                      VendorLabeledField(
                        label: 'Business Address',
                        hint: 'Enter your business address',
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      VendorLabeledField(
                        label: 'Contact Number',
                        hint: 'Enter contact number',
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      VendorLabeledField(
                        label: 'Email Address',
                        hint: 'Enter email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: VendorPrimaryButton(
                  label: 'Next',
                  loading: _saving,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
