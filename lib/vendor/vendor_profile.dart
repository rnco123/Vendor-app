// // lib/screens/vendor_profile_screen.dart
// import 'dart:ui' as BorderType;

// import 'package:poolx_partner/vendor/vendor_drawer.dart';
// import 'package:poolx_partner/vendor/vendor_edit_profile.dart';
// import 'package:poolx_partner/vendor/vendor_help_support_screen.dart';
// import 'package:poolx_partner/vendor/vendor_notification.dart';
// import 'package:flutter/material.dart';
// import '../app_colors.dart';


// class VendorProfileScreen extends StatelessWidget {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   VendorProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//          key: _scaffoldKey,
//       backgroundColor: const Color(0xFFF9FAFB),
//  appBar: AppBar(
//          titleSpacing: 0,
//           backgroundColor:  Color(0xFFF9FAFB),
//         elevation: 0, // 👈 Add elevation

   
   
//    shape: const Border(
//     bottom: BorderSide(
//       color: BorderType.Color.fromARGB(255, 179, 178, 178),   // change to AppColors.primary if needed
//       width: 1,
//     ),
//   ),
  
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: AppColors.textPrimary),
//           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//         ),
        
//         title: const Text(
//           'Carpool',
//           style: TextStyle(
//             color: AppColors.primary,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: CircleAvatar(
//               backgroundColor: AppColors.primary,
//               child: const Icon(Icons.person, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//       drawer: const VendorDrawer(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             // Profile Header
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFEBEBEB),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.person,
//                 size: 60,
//                 color: AppColors.primary,
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Urban Rides',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.primary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               '0321 1234 567',
//               style: TextStyle(
//                 fontSize: 15,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Menu Options
//             _buildMenuItem(
//               context,
//               icon: Icons.edit_outlined,
//               title: 'Edit Profile',
//               onTap: () {
//                  Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>  vendorEditProfileScreen(),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 1),
//             _buildMenuItem(
//               context,
//               icon: Icons.credit_card_outlined,
//               title: 'Payment & Withdrawals',
//               onTap: () {},
//             ),
//             const SizedBox(height: 1),
//             _buildMenuItem(
//               context,
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>  VendorHelpSupportScreen(),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 1),
//             _buildMenuItem(
//               context,
//               icon: Icons.notifications_outlined,
//               title: 'Notification Settings',
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>  VendorNotificationSettingsScreen(),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF9FAFB),
//         border: Border(
//           bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//         ),
//       ),
//       child: ListTile(
//         leading: Icon(
//           icon,
//           color: AppColors.primary,
//           size: 24,
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 16,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         trailing: const Icon(
//           Icons.chevron_right,
//           color: AppColors.textSecondary,
//         ),
//         onTap: onTap,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//     );
//   }
// }