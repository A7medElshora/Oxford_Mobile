import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// flutter run --dart-define=API_URL=https://tafra-learning.domain.com/api
const kBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:5000/api');

class Api {
  static final Api i = Api._();
  late final Dio dio;
  String? token;
  Api._() {
    dio = Dio(BaseOptions(baseUrl: kBaseUrl, connectTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'}));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }));
  }
  Future<dynamic> get(String p, {Map<String, dynamic>? q}) async => (await dio.get(p, queryParameters: q)).data;
  Future<dynamic> post(String p, [dynamic d]) async => (await dio.post(p, data: d)).data;
  static String err(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] != null) return '${d['message']}';
    }
    return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
  }

  // Auth
  Future<Map> me() async => Map.from(await get('/auth/me'));
  // Courses
  Future<List<dynamic>> courses({String? category, String? search, String? level, int? page}) async =>
      await get('/courses', q: {'category': category, 'search': search, 'level': level, 'page': page}..removeWhere((k, v) => v == null || v == ''));
  Future<Map> course(int id) async => Map.from(await get('/courses/$id'));
  // Enrollments & payments
  Future<List<dynamic>> paymentMethods() async => await get('/payment-methods');
  Future<List<dynamic>> myEnrollments() async => await get('/student/enrollments');
  Future<void> enrollFree(int courseId) => post('/enrollments/free', {'courseId': courseId});
  Future<Map> enrollManual(FormData f) async => Map.from((await dio.post('/enrollments/manual', data: f)).data);
  // Lessons
  Future<Map> lesson(int id) async => Map.from(await get('/lessons/$id'));
  Future<Map> progress(int id, bool completed, int seconds) async =>
      Map.from(await post('/lessons/$id/progress', {'completed': completed, 'watchedSeconds': seconds}));
  // Admin
  Future<List<dynamic>> pendingPayments() async => await get('/admin/payments/pending');
  Future<void> approve(int id) => post('/admin/payments/$id/approve');
  Future<void> reject(int id, String reason) => post('/admin/payments/$id/reject', {'reason': reason});
}

class Session extends ChangeNotifier {
  static final Session i = Session._();
  Session._();
  Map? user;
  String get role => '${user?['role'] ?? 'student'}';

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    if (t != null) {
      Api.i.token = t;
      try { user = await Api.i.me(); } catch (_) { Api.i.token = null; await p.remove('token'); }
    }
  }

  Future<void> auth(String path, Map body) async {
    final r = await Api.i.post(path, body);
    Api.i.token = r['token'];
    user = Map.from(r['user']);
    await (await SharedPreferences.getInstance()).setString('token', r['token']);
    notifyListeners();
  }

  Future<void> logout() async {
    Api.i.token = null; user = null;
    await (await SharedPreferences.getInstance()).remove('token');
    notifyListeners();
  }
}
