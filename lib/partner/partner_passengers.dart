import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../vendor/vendor_passenger_requests_screen.dart' show VendorPassengerRequests;
import 'partner_data.dart';
import 'partner_drivers.dart';
import 'partner_links.dart';
import 'partner_ui.dart';

class PartnerPassengersPage extends StatefulWidget {
  final int initialTab;

  const PartnerPassengersPage({super.key, this.initialTab = 0});

  @override
  State<PartnerPassengersPage> createState() => _PartnerPassengersPageState();
}

class _PartnerPassengersPageState extends State<PartnerPassengersPage> {
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  late int _tab = widget.initialTab.clamp(0, 2);
  String _q = '';

  static const _tabs = ['All', 'Request', 'Assigned'];

  bool _inTab(PxMap r) {
    switch (_tab) {
      case 1:
        return Px.rideIsRequest(r);
      case 2:
        return Px.rideIsAssigned(r);
      default:
        return Px.rideIsRequest(r) || Px.rideIsAssigned(r);
    }
  }

  bool _matches(PxMap r) {
    if (_q.isEmpty) return true;
    final hay = [
      VendorPassengerRequests.passengerName(r),
      Px.address(r['pickup']),
      Px.address(r['destination']),
      Px.text(r['driver_name']),
    ].join(' ').toLowerCase();
    return hay.contains(_q);
  }

  void _export(List<PxDoc> docs) {
    final lines = <String>['Passenger,Plan,Pickup,Destination,Driver,Status'];
    for (final doc in docs) {
      final r = doc.data();
      lines.add([
        VendorPassengerRequests.passengerName(r),
        Px.plan(r),
        Px.address(r['pickup']),
        Px.address(r['destination']),
        Px.text(r['driver_name']),
        Px.rideIsRequest(r) ? 'Pending' : 'Active',
      ].map((e) => '"${e.replaceAll('"', "'")}"').join(','));
    }
    pxCopy(context, lines.join('\n'), 'Passenger list copied');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _rides,
      builder: (context, snap) {
        final all = pxSortedBy(snap.data?.docs ?? const <PxDoc>[], pxRideRequestedAt);
        final list = all.where((d) => _inTab(d.data()) && _matches(d.data())).toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            PxPageTitle('Passenger Management', onExport: () => _export(list)),
            PxSegmentTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: 14),
            PxSearchField(hint: 'Search passenger', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
            const SizedBox(height: 14),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const PxLoading()
            else if (list.isEmpty)
              const PxEmpty('No passengers here yet', icon: Icons.airline_seat_recline_normal)
            else
              for (final r in list) ...[
                PartnerPassengerCard(rideId: r.id, ride: r.data()),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class PartnerPassengerCard extends StatelessWidget {
  final String rideId;
  final PxMap ride;

  const PartnerPassengerCard({super.key, required this.rideId, required this.ride});

  @override
  Widget build(BuildContext context) {
    final name = VendorPassengerRequests.passengerName(ride);
    final route = '${Px.shortAddress(ride['pickup'])} → ${Px.shortAddress(ride['destination'])}';
    final active = Px.rideDriverAccepted(ride);
    final canAssign = VendorPassengerRequests.canAssign(ride);

    void open() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartnerRequestDetailsScreen(rideId: rideId)),
        );

    return PxCard(
      onTap: open,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PxAvatar(name: name, size: 36, tint: kPxGreen),
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
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                        PxChip.plan(Px.plan(ride)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(route, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                    Text(Px.rideSchedule(ride),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                  ],
                ),
              ),
              PxChip.status(active ? 'active' : 'pending'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PxSmallButton(
                'Assign',
                kPxGreen,
                onTap: canAssign
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PartnerAssignDriverScreen(rideId: rideId, ride: ride)),
                        )
                    : null,
              ),
              const SizedBox(width: 8),
              PxSmallButton('View', kPxBlue, onTap: open),
            ],
          ),
        ],
      ),
    );
  }
}

class PartnerRequestDetailsScreen extends StatefulWidget {
  final String rideId;

  const PartnerRequestDetailsScreen({super.key, required this.rideId});

  @override
  State<PartnerRequestDetailsScreen> createState() => _PartnerRequestDetailsScreenState();
}

