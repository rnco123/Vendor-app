// import 'dart:ui' as BorderType;

// import 'package:poolx_partner/app_colors.dart';
// import 'package:poolx_partner/driver/driver_screen.dart';
// import 'package:poolx_partner/vendor/issue.dart';
// import 'package:poolx_partner/vendor/vendor_drawer.dart';
// import 'package:poolx_partner/vendor/vendor_driver_perf.dart';
// import 'package:poolx_partner/vendor/vendor_incentive.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class RideDriverManagementScreen extends StatefulWidget {
//   final int initialTab;

//   const RideDriverManagementScreen({
//     Key? key,
//     this.initialTab = 0,
//   }) : super(key: key);

//   @override
//   State<RideDriverManagementScreen> createState() =>
//       _RideDriverManagementScreenState();
// }

// class _RideDriverManagementScreenState
//     extends State<RideDriverManagementScreen> {
//   late int _selectedTab;
//       final _firestore = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;
//     String? get _vendorId => _auth.currentUser?.uid;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   void initState() {
//     super.initState();
//     _selectedTab = widget.initialTab;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: const Color(0xFFF1F1F1),
//     appBar: AppBar(
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
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Ride/Driver Management',
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             const Divider(),
//             const SizedBox(height: 24),

//             // Stats Grid - changes based on selected tab
//             _buildStatsGrid(),
//             const SizedBox(height: 24),

//             // Tab Bar
//             Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Row(
//                 children: [
//                   _buildTab('Complaints', 0),
//                   const SizedBox(width: 4),
//                   _buildTab('Drivers', 1),
//                   const SizedBox(width: 4),
//                   _buildTab('Incentives', 2),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Content based on selected tab
//             _buildTabContent(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsGrid() {
//     if (_selectedTab == 0) {
//       // Complaints tab stats - 2x2 grid with equal widths
//       return Column(
//         children: [
//           Row(
//             children: [
//               Expanded(child: _buildStatCard('63', 'Active Rides')),
//               const SizedBox(width: 16),
//               Expanded(child: _buildStatCard('24', 'Active Rides')),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(child: _buildStatCard('8', 'Pending Complaints')),
//               const SizedBox(width: 16),
//               Expanded(child: _buildStatCard('4.6/5', 'Avg. Rating')),
//             ],
//           ),
//         ],
//       );
//     } else {
//       // Drivers and Incentives tab stats - 2x2 grid with equal widths
//       return Column(
//         children: [
//           Row(
//             children: [
//               Expanded(child: _buildStatCard('12', 'Active Rides')),
//               const SizedBox(width: 16),
//               Expanded(child: _buildStatCard('\$1,245', 'Today\'s Earnings')),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(child: _buildStatCard('17', 'Available Drivers')),
//               const SizedBox(width: 16),
//               Expanded(child: _buildStatCard('4.8', 'Avg. Rating')),
//             ],
//           ),
//         ],
//       );
//     }
//   }

