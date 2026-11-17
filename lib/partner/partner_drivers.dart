import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../shared/ride_visibility.dart' show readableTripId;
import '../vendor/vendor_passenger_requests_screen.dart' show VendorPassengerRequests;
import 'partner_chat.dart';
import 'partner_data.dart';
import 'partner_links.dart';
import 'partner_passengers.dart';
import 'partner_ui.dart';

class PartnerDriversPage extends StatefulWidget {
  final int initialTab;

  const PartnerDriversPage({super.key, this.initialTab = 0});

  @override
  State<PartnerDriversPage> createState() => _PartnerDriversPageState();
}

class _PartnerDriversPageState extends State<PartnerDriversPage> {
  late final Stream<QuerySnapshot<PxMap>> _drivers = PxStreams.drivers();
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  late int _tab = widget.initialTab.clamp(0, 3);
  String _q = '';

  static const _tabs = ['All', 'Active', 'Pending', 'Rejected'];

  bool _inTab(PxMap d) {
    final s = Px.approval(d);
    switch (_tab) {
      case 1:
        return s == 'approved';
      case 2:
        return s == 'pending';
      case 3:
        return s == 'rejected';
      default:
        return true;
    }
  }

  bool _matches(PxMap d) {
    if (_q.isEmpty) return true;
    final hay = [
      Px.text(d['full_name']),
      Px.text(d['phone_number']),
      Px.text(Px.vehicle(d)['plate_number']),
      Px.vehicleName(d),
    ].join(' ').toLowerCase();
    return hay.contains(_q);
  }

