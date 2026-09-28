import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _ShellState();
}
class _ShellState extends State<StudentShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: IndexedStack(index: i, children: const [StudentDashboard(), BrowseScreen(), MyCoursesScreen(), ProfileScreen()]),
      bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'الكورسات'),
        NavigationDestination(icon: Icon(Icons.play_lesson_outlined), selectedIcon: Icon(Icons.play_lesson), label: 'كورساتي'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
      ]));
}

void openCourse(BuildContext c, int id) => Navigator.push(c, MaterialPageRoute(builder: (_) => CourseDetail(id)));

/// ---------- 5.1 Dashboard ----------
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: Load<Map>(
      fetch: () async {
        final r = await Future.wait([Api.i.courses(), Api.i.myEnrollments()]);
        return {'courses': r[0].map((e) => Course.fromJson(e)).toList(), 'enr': r[1]};
      },
      fake: {'courses': List.generate(4, Course.fake), 'enr': []},
      builder: (c, d, reload) {
        final courses = d['courses'] as List<Course>; final enr = (d['enr'] as List).where((e) => e['status'] == 'active').toList();
        final prog = {for (final e in enr) e['courseId']: (e['progressPercentage'] ?? 0) as num};
        final avg = enr.isEmpty ? 0 : prog.values.reduce((a, b) => a + b) / prog.length;
        double hours = 0; int certs = 0;
        for (final co in courses) { final p = prog[co.id]; if (p != null) { hours += co.durationHours * p / 100; if (p >= 100) certs++; } }
        return RefreshIndicator(color: C.primary, onRefresh: () async => reload(), child: ListView(padding: const EdgeInsets.all(16), children: [
          Rise(child: Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [C.primary, Color(0xFF135FAB)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أهلاً، ${Session.i.user?['name'] ?? ''} 👋', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('نسبة إنجازك الكلية ${avg.round()}%', style: numStyle(size: 14, w: FontWeight.w500, color: Colors.white70)),
                const SizedBox(height: 14),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: avg / 100, minHeight: 8, color: Colors.white, backgroundColor: Colors.white24)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.primaryHover, minimumSize: const Size(0, 42)),
                    onPressed: enr.isEmpty ? null : () => openCourse(context, enr.first['courseId']),
                    icon: const Icon(Icons.play_arrow_rounded), label: const Text('متابعة آخر درس')),
              ]))),
          const SizedBox(height: 16),
          Rise(index: 1, child: statGrid([
            StatCard(Icons.menu_book_rounded, '${enr.length}', 'الكورسات المسجلة'),
            StatCard(Icons.trending_up_rounded, '${avg.round()}%', 'نسبة الإكمال', color: C.mint),
            StatCard(Icons.schedule_rounded, hours.toStringAsFixed(1), 'الساعات المكتملة', color: C.amber),
            StatCard(Icons.workspace_premium_rounded, '$certs', 'الشهادات المكتسبة', color: C.coral),
          ])),
          const SizedBox(height: 20),
          const Text('كورسات متاحة ومقترحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var k = 0; k < courses.length; k++) Padding(padding: const EdgeInsets.only(bottom: 14),
              child: CourseCard(courses[k], index: k + 2, progress: prog[courses[k].id], onTap: () => openCourse(context, courses[k].id))),
        ]));
      }));
}

/// ---------- Browse with filters ----------
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseState();
}
class _BrowseState extends State<BrowseScreen> {
  String q = '', level = ''; Timer? t; Key k = UniqueKey();
  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextField(decoration: const InputDecoration(hintText: 'ابحث عن كورس...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) { t?.cancel(); t = Timer(const Duration(milliseconds: 450), () => setState(() { q = v; k = UniqueKey(); })); }),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final l in const {'': 'الكل', 'beginner': 'مبتدئ', 'intermediate': 'متوسط', 'advanced': 'متقدم'}.entries)
              Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(l.value), selected: level == l.key,
                  selectedColor: C.primary.withOpacity(.18), onSelected: (_) => setState(() { level = l.key; k = UniqueKey(); }))),
          ])),
        ])),
        Expanded(child: Load<List<Course>>(key: k,
            fetch: () async => (await Api.i.courses(search: q, level: level)).map((e) => Course.fromJson(e)).toList(),
            fake: List.generate(3, Course.fake),
            builder: (c, list, r) => list.isEmpty ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: C.muted)))
                : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => CourseCard(list[i], index: i, onTap: () => openCourse(context, list[i].id))))),
      ]));
}

