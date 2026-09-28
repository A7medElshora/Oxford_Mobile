# طفرة التعليمية - Flutter App

## التشغيل
```bash
flutter create . --org com.tafra --project-name tafra_learning   # يولّد مجلدات android/ios فقط (لا يستبدل lib)
flutter pub get
flutter run --dart-define=API_URL=http://<YOUR_LOCAL_IP>:5000/api
```
الإنتاج: `--dart-define=API_URL=https://tafra-learning.domain.com/api`

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
