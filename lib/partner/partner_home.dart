import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'partner_data.dart';
import 'partner_monitoring.dart';
import 'partner_shell.dart';
import 'partner_ui.dart';

class PartnerHomePage extends StatefulWidget {
  const PartnerHomePage({super.key});

  @override
  State<PartnerHomePage> createState() => _PartnerHomePageState();
}

class _PartnerHomePageState extends State<PartnerHomePage> {
  late final Stream<QuerySnapshot<PxMap>> _payments = PxStreams.payments();
  late final Stream<QuerySnapshot<PxMap>> _drivers = PxStreams.drivers();
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  late final Stream<QuerySnapshot<PxMap>> _sos = PxStreams.sos();

  @override
  Widget build(BuildContext context) {
    final scope = PartnerScope.of(context);
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _payments,
      builder: (context, paySnap) {
        return StreamBuilder<QuerySnapshot<PxMap>>(
          stream: _drivers,
          builder: (context, driverSnap) {
            return StreamBuilder<QuerySnapshot<PxMap>>(
              stream: _rides,
              builder: (context, rideSnap) {
                return StreamBuilder<QuerySnapshot<PxMap>>(
                  stream: _sos,
                  builder: (context, sosSnap) {
                    final payments = paySnap.data?.docs ?? const <PxDoc>[];
                    final drivers = driverSnap.data?.docs ?? const <PxDoc>[];
                    final rides = rideSnap.data?.docs ?? const <PxDoc>[];
                    final sos = sosSnap.data?.docs ?? const <PxDoc>[];
                    return _content(context, scope, payments, drivers, rides, sos);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    PartnerScope? scope,
    List<PxDoc> payments,
    List<PxDoc> drivers,
    List<PxDoc> rides,
    List<PxDoc> sos,
  ) {
    final approved = payments.where((p) => Px.paymentApproved(p.data())).toList();
    final now = DateTime.now();
    final thisWeek = Px.weekStart(now);
    final lastWeek = thisWeek.subtract(const Duration(days: 7));
    num sumBetween(DateTime a, DateTime b) => approved.fold<num>(0, (s, p) {
          final d = Px.paymentDate(p.data());
          if (d == null || d.isBefore(a) || !d.isBefore(b)) return s;
          return s + Px.paymentAmount(p.data());
        });
    final week = sumBetween(thisWeek, thisWeek.add(const Duration(days: 7)));
    final prev = sumBetween(lastWeek, thisWeek);
    final today = DateTime(now.year, now.month, now.day);
    final spark = List<double>.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return sumBetween(day, day.add(const Duration(days: 1))).toDouble();
    });
    String change;
    if (prev <= 0) {
      change = week > 0 ? 'New this week' : 'No earnings yet';
    } else {
      final pct = (week - prev) / prev * 100;
      change = '${pct >= 0 ? '+' : '−'} ${pct.abs().toStringAsFixed(1)}% from last week';
    }

    final activeRides = rides.where((r) => Px.rideActiveNow(r.data())).length;
    final approvedDrivers = drivers.where((d) => Px.approval(d.data()) == 'approved').length;
    final subs = rides.where((r) => Px.rideHasSubscription(r.data())).length;
    final pendingDrivers = drivers.where((d) => Px.approval(d.data()) == 'pending').length;
    final toReview = pxSortedBy(
      payments.where((p) => Px.paymentNeedsReview(p.data())).toList(),
      (d) => Px.date(d['resubmitted_at']) ?? Px.date(d['transaction_date']),
    );
    final requests = rides.where((r) => Px.rideIsRequest(r.data())).length;
    final recent = pxSortedBy(approved, Px.paymentDate);
    final activeSos = pxSortedBy(
      sos.where((s) => Px.sosStatus(s.data()) == 'active').toList(),
      (d) => Px.date(d['created_at']),
    );

    String reviewSub = '';
    if (toReview.isNotEmpty) {
      final p = toReview.first.data();
      reviewSub = '${Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name'])} · ${Px.rs(Px.paymentAmount(p))}';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        PxCard(
          padding: const EdgeInsets.all(14),
          radius: 14,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Earnings (This Week)',
                        style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(Px.pkr(week),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(change, style: const TextStyle(color: kPxGreen, fontSize: 10)),
                  ],
                ),
              ),
              SizedBox(width: 110, height: 52, child: CustomPaint(painter: _SparkPainter(spark))),
            ],
          ),
        ),
        const PxSectionLabel('Today'),
        SizedBox(
          height: 74,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _stat('$activeRides', 'Active ride', () => scope?.goTo(PartnerPage.monitoring)),
              _stat('$approvedDrivers', 'Drivers', () => scope?.goTo(PartnerPage.drivers, subTab: 1)),
              _stat('$subs', 'Subscriptions', () => scope?.goTo(PartnerPage.passengers, subTab: 2)),
            ],
          ),
        ),
        const PxSectionLabel('Needs attention'),
        Container(
          decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _attention(Icons.directions_car, kPxAmber, 'Drivers to approve', '', pendingDrivers,
                  () => scope?.goTo(PartnerPage.drivers, subTab: 2)),
              _attention(Icons.account_balance_wallet_outlined, kPxGreen, 'Payment to review', reviewSub,
                  toReview.length, () => scope?.goTo(PartnerPage.payments)),
              _attention(Icons.airline_seat_recline_normal, kPxBlue, 'Passenger requests', '', requests,
                  () => scope?.goTo(PartnerPage.passengers, subTab: 1)),
            ],
          ),
        ),
        PxSectionLabel(
          'Recent',
          trailing: GestureDetector(
            onTap: () => scope?.goTo(PartnerPage.payments, subTab: 1),
            child: const Text('See all', style: TextStyle(color: kPxGreen, fontSize: 13)),
          ),
        ),
        if (recent.isEmpty)
          const PxCard(
            child: Text('No payments received yet', style: TextStyle(color: kPxMuted, fontSize: 13)),
          )
        else
          for (final p in recent.take(3)) ...[
            PxCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment received', style: TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${Px.pkr(Px.paymentAmount(p.data()))} from ${Px.text(p.data()['passenger_name']).isEmpty ? 'passenger' : Px.text(p.data()['passenger_name'])}',
                          style: const TextStyle(color: kPxMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(Px.ago(Px.paymentDate(p.data())), style: const TextStyle(color: kPxMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        for (final s in activeSos.take(1)) ...[
          const SizedBox(height: 4),
          PartnerSosBanner(
            alertId: s.id,
            data: s.data(),
          ),
        ],
      ],
    );
  }

  Widget _stat(String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, style: const TextStyle(color: kPxMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _attention(IconData icon, Color color, String title, String sub, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: kPxMuted, fontSize: 11)),
                ],
              ),
            ),
            Text('$count', style: const TextStyle(color: kPxMuted, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kPxMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;

  _SparkPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width : size.width * i / (values.length - 1);
      final ratio = max <= 0 ? 0.15 : 0.12 + 0.76 * values[i] / max;
      pts.add(Offset(x, size.height * (1 - ratio)));
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPxGreen.withAlpha(110), kPxGreen.withAlpha(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = kPxGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 2.6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values;
}
