import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text('لوحة الأدمن'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: Session.i.logout)],
          bottom: const TabBar(labelColor: C.primary, indicatorColor: C.primary, tabs: [Tab(text: 'المؤشرات'), Tab(text: 'طلبات الدفع')])),
      body: const TabBarView(children: [_Metrics(), _Pending()])));
}

/// NOTE: /admin/stats is not in the spec; falls back to counting pending payments.
class _Metrics extends StatelessWidget {
  const _Metrics();
  @override
  Widget build(BuildContext context) => Load<Map>(
      fetch: () async {
        Map s = {};
        try { s = Map.from(await Api.i.get('/admin/stats')); } catch (_) {}
        s.putIfAbsent('pendingPayments', () => 0);
        if (s['pendingPayments'] == 0) { try { s['pendingPayments'] = (await Api.i.pendingPayments()).length; } catch (_) {} }
        return s;
      },
      fake: {'totalRevenue': 0, 'pendingPayments': 0, 'studentsCount': 0, 'teachersCount': 0},
      builder: (c, s, r) => ListView(padding: const EdgeInsets.all(16), children: [Rise(child: statGrid([
            StatCard(Icons.account_balance_wallet_rounded, '${s['totalRevenue'] ?? 0}', 'إجمالي الإيرادات', color: C.mint),
            StatCard(Icons.hourglass_top_rounded, '${s['pendingPayments']}', 'طلبات دفع معلقة', color: C.amber),
            StatCard(Icons.groups_rounded, '${s['studentsCount'] ?? 0}', 'الطلاب'),
            StatCard(Icons.cast_for_education_rounded, '${s['teachersCount'] ?? 0}', 'المدرسون', color: C.coral),
          ]))]));
}

class _Pending extends StatefulWidget {
  const _Pending();
  @override
  State<_Pending> createState() => _PendingState();
}
class _PendingState extends State<_Pending> {
  Key k = UniqueKey();
  void refresh() => setState(() => k = UniqueKey());

  Future<void> approve(int id) async {
    try { await Api.i.approve(id); if (mounted) { snack(context, 'تمت الموافقة وتفعيل الكورس'); refresh(); } }
    catch (e) { if (mounted) snack(context, Api.err(e), error: true); }
  }
  Future<void> reject(int id) async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('سبب الرفض'),
        content: TextField(controller: ctl, maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب سبب رفض الإيصال...')),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('رفض', style: TextStyle(color: C.coral)))]));
    if (ok != true || ctl.text.trim().isEmpty) return;
    try { await Api.i.reject(id, ctl.text.trim()); if (mounted) { snack(context, 'تم رفض الطلب'); refresh(); } }
    catch (e) { if (mounted) snack(context, Api.err(e), error: true); }
  }
  void viewReceipt(String url) => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('إيصال التحويل')),
      body: Center(child: InteractiveViewer(minScale: .8, maxScale: 6, child: Image.network(url, loadingBuilder: (c, w, p) => p == null ? w : const CircularProgressIndicator(color: C.primary)))))));

  @override
  Widget build(BuildContext context) => Load<List>(key: k, fetch: () => Api.i.pendingPayments(),
      fake: List.generate(3, (i) => {'paymentId': -i, 'studentName': 'اسم الطالب', 'studentEmail': 'mail@example.com', 'courseTitle': 'عنوان الكورس التجريبي', 'amount': 100, 'paymentMethod': 'فودافون كاش', 'senderPhone': '01000000000', 'receiptImageUrl': '', 'createdAt': '2026-01-01T00:00:00Z'}),
      builder: (c, list, r) => RefreshIndicator(onRefresh: () async => refresh(), child: list.isEmpty
          ? ListView(children: const [SizedBox(height: 120), Center(child: Text('لا توجد طلبات معلقة 🎉', style: TextStyle(color: C.muted)))])
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) {
              final p = list[i];
              return Rise(index: i, child: Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: cardDeco(c), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('${p['studentName']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), Text('${p['amount']} ج.م', style: numStyle(size: 16, color: C.primary))]),
                Text('${p['studentEmail']}', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                const Divider(height: 20),
                Text('الكورس: ${p['courseTitle']}'),
                Text('طريقة الدفع: ${p['paymentMethod']}'),
                Row(children: [const Text('رقم المحوِّل: '), Text('${p['senderPhone']}', style: numStyle(size: 14))]),
                Row(children: [const Text('التاريخ: '), Text('${p['createdAt']}'.replaceFirst('T', ' ').split('.').first.replaceAll('Z', ''), style: numStyle(size: 13, w: FontWeight.w500))]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: '${p['receiptImageUrl']}'.isEmpty ? null : () => viewReceipt(p['receiptImageUrl']), icon: const Icon(Icons.receipt_long), label: const Text('عرض الإيصال'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.mint, minimumSize: const Size(0, 44)), onPressed: () => approve(p['paymentId']), child: const Text('قبول'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.coral, minimumSize: const Size(0, 44)), onPressed: () => reject(p['paymentId']), child: const Text('رفض'))),
                ]),
              ])));
            })));
}