class _PartnerRequestDetailsScreenState extends State<PartnerRequestDetailsScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _ride =
      Px.db.collection('active_rides').doc(widget.rideId).snapshots();
  Future<DocumentSnapshot<PxMap>>? _user;
  String _userId = '';

  Future<DocumentSnapshot<PxMap>>? _userFor(String id) {
    if (id.isEmpty) return null;
    if (id != _userId) {
      _userId = id;
      _user = Px.db.collection('users').doc(id).get();
    }
    return _user;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<PxMap>>(
      stream: _ride,
      builder: (context, snap) {
        final r = snap.data?.data();
        final assigned = r != null && Px.rideIsAssigned(r);
        return Scaffold(
          backgroundColor: kPxBg,
          appBar: pxBackAppBar(context, assigned ? 'View Details' : 'Request Details'),
          body: !snap.hasData
              ? const PxLoading()
              : r == null
                  ? const PxEmpty('Request not found')
                  : FutureBuilder<DocumentSnapshot<PxMap>>(
                      future: _userFor(Px.text(r['passengerId'])),
                      builder: (context, userSnap) => _content(r, userSnap.data?.data() ?? const {}),
                    ),
        );
      },
    );
  }

  Widget _content(PxMap r, PxMap user) {
    final name = VendorPassengerRequests.passengerName(r);
    final assigned = Px.rideIsAssigned(r);
    final canAssign = VendorPassengerRequests.canAssign(r);
    final rating = Px.number(user['average_rating']).toDouble();
    final rides = Px.number(user['total_rides']).toInt();
    final phone = Px.text(user['phone_number']).isNotEmpty ? Px.text(user['phone_number']) : Px.text(r['passenger_phone']);
    final fare = Px.map(r['fare']);
    final vehicleType = Px.text(r['vehicle_type']).isNotEmpty ? Px.text(r['vehicle_type']) : Px.text(fare['vehicle_type']);
    final start = Px.date(r['plan_start_date']) ?? Px.date(r['scheduled_at']);
    final returnTime = Px.text(r['return_daily_time']).isNotEmpty ? Px.text(r['return_daily_time']) : Px.text(r['return_time']);
    final departure = Px.text(r['pickup_daily_time']).isNotEmpty
        ? Px.text(r['pickup_daily_time'])
        : (Px.date(r['scheduled_at']) == null ? '' : TimeOfDay.fromDateTime(Px.date(r['scheduled_at'])!).format(context));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            children: [
              Center(child: PxLetterAvatar(name: name, size: 58)),
              const SizedBox(height: 10),
              Center(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600))),
              const SizedBox(height: 4),
              Center(
                child: Text('★ ${rating.toStringAsFixed(1)} · $rides ride${rides == 1 ? '' : 's'}',
                    style: const TextStyle(color: kPxMuted, fontSize: 11)),
              ),
              if (assigned) ...[
                const SizedBox(height: 14),
                _driverBanner(r),
              ] else if (VendorPassengerRequests.isAwaitingDriver(r) && Px.rideHasDriver(r)) ...[
                const SizedBox(height: 14),
                PxCard(
                  color: kPxAmber.withAlpha(30),
                  child: Text(
                    'Waiting for ${Px.text(r['driver_name']).isEmpty ? 'the driver' : Px.text(r['driver_name'])} to accept',
                    style: const TextStyle(color: kPxAmber, fontSize: 12),
                  ),
                ),
              ],
              const PxSectionLabel('Basic information'),
              PxInfoTable(
                [
                  MapEntry('Phone', phone),
                  MapEntry('Email', Px.text(user['email'])),
                  MapEntry('Gender', Px.text(user['gender'])),
                ],
                valueColors: const {'Phone': kPxGreen},
              ),
              const PxSectionLabel('Request details'),
              PxInfoTable([
                MapEntry('Pickup', Px.address(r['pickup'])),
                MapEntry('Destination', Px.address(r['destination'])),
                MapEntry('Departure', departure),
                MapEntry('Return time', returnTime),
                MapEntry('Ride start date', Px.longDate(start)),
                MapEntry('Subscription', Px.plan(r)),
                if (!assigned) MapEntry('Requested On', Px.dayMonthYear(pxRideRequestedAt(r))),
                MapEntry('Vehicle type', vehicleType),
                MapEntry('Preferences', VendorPassengerRequests.preferencesLabel(r)),
              ]),
            ],
          ),
        ),
        if (!assigned && canAssign)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: PxButton(
                label: 'Assign Driver',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PartnerAssignDriverScreen(rideId: widget.rideId, ride: r)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _driverBanner(PxMap r) {
    final driver = Px.text(r['driver_name']).isEmpty ? 'Driver' : Px.text(r['driver_name']);
    final plate = Px.text(r['driver_plate']);
    final driverId = Px.text(r['driverId']);
    return PxCard(
      color: const Color(0xFF0F2418),
      onTap: driverId.isEmpty
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartnerDriverDetailsScreen(driverId: driverId)),
              ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: kPxGreen.withAlpha(40), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check, color: kPxGreen, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Driver assigned', style: TextStyle(color: kPxGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                Text([driver, plate].where((e) => e.isNotEmpty).join(' · '),
                    style: const TextStyle(color: kPxGreen, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

class PartnerAssignDriverScreen extends StatefulWidget {
  final String rideId;
  final PxMap ride;

  const PartnerAssignDriverScreen({super.key, required this.rideId, required this.ride});

  @override
  State<PartnerAssignDriverScreen> createState() => _PartnerAssignDriverScreenState();
}

class _PartnerAssignDriverScreenState extends State<PartnerAssignDriverScreen> {
  late final Stream<QuerySnapshot<PxMap>> _drivers = PxStreams.drivers();
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  String? _selected;
  bool _saving = false;

  Future<void> _assign(List<_RankedDriver> ranked) async {
    final pick = ranked.where((e) => e.id == _selected).firstOrNull;
    if (pick == null) {
      pxToast(context, 'Please select a driver', ok: false);
      return;
    }
    final ok = await pxConfirmAssignment(
      context,
      "You're about to assign this Driver",
      PartnerDriverPickTile(
        driver: pick.data,
        driverName: pick.name,
        seatsLeft: pick.seatsLeft,
        match: pick.match,
        showRadio: false,
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final err = await VendorPassengerRequests.assignDriver(widget.rideId, pick.id, pick.data);
    if (!mounted) return;
    setState(() => _saving = false);
    pxToast(context, err ?? '${pick.name} assigned. Waiting for the driver to accept.', ok: err == null);
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final name = VendorPassengerRequests.passengerName(r);
    final requested = pxRideRequestedAt(r);
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Assign Driver'),
      body: StreamBuilder<QuerySnapshot<PxMap>>(
        stream: _drivers,
        builder: (context, snap) {
          return StreamBuilder<QuerySnapshot<PxMap>>(
            stream: _rides,
            builder: (context, rideSnap) {
              final rides = rideSnap.data?.docs ?? const <PxDoc>[];
              final ranked = <_RankedDriver>[];
              for (final d in snap.data?.docs ?? const <PxDoc>[]) {
                if (Px.approval(d.data()) != 'approved') continue;
                final left = Px.seatCapacity(d.data()) - pxSeatsUsed(d.id, rides);
                if (left <= 0) continue;
                ranked.add(_RankedDriver(
                  d.id,
                  d.data(),
                  Px.text(d.data()['full_name']).isEmpty ? 'Driver' : Px.text(d.data()['full_name']),
                  left,
                  Px.matchPercent(d.data(), r),
                ));
              }
              ranked.sort((a, b) => b.match.compareTo(a.match));
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        PxCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PxAvatar(name: name, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text('${Px.shortAddress(r['pickup'])} → ${Px.shortAddress(r['destination'])}',
                                        style: const TextStyle(color: kPxMuted, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, color: kPxMuted, size: 11),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(Px.rideSchedule(r),
                                              style: const TextStyle(color: kPxMuted, fontSize: 10)),
                                        ),
                                      ],
                                    ),
                                    if (requested != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Requested on ${Px.dayMonthYear(requested)}',
                                          style: const TextStyle(color: kPxMuted, fontSize: 9)),
                                    ],
                                  ],
                                ),
                              ),
                              PxChip(Px.plan(r), kPxGreen),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 18, 0, 10),
                          child: Text('Select Driver', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        if (!snap.hasData)
                          const PxLoading()
                        else if (ranked.isEmpty)
                          const PxEmpty('No approved drivers with free seats', icon: Icons.directions_car_outlined)
                        else
                          for (final e in ranked) ...[
                            PartnerDriverPickTile(
                              driver: e.data,
                              driverName: e.name,
                              seatsLeft: e.seatsLeft,
                              match: e.match,
                              selected: _selected == e.id,
                              onTap: () => setState(() => _selected = e.id),
                            ),
                            const SizedBox(height: 8),
                          ],
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                      child: PxButton(label: 'Assign', loading: _saving, onPressed: () => _assign(ranked)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _RankedDriver {
  final String id;
  final PxMap data;
  final String name;
  final int seatsLeft;
  final int match;

  _RankedDriver(this.id, this.data, this.name, this.seatsLeft, this.match);
}
