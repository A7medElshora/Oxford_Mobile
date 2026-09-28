import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'api.dart';
import 'models.dart';
import 'theme.dart';

/// Rise animation: 16dp from below + fade, 450ms, Cubic(0.23,1,0.32,1)
class Rise extends StatelessWidget {
  final Widget child; final int index;
  const Rise({super.key, required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1), curve: kCurve,
      duration: Duration(milliseconds: 450 + (index.clamp(0, 8)) * 60),
      builder: (c, v, ch) => Opacity(opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: ch)),
      child: child);
}

/// Active scale 0.98 + haptic feedback
class Press extends StatefulWidget {
  final Widget child; final VoidCallback? onTap;
  const Press({super.key, required this.child, this.onTap});
  @override
  State<Press> createState() => _PressState();
}
class _PressState extends State<Press> {
  bool _d = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) => setState(() => _d = true),
      onTapCancel: () => setState(() => _d = false),
      onTapUp: (_) => setState(() => _d = false),
      onTap: widget.onTap == null ? null : () { HapticFeedback.selectionClick(); widget.onTap!(); },
      child: AnimatedScale(scale: _d ? .98 : 1, duration: const Duration(milliseconds: 120), curve: kCurve, child: widget.child));
}

/// Generic loader: sets Skeletonizer(enabled: isLoading) with fake structural data
class Load<T> extends StatefulWidget {
  final Future<T> Function() fetch; final T fake;
  final Widget Function(BuildContext, T, VoidCallback reload) builder;
  const Load({super.key, required this.fetch, required this.fake, required this.builder});
  @override
  State<Load<T>> createState() => _LoadState<T>();
}
class _LoadState<T> extends State<Load<T>> {
  late Future<T> f = widget.fetch();
  void reload() => setState(() => f = widget.fetch());
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: f,
      builder: (c, s) {
        if (s.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: C.muted), const SizedBox(height: 12),
            Text(Api.err(s.error!), textAlign: TextAlign.center), const SizedBox(height: 12),
            OutlinedButton(onPressed: reload, child: const Text('إعادة المحاولة'))])));
        }
        final loading = s.connectionState != ConnectionState.done;
        return Skeletonizer(enabled: loading, child: widget.builder(c, s.data ?? widget.fake, reload));
      });
}

BoxDecoration cardDeco(BuildContext c) => BoxDecoration(
    color: Theme.of(c).cardColor, borderRadius: BorderRadius.circular(kRadius),
    border: Border.all(color: Theme.of(c).dividerColor),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0, 8))]);

class NetImg extends StatelessWidget {
  final String url; final double? h;
  const NetImg(this.url, {super.key, this.h});
  @override
  Widget build(BuildContext context) => url.isEmpty
      ? Container(height: h, color: C.paper, child: const Center(child: Icon(Icons.school_rounded, color: C.primary, size: 40)))
      : Image.network(url, height: h, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(height: h, color: C.paper, child: const Icon(Icons.broken_image_outlined, color: C.muted)));
}

class CourseCard extends StatelessWidget {
  final Course c; final num? progress; final VoidCallback onTap; final int index;
  const CourseCard(this.c, {super.key, this.progress, required this.onTap, this.index = 0});
  @override
  Widget build(BuildContext context) => Rise(index: index, child: Press(onTap: onTap, child: Container(
      decoration: cardDeco(context), clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          NetImg(c.imageUrl, h: 150),
          if (c.category.isNotEmpty) Positioned(top: 10, right: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(20)),
              child: Text(c.category, style: const TextStyle(color: C.primary, fontSize: 12, fontWeight: FontWeight.w700)))),
        ]),
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.instructor, style: const TextStyle(color: C.muted, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, height: 1.4)),
          const SizedBox(height: 10),
          if (progress != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: (progress! / 100).clamp(0, 1).toDouble(), minHeight: 7, color: C.mint, backgroundColor: Theme.of(context).dividerColor)),
            const SizedBox(height: 4),
            Text('${progress!.round()}% مكتمل', style: numStyle(size: 12, color: C.muted)),
          ] else Row(children: [
            Text(c.price == 0 ? 'مجاني' : '${c.price} ج.م', style: numStyle(size: 16, color: C.primary)),
            const Spacer(),
            const Icon(Icons.play_circle_outline, size: 16, color: C.muted), const SizedBox(width: 4),
            Text('${c.totalLessons}', style: numStyle(size: 12.5, color: C.muted)),
          ]),
        ])),
      ]))));
}

class StatCard extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const StatCard(this.icon, this.value, this.label, {super.key, this.color = C.primary});
  @override
  Widget build(BuildContext context) => Container(height: 108, padding: const EdgeInsets.all(14), decoration: cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color)),
        Text(value, style: numStyle(size: 22)),
        Text(label, style: const TextStyle(color: C.muted, fontSize: 12.5)),
      ]));
}

Widget statGrid(List<StatCard> cards) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55, children: cards);

void snack(BuildContext c, String m, {bool error = false}) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: error ? C.coral : C.mint, behavior: SnackBarBehavior.floating));
