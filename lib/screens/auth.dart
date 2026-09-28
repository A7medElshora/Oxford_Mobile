import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}
class _AuthState extends State<AuthScreen> {
  bool login = true, busy = false, hide = true; String role = 'student';
  final name = TextEditingController(), email = TextEditingController(), pass = TextEditingController();

  Future<void> submit() async {
    if (email.text.trim().isEmpty || pass.text.length < 6 || (!login && name.text.trim().isEmpty)) {
      return snack(context, 'يرجى إكمال البيانات (كلمة المرور 6 أحرف على الأقل)', error: true);
    }
    setState(() => busy = true);
    try {
      await Session.i.auth(login ? '/auth/login' : '/auth/register',
          {if (!login) 'name': name.text.trim(), 'email': email.text.trim(), 'password': pass.text, if (!login) 'role': role}
            ..putIfAbsent('email', () => email.text.trim()));
    } catch (e) { if (mounted) snack(context, Api.err(e), error: true); }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Rise(child: Column(children: [
        Container(width: 78, height: 78, decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40)),
        const SizedBox(height: 16),
        const Text('طفرة التعليمية', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const Text('Editorial Learning Atelier', style: TextStyle(color: C.muted)),
        const SizedBox(height: 28),
        if (!login) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: hide, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => hide = !hide)))),
        if (!login) ...[const SizedBox(height: 14), SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'student', label: Text('طالب'), icon: Icon(Icons.school_outlined)),
              ButtonSegment(value: 'teacher', label: Text('مدرس'), icon: Icon(Icons.cast_for_education_outlined))],
            selected: {role}, onSelectionChanged: (s) => setState(() => role = s.first))],
        const SizedBox(height: 22),
        Press(onTap: busy ? null : submit, child: ElevatedButton(onPressed: busy ? null : submit,
            child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Text(login ? 'تسجيل الدخول' : 'إنشاء حساب'))),
        TextButton(onPressed: () => setState(() => login = !login), child: Text(login ? 'ليس لديك حساب؟ سجّل الآن' : 'لديك حساب؟ سجّل الدخول')),
      ]))))));
}