/// ---------- My enrollments ----------
class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: Load<List>(
      fetch: () async => await Api.i.myEnrollments(),
      fake: List.generate(4, (i) => {'id': i, 'courseId': -i, 'courseTitle': 'عنوان الكورس التجريبي', 'status': 'active', 'progressPercentage': 40}),
      builder: (c, list, reload) => RefreshIndicator(onRefresh: () async => reload(), child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('كورساتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
            if (list.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('لم تشترك في أي كورس بعد', style: TextStyle(color: C.muted)))),
            for (var i = 0; i < list.length; i++) Rise(index: i, child: _enrRow(context, list[i]))
          ]))));

  Widget _enrRow(BuildContext c, Map e) {
    final s = e['status'];
    final (label, col) = switch (s) { 'active' => ('نشط', C.mint), 'pending_approval' => ('بانتظار تفعيل الدفع', C.amber), _ => ('مرفوض', C.coral) };
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Press(onTap: s == 'active' ? () => openCourse(c, e['courseId']) : null,
        child: Container(padding: const EdgeInsets.all(14), decoration: cardDeco(c), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('${e['courseTitle']}', style: const TextStyle(fontWeight: FontWeight.w700))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: col.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
                child: Text(label, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700)))]),
          if (s == 'active') ...[const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ((e['progressPercentage'] ?? 0) as num) / 100, minHeight: 7, color: C.mint, backgroundColor: Theme.of(c).dividerColor))],
        ]))));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final u = Session.i.user ?? {};
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 20),
      Center(child: CircleAvatar(radius: 44, backgroundColor: C.primary, backgroundImage: (u['avatarUrl'] ?? '').toString().isEmpty ? null : NetworkImage(u['avatarUrl']),
          child: (u['avatarUrl'] ?? '').toString().isEmpty ? Text('${u['name'] ?? '?'}'.characters.first, style: const TextStyle(fontSize: 34, color: Colors.white)) : null)),
      const SizedBox(height: 12),
      Center(child: Text('${u['name'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      Center(child: Text('${u['email'] ?? ''}', style: const TextStyle(color: C.muted))),
      const SizedBox(height: 30),
      ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: C.coral), onPressed: Session.i.logout, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
    ]));
  }
}

/// ---------- 5.2 Course detail ----------
class CourseDetail extends StatelessWidget {
  final int id;
  const CourseDetail(this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Load<Course>(
      fetch: () async => Course.fromJson(await Api.i.course(id)),
      fake: Course.fake(1),
      builder: (c, co, reload) => Stack(children: [
            CustomScrollView(slivers: [
              SliverAppBar(expandedHeight: 240, pinned: true, backgroundColor: C.primary, foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
                    NetImg(co.imageUrl), // warm gradient overlay
                    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCCF36A21)]))),
                  ]))),
              SliverPadding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), sliver: SliverList(delegate: SliverChildListDelegate([
                Rise(child: Text(co.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.4))),
                const SizedBox(height: 12),
                Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: C.paper, backgroundImage: co.instructorAvatar.isEmpty ? null : NetworkImage(co.instructorAvatar), child: co.instructorAvatar.isEmpty ? const Icon(Icons.person, color: C.primary) : null),
                  const SizedBox(width: 10), Text(co.instructor, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(),
                  const Icon(Icons.video_library_outlined, size: 17, color: C.muted), const SizedBox(width: 4), Text('${co.totalLessons}', style: numStyle(size: 14)),
                  const SizedBox(width: 12), const Icon(Icons.schedule, size: 17, color: C.muted), const SizedBox(width: 4), Text('${co.durationHours}h', style: numStyle(size: 14)),
                ]),
                const SizedBox(height: 16),
                Text(co.description, style: const TextStyle(height: 1.8, color: C.muted)),
                const SizedBox(height: 22),
                const Text('المنهج والدروس', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (var i = 0; i < co.lessons.length; i++) _lessonTile(context, co, co.lessons[i], i),
              ]))),
            ]),
            if (!co.isEnrolled) Positioned(left: 16, right: 16, bottom: 20, child: SafeArea(child: Press(onTap: () => _enroll(context, co), child: ElevatedButton(onPressed: () => _enroll(context, co),
                child: Text(co.price == 0 ? 'انضم مجاناً الآن' : 'اشترك الآن - ${co.price} ج.م'))))),
          ])));

  Widget _lessonTile(BuildContext c, Course co, Lesson l, int i) {
    final open = co.isEnrolled || l.isFreePreview;
    return Rise(index: i, child: Container(margin: const EdgeInsets.only(bottom: 8), decoration: cardDeco(c), child: ListTile(
        leading: Icon(l.isCompleted ? Icons.check_circle : open ? Icons.play_circle_fill_rounded : Icons.lock_outline, color: l.isCompleted ? C.mint : open ? C.primary : C.muted),
        title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
        subtitle: l.isFreePreview && !co.isEnrolled ? const Text('معاينة مجانية', style: TextStyle(color: C.mint, fontSize: 12)) : null,
        trailing: Text(l.duration, style: numStyle(size: 13, w: FontWeight.w500, color: C.muted)),
        onTap: open ? () => Navigator.push(c, MaterialPageRoute(builder: (_) => LessonScreen(l.id))) : () => snack(c, 'اشترك في الكورس لفتح هذا الدرس', error: true))));
  }

  Future<void> _enroll(BuildContext c, Course co) async {
    if (co.price == 0) {
      try { await Api.i.enrollFree(co.id); if (c.mounted) { snack(c, 'تم الانضمام بنجاح'); Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => CourseDetail(co.id))); } }
      catch (e) { if (c.mounted) snack(c, Api.err(e), error: true); }
    } else {
      Navigator.push(c, MaterialPageRoute(builder: (_) => PaymentScreen(co)));
    }
  }
}

