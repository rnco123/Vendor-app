import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../vendor/vendor_passenger_requests_screen.dart' show VendorPassengerRequests;
import 'partner_chat.dart';
import 'partner_data.dart';
import 'partner_links.dart';
import 'partner_ui.dart';

class PartnerMonitoringPage extends StatefulWidget {
  const PartnerMonitoringPage({super.key});

  @override
  State<PartnerMonitoringPage> createState() => _PartnerMonitoringPageState();
}

class _PartnerMonitoringPageState extends State<PartnerMonitoringPage> {
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  late final Stream<QuerySnapshot<PxMap>> _drivers = PxStreams.drivers();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _rides,
      builder: (context, snap) {
        return StreamBuilder<QuerySnapshot<PxMap>>(
          stream: _drivers,
          builder: (context, driverSnap) {
            final rides = snap.data?.docs ?? const <PxDoc>[];
            final drivers = {for (final d in driverSnap.data?.docs ?? const <PxDoc>[]) d.id: d.data()};
            final active = pxSortedBy(rides.where((r) => Px.rideActiveNow(r.data())).toList(), pxRideRequestedAt);
            final done = rides.where((r) => Px.rideCompletedToday(r.data())).length;
            final list = active.where((r) {
              if (_q.isEmpty) return true;
              final d = r.data();
              return [
                Px.text(d['driver_name']),
                VendorPassengerRequests.passengerName(d),
                Px.address(d['pickup']),
                Px.address(d['destination']),
              ].join(' ').toLowerCase().contains(_q);
            }).toList();
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Text('Monitoring Rides',
                      style: TextStyle(color: kPxGreen, fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const Divider(color: kPxBorder, height: 20),
                Row(
                  children: [
                    Expanded(child: _stat('${active.length}', 'Active Rides')),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('$done', 'Complete Today')),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 18, 0, 0),
                  child: Text('Active Rides',
                      style: TextStyle(color: kPxGreen, fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const Divider(color: kPxBorder, height: 20),
                PxSearchField(hint: 'Search rides', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
                const SizedBox(height: 14),
                if (!snap.hasData)
                  const PxLoading()
                else if (list.isEmpty)
                  const PxEmpty('No active rides right now', icon: Icons.route_outlined)
                else
                  for (final r in list) ...[
                    _rideCard(r.data(), drivers[Px.text(r.data()['driverId'])] ?? const {}),
                    const SizedBox(height: 14),
                  ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _stat(String v, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: const TextStyle(color: kPxGreen, fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: kPxMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _rideCard(PxMap r, PxMap driver) {
    final name = Px.text(r['driver_name']).isEmpty ? Px.text(driver['full_name']) : Px.text(r['driver_name']);
    final rating = Px.number(r['driver_rating']) > 0 ? Px.number(r['driver_rating']) : Px.number(driver['average_rating']);
    final trips = Px.number(driver['total_rides']).toInt();
    final driverId = Px.text(r['driverId']);
    final live = Px.point(r['driver_live']);
    return PxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PxRoute(
            from: Px.address(r['pickup']),
            to: Px.address(r['destination']),
            fromLabel: 'Starting Point',
            toLabel: 'End Point',
            pins: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PxAvatar(name: name, imageUrl: Px.text(driver['profile_image_url']), size: 36, photoStyle: true),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Driver' : name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  Text('★ ${rating.toStringAsFixed(1)} ($trips rides)',
                      style: const TextStyle(color: kPxAmber, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _action(Icons.chat_bubble_outline, 'Chat', kPxAmber, () {
                  if (driverId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartnerDriverChatScreen(driverId: driverId, driverName: name)),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _action(Icons.person_pin_circle_outlined, 'Track', kPxBlue, () {
                  if (live != null) {
                    pxOpenMap(context, live.lat, live.lng);
                  } else {
                    pxOpenDirections(context, Px.address(r['pickup']), Px.address(r['destination']));
                  }
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(color: color.withAlpha(36), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class PartnerSosPage extends StatefulWidget {
  const PartnerSosPage({super.key});

  @override
  State<PartnerSosPage> createState() => _PartnerSosPageState();
}

class _PartnerSosPageState extends State<PartnerSosPage> {
  late final Stream<QuerySnapshot<PxMap>> _sos = PxStreams.sos();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _sos,
      builder: (context, snap) {
        final all = pxSortedBy(snap.data?.docs ?? const <PxDoc>[], (d) => Px.date(d['created_at']));
        final active = all.where((s) => Px.sosStatus(s.data()) == 'active').toList();
        final resolved = all.where((s) => Px.sosStatus(s.data()) == 'resolved').toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            const PxPageTitle('SOS Alerts'),
            const PxSectionLabel('Active', padding: EdgeInsets.fromLTRB(12, 0, 0, 8)),
            if (!snap.hasData)
              const PxLoading()
            else if (active.isEmpty)
              const PxCard(child: Text('No active alerts', style: TextStyle(color: kPxMuted, fontSize: 13)))
            else
              for (final s in active) ...[
                _activeCard(s.id, s.data()),
                const SizedBox(height: 10),
              ],
            const PxSectionLabel('Resolved', padding: EdgeInsets.fromLTRB(12, 18, 0, 8)),
            if (resolved.isEmpty)
              const PxCard(child: Text('No resolved alerts yet', style: TextStyle(color: kPxMuted, fontSize: 13)))
            else
              Container(
                decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    for (final s in resolved)
                      ListTile(
                        dense: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PartnerSosDetailScreen(alertId: s.id)),
                        ),
                        title: Text(
                          '${_who(s.data(), 'passenger')} · ${_who(s.data(), 'driver')}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(_when(s.data()), style: const TextStyle(color: kPxMuted, fontSize: 11)),
                        trailing: const PxChip('Resolved', kPxGreen, fontSize: 9),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _activeCard(String id, PxMap s) {
    final loc = Px.point(s['location']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF241313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8E1F1F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kPxRed, borderRadius: BorderRadius.circular(20)),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(_when(s), style: const TextStyle(color: Color(0xFFB5B5B5), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _person('Passenger', _who(s, 'passenger'), Px.text(s['passenger_phone']))),
              Expanded(child: _person('Driver', _who(s, 'driver'), Px.text(s['driver_phone']))),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: loc == null ? null : () => pxOpenMap(context, loc.lat, loc.lng),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: kPxRed.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.location_on_outlined, color: kPxRed, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc == null ? 'Location not shared' : 'Location available',
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      if (loc != null)
                        Text('${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
                            style: const TextStyle(color: kPxMuted, fontSize: 10)),
                    ],
                  ),
                ),
                if (loc != null) const Icon(Icons.chevron_right, color: kPxMuted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PartnerSosDetailScreen(alertId: id)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6A6A6A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View alert', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () async {
                      final err = await Px.resolveSos(id);
                      if (!mounted) return;
                      pxToast(context, err ?? 'Alert marked as resolved', ok: err == null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Mark resolved', style: TextStyle(color: Colors.black, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _person(String label, String name, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: kPxMuted, fontSize: 9, letterSpacing: 0.4)),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(phone, style: const TextStyle(color: kPxMuted, fontSize: 10)),
      ],
    );
  }
}

String _who(PxMap s, String role) {
  final n = Px.text(s['${role}_name']);
  return n.isEmpty ? (role == 'driver' ? 'Driver' : 'Passenger') : n;
}

String _when(PxMap s) {
  final d = Px.date(s['created_at']);
  return d == null ? '' : DateFormat('d MMM yyyy · h:mm a').format(d);
}

class PartnerSosBanner extends StatelessWidget {
  final String alertId;
  final PxMap data;

  const PartnerSosBanner({super.key, required this.alertId, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartnerSosDetailScreen(alertId: alertId)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withAlpha(90), blurRadius: 14)],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SOS from ${_who(data, 'passenger')}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const Text('Tap to respond', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class PartnerSosDetailScreen extends StatefulWidget {
  final String alertId;

  const PartnerSosDetailScreen({super.key, required this.alertId});

  @override
  State<PartnerSosDetailScreen> createState() => _PartnerSosDetailScreenState();
}

class _PartnerSosDetailScreenState extends State<PartnerSosDetailScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _doc =
      Px.db.collection('sos_alerts').doc(widget.alertId).snapshots();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot<PxMap>>(
        stream: _doc,
        builder: (context, snap) {
          if (!snap.hasData) return const PxLoading();
          final s = snap.data!.data();
          if (s == null) return const PxEmpty('Alert not found');
          final active = Px.sosStatus(s) == 'active';
          final loc = Px.point(s['location']);
          final raised = Px.date(s['created_at']);
          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFB91C1C),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(color: Color(0xFF8E1414), shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                active ? 'SOS · ACTIVE' : 'SOS · RESOLVED',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1),
                              ),
                            ),
                            const SizedBox(width: 32),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withAlpha(70), width: 6),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text('Passenger needs help',
                            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (raised != null) 'Raised ${DateFormat('d MMM, h:mm a').format(raised)}',
                            if (Px.text(s['driver_name']).isNotEmpty) 'ride with ${Px.text(s['driver_name'])}',
                          ].join(' · '),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _contact('Passenger', _who(s, 'passenger'), Px.text(s['passenger_phone'])),
                          const Divider(color: kPxBorder, height: 1),
                          _contact('Driver', _who(s, 'driver'), Px.text(s['driver_phone'])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    PxCard(
                      onTap: loc == null ? null : () => pxOpenMap(context, loc.lat, loc.lng),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: kPxRed.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.location_on_outlined, color: kPxRed, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Current Location', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text(
                                  loc == null ? 'Location not shared' : '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
                                  style: const TextStyle(color: kPxMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (loc != null) const Icon(Icons.chevron_right, color: kPxMuted, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => pxCall(context, '15'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPxSurface2,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Call emergency services (15)',
                              style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    setState(() => _busy = true);
                                    final err = await Px.resolveSos(widget.alertId);
                                    if (!mounted) return;
                                    setState(() => _busy = false);
                                    pxToast(this.context, err ?? 'Alert marked as resolved', ok: err == null);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Mark as resolved', style: TextStyle(color: Colors.black, fontSize: 14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _contact(String label, String name, String phone) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PxLetterAvatar(name: name, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(color: kPxMuted, fontSize: 9, letterSpacing: 0.4)),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(phone, style: const TextStyle(color: kPxMuted, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => pxCall(context, phone),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: kPxGreen, shape: BoxShape.circle),
              child: const Icon(Icons.call_outlined, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

