// lib/screens/vendor_fleet_management_screen.dart
import 'dart:ui' as BorderType;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'vendor_drawer.dart';
import 'vendor_driver_perf.dart' show VendorPayDriverScreen;
import 'vendor_passenger_requests_screen.dart';

import 'package:intl/intl.dart';
class VendorFleetManagementScreen extends StatefulWidget {
  const VendorFleetManagementScreen({super.key});

  @override
  State<VendorFleetManagementScreen> createState() =>
      _VendorFleetManagementScreenState();
}

class _VendorFleetManagementScreenState
    extends State<VendorFleetManagementScreen> {
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _driversSearchController = TextEditingController();
  final _vehiclesSearchController = TextEditingController();
  String? get _vendorId => _auth.currentUser?.uid;

  @override
  void dispose() {
    _driversSearchController.dispose();
    _vehiclesSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
         key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
         titleSpacing: 0,
          backgroundColor:  Color(0xFFF9FAFB),
        elevation: 0, 

   
   
   shape: const Border(
    bottom: BorderSide(
      color: BorderType.Color.fromARGB(255, 179, 178, 178),   // change to AppColors.primary if needed
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fleet Management System',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                // Stat cards — white, border, shadow, equal size
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildStatCard('2', 'Active Drivers')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard('2', 'Available Vehicles')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('3', 'Pending Rides')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTabBar(),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildDriversTab()
                : _selectedTab == 1
                    ? _buildVehiclesTab()
                    : _buildAssignmentsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    // ← White background, selected has border+tint, non-selected = plain text
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTab('Drivers', 0)),
          Expanded(child: _buildTab('Vehicles', 1)),
          Expanded(child: _buildTab('Assignments', 2)),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              )
            : const BoxDecoration(), // ← No border, no background for unselected
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Drivers Tab ──────────────────────────────────────────────────────
Widget _buildDriversTab() {
  String _searchQuery = '';

  return StatefulBuilder(
    builder: (context, setTabState) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Driver Management',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  onPressed: () => _showAddDriverDialog(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          // Search bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _driversSearchController,
              onChanged: (v) =>
                  setTabState(() => _searchQuery = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search drivers',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                icon: Icon(Icons.search,
                    color: AppColors.textSecondary, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Stream from Firestore ─────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('drivers')
                .where('vendor_id', isEqualTo: _vendorId)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ));
              }

              final docs = snapshot.data?.docs ?? [];

              // Client-side search filter
              final filtered = docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final d = doc.data() as Map<String, dynamic>;
                final name =
                    (d['full_name'] as String? ?? '').toLowerCase();
                final plate = (d['vehicle']?['plate_number'] as String? ?? '')
                    .toLowerCase();
                final phone =
                    (d['phone_number'] as String? ?? '').toLowerCase();
                return name.contains(_searchQuery) ||
                    plate.contains(_searchQuery) ||
                    phone.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
              
                // return _buildEmptyState(
                //     docs.isEmpty ? 'No drivers assigned yet' : 'No drivers found');
              }

              return Column(
                children: filtered.asMap().entries.map((entry) {
                  final d =
                      entry.value.data() as Map<String, dynamic>;
                  final uid = entry.value.id;

                  // ── Parse fields from schema ────────────────
                  final name = d['full_name'] as String? ?? 'Driver';
                  final phone =
                      d['phone_number'] as String? ?? '';
                  final city = d['city'] as String? ?? '';
                  final approvalStatus =
                      d['approval_status'] as String? ?? 'pending';
                  final isAvailable =
                      d['is_available'] as bool? ?? false;
                  final totalRides =
                      (d['total_rides'] as num?)?.toInt() ?? 0;
                  final avgRating =
                      (d['average_rating'] as num?)?.toStringAsFixed(1) ??
                          '0.0';
                  final gender = d['gender'] as String? ?? '';
                  final vehiclePending =
                      d['pending_vehicle_status'] == 'pending' &&
                          d['pending_vehicle_update'] is Map;
                  final documentsPending =
                      d['documents_pending_review'] == true;

                  // Vehicle
                  final vehicle =
                      d['vehicle'] as Map<dynamic, dynamic>? ?? {};
                  final make =
                      vehicle['make'] as String? ?? '';
                  final model =
                      vehicle['model'] as String? ?? '';
                  final plate =
                      vehicle['plate_number'] as String? ?? '';
                  final vehicleType =
                      vehicle['type'] as String? ?? '';
                  final seats =
                      (vehicle['seating_capacity'] as num?)?.toInt() ??
                          0;
                  final color =
                      vehicle['color'] as String? ?? '';

                  // Availability
                  final avail =
                      d['availability'] as Map<dynamic, dynamic>? ?? {};
                  final hoursFrom =
                      avail['working_hours_from'] as String? ?? '';
                  final hoursTo =
                      avail['working_hours_to'] as String? ?? '';
                  final days =
                      avail['days_of_week'] as String? ?? '';
                  final routeFrom =
                      avail['preferred_route_from'] as String? ?? '';
                  final routeTo =
                      avail['preferred_route_to'] as String? ?? '';

                  // Status label
                  String statusLabel;
                  Color statusColor;
                  if (approvalStatus == 'pending') {
                    statusLabel = 'Pending';
                    statusColor = const Color(0xFFF59E0B);
                  } else if (approvalStatus == 'rejected') {
                    statusLabel = 'Rejected';
                    statusColor = const Color(0xFFEF4444);
                  } else if (isAvailable) {
                    statusLabel = 'Available';
                    statusColor = const Color(0xFF10B981);
                  } else {
                    statusLabel = 'On Trip';
                    statusColor = AppColors.primary;
                  }

                  return Column(
                    children: [
                      _buildDriverCard(
                        uid: uid,
                        name: name,
                        phone: phone,
                        city: city,
                        gender: gender,
                        totalRides: totalRides,
                        avgRating: avgRating,
                        vehicleLabel:
                            '${make.isNotEmpty ? make[0].toUpperCase() + make.substring(1) : ''} ${model.isNotEmpty ? model[0].toUpperCase() + model.substring(1) : ''}'
                                .trim(),
                        plate: plate,
                        vehicleType: vehicleType,
                        seats: seats,
                        color: color,
                        hours: hoursFrom.isNotEmpty && hoursTo.isNotEmpty
                            ? '$days, $hoursFrom - $hoursTo'
                            : 'Not set',
                        route: routeFrom.isNotEmpty && routeTo.isNotEmpty
                            ? '$routeFrom → $routeTo'
                            : '',
                        status: statusLabel,
                        statusColor: statusColor,
                        vehiclePending: vehiclePending,
                        documentsPending: documentsPending,
                      ),
                      if (entry.key < filtered.length - 1)
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    },
  );
}

Widget _buildDriverCard({
  required String uid,
  required String name,
  required String phone,
  required String city,
  required String gender,
  required int totalRides,
  required String avgRating,
  required String vehicleLabel,
  required String plate,
  required String vehicleType,
  required int seats,
  required String color,
  required String hours,
  required String route,
  required String status,
  required Color statusColor,
  bool vehiclePending = false,
  bool documentsPending = false,
}) {
  final needsReview = vehiclePending || documentsPending;
  final initials = name
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with initials
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('$phone${city.isNotEmpty ? ' • $city' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text('$avgRating  •  $totalRides rides',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ],
        ),
        if (needsReview) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (vehiclePending)
                _vendorReviewBadge(
                  'Vehicle update pending',
                  _reviewAmber,
                  Icons.directions_car_outlined,
                ),
              if (documentsPending)
                _vendorReviewBadge(
                  'New documents',
                  _reviewBlue,
                  Icons.description_outlined,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade100),
        const SizedBox(height: 10),

        // ── Vehicle info ─────────────────────────────────────────
        if (vehicleLabel.isNotEmpty)
          _driverInfoRow(Icons.directions_car_outlined,
              '$vehicleLabel • $plate${vehicleType.isNotEmpty ? ' ($vehicleType)' : ''}${seats > 0 ? ' • $seats seats' : ''}'),

        // ── Working hours ────────────────────────────────────────
        if (hours != 'Not set') ...[
          const SizedBox(height: 6),
          _driverInfoRow(Icons.access_time_outlined, hours),
        ],

        // ── Preferred route ──────────────────────────────────────
        if (route.isNotEmpty) ...[
          const SizedBox(height: 6),
          _driverInfoRow(Icons.route_outlined, route),
        ],

        const SizedBox(height: 14),
        // ── Action buttons ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: const Color(0xFF3B82F6),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'Hours',
              icon: Icons.access_time,
              color: const Color(0xFFF59E0B),
              onPressed: () =>
                  _showSetHoursDialog(context, name, uid),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'Remove',
              icon: Icons.delete_outline,
              color: const Color(0xFFEF4444),
              onPressed: () => _confirmRemoveDriver(context, uid, name),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            label: 'Pay Driver',
            icon: Icons.payments_outlined,
            color: AppColors.primary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VendorPayDriverScreen(driverId: uid, driverName: name),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            label: needsReview
                ? 'Review vehicle & documents'
                : 'Vehicle & documents',
            icon: Icons.fact_check_outlined,
            color: needsReview ? _reviewAmber : _reviewBlue,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VendorDriverReviewScreen(driverId: uid),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _driverInfoRow(IconData icon, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ),
    ],
  );
}

// ── Confirm remove driver dialog ──────────────────────────────────────
void _confirmRemoveDriver(
    BuildContext context, String uid, String name) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove Driver'),
      content: Text('Remove $name from your fleet?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _firestore
                .collection('drivers')
                .doc(uid)
                .update({'vendor_id': FieldValue.delete()});
          },
          child: const Text('Remove',
              style: TextStyle(color: Color(0xFFEF4444))),
        ),
      ],
    ),
  );
}

  // ─── DRIVERS TAB ────────────────────────────────────────────────────────────

  // Widget _buildDriversTab() {
  //   return ListView(
  //     padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           const Text(
  //             'Driver Management',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: AppColors.primary,
  //             ),
  //           ),
  //           // ← Smaller add button
  //           Container(
  //             width: 36,
  //             height: 36,
  //             decoration: const BoxDecoration(
  //               color: AppColors.primary,
  //               shape: BoxShape.circle,
  //             ),
  //             child: IconButton(
  //               icon: const Icon(Icons.add, color: Colors.white, size: 18),
  //               onPressed: () => _showAddDriverDialog(context),
  //               padding: EdgeInsets.zero,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const Divider(), // ← Divider below Driver Management
  //       const SizedBox(height: 12),
  //       // Search — transparent background
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  //         decoration: BoxDecoration(
  //           color: Colors.transparent,
  //           borderRadius: BorderRadius.circular(100),
  //           border: Border.all(color: Colors.grey.shade300),
  //         ),
  //         child: const TextField(
  //           decoration: InputDecoration(
  //             hintText: 'Search drivers',
  //             hintStyle:
  //                 TextStyle(color: AppColors.textSecondary, fontSize: 15),
  //             border: InputBorder.none,
  //             icon: Icon(Icons.search,
  //                 color: AppColors.textSecondary, size: 22),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 20),
  //       _buildDriverCard(
  //         name: 'Hamza Khan',
  //         id: 'DRV-001',
  //         experience: '2 years experience',
  //         hours: 'Mon-Fri, 11:00 AM - 7:00 PM',
  //         status: 'Available',
  //         statusColor: const Color(0xFF10B981),
  //       ),
  //       const SizedBox(height: 16),
  //       _buildDriverCard(
  //         name: 'Waqar Ali',
  //         id: 'HSR-005',
  //         experience: '5 years experience',
  //         hours: 'Mon-Fri, 07:00 AM - 9:00 PM',
  //         status: 'Available',
  //         statusColor: const Color(0xFF10B981),
  //       ),
  //       const SizedBox(height: 16),
  //       _buildDriverCard(
  //         name: 'Haider Imran',
  //         id: 'SVC-015',
  //         experience: '7 years experience',
  //         hours: 'Tue-Sat, 06:00 AM - 6:00 PM',
  //         status: 'On Trip',
  //         statusColor: const Color(0xFFF59E0B),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildDriverCard({
  //   required String name,
  //   required String id,
  //   required String experience,
  //   required String hours,
  //   required String status,
  //   required Color statusColor,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       // ← No border, shadow only
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.06),
  //           blurRadius: 12,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Top row: avatar + info + status badge
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               width: 50,
  //               height: 50,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey.shade200,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(Icons.person,
  //                   color: AppColors.textSecondary, size: 28),
  //             ),
  //             const SizedBox(width: 12),
  //             // Name, ID+experience, working hours — all left-aligned
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     name,
  //                     style: const TextStyle(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w700,
  //                       color: AppColors.textPrimary,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 3),
  //                   Text(
  //                     'ID: $id | $experience',
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: AppColors.textSecondary,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 3),
  //                   // ← Working hours aligned under name (no separate row)
  //                   Row(
  //                     children: [
  //                       const Icon(Icons.access_time,
  //                           size: 13, color: AppColors.textSecondary),
  //                       const SizedBox(width: 4),
  //                       Flexible(
  //                         child: Text(
  //                           'Working Hours: $hours',
  //                           style: const TextStyle(
  //                             fontSize: 12,
  //                             color: AppColors.textSecondary,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             // Status badge
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //               decoration: BoxDecoration(
  //                 color: statusColor.withValues(alpha: 0.12),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Text(
  //                 status,
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: statusColor,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 14),
  //         // ← Buttons right-aligned, not full width
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.end,
  //           children: [
  //             _buildActionButton(
  //               label: 'Edit',
  //               icon: Icons.edit_outlined,
  //               color: const Color(0xFF3B82F6),
  //               onPressed: () {},
  //             ),
  //             const SizedBox(width: 8),
  //             _buildActionButton(
  //               label: 'Hours',
  //               icon: Icons.access_time,
  //               color: const Color(0xFFF59E0B),
  //               onPressed: () => _showSetHoursDialog(context, name, id),
  //             ),
  //             const SizedBox(width: 8),
  //             _buildActionButton(
  //               label: 'Remove',
  //               icon: Icons.delete_outline,
  //               color: const Color(0xFFEF4444),
  //               onPressed: () {},
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 13, color: color)),
      style: OutlinedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.06),
        side: BorderSide(color: color, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ─── VEHICLES TAB ───────────────────────────────────────────────────────────
// ── Vehicles Tab ─────────────────────────────────────────────────────
Widget _buildVehiclesTab() {
  String _searchQuery = '';

  return StatefulBuilder(
    builder: (context, setTabState) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vehicle Fleet',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  onPressed: () => _showAddVehicleDialog(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _vehiclesSearchController,
              onChanged: (v) =>
                  setTabState(() => _searchQuery = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search vehicles',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                icon: Icon(Icons.search,
                    color: AppColors.textSecondary, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Stream from vendors/{uid}/vehicles subcollection ──
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('vendors')
                .doc(_vendorId)
                .collection('vehicles')
                .where('is_active', isEqualTo: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ));
              }

              final docs = snapshot.data?.docs ?? [];

              final filtered = docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final v = doc.data() as Map<String, dynamic>;
                final model =
                    (v['model'] as String? ?? '').toLowerCase();
                final plate =
                    (v['plate_number'] as String? ?? '').toLowerCase();
                final type =
                    (v['type'] as String? ?? '').toLowerCase();
                return model.contains(_searchQuery) ||
                    plate.contains(_searchQuery) ||
                    type.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Text("No vehicles in fleet yet");
                // return _buildEmptyState(
                //     docs.isEmpty ? 'No vehicles in fleet yet' : 'No vehicles found');
              }

              return Column(
                children: filtered.asMap().entries.map((entry) {
                  final v =
                      entry.value.data() as Map<String, dynamic>;
                  final docId = entry.value.id;

                  final model = v['model'] as String? ?? 'Vehicle';
                  final plate =
                      v['plate_number'] as String? ?? '';
                  final type = v['type'] as String? ?? '';
                 final year = (v['year'] as String? ?? '').trim();
                  final seats =
                      (v['seating_capacity'] as num?)?.toInt() ?? 0;
                  final assignedDriverId =
                      v['assigned_driver_id'] as String?;
                  final isActive = v['is_active'] as bool? ?? true;

                  // Status from assigned_driver_id
                  final String status;
                  final Color statusColor;
                  if (!isActive) {
                    status = 'Inactive';
                    statusColor = Colors.grey;
                  } else if (assignedDriverId != null &&
                      assignedDriverId.isNotEmpty) {
                    status = 'Assigned';
                    statusColor = AppColors.primary;
                  } else {
                    status = 'Available';
                    statusColor = const Color(0xFF10B981);
                  }

                  // Capitalize model
                  final displayModel = model.isNotEmpty
                      ? model[0].toUpperCase() + model.substring(1)
                      : model;

                  return Column(
                    children: [
                      _buildVehicleCard(
                        docId: docId,
                        model: displayModel,
                        plate: plate,
                        type: type,
                        year: year,
                        seats: seats,
                        assignedDriverId: assignedDriverId,
                        status: status,
                        statusColor: statusColor,
                      ),
                      if (entry.key < filtered.length - 1)
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    },
  );
}

Widget _buildVehicleCard({
  required String docId,
  required String model,
  required String plate,
  required String type,
  required String year,
  required int seats,
  required String? assignedDriverId,
  required String status,
  required Color statusColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    'Plate: $plate${type.isNotEmpty ? ' • $type' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  Text(
                    '${seats > 0 ? '$seats seats' : ''}${year.isNotEmpty ? ' • $year' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  // Show assigned driver ID if assigned
                  if (assignedDriverId != null &&
                      assignedDriverId.isNotEmpty)
                    Text(
                      'Driver: ${assignedDriverId.substring(0, 8)}...',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: const Color(0xFF3B82F6),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'Remove',
              icon: Icons.delete_outline,
              color: const Color(0xFFEF4444),
              onPressed: () =>
                  _confirmRemoveVehicle(context, docId, model),
            ),
          ],
        ),
      ],
    ),
  );
}

