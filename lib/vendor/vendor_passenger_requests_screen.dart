import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../shared/ride_visibility.dart'
    show kAwaitingDriverPhases, rideAwaitingDriverAcceptance;

const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _pageBg = Color(0xFFF9FAFB);
const Color _danger = Color(0xFFEF4444);
const Color _warn = Color(0xFFF59E0B);

typedef VendorRequestDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

class VendorPassengerRequests {
  VendorPassengerRequests._();

  static String norm(dynamic v) =>
      (v ?? '').toString().toLowerCase().replaceAll(' ', '_').trim();

  static String text(dynamic v) => (v ?? '').toString().trim();

  static bool isPending(Map<String, dynamic> d) {
    final status = norm(d['status']);
    if (status == 'cancelled' ||
        status == 'canceled' ||
        status == 'declined' ||
        status == 'completed') {
      return false;
    }
    return norm(d['current_phase']) == 'waiting_for_vendor';
  }

  static bool isAwaitingDriver(Map<String, dynamic> d) =>
      rideAwaitingDriverAcceptance(d);

  static bool canAssign(Map<String, dynamic> d) =>
      isPending(d) || isAwaitingDriver(d);

  static bool hasDriver(Map<String, dynamic> d) =>
      text(d['driverId']).isNotEmpty;

  static String declinedNote(Map<String, dynamic> d) {
    final ids = d['declined_driver_ids'];
    if (ids is! List || ids.isEmpty || !isPending(d) || hasDriver(d)) {
      return '';
    }
    final name = text(d['driver_name']);
    return 'Declined by ${name.isEmpty ? 'the assigned driver' : name}. Assign another driver.';
  }