/// ---------- 4. Manual payment + receipt picker ----------
class PaymentScreen extends StatefulWidget {
  final Course course;
  const PaymentScreen(this.course, {super.key});
  @override
  State<PaymentScreen> createState() => _PayState();
}
class _PayState extends State<PaymentScreen> {
  int? method; XFile? img; bool busy = false; final phone = TextEditingController();

  Future<void> pick() async {
    final src = await showModalBottomSheet<ImageSource>(context: context, showDragHandle: true, builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.photo_camera_outlined, color: C.primary), title: const Text('فتح الكاميرا والتقاط صورة فوراً'), onTap: () => Navigator.pop(c, ImageSource.camera)),
      ListTile(leading: const Icon(Icons.photo_library_outlined, color: C.primary), title: const Text('اختر من معرض الصور'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
    ])));
    if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, imageQuality: 80, maxWidth: 1600);
    if (x != null) setState(() => img = x);
  }

  Future<void> submit() async {
    if (method == null || phone.text.trim().length < 10 || img == null) return snack(context, 'اختر طريقة الدفع وأدخل رقم المحول وأرفق الإيصال', error: true);
    setState(() => busy = true);
    try {
      final r = await Api.i.enrollManual(FormData.fromMap({
        'courseId': widget.course.id, 'paymentMethodId': method, 'senderPhone': phone.text.trim(),
        'receiptImage': await MultipartFile.fromFile(img!.path, filename: img!.name)}));
      if (!mounted) return;
      await showDialog(context: context, builder: (c) => AlertDialog(icon: const Icon(Icons.check_circle, color: C.mint, size: 48), content: Text('${r['message']}', textAlign: TextAlign.center),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('حسناً'))]));
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) { if (mounted) snack(context, Api.err(e), error: true); }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الدفع والتحويل')), body: Load<List>(
      fetch: () => Api.i.paymentMethods(),
      fake: List.generate(2, (i) => {'id': -i, 'title': 'طريقة الدفع', 'accountNumber': '01000000000', 'accountName': 'اسم الحساب', 'instructions': 'تعليمات التحويل ' * 3}),
      builder: (c, ms, r) => ListView(padding: const EdgeInsets.all(16), children: [
            Text('المبلغ المطلوب: ${widget.course.price} ج.م', style: numStyle(size: 18, color: C.primary)),
            const SizedBox(height: 14),
            for (final m in ms) Padding(padding: const EdgeInsets.only(bottom: 10), child: Press(onTap: () => setState(() => method = m['id']),
                child: Container(padding: const EdgeInsets.all(14), decoration: cardDeco(c).copyWith(border: Border.all(color: method == m['id'] ? C.primary : Theme.of(c).dividerColor, width: method == m['id'] ? 2 : 1)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(method == m['id'] ? Icons.radio_button_checked : Icons.radio_button_off, color: C.primary), const SizedBox(width: 8),
                        Text('${m['title']}', style: const TextStyle(fontWeight: FontWeight.w800))]),
                      const SizedBox(height: 8),
                      Row(children: [Text('${m['accountNumber']}', style: numStyle(size: 16)), IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: '${m['accountNumber']}')); snack(c, 'تم النسخ'); })]),
                      Text('${m['accountName']}', style: const TextStyle(color: C.muted)),
                      Text('${m['instructions']}', style: const TextStyle(fontSize: 12.5, height: 1.6)),
                    ])))),
            const SizedBox(height: 6),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف المحوّل منه', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 16),
            const Text('إيصال التحويل', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
            img == null
                ? Press(onTap: pick, child: Container(height: 150, decoration: BoxDecoration(color: C.paper.withOpacity(Theme.of(c).brightness == Brightness.dark ? .08 : 1), borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: C.primary.withOpacity(.5))),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 40, color: C.primary), SizedBox(height: 8), Text('اضغط لرفع صورة الإيصال')])))
                : Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(kRadius), child: Image.file(File(img!.path), height: 220, width: double.infinity, fit: BoxFit.cover)),
                    Positioned(top: 8, left: 8, child: CircleAvatar(backgroundColor: C.coral, child: IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () => setState(() => img = null)))),
                    Positioned(top: 8, left: 56, child: CircleAvatar(backgroundColor: C.primary, child: IconButton(icon: const Icon(Icons.photo_camera, color: Colors.white), onPressed: pick))),
                  ]),
            const SizedBox(height: 22),
            Press(onTap: busy ? null : submit, child: ElevatedButton(onPressed: busy ? null : submit,
                child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('إرسال طلب الاشتراك'))),
          ])));
}