void _confirmRemoveVehicle(
    BuildContext context, String docId, String model) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove Vehicle'),
      content: Text('Remove $model from your fleet?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _firestore
                .collection('vendors')
                .doc(_vendorId)
                .collection('vehicles')
                .doc(docId)
                .update({'is_active': false});
          },
          child: const Text('Remove',
              style: TextStyle(color: Color(0xFFEF4444))),
        ),
      ],
    ),
  );
}
  
  
  
  // Widget _buildVehiclesTab() {
  //   return ListView(
  //     padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           const Text(
  //             'Vehicle Fleet',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: AppColors.primary,
  //             ),
  //           ),
  //           Container(
  //             width: 36,
  //             height: 36,
  //             decoration: const BoxDecoration(
  //               color: AppColors.primary,
  //               shape: BoxShape.circle,
  //             ),
  //             child: IconButton(
  //               icon: const Icon(Icons.add, color: Colors.white, size: 18),
  //               onPressed: () => _showAddVehicleDialog(context),
  //               padding: EdgeInsets.zero,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const Divider(), // ← Divider below Vehicle Fleet
  //       const SizedBox(height: 12),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  //         decoration: BoxDecoration(
  //           color: Colors.transparent,
  //           borderRadius: BorderRadius.circular(100),
  //           border: Border.all(color: Colors.grey.shade300),
  //         ),
  //         child: const TextField(
  //           decoration: InputDecoration(
  //             hintText: 'Search vehicles',
  //             hintStyle:
  //                 TextStyle(color: AppColors.textSecondary, fontSize: 15),
  //             border: InputBorder.none,
  //             icon: Icon(Icons.search,
  //                 color: AppColors.textSecondary, size: 22),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 20),
  //       _buildVehicleCard(
  //         name: 'Hamza Khan',
  //         license: 'ABC-123',
  //         capacity: '4 passengers',
  //         status: 'Available',
  //         statusColor: const Color(0xFF10B981),
  //       ),
  //       const SizedBox(height: 16),
  //       _buildVehicleCard(
  //         name: 'Hamza Khan',
  //         license: 'XYZ-789',
  //         capacity: '4 passengers',
  //         status: 'Available',
  //         statusColor: const Color(0xFF10B981),
  //       ),
  //       const SizedBox(height: 16),
  //       _buildVehicleCard(
  //         name: 'Hamza Khan',
  //         license: 'ABC-123',
  //         capacity: '4 passengers',
  //         status: 'Maintenance',
  //         statusColor: const Color(0xFFF59E0B),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildVehicleCard({
  //   required String name,
  //   required String license,
  //   required String capacity,
  //   required String status,
  //   required Color statusColor,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.06),
  //           blurRadius: 12,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               width: 50,
  //               height: 50,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey.shade200,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(Icons.directions_car,
  //                   color: AppColors.textSecondary, size: 26),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     name,
  //                     style: const TextStyle(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w700,
  //                       color: AppColors.textPrimary,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 3),
  //                   Text(
  //                     'License: $license',
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: AppColors.textSecondary,
  //                     ),
  //                   ),
  //                   Text(
  //                     'Capacity: $capacity',
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: AppColors.textSecondary,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //               decoration: BoxDecoration(
  //                 color: statusColor.withValues(alpha: 0.12),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Text(
  //                 status,
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: statusColor,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 14),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.end,
  //           children: [
  //             _buildActionButton(
  //               label: 'Edit',
  //               icon: Icons.edit_outlined,
  //               color: const Color(0xFF3B82F6),
  //               onPressed: () {},
  //             ),
  //             const SizedBox(width: 8),
  //             _buildActionButton(
  //               label: 'Remove',
  //               icon: Icons.delete_outline,
  //               color: const Color(0xFFEF4444),
  //               onPressed: () {},
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ─── ASSIGNMENTS TAB ────────────────────────────────────────────────────────

 late final Stream<List<VendorRequestDoc>> _assignmentRequestsStream =
     VendorPassengerRequests.stream();

 Widget _buildAssignmentsTab() {
  return StreamBuilder<List<VendorRequestDoc>>(
    stream: _assignmentRequestsStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load passenger requests. ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.data!.isEmpty) {
        return const Center(child: Text("No passenger requests right now"));
      }

      var rides = snapshot.data!;

      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          const Text(
            'Ride Assignments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),

          /// 🔍 Search bar (UI only for now)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search rides',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 Dynamic Ride Cards
          ...rides.map((ride) {
            var data = ride.data();

            /// ⏰ Time formatting
            final reqMs = VendorPassengerRequests.requestedMillis(data);
            Timestamp? ts = reqMs > 0
                ? Timestamp.fromMillisecondsSinceEpoch(reqMs)
                : null;
            String time = "N/A";
            String period = "";

            if (ts != null) {
              DateTime dt = ts.toDate();
              time = DateFormat('hh:mm').format(dt);
              period = DateFormat('a').format(dt);
            }

            /// 📍 Route
            String route =
                data['destination']?['address'] ?? "Unknown Route";

            /// 📊 Details
            String details =
                "${data['estimated_distance_km'] ?? 0} km • ${data['estimated_trip_time'] ?? ''}";

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAssignmentCard(
                rideId: ride.id,
                time: time,
                period: period,
                route: route,
                details: details,
              ),
            );
          }).toList(),
        ],
      );
    },
  );
}
Widget _buildAssignmentCard({
  required String rideId,
  required String time,
  required String period,
  required String route,
  required String details,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        /// ⏰ Time Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                period,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        /// 📍 Ride Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        /// 🚀 Assign Button
        ElevatedButton(
          onPressed: () => _assignDriver(rideId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Assign',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
Future<void> _assignDriver(String rideId) async {
  VendorPassengerRequests.openDetails(context, rideId);
}
  // ─── DIALOGS ────────────────────────────────────────────────────────────────

void _showAddDriverDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final cnicCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  bool isSaving = false;
  bool obscurePassword = true;

  // Vehicle selection from subcollection
  Map<String, dynamic>? selectedVehicle;
  String? selectedVehicleDocId;
  List<QueryDocumentSnapshot> vehicleDocs = [];
  bool vehiclesLoaded = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        // ── Load vehicles once ──────────────────────────────────
        if (!vehiclesLoaded) {
          vehiclesLoaded = true;
          _firestore
              .collection('vendors')
              .doc(_vendorId)
              .collection('vehicles')
              .where('is_active', isEqualTo: true)
              .get()
              .then((snap) => setModalState(() => vehicleDocs = snap.docs));
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Driver',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Personal Info ───────────────────────────
                      _sectionLabel('Personal Information'),
                      const SizedBox(height: 12),
                      _dialogField(
                          'Full Name', 'Enter full name', nameCtrl),
                      const SizedBox(height: 12),
                      _dialogField('Email', 'Enter email address', emailCtrl,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),

                      // Password
                      const Text('Password',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setModalState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dialogField(
                          'Phone Number', '03xxxxxxxxx', phoneCtrl,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _dialogField('City', 'e.g. Karachi', cityCtrl),
                      const SizedBox(height: 12),
                      _dialogField(
                          'CNIC', '13 digit CNIC number', cnicCtrl,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _dialogField('License Number',
                          'Enter license number', licenseCtrl),
                      const SizedBox(height: 20),

                      // ── Assign Vehicle ──────────────────────────
                      _sectionLabel('Assign Vehicle'),
                      const SizedBox(height: 12),

                      if (vehicleDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange.shade600,
                                  size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'No vehicles available. Add a vehicle first.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Vehicle',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedVehicleDocId,
                              hint: const Text('Choose a vehicle'),
                              isExpanded: true,
                              items: vehicleDocs.map((doc) {
                                final v = doc.data()
                                    as Map<String, dynamic>;
                                final make = _capitalize(
                                    v['make'] as String? ?? '');
                                final model = _capitalize(
                                    v['model'] as String? ?? '');
                                final plate =
                                    v['plate_number'] as String? ?? '';
                                final type =
                                    v['type'] as String? ?? '';
                                final seats = (v['seating_capacity']
                                            as num?)
                                        ?.toInt() ??
                                    0;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    '$make $model • $plate${type.isNotEmpty ? ' ($type)' : ''}${seats > 0 ? ' • $seats seats' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (docId) {
                                if (docId == null) return;
                                final doc = vehicleDocs
                                    .firstWhere((d) => d.id == docId);
                                setModalState(() {
                                  selectedVehicleDocId = docId;
                                  selectedVehicle = doc.data()
                                      as Map<String, dynamic>;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary)),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                              ),
                            ),

                            // ── Selected vehicle preview ──────────
                            if (selectedVehicle != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    _previewRow(
                                        Icons.directions_car_outlined,
                                        '${_capitalize(selectedVehicle!['make'] ?? '')} ${_capitalize(selectedVehicle!['model'] ?? '')}'),
                                    const SizedBox(height: 6),
                                    _previewRow(
                                        Icons.confirmation_number_outlined,
                                        selectedVehicle!['plate_number'] ??
                                            ''),
                                    const SizedBox(height: 6),
                                    _previewRow(
                                        Icons.airline_seat_recline_normal,
                                        '${selectedVehicle!['seating_capacity'] ?? 0} seats • ${selectedVehicle!['type'] ?? ''}'),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                      const SizedBox(height: 28),

                      // ── Save button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameCtrl.text.trim().isEmpty ||
                                      emailCtrl.text.trim().isEmpty ||
                                      passwordCtrl.text.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Name, email and password are required')));
                                    return;
                                  }
                                  setModalState(() => isSaving = true);
                                  try {
                                    // 1. Create Auth user
                                    final credential = await FirebaseAuth
                                        .instance
                                        .createUserWithEmailAndPassword(
                                      email: emailCtrl.text.trim(),
                                      password: passwordCtrl.text,
                                    );
                                    final newUid = credential.user!.uid;

                                    // 2. users collection
                                    await _firestore
                                        .collection('users')
                                        .doc(newUid)
                                        .set({
                                      'firebase_uid': newUid,
                                      'email': emailCtrl.text.trim(),
                                      'full_name': nameCtrl.text.trim(),
                                      'role': 'driver',
                                      'created_at':
                                          FieldValue.serverTimestamp(),
                                    });

                                    // 3. drivers collection
                                    final v = selectedVehicle ?? {};
                                    await _firestore
                                        .collection('drivers')
                                        .doc(newUid)
                                        .set({
                                      'firebase_uid': newUid,
                                      'email': emailCtrl.text.trim(),
                                      'full_name': nameCtrl.text.trim(),
                                      'phone_number':
                                          phoneCtrl.text.trim(),
                                      'city': cityCtrl.text.trim(),
                                      'cnic': cnicCtrl.text.trim(),
                                      'license_number':
                                          licenseCtrl.text.trim(),
                                      'gender': '',
                                      'date_of_birth': '',
                                      'license_expiry': '',
                                      'approval_status': 'approved',
                                      'is_available': false,
                                      'profile_complete': true,
                                      'average_rating': 0,
                                      'total_rides': 0,
                                      'documents_submitted': false,
                                      'documents': {
                                        'license': false,
                                        'registration': false,
                                        'insurance': false,
                                      },
                                      'vehicle': {
                                        'make': v['make'] ?? '',
                                        'model': v['model'] ?? '',
                                        'plate_number':
                                            v['plate_number'] ?? '',
                                        'color': v['color'] ?? '',
                                        'type': v['type'] ?? '',
                                        'seating_capacity':
                                            v['seating_capacity'] ?? 4,
                                        'year': v['year'] ?? '',
                                      },
                                      'availability': {
                                        'days_of_week': '',
                                        'working_hours_from': '',
                                        'working_hours_to': '',
                                        'preferred_route_from': '',
                                        'preferred_route_to': '',
                                      },
                                      'vendor_id':  _vendorId,
                                      'created_at':
                                          FieldValue.serverTimestamp(),
                                    });

                                    // 4. Mark vehicle as assigned
                                    if (selectedVehicleDocId != null) {
                                      await _firestore
                                          .collection('vendors')
                                          .doc(_vendorId)
                                          .collection('vehicles')
                                          .doc(selectedVehicleDocId)
                                          .update({
                                        'assigned_driver_id': newUid,
                                      });
                                    }

                                    if (!mounted) return;
                                    final messenger =
                                        ScaffoldMessenger.of(this.context);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }
                                    messenger.showSnackBar(const SnackBar(
                                      content: Text(
                                          'Driver added successfully'),
                                      backgroundColor:
                                          Color(0xFF10B981),
                                    ));
                                  } on FirebaseAuthException catch (e) {
                                    if (!mounted) return;
                                    setModalState(
                                        () => isSaving = false);
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                e.message ?? 'Auth error')));
                                  } catch (e) {
                                    if (!mounted) return;
                                    setModalState(
                                        () => isSaving = false);
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(SnackBar(
                                            content:
                                                Text('Error: $e')));
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5))
                              : const Text('Add Driver',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  ).whenComplete(() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    phoneCtrl.dispose();
    cityCtrl.dispose();
    cnicCtrl.dispose();
    licenseCtrl.dispose();
  });
}

// ── Helper widgets used in dialogs ────────────────────────────────────
String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

Widget _previewRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary)),
      ),
    ],
  );
}
  
  void _showSetHoursDialog(
      BuildContext context, String driverName, String driverId) {
    final selectedDays = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set Working Hours',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.textSecondary, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('ID: $driverId',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Working Days',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                ].map((day) {
                  final isSelected = selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (isSelected) {
                          selectedDays.remove(day);
                        } else {
                          selectedDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildTimeField('Work Start Time', '08:00 AM')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTimeField('Work End Time', '05:00 PM')),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('Save Working Hours',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
void _showAddVehicleDialog(BuildContext context) {
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final plateCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  int seatingCapacity = 4;
  String? selectedType;
  bool isSaving = false;
  final vehicleTypes = ['Sedan', 'SUV', 'Van', 'Mini Bus', 'Bus'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add New Vehicle',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogField('Make', 'e.g. Toyota', makeCtrl),
                    const SizedBox(height: 12),
                    _dialogField('Model', 'e.g. Corolla', modelCtrl),
                    const SizedBox(height: 12),
                    _dialogField(
                        'Plate Number', 'e.g. ABC-123', plateCtrl),
                    const SizedBox(height: 12),
                    _dialogField('Year', 'e.g. 2022', yearCtrl,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),

                    // Vehicle type
                    const Text('Vehicle Type',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      hint: const Text('Select vehicle type'),
                      items: vehicleTypes
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedType = v),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Seating capacity stepper
                    const Text('Seating Capacity',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                            onPressed: seatingCapacity > 1
                                ? () => setModalState(
                                    () => seatingCapacity--)
                                : null,
                          ),
                          Text('$seatingCapacity seats',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                            onPressed: () =>
                                setModalState(() => seatingCapacity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (makeCtrl.text.trim().isEmpty ||
                                    modelCtrl.text.trim().isEmpty ||
                                    plateCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Make, model and plate are required')));
                                  return;
                                }
                                setModalState(() => isSaving = true);
                                try {
                                  // Add to vendors/{uid}/vehicles subcollection
                                  await _firestore
                                      .collection('vendors')
                                      .doc(_vendorId)
                                      .collection('vehicles')
                                      .add({
                                    'vendor_id': _vendorId,
                                    'make': makeCtrl.text.trim().toLowerCase(),
                                    'model': modelCtrl.text.trim().toLowerCase(),
                                    'plate_number': plateCtrl.text.trim(),
                                    'year': yearCtrl.text.trim(),
                                    'type': selectedType ?? '',
                                    'seating_capacity': seatingCapacity,
                                    'is_active': true,
                                    'assigned_driver_id': null,
                                    'created_at': FieldValue.serverTimestamp(),
                                  });

                                  // Increment total_vehicles count
                                  await _firestore
                                      .collection('vendors')
                                      .doc(_vendorId)
                                      .update({
                                    'total_vehicles':
                                        FieldValue.increment(1),
                                    'updated_at':
                                        FieldValue.serverTimestamp(),
                                  });

                                  if (!mounted) return;
                                  final messenger =
                                      ScaffoldMessenger.of(this.context);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                  messenger.showSnackBar(const SnackBar(
                                    content: Text(
                                        'Vehicle added successfully'),
                                    backgroundColor: Color(0xFF10B981),
                                  ));
                                } catch (e) {
                                  if (!mounted) return;
                                  setModalState(() => isSaving = false);
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(SnackBar(
                                          content: Text('Error: $e')));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Add Vehicle',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    makeCtrl.dispose();
    modelCtrl.dispose();
    plateCtrl.dispose();
    yearCtrl.dispose();
  });
}
Widget _dialogField(
  String label,
  String hint,
  TextEditingController ctrl, {
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
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
}

Widget _sectionLabel(String label) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary)),
      const SizedBox(height: 4),
      Divider(color: Colors.grey.shade200),
    ],
  );
}

  Widget _buildTimeField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon:
                const Icon(Icons.access_time, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

}

const Color _reviewInk = Color(0xFF111827);
const Color _reviewMuted = Color(0xFF6B7280);
const Color _reviewAmber = Color(0xFFF59E0B);
const Color _reviewRed = Color(0xFFEF4444);
const Color _reviewBlue = Color(0xFF3B82F6);

Widget _vendorReviewBadge(String label, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

String _reviewText(dynamic v) {
  if (v is String) return v.trim();
  if (v is num) return v.toString();
  return '';
}

bool _vendorDocAwaitingReview(
  Map<String, dynamic> data,
  Map<String, dynamic> docs,
  String key,
) {
  if (data['documents_pending_review'] != true) return false;
  if (!docs.containsKey('${key}_updated_at')) return false;
  final updated = docs['${key}_updated_at'];
  final reviewed = data['documents_reviewed_at'];
  if (updated is! Timestamp || reviewed is! Timestamp) return true;
  return updated.millisecondsSinceEpoch > reviewed.millisecondsSinceEpoch;
}

class VendorDriverReviewScreen extends StatefulWidget {
  final String driverId;

  const VendorDriverReviewScreen({super.key, required this.driverId});

  @override
  State<VendorDriverReviewScreen> createState() =>
      _VendorDriverReviewScreenState();
}

class _VendorDriverReviewScreenState extends State<VendorDriverReviewScreen> {
  static const _fields = [
    ['make', 'Make'],
    ['model', 'Model'],
    ['year', 'Year'],
    ['color', 'Color'],
    ['plate_number', 'Plate number'],
    ['type', 'Type'],
    ['seating_capacity', 'Seats'],
  ];
  static const _documents = [
    ['license', 'Driving license'],
    ['registration', 'Vehicle registration'],
    ['cnic', 'CNIC'],
  ];
  bool _busy = false;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('drivers').doc(widget.driverId);

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _reviewRed : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approve() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final done =
          await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(_ref);
        final d = snap.data() ?? <String, dynamic>{};
        final pending = d['pending_vehicle_update'];
        if (d['pending_vehicle_status'] != 'pending' || pending is! Map) {
          return false;
        }
        tx.update(_ref, {
          'vehicle': Map<String, dynamic>.from(pending),
          'vehicle_updated_at': FieldValue.serverTimestamp(),
          'pending_vehicle_status': 'approved',
          'pending_vehicle_reviewed_at': FieldValue.serverTimestamp(),
          'pending_vehicle_update': FieldValue.delete(),
          'pending_vehicle_reject_reason': FieldValue.delete(),
        });
        return true;
      });
      _snack(done
          ? 'Vehicle update approved'
          : 'This update was already reviewed');
    } catch (e) {
      _snack('Could not approve. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Reject vehicle update',
            style: TextStyle(
              color: _reviewInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 200,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setDialog(() {}),
            style: const TextStyle(color: _reviewInk),
            decoration: InputDecoration(
              hintText: 'Short reason for the driver',
              hintStyle: const TextStyle(color: _reviewMuted, fontSize: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _reviewMuted),
              ),
            ),
            TextButton(
              onPressed: ctrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, ctrl.text.trim()),
              style: TextButton.styleFrom(foregroundColor: _reviewRed),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), () => ctrl.dispose());
    return result;
  }

  Future<void> _reject() async {
    if (_busy) return;
    final reason = await _askReason();
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final done =
          await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(_ref);
        if (snap.data()?['pending_vehicle_status'] != 'pending') return false;
        tx.update(_ref, {
          'pending_vehicle_status': 'rejected',
          'pending_vehicle_reject_reason': reason,
          'pending_vehicle_reviewed_at': FieldValue.serverTimestamp(),
        });
        return true;
      });
      _snack(done
          ? 'Vehicle update rejected'
          : 'This update was already reviewed');
    } catch (e) {
      _snack('Could not reject. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markDocsReviewed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _ref.update({
        'documents_pending_review': false,
        'documents_reviewed_at': FieldValue.serverTimestamp(),
      });
      _snack('Documents marked as reviewed');
    } catch (e) {
      _snack('Could not update. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openImage(String title, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                  color: _reviewInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load image',
                      style: TextStyle(color: _reviewMuted),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _reviewInk,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _reviewMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _reviewInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareHeader() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _reviewMuted,
    );
    return const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Field', style: style)),
          Expanded(flex: 4, child: Text('Current', style: style)),
          Expanded(flex: 4, child: Text('New', style: style)),
        ],
      ),
    );
  }

  Widget _compareRow(String label, String current, String next) {
    final changed = current != next;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _reviewMuted),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              current.isEmpty ? 'Not set' : current,
              style: const TextStyle(fontSize: 13, color: _reviewInk),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              next.isEmpty ? 'Not set' : next,
              style: TextStyle(
                fontSize: 13,
                fontWeight: changed ? FontWeight.w700 : FontWeight.w400,
                color: changed ? AppColors.primary : _reviewInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(String title, String url, bool isNew) {
    final uploaded = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.error_outline,
            color: uploaded ? AppColors.primary : _reviewAmber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _reviewInk,
                  ),
                ),
                Text(
                  isNew
                      ? 'New upload'
                      : uploaded
                          ? 'Uploaded'
                          : 'Missing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isNew ? FontWeight.w600 : FontWeight.w400,
                    color: isNew ? _reviewBlue : _reviewMuted,
                  ),
                ),
              ],
            ),
          ),
          if (uploaded)
            TextButton(
              onPressed: () => _openImage(title, url),
              child: const Text(
                'View',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _reviewMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: _reviewInk),
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        title: const Text(
          'Vehicle & Documents',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _message('Could not load driver details. Please try again.');
          }
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final data = snap.data!.data();
          if (data == null) return _message('Driver not found.');
          final vehicle = data['vehicle'] is Map
              ? Map<String, dynamic>.from(data['vehicle'] as Map)
              : <String, dynamic>{};
          final pending = data['pending_vehicle_update'] is Map
              ? Map<String, dynamic>.from(data['pending_vehicle_update'] as Map)
              : null;
          final status = _reviewText(data['pending_vehicle_status']);
          final reason = _reviewText(data['pending_vehicle_reject_reason']);
          final docs = data['documents'] is Map
              ? Map<String, dynamic>.from(data['documents'] as Map)
              : <String, dynamic>{};
          final docsPending = data['documents_pending_review'] == true;
          final name = _reviewText(data['full_name']);
          final phone = _reviewText(data['phone_number']);
          final submitted = data['pending_vehicle_submitted_at'];
          final submittedLabel = submitted is Timestamp
              ? DateFormat('d MMM yyyy, h:mm a')
                  .format(submitted.toDate().toLocal())
              : '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              Text(
                name.isEmpty ? 'Driver' : name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 13, color: _reviewMuted),
                ),
              ],
              const SizedBox(height: 16),
              if (pending != null && status == 'pending')
                _card(
                  title: 'Vehicle update',
                  trailing: _vendorReviewBadge(
                    'Pending',
                    _reviewAmber,
                    Icons.hourglass_top,
                  ),
                  children: [
                    if (submittedLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Sent on $submittedLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _reviewMuted,
                          ),
                        ),
                      ),
                    _compareHeader(),
                    for (final f in _fields)
                      _compareRow(
                        f[1],
                        _reviewText(vehicle[f[0]]),
                        _reviewText(pending[f[0]]),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _reject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _reviewRed,
                              side: const BorderSide(color: _reviewRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _busy ? null : _approve,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _busy ? 'Saving...' : 'Approve',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                _card(
                  title: 'Vehicle',
                  trailing: status == 'rejected'
                      ? _vendorReviewBadge(
                          'Last change rejected',
                          _reviewRed,
                          Icons.block,
                        )
                      : status == 'approved'
                          ? _vendorReviewBadge(
                              'Last change approved',
                              AppColors.primary,
                              Icons.check_circle_outline,
                            )
                          : null,
                  children: [
                    for (final f in _fields)
                      _valueRow(f[1], _reviewText(vehicle[f[0]])),
                    if (status == 'rejected' && reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Reason: $reason',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _reviewRed,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              _card(
                title: 'Documents',
                trailing: docsPending
                    ? _vendorReviewBadge(
                        'New documents',
                        _reviewBlue,
                        Icons.description_outlined,
                      )
                    : null,
                children: [
                  _valueRow(
                    'License number',
                    _reviewText(data['license_number']),
                  ),
                  _valueRow(
                    'License expiry',
                    _reviewText(data['license_expiry']),
                  ),
                  const SizedBox(height: 4),
                  for (final doc in _documents)
                    _docTile(
                      doc[1],
                      _reviewText(docs['${doc[0]}_url']),
                      _vendorDocAwaitingReview(data, docs, doc[0]),
                    ),
                  if (docsPending) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _markDocsReviewed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Mark reviewed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
