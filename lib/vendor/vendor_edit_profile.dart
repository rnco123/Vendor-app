// import 'package:poolx_partner/app_colors.dart';
// import 'package:flutter/material.dart';

// class vendorEditProfileScreen extends StatefulWidget {
//   const vendorEditProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<vendorEditProfileScreen> createState() => _vendorEditProfileScreenState();
// }

// class _vendorEditProfileScreenState extends State<vendorEditProfileScreen> {
//   final TextEditingController _nameController = TextEditingController(text: 'Waqar Khan');
//   final TextEditingController _dobController = TextEditingController(text: '01/02/1990');
//   final TextEditingController _phoneController = TextEditingController(text: '+92 1234 5678');
//   String _selectedGender = 'Male';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//            backgroundColor: Color(0xFFF9FAFB),
//         elevation: 0,
//            titleSpacing: 0,
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
//           'Edit Profile',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             // Profile Picture with Edit Icon
//             Stack(
//                 children: [
//                   Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEBEBEB),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.person_outline,
//                       size: 48,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: BoxDecoration(
//                         color: AppColors.primary,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 3),
//                       ),
//                       child: const Icon(
//                         Icons.add,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
            
//             const SizedBox(height: 40),

//             // Full Name
//             _buildTextField(
//               label: 'Full Name',
//               controller: _nameController,
//             ),
//             const SizedBox(height: 20),

//             // Date of Birth
//             _buildTextField(
//               label: 'Date of Birth',
//               controller: _dobController,
//               suffixIcon: Icons.calendar_today_outlined,
//               readOnly: true,
//               onTap: () async {
//                 final date = await showDatePicker(
//                   context: context,
//                   initialDate: DateTime(1990, 2, 1),
//                   firstDate: DateTime(1950),
//                   lastDate: DateTime.now(),
//                   builder: (context, child) {
//                     return Theme(
//                       data: Theme.of(context).copyWith(
//                         colorScheme: const ColorScheme.light(
//                           primary: AppColors.primary,
//                         ),
//                       ),
//                       child: child!,
//                     );
//                   },
//                 );
//                 if (date != null) {
//                   _dobController.text =
//                       '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//                 }
//               },
//             ),
//             const SizedBox(height: 20),

//             // Gender
//             _buildDropdownField(
//               label: 'Gender',
//               value: _selectedGender,
//               items: ['Male', 'Female', 'Other'],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedGender = value!;
//                 });
//               },
//             ),
//             const SizedBox(height: 20),

//             // Phone number
//             _buildTextField(
//               label: 'Phone number',
//               controller: _phoneController,
//               keyboardType: TextInputType.phone,
//             ),
//             const SizedBox(height: 40),

//             // Update Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text(
//                   'Update',
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

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     IconData? suffixIcon,
//     bool readOnly = false,
//     VoidCallback? onTap,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//             cursorColor: AppColors.primary,
//           controller: controller,
//           readOnly: readOnly,
//           onTap: onTap,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: const Color(0xFFF9FAFB),
//             suffixIcon: suffixIcon != null
//                 ? Icon(suffixIcon, color: AppColors.textSecondary, size: 20)
//                 : null,
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: Color(0xFFE8E8E8),
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
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: Color(0xFFE8E8E8),
//                 width: 1,
//               ),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//           ),
//           style: const TextStyle(
//             fontSize: 16,
//             color: AppColors.textPrimary,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField({
//     required String label,
//     required String value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF9FAFB),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: const Color(0xFFE8E8E8),
//               width: 1,
//             ),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: value,
//               isExpanded: true,
//               icon: const Icon(
//                 Icons.keyboard_arrow_down,
//                 color: AppColors.textSecondary,
//               ),
//               dropdownColor: Colors.white,
//               style: const TextStyle(
//                 color: AppColors.textPrimary,
//                 fontSize: 16,
//               ),
//               items: items.map((String item) {
//                 return DropdownMenuItem<String>(
//                   value: item,
//                   child: Text(item),
//                 );
//               }).toList(),
//               onChanged: onChanged,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _dobController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
// }