//   Widget _buildStatCard(String value, String label) {
//     return Container(
//       // Fixed height to ensure all cards are the same size
//       height: 120,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Use FittedBox to ensure text scales uniformly
//           FittedBox(
//             fit: BoxFit.scaleDown,
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.primary,
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 13,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(String title, int index) {
//     final isSelected = _selectedTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedTab = index),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           decoration: isSelected
//             ? BoxDecoration(
//                 color: AppColors.primary.withValues(alpha: 0.08),
//                 borderRadius: BorderRadius.circular(100),
//                 border: Border.all(
//                   color: AppColors.primary,
//                   width: 1.5,
//                 ),
//               )
//             : const BoxDecoration(),
//           child: Text(
//           title,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight:
//                 isSelected ? FontWeight.w600 : FontWeight.w400,
//             color: isSelected
//                 ? AppColors.primary
//                 : AppColors.textSecondary,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTabContent() {
//     switch (_selectedTab) {
//       case 0:
//         return _buildComplaintsContent();
//       case 1:
//         return _buildDriversContent();
//       case 2:
//         return _buildIncentivesContent();
//       default:
//         return _buildComplaintsContent();
//     }
//   }

//   Widget _buildDriversContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         LayoutBuilder(
//           builder: (context, constraints) {
//             if (constraints.maxWidth < 600) {
//               // Stack title and button vertically on small screens
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Text(
//                     'Driver Performance',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   const Divider(),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => VendorAddDriverPerformanceScreen(),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.add, size: 18),
//                       label: const Text('Add Driver perf.'),
//                       style: ElevatedButton.styleFrom(

//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             } else {
//               // Horizontal layout for larger screens
//               return Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Flexible(
//                         child: Text(
//                           'Driver Performance',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => VendorAddDriverPerformanceScreen(),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.add, size: 18),
//                         label: const Text('Add Driver perf.'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(),
//                 ],
//               );
//             }
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildDriverCard(
//           name: 'Hamza Khan',
//           driverId: 'D-1002',
//           phone: '+92 321 1234 5678',
//           trips: '78 trips',
//           rating: 4.2,
//           badge: 'Weekly Bonus',
//         ),
//         const SizedBox(height: 12),
//         _buildDriverCard(
//           name: 'Waqar Khan',
//           driverId: 'D-1004',
//           phone: '+92 321 1234 5678',
//           trips: '42 trips',
//           rating: 4.6,
//           badge: null,
//         ),
//         const SizedBox(height: 12),
//         _buildDriverCard(
//           name: 'Ali Ahmed',
//           driverId: 'D-1002',
//           phone: '+92 321 1234 5678',
//           trips: '122 trips',
//           rating: 4.8,
//           badge: 'High Util',
//         ),
//       ],
//     );
//   }

//   Widget _buildComplaintsContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Recent Issues & Complaints',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: AppColors.primary,
//           ),
//         ),
//         const Divider(),
//         const SizedBox(height: 16),
//         _buildComplaintCard(
//           title: 'Driver arrived late',
//           issueId: '#CP-1245',
//           type: 'Passenger complaint',
//           date: '12 Oct 2025',
//           status: 'Dispute',
//           statusColor: const Color(0xFFFFA726),
//           buttons: ['Escalate', 'Resolve'],
//         ),
//         const SizedBox(height: 12),
//         _buildComplaintCard(
//           title: 'Payment issue',
//           issueId: '#CP-1244',
//           type: 'Driver complaint',
//           date: '11 Oct 2025',
//           status: 'Escalate',
//           statusColor: const Color(0xFFA13D38),
//           buttons: ['Resolve'],
//         ),
//         const SizedBox(height: 12),
//         _buildComplaintCard(
//           title: 'Payment issue',
//           issueId: '#CP-1244',
//           type: 'Driver complaint',
//           date: '11 Oct 2025',
//           status: 'Pending',
//           statusColor: const Color(0xFFFFA726),
//           buttons: ['Dispute', 'Resolve'],
//         ),
//         const SizedBox(height: 12),
//         _buildComplaintCard(
//           title: 'Payment issue',
//           issueId: '#CP-1244',
//           type: 'Driver complaint',
//           date: '11 Oct 2025',
//           status: 'Resolved',
//           statusColor: const Color(0xFF4CAF50),
//           buttons: ['Details'],
//         ),
//       ],
//     );
//   }

//   Widget _buildDriverCard({
//     required String name,
//     required String driverId,
//     required String phone,
//     required String trips,
//     required double rating,
//     String? badge,
//   }) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isSmallScreen = constraints.maxWidth < 600;

//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Driver Info Row
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: isSmallScreen ? 25 : 30,
//                     backgroundColor: const Color(0xFFE8E8E8),
//                     child: Icon(
//                       Icons.person,
//                       size: isSmallScreen ? 28 : 32,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Name and ID
//                         Text(
//                           '$name • $driverId',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 16 : 18,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.textPrimary,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         // Phone and trips
//                         Text(
//                           '$phone • $trips',
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: AppColors.textSecondary,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   // Rating column
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             rating.toString(),
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.textPrimary,
//                             ),
//                           ),
//                           const SizedBox(width: 2),
//                           const Icon(
//                             Icons.star,
//                             size: 16,
//                             color: Color(0xFFFFA726),
//                           ),
//                         ],
//                       ),
//                       if (badge != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           badge,
//                           style: const TextStyle(
//                             fontSize: 11,
//                             color: AppColors.textSecondary,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Action Buttons - Responsive layout
//               if (isSmallScreen)
//                 // Stack buttons on small screens
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     _buildActionButton(
//                       icon: Icons.edit_outlined,
//                       label: 'Edit',
//                       color: const Color(0xFF4A90E2),
//                       backgroundColor: const Color(0xFFE3F2FD),
//                       onPressed: () {},
//                       fullWidth: true,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildActionButton(
//                             icon: Icons.visibility_outlined,
//                             label: 'View',
//                             color: const Color(0xFFFFA726),
//                             backgroundColor: const Color(0xFFFFF3E0),
//                             onPressed: () {},
//                             fullWidth: false,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: _buildActionButton(
//                             icon: Icons.delete_outline,
//                             label: 'Remove',
//                             color: const Color(0xFFA13D38),
//                             backgroundColor: const Color(0xFFFFEBEE),
//                             onPressed: () {},
//                             fullWidth: false,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 )
//               else
//                 // Horizontal layout on larger screens
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildActionButton(
//                         icon: Icons.edit_outlined,
//                         label: 'Edit',
//                         color: const Color(0xFF4A90E2),
//                         backgroundColor: const Color(0xFFE3F2FD),
//                         onPressed: () {},
//                         fullWidth: false,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: _buildActionButton(
//                         icon: Icons.visibility_outlined,
//                         label: 'View',
//                         color: const Color(0xFFFFA726),
//                         backgroundColor: const Color(0xFFFFF3E0),
//                         onPressed: () {},
//                         fullWidth: false,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: _buildActionButton(
//                         icon: Icons.delete_outline,
//                         label: 'Remove',
//                         color: const Color(0xFFA13D38),
//                         backgroundColor: const Color(0xFFFFEBEE),
//                         onPressed: () {},
//                         fullWidth: false,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required Color backgroundColor,
//     required VoidCallback onPressed,
//     required bool fullWidth,
//   }) {
//     return OutlinedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, size: 16),
//       label: Text(label),
//       style: OutlinedButton.styleFrom(
//         foregroundColor: color,
//         side: const BorderSide(color: Color(0xFFE8E8E8)),
//         backgroundColor: backgroundColor,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         minimumSize: fullWidth ? const Size(double.infinity, 40) : null,
//       ),
//     );
//   }

//   Widget _buildIncentivesContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Expanded(
//               child: Text(
//                 'Incentive Programs',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => VendorCreateIncentiveScreen(),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.add, size: 18),
//               label: const Text('Create Incentive'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const Divider(),
//         const SizedBox(height: 16),
//         _buildIncentiveCard(
//           title: 'Top Performer',
//           criteria: 'rating > 4.8 & 50+ trips',
//         ),
//         const SizedBox(height: 12),
//         _buildIncentiveCard(
//           title: 'Weekly Bonus',
//           criteria: '20+ trips/week',
//         ),
//       ],
//     );
//   }

//   Widget _buildComplaintCard({
//     required String title,
//     required String issueId,
//     required String type,
//     required String date,
//     required String status,
//     required Color statusColor,
//     required List<String> buttons,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: statusColor.withValues(alpha: 0.15),
//                   borderRadius: BorderRadius.circular(100),
//                 ),
//                 child: Text(
//                   status,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: statusColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '$issueId • $type',
//             style: const TextStyle(
//               fontSize: 14,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               const Icon(
//                 Icons.access_time,
//                 size: 14,
//                 color: AppColors.textSecondary,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 date,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: buttons.map((button) {
//               final isEscalate = button == 'Escalate';
//               final isDispute = button == 'Dispute';
//               final isResolve = button == 'Resolve';
//               final isDetails = button == 'Details';

//               Color buttonColor;
//               Color textColor;

//               if (isEscalate) {
//                 buttonColor = const Color(0xFFA13D38);
//                 textColor = Colors.white;
//               } else if (isDispute) {
//                 buttonColor = const Color(0xFFFFA726);
//                 textColor = Colors.white;
//               } else if (isResolve) {
//                 buttonColor = const Color(0xFF4CAF50);
//                 textColor = Colors.white;
//               } else {
//                 buttonColor = Colors.white;
//                 textColor = AppColors.textPrimary;
//               }

//               return ElevatedButton(
//                 onPressed: () {
//                   if (isDetails) {
//                     // Navigator.push(
//                     //   context,
//                     //   MaterialPageRoute(
//                     //     builder: (context) => VendorIssueDetailsScreen(vendorId: ),
//                     //   ),
//                     // );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: buttonColor,
//                   foregroundColor: textColor,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 10,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: isDetails
//                         ? const BorderSide(
//                             color: Color(0xFFE8E8E8),
//                             width: 1,
//                           )
//                         : BorderSide.none,
//                   ),
//                 ),
//                 child: Text(
//                   button,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIncentiveCard({
//     required String title,
//     required String criteria,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   criteria,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFFE3F2FD),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: IconButton(
//               icon: const Icon(
//                 Icons.edit,
//                 color: Color(0xFF4A90E2),
//                 size: 20,
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const VendorIncentivesScreen(),
//                   ),
//                 );
//               },
//               padding: EdgeInsets.zero,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFEBEE),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: IconButton(
//               icon: const Icon(
//                 Icons.delete_outline,
//                 color: Color(0xFFA13D38),
//                 size: 20,
//               ),
//               onPressed: () {},
//               padding: EdgeInsets.zero,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:ui' as BorderType;

import 'package:poolx_partner/app_colors.dart';
import 'package:poolx_partner/vendor/vendor_drawer.dart';
import 'package:poolx_partner/vendor/vendor_driver_perf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

class ReportModel {
  final String id;
  final String issueType;
  final String issueDetail;
  final String driverName;
  final String reporterRole;
  final String reportedBy;
  final String rideId;
  final String status; // pending | dispute | escalated | resolved
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.issueType,
    required this.issueDetail,
    required this.driverName,
    required this.reporterRole,
    required this.reportedBy,
    required this.rideId,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      issueType: d['issue_type'] ?? '',
      issueDetail: d['issue_detail'] ?? '',
      driverName: d['driver_name'] ?? '',
      reporterRole: d['reporterRole'] ?? '',
      reportedBy: d['reportedBy'] ?? '',
      rideId: d['ride_id'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['created_at'] as Timestamp).toDate(),
    );
  }
}

class DriverPerformanceModel {
  final String id;
  final String driverId;
  final String driverName;
  final String phone;
  final int totalTrips;
  final double rating;
  final String? badge;
  final String vendorId;

  DriverPerformanceModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.phone,
    required this.totalTrips,
    required this.rating,
    this.badge,
    required this.vendorId,
  });

  factory DriverPerformanceModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DriverPerformanceModel(
      id: doc.id,
      driverId: d['driver_id'] ?? '',
      driverName: d['driver_name'] ?? '',
      phone: d['phone'] ?? '',
      totalTrips: (d['total_trips'] ?? 0) as int,
      rating: (d['rating'] ?? 0.0).toDouble(),
      badge: d['badge'],
      vendorId: d['vendor_id'] ?? '',
    );
  }
}