/// ---------- 5.3 Lesson viewer ----------
class LessonScreen extends StatefulWidget {
  final int id;
  const LessonScreen(this.id, {super.key});
  @override
  State<LessonScreen> createState() => _LessonState();
}
class _LessonState extends State<LessonScreen> {
  Map? lesson; VideoPlayerController? vc; String? error; bool completed = false; double speed = 1; DateTime _lastSync = DateTime.now();

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final l = await Api.i.lesson(widget.id);
      final url = '${l['videoUrl'] ?? ''}';
      if (url.isNotEmpty) {
        vc = VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: {'Authorization': 'Bearer ${Api.i.token}'});
        await vc!.initialize(); vc!.addListener(onTick);
      }
      if (mounted) setState(() => lesson = l);
    } catch (e) { if (mounted) setState(() => error = Api.err(e)); }
  }
  void onTick() {
    final v = vc!.value; if (mounted) setState(() {});
    if (v.duration.inSeconds == 0 || completed) return;
    if (v.position.inSeconds / v.duration.inSeconds >= .9) {
      complete(auto: true);
    }
    else if (DateTime.now().difference(_lastSync).inSeconds > 20) { _lastSync = DateTime.now(); Api.i.progress(widget.id, false, v.position.inSeconds).catchError((_) => <String, dynamic>{}); }
  }
  Future<void> complete({bool auto = false}) async {
    if (completed) return; completed = true;
    try { final r = await Api.i.progress(widget.id, true, vc?.value.position.inSeconds ?? 0);
      if (mounted) snack(context, 'تم إكمال الدرس ✓  التقدم ${r['courseProgressPercentage']}%'); }
    catch (e) { completed = false; if (mounted && !auto) snack(context, Api.err(e), error: true); }
  }
  @override
  void dispose() { vc?.removeListener(onTick); vc?.dispose(); super.dispose(); }

  String fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(error!)));
    if (lesson == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator(color: C.primary)));
    final l = lesson!; final v = vc?.value;
    return DefaultTabController(length: 3, child: Scaffold(appBar: AppBar(title: Text('${l['title']}', style: const TextStyle(fontSize: 16))), body: Column(children: [
      if (vc != null && v!.isInitialized) ...[
        AspectRatio(aspectRatio: v.aspectRatio, child: Stack(alignment: Alignment.center, children: [
          VideoPlayer(vc!),
          IconButton(iconSize: 56, color: Colors.white, icon: Icon(v.isPlaying ? Icons.pause_circle : Icons.play_circle), onPressed: () => v.isPlaying ? vc!.pause() : vc!.play()),
        ])),
        Row(children: [
          Text(fmt(v.position), style: numStyle(size: 12)),
          Expanded(child: Slider(activeColor: C.primary, value: v.position.inMilliseconds.clamp(0, v.duration.inMilliseconds).toDouble(), max: v.duration.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble(), onChanged: (x) => vc!.seekTo(Duration(milliseconds: x.toInt())))),
          Text(fmt(v.duration), style: numStyle(size: 12)),
          PopupMenuButton<double>(icon: Text('${speed}x', style: numStyle(size: 13, color: C.primary)), onSelected: (s) { setState(() => speed = s); vc!.setPlaybackSpeed(s); },
              itemBuilder: (_) => [for (final s in const [.75, 1.0, 1.25, 1.5, 2.0]) PopupMenuItem(value: s, child: Text('${s}x', style: numStyle(size: 14)))]),
        ]),
      ] else Container(height: 200, color: Colors.black12, child: const Center(child: Icon(Icons.videocam_off_outlined, size: 44, color: C.muted))),
      const TabBar(labelColor: C.primary, indicatorColor: C.primary, tabs: [Tab(text: 'نظرة عامة'), Tab(text: 'المرفقات'), Tab(text: 'اختبار')]),
      Expanded(child: TabBarView(children: [
        ListView(padding: const EdgeInsets.all(16), children: [Text('${l['content'] ?? ''}', style: const TextStyle(height: 1.9)), const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: completed ? null : () => complete(), icon: Icon(completed ? Icons.check : Icons.done_all), label: Text(completed ? 'تم إكمال الدرس' : 'إكمال الدرس')),
          const SizedBox(height: 12),
          Row(children: [
            if (l['previousLessonId'] != null) Expanded(child: OutlinedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LessonScreen(l['previousLessonId']))), child: const Text('السابق'))),
            if (l['previousLessonId'] != null && l['nextLessonId'] != null) const SizedBox(width: 10),
            if (l['nextLessonId'] != null) Expanded(child: OutlinedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LessonScreen(l['nextLessonId']))), child: const Text('التالي'))),
          ])]),
        ListView(padding: const EdgeInsets.all(16), children: [
          if (((l['attachments'] ?? []) as List).isEmpty) const Center(child: Text('لا توجد مرفقات', style: TextStyle(color: C.muted))),
          for (final a in (l['attachments'] ?? []) as List) Container(margin: const EdgeInsets.only(bottom: 8), decoration: cardDeco(context), child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: C.coral), title: Text('${a['name']}'), trailing: const Icon(Icons.download_rounded),
              onTap: () => launchUrl(Uri.parse('${a['url']}'), mode: LaunchMode.externalApplication)))]),
        QuizTab(List<Map>.from(((l['quiz'] ?? l['questions'] ?? []) as List).map((e) => Map.from(e)))),
      ])),
    ])));
  }
}

