
// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────

import 'dart:ui' as BorderType;

import 'package:poolx_partner/app_colors.dart';
import 'package:poolx_partner/vendor/vendor_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../shared/app_log.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

class ReportModel {
  final String id;
  final String rideId;
  final String issueType;
  final String issueDetail;
  final String driverName;
  final String reporterRole;
  final String reportedBy;
  final String status; // pending | dispute | escalated | resolved
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.rideId,
    required this.issueType,
    required this.issueDetail,
    required this.driverName,
    required this.reporterRole,
    required this.reportedBy,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc, String rideId) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      rideId: rideId,
      issueType: d['issue_type'] ?? '',
      issueDetail: d['issue_detail'] ?? '',
      driverName: d['driver_name'] ?? '',
      reporterRole: d['reporterRole'] ?? 'passenger',
      reportedBy: d['reportedBy'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
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
  final int onTimePercent;
  final String? assignedIncentive;

  DriverPerformanceModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.phone,
    required this.totalTrips,
    required this.rating,
    this.badge,
    required this.vendorId,
    required this.onTimePercent,
    this.assignedIncentive,
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
      onTimePercent: (d['on_time_percent'] ?? 0) as int,
      assignedIncentive: d['assigned_incentive'],
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
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class _AllReportsWidget extends StatefulWidget {
  final String vendorId;
  final FirebaseFirestore firestore;
  final VoidCallback? onStatusChanged;

  const _AllReportsWidget({
    required this.vendorId,
    required this.firestore,
    this.onStatusChanged,
  });

  @override
  State<_AllReportsWidget> createState() => _AllReportsWidgetState();
}

class _AllReportsWidgetState extends State<_AllReportsWidget> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }
Future<List<Map<String, dynamic>>> _loadReports() async {
  debugPrint('==> Loading reports for vendorId: ${widget.vendorId}');

  final ridesSnap = await widget.firestore
      .collection('active_rides')
      .where('vendorId', isEqualTo: widget.vendorId)
      .limit(50)
      .get();

  debugPrint('==> Vendor rides: ${ridesSnap.docs.length}');

  if (ridesSnap.docs.isEmpty) return [];

  final List<Map<String, dynamic>> allReports = [];

  for (final rideDoc in ridesSnap.docs) {
    final rideData = rideDoc.data();

    final reportsSnap = await widget.firestore
        .collection('active_rides')
        .doc(rideDoc.id)
        .collection('reports')
        .limit(20)
        .get();

    debugPrint('==> Ride ${rideDoc.id} → ${reportsSnap.docs.length} reports');

    for (final reportDoc in reportsSnap.docs) {
      debugPrint('==> Report: ${reportDoc.data()}');
      allReports.add({
        ...reportDoc.data(),
        'report_id': reportDoc.id,
        'ride_doc_id': rideDoc.id,
        'ride_pickup': rideData['pickup']?['address'] as String? ?? '',
        'ride_destination': rideData['destination']?['address'] as String? ?? '',
        'passenger_rating': (rideData['passenger_rating'] as num?)?.toInt() ?? 0,
        'fare_display': ((rideData['fare']?['final_total'] ??
                rideData['fare']?['estimated_total']) as num?)?.toInt() ?? 0,
      });
    }
  }

  allReports.sort((a, b) {
    int toMs(dynamic v) {
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is int) return v;
      return 0;
    }
    return toMs(b['created_at']).compareTo(toMs(a['created_at']));
  });

  debugPrint('==> Total reports: ${allReports.length}');
  return allReports;
}
 
  void _refresh() {
    setState(() => _reportsFuture = _loadReports());
    widget.onStatusChanged?.call();
  }

  Future<void> _updateStatus(
      String rideDocId, String reportId, String newStatus) async {
    await widget.firestore
        .collection('active_rides')
        .doc(rideDocId)
        .collection('reports')
        .doc(reportId)
        .update({'status': newStatus});
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _emptyStateLocal('Error loading reports.');
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _emptyStateLocal('No reports found for your rides.');
        }

        // Summary row
        final pending =
            reports.where((r) => r['status'] == 'pending').length;
        final resolved =
            reports.where((r) => r['status'] == 'resolved').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary chips ───────────────────────────────────
            Row(
              children: [
                _chip('${reports.length} Total',
                    Icons.report_outlined, AppColors.primary),
                const SizedBox(width: 8),
                _chip('$pending Pending',
                    Icons.hourglass_empty, const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _chip('$resolved Resolved',
                    Icons.check_circle_outline, const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Report cards ────────────────────────────────────
            ...reports.map((r) => _buildReportCard(r)),
          ],
        );
      },
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
    final passengerRating =
        (r['passenger_rating'] as num?)?.toInt() ?? 0;
    final fare = (r['fare_display'] as num?)?.toInt() ?? 0;

    final createdAt = r['created_at'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('MMM d, yyyy • h:mm a')
          .format(createdAt.toDate().toLocal());
    }

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
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ──────────────────────────────────────
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
                Row(children: [
                  const Icon(Icons.flag_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(issueType,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20)),
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

          // ── Body ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issueDetail,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5)),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 10),

                _infoRow(Icons.person_outline, 'Driver', driverName),
                const SizedBox(height: 6),
                _infoRow(
                    reporterRole == 'passenger'
                        ? Icons.emoji_people_outlined
                        : Icons.drive_eta_outlined,
                    'Reported By',
                    reporterRole.isEmpty
                        ? 'Unknown'
                        : '${reporterRole[0].toUpperCase()}${reporterRole.substring(1)}'),
                const SizedBox(height: 6),
                _infoRow(
                    Icons.confirmation_number_outlined,
                    'Ride',
                    '#${rideId.length >= 8 ? rideId.substring(0, 8).toUpperCase() : rideId.toUpperCase()}'),
                if (pickup.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(Icons.route_outlined, 'Route',
                      '${pickup.split(',').first} → ${destination.split(',').first}'),
                ],
                if (passengerRating > 0) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_border,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('Rating: ',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    ...List.generate(
                      5,
                      (i) => Icon(
                          i < passengerRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: i < passengerRating
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade300),
                    ),
                    const SizedBox(width: 4),
                    Text('($passengerRating/5)',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ]),
                ],
                if (fare > 0) ...[
                  const SizedBox(height: 6),
                  _infoRow(
                      Icons.payments_outlined, 'Fare', 'Rs $fare'),
                ],
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(Icons.access_time, 'Reported', dateStr),
                ],
                const SizedBox(height: 14),

                // ── Action buttons ─────────────────────────────
                if (status == 'pending')
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(
                            rideDocId, reportId, 'resolved'),
                        icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16),
                        label: const Text('Resolve'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(
                              color: Color(0xFF10B981)),
                          backgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
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
                          side: BorderSide(color: Colors.grey.shade400),
                          backgroundColor:
                              Colors.grey.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ])
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: status == 'resolved'
                          ? const Color(0xFFECFDF5)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            status == 'resolved'
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: status == 'resolved'
                                ? const Color(0xFF10B981)
                                : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                            status == 'resolved'
                                ? 'Issue Resolved'
                                : 'Issue Dismissed',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: status == 'resolved'
                                    ? const Color(0xFF10B981)
                                    : Colors.grey)),
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

  Widget _chip(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
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

  Widget _emptyStateLocal(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(msg,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
      ),
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
  _AllReportsWidget? _allReportsWidget;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
Stream<QuerySnapshot>? _driverPerfStream;
  int _activeRides = 0;
  int _totalDrivers = 0;
  int _pendingComplaints = 0;
  double _avgRating = 0.0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchStats();

     if (_vendorId != null) {
    _driverPerfStream = _firestore
        .collection('driver_performance')
        .where('vendor_id', isEqualTo: _vendorId)
        .limit(50)
        .snapshots();
         _allReportsWidget = _AllReportsWidget(
      vendorId: _vendorId!,
      firestore: _firestore,
      onStatusChanged: _fetchStats,
    );
    
  }
  }

  // ─────────────────────────────────────────────
  //  STATS
  //  Reports live inside active_rides/{id}/reports subcollection
  // ─────────────────────────────────────────────
  Future<void> _fetchStats() async {
    if (_vendorId == null) return;
    if (mounted) setState(() => _statsLoading = true);

    try {
      // 1. All vendor rides
      final ridesSnap = await _firestore
          .collection('active_rides')
          .where('vendorId', isEqualTo: _vendorId)
          .get();

      final activeCount = ridesSnap.docs.length;

      // 2. Pending reports across all ride subcollections
      int pendingCount = 0;
      final reportFutures = ridesSnap.docs.map((ride) => _firestore
          .collection('active_rides')
          .doc(ride.id)
          .collection('reports')
       
          .get());
      final reportResults = await Future.wait(reportFutures);
      for (final r in reportResults) {
        pendingCount += r.size;
      }

      // 3. Driver performance
      final driverSnap = await _firestore
          .collection('driver_performance')
          .where('vendor_id', isEqualTo: _vendorId)
          .get();

      double totalRating = 0;
      for (final doc in driverSnap.docs) {
        totalRating += ((doc.data())['rating'] ?? 0.0).toDouble();
      }

      final driverCount = driverSnap.docs.length;

      if (mounted) {
        setState(() {
          _activeRides = activeCount;
          _totalDrivers = driverCount;
          _pendingComplaints = pendingCount;
          _avgRating = driverCount == 0
              ? 0.0
              : totalRating / driverCount;
          _statsLoading = false;
        });
      }
    } catch (e, st) { AppLog.caught('lib/vendor/vendor_driver_perf.dart', e, st); if (mounted) setState(() => _statsLoading = false); }
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
              fontWeight: FontWeight.w600),
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
                  color: AppColors.textPrimary),
            ),
            const Divider(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24)),
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
    final s1 = _statsLoading ? '...' : _activeRides.toString();
    final s2 = _statsLoading ? '...' : _totalDrivers.toString();
    final s3 = _statsLoading ? '...' : _pendingComplaints.toString();
    final s4 = _statsLoading
        ? '...'
        : (_avgRating == 0.0 ? '—' : _avgRating.toStringAsFixed(1));

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(s1, 'Active Rides')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(s2, 'Total Drivers')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(s3, 'Pending Issues')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(s4, 'Avg. Rating')),
          ],
        ),
      ],
    );
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
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
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

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
    
