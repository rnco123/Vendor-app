// // lib/screens/vendor_issue_details_screen.dart
// import 'package:flutter/material.dart';
// import '../app_colors.dart';

// class VendorIssueDetailsScreen extends StatelessWidget {
//   const VendorIssueDetailsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//            titleSpacing: 0,
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF9FAFB),
//               borderRadius: BorderRadius.circular(8),
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
//           'Issue Details',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInfoSection('Issue ID', '#ISSUE-1244'),
//             const SizedBox(height: 24),
//             _buildInfoSection('Title', 'Payment issue reported by driver'),
//             const SizedBox(height: 24),
//             _buildInfoSection(
//               'Description',
//               'Payment not received in driver wallet after ride completion.',
//             ),
//             const SizedBox(height: 24),
//             _buildInfoSection('Reported By', 'Driver'),
//             const SizedBox(height: 24),
//             _buildInfoSection('Ride ID', '##RIDE-9812'),
//             const SizedBox(height: 24),
//             const Text(
//               'Status',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFEF3C7),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Text(
//                 'Pending',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFFF59E0B),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoSection(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 15,
//             color: AppColors.textSecondary,
//             height: 1.5,
//           ),
//         ),
//       ],
//     );
//   }
// }





import 'dart:ui' as BorderType;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';

class VendorIssueDetailsScreen extends StatefulWidget {
  final String vendorId;
  const VendorIssueDetailsScreen({super.key, required this.vendorId});

  @override
  State<VendorIssueDetailsScreen> createState() =>
      _VendorIssueDetailsScreenState();
}

