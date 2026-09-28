import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// NOTE: /teacher/* endpoints are not listed in the spec; adjust paths to match your backend.
class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('لوحة المدرس'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: Session.i.logout)]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: C.primary, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('كورس جديد'),
          onPressed: () => showDialog(context: context, builder: (_) => const _CourseForm())),
      body: Load<Map>(
          fetch: () async {
            final r = await Future.wait([Api.i.get('/teacher/stats'), Api.i.get('/teacher/courses')]);
            return {'stats': r[0], 'courses': (r[1] as List).map((e) => Course.fromJson(e)).toList()};
          },
          fake: {'stats': {'students': 0, 'revenue': 0, 'publishedCourses': 0, 'avgRating': 0}, 'courses': List.generate(3, Course.fake)},
          builder: (c, d, reload) {
            final s = d['stats'] as Map; final cs = d['courses'] as List<Course>;
            return RefreshIndicator(onRefresh: () async => reload(), child: ListView(padding: const EdgeInsets.all(16), children: [
              statGrid([
                StatCard(Icons.groups_rounded, '${s['students'] ?? 0}', 'إجمالي الطلاب'),
                StatCard(Icons.payments_rounded, '${s['revenue'] ?? 0}', 'الإيرادات (ج.م)', color: C.mint),
                StatCard(Icons.menu_book_rounded, '${s['publishedCourses'] ?? 0}', 'كورسات منشورة', color: C.amber),
                StatCard(Icons.star_rounded, '${s['avgRating'] ?? 0}', 'متوسط التقييم', color: C.coral),
              ]),
              const SizedBox(height: 18), const Text('كورساتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
              for (var i = 0; i < cs.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: CourseCard(cs[i], index: i, onTap: () {})),
            ]));
          }));
}

class _CourseForm extends StatefulWidget {
  const _CourseForm();
  @override
  State<_CourseForm> createState() => _CourseFormState();
}
class _CourseFormState extends State<_CourseForm> {
  final t = TextEditingController(), d = TextEditingController(), cat = TextEditingController(), p = TextEditingController(text: '0'); String level = 'beginner';
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('إنشاء كورس'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: 'العنوان')), const SizedBox(height: 8),
        TextField(controller: d, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف')), const SizedBox(height: 8),
        TextField(controller: cat, decoration: const InputDecoration(labelText: 'الفئة')), const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: level, items: const [DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')), DropdownMenuItem(value: 'intermediate', child: Text('متوسط')), DropdownMenuItem(value: 'advanced', child: Text('متقدم'))], onChanged: (v) => level = v!),
        const SizedBox(height: 8), TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
      ])), actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(onPressed: () async {
          try { await Api.i.post('/teacher/courses', {'title': t.text, 'description': d.text, 'category': cat.text, 'level': level, 'price': num.tryParse(p.text) ?? 0});
            if (context.mounted) { Navigator.pop(context); snack(context, 'تم إنشاء الكورس'); } }
          catch (e) { if (context.mounted) snack(context, Api.err(e), error: true); }
        }, child: const Text('حفظ')),
      ]);
}