class IncentiveModel {
  final String id;
  final String title;
  final String criteria;
  final String vendorId;
  final DateTime createdAt;

  IncentiveModel({
    required this.id,
    required this.title,
    required this.criteria,
    required this.vendorId,
    required this.createdAt,
  });

  factory IncentiveModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IncentiveModel(
      id: doc.id,
      title: d['title'] ?? '',
      criteria: d['criteria'] ?? '',
      vendorId: d['vendor_id'] ?? '',
      createdAt: (d['created_at'] as Timestamp).toDate(),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────

class RideDriverManagementScreen extends StatefulWidget {
  final int initialTab;

  const RideDriverManagementScreen({super.key, this.initialTab = 0});

  @override
  State<RideDriverManagementScreen> createState() =>
      _RideDriverManagementScreenState();
}

class _RideDriverManagementScreenState
    extends State<RideDriverManagementScreen> {
  late int _selectedTab;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? get _vendorId => _auth.currentUser?.uid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Stats state ──
  int _activeRides = 0;
  int _totalDrivers = 0;
  int _pendingComplaints = 0;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchStats();
  }

  // ─────────────────────────────────────────────
  //  STATS
  // ─────────────────────────────────────────────

  Future<void> _fetchStats() async {
    if (_vendorId == null) return;

    // Active rides for this vendor
    final activeRidesSnap = await _firestore
        .collection('active_rides')
        .where('vendorId', isEqualTo: _vendorId)
        .where('status', isEqualTo: 'active')
        .get();

    // Pending complaints: reports whose rideId belongs to this vendor
    // We join through active_rides
    final allRidesSnap = await _firestore
        .collection('active_rides')
        .where('vendorId', isEqualTo: _vendorId)
        .get();
    final vendorRideIds = allRidesSnap.docs.map((d) => d.id).toSet();

    final reportsSnap = await _firestore
        .collection('reports')
        .where('vendor_id', isEqualTo: _vendorId)
        .limit(100)
        .get();
    var vendorReports = reportsSnap.docs;

    // Legacy reports keyed by ride_id only (no vendor_id field).
    if (vendorReports.isEmpty && vendorRideIds.isNotEmpty) {
      final chunk = vendorRideIds.take(30).toList();
      final byRide = await _firestore
          .collection('reports')
          .where('ride_id', whereIn: chunk)
          .limit(100)
          .get();
      vendorReports = byRide.docs
          .where((d) => vendorRideIds.contains((d.data())['ride_id']))
          .toList();
    }

    final pendingReports = vendorReports.where(
      (d) => (d.data())['status'] == 'pending',
    );

    // Driver performance docs for this vendor
    final driverPerfSnap = await _firestore
        .collection('driver_performance')
        .where('vendor_id', isEqualTo: _vendorId)
        .get();

    double totalRating = 0;
    for (final doc in driverPerfSnap.docs) {
      totalRating += ((doc.data())['rating'] ?? 0.0).toDouble();
    }

    if (mounted) {
      setState(() {
        _activeRides = activeRidesSnap.size;
        _totalDrivers = driverPerfSnap.size;
        _pendingComplaints = pendingReports.length;
        _avgRating = driverPerfSnap.size == 0
            ? 0.0
            : totalRating / driverPerfSnap.size;
      });
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: BorderType.Color.fromARGB(255, 179, 178, 178),
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Carpool',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: const VendorDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride/Driver Management',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            // Tab bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  _buildTab('Complaints', 0),
                  const SizedBox(width: 4),
                  _buildTab('Drivers', 1),
                  const SizedBox(width: 4),
                  _buildTab('Incentives', 2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  STATS GRID
  // ─────────────────────────────────────────────

  Widget _buildStatsGrid() {
    if (_selectedTab == 0) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_activeRides.toString(), 'Active Rides'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  _totalDrivers.toString(),
                  'Total Drivers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _pendingComplaints.toString(),
                  'Pending Complaints',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  _avgRating == 0.0 ? '—' : _avgRating.toStringAsFixed(1),
                  'Avg. Rating',
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_activeRides.toString(), 'Active Rides'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  _totalDrivers.toString(),
                  'Total Drivers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _pendingComplaints.toString(),
                  'Pending Issues',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  _avgRating == 0.0 ? '—' : _avgRating.toStringAsFixed(1),
                  'Avg. Rating',
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                )
              : const BoxDecoration(),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB CONTENT ROUTER
  // ─────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildComplaintsContent();
      case 1:
        return _buildDriversContent();
      case 2:
        return _buildIncentivesContent();
      default:
        return _buildComplaintsContent();
    }
  }

  // ═════════════════════════════════════════════
  //  TAB 0 – COMPLAINTS (live from Firestore)
  // ═════════════════════════════════════════════

  Widget _buildComplaintsContent() {
    if (_vendorId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Issues & Complaints',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),

        // Step 1: stream vendor's active_rides IDs
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('active_rides')
              .where('vendorId', isEqualTo: _vendorId)
              .limit(50)
              .snapshots(),
          builder: (context, ridesSnap) {
            if (ridesSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rideIds =
                ridesSnap.data?.docs.map((d) => d.id).toList() ?? [];

            if (rideIds.isEmpty) {
              return _emptyState('No complaints found for your rides.');
            }

            // Step 2: stream reports whose ride_id is in vendor's rides
            // Firestore whereIn supports up to 30 items
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reports')
                  .where('ride_id', whereIn: rideIds.take(30).toList())
                  .orderBy('created_at', descending: true)
                  .limit(40)
                  .snapshots(),
              builder: (context, repSnap) {
                if (repSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports =
                    repSnap.data?.docs
                        .map((d) => ReportModel.fromDoc(d))
                        .toList() ??
                    [];

                if (reports.isEmpty) {
                  return _emptyState('No complaints found.');
                }

                return Column(
                  children: reports.asMap().entries.map((e) {
                    final report = e.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: e.key < reports.length - 1 ? 12 : 0,
                      ),
                      child: _buildComplaintCard(report),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildComplaintCard(ReportModel report) {
    // Map status → color
    Color statusColor;
    List<String> buttons;

    switch (report.status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFFFA726);
        buttons = ['Dispute', 'Resolve'];
        break;
      case 'dispute':
        statusColor = const Color(0xFFFFA726);
        buttons = ['Escalate', 'Resolve'];
        break;
      case 'escalated':
        statusColor = const Color(0xFFA13D38);
        buttons = ['Resolve'];
        break;
      case 'resolved':
        statusColor = const Color(0xFF4CAF50);
        buttons = ['Details'];
        break;
      default:
        statusColor = const Color(0xFFFFA726);
        buttons = ['Dispute', 'Resolve'];
    }

    final dateStr = DateFormat('dd MMM yyyy').format(report.createdAt);
    final typeLabel =
        '${report.reporterRole[0].toUpperCase()}${report.reporterRole.substring(1)} complaint';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  report.issueType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _capitalize(report.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.issueDetail,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${report.id.substring(0, 8).toUpperCase()} • $typeLabel',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Driver: ${report.driverName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons.map((btn) {
              return _complaintButton(
                label: btn,
                onPressed: () => _handleComplaintAction(report, btn),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _complaintButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    Color bg;
    Color fg;
    switch (label) {
      case 'Escalate':
        bg = const Color(0xFFA13D38);
        fg = Colors.white;
        break;
      case 'Dispute':
        bg = const Color(0xFFFFA726);
        fg = Colors.white;
        break;
      case 'Resolve':
        bg = const Color(0xFF4CAF50);
        fg = Colors.white;
        break;
      default:
        bg = Colors.white;
        fg = AppColors.textPrimary;
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: label == 'Details'
              ? const BorderSide(color: Color(0xFFE8E8E8))
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _handleComplaintAction(ReportModel report, String action) async {
    String newStatus;
    switch (action) {
      case 'Dispute':
        newStatus = 'dispute';
        break;
      case 'Escalate':
        newStatus = 'escalated';
        break;
      case 'Resolve':
        newStatus = 'resolved';
        break;
      default:
        return; // Details – navigate if needed
    }

    await _firestore.collection('reports').doc(report.id).update({
      'status': newStatus,
    });

    // Refresh stats
    _fetchStats();
  }

  // ═════════════════════════════════════════════
  //  TAB 1 – DRIVERS (live from driver_performance)
  // ═════════════════════════════════════════════

  Widget _buildDriversContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            if (isSmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Driver Performance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _addDriverPerfButton(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Driver Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _addDriverPerfButton(),
                  ],
                ),
                const Divider(),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Live list
        StreamBuilder<QuerySnapshot>(
          stream: _vendorId == null
              ? null
              : _firestore
                    .collection('driver_performance')
                    .where('vendor_id', isEqualTo: _vendorId)
                    .orderBy('rating', descending: true)
                    .limit(50)
                    .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final drivers =
                snap.data?.docs
                    .map((d) => DriverPerformanceModel.fromDoc(d))
                    .toList() ??
                [];
            if (drivers.isEmpty) {
              return _emptyState(
                'No driver performance records found.\nTap "Add Driver perf." to get started.',
              );
            }
            return Column(
              children: drivers.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < drivers.length - 1 ? 12 : 0,
                  ),
                  child: _buildDriverCard(e.value),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _addDriverPerfButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VendorAddDriverPerformanceScreen()),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Driver perf.'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDriverCard(DriverPerformanceModel driver) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 25 : 30,
                    backgroundColor: const Color(0xFFE8E8E8),
                    child: Icon(
                      Icons.person,
                      size: isSmallScreen ? 28 : 32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver.driverName} • ${driver.driverId}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${driver.phone} • ${driver.totalTrips} trips',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFFFA726),
                          ),
                        ],
                      ),
                      if (driver.badge != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          driver.badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isSmallScreen)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF4A90E2),
                      backgroundColor: const Color(0xFFE3F2FD),
                      onPressed: () => _navigateEditDriver(driver),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.visibility_outlined,
                            label: 'View',
                            color: const Color(0xFFFFA726),
                            backgroundColor: const Color(0xFFFFF3E0),
                            onPressed: () => _navigateViewDriver(driver),
                            fullWidth: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.delete_outline,
                            label: 'Remove',
                            color: const Color(0xFFA13D38),
                            backgroundColor: const Color(0xFFFFEBEE),
                            onPressed: () => _confirmDeleteDriver(driver),
                            fullWidth: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: const Color(0xFF4A90E2),
                        backgroundColor: const Color(0xFFE3F2FD),
                        onPressed: () => _navigateEditDriver(driver),
                        fullWidth: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                        color: const Color(0xFFFFA726),
                        backgroundColor: const Color(0xFFFFF3E0),
                        onPressed: () => _navigateViewDriver(driver),
                        fullWidth: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        color: const Color(0xFFA13D38),
                        backgroundColor: const Color(0xFFFFEBEE),
                        onPressed: () => _confirmDeleteDriver(driver),
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateEditDriver(DriverPerformanceModel driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorAddDriverPerformanceScreen(
          // existingDoc: driver,
        ),
      ),
    );
  }

  void _navigateViewDriver(DriverPerformanceModel driver) {
    // Navigate to driver detail screen – implement as needed
  }

  Future<void> _confirmDeleteDriver(DriverPerformanceModel driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Text('Are you sure you want to remove ${driver.driverName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFA13D38)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('driver_performance').doc(driver.id).delete();
      _fetchStats();
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required bool fullWidth,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: const BorderSide(color: Color(0xFFE8E8E8)),
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: fullWidth ? const Size(double.infinity, 40) : null,
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  TAB 2 – INCENTIVES (live from incentives)
  // ═════════════════════════════════════════════

  Widget _buildIncentivesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Incentive Programs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateIncentiveDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Incentive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),

        // Live list from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: _vendorId == null
              ? null
              : _firestore
                    .collection('incentives')
                    .where('vendor_id', isEqualTo: _vendorId)
                    .limit(40)
                    .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final incentives =
                snap.data?.docs
                    .map((d) => IncentiveModel.fromDoc(d))
                    .toList() ??
                [];
            if (incentives.isEmpty) {
              return _emptyState(
                'No incentive programs yet.\nTap "Create Incentive" to add one.',
              );
            }
            return Column(
              children: incentives.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < incentives.length - 1 ? 12 : 0,
                  ),
                  child: _buildIncentiveCard(e.value),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncentiveCard(IncentiveModel incentive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incentive.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incentive.criteria,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _iconBtn(
            icon: Icons.edit,
            color: const Color(0xFF4A90E2),
            bg: const Color(0xFFE3F2FD),
            onPressed: () => _showEditIncentiveDialog(incentive),
          ),
          const SizedBox(width: 8),
          _iconBtn(
            icon: Icons.delete_outline,
            color: const Color(0xFFA13D38),
            bg: const Color(0xFFFFEBEE),
            onPressed: () => _confirmDeleteIncentive(incentive),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ── Incentive dialogs ──

  void _showCreateIncentiveDialog() => _showIncentiveDialog(null);

  void _showEditIncentiveDialog(IncentiveModel incentive) =>
      _showIncentiveDialog(incentive);

  void _showIncentiveDialog(IncentiveModel? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final criteriaCtrl = TextEditingController(text: existing?.criteria ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Create Incentive' : 'Edit Incentive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Top Performer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: criteriaCtrl,
              decoration: const InputDecoration(
                labelText: 'Criteria',
                hintText: 'e.g. rating > 4.8 & 50+ trips',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final criteria = criteriaCtrl.text.trim();
              if (title.isEmpty || criteria.isEmpty) return;

              if (existing == null) {
                await _firestore.collection('incentives').add({
                  'title': title,
                  'criteria': criteria,
                  'vendor_id': _vendorId,
                  'created_at': FieldValue.serverTimestamp(),
                });
              } else {
                await _firestore
                    .collection('incentives')
                    .doc(existing.id)
                    .update({'title': title, 'criteria': criteria});
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      criteriaCtrl.dispose();
    });
  }

  Future<void> _confirmDeleteIncentive(IncentiveModel incentive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Incentive'),
        content: Text('Delete "${incentive.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFA13D38)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('incentives').doc(incentive.id).delete();
    }
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