/// MCQ quiz with instant result. Expects lesson.quiz = [{question, options:[..], answerIndex}]
class QuizTab extends StatefulWidget {
  final List<Map> qs;
  const QuizTab(this.qs, {super.key});
  @override
  State<QuizTab> createState() => _QuizState();
}
class _QuizState extends State<QuizTab> {
  final sel = <int, int>{}; bool done = false;
  @override
  Widget build(BuildContext context) {
    if (widget.qs.isEmpty) return const Center(child: Text('لا يوجد اختبار لهذا الدرس', style: TextStyle(color: C.muted)));
    final score = widget.qs.asMap().entries.where((e) => sel[e.key] == e.value['answerIndex']).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final e in widget.qs.asMap().entries) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: cardDeco(context),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.key + 1}. ${e.value['question']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            for (final o in (e.value['options'] as List).asMap().entries) RadioListTile<int>(dense: true, activeColor: C.primary, value: o.key, groupValue: sel[e.key],
                title: Text('${o.value}', style: TextStyle(color: !done ? null : o.key == e.value['answerIndex'] ? C.mint : sel[e.key] == o.key ? C.coral : null)),
                onChanged: done ? null : (v) => setState(() => sel[e.key] = v!)),
          ])),
      if (done) Center(child: Text('نتيجتك: $score / ${widget.qs.length}', style: numStyle(size: 20, color: C.primary)))
      else ElevatedButton(onPressed: sel.length == widget.qs.length ? () => setState(() => done = true) : null, child: const Text('عرض النتيجة')),
    ]);
  }
}