Widget _buildComplaintsContent() {
  if (_vendorId == null) return _emptyState('Not logged in.');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Recent Issues & Complaints',
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
      ),
      const Divider(),
      const SizedBox(height: 16),
      _allReportsWidget ?? _emptyState('Loading...'),
    ],
  );
}

Widget _buildDriversContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Driver Performance',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const Divider(),
              const SizedBox(height: 12),
              _addDriverPerfButton(fullWidth: true),
            ],
          );
        }
        return Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                  child: Text('Driver Performance',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary))),
              const SizedBox(width: 16),
              _addDriverPerfButton(fullWidth: false),
            ],
          ),
          const Divider(),
        ]);
      }),
      const SizedBox(height: 16),
      StreamBuilder<QuerySnapshot>(
     
       stream: _driverPerfStream ?? const Stream.empty(),
  builder: (context, snap) {
          // ── Only show loader on first load, not on updates ──
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return _emptyState('Error loading drivers. Please try again.');
          }
          final drivers = snap.data?.docs
                  .map((d) => DriverPerformanceModel.fromDoc(d))
                  .toList() ??
              [];
          drivers.sort((a, b) => b.rating.compareTo(a.rating));
          if (drivers.isEmpty) {
            return _emptyState(
                'No driver performance records.\nTap "Add Driver perf." to get started.');
          }
          return Column(
            children: drivers.asMap().entries.map((e) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: e.key < drivers.length - 1 ? 12 : 0),
                child: _buildDriverCard(e.value),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}
  
  
  
  
  Widget _addDriverPerfButton({required bool fullWidth}) {
    return ElevatedButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const VendorAddDriverPerformanceScreen()),
        );
        _fetchStats();
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Driver perf.'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDriverCard(DriverPerformanceModel driver) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isSmall ? 25 : 30,
                  backgroundColor: const Color(0xFFE8E8E8),
                  child: Icon(Icons.person,
                      size: isSmall ? 28 : 32,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${driver.driverName} • ${driver.driverId}',
                        style: TextStyle(
                            fontSize: isSmall ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${driver.phone} • ${driver.totalTrips} trips',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
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
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star,
                            size: 16, color: Color(0xFFFFA726)),
                      ],
                    ),
                    if (driver.badge != null && driver.badge!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(driver.badge!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSmall)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF4A90E2),
                      bg: const Color(0xFFE3F2FD),
                      onPressed: () => _navigateEditDriver(driver),
                      fullWidth: true),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _actionButton(
                          icon: Icons.visibility_outlined,
                          label: 'View',
                          color: const Color(0xFFFFA726),
                          bg: const Color(0xFFFFF3E0),
                          onPressed: () => _navigateEditDriver(driver),
                          fullWidth: false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                          icon: Icons.delete_outline,
                          label: 'Remove',
                          color: const Color(0xFFA13D38),
                          bg: const Color(0xFFFFEBEE),
                          onPressed: () => _confirmDeleteDriver(driver),
                          fullWidth: false),
                    ),
                  ]),
                ],
              )
            else
              Row(children: [
                Expanded(
                    child: _actionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: const Color(0xFF4A90E2),
                        bg: const Color(0xFFE3F2FD),
                        onPressed: () => _navigateEditDriver(driver),
                        fullWidth: false)),
                const SizedBox(width: 8),
                Expanded(
                    child: _actionButton(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                        color: const Color(0xFFFFA726),
                        bg: const Color(0xFFFFF3E0),
                        onPressed: () => _navigateEditDriver(driver),
                        fullWidth: false)),
                const SizedBox(width: 8),
                Expanded(
                    child: _actionButton(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        color: const Color(0xFFA13D38),
                        bg: const Color(0xFFFFEBEE),
                        onPressed: () => _confirmDeleteDriver(driver),
                        fullWidth: false)),
              ]),
            const SizedBox(height: 8),
            _actionButton(
                icon: Icons.payments_outlined,
                label: 'Pay Driver',
                color: AppColors.primary,
                bg: AppColors.primary.withValues(alpha: 0.08),
                onPressed: () => _openPayDriver(driver),
                fullWidth: true),
          ],
        ),
      );
    });
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
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
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: fullWidth ? const Size(double.infinity, 40) : null,
      ),
    );
  }

  void _navigateEditDriver(DriverPerformanceModel driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              VendorAddDriverPerformanceScreen(existingDriver: driver)),
    ).then((_) => _fetchStats());
  }

  void _openPayDriver(DriverPerformanceModel driver) {
    final id = driver.driverId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This record is not linked to a driver account.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VendorPayDriverScreen(
              driverId: id, driverName: driver.driverName)),
    );
  }

  Future<void> _confirmDeleteDriver(DriverPerformanceModel driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Driver'),
        content:
            Text('Remove "${driver.driverName}" from performance records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: Color(0xFFA13D38)))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore
          .collection('driver_performance')
          .doc(driver.id)
          .delete();
      _fetchStats();
    }
  }

  // ═════════════════════════════════════════════
  //  TAB 2 – INCENTIVES
  // ═════════════════════════════════════════════

  Widget _buildIncentivesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Incentive Programs',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showIncentiveDialog(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _vendorId == null
              ? const Stream.empty()
              : _firestore
                  .collection('incentives')
                  .where('vendor_id', isEqualTo: _vendorId)
                  .limit(40)
                  .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _emptyState('Error loading incentives. Please try again.');
            }
            final incentives = snap.data?.docs
                    .map((d) => IncentiveModel.fromDoc(d))
                    .toList() ??
                [];
            // Sort client-side newest first
            incentives.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (incentives.isEmpty) {
              return _emptyState(
                  'No incentive programs yet.\nTap "Create" to add one.');
            }
            return Column(
              children: incentives.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < incentives.length - 1 ? 12 : 0),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incentive.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(incentive.criteria,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _iconBtn(
              icon: Icons.edit,
              color: const Color(0xFF4A90E2),
              bg: const Color(0xFFE3F2FD),
              onPressed: () => _showIncentiveDialog(incentive)),
          const SizedBox(width: 8),
          _iconBtn(
              icon: Icons.delete_outline,
              color: const Color(0xFFA13D38),
              bg: const Color(0xFFFFEBEE),
              onPressed: () => _confirmDeleteIncentive(incentive)),
        ],
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required Color bg,
      required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onPressed,
          padding: EdgeInsets.zero),
    );
  }

  void _showIncentiveDialog(IncentiveModel? existing) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final criteriaCtrl =
        TextEditingController(text: existing?.criteria ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(existing == null ? 'Create Incentive' : 'Edit Incentive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Top Performer',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: criteriaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Criteria',
                  hintText: 'e.g. rating > 4.8 & 50+ trips',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
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
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFA13D38)))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore
          .collection('incentives')
          .doc(incentive.id)
          .delete();
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
class VendorAddDriverPerformanceScreen extends StatefulWidget {
  /// Pass an existing record to switch into edit mode
  final dynamic existingDriver; // DriverPerformanceModel or null

