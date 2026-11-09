// // lib/screens/vendor_business_info_screen.dart
// import 'dart:ui' as BorderType;

// import 'package:poolx_partner/supabase_service.dart';
// import 'package:flutter/material.dart';
// import '../app_colors.dart';
// import 'vendor_vehicle_fleet_screen.dart';

// class VendorBusinessInfoScreen extends StatefulWidget {
//   const VendorBusinessInfoScreen({super.key});

//   @override
//   State<VendorBusinessInfoScreen> createState() => _VendorBusinessInfoScreenState();
// }

// class _VendorBusinessInfoScreenState extends State<VendorBusinessInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _businessNameController = TextEditingController();
//   final _businessAddressController = TextEditingController();
//   final _contactNumberController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _taxIdController = TextEditingController();
//   String? _selectedBusinessType;
//   bool _businessTypeTouched = false;
//   final _supabaseService = SupabaseService();

//   final List<String> _businessTypes = [
//     'Transportation Company',
//     'Car Rental Service',
//     'Tour Operator',
//     'Private Charter',
//     'Corporate Transport',
//   ];

//   @override
//   void dispose() {
//     _businessNameController.dispose();
//     _businessAddressController.dispose();
//     _contactNumberController.dispose();
//     _emailController.dispose();
//     _taxIdController.dispose();
//     super.dispose();
//   }