  static Widget stateNote(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int requestedMillis(Map<String, dynamic> d) {
    final ts = d['timestamps'];
    if (ts is Map) {
      final r = ts['requested_at'];
      if (r is Timestamp) return r.millisecondsSinceEpoch;
      final b = ts['booked_at'];
      if (b is Timestamp) return b.millisecondsSinceEpoch;
    }
    return 0;
  }

  static Stream<List<VendorRequestDoc>> stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(<VendorRequestDoc>[]);
    }
    return FirebaseFirestore.instance
        .collection('active_rides')
        .where('vendorId', isEqualTo: uid)
        .where('current_phase', isEqualTo: 'waiting_for_vendor')
        .snapshots()
        .map((s) => _sorted(s.docs.where((d) => isPending(d.data()))));
  }

  static Stream<List<VendorRequestDoc>> streamWithAwaiting() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(<VendorRequestDoc>[]);
    }
    return FirebaseFirestore.instance
        .collection('active_rides')
        .where('vendorId', isEqualTo: uid)
        .where('current_phase',
            whereIn: ['waiting_for_vendor', ...kAwaitingDriverPhases])
        .snapshots()
        .map((s) => _sorted(s.docs.where((d) => canAssign(d.data()))));
  }

  static List<VendorRequestDoc> _sorted(Iterable<VendorRequestDoc> source) {
    final docs = source.toList();
    docs.sort((a, b) =>
        requestedMillis(b.data()).compareTo(requestedMillis(a.data())));
    return docs;
  }

  static String address(dynamic v) {
    if (v is Map) return text(v['address']);
    return text(v);
  }

  static String shortAddress(dynamic v) {
    final a = address(v);
    if (a.isEmpty) return 'Unknown';
    return a.split(',').first.trim();
  }

  static String passengerName(Map<String, dynamic> d) {
    final n = text(d['passenger_name']);
    return n.isEmpty ? 'Passenger' : n;
  }

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String fareLabel(Map<String, dynamic> d) {
    num? amount;
    final plan = d['subscription_plan'];
    if (plan is Map && plan['amount'] is num) {
      amount = plan['amount'] as num;
    }
    final fare = d['fare'];
    if (amount == null && fare is Map) {
      final v = fare['final_total'] ?? fare['estimated_total'];
      if (v is num) {
        amount = v;
      } else if (v is String) {
        amount = num.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
      }
    }
    if (amount == null || amount <= 0) return '';
    return 'PKR ${NumberFormat('#,##0').format(amount.round())}';
  }

  static String planLabel(Map<String, dynamic> d) {
    final plan = d['subscription_plan'];
    if (plan is Map) {
      final label = text(plan['label'] ?? plan['type']);
      if (label.isNotEmpty) {
        return label[0].toUpperCase() + label.substring(1);
      }
    }
    return '';
  }

  static String daysLabel(Map<String, dynamic> d) {
    final days = d['repeat_days'];
    if (days is List && days.isNotEmpty) {
      return days.map((e) => e.toString()).join(', ');
    }
    return '';
  }

  static String timeLabel(Map<String, dynamic> d) {
    final s = d['scheduled_at'];
    if (s is Timestamp) {
      return DateFormat('d MMM yyyy, h:mm a').format(s.toDate().toLocal());
    }
    return text(d['pickup_daily_time']);
  }

  static String scheduleLabel(Map<String, dynamic> d) {
    final parts = <String>[];
    final days = daysLabel(d);
    if (days.isNotEmpty) parts.add(days);
    final time = timeLabel(d);
    if (time.isNotEmpty) parts.add(time);
    final plan = planLabel(d);
    if (plan.isNotEmpty) parts.add(plan);
    return parts.join(' | ');
  }

  static String requestedOnLabel(Map<String, dynamic> d) {
    final ms = requestedMillis(d);
    if (ms <= 0) return '';
    return 'Requested on ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms))}';
  }

  static String preferencesLabel(Map<String, dynamic> d) {
    final parts = <String>[];
    final p = d['ride_preferences'];
    if (p is List) {
      parts.addAll(p.map((e) => e.toString()).where((e) => e.trim().isNotEmpty));
    } else if (p is Map) {
      p.forEach((k, v) {
        if (v == true) parts.add(k.toString());
      });
    } else if (text(p).isNotEmpty) {
      parts.add(text(p));
    }
    final g = text(d['gender_preference']);
    if (g.isNotEmpty && g.toLowerCase() != 'any') parts.add('$g driver');
    return parts.join(', ');
  }

  static Future<String?> _guardedUpdate(String rideId,
      Map<String, dynamic> data, bool Function(Map<String, dynamic>) allowed) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('active_rides').doc(rideId);
    try {
      return await db.runTransaction<String?>((tx) async {
        final snap = await tx.get(ref);
        final cur = snap.data();
        if (cur == null || !allowed(cur)) {
          return 'This request is no longer waiting for approval.';
        }
        tx.update(ref, data);
        return null;
      });
    } catch (e) {
      return 'Could not update the request. $e';
    }
  }

  static Future<String?> accept(String rideId) => _guardedUpdate(
        rideId,
        {
          'status': 'assigned_to_driver',
          'current_phase': 'driver_assigned',
          'driver_accepted': false,
          'vendor_approved': true,
          'vendor_approved_at': FieldValue.serverTimestamp(),
          'timestamps.driver_assigned_at': FieldValue.serverTimestamp(),
          'timestamps.vendor_assigned_at': FieldValue.serverTimestamp(),
        },
        (d) => isPending(d) && hasDriver(d),
      );

  static Future<String?> reject(String rideId) => _guardedUpdate(
        rideId,
        {
          'status': 'cancelled',
          'cancelled_by': 'vendor',
          'vendor_approved': false,
          'timestamps.cancelled_at': FieldValue.serverTimestamp(),
        },
        canAssign,
      );

  static Future<String?> assignDriver(
      String rideId, String driverId, Map<String, dynamic> driver) {
    final vh = driver['vehicle'] is Map ? driver['vehicle'] as Map : const {};
    final vs = '${vh['make'] ?? ''} ${vh['model'] ?? ''}'.trim();
    return _guardedUpdate(rideId, {
      'driverId': driverId,
      'driver_name': driver['full_name'] ?? '',
      'driver_phone': driver['phone_number'] ?? '',
      'driver_rating': driver['average_rating'] ?? 0,
      'driver_vehicle': vs,
      'driver_vehicle_type': vh['type'] ?? '',
      'driver_plate': vh['plate_number'] ?? '',
      'driver_fcm_token': driver['fcm_token'] ?? '',
      'status': 'assigned_to_driver',
      'current_phase': 'driver_assigned',
      'driver_accepted': false,
      'assigned_by': 'vendor',
      'vendor_approved': true,
      'vendor_approved_at': FieldValue.serverTimestamp(),
      'timestamps.driver_assigned_at': FieldValue.serverTimestamp(),
      'timestamps.vendor_assigned_at': FieldValue.serverTimestamp(),
    }, canAssign);
  }

  static void toast(BuildContext context, String message, bool ok) {
    _show(ScaffoldMessenger.of(context), message, ok);
  }

  static void _show(ScaffoldMessengerState messenger, String message, bool ok) {
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: ok ? AppColors.primary : _danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static Future<bool> acceptWithFeedback(
      BuildContext context, String rideId) async {
    final messenger = ScaffoldMessenger.of(context);
    final err = await accept(rideId);
    _show(
        messenger,
        err ?? 'Request accepted. Waiting for the driver to accept the ride.',
        err == null);
    return err == null;
  }

  static Future<bool> rejectWithFeedback(
      BuildContext context, String rideId) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Reject request?',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        content: const Text(
            'The passenger will be told that this ride request was declined.',
            style: TextStyle(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    final err = await reject(rideId);
    _show(messenger, err ?? 'Request rejected.', err == null);
    return err == null;
  }

  static Future<bool> openAssign(
      BuildContext context, String rideId, Map<String, dynamic> ride) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VendorAssignDriverScreen(rideId: rideId, ride: ride),
      ),
    );
    return done == true;
  }

  static void openDetails(BuildContext context, String rideId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorPassengerRequestDetailsScreen(rideId: rideId),
      ),
    );
  }
}

