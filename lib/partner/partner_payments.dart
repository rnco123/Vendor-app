import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'partner_data.dart';
import 'partner_links.dart';
import 'partner_ui.dart';

class PartnerPaymentsPage extends StatefulWidget {
  final int initialTab;

  const PartnerPaymentsPage({super.key, this.initialTab = 0});

  @override
  State<PartnerPaymentsPage> createState() => _PartnerPaymentsPageState();
}

class _PartnerPaymentsPageState extends State<PartnerPaymentsPage> {
  late final Stream<QuerySnapshot<PxMap>> _payments = PxStreams.payments();
  late final Stream<QuerySnapshot<PxMap>> _payouts = PxStreams.payouts();
  late final Stream<DocumentSnapshot<PxMap>> _vendor = PxStreams.vendor();
  late int _tab = widget.initialTab.clamp(0, 2);
  int _type = 0;
  int _weekOffset = 0;
  int _payoutTab = 0;

  void _export(List<PxDoc> payments) {
    final lines = <String>['Passenger,Driver,Amount,Status,Date'];
    for (final p in pxSortedBy(payments, Px.paymentDate)) {
      final d = p.data();
      lines.add([
        Px.text(d['passenger_name']),
        Px.text(d['driver_name']),
        Px.plain(Px.paymentAmount(d)),
        Px.paymentStatus(d),
        Px.dayMonthYear(Px.paymentDate(d)),
      ].map((e) => '"${e.replaceAll('"', "'")}"').join(','));
    }
    pxCopy(context, lines.join('\n'), 'Payments copied');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _payments,
      builder: (context, paySnap) {
        return StreamBuilder<QuerySnapshot<PxMap>>(
          stream: _payouts,
          builder: (context, payoutSnap) {
            return StreamBuilder<DocumentSnapshot<PxMap>>(
              stream: _vendor,
              builder: (context, vendorSnap) {
                final payments = paySnap.data?.docs ?? const <PxDoc>[];
                final payouts = payoutSnap.data?.docs ?? const <PxDoc>[];
                final commission = Px.commissionPercent(vendorSnap.data?.data() ?? const {});
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    PxPageTitle('Payments', onExport: () => _export(payments)),
                    PxSegmentTabs(
                      tabs: const ['Passengers', 'Earnings', 'Payouts'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const SizedBox(height: 14),
                    if (!paySnap.hasData)
                      const PxLoading()
                    else if (_tab == 0)
                      ..._passengers(payments)
                    else if (_tab == 1)
                      ..._earnings(payments, commission)
                    else
                      ..._payoutsView(payments, payouts, commission),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _passengers(List<PxDoc> payments) {
    final pending = pxSortedBy(payments.where((p) => Px.paymentNeedsReview(p.data())).toList(),
        (d) => Px.date(d['resubmitted_at']) ?? Px.date(d['transaction_date']));
    final approved = pxSortedBy(payments.where((p) => Px.paymentApproved(p.data())).toList(), Px.paymentDate);
    final reupload = pxSortedBy(payments.where((p) => Px.paymentReupload(p.data())).toList(), Px.paymentDate);
    final lists = [pending, approved, reupload];
    final list = lists[_type];
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _count('${pending.length}', 'To review', kPxAmber),
            _count('${approved.length}', 'Approved', Colors.white),
            _count('${reupload.length}', 'Re-upload', Colors.white),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text('Payments Type', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
      ),
      PxSegmentTabs(
        small: true,
        tabs: ['Pending (${pending.length})', 'Approved (${approved.length})', 'Re-upload (${reupload.length})'],
        index: _type,
        onChanged: (i) => setState(() => _type = i),
      ),
      const SizedBox(height: 14),
      if (list.isEmpty)
        const PxEmpty('Nothing here right now', icon: Icons.receipt_long_outlined)
      else
        for (final p in list) ...[
          if (_type == 2)
            _reuploadCard(p)
          else
            _proofCard(p, review: _type == 0),
          const SizedBox(height: 12),
        ],
    ];
  }

  Widget _count(String v, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(v, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: kPxMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _proofCard(PxDoc doc, {required bool review}) {
    final p = doc.data();
    final name = Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name']);
    final when = Px.date(p['resubmitted_at']) ?? Px.date(p['transaction_date']);
    final method = Px.text(p['payment_method']).isEmpty ? 'Transfer' : _cap(Px.text(p['payment_method']));
    void open() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartnerPaymentProofScreen(paymentId: doc.id)),
        );
    return PxCard(
      child: Column(
        children: [
          Row(
            children: [
              PxLetterAvatar(name: name, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                        PxChip.plan(Px.planOfPayment(p)),
                      ],
                    ),
                    Text([method, if (when != null) DateFormat('d MMM · hh:mm a').format(when)].join(' · '),
                        style: const TextStyle(color: kPxMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(Px.rs(Px.paymentAmount(p)),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          PxCard(
            color: kPxSurface2,
            padding: const EdgeInsets.all(8),
            radius: 10,
            onTap: open,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.description_outlined, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Payment receipt', style: TextStyle(color: Colors.white, fontSize: 12))),
                const Icon(Icons.chevron_right, color: kPxMuted, size: 16),
              ],
            ),
          ),
          if (review) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PartnerRequestReuploadScreen(paymentId: doc.id, payment: p)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4A4A4A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ask re-upload', style: TextStyle(color: kPxAmber, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => pxApprovePayment(context, doc.id, p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPxGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _reuploadCard(PxDoc doc) {
    final p = doc.data();
    final name = Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name']);
    final review = Px.map(p['vendor_review']);
    final reason = Px.text(review['reason']).isEmpty
        ? (Px.paymentStatus(p) == 'rejected' ? 'Payment was rejected.' : 'Please re-upload a clear payment proof.')
        : Px.text(review['reason']);
    final driver = Px.text(p['driver_name']);
    final when = Px.paymentDate(p);
    final tints = [kPxBlue, kPxOrange, kPxAmber, kPxGreen];
    final tint = tints[name.codeUnits.fold<int>(0, (a, b) => a + b) % tints.length];
    return PxCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartnerPaymentProofScreen(paymentId: doc.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PxAvatar(name: name, size: 26, tint: tint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    PxChip.plan(Px.planOfPayment(p)),
                  ],
                ),
              ),
              Text(Px.pkr(Px.paymentAmount(p)),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              [if (driver.isNotEmpty) 'Driver: $driver', if (when != null) Px.dayMonthYear(when)].join(' • '),
              style: const TextStyle(color: kPxMuted, fontSize: 9),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kPxAmber.withAlpha(28), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: kPxAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(reason, style: const TextStyle(color: kPxAmber, fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _earnings(List<PxDoc> payments, num commission) {
    final approved = payments.where((p) => Px.paymentApproved(p.data())).toList();
    final start = Px.weekStart(DateTime.now()).add(Duration(days: 7 * _weekOffset));
    final end = start.add(const Duration(days: 7));
    final week = pxSortedBy(
      approved.where((p) {
        final d = Px.paymentDate(p.data());
        return d != null && !d.isBefore(start) && d.isBefore(end);
      }).toList(),
      Px.paymentDate,
    );
    final total = week.fold<num>(0, (s, p) => s + Px.paymentAmount(p.data()));
    final mine = total * commission / 100;
    final pct = commission % 1 == 0 ? commission.toInt().toString() : commission.toString();
    return [
      PxCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your commission', style: TextStyle(color: kPxMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('$pct% per payment',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kPxSurface2, borderRadius: BorderRadius.circular(20)),
              child: Text('${approved.length} payments', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ),
      ),
      PxSectionLabel(_weekOffset == 0 ? 'This week summary' : 'Week summary',
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 8)),
      SizedBox(
        height: 70,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _summary('Total Collected', Px.pkr(total), kPxGreen),
            _summary('My Commission($pct%)', Px.pkr(mine), kPxGreen),
            _summary('Driver Share', Px.pkr(total - mine), kPxGreen),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _navCircle(Icons.chevron_left, () => setState(() => _weekOffset--)),
          Expanded(
            child: Text(
              '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end.subtract(const Duration(days: 1)))}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kPxMuted, fontSize: 12),
            ),
          ),
          _navCircle(Icons.chevron_right, _weekOffset >= 0 ? null : () => setState(() => _weekOffset++)),
        ],
      ),
      const SizedBox(height: 14),
      if (week.isEmpty)
        const PxEmpty('No approved payments this week', icon: Icons.payments_outlined)
      else
        for (final p in week) ...[
          _earningRow(p.data(), commission),
          const SizedBox(height: 10),
        ],
    ];
  }

  Widget _navCircle(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
        child: Icon(icon, color: onTap == null ? const Color(0xFF555555) : Colors.white, size: 16),
      ),
    );
  }

  Widget _summary(String label, String value, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 1, style: const TextStyle(color: kPxMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _earningRow(PxMap p, num commission) {
    final amount = Px.paymentAmount(p);
    final mine = amount * commission / 100;
    final passenger = Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name']);
    final driver = Px.text(p['driver_name']).isEmpty ? 'Driver' : Px.text(p['driver_name']);
    final when = Px.paymentDate(p);
    return PxCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$passenger → $driver',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [if (when != null) DateFormat('d MMM').format(when), Px.planOfPayment(p)]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(color: kPxMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Px.pkr(amount), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Driver ${Px.plain(amount - mine)}', style: const TextStyle(color: kPxOrange, fontSize: 10)),
              Text('You ${Px.plain(mine)}', style: const TextStyle(color: kPxGreen, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _payoutsView(List<PxDoc> payments, List<PxDoc> payouts, num commission) {
    final pending = pxPendingPayouts(payments, payouts, commission);
    final paid = pxSortedBy(payouts, (d) => Px.date(d['paid_at']));
    final toPay = pending.fold<num>(0, (s, g) => s + g.net);
    final paidOut = paid.fold<num>(0, (s, p) => s + Px.number(p.data()['amount_paid']));
    return [
      const PxSectionLabel('Payout summary', padding: EdgeInsets.fromLTRB(0, 4, 0, 8)),
      SizedBox(
        height: 70,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _summary('Total to Pay', Px.pkr(toPay), kPxGreen),
            _summary('Paid out', Px.pkr(paidOut), kPxGreen),
            _summary('Pending payouts', '${pending.length}', kPxGreen),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PxSegmentTabs(
        tabs: const ['Pending', 'Paid'],
        index: _payoutTab,
        onChanged: (i) => setState(() => _payoutTab = i),
      ),
      const SizedBox(height: 14),
      if (_payoutTab == 0) ...[
        if (pending.isEmpty)
          const PxEmpty('No driver payouts due', icon: Icons.account_balance_outlined)
        else
          for (final g in pending) ...[
            _payoutRow(
              name: g.driverName,
              line1: 'Week ${Px.isoWeek(g.weekStart)} · ${Px.weekRange(g.weekStart)}',
              line2: '${g.passengers} passenger${g.passengers == 1 ? '' : 's'}${g.plan.isEmpty ? '' : ' · ${g.plan}'}',
              amount: g.net,
              button: SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartnerPayDriverScreen(group: g, commission: commission)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPxGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ] else ...[
        if (paid.isEmpty)
          const PxEmpty('No payouts made yet', icon: Icons.receipt_long_outlined)
        else
          for (final p in paid) ...[
            _payoutRow(
              name: Px.text(p.data()['driver_name']).isEmpty ? 'Driver' : Px.text(p.data()['driver_name']),
              line1: Px.text(p.data()['week_label']),
              line2: '${Px.number(p.data()['passengers']).toInt()} passengers',
              amount: Px.number(p.data()['amount_paid']),
              button: SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartnerPayoutReceiptScreen(payout: p.data())),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6A6A6A)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Receipt', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    ];
  }

  Widget _payoutRow({
    required String name,
    required String line1,
    required String line2,
    required num amount,
    required Widget button,
  }) {
    return PxCard(
      child: Row(
        children: [
          PxAvatar(name: name, size: 38, photoStyle: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(line1, style: const TextStyle(color: kPxMuted, fontSize: 11)),
                Text(line2, style: const TextStyle(color: kPxMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Px.pkr(amount), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              button,
            ],
          ),
        ],
      ),
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class PxPayoutGroup {
  final String driverId;
  final String driverName;
  final DateTime weekStart;
  final num gross;
  final num commission;
  final num commissionPercent;
  final int passengers;
  final int trips;
  final String plan;
  final List<String> paymentIds;

  PxPayoutGroup({
    required this.driverId,
    required this.driverName,
    required this.weekStart,
    required this.gross,
    required this.commission,
    required this.commissionPercent,
    required this.passengers,
    required this.trips,
    required this.plan,
    required this.paymentIds,
  });

  num get net => gross - commission;
  String get key => '${driverId}_${Px.weekKey(weekStart)}';
  String get weekLabel => 'Week ${Px.isoWeek(weekStart)} · ${Px.weekRange(weekStart)}';
}

List<PxPayoutGroup> pxPendingPayouts(List<PxDoc> payments, List<PxDoc> payouts, num commissionPercent) {
  final paidKeys = payouts.map((p) => p.id).toSet();
  final groups = <String, List<PxMap>>{};
  final ids = <String, List<String>>{};
  for (final p in payments) {
    final d = p.data();
    if (!Px.paymentApproved(d)) continue;
    final driverId = Px.text(d['driverId']);
    final when = Px.paymentDate(d);
    if (driverId.isEmpty || when == null) continue;
    final key = '${driverId}_${Px.weekKey(Px.weekStart(when))}';
    if (paidKeys.contains(key)) continue;
    groups.putIfAbsent(key, () => []).add(d);
    ids.putIfAbsent(key, () => []).add(p.id);
  }
  final out = <PxPayoutGroup>[];
  groups.forEach((key, list) {
    final first = list.first;
    final when = Px.paymentDate(first)!;
    final gross = list.fold<num>(0, (s, d) => s + Px.paymentAmount(d));
    final plans = <String, int>{};
    for (final d in list) {
      final pl = Px.planOfPayment(d);
      if (pl.isNotEmpty) plans[pl] = (plans[pl] ?? 0) + 1;
    }
    final plan = plans.isEmpty ? '' : (plans.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    out.add(PxPayoutGroup(
      driverId: Px.text(first['driverId']),
      driverName: Px.text(first['driver_name']).isEmpty ? 'Driver' : Px.text(first['driver_name']),
      weekStart: Px.weekStart(when),
      gross: gross,
      commission: gross * commissionPercent / 100,
      commissionPercent: commissionPercent,
      passengers: list.map((d) => Px.text(d['passengerId'])).toSet().length,
      trips: list.length,
      plan: plan,
      paymentIds: ids[key] ?? const [],
    ));
  });
  out.sort((a, b) => b.weekStart.compareTo(a.weekStart));
  return out;
}

Future<void> pxApprovePayment(BuildContext context, String paymentId, PxMap payment, {bool replace = false}) async {
  final err = await Px.reviewPayment(paymentId: paymentId, payment: payment, status: 'approved');
  if (!context.mounted) return;
  if (err != null) {
    pxToast(context, err, ok: false);
    return;
  }
  final route = MaterialPageRoute<void>(
    builder: (_) => PartnerPaymentApprovedScreen(payment: payment, verifiedAt: DateTime.now()),
  );
  if (replace) {
    await Navigator.pushReplacement(context, route);
  } else {
    await Navigator.push(context, route);
  }
}

class PartnerPaymentProofScreen extends StatefulWidget {
  final String paymentId;

  const PartnerPaymentProofScreen({super.key, required this.paymentId});

  @override
  State<PartnerPaymentProofScreen> createState() => _PartnerPaymentProofScreenState();
}

class _PartnerPaymentProofScreenState extends State<PartnerPaymentProofScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _doc =
      Px.db.collection('payments').doc(widget.paymentId).snapshots();
  bool _busy = false;

  Future<void> _reject(PxMap p) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPxSurface,
        title: const Text('Reject payment?', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: TextField(
          controller: reason,
          cursorColor: kPxGreen,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: TextStyle(color: kPxMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kPxGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: kPxRed)),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final err = await Px.reviewPayment(paymentId: widget.paymentId, payment: p, status: 'rejected', reason: text);
    if (!mounted) return;
    setState(() => _busy = false);
    pxToast(context, err ?? 'Payment rejected', ok: err == null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Payment Proof'),
      body: StreamBuilder<DocumentSnapshot<PxMap>>(
        stream: _doc,
        builder: (context, snap) {
          if (!snap.hasData) return const PxLoading();
          final p = snap.data!.data();
          if (p == null) return const PxEmpty('Payment not found');
          final status = Px.paymentStatus(p);
          final review = Px.paymentNeedsReview(p);
          final url = Px.text(p['proof_url']);
          final name = Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name']);
          final submitted = Px.date(p['resubmitted_at']) ?? Px.date(p['transaction_date']);
          final statusLabel = {
                'approved': 'Approved',
                'rejected': 'Rejected',
                'reupload_requested': 'Re-upload requested',
              }[status] ??
              'Pending review';
          final statusColor = status == 'approved' ? kPxGreen : (status == 'rejected' ? kPxRed : kPxAmber);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Screenshot', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
              ),
              GestureDetector(
                onTap: url.isEmpty ? null : () => pxOpenUrl(context, url),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: kPxSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPxGreen, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: url.isEmpty
                      ? const Center(child: Text('No screenshot attached', style: TextStyle(color: kPxMuted)))
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (c, child, prog) => prog == null
                              ? child
                              : const Center(child: CircularProgressIndicator(color: kPxGreen, strokeWidth: 2)),
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('Could not load the image', style: TextStyle(color: kPxMuted))),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          PxAvatar(name: name, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                if (Px.text(p['driver_name']).isNotEmpty)
                                  Text('Driver: ${Px.text(p['driver_name'])}',
                                      style: const TextStyle(color: kPxMuted, fontSize: 9)),
                              ],
                            ),
                          ),
                          PxChip(Px.planOfPayment(p), kPxGreen),
                        ],
                      ),
                    ),
                    const Divider(color: kPxBorder, height: 1),
                    PxInfoTable(
                      [
                        MapEntry('Amount', Px.pkr(Px.paymentAmount(p))),
                        MapEntry('Payment Method', _cap(Px.text(p['payment_method']).isEmpty ? 'transfer' : Px.text(p['payment_method']))),
                        MapEntry('Transaction ID', Px.text(p['transaction_id']).isEmpty ? widget.paymentId : Px.text(p['transaction_id'])),
                        MapEntry('Submitted', submitted == null ? '' : DateFormat('d MMM yyyy, hh:mm a').format(submitted)),
                        MapEntry('Status', statusLabel),
                      ],
                      valueColors: {'Status': statusColor},
                    ),
                  ],
                ),
              ),
              if (review) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PxButton(
                        label: 'Approve',
                        onPressed: _busy ? null : () => pxApprovePayment(context, widget.paymentId, p, replace: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PxButton(label: 'Reject', color: kPxRed, loading: _busy, onPressed: () => _reject(p)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PxButton.dark(
                  label: 'Ask for Re-upload',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartnerRequestReuploadScreen(paymentId: widget.paymentId, payment: p),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PartnerPaymentApprovedScreen extends StatelessWidget {
  final PxMap payment;
  final DateTime verifiedAt;

  const PartnerPaymentApprovedScreen({super.key, required this.payment, required this.verifiedAt});

  @override
  Widget build(BuildContext context) {
    final name = Px.text(payment['passenger_name']).isEmpty ? 'Passenger' : Px.text(payment['passenger_name']);
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Payment Proof'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 18),
              const PxCheckBadge(size: 52, outlined: true),
              const SizedBox(height: 14),
              const Text('Payment Approved!',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Payment has been verified successfully.', style: TextStyle(color: kPxMuted, fontSize: 12)),
              const SizedBox(height: 26),
              Container(
                decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          PxAvatar(name: name, size: 26),
                          const SizedBox(width: 10),
                          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                          PxChip(Px.planOfPayment(payment), kPxGreen),
                        ],
                      ),
                    ),
                    PxInfoTable([
                      MapEntry('Amount', Px.pkr(Px.paymentAmount(payment))),
                      MapEntry('Driver', Px.text(payment['driver_name'])),
                      MapEntry('Verified on', DateFormat('d MMM yyyy, hh:mm a').format(verifiedAt)),
                    ]),
                  ],
                ),
              ),
              const Spacer(),
              PxButton(label: 'OK', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerRequestReuploadScreen extends StatefulWidget {
  final String paymentId;
  final PxMap payment;

  const PartnerRequestReuploadScreen({super.key, required this.paymentId, required this.payment});

  @override
  State<PartnerRequestReuploadScreen> createState() => _PartnerRequestReuploadScreenState();
}

class _PartnerRequestReuploadScreenState extends State<PartnerRequestReuploadScreen> {
  final _reason = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      pxToast(context, 'Please add a reason for the passenger', ok: false);
      return;
    }
    setState(() => _sending = true);
    final err = await Px.reviewPayment(
      paymentId: widget.paymentId,
      payment: widget.payment,
      status: 'reupload_requested',
      reason: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    pxToast(context, err ?? 'Re-upload request sent', ok: err == null);
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final name = Px.text(p['passenger_name']).isEmpty ? 'Passenger' : Px.text(p['passenger_name']);
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Payment Proof'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Color(0xFF3A2410), shape: BoxShape.circle),
                      child: const Icon(Icons.access_time, color: kPxOrange, size: 28),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text('Request Re-upload',
                        style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Ask passenger to upload the correct payment\nproof.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kPxMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PxCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PxAvatar(name: name, size: 26),
                            const SizedBox(width: 10),
                            Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                            PxChip(Px.planOfPayment(p), kPxGreen),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Text('Amount', style: TextStyle(color: Color(0xFFB5B5B5), fontSize: 12))),
                            Text(Px.pkr(Px.paymentAmount(p)), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                        const Divider(color: kPxBorder, height: 26),
                        const Text('Reason of Re-upload', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reason,
                          minLines: 3,
                          maxLines: 5,
                          cursorColor: kPxGreen,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Please upload clear screenshot with correct amount.',
                            hintStyle: const TextStyle(color: kPxMuted, fontSize: 12),
                            filled: true,
                            fillColor: kPxSurface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: PxButton(label: 'Send Request', loading: _sending, onPressed: _send),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerPayDriverScreen extends StatefulWidget {
  final PxPayoutGroup group;
  final num commission;

  const PartnerPayDriverScreen({super.key, required this.group, required this.commission});

  @override
  State<PartnerPayDriverScreen> createState() => _PartnerPayDriverScreenState();
}

class _PartnerPayDriverScreenState extends State<PartnerPayDriverScreen> {
  late final Future<DocumentSnapshot<PxMap>> _driver =
      Px.db.collection('drivers').doc(widget.group.driverId).get();
  bool _paying = false;

  String _pct(num v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  String _mask(String n) {
    final t = n.replaceAll(' ', '');
    if (t.length <= 4) return t;
    return '**** **** **** ${t.substring(t.length - 4)}';
  }

  Future<void> _confirm(PxMap driver) async {
    final g = widget.group;
    final pm = Px.map(driver['payment_methods']);
    final method = Px.text(pm['active']);
    final det = Px.map(pm[method]);
    final bank = Px.text(det['bank_name']);
    final via = [if (method.isNotEmpty) Px.methodLabel(method), if (bank.isNotEmpty) bank].join(' · ');
    final ok = await showPxSheet<bool>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: PxSheetHandle()),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text('Confirm Payment',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Color(0xFFB5B5B5), size: 14),
                  ),
                ),
              ],
            ),
            const Divider(color: kPxBorder, height: 22),
            PxInfoTable(
              [
                MapEntry('Week', g.weekLabel),
                MapEntry('Paid via', via),
                MapEntry('Gross collected', Px.pkr(g.gross)),
                MapEntry('Commission (${_pct(widget.commission)}%)', Px.pkr(g.commission)),
              ],
              valueColors: const {'Gross collected': kPxGreen},
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPxSurface2, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Expanded(child: Text('Paying now', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14))),
                  Text(Px.pkr(g.net), style: const TextStyle(color: kPxBlue, fontSize: 17, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PxButton(label: 'Confirm & Pay', onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _paying = true);
    final txn = 'TXN-${DateFormat('yyyyMMdd').format(DateTime.now())}-${1000 + math.Random().nextInt(9000)}';
    final payout = <String, dynamic>{
      'vendor_id': Px.uid,
      'driver_id': g.driverId,
      'driver_name': g.driverName,
      'week_start': Timestamp.fromDate(g.weekStart),
      'week_key': Px.weekKey(g.weekStart),
      'week_label': g.weekLabel,
      'gross': g.gross,
      'commission_percent': widget.commission,
      'commission': g.commission,
      'amount_paid': g.net,
      'trips': g.trips,
      'passengers': g.passengers,
      'method': method,
      'method_label': via,
      'bank_name': bank,
      'account_title': Px.text(det['account_title']),
      'account_number': Px.text(det['account_number']),
      'payment_ids': g.paymentIds,
      'status': 'paid',
      'transaction_id': txn,
      'paid_at': FieldValue.serverTimestamp(),
    };
    try {
      await Px.db.collection('driver_payouts').doc(g.key).set(payout);
      await Px.notify(
        userId: g.driverId,
        role: 'driver',
        title: 'Payout sent',
        body: '${Px.pkr(g.net)} for ${g.weekLabel}',
        type: 'driver_payout',
      );
      if (!mounted) return;
      final shown = Map<String, dynamic>.from(payout)..['paid_at'] = Timestamp.now();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PartnerPayoutReceiptScreen(payout: shown)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      pxToast(context, 'Could not save the payout. $e', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Pay Driver'),
      body: FutureBuilder<DocumentSnapshot<PxMap>>(
        future: _driver,
        builder: (context, snap) {
          if (!snap.hasData) return const PxLoading();
          final d = snap.data!.data() ?? const <String, dynamic>{};
          final pm = Px.map(d['payment_methods']);
          final method = Px.text(pm['active']);
          final det = Px.map(pm[method]);
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      PxCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                PxAvatar(
                                    name: g.driverName,
                                    imageUrl: Px.text(d['profile_image_url']),
                                    size: 38,
                                    photoStyle: true),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.driverName,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text('Week ${Px.isoWeek(g.weekStart)} • ${Px.weekRange(g.weekStart)} ${g.weekStart.year}',
                                          style: const TextStyle(color: kPxMuted, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _row('Passengers total', Px.pkr(g.gross), kPxGreen),
                            _row('Your commission (${_pct(widget.commission)}%)', Px.pkr(g.commission), Colors.white),
                            _row('Trips Completed', '${g.trips} trips', const Color(0xFFB5B5B5)),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text('Driver Receives', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14)),
                                  ),
                                  Text(Px.pkr(g.net),
                                      style: const TextStyle(color: kPxBlue, fontSize: 17, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PxCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_outlined, color: kPxGreen, size: 16),
                                SizedBox(width: 8),
                                Text('Driver Bank Details', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (method.isEmpty)
                              const Text('This driver has not added payment details yet.',
                                  style: TextStyle(color: kPxAmber, fontSize: 11))
                            else ...[
                              _detail('Bank Name', Px.text(det['bank_name']).isEmpty ? Px.methodLabel(method) : Px.text(det['bank_name'])),
                              _detail('Account Title', Px.text(det['account_title'])),
                              _detail('Account Number', _mask(Px.text(det['account_number']))),
                              if (Px.text(det['iban']).isNotEmpty) _detail('IBAN', Px.text(det['iban'])),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: PxButton(label: 'Proceed to confirm', loading: _paying, onPressed: () => _confirm(d)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String a, String b, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kPxBorder))),
      child: Row(
        children: [
          Expanded(child: Text(a, style: const TextStyle(color: kPxMuted, fontSize: 11))),
          Text(b, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _detail(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(a, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 11))),
          Text(b.isEmpty ? '—' : b, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 11)),
        ],
      ),
    );
  }
}

class PartnerPayoutReceiptScreen extends StatelessWidget {
  final PxMap payout;

  const PartnerPayoutReceiptScreen({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    final p = payout;
    final paidAt = Px.date(p['paid_at']) ?? DateTime.now();
    final name = Px.text(p['driver_name']);
    final via = Px.text(p['method_label']);
    final week = Px.text(p['week_label']).split(' · ').first;
    final pct = Px.number(p['commission_percent']);
    final receipt = [
      'PoolX payout receipt',
      'Driver: $name',
      'Week: ${Px.text(p['week_label'])}',
      'Gross collected: ${Px.pkr(Px.number(p['gross']))}',
      'Commission (${pct % 1 == 0 ? pct.toInt() : pct}%): ${Px.pkr(Px.number(p['commission']))}',
      'Amount paid: ${Px.pkr(Px.number(p['amount_paid']))}',
      'Method: $via',
      'Date: ${DateFormat('d MMM yyyy · h:mm a').format(paidAt)}',
      'Transaction ID: ${Px.text(p['transaction_id'])}',
    ].join('\n');
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Payment Receipt'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 16),
            const Center(child: PxCheckBadge(size: 52, outlined: true)),
            const SizedBox(height: 14),
            const Center(
              child: Text('Payment Sent!', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${Px.pkr(Px.number(p['amount_paid']))} successfully transferred\nto $name${via.isEmpty ? '' : ' via $via'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kPxMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 22),
            PxInfoTable(
              [
                MapEntry('Driver', name),
                MapEntry('Week', week),
                MapEntry('Gross collected', Px.pkr(Px.number(p['gross']))),
                MapEntry('Commission deducted', Px.pkr(Px.number(p['commission']))),
                MapEntry('Amount paid', Px.pkr(Px.number(p['amount_paid']))),
                MapEntry('Method', via),
                MapEntry('Date & time', DateFormat('d MMM yyyy · h:mm a').format(paidAt)),
                const MapEntry('Status', 'Paid'),
              ],
              valueColors: const {'Gross collected': kPxGreen, 'Amount paid': kPxBlue, 'Status': kPxGreen},
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF151C2B), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Expanded(child: Text('# Transaction ID', style: TextStyle(color: kPxBlue, fontSize: 11))),
                  Text(Px.text(p['transaction_id']), style: const TextStyle(color: kPxMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            PxButton(label: 'Download Receipt', onPressed: () => pxCopy(context, receipt, 'Receipt copied')),
            const SizedBox(height: 10),
            PxButton.dark(label: 'Back to Payouts', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
