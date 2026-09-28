# طفرة التعليمية - Flutter App

تطبيق Flutter عربي RTL لمنصة طفرة التعليمية، ويستخدم endpoints الموثقة في
`FLUTTER_SPECIFICATION.md`. لا يحتوي المستند على عنوان خادم إنتاج فعلي؛ لذلك
يتم تمرير عنوان الـ API وقت التشغيل ولا يتم تضمين عنوان وهمي داخل التطبيق.

## التشغيل
```bash
flutter create . --org com.tafra --project-name tafra_learning   # يولّد مجلدات android/ios فقط (لا يستبدل lib)
flutter pub get
flutter run --dart-define=API_URL=http://<YOUR_LOCAL_IP>:5000/api
```
الإنتاج: `--dart-define=API_URL=https://tafra-learning.domain.com/api`

للمحاكي Android يمكن استخدام `http://10.0.2.2:5000/api`، أما الجهاز الحقيقي
فيجب استخدام عنوان IP المحلي للجهاز الذي يشغّل الخادم. لاختبار الاتصال فعليًا
يجب تشغيل backend متاح على هذا العنوان مع endpoints والتوكنات الموضحة في المواصفات.

## أذونات مطلوبة
**Android** `android/app/src/main/AndroidManifest.xml` (داخل `<manifest>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
وأضف `android:usesCleartextTraffic="true"` على `<application>` للتطوير المحلي (HTTP) فقط.

**iOS** `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>لالتقاط صورة إيصال التحويل</string>
<key>NSPhotoLibraryUsageDescription</key><string>لاختيار صورة إيصال التحويل</string>
```

## ملاحظات
- Endpoints المعرّفة في المواصفات مطبّقة كما هي. أما `/teacher/*` و`/admin/stats` وحقل `quiz` داخل الدرس فهي افتراضات (غير موجودة في الملف) — عدّلها في `lib/api.dart` و`lib/screens/`.
