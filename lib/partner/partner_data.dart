import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../shared/ride_visibility.dart' show rideApprovedForDriver;
import '../vendor/vendor_passenger_requests_screen.dart' show VendorPassengerRequests;

typedef PxDoc = QueryDocumentSnapshot<Map<String, dynamic>>;
typedef PxMap = Map<String, dynamic>;

const double kDefaultCommissionPercent = 15;

class Px {
  Px._();

  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static String text(dynamic v) => (v ?? '').toString().trim();
  static String norm(dynamic v) => text(v).toLowerCase().replaceAll(' ', '_');

  static num number(dynamic v) {
    if (v is num) return v;
    return num.tryParse(text(v).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  static PxMap map(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static DateTime? date(dynamic v) {
    if (v is Timestamp) return v.toDate().toLocal();
    if (v is int && v > 0) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  static final NumberFormat _money = NumberFormat('#,##0');
  static String pkr(num v) => 'PKR ${_money.format(v.round())}';
  static String rs(num v) => 'Rs. ${_money.format(v.round())}';
  static String plain(num v) => _money.format(v.round());

  static String dayMonthYear(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);
  static String longDate(DateTime? d) => d == null ? '' : DateFormat('MMM d, yyyy').format(d);
  static String dateTime(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(d);
  static String shortDateTime(DateTime? d) => d == null ? '' : DateFormat('d MMM · hh:mm a').format(d);

  static String ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(d);
  }

  static String address(dynamic v) {
    if (v is Map) return text(v['address']);
    return text(v);
  }

  static String shortAddress(dynamic v) {
    final a = address(v);
    if (a.isEmpty) return '';
    return a.split(',').first.trim();
  }

  static const Set<String> closedStatuses = {
    'cancelled',
    'canceled',
    'declined',
    'completed',
    'rejected',
  };

  static bool rideClosed(PxMap r) => closedStatuses.contains(norm(r['status']));
  static bool rideHasDriver(PxMap r) => text(r['driverId']).isNotEmpty;
  static bool rideIsRequest(PxMap r) => !rideClosed(r) && VendorPassengerRequests.canAssign(r);
  static bool rideIsAssigned(PxMap r) => !rideClosed(r) && rideHasDriver(r) && !VendorPassengerRequests.isPending(r);
  static bool rideDriverAccepted(PxMap r) => rideIsAssigned(r) && rideApprovedForDriver(r);

  static bool rideActiveNow(PxMap r) {
    if (!rideDriverAccepted(r)) return false;
    const live = {
      'in_progress',
      'en_route_pickup',
      'arrived_at_pickup',
      'en_route_dropoff',
      'arrived_at_dropoff',
      'to_destination',
    };
    return live.contains(norm(r['status'])) || live.contains(norm(r['current_phase']));
  }

  static bool rideCompletedToday(PxMap r) {
    if (norm(r['status']) != 'completed') return false;
    final t = map(r['timestamps']);
    final at = date(t['completed_at']) ?? date(r['completed_at']);
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  static bool rideHasSubscription(PxMap r) {
    if (rideClosed(r)) return false;
    final wp = map(r['weekly_plan']);
    if (wp['activated'] == true) return true;
    return const {'approved', 'paid', 'completed', 'confirmed'}.contains(norm(r['payment_status']));
  }

  static String plan(PxMap r) => VendorPassengerRequests.planLabel(r);

  static String rideSchedule(PxMap r) {
    final days = r['repeat_days'];
    final parts = <String>[];
    if (days is List && days.isNotEmpty) parts.add(daysLabel(days.map((e) => e.toString()).toList()));
    final t = text(r['pickup_daily_time']);
    if (t.isNotEmpty) {
      parts.add(t);
    } else {
      final s = date(r['scheduled_at']);
      if (s != null) parts.add(DateFormat('h:mma').format(s));
    }
    return parts.join(' | ');
  }

  static const List<String> _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String daysLabel(List<String> days) {
    final idx = days
        .map((d) => d.trim().length >= 3 ? d.trim().substring(0, 3).toLowerCase() : '')
        .map((d) => _week.indexWhere((w) => w.toLowerCase() == d))
        .where((i) => i >= 0)
        .toSet()
        .toList()
      ..sort();
    if (idx.isEmpty) return days.join(', ');
    var contiguous = true;
    for (var i = 1; i < idx.length; i++) {
      if (idx[i] != idx[i - 1] + 1) contiguous = false;
    }
    if (contiguous && idx.length > 2) return '${_week[idx.first]} to ${_week[idx.last]}';
    return idx.map((i) => _week[i]).join(', ');
  }

  static PxMap availability(PxMap d) => map(d['availability']);
  static PxMap vehicle(PxMap d) => map(d['vehicle']);

  static String driverRoute(PxMap d) {
    final a = availability(d);
    final from = text(a['preferred_route_from']).split(',').first.trim();
    final to = text(a['preferred_route_to']).split(',').first.trim();
    if (from.isEmpty && to.isEmpty) return '';
    return '$from → $to';
  }

  static String driverSchedule(PxMap d) {
    final a = availability(d);
    final raw = a['days_selected'] is List
        ? (a['days_selected'] as List).map((e) => e.toString()).toList()
        : text(a['days_of_week']).split(',').where((e) => e.trim().isNotEmpty).toList();
    final days = raw.isEmpty ? '' : daysLabel(raw).replaceAll(' to ', ' - ');
    final from = text(a['working_hours_from']);
    final to = text(a['working_hours_to']);
    final hours = [from, to].where((e) => e.isNotEmpty).join(' - ');
    return [days, hours].where((e) => e.isNotEmpty).join(' | ');
  }

  static String vehicleName(PxMap d) {
    final v = vehicle(d);
    final name = '${text(v['make'])} ${text(v['model'])}'.trim();
    return name;
  }

  static int seatCapacity(PxMap d) {
    final a = availability(d);
    final offered = number(a['seats_offered']).toInt();
    if (offered > 0) return offered;
    final cap = number(vehicle(d)['seating_capacity']).toInt();
    return cap > 0 ? cap : 4;
  }

  static String approval(PxMap d) {
    final s = norm(d['approval_status']);
    if (s == 'approved' || s == 'rejected') return s;
    return 'pending';
  }

  static GeoPx? point(dynamic m, [String latKey = 'lat', String lngKey = 'lng']) {
    if (m is! Map) return null;
    final lat = (m[latKey] as num?)?.toDouble();
    final lng = (m[lngKey] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return GeoPx(lat, lng);
  }

  static double km(GeoPx a, GeoPx b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static int? minutesOfDay(String? t) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$').firstMatch((t ?? '').trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return h * 60 + min;
  }

  static int matchPercent(PxMap driver, PxMap ride) {
    final a = availability(driver);
    double end(GeoPx? x, GeoPx? y, String xt, String yt) {
      if (x != null && y != null) return (1 - km(x, y) / 10).clamp(0.0, 1.0);
      final p = xt.split(',').first.trim().toLowerCase();
      final q = yt.split(',').first.trim().toLowerCase();
      if (p.length < 3 || q.length < 3) return 0.3;
      return (p.contains(q) || q.contains(p)) ? 0.8 : 0.2;
    }

    final start = end(point(a, 'route_from_lat', 'route_from_lng'), point(ride['pickup']),
        text(a['preferred_route_from']), address(ride['pickup']));
    final finish = end(point(a, 'route_to_lat', 'route_to_lng'), point(ride['destination']),
        text(a['preferred_route_to']), address(ride['destination']));
    double time = 0.5;
    final dm = minutesOfDay(text(a['working_hours_from']));
    final rm = minutesOfDay(text(ride['pickup_daily_time']));
    if (dm != null && rm != null) {
      time = ((dm - rm).abs() <= 120) ? 1 : 0;
    }
    return ((start * 0.4 + finish * 0.4 + time * 0.2) * 100).round().clamp(0, 100);
  }

  static String paymentStatus(PxMap p) {
    final ps = norm(p['payment_status']);
    final review = map(p['vendor_review']);
    final rs = norm(review['status']);
    if (ps == 'reupload_requested' || ps == 'rejected' || ps == 'approved') return ps;
    if (const {'paid', 'completed', 'confirmed'}.contains(ps)) return 'approved';
    if (rs == 'reupload_requested' && ps == 'proof_submitted' && p['resubmitted_at'] != null) {
      return 'proof_submitted';
    }
    return rs.isNotEmpty ? rs : (ps.isEmpty ? 'pending' : ps);
  }

  static bool paymentNeedsReview(PxMap p) {
    final s = paymentStatus(p);
    return s == 'proof_submitted' || s == 'pending';
  }

  static bool paymentApproved(PxMap p) => paymentStatus(p) == 'approved';
  static bool paymentReupload(PxMap p) {
    final s = paymentStatus(p);
    return s == 'reupload_requested' || s == 'rejected';
  }

  static num paymentAmount(PxMap p) {
    final a = number(p['amount']);
    return a > 0 ? a : number(p['ride_fare']);
  }

  static DateTime? paymentDate(PxMap p) =>
      date(map(p['vendor_review'])['reviewed_at']) ?? date(p['approved_at']) ?? date(p['transaction_date']);

  static String planOfPayment(PxMap p) {
    final l = text(p['plan_label']).toLowerCase();
    if (l.contains('month')) return 'Monthly';
    if (l.contains('week')) return 'Weekly';
    return text(p['plan_label']);
  }

  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static int isoWeek(DateTime d) {
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final firstDay = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(firstDay).inDays) / 7).floor() + 1;
  }

  static String weekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final sameMonth = start.month == end.month;
    final a = DateFormat(sameMonth ? 'd' : 'd MMM').format(start);
    final b = DateFormat('d MMM').format(end);
    return '$a – $b';
  }

  static String weekKey(DateTime start) => DateFormat('yyyyMMdd').format(start);

  static num commissionPercent(PxMap vendor) {
    final v = number(vendor['commission_percent']);
    return v > 0 ? v : kDefaultCommissionPercent;
  }

  static String sosStatus(PxMap s) => norm(s['status']) == 'resolved' ? 'resolved' : 'active';

  static String methodLabel(String key) {
    switch (key) {
      case 'jazzcash':
        return 'JazzCash';
      case 'easypaisa':
        return 'Easypaisa';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return key;
    }
  }

  static Future<void> notify({
    required String userId,
    required String role,
    required String title,
    required String body,
    required String type,
    String rideId = '',
  }) async {
    if (userId.isEmpty) return;
    try {
      await db.collection('notifications').add({
        'user_id': userId,
        'role': role,
        'audience': role,
        'title': title,
        'body': body,
        'type': type,
        'ride_id': rideId,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Future<String?> approveDriver(String driverId) async {
    try {
      await db.collection('drivers').doc(driverId).update({
        'approval_status': 'approved',
        'vendor_approved_at': FieldValue.serverTimestamp(),
        'rejection_reason': FieldValue.delete(),
        'vendor_rejection_reason': FieldValue.delete(),
      });
      await notify(
        userId: driverId,
        role: 'driver',
        title: 'You are approved',
        body: 'Your vendor approved your driver profile.',
        type: 'driver_approved',
      );
      return null;
    } catch (e) {
      return 'Could not approve the driver. $e';
    }
  }

  static Future<String?> rejectDriver(String driverId, String reason) async {
    try {
      await db.collection('drivers').doc(driverId).update({
        'approval_status': 'rejected',
        'vendor_rejected_at': FieldValue.serverTimestamp(),
        'rejection_reason': reason,
        'vendor_rejection_reason': reason,
        'rejected_vendor_ids': FieldValue.arrayUnion([uid]),
      });
      await notify(
        userId: driverId,
        role: 'driver',
        title: 'Vendor request rejected',
        body: reason.isEmpty ? 'Your vendor did not approve your profile.' : reason,
        type: 'driver_rejected',
      );
      return null;
    } catch (e) {
      return 'Could not reject the driver. $e';
    }
  }

  static Future<String?> reviewPayment({
    required String paymentId,
    required PxMap payment,
    required String status,
    String reason = '',
  }) async {
    try {
      final batch = db.batch();
      batch.update(db.collection('payments').doc(paymentId), {
        'payment_status': status,
        'vendor_review': {
          'status': status,
          'reason': reason,
          'reviewed_at': FieldValue.serverTimestamp(),
          'reviewed_by': uid,
        },
        if (status == 'approved') 'approved_at': FieldValue.serverTimestamp(),
      });
      final rideId = text(payment['rideId']);
      if (rideId.isNotEmpty) {
        batch.set(
          db.collection('active_rides').doc(rideId),
          {
            'payment_status': status,
            if (status == 'approved')
              'weekly_plan': {
                'activated': true,
                'activation_pending': false,
                'activated_at': FieldValue.serverTimestamp(),
              },
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      final title = status == 'approved'
          ? 'Payment approved'
          : status == 'rejected'
              ? 'Payment rejected'
              : 'Please upload a new payment screenshot';
      await notify(
        userId: text(payment['passengerId']),
        role: 'passenger',
        title: title,
        body: reason.isEmpty ? title : reason,
        type: 'payment_$status',
        rideId: rideId,
      );
      return null;
    } catch (e) {
      return 'Could not update the payment. $e';
    }
  }

  static Future<String?> resolveSos(String id) async {
    try {
      await db.collection('sos_alerts').doc(id).update({
        'status': 'resolved',
        'resolved_at': FieldValue.serverTimestamp(),
        'resolved_by': uid,
      });
      return null;
    } catch (e) {
      return 'Could not update the alert. $e';
    }
  }
}

class GeoPx {
  final double lat;
  final double lng;
  const GeoPx(this.lat, this.lng);
}

class PxStreams {
  PxStreams._();

  static Stream<QuerySnapshot<PxMap>> drivers() =>
      Px.db.collection('drivers').where('vendor_id', isEqualTo: Px.uid).limit(300).snapshots();

  static Stream<QuerySnapshot<PxMap>> rides() =>
      Px.db.collection('active_rides').where('vendorId', isEqualTo: Px.uid).limit(400).snapshots();

  static Stream<QuerySnapshot<PxMap>> payments() =>
      Px.db.collection('payments').where('vendorId', isEqualTo: Px.uid).limit(500).snapshots();

  static Stream<QuerySnapshot<PxMap>> sos() =>
      Px.db.collection('sos_alerts').where('vendor_id', isEqualTo: Px.uid).limit(100).snapshots();

  static Stream<QuerySnapshot<PxMap>> payouts() =>
      Px.db.collection('driver_payouts').where('vendor_id', isEqualTo: Px.uid).limit(300).snapshots();

  static Stream<DocumentSnapshot<PxMap>> vendor() => Px.db.collection('vendors').doc(Px.uid).snapshots();

  static Stream<QuerySnapshot<PxMap>> notifications() => Px.db
      .collection('notifications')
      .where('user_id', isEqualTo: Px.uid)
      .orderBy('created_at', descending: true)
      .limit(80)
      .snapshots();
}

List<PxDoc> pxSortedBy(List<PxDoc> docs, DateTime? Function(PxMap d) key) {
  final list = docs.toList();
  list.sort((a, b) {
    final x = key(a.data())?.millisecondsSinceEpoch ?? 0;
    final y = key(b.data())?.millisecondsSinceEpoch ?? 0;
    return y.compareTo(x);
  });
  return list;
}

DateTime? pxRideRequestedAt(PxMap r) {
  final t = Px.map(r['timestamps']);
  return Px.date(t['requested_at']) ?? Px.date(t['booked_at']);
}
