

import 'dart:ui' as BorderType;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../shared/ride_visibility.dart' show rideAwaitingDriverAcceptance;
import 'vendor_drawer.dart';
import 'package:poolx_partner/vendor/vendor_live _tracking.dart';

class VendorRideDriverManagementScreen extends StatefulWidget {
  const VendorRideDriverManagementScreen({super.key});

  @override
  State<VendorRideDriverManagementScreen> createState() =>
      _VendorRideDriverManagementScreenState();
}

class _VendorRideDriverManagementScreenState
    extends State<VendorRideDriverManagementScreen> {
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String? get _vendorId => _auth.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Monitoring Rides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(),
          const SizedBox(height: 24),

          // ── Live stat cards ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('active_rides')
                      .where('vendorId', isEqualTo: _vendorId)
                      .where(
                        'status',
                        whereIn: ['driver_assigned', 'in_progress'],
                      )
                       .where(
                         'current_phase',
                        whereIn: ['accepted'],
                      )
                      .limit(100)
                      .snapshots(),
                  builder: (_, snap) => _buildStatCard(
                    '${snap.data?.docs.length ?? 0}',
                    'Active Rides',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('drivers')
                      .where('vendor_id', isEqualTo: _vendorId)
                      .where('is_available', isEqualTo: true)
                      .where('approval_status', isEqualTo: 'approved')
                      .limit(100)
                      .snapshots(),
                  builder: (_, snap) => _buildStatCard(
                    '${snap.data?.docs.length ?? 0}',
                    'Available Drivers',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: () {
                    final now = DateTime.now();
                    final startOfDay = DateTime(now.year, now.month, now.day);
                    return _firestore
                        .collection('active_rides')
                        .where('vendorId', isEqualTo: _vendorId)
                        .where('status', isEqualTo: 'completed')
                        .where(
                          'timestamps.completed_at',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            startOfDay,
                          ),
                        )
                        .limit(100)
                        .snapshots();
                  }(),
                  builder: (_, snap) => _buildStatCard(
                    '${snap.data?.docs.length ?? 0}',
                    'Completed Today',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          if (_selectedTab == 0) _buildActiveRidesSection(),
          if (_selectedTab == 1) _buildBookingsSection(),
          if (_selectedTab == 2) _buildMessagesSection(),
        ],
      ),
    );
  }

  // ── Active Rides (live stream) ──────────────────────────────────────
  Widget _buildActiveRidesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Rides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search rides',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              border: InputBorder.none,
              icon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('active_rides')
              .where('vendorId', isEqualTo: _vendorId)
              .where(
                'status',
                whereIn: [
                  'assigned_to_driver',
                  'driver_assigned',
                  'in_progress',
                  'completed',
                ],
              )
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var docs = snapshot.data?.docs ?? [];

            // Apply search filter
            if (_searchQuery.isNotEmpty) {
              docs = docs.where((doc) {
                final ride = doc.data() as Map<String, dynamic>;
                final driverName = (ride['driver_name'] as String? ?? '')
                    .toLowerCase();
                final passenger = (ride['passenger_name'] as String? ?? '')
                    .toLowerCase();
                final pickup = (ride['pickup']?['address'] as String? ?? '')
                    .toLowerCase();
                return driverName.contains(_searchQuery) ||
                    passenger.contains(_searchQuery) ||
                    pickup.contains(_searchQuery);
              }).toList();
            }

            if (docs.isEmpty) {
              return _buildEmptyState('No active rides');
            }

            return Column(
              children: docs.asMap().entries.map((entry) {
                final ride = entry.value.data() as Map<String, dynamic>;
                final rideId = entry.value.id;
                final status = ride['status'] as String? ?? '';
                Color statusColor;
                String statusLabel;
                switch (status) {
                  case 'in_progress':
                    statusColor = const Color(0xFF10B981);
                    statusLabel = 'In Progress';
                    break;
                  case 'driver_assigned':
                    statusColor = const Color(0xFFF59E0B);
                    statusLabel = 'Driver en Route';
                    break;
                  case 'completed':
                    statusColor = const Color(0xFF3B82F6);
                    statusLabel = 'Completed';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusLabel = status;
                }
                if (rideAwaitingDriverAcceptance(ride)) {
                  statusColor = const Color(0xFFF59E0B);
                  statusLabel = 'Waiting for Driver';
                }

                return Column(
                  children: [
                    _buildRideCard(
                      rideId: 'Ride #${rideId.substring(0, 6).toUpperCase()}',
                      pickup: ride['pickup']?['address'] ?? '',
                      dropoff: ride['destination']?['address'] ?? '',
                      driverName: ride['driver_name'] ?? 'Unassigned',
                      rating:
                          (ride['driver_rating'] as num?)?.toStringAsFixed(1) ??
                          '0',
                      totalRides: '${ride['driver_total_rides'] ?? 0} rides',
                      status: statusLabel,
                      statusColor: statusColor,
                      driverPhone: ride['driver_phone'] ?? '',
                      rideDocId: rideId,
                    ),
                    if (entry.key < docs.length - 1) const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Bookings (all rides) ────────────────────────────────────────────
  Widget _buildBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('active_rides')
              .where('vendorId', isEqualTo: _vendorId)
              .where('driverId', isNotEqualTo: null)
              .where(
                'current_phase',
                        whereIn: ['accepted'],
                      )
              .limit(30)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return _buildEmptyState('No bookings yet');

            return Column(
              children: docs.asMap().entries.map((entry) {
                final ride = entry.value.data() as Map<String, dynamic>;
                final rideId = entry.value.id;
                final status = ride['status'] as String? ?? '';

                // ── Timestamps ──────────────────────────────────────
                final bookedAt = ride['timestamps']?['booked_at'] as Timestamp?;
                final dateStr = bookedAt != null
                    ? DateFormat(
                        'MMM d, yyyy',
                      ).format(bookedAt.toDate().toLocal())
                    : '';

                // ── Addresses ────────────────────────────────────────
                final pickup = ride['pickup']?['address'] as String? ?? '';
                final destination =
                    ride['destination']?['address'] as String? ?? '';

                // ── Fare ─────────────────────────────────────────────
                final fare = ride['fare'] as Map<dynamic, dynamic>? ?? {};
                final finalTotal = (fare['final_total'] as num?)?.toInt();
                final estimatedTotal =
                    (fare['estimated_total'] as num?)?.toInt() ?? 0;
                final displayFare = finalTotal ?? estimatedTotal;

                // ── Status mapping ───────────────────────────────────
                Color statusColor;
                String statusLabel;
                switch (status) {
                  case 'driver_assigned':
                  case 'in_progress':
                    statusColor = AppColors.primary;
                    statusLabel = 'Ongoing';
                    break;
                  case 'requested':
                    statusColor = const Color(0xFFF59E0B);
                    statusLabel = 'Upcoming';
                    break;
                  case 'completed':
                    statusColor = const Color(0xFF3B82F6);
                    statusLabel = 'Completed';
                    break;
                  case 'cancelled':
                  case 'declined':
                    statusColor = const Color(0xFFEF4444);
                    statusLabel = 'Cancelled';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusLabel = status;
                }

                return Column(
                  children: [
                    _buildBookingCard(
                      rideId: 'Ride #${rideId.substring(0, 6).toUpperCase()}',
                      date: 'Date: $dateStr',
                      route:
                          '${_shortAddr(pickup)} → ${_shortAddr(destination)}',
                      pickup: pickup,
                      destination: destination,
                      passengerName: ride['passenger_name'] as String? ?? 'N/A',
                      passengerPhone: ride['passenger_phone'] as String? ?? '',
                      driverName:
                          ride['driver_name'] as String? ?? 'Unassigned',
                      driverPhone: ride['driver_phone'] as String? ?? '',
                      driverVehicle: ride['driver_vehicle'] as String? ?? 'N/A',
                      driverVehicleType:
                          ride['driver_vehicle_type'] as String? ?? '',
                      driverPlate: ride['driver_plate'] as String? ?? '',
                      driverRating:
                          (ride['driver_rating'] as num?)?.toStringAsFixed(1) ??
                          '0',
                      paymentMethod:
                          ride['payment_method'] as String? ?? 'cash',
                      paymentStatus:
                          ride['payment_status'] as String? ?? 'pending',
                      estimatedDistance:
                          (ride['estimated_distance_km'] as num?)
                              ?.toStringAsFixed(1) ??
                          '0',
                      estimatedTime:
                          ride['estimated_trip_time'] as String? ?? '',
                      fare: 'Rs $displayFare',
                      rideTiming: ride['ride_timing'] as String? ?? 'Now',
                      recurringRide: ride['recurring_ride'] as String? ?? '',
                      status: statusLabel,
                      statusColor: statusColor,
                    ),
                    if (entry.key < docs.length - 1) const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Booking Card ──────────────────────────────────────────────────────
  Widget _buildBookingCard({
    required String rideId,
    required String date,
    required String route,
    required String pickup,
    required String destination,
    required String passengerName,
    required String passengerPhone,
    required String driverName,
    required String driverPhone,
    required String driverVehicle,
    required String driverVehicleType,
    required String driverPlate,
    required String driverRating,
    required String paymentMethod,
    required String paymentStatus,
    required String estimatedDistance,
    required String estimatedTime,
    required String fare,
    required String rideTiming,
    required String recurringRide,
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Ride ID + Date + Status ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$rideId • $date',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Route ─────────────────────────────────────────────────
          Text(
            route,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // ── Passenger ─────────────────────────────────────────────
          _bookingRow(
            Icons.person_outline,
            'Passenger',
            '$passengerName${passengerPhone.isNotEmpty ? ' • $passengerPhone' : ''}',
          ),

          const SizedBox(height: 6),

          // ── Driver ────────────────────────────────────────────────
          _bookingRow(
            Icons.drive_eta_outlined,
            'Driver',
            driverName == 'Unassigned'
                ? 'Unassigned'
                : '$driverName • ⭐ $driverRating',
          ),

          const SizedBox(height: 6),

          // ── Vehicle ───────────────────────────────────────────────
          _bookingRow(
            Icons.directions_car_outlined,
            'Vehicle',
            driverVehicle.isNotEmpty
                ? '$driverVehicle ($driverPlate) • $driverVehicleType'
                : 'N/A',
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Stats row ─────────────────────────────────────────────
          Row(
            children: [
              _miniStat(Icons.route_outlined, estimatedDistance, 'km'),
              _vertDivider(),
              _miniStat(Icons.timer_outlined, estimatedTime, ''),
              _vertDivider(),
              _miniStat(Icons.payments_outlined, fare, ''),
              _vertDivider(),
              _miniStat(
                paymentMethod == 'cash'
                    ? Icons.money
                    : Icons.credit_card_outlined,
                paymentMethod.toUpperCase(),
                '',
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Bottom row: timing + payment status ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$rideTiming${recurringRide.isNotEmpty && recurringRide != 'Custom' ? ' • $recurringRide' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentStatus == 'completed'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paymentStatus == 'completed' ? '✓ Paid' : '⏳ Payment Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: paymentStatus == 'completed'
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────
  Widget _bookingRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 2),
          Text(
            unit.isNotEmpty ? '$value $unit' : value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _vertDivider() =>
      Container(width: 1, height: 32, color: Colors.grey.shade200);

  // ── Messages Section ─────────────────────────────────────────────────
  Widget _buildMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('active_rides')
              .where('vendorId', isEqualTo: _vendorId)
              .where('status',
                  whereIn: ['assigned_to_driver', 'driver_assigned', 'in_progress'])
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _buildEmptyState('No active ride chats');
            }

            return Column(
              children: docs.map((doc) {
                final ride = doc.data() as Map<String, dynamic>;
                final rideId = doc.id;
                final driverName = ride['driver_name'] as String? ?? 'Driver';
                final passengerName =
                    ride['passenger_name'] as String? ?? 'Passenger';
                final initials = driverName
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();
                final pickup = ride['pickup']?['address'] as String? ?? '';
                final destination =
                    ride['destination']?['address'] as String? ?? '';

                return _RideMessageCard(
                  rideId: rideId,
                  driverName: driverName,
                  passengerName: passengerName,
                  initials: initials,
                  pickup: pickup,
                  destination: destination,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _shortAddr(String address) => address.split(',').first.trim();

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTab('Active Rides', 0),
          const SizedBox(width: 4),
          _buildTab('Booking', 1),
          const SizedBox(width: 4),
          _buildTab('Message', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                )
              : const BoxDecoration(),
          child: Text(
            text,
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

  Widget _buildRideCard({
    required String rideId,
    required String pickup,
    required String dropoff,
    required String driverName,
    required String rating,
    required String totalRides,
    required String status,
    required Color statusColor,
    required String driverPhone,
    required String rideDocId,
  }) {
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
              Text(
                rideId,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pickup Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 2,
                  height: 20,
                  child: CustomPaint(painter: DottedLinePainter()),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Drop-off Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              dropoff,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFB923C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($totalRides)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.phone,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  label: const Text(
                    'Call',
                    style: TextStyle(fontSize: 13, color: Color(0xFF10B981)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981)),
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                  label: const Text(
                    'Chat',
                    style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorLiveTrackingScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                  label: const Text(
                    'Track',
                    style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildBookingCard({
  //   required String rideId,
  //   required String date,
  //   required String route,
  //   required String passenger,
  //   required String vehicle,
  //   required String driver,
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
  //           color: Colors.black.withValues(alpha: 0.04),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text('$rideId • $date',
  //                 style: const TextStyle(
  //                     fontSize: 13,
  //                     color: AppColors.textSecondary)),
  //             Container(
  //               padding: const EdgeInsets.symmetric(
  //                   horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: statusColor,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(status,
  //                   style: const TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.white)),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Text(route,
  //             style: const TextStyle(
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.textPrimary),
  //             textAlign: TextAlign.center),
  //         const SizedBox(height: 8),
  //         Text(passenger,
  //             style: const TextStyle(
  //                 fontSize: 13, color: AppColors.textSecondary)),
  //         const SizedBox(height: 4),
  //         Text(vehicle,
  //             style: const TextStyle(
  //                 fontSize: 13, color: AppColors.textSecondary)),
  //         const SizedBox(height: 4),
  //         Text(driver,
  //             style: const TextStyle(
  //                 fontSize: 13, color: AppColors.textSecondary)),
  //       ],
  //     ),
  //   );
  // }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── Per-ride message card that streams from Realtime DB ──────────────
// ── Paste this class OUTSIDE your main widget class ──────────────────
class _RideMessageCard extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String passengerName;
  final String initials;
  final String pickup;
  final String destination;

  const _RideMessageCard({
    required this.rideId,
    required this.driverName,
    required this.passengerName,
    required this.initials,
    required this.pickup,
    required this.destination,
  });

  @override
  State<_RideMessageCard> createState() => _RideMessageCardState();
}

class _RideMessageCardState extends State<_RideMessageCard> {
  final _rtdb = FirebaseDatabase.instance;

  String _shortAddr(String address) => address.split(',').first.trim();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _rtdb
          .ref('active_rides/${widget.rideId}/ride_chats/meta')
          .onValue,
      builder: (context, metaSnap) {
        String lastMessage =
            '${_shortAddr(widget.pickup)} → ${_shortAddr(widget.destination)}';
        String timeStr = '';
        int driverUnread = 0;
        int passengerUnread = 0;

        if (metaSnap.hasData && metaSnap.data!.snapshot.value != null) {
          final meta = Map<String, dynamic>.from(
            metaSnap.data!.snapshot.value as Map,
          );

          lastMessage = meta['last_message'] as String? ?? lastMessage;
          driverUnread = (meta['driver_unread_count'] as int? ?? 0);
          passengerUnread = (meta['passenger_unread_count'] as int? ?? 0);

          final lastMsgAt = meta['last_message_at'];
          if (lastMsgAt != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(lastMsgAt as int);
            final now = DateTime.now();
            final isToday =
                dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day;
            final isYesterday =
                dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day - 1;
            if (isToday) {
              timeStr = DateFormat('h:mm a').format(dt);
            } else if (isYesterday) {
              timeStr = 'Yesterday';
            } else {
              timeStr = DateFormat('MMM d').format(dt);
            }
          }
        }

        final totalUnread = driverUnread + passengerUnread;
        final hasUnread = totalUnread > 0;
        final shortRideId =
            'Ride #R${widget.rideId.substring(0, 4).toUpperCase()}';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ───────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.initials,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$totalUnread',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // ── Text content ─────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.driverName} - $shortRideId',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Last message
                        Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Subtitle — passenger name in primary color
                        Text(
                          'Passenger: ${widget.passengerName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Thin divider between items
            Divider(height: 1, color: Colors.grey.shade100, indent: 60),
          ],
        );
      },
    );
  }
}
