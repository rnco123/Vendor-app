// // lib/screens/vendor_dashboard_screen.dart
// import 'dart:ui' as BorderType;

// import 'package:flutter/material.dart';
// import '../app_colors.dart';
// import 'vendor_drawer.dart';

// class VendorDashboardScreen extends StatelessWidget {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//  VendorDashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//          key: _scaffoldKey,
//       backgroundColor: const Color(0xFFF9FAFB),
//    appBar: AppBar(
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
//       body: ListView(
//         padding: const EdgeInsets.all(24),
//         children: [
//           // Dashboard heading + divider
//           const Text(
//             'Dashboard',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//           ),
//           const Divider(), // ← Added divider below heading
//           const SizedBox(height: 24),

//           // Stat cards — equal height via IntrinsicHeight
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   child: _buildStatCard(
//                     value: '12',
//                     label: 'Active Rides',
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatCard(
//                     value: '\$1,245',
//                     label: "Today's Earnings",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   child: _buildStatCard(
//                     value: '17',
//                     label: 'Available Drivers',
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatCard(
//                     value: '4.8',
//                     label: 'Avg. Rating',
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 32),

//           // Recent Activities heading + divider
//           const Text(
//             'Recent Activities',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//           ),
//           const Divider(), // ← Divider below "Recent Activities"
//           const SizedBox(height: 16),

//           // Individual activity cards
//           _buildActivityCard(
//             title: 'New Ride Request',
//             subtitle: 'From Downtown to Airport - 3 passengers',
//             action: 'Assign Driver',
//             onTap: () {},
//           ),
//           const SizedBox(height: 16),
//           _buildActivityCard(
//             title: 'Weekly Payout Sent',
//             subtitle: '\$2,430 transferred to bank',
//             action: 'View Details',
//             onTap: () {},
//           ),
//           const SizedBox(height: 16),
//           _buildActivityCard(
//             title: 'Ride Completed',
//             subtitle: 'Ride #458 successfully completed',
//             action: 'View Details',
//             onTap: () {},
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required String value,
//     required String label,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       decoration: BoxDecoration(
//         color: Colors.white, // ← Clearly white background
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.grey.shade200, // ← Visible border
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.06), // ← Subtle shadow
//             blurRadius: 12,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 14,
//               color: AppColors.textSecondary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActivityCard({
//     required String title,
//     required String subtitle,
//     required String action,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white, // ← White background
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.grey.shade200, // ← Visible border
//           width: 1,
//         ),
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
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: const TextStyle(
//               fontSize: 14,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: ElevatedButton(
//               onPressed: onTap,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: const Color(0xFFF9F9F9),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(
//                 action,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'dart:ui' as BorderType;
import 'package:poolx_partner/vendor/monitoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../shared/early_access_status_screen.dart' show handleRoleRootBack;
import 'vendor_drawer.dart';
import 'vendor_passenger_requests_screen.dart';


class VendorDashboardScreen extends StatefulWidget {
  VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Live stat streams ─────────────────────────────────────────────────

  // Active rides: status == driver_assigned or in_progress for this vendor
  late final Stream<List<VendorRequestDoc>> _requestsStream =
      VendorPassengerRequests.stream();

  Stream<int> get _activeRidesStream => _firestore
      .collection('active_rides')
      .where('vendorId', isEqualTo: _auth.currentUser?.uid)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.where((d) {
            if (VendorPassengerRequests.isAwaitingDriver(d.data())) {
              return false;
            }
            final st = VendorPassengerRequests.norm(d.data()['status']);
            return st == 'driver_assigned' || st == 'in_progress';
          }).length);

  // Available drivers under this vendor
  Stream<int> get _availableDriversStream => _firestore
      .collection('drivers')
      .where('vendor_id', isEqualTo: _auth.currentUser?.uid)
      .limit(300)
      .snapshots()
      .map((s) => s.docs
          .where((d) =>
              d.data()['is_available'] == true &&
              VendorPassengerRequests.norm(d.data()['approval_status']) ==
                  'approved')
          .length);

  // Today's earnings from payments
  Stream<int> get _todayEarningsStream {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _firestore
        .collection('payments')
        .where('vendorId', isEqualTo: _auth.currentUser?.uid)
        .limit(500)
        .snapshots()
        .map((s) => s.docs.where((doc) {
              final data = doc.data();
              final at = data['transaction_date'];
              return VendorPassengerRequests.norm(data['payment_status']) ==
                      'completed' &&
                  at is Timestamp &&
                  !at.toDate().isBefore(startOfDay);
            }).fold<int>(
                0,
                (sum, doc) =>
                    sum +
                    ((doc.data()['amount'] as num?)?.toInt() ?? 0)));
  }

  // Average rating from vendor doc
  Stream<String> get _avgRatingStream => _firestore
      .collection('vendors')
      .doc(_auth.currentUser?.uid)
      .snapshots()
      .map((s) =>
          (s.data()?['average_rating'] as num?)
              ?.toStringAsFixed(1) ??
          '0.0');

  // Recent rides (last 3) for activity feed
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      get _recentRidesStream => _firestore
          .collection('active_rides')
          .where('vendorId', isEqualTo: _auth.currentUser?.uid)
          .limit(200)
          .snapshots()
          .map((s) {
            final docs = s.docs.toList();
            int millis(QueryDocumentSnapshot<Map<String, dynamic>> d) {
              final ts = d.data()['timestamps'];
              final booked = ts is Map ? ts['booked_at'] : null;
              return booked is Timestamp ? booked.millisecondsSinceEpoch : 0;
            }
            docs.sort((a, b) => millis(b).compareTo(millis(a)));
            return docs.take(3).toList();
          });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        handleRoleRootBack(context);
      },
      child: _buildDashboard(context),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
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
        title: const Text('Carpool',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Dashboard',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const Divider(),
          const SizedBox(height: 24),

          // ── Stat Cards Row 1 ────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _activeRidesStream,
                    builder: (_, snap) => _buildStatCard(
                        value: '${snap.data ?? 0}',
                        label: 'Active Rides'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _todayEarningsStream,
                    builder: (_, snap) => _buildStatCard(
                        value: 'Rs ${snap.data ?? 0}',
                        label: "Today's Earnings"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stat Cards Row 2 ────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _availableDriversStream,
                    builder: (_, snap) => _buildStatCard(
                        value: '${snap.data ?? 0}',
                        label: 'Available Drivers'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<String>(
                    stream: _avgRatingStream,
                    builder: (_, snap) => _buildStatCard(
                        value: snap.data ?? '0.0',
                        label: 'Avg. Rating'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text('Passenger Requests',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                    SizedBox(width: 8),
                    VendorRequestsBadge(),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VendorPassengerRequestsScreen(),
                  ),
                ),
                child: const Text('View All',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          StreamBuilder<List<VendorRequestDoc>>(
            stream: _requestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                      'Could not load passenger requests. ${snapshot.error}',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 14)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }
              final requests = snapshot.data!;
              if (requests.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text('No new passenger requests',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 15)),
                  ),
                );
              }
              final shown = requests.take(3).toList();
              return Column(
                children: [
                  for (final doc in shown) ...[
                    VendorPassengerRequestCard(
                      key: ValueKey(doc.id),
                      rideId: doc.id,
                      ride: doc.data(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (requests.length > shown.length)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const VendorPassengerRequestsScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            'View all ${requests.length} requests',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Recent Activities ───────────────────────────────────────
          const Text('Recent Activities',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const Divider(),
          const SizedBox(height: 16),

          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _recentRidesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Could not load ride requests',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15)),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }

              final docs = snapshot.data ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text('No recent activity yet',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15)),
                  ),
                );
              }

              return Column(
                children: docs.asMap().entries.map((entry) {
                  final ride = entry.value.data();
                  final rideId = entry.value.id;
                  final awaitingDriver =
                      VendorPassengerRequests.isAwaitingDriver(ride);
                  final pendingRequest =
                      VendorPassengerRequests.isPending(ride) ||
                          awaitingDriver;
                  final status =
                      ride['status'] as String? ?? 'requested';
                  final pickup =
                      ride['pickup']?['address'] as String? ??
                          'Unknown';
                  final destination =
                      ride['destination']?['address'] as String? ??
                          'Unknown';
                  final passengerName =
                      ride['passenger_name'] as String? ?? 'Passenger';
                  final bookedAt =
                      ride['timestamps']?['booked_at'] as Timestamp?;
                  final timeStr = bookedAt != null
                      ? DateFormat('MMM d, h:mm a')
                          .format(bookedAt.toDate().toLocal())
                      : '';

                  // Map status to title/subtitle/action
                  String title;
                  String subtitle;
                  String action;
                  switch (status) {
                    case 'requested':
                    case 'searching':
                      title = 'New Ride Request';
                      subtitle =
                          '$passengerName • ${_shortAddr(pickup)} → ${_shortAddr(destination)}';
                      action = 'View Ride';
                      break;
                    case 'completed':
                      title = 'Ride Completed';
                      subtitle =
                          'Ride #${rideId.substring(0, 6).toUpperCase()} • $timeStr';
                      action = 'View Details';
                      break;
                    case 'cancelled':
                    case 'declined':
                      title = 'Ride Cancelled';
                      subtitle =
                          '$passengerName • $timeStr';
                      action = 'View Details';
                      break;
                    default:
                      title = 'Ride In Progress';
                      subtitle =
                          '$passengerName • ${_shortAddr(pickup)} → ${_shortAddr(destination)}';
                      action = 'Monitor';
                  }
                  if (pendingRequest) {
                    title = awaitingDriver
                        ? 'Awaiting Driver Acceptance'
                        : 'New Ride Request';
                    subtitle =
                        '$passengerName • ${_shortAddr(pickup)} → ${_shortAddr(destination)}';
                    action = 'Review Request';
                  }

                  return Column(
                    children: [
                      _buildActivityCard(
                        title: title,
                        subtitle: subtitle,
                        action: action,
                        onTap: () {
                          if (pendingRequest) {
                            VendorPassengerRequests.openDetails(
                                context, rideId);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const VendorRideDriverManagementScreen(),
                            ),
                          );
                        },
                      ),
                      if (entry.key < docs.length - 1)
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _shortAddr(String address) =>
      address.split(',').first.trim();

  Widget _buildStatCard({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFFF9F9F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(action,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}