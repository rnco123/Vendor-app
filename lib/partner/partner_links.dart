import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'partner_ui.dart';

Future<void> pxOpenUrl(BuildContext context, String url) async {
  final u = url.trim();
  if (u.isEmpty) {
    pxToast(context, 'Link is not available', ok: false);
    return;
  }
  final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) pxToast(context, 'Could not open the link', ok: false);
}

Future<void> pxCall(BuildContext context, String phone) async {
  final p = phone.trim();
  if (p.isEmpty) {
    pxToast(context, 'Phone number is not available', ok: false);
    return;
  }
  final ok = await launchUrl(Uri(scheme: 'tel', path: p), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) pxToast(context, 'Could not open the phone app', ok: false);
}

Future<void> pxOpenMap(BuildContext context, double lat, double lng) {
  return pxOpenUrl(context, 'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
}

Future<void> pxOpenDirections(BuildContext context, String from, String to) {
  final o = Uri.encodeComponent(from);
  final d = Uri.encodeComponent(to);
  return pxOpenUrl(context, 'https://www.google.com/maps/dir/?api=1&origin=$o&destination=$d');
}

Future<void> pxCopy(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) pxToast(context, message);
}