class VendorRequestsBadge extends StatefulWidget {
  const VendorRequestsBadge({super.key});

  @override
  State<VendorRequestsBadge> createState() => _VendorRequestsBadgeState();
}

class _VendorRequestsBadgeState extends State<VendorRequestsBadge> {
  late final Stream<List<VendorRequestDoc>> _stream =
      VendorPassengerRequests.stream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VendorRequestDoc>>(
      stream: _stream,
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        if (count <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _danger,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class VendorPassengerRequestCard extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> ride;

  const VendorPassengerRequestCard({
    super.key,
    required this.rideId,
    required this.ride,
  });

  @override
  State<VendorPassengerRequestCard> createState() =>
      _VendorPassengerRequestCardState();
}

class _VendorPassengerRequestCardState
    extends State<VendorPassengerRequestCard> {
  bool _busy = false;

  Future<void> _guard(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final name = VendorPassengerRequests.passengerName(ride);
    final route =
        '${VendorPassengerRequests.shortAddress(ride['pickup'])} → ${VendorPassengerRequests.shortAddress(ride['destination'])}';
    final schedule = VendorPassengerRequests.scheduleLabel(ride);
    final requestedOn = VendorPassengerRequests.requestedOnLabel(ride);
    final fare = VendorPassengerRequests.fareLabel(ride);
    final withDriver = VendorPassengerRequests.hasDriver(ride);
    final awaiting = VendorPassengerRequests.isAwaitingDriver(ride);
    final declinedNote = VendorPassengerRequests.declinedNote(ride);
    final driverName = VendorPassengerRequests.text(ride['driver_name']);
    final driverVehicle = [
      VendorPassengerRequests.text(ride['driver_vehicle']),
      VendorPassengerRequests.text(ride['driver_plate']),
    ].where((e) => e.isNotEmpty).join(' • ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            VendorPassengerRequests.openDetails(context, widget.rideId),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      VendorPassengerRequests.initials(name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route,
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                        if (schedule.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  schedule,
                                  style: const TextStyle(
                                      fontSize: 12, color: _ink),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (requestedOn.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            requestedOn,
                            style:
                                const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (fare.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      fare,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      withDriver ? Icons.person_pin : Icons.person_search,
                      size: 18,
                      color: withDriver ? AppColors.primary : _muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        withDriver
                            ? '${awaiting ? 'Assigned driver' : 'Requested driver'}: ${driverName.isEmpty ? 'Driver' : driverName}${driverVehicle.isEmpty ? '' : ' ($driverVehicle)'}'
                            : 'No driver selected. Assign one of your drivers.',
                        style: const TextStyle(fontSize: 12, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
              if (awaiting) ...[
                const SizedBox(height: 8),
                VendorPassengerRequests.stateNote(
                  'Waiting for driver to accept',
                  Icons.hourglass_top_rounded,
                  _warn,
                ),
              ],
              if (declinedNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                VendorPassengerRequests.stateNote(
                  declinedNote,
                  Icons.info_outline,
                  _danger,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _guard(() =>
                              VendorPassengerRequests.rejectWithFeedback(
                                  context, widget.rideId)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: const BorderSide(color: _danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _guard(() => withDriver && !awaiting
                              ? VendorPassengerRequests.acceptWithFeedback(
                                  context, widget.rideId)
                              : VendorPassengerRequests.openAssign(
                                  context, widget.rideId, ride)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              awaiting
                                  ? 'Reassign Driver'
                                  : withDriver
                                      ? 'Accept'
                                      : 'Assign Driver',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VendorPassengerRequestsScreen extends StatefulWidget {
  const VendorPassengerRequestsScreen({super.key});

  @override
  State<VendorPassengerRequestsScreen> createState() =>
      _VendorPassengerRequestsScreenState();
}

class _VendorPassengerRequestsScreenState
    extends State<VendorPassengerRequestsScreen> {
  late final Stream<List<VendorRequestDoc>> _stream =
      VendorPassengerRequests.streamWithAwaiting();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Passenger Requests',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<VendorRequestDoc>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              Icons.error_outline,
              'Could not load passenger requests',
              '${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final docs = snapshot.data ?? <VendorRequestDoc>[];
          final pendingCount = docs
              .where((d) => VendorPassengerRequests.isPending(d.data()))
              .length;
          final awaitingCount = docs.length - pendingCount;
          if (docs.isEmpty) {
            return _message(
              Icons.inbox_outlined,
              'No passenger requests right now',
              'New ride requests sent to you will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  '$pendingCount pending ${pendingCount == 1 ? 'request' : 'requests'}${awaitingCount > 0 ? ' · $awaitingCount waiting for driver' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                );
              }
              final doc = docs[i - 1];
              return VendorPassengerRequestCard(
                key: ValueKey(doc.id),
                rideId: doc.id,
                ride: doc.data(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(IconData icon, String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorPassengerRequestDetailsScreen extends StatefulWidget {
  final String rideId;

  const VendorPassengerRequestDetailsScreen({super.key, required this.rideId});

  @override
  State<VendorPassengerRequestDetailsScreen> createState() =>
      _VendorPassengerRequestDetailsScreenState();
}

class _VendorPassengerRequestDetailsScreenState
    extends State<VendorPassengerRequestDetailsScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance
          .collection('active_rides')
          .doc(widget.rideId)
          .snapshots();
  bool _busy = false;

  Future<void> _guard(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load this request. ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final ride = snapshot.data!.data();
          if (ride == null) {
            return const Center(
              child: Text('This request no longer exists.',
                  style: TextStyle(color: _muted)),
            );
          }
          return _body(ride);
        },
      ),
    );
  }

  Widget _body(Map<String, dynamic> ride) {
    final name = VendorPassengerRequests.passengerName(ride);
    final phone = VendorPassengerRequests.text(ride['passenger_phone']);
    final pending = VendorPassengerRequests.isPending(ride);
    final awaiting = VendorPassengerRequests.isAwaitingDriver(ride);
    final declinedNote = VendorPassengerRequests.declinedNote(ride);
    final withDriver = VendorPassengerRequests.hasDriver(ride);
    final startTs = ride['plan_start_date'];
    final startDate = startTs is Timestamp
        ? DateFormat('d MMM yyyy').format(startTs.toDate().toLocal())
        : '';
    final requestedOn = VendorPassengerRequests.requestedOnLabel(ride)
        .replaceFirst('Requested on ', '');
    final driverName = VendorPassengerRequests.text(ride['driver_name']);
    final driverVehicle = [
      VendorPassengerRequests.text(ride['driver_vehicle']),
      VendorPassengerRequests.text(ride['driver_plate']),
    ].where((e) => e.isNotEmpty).join(' • ');

    final rows = <MapEntry<String, String>>[
      MapEntry('From', VendorPassengerRequests.address(ride['pickup'])),
      MapEntry('To', VendorPassengerRequests.address(ride['destination'])),
      MapEntry('Subscription Plan', VendorPassengerRequests.planLabel(ride)),
      MapEntry('Days', VendorPassengerRequests.daysLabel(ride)),
      MapEntry('Timing', VendorPassengerRequests.timeLabel(ride)),
      MapEntry('Start Date', startDate),
      MapEntry('Requested On', requestedOn),
      MapEntry('Preferences', VendorPassengerRequests.preferencesLabel(ride)),
      MapEntry('Fare', VendorPassengerRequests.fareLabel(ride)),
      MapEntry('Payment Method',
          VendorPassengerRequests.text(ride['payment_method'])),
      MapEntry(
        awaiting ? 'Assigned Driver' : 'Requested Driver',
        withDriver
            ? '${driverName.isEmpty ? 'Driver' : driverName}${driverVehicle.isEmpty ? '' : ' ($driverVehicle)'}'
            : 'None, assign a driver',
      ),
    ].where((e) => e.value.trim().isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      VendorPassengerRequests.initials(name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(phone,
                              style: const TextStyle(
                                  fontSize: 13, color: _muted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...rows.map((e) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                fontSize: 12, color: _muted)),
                        const SizedBox(height: 2),
                        Text(e.value,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _ink)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!pending && !awaiting)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'This request is no longer waiting for approval. Current status: ${VendorPassengerRequests.text(ride['status']).replaceAll('_', ' ')}',
              style: const TextStyle(fontSize: 14, color: _ink),
            ),
          )
        else ...[
          if (awaiting) ...[
            VendorPassengerRequests.stateNote(
              'Waiting for driver to accept',
              Icons.hourglass_top_rounded,
              _warn,
            ),
            const SizedBox(height: 12),
          ],
          if (declinedNote.isNotEmpty) ...[
            VendorPassengerRequests.stateNote(
              declinedNote,
              Icons.info_outline,
              _danger,
            ),
            const SizedBox(height: 12),
          ],
          if (!awaiting)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _guard(() => withDriver
                      ? VendorPassengerRequests.acceptWithFeedback(
                          context, widget.rideId)
                      : VendorPassengerRequests.openAssign(
                          context, widget.rideId, ride)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      withDriver ? 'Accept Request' : 'Assign Driver',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (withDriver) ...[
            if (!awaiting) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _guard(() => VendorPassengerRequests.openAssign(
                        context, widget.rideId, ride)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Assign a Different Driver',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _guard(() =>
                      VendorPassengerRequests.rejectWithFeedback(
                          context, widget.rideId)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: const BorderSide(color: _danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reject Request',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }
}

class VendorAssignDriverScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> ride;

  const VendorAssignDriverScreen({
    super.key,
    required this.rideId,
    required this.ride,
  });

  @override
  State<VendorAssignDriverScreen> createState() =>
      _VendorAssignDriverScreenState();
}

class _VendorAssignDriverScreenState extends State<VendorAssignDriverScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _driversStream =
      FirebaseFirestore.instance
          .collection('drivers')
          .where('vendor_id',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
          .snapshots();
  String? _selectedId;
  Map<String, dynamic>? _selected;
  bool _saving = false;

  Future<void> _assign() async {
    final id = _selectedId;
    final data = _selected;
    if (id == null || data == null || _saving) return;
    setState(() => _saving = true);
    final err =
        await VendorPassengerRequests.assignDriver(widget.rideId, id, data);
    if (!mounted) return;
    setState(() => _saving = false);
    final name = VendorPassengerRequests.text(data['full_name']);
    VendorPassengerRequests.toast(
      context,
      err ??
          '${name.isEmpty ? 'Driver' : name} assigned. Waiting for the driver to accept.',
      err == null,
    );
    if (err == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final name = VendorPassengerRequests.passengerName(ride);
    final route =
        '${VendorPassengerRequests.shortAddress(ride['pickup'])} → ${VendorPassengerRequests.shortAddress(ride['destination'])}';
    final schedule = VendorPassengerRequests.scheduleLabel(ride);
    final requestedOn = VendorPassengerRequests.requestedOnLabel(ride);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Assign Driver',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    VendorPassengerRequests.initials(name),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      const SizedBox(height: 4),
                      Text(route,
                          style: const TextStyle(fontSize: 13, color: _muted)),
                      if (schedule.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(schedule,
                            style: const TextStyle(fontSize: 12, color: _ink)),
                      ],
                      if (requestedOn.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(requestedOn,
                            style:
                                const TextStyle(fontSize: 12, color: _muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Driver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _driversStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load your drivers. ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final drivers = snapshot.data!.docs
                    .where((d) =>
                        VendorPassengerRequests.norm(
                            d.data()['approval_status']) ==
                        'approved')
                    .toList();
                drivers.sort((a, b) {
                  final aa = a.data()['is_available'] == true ? 0 : 1;
                  final bb = b.data()['is_available'] == true ? 0 : 1;
                  if (aa != bb) return aa.compareTo(bb);
                  return VendorPassengerRequests.text(a.data()['full_name'])
                      .toLowerCase()
                      .compareTo(VendorPassengerRequests.text(
                              b.data()['full_name'])
                          .toLowerCase());
                });
                if (drivers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'You have no approved drivers yet. Add and approve drivers in Fleet Management first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _driverTile(drivers[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedId == null || _saving ? null : _assign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Assign',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverTile(VendorRequestDoc doc) {
    final d = doc.data();
    final name = VendorPassengerRequests.text(d['full_name']);
    final vh = d['vehicle'] is Map ? d['vehicle'] as Map : const {};
    final vehicle = [
      '${vh['make'] ?? ''} ${vh['model'] ?? ''}'.trim(),
      VendorPassengerRequests.text(vh['plate_number']),
    ].where((e) => e.isNotEmpty).join(' • ');
    final available = d['is_available'] == true;
    final rating = d['average_rating'];
    final selected = _selectedId == doc.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _selectedId = doc.id;
          _selected = d;
        }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  VendorPassengerRequests.initials(
                      name.isEmpty ? 'Driver' : name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Driver' : name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (vehicle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(vehicle,
                          style: const TextStyle(fontSize: 12, color: _muted)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: available ? AppColors.primary : _muted),
                        const SizedBox(width: 4),
                        Text(
                          available ? 'Available' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: available ? AppColors.primary : _muted,
                          ),
                        ),
                        if (rating is num && rating > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.star,
                              size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: _ink),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