//   void _showBusinessTypeBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(24),
//               topRight: Radius.circular(24),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 12),
//               // Drag handle
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Title
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 24),
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     'Select Business Type',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Divider(height: 1),
//               // Options list
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _businessTypes.length,
//                 separatorBuilder: (_, __) => const Divider(
//                   height: 1,
//                   indent: 24,
//                   endIndent: 24,
//                 ),
//                 itemBuilder: (context, index) {
//                   final type = _businessTypes[index];
//                   final isSelected = _selectedBusinessType == type;
//                   return InkWell(
//                     onTap: () {
//                       setState(() {
//                         _selectedBusinessType = type;
//                         _businessTypeTouched = true;
//                       });
//                       Navigator.pop(context);
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 16,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             type,
//                             style: TextStyle(
//                               fontSize: 15,
//                               color: isSelected
//                                   ? AppColors.primary
//                                   : AppColors.textPrimary,
//                               fontWeight: isSelected
//                                   ? FontWeight.w600
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                           if (isSelected)
//                             const Icon(
//                               Icons.check_circle,
//                               color: AppColors.primary,
//                               size: 20,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//         titleSpacing: 0,
//              backgroundColor: Color(0xFFF9FAFB),
//         elevation: 0,
//         shape: const Border(
//           bottom: BorderSide(
//             color: Color.fromARGB(255, 179, 178, 178),
//             width: 1,
//           ),
//         ),
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: Color.fromRGBO(230, 231, 242, 1),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: const Icon(
//               Icons.arrow_back_ios_new,
//               color: AppColors.textPrimary,
//               size: 16,
//             ),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
       
//         title: const Text(
//           'Vendor Profile Setup',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(24),
//           children: [
//             const Text(
//               'Business Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.primary,
//               ),
//             ),
//             const Divider(),
//             const SizedBox(height: 32),
//             _buildTextField(
//               label: 'Business Name',
//               hint: 'Enter your business name',
//               controller: _businessNameController,
//             ),
//             const SizedBox(height: 20),
//             _buildBusinessTypePicker(),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Business Address',
//               hint: 'Enter your business address',
//               controller: _businessAddressController,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Contact Number',
//               hint: 'Enter contact number',
//               controller: _contactNumberController,
//               keyboardType: TextInputType.phone,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Email Address',
//               hint: 'Enter email address',
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Tax ID / Registration Number',
//               hint: 'Enter tax ID / registration number',
//               controller: _taxIdController,
//             ),
//             const SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   setState(() {
//                     _businessTypeTouched = true;
//                   });
//                   if (_formKey.currentState?.validate() ?? false) {
//                     if (_selectedBusinessType == null) return;
//                     try {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text('Saving business information...')),
//                       );

//                       // await _supabaseService.insertVendor(
//                       //   businessName: _businessNameController.text.trim(),
//                       //   businessType: _selectedBusinessType!,
//                       //   businessAddress:
//                       //       _businessAddressController.text.trim(),
//                       //   contactNumber: _contactNumberController.text.trim(),
//                       //   email: _emailController.text.trim(),
//                       //   taxId: _taxIdController.text.trim(),
//                       // );

//                       if (mounted) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 const VendorVehicleFleetScreen(),
//                           ),
//                         );
//                       }
//                     } catch (e) {
//                       if (mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Error: ${e.toString()}')),
//                         );
//                       }
//                     }
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                 ),
//                 child: const Text(
//                   'Next',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBusinessTypePicker() {
//     final hasError = _businessTypeTouched && _selectedBusinessType == null;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Business Type',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: _showBusinessTypeBottomSheet,
//           child: Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             decoration: BoxDecoration(
//               color: Colors.transparent,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: hasError ? AppColors.error : Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _selectedBusinessType ?? 'Select business type',
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: _selectedBusinessType != null
//                         ? AppColors.textPrimary
//                         : AppColors.textSecondary,
//                   ),
//                 ),
//                 const Icon(
//                   Icons.keyboard_arrow_down,
//                   color: AppColors.textSecondary,
//                   size: 22,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (hasError) ...[
//           const SizedBox(height: 6),
//           const Text(
//             'Please select a business type',
//             style: TextStyle(
//               fontSize: 12,
//               color: AppColors.error,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//             cursorColor: AppColors.primary,
//           controller: controller,
//           keyboardType: keyboardType,
//           style: const TextStyle(
//             fontSize: 15,
//             color: AppColors.textPrimary,
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(
//               fontSize: 15,
//               color: AppColors.textSecondary,
//             ),
//             filled: true,
//             fillColor: Colors.transparent,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: AppColors.primary,
//                 width: 1.5,
//               ),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: AppColors.error,
//                 width: 1,
//               ),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: AppColors.error,
//                 width: 1.5,
//               ),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'This field is required';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import 'vendor_vehicle_fleet_screen.dart';
import '../shared/app_log.dart';

class VendorBusinessInfoScreen extends StatefulWidget {
  const VendorBusinessInfoScreen({super.key});

  @override
  State<VendorBusinessInfoScreen> createState() =>
      _VendorBusinessInfoScreenState();
}

class _VendorBusinessInfoScreenState
    extends State<VendorBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();
  String? _selectedBusinessType;
  bool _businessTypeTouched = false;
  bool _isSaving = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final List<String> _businessTypes = [
    'Transportation Company',
    'Car Rental Service',
    'Tour Operator',
    'Private Charter',
    'Corporate Transport',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromFirestore();
  }

  // ── Pre-fill if vendor doc already exists ─────────────────────────────
  Future<void> _prefillFromFirestore() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final doc =
          await _firestore.collection('vendors').doc(uid).get();
      final data = doc.data();
      if (data == null || !mounted) return;
      setState(() {
        if ((data['business_name'] as String? ?? '').isNotEmpty)
          _businessNameController.text = data['business_name'];
        if ((data['business_address'] as String? ?? '').isNotEmpty)
          _businessAddressController.text = data['business_address'];
        if ((data['contact_number'] as String? ?? '').isNotEmpty)
          _contactNumberController.text = data['contact_number'];
        if ((data['email'] as String? ?? '').isNotEmpty)
          _emailController.text = data['email'];
        if ((data['tax_id'] as String? ?? '').isNotEmpty)
          _taxIdController.text = data['tax_id'];
        if ((data['business_type'] as String? ?? '').isNotEmpty)
          _selectedBusinessType = data['business_type'];
      });
    } catch (e, st) { AppLog.caught('lib/vendor/vendor_business_info_screen.dart:525', e, st); }
  }

  // ── Save to Firestore vendors/{uid} ───────────────────────────────────
  Future<void> _saveAndNext() async {
    setState(() => _businessTypeTouched = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBusinessType == null) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _showSnack('Not logged in');
        setState(() => _isSaving = false);
        return;
      }

      // upsert — create if not exists, update if exists
      await _firestore.collection('vendors').doc(uid).set({
        'firebase_uid': uid,
        'business_name': _businessNameController.text.trim(),
        'business_type': _selectedBusinessType,
        'business_address': _businessAddressController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'tax_id': _taxIdController.text.trim(),
        'approval_status': 'pending',
        'profile_step': 'business_info_complete',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VendorVehicleFleetScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Error saving: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBusinessTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Business Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _businessTypes.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, indent: 24, endIndent: 24),
              itemBuilder: (context, index) {
                final type = _businessTypes[index];
                final isSelected = _selectedBusinessType == type;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBusinessType = type;
                      _businessTypeTouched = true;
                    });
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 179, 178, 178),
            width: 1,
          ),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Business Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 32),
            _buildTextField(
              label: 'Business Name',
              hint: 'Enter your business name',
              controller: _businessNameController,
            ),
            const SizedBox(height: 20),
            _buildBusinessTypePicker(),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Business Address',
              hint: 'Enter your business address',
              controller: _businessAddressController,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Contact Number',
              hint: 'Enter contact number',
              controller: _contactNumberController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Email Address',
              hint: 'Enter email address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Tax ID / Registration Number',
              hint: 'Enter tax ID / registration number',
              controller: _taxIdController,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAndNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Next',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTypePicker() {
    final hasError =
        _businessTypeTouched && _selectedBusinessType == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Type',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showBusinessTypeBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedBusinessType ?? 'Select business type',
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedBusinessType != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary, size: 22),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          const Text('Please select a business type',
              style: TextStyle(
                  fontSize: 12, color: AppColors.error)),
        ],
      ],
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
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          cursorColor: AppColors.primary,
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.5)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
}