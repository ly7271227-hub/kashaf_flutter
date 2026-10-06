# كشاف — Flutter (نسخة متوافقة مع Flutter 3.47+)

مميزات التطبيق:
- تشغيل وإيقاف فلاش الهاتف عبر Android Camera2 + MethodChannel، بدون torch_light القديم.
- مؤقت بالساعات والدقائق والثواني.
- إطفاء تلقائي عند انتهاء المؤقت.
- تنبيه صوتي عند انتهاء المؤقت.
- وضع SOS.
- ضوء الشاشة.
- واجهة عربية بتصميم داكن وتدرجات بنفسجي/أزرق.

## البناء
```bash
flutter clean
flutter pub get
flutter build apk --release
```

هذه النسخة لا تستخدم `torch_light`، وبالتالي لا تعتمد على Android v1 embedding.
