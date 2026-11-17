import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/profile_image_service.dart';
import '../vendor/vendor_ui.dart';
import 'partner_chat.dart';
import 'partner_data.dart';
import 'partner_shell.dart';
import 'partner_ui.dart';

class PartnerSettingsPage extends StatefulWidget {
  const PartnerSettingsPage({super.key});

  @override
  State<PartnerSettingsPage> createState() => _PartnerSettingsPageState();
}

class _PartnerSettingsPageState extends State<PartnerSettingsPage> {
  late final Stream<DocumentSnapshot<PxMap>> _vendor = PxStreams.vendor();

  @override
  Widget build(BuildContext context) {
    void push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return StreamBuilder<DocumentSnapshot<PxMap>>(
      stream: _vendor,
      builder: (context, snap) {
        final v = snap.data?.data() ?? const <String, dynamic>{};
        final name = Px.text(v['business_name']).isNotEmpty ? Px.text(v['business_name']) : Px.text(v['full_name']);
        final email = Px.text(v['email']).isNotEmpty ? Px.text(v['email']) : (FirebaseAuth.instance.currentUser?.email ?? '');
        final logo = Px.text(v['profile_image_url']);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            const SizedBox(height: 28),
            Center(
              child: logo.isNotEmpty
                  ? PxAvatar(name: name, imageUrl: logo, size: 76)
                  : Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
                      child: const Icon(Icons.apartment_rounded, color: kPxGreen, size: 38),
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(name.isEmpty ? 'Vendor' : name,
                  style: const TextStyle(color: kPxGreen, fontSize: 22, fontWeight: FontWeight.w600)),
            ),
            Center(child: Text(email, style: const TextStyle(color: kPxMuted, fontSize: 12))),
            const SizedBox(height: 22),
            _row(Icons.manage_accounts_outlined, 'Edit Profile', () => push(const PartnerEditProfileScreen())),
            _row(Icons.help_outline, 'Help & Support', () => push(const PartnerHelpSupportScreen())),
            _row(Icons.notifications_none_rounded, 'Notification Settings',
                () => push(const PartnerNotificationSettingsScreen())),
            _row(Icons.credit_card_outlined, 'Manage Payment', () => push(const PartnerManagePaymentScreen())),
          ],
        );
      },
    );
  }

  Widget _row(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kPxBorder))),
        child: Row(
          children: [
            Icon(icon, color: kPxGreen, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class PartnerEditProfileScreen extends StatefulWidget {
  const PartnerEditProfileScreen({super.key});

  @override
  State<PartnerEditProfileScreen> createState() => _PartnerEditProfileScreenState();
}

class _PartnerEditProfileScreenState extends State<PartnerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _type = TextEditingController();
  final _tax = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  File? _logoFile;
  String _logoUrl = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_company, _type, _tax, _address, _contact, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final v = (await Px.db.collection('vendors').doc(Px.uid).get()).data() ?? {};
      _company.text = Px.text(v['business_name']);
      _type.text = Px.text(v['business_type']);
      _tax.text = Px.text(v['tax_id']);
      _address.text = Px.text(v['business_address']);
      _contact.text = Px.text(v['contact_number']);
      _email.text = Px.text(v['email']);
      _logoUrl = Px.text(v['profile_image_url']);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick() async {
    final f = await pickProfileImageFile();
    if (f != null && mounted) setState(() => _logoFile = f);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'business_name': _company.text.trim(),
        'business_type': _type.text.trim(),
        'tax_id': _tax.text.trim(),
        'business_address': _address.text.trim(),
        'contact_number': _contact.text.trim(),
        'email': _email.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (_logoFile != null) {
        data['profile_image_url'] = await uploadProfileImage(role: 'vendor', uid: Px.uid, file: _logoFile!);
      }
      await Px.db.collection('vendors').doc(Px.uid).set(data, SetOptions(merge: true));
      if (!mounted) return;
      pxToast(context, 'Profile updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      pxToast(context, profilePhotoUploadErrorMessage(e), ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (_logoFile != null) {
      image = FileImage(_logoFile!);
    } else if (_logoUrl.isNotEmpty) {
      image = NetworkImage(_logoUrl);
    }
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Edit Profile'),
      body: _loading
          ? const PxLoading()
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pick,
                            child: SizedBox(
                              width: 84,
                              height: 84,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: kPxSurface2,
                                      shape: BoxShape.circle,
                                      image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
                                    ),
                                    child: image == null
                                        ? const Icon(Icons.apartment_rounded, color: kPxGreen, size: 40)
                                        : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: 14,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: kPxGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: kPxBg, width: 2),
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        VendorLabeledField(label: 'Company Name', hint: 'Enter your business name', controller: _company),
                        const SizedBox(height: 14),
                        VendorLabeledField(label: 'Business Type', hint: 'Enter business type', controller: _type),
                        const SizedBox(height: 14),
                        VendorLabeledField(
                            label: 'Registration / NTN no.', hint: 'Enter tax ID / registration number', controller: _tax),
                        const SizedBox(height: 14),
                        VendorLabeledField(
                            label: 'Business Address', hint: 'Enter your business address', controller: _address),
                        const SizedBox(height: 14),
                        VendorLabeledField(
                          label: 'Contact Number',
                          hint: 'Enter contact number',
                          controller: _contact,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        VendorLabeledField(
                          label: 'Email Address',
                          hint: 'Enter email address',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'This field is required';
                            if (!t.contains('@') || !t.contains('.')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                      child: PxButton(label: 'Update', loading: _saving, onPressed: _save),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

const List<String> _pakistanBanks = [
  'Allied Bank',
  'Askari Bank',
  'Bank Alfalah',
  'Bank Al Habib',
  'BankIslami',
  'Faysal Bank',
  'Habib Bank Limited (HBL)',
  'Habib Metropolitan Bank',
  'JS Bank',
  'MCB Bank',
  'Meezan Bank',
  'National Bank of Pakistan',
  'Soneri Bank',
  'Standard Chartered',
  'United Bank Limited (UBL)',
];

const _methods = [
  ('jazzcash', 'JazzCash', 'Mobile wallet · Instant transfer', 'assets/images/jazzcash.png'),
  ('easypaisa', 'Easypaisa', 'Mobile wallet · Fast & secure', 'assets/images/easypaisa.png'),
  ('bank_transfer', 'Bank Transfer', 'IBFT · Direct to account', ''),
];

Widget _methodLogo(String asset) {
  const fallback = Icon(Icons.account_balance_outlined, color: kPxGreen, size: 20);
  return Container(
    width: 36,
    height: 36,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: const Color(0xFF0F2418), borderRadius: BorderRadius.circular(8)),
    child: asset.isEmpty
        ? fallback
        : Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback),
  );
}

class PartnerManagePaymentScreen extends StatefulWidget {
  const PartnerManagePaymentScreen({super.key});

  @override
  State<PartnerManagePaymentScreen> createState() => _PartnerManagePaymentScreenState();
}

class _PartnerManagePaymentScreenState extends State<PartnerManagePaymentScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _vendor = PxStreams.vendor();
  String? _switchTo;
  bool _saving = false;

  Future<Map<String, String>?> _editDetails(String method, PxMap initial) {
    return showPxSheet<Map<String, String>>(
      context,
      (ctx) => _PaymentDetailsSheet(method: method, initial: initial),
    );
  }

  Future<void> _saveMethod(String method, Map<String, String> details, {required bool makeActive}) async {
    setState(() => _saving = true);
    try {
      await Px.db.collection('vendors').doc(Px.uid).set({
        'payment_methods': {
          method: {...details, 'updated_at': FieldValue.serverTimestamp()},
          if (makeActive) 'active': method,
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _switchTo = null);
      pxToast(context, makeActive ? '${Px.methodLabel(method)} is now your active method' : 'Payment details saved');
    } catch (e) {
      if (mounted) pxToast(context, 'Could not save. $e', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Manage Payment'),
      body: StreamBuilder<DocumentSnapshot<PxMap>>(
        stream: _vendor,
        builder: (context, snap) {
          if (!snap.hasData) return const PxLoading();
          final pm = Px.map(snap.data!.data()?['payment_methods']);
          final active = Px.text(pm['active']);
          final activeDetails = Px.map(pm[active]);
          final activeMeta = _methods.where((m) => m.$1 == active).firstOrNull;
          final others = _methods.where((m) => m.$1 != active).toList();
          final verified = Px.text(activeDetails['account_number']).isNotEmpty;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('ACTIVE PAYMENT METHOD', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
                    ),
                    if (activeMeta == null)
                      const PxCard(
                        child: Text('No payment method selected yet. Pick one below.',
                            style: TextStyle(color: kPxMuted, fontSize: 12)),
                      )
                    else
                      PxCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _methodLogo(activeMeta.$4),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(activeMeta.$2,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(
                                        verified
                                            ? [Px.text(activeDetails['account_number']), Px.text(activeDetails['account_title'])]
                                                .where((e) => e.isNotEmpty)
                                                .join(' · ')
                                            : 'Add your account details',
                                        style: const TextStyle(color: kPxMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 28,
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () async {
                                            final d = await _editDetails(active, activeDetails);
                                            if (d != null) await _saveMethod(active, d, makeActive: true);
                                          },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kPxGreen),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: Text(verified ? 'Edit' : 'Add',
                                        style: const TextStyle(color: kPxGreen, fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                            if (verified) ...[
                              const SizedBox(height: 10),
                              const PxChip('✓  Verified & Active', kPxGreen, fontSize: 9),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: kPxBorder)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Switch to another method', style: TextStyle(color: kPxMuted, fontSize: 10)),
                        ),
                        Expanded(child: Divider(color: kPxBorder)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final m in others) ...[
                      PxCard(
                        color: _switchTo == m.$1 ? const Color(0xFF0F2418) : kPxSurface,
                        borderColor: _switchTo == m.$1 ? kPxGreen : null,
                        onTap: () => setState(() => _switchTo = m.$1),
                        child: Row(
                          children: [
                            _methodLogo(m.$4),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.$2,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(m.$3, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              if (_switchTo != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        PxButton(
                          label: 'Confirm Switch',
                          loading: _saving,
                          onPressed: () async {
                            final method = _switchTo!;
                            final d = await _editDetails(method, Px.map(pm[method]));
                            if (d != null) await _saveMethod(method, d, makeActive: true);
                          },
                        ),
                        const SizedBox(height: 10),
                        PxButton.dark(label: 'Cancel', onPressed: () => setState(() => _switchTo = null)),
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
}

class _PaymentDetailsSheet extends StatefulWidget {
  final String method;
  final PxMap initial;

  const _PaymentDetailsSheet({required this.method, required this.initial});

  @override
  State<_PaymentDetailsSheet> createState() => _PaymentDetailsSheetState();
}

class _PaymentDetailsSheetState extends State<_PaymentDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(text: Px.text(widget.initial['account_number']));
  late final _iban = TextEditingController(text: Px.text(widget.initial['iban']));
  late final _holder = TextEditingController(text: Px.text(widget.initial['account_title']));
  late String? _bank =
      _pakistanBanks.contains(Px.text(widget.initial['bank_name'])) ? Px.text(widget.initial['bank_name']) : null;

  bool get _isBank => widget.method == 'bank_transfer';

  @override
  void dispose() {
    _number.dispose();
    _iban.dispose();
    _holder.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, <String, String>{
      'account_number': _number.text.trim(),
      'account_title': _holder.text.trim(),
      if (_isBank) 'bank_name': _bank ?? '',
      if (_isBank) 'iban': _iban.text.trim().toUpperCase().replaceAll(' ', ''),
    });
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      );

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 14);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: PxSheetHandle()),
            const SizedBox(height: 14),
            Text('${Px.methodLabel(widget.method)} details',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            if (_isBank) ...[
              _label('Select Bank'),
              DropdownButtonFormField<String>(
                initialValue: _bank,
                isExpanded: true,
                dropdownColor: kPxSurface2,
                style: style,
                iconEnabledColor: kPxMuted,
                decoration: vendorInputDecoration('Select your bank'),
                items: _pakistanBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bank = v),
                validator: (v) => v == null || v.isEmpty ? 'Please select your bank' : null,
              ),
              _label('Account Number'),
              TextFormField(
                controller: _number,
                style: style,
                cursorColor: kPxGreen,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(20)],
                decoration: vendorInputDecoration('Enter account number'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Please enter your account number';
                  if (t.length < 8) return 'Account number looks too short';
                  return null;
                },
              ),
              _label('IBAN number'),
              TextFormField(
                controller: _iban,
                style: style,
                cursorColor: kPxGreen,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(24),
                ],
                decoration: vendorInputDecoration('PK36 HABB 0000 1234 5678 9012'),
                validator: (v) {
                  final t = (v ?? '').trim().toUpperCase();
                  if (t.isEmpty) return 'Please enter your IBAN';
                  if (!RegExp(r'^PK[0-9]{2}[A-Z]{4}[0-9]{16}$').hasMatch(t)) {
                    return 'Enter a valid 24 character IBAN starting with PK';
                  }
                  return null;
                },
              ),
            ] else ...[
              _label('${Px.methodLabel(widget.method)} mobile number'),
              TextFormField(
                controller: _number,
                style: style,
                cursorColor: kPxGreen,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: vendorInputDecoration('03XX-XXXXXXX'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Please enter your mobile number';
                  if (!RegExp(r'^03[0-9]{9}$').hasMatch(t)) return 'Enter an 11 digit number starting with 03';
                  return null;
                },
              ),
            ],
            _label('Account holder name'),
            TextFormField(
              controller: _holder,
              style: style,
              cursorColor: kPxGreen,
              textCapitalization: TextCapitalization.words,
              decoration: vendorInputDecoration(_isBank ? 'Exactly as on bank account' : 'Full name as registered'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Please enter the account holder name';
                if (t.length < 3) return 'Name looks too short';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PxButton(label: 'Save', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class PartnerNotificationSettingsScreen extends StatefulWidget {
  const PartnerNotificationSettingsScreen({super.key});

  @override
  State<PartnerNotificationSettingsScreen> createState() => _PartnerNotificationSettingsScreenState();
}

class _PartnerNotificationSettingsScreenState extends State<PartnerNotificationSettingsScreen> {
  late final Stream<DocumentSnapshot<PxMap>> _vendor = PxStreams.vendor();
  final Map<String, bool> _local = {};

  static const _defaults = {
    'ride_requests': true,
    'driver_updates': true,
    'booking_cancelled': true,
    'payment_receipts': true,
    'notification_sounds': true,
    'vibration': true,
  };

  Future<void> _set(String key, bool value) async {
    setState(() => _local[key] = value);
    try {
      await Px.db.collection('vendors').doc(Px.uid).set({
        'notification_preferences': {key: value},
        'notification_preferences_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      setState(() => _local[key] = !value);
      pxToast(context, 'Could not save. $e', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Notification Settings'),
      body: StreamBuilder<DocumentSnapshot<PxMap>>(
        stream: _vendor,
        builder: (context, snap) {
          final prefs = Px.map(snap.data?.data()?['notification_preferences']);
          bool val(String k) => _local[k] ?? (prefs[k] is bool ? prefs[k] as bool : _defaults[k]!);
          Widget tile(String key, String title, String sub, {bool last = false}) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: last ? null : const Border(bottom: BorderSide(color: kPxBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(sub, style: const TextStyle(color: kPxMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Switch(
                    value: val(key),
                    onChanged: (v) => _set(key, v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: kPxGreen,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF5A5A5A),
                    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ],
              ),
            );
          }

          Widget head(IconData icon, String text) => Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 4),
                child: Row(
                  children: [
                    Icon(icon, color: kPxGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              head(Icons.notifications_none_rounded, 'Manage Notifications'),
              tile('ride_requests', 'New Passenger Requests', 'Get notified when passengers request.'),
              tile('driver_updates', 'Drives Update', 'Receive alerts for new driver added'),
              tile('booking_cancelled', 'Booking Cancelled', 'Notify when a passenger cancels their booking', last: true),
              head(Icons.savings_outlined, 'Earning & Payment Notifications'),
              tile('payment_receipts', 'Payment Received', 'Get notified when payment hits your wallet', last: true),
              head(Icons.volume_up_outlined, 'Sound & Alert Preferences'),
              tile('notification_sounds', 'Notification Sounds', 'Play sound when get notifications.'),
              tile('vibration', 'Vibration', 'Vibrate when get notifications.', last: true),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class PartnerHelpSupportScreen extends StatelessWidget {
  const PartnerHelpSupportScreen({super.key});

  static const _topics = [
    'Payment Issues',
    'Passenger Support',
    'Technical Support',
    'Report a Problem',
    'Need assistance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final t in _topics) ...[
            PxCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              radius: 6,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartnerSupportChatScreen(topic: t)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(t, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12))),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PartnerNotificationsScreen extends StatefulWidget {
  final void Function(int page, {int subTab})? onOpenPage;

  const PartnerNotificationsScreen({super.key, this.onOpenPage});

  @override
  State<PartnerNotificationsScreen> createState() => _PartnerNotificationsScreenState();
}

class _PartnerNotificationsScreenState extends State<PartnerNotificationsScreen> {
  late final Stream<QuerySnapshot<PxMap>> _items = PxStreams.notifications();

  (IconData, Color, String, int, int) _style(String type, String title) {
    final t = '$type $title'.toLowerCase();
    if (t.contains('sos')) return (Icons.warning_amber_rounded, kPxRed, 'View Alert', PartnerPage.sos, 0);
    if (t.contains('pending') && t.contains('payment')) {
      return (Icons.access_time, kPxOrange, 'Review Now', PartnerPage.payments, 0);
    }
    if (t.contains('payment') || t.contains('proof')) {
      return (Icons.savings_outlined, kPxGreen, 'View Proof', PartnerPage.payments, 0);
    }
    if (t.contains('driver')) return (Icons.directions_car_outlined, kPxBlue, 'View Driver', PartnerPage.drivers, 2);
    return (Icons.airline_seat_recline_normal, kPxGreen, 'View Details', PartnerPage.passengers, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, 'Notification'),
      body: StreamBuilder<QuerySnapshot<PxMap>>(
        stream: _items,
        builder: (context, snap) {
          if (snap.hasError) {
            return const PxEmpty('Could not load notifications', icon: Icons.notifications_off_outlined);
          }
          if (!snap.hasData) return const PxLoading();
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const PxEmpty('No notifications yet', icon: Icons.notifications_none_rounded);
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final n = docs[i].data();
              final title = Px.text(n['title']);
              final s = _style(Px.text(n['type']), title);
              return PxCard(
                color: n['read'] == true ? kPxSurface : const Color(0xFF1E1E1E),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: s.$2, shape: BoxShape.circle),
                      child: Icon(s.$1, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(title.isEmpty ? 'Notification' : title,
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              Text(Px.ago(Px.date(n['created_at'])), style: const TextStyle(color: kPxMuted, fontSize: 9)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(Px.text(n['body']), style: const TextStyle(color: kPxMuted, fontSize: 10)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              docs[i].reference.update({'read': true}).catchError((_) {});
                              Navigator.pop(context);
                              widget.onOpenPage?.call(s.$4, subTab: s.$5);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: kPxGreen, borderRadius: BorderRadius.circular(6)),
                              child: Text(s.$3, style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