  const VendorAddDriverPerformanceScreen({super.key, this.existingDriver});

  @override
  State<VendorAddDriverPerformanceScreen> createState() =>
      _VendorAddDriverPerformanceScreenState();
}

class _VendorAddDriverPerformanceScreenState
    extends State<VendorAddDriverPerformanceScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? get _vendorId => _auth.currentUser?.uid;

  bool get _isEditing => widget.existingDriver != null;

  // ── Form state ──
  String? _selectedDriverId; // uid from 'drivers' collection
  String _driverName = '';
  String _driverId = ''; // display ID e.g. D-1002
  final _phoneCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _tripsCtrl = TextEditingController();
  final _onTimeCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  String? _selectedIncentiveId;
  String? _selectedIncentiveTitle;

  // ── Fetched data ──
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _incentives = [];
  bool _loadingDrivers = true;
  bool _loadingIncentives = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _loadIncentives();
    _prefillIfEditing();
  }

  void _prefillIfEditing() {
    if (!_isEditing) return;
    final d = widget.existingDriver;
    _driverName = d.driverName ?? '';
    _driverId = d.driverId ?? '';
    _phoneCtrl.text = d.phone ?? '';
    _ratingCtrl.text = d.rating?.toStringAsFixed(1) ?? '';
    _tripsCtrl.text = d.totalTrips?.toString() ?? '';
    _onTimeCtrl.text = d.onTimePercent?.toString() ?? '';
    _badgeCtrl.text = d.badge ?? '';
    _selectedIncentiveTitle = d.assignedIncentive;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _ratingCtrl.dispose();
    _tripsCtrl.dispose();
    _onTimeCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  LOAD: drivers from 'drivers' collection under this vendor
  // ─────────────────────────────────────────────
  Future<void> _loadDrivers() async {
    if (_vendorId == null) return;
    try {
      // Fetch drivers that belong to this vendor
      final snap = await _firestore
          .collection('drivers')
          .where('vendor_id', isEqualTo: _vendorId)
          .get();

      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'uid': doc.id,
          'name': d['name'] ?? d['full_name'] ?? 'Unknown',
          'phone': d['phone'] ?? d['phone_number'] ?? '',
          'driver_id': d['firebase_uid'] ?? d['driver_id'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _drivers = list;
          _loadingDrivers = false;
        });
      }
    } catch (e, st) { AppLog.caught('lib/vendor/vendor_driver_perf.dart', e, st); if (mounted) setState(() => _loadingDrivers = false); }
  }

  // ─────────────────────────────────────────────
  //  LOAD: incentives from 'incentives' collection for this vendor
  // ─────────────────────────────────────────────
  Future<void> _loadIncentives() async {
    if (_vendorId == null) return;
    try {
      final snap = await _firestore
          .collection('incentives')
          .where('vendor_id', isEqualTo: _vendorId)
          .get();

      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'title': d['title'] ?? '',
          'criteria': d['criteria'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _incentives = list;
          _loadingIncentives = false;
        });
      }
    } catch (e, st) { AppLog.caught('lib/vendor/vendor_driver_perf.dart', e, st); if (mounted) setState(() => _loadingIncentives = false); }
  }

  // ─────────────────────────────────────────────
  //  SAVE to Firestore
  // ─────────────────────────────────────────────
 Future<void> _save() async {
  if (_vendorId == null) return;

  if (_driverName.isEmpty) {
    _showSnack('Please select a driver.');
    return;
  }
  if (_ratingCtrl.text.trim().isEmpty) {
    _showSnack('Please enter a rating.');
    return;
  }

  final ratingVal = double.tryParse(_ratingCtrl.text.trim());
  if (ratingVal == null || ratingVal < 0 || ratingVal > 5) {
    _showSnack('Rating must be between 0.0 and 5.0.');
    return;
  }

  setState(() => _saving = true);

  final data = {
    'vendor_id': _vendorId,
    'driver_id': _driverId,
    'driver_name': _driverName,
    'phone': _phoneCtrl.text.trim(),
    'rating': ratingVal,
    'total_trips': int.tryParse(_tripsCtrl.text.trim()) ?? 0,
    'on_time_percent': int.tryParse(_onTimeCtrl.text.trim()) ?? 0,
    'badge': _badgeCtrl.text.trim().isEmpty ? null : _badgeCtrl.text.trim(),
    'assigned_incentive': _selectedIncentiveTitle,
    'updated_at': FieldValue.serverTimestamp(),
  };

  try {
    // ── Check if existing doc id is valid ──────────────────
    final existingId = widget.existingDriver?.id as String?;

    if (_isEditing && existingId != null && existingId.isNotEmpty) {
      // UPDATE existing record
      await _firestore
          .collection('driver_performance')
          .doc(existingId)
          .update(data);
      _showSnack('Driver performance updated.');
    } else {
      // ADD new record
      data['created_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('driver_performance').add(data);
      _showSnack('Driver performance added.');
    }

    if (mounted) Navigator.pop(context);
  } catch (e) {
    _showSnack('Error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
  // ─────────────────────────────────────────────
  //  DELETE (only in edit mode)
  // ─────────────────────────────────────────────
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Record'),
        content: Text('Remove performance record for "$_driverName"?'),
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
      await _firestore
          .collection('driver_performance')
          .doc(widget.existingDriver.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(
          bottom: BorderSide(
            color: BorderType.Color.fromARGB(255, 220, 220, 220),
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Driver Performance' : 'Add Driver Performance',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Driver Name Dropdown ──
            _sectionLabel('Driver Name'),
            const SizedBox(height: 8),
            _loadingDrivers
                ? const Center(child: CircularProgressIndicator())
                : _drivers.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No drivers found for your account.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildDropdown(
                    value: _selectedDriverId,
                    hint: _isEditing ? _driverName : 'Select driver',
                    items: _drivers
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d['uid'] as String,
                            child: Text(d['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final found = _drivers.firstWhere(
                        (d) => d['uid'] == val,
                        orElse: () => {},
                      );
                      setState(() {
                        _selectedDriverId = val;
                        _driverName = found['name'] ?? '';
                        _driverId = found['driver_id'] ?? '';
                        if (_phoneCtrl.text.isEmpty) {
                          _phoneCtrl.text = found['phone'] ?? '';
                        }
                      });
                    },
                  ),
            const SizedBox(height: 20),

            // ── Phone ──
            _sectionLabel('Phone'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _phoneCtrl,
              hint: '+92 321 1234 5678',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // ── Rating ──
            _sectionLabel('Rating (0.0 – 5.0)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _ratingCtrl,
              hint: '4.5',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Metrics ──
            const Text(
              'Metrics (last 30 days)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Total Trips'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _tripsCtrl,
                        hint: '125',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('On-time %'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _onTimeCtrl,
                        hint: '95',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Badge ──
            _sectionLabel('Badge (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _badgeCtrl,
              hint: 'e.g. Weekly Bonus, High Util',
            ),
            const SizedBox(height: 24),

            // ── Assign Incentive ──
            _sectionLabel('Assign Incentive'),
            const SizedBox(height: 8),
            _loadingIncentives
                ? const Center(child: CircularProgressIndicator())
                : _buildDropdown<String>(
                    value: _selectedIncentiveId,
                    hint: _isEditing && _selectedIncentiveTitle != null
                        ? _selectedIncentiveTitle!
                        : 'None',
                    items: [
                      const DropdownMenuItem<String>(
                        value: '__none__',
                        child: Text('None'),
                      ),
                      ..._incentives.map(
                        (inc) => DropdownMenuItem<String>(
                          value: inc['id'] as String,
                          child: Text(inc['title'] as String),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedIncentiveId = val;
                        if (val == '__none__' || val == null) {
                          _selectedIncentiveTitle = null;
                        } else {
                          final found = _incentives.firstWhere(
                            (i) => i['id'] == val,
                            orElse: () => {},
                          );
                          _selectedIncentiveTitle = found['title'] as String?;
                        }
                      });
                    },
                  ),
            const SizedBox(height: 8),
            const Text(
              'Applying an incentive will show on payouts.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : (_isEditing ? _delete : () => Navigator.pop(context)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isEditing
                          ? const Color(0xFFA13D38)
                          : AppColors.primary,
                      side: BorderSide(
                        color: _isEditing
                            ? const Color(0xFFA13D38)
                            : AppColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Remove' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Update' : 'Save',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

const Color _payInk = AppColors.textPrimary;
const Color _payMuted = Color(0xFF8E8E8E);
const Color _payLine = Color(0xFF262626);
const Color _payBlue = Color(0xFF3B82F6);
const Color _payCardBg = Color(0xFF1A1A1A);

const Map<String, String> _payMethodLabels = {
  'bank_transfer': 'Bank Transfer',
  'jazzcash': 'JazzCash',
  'easypaisa': 'Easypaisa',
};

const Map<String, IconData> _payMethodIcons = {
  'bank_transfer': Icons.account_balance_outlined,
  'jazzcash': Icons.phone_android,
  'easypaisa': Icons.account_balance_wallet_outlined,
};

Map<String, dynamic> _payMap(dynamic raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

num _payNum(dynamic v) => v is num ? v : 0;

String _payPkr(dynamic v) =>
    'PKR ${NumberFormat('#,##0').format(_payNum(v).round())}';

DateTime? _payDate(dynamic v) =>
    v is num && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

String _payPercent(Map<String, dynamic> s) {
  final p = _payNum(s['commission_percent']);
  return '${p % 1 == 0 ? p.toInt() : p}%';
}

String _payPeriod(Map<String, dynamic> s) {
  final a = _payDate(s['period_start']);
  final b = _payDate(s['period_end']);
  if (a == null || b == null) return 'All pending trips';
  return '${DateFormat('d MMM').format(a)} - ${DateFormat('d MMM yyyy').format(b)}';
}

String _payAccount(Map<String, dynamic> m) {
  final bank = (m['bank_name'] as String? ?? '').trim();
  final last4 = (m['account_last4'] as String? ?? '').trim();
  return [
    if (bank.isNotEmpty) bank,
    if (last4.isNotEmpty) 'AC ****$last4',
  ].join(' · ');
}

String _payMasked(Map<String, dynamic> m) {
  final last4 = (m['account_last4'] as String? ?? '').trim();
  return last4.isEmpty ? '—' : '**** **** **** $last4';
}

Widget _payRow(
  String label,
  String value, {
  Color valueColor = _payInk,
  bool strong = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? _payInk : _payMuted,
              fontSize: strong ? 15 : 12,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: strong ? 17 : 12,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _payCard(Widget child) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _payCardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _payLine),
    ),
    child: child,
  );
}

Widget _payNote(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2214),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF4A3A1A)),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFF5C26B), fontSize: 13),
    ),
  );
}

PreferredSizeWidget _payAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    titleSpacing: 16,
    title: Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF262626),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _payInk,
              size: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _payInk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

ButtonStyle _payButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
    disabledForegroundColor: Colors.white70,
    elevation: 0,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
  );
}

class VendorPayDriverScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const VendorPayDriverScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<VendorPayDriverScreen> createState() => _VendorPayDriverScreenState();
}

class _VendorPayDriverScreenState extends State<VendorPayDriverScreen> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _methods = [];
  String? _method;
  String? _error;
  bool _loading = true;
  bool _paying = false;

  HttpsCallable get _callable =>
      FirebaseFunctions.instance.httpsCallable('vendorPayDriver');

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _errorText(Object e) {
    if (e is FirebaseFunctionsException) {
      final msg = (e.message ?? '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Something went wrong. Please try again.';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _callable.call(<String, dynamic>{
        'driverId': widget.driverId,
        'preview': true,
      });
      final data = _payMap(result.data);
      final raw = data['methods'];
      final methods =
          raw is List ? raw.map(_payMap).toList() : <Map<String, dynamic>>[];
      final active = (data['active_method'] as String? ?? '').trim();
      if (!mounted) return;
      setState(() {
        _summary = data;
        _methods = methods;
        _method = methods.any((m) => m['method'] == active)
            ? active
            : methods.isNotEmpty
                ? methods.first['method'] as String?
                : null;
        _loading = false;
      });
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_driver_perf.dart', e, st);
      if (!mounted) return;
      setState(() {
        _error = _errorText(e);
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _selectedMethod => _methods.firstWhere(
        (e) => e['method'] == _method,
        orElse: () => <String, dynamic>{},
      );

  String _methodLine(String method) {
    final m = _methods.firstWhere(
      (e) => e['method'] == method,
      orElse: () => <String, dynamic>{},
    );
    final label = _payMethodLabels[method] ?? method;
    final bank = (m['bank_name'] as String? ?? '').trim();
    return bank.isEmpty ? label : '$label · $bank';
  }

  Future<void> _pickMethod() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _payCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              for (final m in _methods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(ctx, m['method'] as String?),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: m['method'] == _method
                              ? AppColors.primary
                              : _payLine,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _payMethodIcons[m['method']] ??
                                Icons.payments_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _payMethodLabels[m['method']] ??
                                      (m['method'] as String? ?? ''),
                                  style: const TextStyle(
                                    color: _payInk,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_payAccount(m).isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _payAccount(m),
                                    style: const TextStyle(
                                      color: _payMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _method = picked);
  }

  Future<void> _confirm() async {
    final s = _summary;
    final method = _method;
    if (s == null || _paying) return;
    if (method == null) {
      _snack('This driver has not added a payout method yet.');
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _payCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Confirm Payment',
                      style: TextStyle(
                        color: _payInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF262626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: _payMuted, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _payRow('Week', _payPeriod(s)),
              _payRow('Paid via', _methodLine(method)),
              _payRow(
                'Gross collected',
                _payPkr(s['gross']),
                valueColor: AppColors.primary,
              ),
              _payRow('Commission (${_payPercent(s)})', _payPkr(s['commission'])),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _payRow(
                  'Paying now',
                  _payPkr(s['amount']),
                  valueColor: _payBlue,
                  strong: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: _payButtonStyle(),
                  child: const Text('Confirm & Pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _paying = true);
    try {
      final result = await _callable.call(<String, dynamic>{
        'driverId': widget.driverId,
        'method': method,
        'remark': '',
      });
      final receipt = _payMap(result.data);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VendorPayoutReceiptScreen(receipt: receipt),
        ),
      );
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_driver_perf.dart', e, st);
      if (!mounted) return;
      setState(() => _paying = false);
      _snack(_errorText(e));
    }
  }

  Widget _bankCard() {
    final m = _selectedMethod;
    final method = _method ?? '';
    final title = (m['account_title'] as String? ?? '').trim();
    final bank = (m['bank_name'] as String? ?? '').trim();
    final isBank = method == 'bank_transfer';
    return _payCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _payMethodIcons[method] ?? Icons.account_balance_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBank
                      ? 'Driver Bank Details'
                      : 'Driver ${_payMethodLabels[method] ?? 'Payout'} Details',
                  style: const TextStyle(
                    color: _payInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_methods.length > 1)
                GestureDetector(
                  onTap: _paying ? null : _pickMethod,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isBank) _payRow('Bank Name', bank.isEmpty ? '—' : bank),
          _payRow('Account Title', title.isEmpty ? '—' : title),
          _payRow(isBank ? 'Account Number' : 'Mobile Account', _payMasked(m)),
          if ((m['iban'] as String? ?? '').trim().isNotEmpty)
            _payRow('IBAN', (m['iban'] as String).trim()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final s = _summary;
    if (_error != null || s == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Could not load payout details.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _payMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final count = _payNum(s['payment_count']).toInt();
    final name = (s['driver_name'] as String? ?? '').trim();
    final photo = (s['driver_photo'] as String? ?? '').trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _payCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF3A3A3A),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isNotEmpty
                        ? null
                        : const Icon(Icons.person, color: _payMuted, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? widget.driverName : name,
                          style: const TextStyle(
                            color: _payInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Week: ${_payPeriod(s)}',
                          style: const TextStyle(color: _payMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: _payLine),
              _payRow(
                'Passengers total',
                _payPkr(s['gross']),
                valueColor: AppColors.primary,
              ),
              _payRow(
                'Your commission (${_payPercent(s)})',
                _payPkr(s['commission']),
              ),
              _payRow(
                'Trips Completed',
                '${_payNum(s['trips']).toInt()} trips',
              ),
              const Divider(height: 20, color: _payLine),
              _payRow(
                'Driver Receives',
                _payPkr(s['amount']),
                valueColor: _payBlue,
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (count == 0)
          _payNote('No approved passenger payments are waiting for payout.')
        else if (_methods.isEmpty)
          _payNote('This driver has not added a payout method yet.')
        else
          _bankCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    final canPay = !_loading &&
        s != null &&
        _payNum(s['payment_count']).toInt() > 0 &&
        _method != null &&
        !_paying;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _payAppBar(context, 'Pay Driver'),
      body: _body(),
      bottomNavigationBar: _loading || s == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: canPay ? _confirm : null,
                  style: _payButtonStyle(),
                  child: _paying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Proceed to confirm'),
                ),
              ),
            ),
    );
  }
}

class VendorPayoutReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const VendorPayoutReceiptScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    final name = (r['driver_name'] as String? ?? '').trim();
    final method = (r['method'] as String? ?? '').trim();
    final label = _payMethodLabels[method] ?? method;
    final bank = (r['bank_name'] as String? ?? '').trim();
    final via = bank.isEmpty ? label : '$label · $bank';
    final paidAt = _payDate(r['paid_at']) ?? DateTime.now();
    final txn = (r['transaction_id'] as String? ?? '').trim();
    final when = DateFormat('d MMM yyyy · h:mm a').format(paidAt);
    final who = name.isEmpty ? 'the driver' : name;
    final receiptText = [
      'PoolX Payment Receipt',
      'Driver: ${name.isEmpty ? 'Driver' : name}',
      'Week: ${_payPeriod(r)}',
      'Gross collected: ${_payPkr(r['gross'])}',
      'Commission deducted: ${_payPkr(r['commission'])}',
      'Amount paid: ${_payPkr(r['amount'])}',
      'Method: $via',
      'Date & time: $when',
      'Status: Paid',
      if (txn.isNotEmpty) 'Transaction ID: $txn',
    ].join('\n');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _payAppBar(context, 'Payment Receipt'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.check, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Payment Sent!',
              style: TextStyle(
                color: _payInk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_payPkr(r['amount'])} successfully transferred\nto $who via $via',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _payMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _payCard(
            Column(
              children: [
                _payRow('Driver', name.isEmpty ? 'Driver' : name),
                _payRow('Week', _payPeriod(r)),
                _payRow(
                  'Gross collected',
                  _payPkr(r['gross']),
                  valueColor: AppColors.primary,
                ),
                _payRow('Commission deducted', _payPkr(r['commission'])),
                _payRow(
                  'Amount paid',
                  _payPkr(r['amount']),
                  valueColor: _payBlue,
                ),
                _payRow('Method', via),
                _payRow('Date & time', when),
                _payRow('Status', 'Paid', valueColor: AppColors.primary),
              ],
            ),
          ),
          if (txn.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _payBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '# Transaction ID',
                      style: TextStyle(color: _payBlue, fontSize: 12),
                    ),
                  ),
                  Flexible(
                    child: SelectableText(
                      txn,
                      style: const TextStyle(color: _payMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: receiptText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt copied')),
                );
              },
              style: _payButtonStyle(),
              child: const Text('Download Receipt'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _payCardBg,
                foregroundColor: _payInk,
                elevation: 0,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Back to Payouts'),
            ),
          ),
        ],
      ),
    );
  }
}
