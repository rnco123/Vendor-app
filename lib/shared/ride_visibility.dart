const Set<String> kAwaitingDriverPhases = {
  'driver_assigned',
  'awaiting_driver_acceptance',
};

const Set<String> _approvedPhases = {
  'accepted',
  'en_route_pickup',
  'arrived_at_pickup',
  'en_route_dropoff',
  'arrived_at_dropoff',
  'in_progress',
  'to_destination',
  'completed',
};

const Set<String> _unapprovedStatuses = {
  'requested',
  'searching',
  'pending',
};

bool rideApprovedForDriver(Map<String, dynamic> ride) {
  final phase = (ride['current_phase'] as String? ?? '')
      .toLowerCase()
      .replaceAll(' ', '_')
      .trim();
  final status = (ride['status'] as String? ?? '')
      .toLowerCase()
      .replaceAll(' ', '_')
      .trim();
  if (phase == 'waiting_for_vendor') return false;
  if (kAwaitingDriverPhases.contains(phase)) return false;
  if (status == 'assigned_to_driver' && !_approvedPhases.contains(phase)) {
    return false;
  }
  if (_unapprovedStatuses.contains(status) &&
      !_approvedPhases.contains(phase)) {
    return false;
  }
  return true;
}

String _rideNorm(dynamic v) =>
    (v == null ? '' : v.toString()).toLowerCase().replaceAll(' ', '_').trim();

bool rideAwaitingDriverAcceptance(Map<String, dynamic> ride) {
  const closed = {'cancelled', 'canceled', 'declined', 'completed', 'rejected'};
  final status = _rideNorm(ride['status']);
  if (closed.contains(status)) return false;
  final phase = _rideNorm(ride['current_phase']);
  if (kAwaitingDriverPhases.contains(phase)) return true;
  return status == 'assigned_to_driver' && !_approvedPhases.contains(phase);
}

bool rideAwaitingMatchAtVendor(Map<String, dynamic> ride) {
  return _rideNorm(ride['status']) == 'requested' &&
      _rideNorm(ride['current_phase']) == 'waiting_for_vendor' &&
      _rideNorm(ride['sent_to_vendor_reason']) == 'no_driver_match' &&
      _rideNorm(ride['driverId']).isEmpty;
}

bool rideNeedsPlanChoice(Map<String, dynamic> ride) {
  if (_rideNorm(ride['ride_type']) == 'quick_pool') return false;
  if (ride['transfer_payment'] is Map || ride['weekly_plan'] is Map) {
    return false;
  }
  const paid = {'completed', 'paid', 'approved', 'proof_submitted'};
  if (paid.contains(_rideNorm(ride['payment_status']))) return false;
  final plan = ride['subscription_plan'];
  return !(plan is Map && _rideNorm(plan['type']).isNotEmpty);
}

String readableTripId(Map<String, dynamic> ride, String docId) {
  final code = ride['trip_code'] ?? ride['trip_id'] ?? ride['display_trip_id'];
  if (code != null && code.toString().trim().isNotEmpty) {
    return code.toString().trim();
  }
  var hash = 0;
  for (final unit in docId.codeUnits) {
    hash = (hash * 31 + unit) % 100000;
  }
  return hash.toString().padLeft(5, '0');
}