  void _export(List<PxDoc> docs) {
    final lines = <String>['Name,Phone,Status,Vehicle,Plate'];
    for (final doc in docs) {
      final d = doc.data();
      lines.add([
        Px.text(d['full_name']),
        Px.text(d['phone_number']),
        Px.approval(d),
        Px.vehicleName(d),
        Px.text(Px.vehicle(d)['plate_number']),
      ].map((e) => '"${e.replaceAll('"', "'")}"').join(','));
    }
    pxCopy(context, lines.join('\n'), 'Driver list copied');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<PxMap>>(
      stream: _drivers,
      builder: (context, snap) {
        return StreamBuilder<QuerySnapshot<PxMap>>(
          stream: _rides,
          builder: (context, rideSnap) {
            final all = pxSortedBy(snap.data?.docs ?? const <PxDoc>[],
                (d) => Px.date(d['vendor_requested_at']) ?? Px.date(d['created_at']));
            final rides = rideSnap.data?.docs ?? const <PxDoc>[];
            final list = all.where((d) => _inTab(d.data()) && _matches(d.data())).toList();
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                PxPageTitle('Driver Management', onExport: () => _export(list)),
                PxSegmentTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
                const SizedBox(height: 14),
                PxSearchField(hint: 'Search drivers', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
                const SizedBox(height: 14),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const PxLoading()
                else if (list.isEmpty)
                  const PxEmpty('No drivers here yet', icon: Icons.directions_car_outlined)
                else
                  for (final d in list) ...[
                    PartnerDriverCard(driverId: d.id, data: d.data(), rides: rides),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

int pxSeatsUsed(String driverId, List<PxDoc> rides) =>
    rides.where((r) => Px.text(r.data()['driverId']) == driverId && !Px.rideClosed(r.data())).length;

class PartnerDriverCard extends StatelessWidget {
  final String driverId;
  final PxMap data;
  final List<PxDoc> rides;

  const PartnerDriverCard({super.key, required this.driverId, required this.data, required this.rides});

  @override
  Widget build(BuildContext context) {
    final status = Px.approval(data);
    final used = pxSeatsUsed(driverId, rides);
    final cap = Px.seatCapacity(data);
    final full = used >= cap;
    final applied = Px.date(data['vendor_requested_at']) ?? Px.date(data['created_at']);
    final name = Px.text(data['full_name']).isEmpty ? 'Driver' : Px.text(data['full_name']);

    void open() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartnerDriverDetailsScreen(driverId: driverId)),
        );

    VoidCallback? assign;
    if (status == 'approved' && !full) {
      assign = () => pxOpenAssignPassenger(context, driverId, data);
    } else if (status == 'pending') {
      assign = open;
    }

    return PxCard(
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PxAvatar(name: name, imageUrl: Px.text(data['profile_image_url']), size: 38, photoStyle: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(Px.driverRoute(data), style: const TextStyle(color: kPxMuted, fontSize: 10)),
                    Text(Px.driverSchedule(data), style: const TextStyle(color: kPxMuted, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PxChip.status(status == 'approved' ? 'active' : status),
                  if (status == 'pending' && applied != null) ...[
                    const SizedBox(height: 4),
                    Text('Applied on ${Px.dayMonthYear(applied)}',
                        style: const TextStyle(color: kPxGreen, fontSize: 8)),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _infoBox(Icons.directions_car, 'Vehicle', Px.vehicleName(data).isEmpty ? '—' : Px.vehicleName(data))),
              const SizedBox(width: 8),
              Expanded(
                child: _infoBox(Icons.airline_seat_recline_normal, 'Seats', '$used/$cap',
                    valueColor: full ? kPxRed : Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PxSmallButton('Assign', kPxGreen, onTap: assign),
              const SizedBox(width: 8),
              PxSmallButton('View', kPxBlue, onTap: open),
              if (status == 'pending') ...[
                const SizedBox(width: 8),
                PxSmallButton('Reject', kPxRed, onTap: () => pxRejectDriverDialog(context, driverId, name)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _infoBox(IconData icon, String label, String value, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPxBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: kPxGreen.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: kPxGreen, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> pxRejectDriverDialog(BuildContext context, String driverId, String name) async {
  final reason = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withAlpha(160),
    builder: (ctx) => Dialog(
      backgroundColor: kPxSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject $name?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'They will not be able to join your fleet. You can add a reason for them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB5B5B5), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reason,
              cursorColor: kPxGreen,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Reason (optional)',
                hintStyle: const TextStyle(color: kPxMuted, fontSize: 12),
                filled: true,
                fillColor: kPxSurface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: kPxGreen, fontSize: 15)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Reject', style: TextStyle(color: kPxRed, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  final text = reason.text.trim();
  reason.dispose();
  if (ok != true || !context.mounted) return;
  final err = await Px.rejectDriver(driverId, text);
  if (!context.mounted) return;
  pxToast(context, err ?? '$name rejected', ok: err == null);
}

class PartnerDriverDetailsScreen extends StatefulWidget {
  final String driverId;

  const PartnerDriverDetailsScreen({super.key, required this.driverId});

  @override
  State<PartnerDriverDetailsScreen> createState() => _PartnerDriverDetailsScreenState();
}

class _PartnerDriverDetailsScreenState extends State<PartnerDriverDetailsScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _driver =
      Px.db.collection('drivers').doc(widget.driverId).snapshots();
  late final Stream<QuerySnapshot<PxMap>> _rides = PxStreams.rides();
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    final err = await Px.approveDriver(widget.driverId);
    if (!mounted) return;
    setState(() => _busy = false);
    pxToast(context, err ?? 'Driver approved', ok: err == null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Driver Details'),
      body: StreamBuilder<DocumentSnapshot<PxMap>>(
        stream: _driver,
        builder: (context, snap) {
          if (!snap.hasData) return const PxLoading();
          final d = snap.data!.data();
          if (d == null) return const PxEmpty('Driver not found');
          return StreamBuilder<QuerySnapshot<PxMap>>(
            stream: _rides,
            builder: (context, rideSnap) {
              final rides = rideSnap.data?.docs ?? const <PxDoc>[];
              return _content(d, rides);
            },
          );
        },
      ),
    );
  }

  Widget _content(PxMap d, List<PxDoc> rides) {
    final name = Px.text(d['full_name']).isEmpty ? 'Driver' : Px.text(d['full_name']);
    final status = Px.approval(d);
    final a = Px.availability(d);
    final v = Px.vehicle(d);
    final docs = Px.map(d['documents']);
    final pm = Px.map(d['payment_methods']);
    final active = Px.text(pm['active']);
    final details = Px.map(pm[active]);
    final assigned = rides
        .where((r) => Px.text(r.data()['driverId']) == widget.driverId && !Px.rideClosed(r.data()))
        .toList();
    final used = assigned.length;
    final cap = Px.seatCapacity(d);
    final rating = Px.number(d['average_rating']).toDouble();
    final trips = Px.number(d['total_rides']).toInt();
    final docUploaded = Px.date(d['documents_submitted_at']) ?? Px.date(d['created_at']);
    final vehicleText = [
      Px.vehicleName(d),
      if (Px.text(v['color']).isNotEmpty) '(${Px.text(v['color'])})',
    ].where((e) => e.isNotEmpty).join(' ');
    final scheduleDays = Px.driverSchedule(d).split(' | ').first;
    final scheduleTime = Px.text(a['working_hours_from']);

    final docItems = <MapEntry<String, String>>[
      for (final k in const ['license', 'cnic', 'registration', 'insurance'])
        if (Px.text(docs['${k}_url']).isNotEmpty)
          MapEntry(k == 'cnic' ? 'CNIC' : '${k[0].toUpperCase()}${k.substring(1)}', Px.text(docs['${k}_url'])),
    ];

    Widget? bottom;
    if (status == 'pending') {
      bottom = Row(
        children: [
          Expanded(
            flex: 2,
            child: PxButton.dark(
              label: 'Reject',
              textColor: kPxRed,
              onPressed: _busy ? null : () => pxRejectDriverDialog(context, widget.driverId, name),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: PxButton(label: 'Approve driver', loading: _busy, onPressed: _approve)),
        ],
      );
    } else if (status == 'approved') {
      bottom = Row(
        children: [
          Expanded(
            child: PxButton.dark(
              label: 'Message',
              icon: Icons.chat_bubble_outline,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerDriverChatScreen(driverId: widget.driverId, driverName: name),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PxButton(
              label: 'Assign passenger',
              onPressed: used >= cap ? null : () => pxOpenAssignPassenger(context, widget.driverId, d),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            children: [
              Center(child: PxLetterAvatar(name: name, size: 58)),
              const SizedBox(height: 10),
              Center(
                child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PxChip.status(status, key: null),
                  const SizedBox(width: 8),
                  Text('★ ${rating.toStringAsFixed(1)} · $trips trip${trips == 1 ? '' : 's'}',
                      style: const TextStyle(color: kPxMuted, fontSize: 11)),
                ],
              ),
              const PxSectionLabel('Route'),
              PxCard(
                child: PxRoute(
                  from: Px.text(a['preferred_route_from']),
                  to: Px.text(a['preferred_route_to']),
                  endColor: status == 'approved' ? kPxGreen : kPxOrange,
                ),
              ),
              const PxSectionLabel('Basic information'),
              PxInfoTable(
                [
                  MapEntry('Phone', Px.text(d['phone_number'])),
                  MapEntry('Email', Px.text(d['email'])),
                  MapEntry('Gender', Px.text(d['gender'])),
                  MapEntry('CNIC', Px.text(d['cnic'])),
                  MapEntry('Licence no.', Px.text(d['license_number'])),
                  MapEntry('Vehicle', vehicleText),
                  MapEntry('Schedule', [scheduleDays, scheduleTime].where((e) => e.isNotEmpty).join(' · ')),
                  MapEntry('Seats available', '${(cap - used).clamp(0, cap)}/$cap'),
                  MapEntry('Joined', Px.longDate(Px.date(d['created_at']))),
                ],
                valueColors: const {'Phone': kPxGreen},
              ),
              const PxSectionLabel('Documents'),
              if (docItems.isEmpty)
                const PxCard(child: Text('No documents uploaded', style: TextStyle(color: kPxMuted, fontSize: 13)))
              else
                Container(
                  decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (final doc in docItems)
                        ListTile(
                          dense: true,
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: kPxSurface2, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.description_outlined, color: Colors.white, size: 18),
                          ),
                          title: Text('${doc.key}.jpg', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(
                            docUploaded == null ? 'Uploaded' : 'Uploaded ${Px.longDate(docUploaded)}',
                            style: const TextStyle(color: kPxMuted, fontSize: 11),
                          ),
                          trailing: IconButton(
                            onPressed: () => pxOpenUrl(context, doc.value),
                            icon: const Icon(Icons.file_download_outlined, color: kPxGreen, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              const PxSectionLabel('Payment details'),
              PxInfoTable([
                MapEntry('Method', active.isEmpty ? '' : Px.methodLabel(active)),
                MapEntry('Account title', Px.text(details['account_title'])),
                MapEntry('Account number', Px.text(details['account_number'])),
              ]),
              if (status == 'approved') ...[
                PxSectionLabel('Assigned passengers (${assigned.length})'),
                if (assigned.isEmpty)
                  const PxCard(child: Text('No passengers assigned yet', style: TextStyle(color: kPxMuted, fontSize: 13)))
                else
                  Container(
                    decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        for (final r in assigned)
                          ListTile(
                            dense: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PartnerRequestDetailsScreen(rideId: r.id)),
                            ),
                            leading: PxLetterAvatar(name: VendorPassengerRequests.passengerName(r.data())),
                            title: Text(VendorPassengerRequests.passengerName(r.data()),
                                style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(
                              [Px.plan(r.data()), 'Trip ${readableTripId(r.data(), r.id)}']
                                  .where((e) => e.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(color: kPxMuted, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: kPxMuted, size: 18),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (bottom != null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: const BoxDecoration(
              color: kPxBg,
              border: Border(top: BorderSide(color: kPxBorder)),
            ),
            child: SafeArea(top: false, child: bottom),
          ),
      ],
    );
  }
}

Future<void> pxOpenAssignPassenger(BuildContext context, String driverId, PxMap driver) async {
  List<PxDoc> requests = const [];
  try {
    final snap = await Px.db.collection('active_rides').where('vendorId', isEqualTo: Px.uid).limit(400).get();
    requests = snap.docs.where((r) => Px.rideIsRequest(r.data())).toList();
  } catch (_) {}
  if (!context.mounted) return;
  if (requests.isEmpty) {
    await showPxSheet<void>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PxSheetHandle(),
            const SizedBox(height: 22),
            const Text('Recommended Passengers',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Pending requests that match this driver route',
                style: TextStyle(color: kPxMuted, fontSize: 12)),
            const SizedBox(height: 26),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: Color(0xFFB5B5B5), size: 24),
            ),
            const SizedBox(height: 14),
            const Text(
              'There are no pending passenger requests to\nrecommend right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB5B5B5), fontSize: 12),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E2E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PartnerAssignPassengerScreen(driverId: driverId, driver: driver, requests: requests),
    ),
  );
}

Future<bool> pxConfirmAssignment(BuildContext context, String subtitle, Widget card) async {
  final ok = await showPxSheet<bool>(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PxSheetHandle(),
          const SizedBox(height: 18),
          const PxCheckBadge(size: 50),
          const SizedBox(height: 12),
          const Text('Confirm Assignment',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kPxMuted, fontSize: 12)),
          const SizedBox(height: 14),
          card,
          const SizedBox(height: 12),
          PxButton(label: 'Confirm & Assign', onPressed: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 10),
          PxButton(label: 'Cancel', outlined: true, onPressed: () => Navigator.pop(ctx, false)),
        ],
      ),
    ),
  );
  return ok == true;
}

class PartnerPassengerPickTile extends StatelessWidget {
  final PxMap ride;
  final int match;
  final bool selected;
  final VoidCallback? onTap;
  final bool showRadio;

  const PartnerPassengerPickTile({
    super.key,
    required this.ride,
    required this.match,
    this.selected = false,
    this.onTap,
    this.showRadio = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = VendorPassengerRequests.passengerName(ride);
    final route = '${Px.shortAddress(ride['pickup'])} → ${Px.shortAddress(ride['destination'])}';
    return PxCard(
      onTap: onTap,
      color: selected ? const Color(0xFF0F2418) : kPxSurface,
      borderColor: selected ? kPxGreen : null,
      child: Row(
        children: [
          PxAvatar(name: name, size: 36),
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
                Text(route, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: kPxMuted, size: 11),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(Px.rideSchedule(ride),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PxMatchBadge(match),
          if (showRadio) ...[
            const SizedBox(width: 12),
            PxRadio(selected),
          ],
        ],
      ),
    );
  }
}

class PartnerAssignPassengerScreen extends StatefulWidget {
  final String driverId;
  final PxMap driver;
  final List<PxDoc> requests;

  const PartnerAssignPassengerScreen({
    super.key,
    required this.driverId,
    required this.driver,
    required this.requests,
  });

  @override
  State<PartnerAssignPassengerScreen> createState() => _PartnerAssignPassengerScreenState();
}

class _PartnerAssignPassengerScreenState extends State<PartnerAssignPassengerScreen> {
  String? _selected;
  bool _saving = false;

  late final List<MapEntry<PxDoc, int>> _ranked = widget.requests
      .map((r) => MapEntry(r, Px.matchPercent(widget.driver, r.data())))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  Future<void> _assign() async {
    final pick = _ranked.where((e) => e.key.id == _selected).firstOrNull;
    if (pick == null) {
      pxToast(context, 'Please select a passenger', ok: false);
      return;
    }
    final ok = await pxConfirmAssignment(
      context,
      "You're about to assign this passenger",
      PartnerPassengerPickTile(ride: pick.key.data(), match: pick.value, showRadio: false),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final err = await VendorPassengerRequests.assignDriver(pick.key.id, widget.driverId, widget.driver);
    if (!mounted) return;
    setState(() => _saving = false);
    pxToast(context, err ?? 'Passenger assigned. Waiting for the driver to accept.', ok: err == null);
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;
    final name = Px.text(d['full_name']).isEmpty ? 'Driver' : Px.text(d['full_name']);
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Assign Passenger'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                PartnerDriverPickTile(driver: d, driverName: name, seatsLeft: null, showRadio: false),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 18, 0, 10),
                  child: Text('Select Passenger', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                for (final e in _ranked) ...[
                  PartnerPassengerPickTile(
                    ride: e.key.data(),
                    match: e.value,
                    selected: _selected == e.key.id,
                    onTap: () => setState(() => _selected = e.key.id),
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
              child: PxButton(label: 'Assign', loading: _saving, onPressed: _assign),
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerDriverPickTile extends StatelessWidget {
  final PxMap driver;
  final String driverName;
  final int? seatsLeft;
  final int? match;
  final bool selected;
  final bool showRadio;
  final VoidCallback? onTap;

  const PartnerDriverPickTile({
    super.key,
    required this.driver,
    required this.driverName,
    required this.seatsLeft,
    this.match,
    this.selected = false,
    this.showRadio = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = Px.number(driver['average_rating']).toDouble();
    final left = seatsLeft ?? Px.seatCapacity(driver);
    return PxCard(
      onTap: onTap,
      color: selected ? const Color(0xFF0F2418) : kPxSurface,
      borderColor: selected ? kPxGreen : null,
      child: Row(
        children: [
          PxAvatar(name: driverName, imageUrl: Px.text(driver['profile_image_url']), size: 40, photoStyle: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: kPxAmber, size: 12),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(color: kPxMuted, fontSize: 9)),
                  ],
                ),
                Text(Px.driverRoute(driver),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                Text('$left Seat${left == 1 ? '' : 's'} Available', style: const TextStyle(color: kPxGreen, fontSize: 9)),
              ],
            ),
          ),
          if (match != null) ...[
            const SizedBox(width: 8),
            PxMatchBadge(match!),
          ],
          if (showRadio) ...[
            const SizedBox(width: 12),
            PxRadio(selected),
          ],
        ],
      ),
    );
  }
}
