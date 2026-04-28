# MaviKalem Warehouse App

MaviKalem'in depo operasyonlari icin gelistirilmis Flutter mobil uygulamasi.
Uygulama, IdeaSoft siparislerini takip etme, urun toplama (picking), urun kontrolu ve FCM bildirim akislarini tek bir mobil deneyimde toplar.

## Ozellikler

- IdeaSoft OAuth tabanli giris ve token yonetimi
- Gelen siparisleri listeleme, detay goruntuleme ve durum guncelleme
- Supabase uzerinden picking verisini gercek zamanli senkronize etme
- Barkod/stock code ile urun arama ve urun kontrol akisi
- Firebase Cloud Messaging (FCM) ile yeni siparis bildirimleri

## Teknoloji Yigini

- Flutter (Dart `^3.9.0`)
- State management: Riverpod + flutter_bloc
- Networking: Dio
- Realtime/data store: Supabase
- Push notifications: Firebase Core + Firebase Messaging
- Scanner: mobile_scanner

## Mimari

Proje agirlikli olarak feature bazli Clean Architecture yapisini izler:

- `lib/app`: bootstrap, app shell, route ve startup akisi
- `lib/core`: env, network, DI, storage ve ortak altyapi katmani
- `lib/features/auth`: kimlik dogrulama modulu (`data/domain/presentation`)
- `lib/features/orders`: siparis listesi, detay ve submit akislari
- `lib/features/picking`: Supabase tabanli picking repository ve use-case'ler
- `lib/features/product_check`: barkod/stock code urun kontrol modulu
- `lib/features/notifications`: FCM servis katmani

## Gereksinimler

- Flutter SDK (Dart `^3.9.0` ile uyumlu)
- Android Studio + Android SDK
- iOS icin macOS + Xcode + CocoaPods
- Supabase projesi
- Firebase projesi (Android/iOS config dosyalari)
- IdeaSoft API/OAuth erisimi

## Kurulum

1. Repoyu klonlayin ve dizine girin:

```bash
git clone <repo-url>
cd mavikalem
```

2. Bagimliliklari yukleyin:

```bash
flutter pub get
```

3. iOS kullaniyorsaniz pod kurulumunu yapin:

```bash
cd ios
pod install
cd ..
```

4. `.env` dosyasini olusturun (`.env.example` dosyasini referans alin):

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Calistirma

Ana uygulama:

```bash
flutter run -t lib/main.dart
```

Alternatif manuel urun kontrol entrypoint'i:

```bash
flutter run -t lib/main_manual_product_check.dart
```

Not: `lib/main_manual_order_pick.dart` dosyasi su anda yorum satirina alinmistir.

## Harici Servis Konfigurasyonu

### IdeaSoft

- API base URL: `https://mavikalem.myideasoft.com/api`
- OAuth endpointleri ve API path'leri: `lib/core/constants/api_endpoints.dart`
- API contract notlari: `docs/ideasoft_api_contracts.md`

### Supabase

Uygulama startup'ta `.env` uzerinden Supabase'i initialize eder (`lib/app/bootstrap.dart`).

Picking akisinin SQL kurulumunda onerilen sira:

1. `supabase/sql/picking_order_only.sql`
2. Gerekirse `supabase/sql/picking_schema_audit.sql`
3. Gerekirse `supabase/sql/picking_schema_align_remote_only.sql`

Detayli runbook: `supabase/sql/picking_schema_fix_runbook.md`

### Firebase FCM

- FlutterFire config dosyasi: `lib/firebase_options.dart`
- Android config: `android/app/google-services.json`
- iOS config: `ios/Runner/GoogleService-Info.plist`
- Uygulama FCM init akisi: `lib/app/bootstrap.dart`
- FCM servis katmani: `lib/features/notifications/presentation/services/fcm_notification_service.dart`

### Supabase Edge Function ile FCM Gonderimi

- Function dosyasi: `supabase/functions/send-fcm/index.ts`
- Gerekli secret:

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

- Deploy:

```bash
supabase functions deploy send-fcm
```

## Testler

Tum testleri calistir:

```bash
flutter test
```

Belirli bir test dosyasi:

```bash
flutter test test/picking/order_picking_matcher_test.dart
```

Integration testler:

```bash
flutter test integration_test
```

## Katki ve Gelistirme Notlari

- Kod kalitesi icin merge oncesi:

```bash
flutter analyze
flutter test
```

- Gizli anahtar, token ve service account bilgilerini repoya commit etmeyin.
- Firebase options dosyasi su anda mobil platformlar (Android/iOS) odakli konfigure edilmistir.
- Mimari hedefi feature bazli `data/domain/presentation` ayrimini korumaktir; yeni moduller bu yapida eklenmelidir.
