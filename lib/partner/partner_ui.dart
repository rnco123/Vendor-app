import 'package:flutter/material.dart';

import '../app_colors.dart';

const Color kPxBg = Color(0xFF111111);
const Color kPxSurface = Color(0xFF1A1A1A);
const Color kPxSurface2 = Color(0xFF222222);
const Color kPxBorder = Color(0xFF262626);
const Color kPxGreen = AppColors.primary;
const Color kPxAmber = Color(0xFFF7B500);
const Color kPxRed = Color(0xFFE53935);
const Color kPxBlue = Color(0xFF4A7DFF);
const Color kPxOrange = Color(0xFFFF8A3D);
const Color kPxMuted = AppColors.textSecondary;

class PxChip extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const PxChip(this.label, this.color, {super.key, this.fontSize = 11});

  factory PxChip.status(String status, {Key? key}) {
    final s = status.toLowerCase();
    Color c = kPxAmber;
    if (s == 'active' || s == 'approved' || s == 'resolved' || s == 'paid') {
      c = kPxGreen;
    } else if (s == 'rejected') {
      c = kPxRed;
    }
    final label = status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
    return PxChip(label, c, key: key);
  }

  factory PxChip.plan(String plan, {Key? key}) {
    final weekly = plan.toLowerCase().startsWith('week');
    return PxChip(plan, weekly ? kPxBlue : kPxGreen, key: key, fontSize: 9);
  }

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize < 10 ? 6 : 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class PxSmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const PxSmallButton(this.label, this.color, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(36) : kPxSurface2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? color : kPxMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class PxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  const PxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = kPxSurface,
    this.borderColor,
    this.onTap,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.2),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

class PxSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const PxSectionLabel(this.text,
      {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(0, 18, 0, 8)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                color: kPxMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PxAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool photoStyle;
  final Color? tint;

  const PxAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 36,
    this.photoStyle = false,
    this.tint,
  });

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (photoStyle) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFF3A3A3A), shape: BoxShape.circle),
        child: Icon(Icons.person, color: const Color(0xFF6A6A6A), size: size * 0.7),
      );
    }
    final c = tint ?? kPxBlue;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withAlpha(30), shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: TextStyle(color: c, fontSize: size * 0.36, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class PxLetterAvatar extends StatelessWidget {
  final String name;
  final double size;

  const PxLetterAvatar({super.key, required this.name, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
      child: Text(
        t.isEmpty ? '?' : t[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class PxInfoTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  final Map<String, Color> valueColors;

  const PxInfoTable(this.rows, {super.key, this.valueColors = const {}});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: kPxBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rows[i].key, style: const TextStyle(color: Color(0xFFB5B5B5), fontSize: 13)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].value.isEmpty ? '—' : rows[i].value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: valueColors[rows[i].key] ?? Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PxRoute extends StatelessWidget {
  final String from;
  final String to;
  final String fromLabel;
  final String toLabel;
  final Color endColor;
  final bool pins;

  const PxRoute({
    super.key,
    required this.from,
    required this.to,
    this.fromLabel = 'Starting point',
    this.toLabel = 'End point',
    this.endColor = kPxOrange,
    this.pins = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot(bool start) {
      if (pins) {
        return Icon(start ? Icons.radio_button_checked : Icons.location_on,
            color: Colors.white, size: 14);
      }
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: start ? Colors.transparent : endColor,
          border: start ? Border.all(color: kPxGreen, width: 2) : null,
        ),
      );
    }

    Widget line(String title, String sub) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.isEmpty ? '—' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(color: kPxMuted, fontSize: 11)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            children: [
              dot(true),
              ...List.generate(
                5,
                (_) => Container(
                  width: 1,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: kPxMuted,
                ),
              ),
              dot(false),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(from, fromLabel),
              const SizedBox(height: 8),
              line(to, toLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class PxSegmentTabs extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final bool small;

  const PxSegmentTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kPxSurface, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: small ? 32 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? const Color(0xFF0E2A1B) : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: i == index ? Border.all(color: kPxGreen, width: 1.2) : null,
                  ),
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == index ? kPxGreen : const Color(0xFFB5B5B5),
                      fontSize: small ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PxSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const PxSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      cursorColor: kPxGreen,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: kPxMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: kPxMuted, size: 20),
        filled: true,
        fillColor: kPxBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPxBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPxGreen),
        ),
      ),
    );
  }
}

class PxPageTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onExport;
  final Color color;

  const PxPageTitle(this.title, {super.key, this.onExport, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          if (onExport != null)
            GestureDetector(
              onTap: onExport,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
                child: const Icon(Icons.ios_share, color: Colors.white, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class PxButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final Color textColor;
  final bool outlined;
  final IconData? icon;
  final double height;

  const PxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = kPxGreen,
    this.textColor = Colors.white,
    this.outlined = false,
    this.icon,
    this.height = 48,
  });

  const PxButton.dark({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.textColor = Colors.white,
    this.icon,
    this.height = 48,
  })  : color = kPxSurface2,
        outlined = false;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: textColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
    return SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4A4A4A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withAlpha(120),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: child,
            ),
    );
  }
}

PreferredSizeWidget pxBackAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: kPxBg,
    surfaceTintColor: kPxBg,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
    automaticallyImplyLeading: false,
    shape: const Border(bottom: BorderSide(color: kPxBorder)),
    leading: IconButton(
      onPressed: () => Navigator.maybePop(context),
      icon: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 10),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    actions: actions,
  );
}

class PxEmpty extends StatelessWidget {
  final String text;
  final IconData icon;

  const PxEmpty(this.text, {super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: kPxSurface2, shape: BoxShape.circle),
            child: Icon(icon, color: kPxMuted, size: 24),
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kPxMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class PxLoading extends StatelessWidget {
  const PxLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator(color: kPxGreen, strokeWidth: 2.4)),
    );
  }
}

class PxSheetHandle extends StatelessWidget {
  const PxSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2)),
    );
  }
}

Future<T?> showPxSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPxSurface,
    barrierColor: Colors.black.withAlpha(170),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: builder(ctx),
      ),
    ),
  );
}

class PxCheckBadge extends StatelessWidget {
  final double size;
  final bool outlined;
  final Color color;
  final IconData icon;

  const PxCheckBadge({
    super.key,
    this.size = 56,
    this.outlined = false,
    this.color = kPxGreen,
    this.icon = Icons.check_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outlined ? Colors.transparent : color,
        border: outlined ? Border.all(color: color, width: 2.5) : null,
      ),
      child: Icon(icon, color: outlined ? color : Colors.white, size: size * 0.55),
    );
  }
}

void pxToast(BuildContext context, String message, {bool ok = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: ok ? kPxGreen : kPxRed,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class PxMatchBadge extends StatelessWidget {
  final int percent;

  const PxMatchBadge(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kPxGreen.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text('$percent%', style: const TextStyle(color: kPxGreen, fontSize: 9, fontWeight: FontWeight.w600)),
          const Text('Match', style: TextStyle(color: kPxGreen, fontSize: 8)),
        ],
      ),
    );
  }
}

class PxRadio extends StatelessWidget {
  final bool selected;

  const PxRadio(this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: kPxGreen, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6A6A6A), width: 1.5),
      ),
    );
  }
}
