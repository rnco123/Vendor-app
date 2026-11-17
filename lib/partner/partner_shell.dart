import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../email_signin_screen.dart';
import '../shared/logout_sheet.dart';
import 'partner_data.dart';
import 'partner_drivers.dart';
import 'partner_home.dart';
import 'partner_monitoring.dart';
import 'partner_passengers.dart';
import 'partner_payments.dart';
import 'partner_settings.dart';
import 'partner_ui.dart';

class PartnerPage {
  static const int home = 0;
  static const int drivers = 1;
  static const int passengers = 2;
  static const int payments = 3;
  static const int monitoring = 4;
  static const int sos = 5;
  static const int settings = 6;
}

class PartnerScope extends InheritedWidget {
  final void Function(int page, {int subTab}) goTo;
  final VoidCallback openDrawer;

  const PartnerScope({
    super.key,
    required this.goTo,
    required this.openDrawer,
    required super.child,
  });

  static PartnerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PartnerScope>();

  @override
  bool updateShouldNotify(PartnerScope oldWidget) => false;
}

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _page = PartnerPage.home;
  int _subTab = 0;
  int _nonce = 0;

  void _goTo(int page, {int subTab = 0}) {
    setState(() {
      _page = page;
      _subTab = subTab;
      _nonce++;
    });
  }

  Widget _body() {
    switch (_page) {
      case PartnerPage.drivers:
        return PartnerDriversPage(initialTab: _subTab);
      case PartnerPage.passengers:
        return PartnerPassengersPage(initialTab: _subTab);
      case PartnerPage.payments:
        return PartnerPaymentsPage(initialTab: _subTab);
      case PartnerPage.monitoring:
        return const PartnerMonitoringPage();
      case PartnerPage.sos:
        return const PartnerSosPage();
      case PartnerPage.settings:
        return const PartnerSettingsPage();
      default:
        return const PartnerHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PartnerScope(
      goTo: _goTo,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_scaffoldKey.currentState?.isDrawerOpen == true) {
            Navigator.of(context).pop();
            return;
          }
          if (_page != PartnerPage.home) {
            _goTo(PartnerPage.home);
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: kPxBg,
          drawer: PartnerDrawer(current: _page, onSelect: _goTo),
          appBar: PartnerTopBar(
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            onBell: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PartnerNotificationsScreen(onOpenPage: _goTo)),
            ),
          ),
          body: KeyedSubtree(key: ValueKey('$_page-$_nonce'), child: _body()),
          bottomNavigationBar: PartnerBottomNav(
            current: _page <= PartnerPage.payments ? _page : PartnerPage.home,
            onTap: (i) {
              if (i == 4) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                _goTo(i);
              }
            },
          ),
        ),
      ),
    );
  }
}

class PartnerTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenu;
  final VoidCallback onBell;

  const PartnerTopBar({super.key, required this.onMenu, required this.onBell});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPxBg,
      surfaceTintColor: kPxBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      shape: const Border(bottom: BorderSide(color: kPxBorder)),
      leading: IconButton(
        onPressed: onMenu,
        icon: const Icon(Icons.menu, color: Colors.white, size: 24),
      ),
      title: const PartnerWordmark(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: onBell,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class PartnerWordmark extends StatelessWidget {
  const PartnerWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 22,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 10),
        const Text(
          'POOLX',
          style: TextStyle(
            color: kPxGreen,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class PartnerBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const PartnerBottomNav({super.key, required this.current, required this.onTap});

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.directions_car_outlined, 'Driver'),
    (Icons.airline_seat_recline_normal, 'Passenger'),
    (Icons.account_balance_wallet_outlined, 'Payments'),
    (Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(top: BorderSide(color: kPxBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_items[i].$1, size: 22, color: i == current ? kPxGreen : const Color(0xFF8A8A8A)),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            color: i == current ? kPxGreen : const Color(0xFF8A8A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerDrawer extends StatelessWidget {
  final int current;
  final void Function(int page, {int subTab}) onSelect;

  const PartnerDrawer({super.key, required this.current, required this.onSelect});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final ok = await showLogoutSheet(context);
    if (!ok) return;
    await FirebaseAuth.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: selected ? kPxSurface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: selected
                  ? const BoxDecoration(border: Border(left: BorderSide(color: kPxGreen, width: 3)))
                  : null,
              child: Row(
                children: [
                  Icon(icon, color: kPxGreen, size: 22),
                  const SizedBox(width: 14),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void go(int page) {
      Navigator.pop(context);
      onSelect(page);
    }

    return Drawer(
      backgroundColor: kPxBg,
      width: 290,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder(
                stream: PxStreams.vendor(),
                builder: (context, snap) {
                  final v = snap.data?.data() ?? {};
                  final name = Px.text(v['business_name']).isNotEmpty
                      ? Px.text(v['business_name'])
                      : Px.text(v['full_name']);
                  final email = Px.text(v['email']).isNotEmpty
                      ? Px.text(v['email'])
                      : (FirebaseAuth.instance.currentUser?.email ?? '');
                  final logo = Px.text(v['profile_image_url']);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        if (logo.isNotEmpty)
                          PxAvatar(name: name, imageUrl: logo, size: 48)
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(color: kPxGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Vendor' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: kPxMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 10),
              item(Icons.directions_car_outlined, 'Driver', () => go(PartnerPage.drivers),
                  selected: current == PartnerPage.drivers),
              item(Icons.airline_seat_recline_normal, 'Passenger', () => go(PartnerPage.passengers),
                  selected: current == PartnerPage.passengers),
              item(Icons.account_balance_wallet_outlined, 'Payments', () => go(PartnerPage.payments),
                  selected: current == PartnerPage.payments),
              item(Icons.desktop_windows_outlined, 'Monitoring', () => go(PartnerPage.monitoring),
                  selected: current == PartnerPage.monitoring),
              item(Icons.emergency_outlined, 'Emergency', () => go(PartnerPage.sos),
                  selected: current == PartnerPage.sos),
              const SizedBox(height: 18),
              const Divider(color: kPxBorder, height: 1),
              const SizedBox(height: 18),
              const Text('GENERAL', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              item(Icons.notifications_none_rounded, 'Notification', () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute(builder: (_) => PartnerNotificationsScreen(onOpenPage: onSelect)),
                );
              }),
              item(Icons.settings_outlined, 'Settings', () => go(PartnerPage.settings),
                  selected: current == PartnerPage.settings),
              const Spacer(),
              PxButton(label: 'Log Out', onPressed: () => _logout(context)),
            ],
          ),
        ),
      ),
    );
  }
}