class _VendorIssueDetailsScreenState
    extends State<VendorIssueDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;

  // ── Fetch all reports whose ride_id belongs to this vendor ───────────
  Future<List<Map<String, dynamic>>> _fetchReports() async {
    // 1. Get all active_rides for this vendor
    final ridesSnap = await _firestore
        .collection('active_rides')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    final vendorRideIds = ridesSnap.docs.map((d) => d.id).toSet();

    if (vendorRideIds.isEmpty) return [];

    // 2. For each ride, fetch reports subcollection
    final List<Map<String, dynamic>> allReports = [];

    for (final rideDoc in ridesSnap.docs) {
      final reportsSnap = await _firestore
          .collection('active_rides')
          .doc(rideDoc.id)
          .collection('reports')
          .get();

      for (final reportDoc in reportsSnap.docs) {
        final data = reportDoc.data();
        allReports.add({
          ...data,
          'report_id': reportDoc.id,
          'ride_doc_id': rideDoc.id,
          // Pull ride-level fields we need
          'ride_pickup': rideDoc.data()['pickup']?['address'] ?? '',
          'ride_destination':
              rideDoc.data()['destination']?['address'] ?? '',
          'ride_status': rideDoc.data()['status'] ?? '',
          'driver_id': rideDoc.data()['driverId'] ?? '',
          'passenger_rating':
              rideDoc.data()['passenger_rating'] ?? 0,
          'fare_final': rideDoc.data()['fare']?['final_total'],
          'fare_estimated':
              rideDoc.data()['fare']?['estimated_total'] ?? 0,
        });
      }
    }

    // Sort by created_at descending
    allReports.sort((a, b) {
      final aT = a['created_at'];
      final bT = b['created_at'];
      if (aT == null || bT == null) return 0;
      final aMs = aT is Timestamp
          ? aT.millisecondsSinceEpoch
          : aT as int;
      final bMs = bT is Timestamp
          ? bT.millisecondsSinceEpoch
          : bT as int;
      return bMs.compareTo(aMs);
    });

    return allReports;
  }

  Future<void> _updateStatus(
      String rideDocId, String reportId, String newStatus) async {
    await _firestore
        .collection('active_rides')
        .doc(rideDocId)
        .collection('reports')
        .doc(reportId)
        .update({'status': newStatus});
    setState(() {}); // refresh
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
            color: BorderType.Color.fromARGB(255, 179, 178, 178),
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
        title: const Text('Reports & Issues',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text('No reports found',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('All rides are running smoothly.',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // ── Summary header ──────────────────────────────
                final pending = reports
                    .where((r) => (r['status'] ?? '') == 'pending')
                    .length;
                final resolved = reports
                    .where((r) => (r['status'] ?? '') == 'resolved')
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports & Issues',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Summary chips
                    Row(
                      children: [
                        _summaryChip(
                            '${reports.length} Total',
                            Icons.report_outlined,
                            AppColors.primary),
                        const SizedBox(width: 10),
                        _summaryChip(
                            '$pending Pending',
                            Icons.hourglass_empty,
                            const Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        _summaryChip(
                            '$resolved Resolved',
                            Icons.check_circle_outline,
                            const Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              final r = reports[index - 1];
              return _buildReportCard(r);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r) {
    final reportId = r['report_id'] as String? ?? '';
    final rideDocId = r['ride_doc_id'] as String? ?? '';
    final status = r['status'] as String? ?? 'pending';
    final issueType = r['issue_type'] as String? ?? 'Issue';
    final issueDetail = r['issue_detail'] as String? ?? '';
    final driverName = r['driver_name'] as String? ?? 'Unknown';
    final reporterRole = r['reporterRole'] as String? ?? '';
    final rideId = r['ride_id'] as String? ?? rideDocId;
    final pickup = r['ride_pickup'] as String? ?? '';
    final destination = r['ride_destination'] as String? ?? '';
    final passengerRating = (r['passenger_rating'] as num?)?.toInt() ?? 0;
    final fareRaw = r['fare_final'] ?? r['fare_estimated'];
    final fare = (fareRaw as num?)?.toInt() ?? 0;

    // Timestamp
    final createdAt = r['created_at'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('MMM d, yyyy • h:mm a')
          .format(createdAt.toDate().toLocal());
    }

    // Status styling
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        statusLabel = 'Resolved';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'dismissed':
        statusColor = Colors.grey;
        statusBg = Colors.grey.shade100;
        statusLabel = 'Dismissed';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ───────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      issueType,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Card body ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue detail
                Text(
                  issueDetail,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5),
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 10),

                // ── Info rows ─────────────────────────────────
                _infoRow(Icons.person_outline, 'Driver', driverName),
                const SizedBox(height: 8),
                _infoRow(
                    reporterRole == 'passenger'
                        ? Icons.emoji_people_outlined
                        : Icons.drive_eta_outlined,
                    'Reported By',
                    reporterRole.isNotEmpty
                        ? '${reporterRole[0].toUpperCase()}${reporterRole.substring(1)}'
                        : 'Unknown'),
                const SizedBox(height: 8),
                _infoRow(
                    Icons.confirmation_number_outlined,
                    'Ride ID',
                    '#${rideId.substring(0, 8).toUpperCase()}'),
                const SizedBox(height: 8),

                // Route
                if (pickup.isNotEmpty || destination.isNotEmpty) ...[
                  _infoRow(
                      Icons.route_outlined,
                      'Route',
                      '${pickup.split(',').first} → ${destination.split(',').first}'),
                  const SizedBox(height: 8),
                ],

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star_border,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('Passenger Rating: ',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < passengerRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: i < passengerRating
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('($passengerRating/5)',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),

                // Fare
                if (fare > 0)
                  _infoRow(Icons.payments_outlined, 'Fare',
                      'Rs $fare'),

                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                      Icons.access_time, 'Reported At', dateStr),
                ],

                const SizedBox(height: 16),

                // ── Action buttons (only for pending) ──────────
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(
                              rideDocId, reportId, 'resolved'),
                          icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Resolve'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(0xFF10B981),
                            side: const BorderSide(
                                color: Color(0xFF10B981)),
                            backgroundColor:
                                const Color(0xFF10B981)
                                    .withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(
                              rideDocId, reportId, 'dismissed'),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 16),
                          label: const Text('Dismiss'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side:
                                BorderSide(color: Colors.grey.shade400),
                            backgroundColor:
                                Colors.grey.withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),

                if (status == 'resolved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('Issue Resolved',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}