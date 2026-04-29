# Kurumsal İrsaliye ve Depo Otomasyonu — Geliştirme Planı

Excel veri içe aktarımı, mobil saha sayımı ve masaüstü muhasebe kontrolünden oluşan üç parçalı sistemin Melos monorepo + Clean Architecture mimarisinde issue'lara bölünmüş uygulama planı.

## Proje Kapsamı

1. **Data Importer:** Excel verisini okuyup veritabanına basar.
2. **Mobil Uygulama:** İrsaliye bazlı barkod okuma, adet girme, realtime güncelleme.
3. **Masaüstü Uygulama:** Mobilde tamamlanan irsaliyeleri kontrol eder, muhasebeye aktarır.

## Mimari Karar

- **Monorepo:** Melos ile `apps/*` + `packages/*`
- **Clean Architecture:** `core` (domain) -> `data` -> `adapter`
- **Repository Pattern:** tüm veri erişimi abstract repository üzerinden
- **State Management:** Riverpod (mevcut kodla uyum + test kolaylığı)

## Hedef Klasör Ağacı

```text
mavikalem/
├─ melos.yaml
├─ pubspec.yaml
├─ analysis_options.yaml
├─ apps/
│  ├─ mavikalem_mobil/
│  └─ mavikalem_masaustu/
├─ packages/
│  ├─ mavikalem_core/
│  ├─ mavikalem_data/
│  ├─ mavikalem_supabase/
│  ├─ mavikalem_accounting/
│  ├─ mavikalem_ui/
│  └─ mavikalem_lints/
├─ backend/
│  └─ supabase/
│     ├─ migrations/
│     └─ sql/
└─ tools/
   └─ waybill-importer/
```

---

## Issue 1: Monorepo Iskeleti (Melos)

**Description**

Mevcut tek kök Flutter projesini monorepo yapısına dönüştür. `apps/mavikalem_mobil` mevcut kodun yeni evi olacak, `apps/mavikalem_masaustu` yeni app olarak açılacak.

**Implementation Plan**

- `melos.yaml` oluştur (`apps/**`, `packages/**`)
- root `pubspec.yaml` workspace olacak şekilde sadeleştir
- mevcut mobil app dosyalarını `apps/mavikalem_mobil/` altına taşı
- masaüstü app’i `apps/mavikalem_masaustu/` olarak oluştur
- boş paketleri `packages/` altında aç

**Test/Commit Kriteri**

- `melos bootstrap` başarılı
- `melos run analyze` 0 hata

---

## Issue 2: Core Domain Paketi

**Description**

Pure Dart domain katmanı (`mavikalem_core`) oluşturulur. Flutter/Supabase bağımlılığı olmayacak.

**Implementation Plan**

- `entities`: `Waybill`, `ExpectedItem`, `PickedItem`, `PickingSession`, `AccountingSubmission`
- `value_objects`: `Barcode`, `Sku`, `WaybillStatus`
- `failures`: `Failure` hiyerarşisi
- barrel export dosyası

**Test/Commit Kriteri**

- entity/value object unit testleri geçer

---

## Issue 3: Abstract Repository + Use Case

**Description**

Core içinde repository interface’leri ve use case’ler yazılır.

**Implementation Plan**

- `WaybillRepository`, `PickingRepository`, `AccountingRepository` (abstract)
- waybill/picking/accounting use case’leri
- `PickingProgressCalculator`, `VarianceCalculator` (pure service)

**Test/Commit Kriteri**

- mock repository ile tüm use case testleri geçer

---

## Issue 4: Supabase Şeması (Waybill-Centric)

**Description**

Backend tablosu `waybill` merkezli normalize edilir; realtime + RLS aktif.

**Implementation Plan**

- `waybills`, `expected_items`, `picking_sessions`, `picked_items`, `accounting_submissions`
- trigger + index + unique constraints
- `add_picked_item` RPC fonksiyonu
- migration dosyaları

**Test/Commit Kriteri**

- `supabase db reset` sonrası şema sorunsuz kurulur

---

## Issue 5: Data Importer Adaptasyonu

**Description**

`tools/waybill-importer` yeni Supabase şemasına uyarlanır.

**Implementation Plan**

- waybill upsert sonrası `id` map (waybill_number -> uuid)
- expected_items upsert conflict: `(waybill_id, sku)`
- status alanı enum ile uyumlu (`pending` default)

**Test/Commit Kriteri**

- dry-run ve gerçek insert senaryoları başarıyla çalışır

---

## Issue 6: Data Katmanı (`mavikalem_data`)

**Description**

Repository implementasyonları, DTO mapleme ve datasource abstraction katmanı.

**Implementation Plan**

- DTO: `waybill_dto`, `expected_item_dto`, `picked_item_dto`
- datasource interface’leri
- repository impl’ler (`*_repository_impl.dart`)
- exception -> failure mapping

**Test/Commit Kriteri**

- JSON roundtrip testleri + repository unit testleri

---

## Issue 7: Supabase Adapter (`mavikalem_supabase`)

**Description**

Data katmanındaki abstract datasource’ların Supabase implementasyonu.

**Implementation Plan**

- `supabase_client_provider`
- `supabase_waybill_datasource`
- `supabase_picking_datasource`
- realtime `picked_items` channel

**Test/Commit Kriteri**

- integration testte fetch + realtime + rpc çağrıları geçer

---

## Issue 8: Mobil App Bootstrap

**Description**

`mavikalem_mobil` için Riverpod DI, router, auth bootstrap.

**Implementation Plan**

- app/router/bootstrap yapısı kur
- provider wiring (`repository` + `usecase`)
- mevcut auth/theme parçalarını taşı ve importları güncelle

**Test/Commit Kriteri**

- login -> waybill listesi akışı açılır

---

## Issue 9: Mobil İrsaliye Liste/Detay

**Description**

Açık irsaliyeler listelenir; detayda beklenen/sayılan ilerleme realtime görünür.

**Implementation Plan**

- `waybills_list_page`
- `waybill_detail_page`
- `waybill_detail_controller` (expected + picked stream birleştirme)

**Test/Commit Kriteri**

- widget testleri: liste, arama, detay progress

---

## Issue 10: Mobil Barkod Sayım Ekranı

**Description**

Kamera tarama, adet onayı, pick kaydı ve eşzamanlı güncelleme.

**Implementation Plan**

- `picking_page`
- `picking_controller`
- `quantity_dialog`
- scanner throttle/debounce koruması

**Test/Commit Kriteri**

- scan -> modal -> onay -> use case çağrısı doğrulanır

---

## Issue 11: Mobil Tamamlama Akışı

**Description**

İrsaliye tamamla, variance kontrol et, session sonlandır.

**Implementation Plan**

- `complete_waybill_dialog`
- `complete_waybill_controller`
- force complete opsiyonu (eksik kalem olsa bile)

**Test/Commit Kriteri**

- complete use case happy/error/force path testleri

---

## Issue 12: Masaüstü Bootstrap + Review

**Description**

`mavikalem_masaustu` iskeleti ve tamamlanan irsaliyelerin kontrol ekranı.

**Implementation Plan**

- desktop router + sidebar layout
- `completed_waybills_page` (DataTable)
- `waybill_review_detail_page` (beklenen/sayılan/fark)

**Test/Commit Kriteri**

- masaüstünde liste + detay akışı çalışır

---

## Issue 13: Muhasebe Gateway Paketi

**Description**

Muhasebe entegrasyonu için abstract gateway + REST/mock adapter.

**Implementation Plan**

- `AccountingGateway` contract
- `rest_accounting_gateway`
- `mock_accounting_gateway`
- submission model/result sınıfları

**Test/Commit Kriteri**

- mock ile e2e submission, REST retry senaryosu testleri

---

## Issue 14: Masaüstü Muhasebe Gönderim Akışı

**Description**

Tamamlanan irsaliyeleri masaüstünden muhasebeye gönder, durum izle, retry yap.

**Implementation Plan**

- `accounting_export_page`
- `submit_review_dialog`
- `submit_controller`
- başarı/hata/retry UI durumları

**Test/Commit Kriteri**

- dialog onayı sonrası submit çağrısı ve retry akışı testten geçer

---

## Açık Sorular (Plan Sonu)

1. Mevcut `mavikalem_app` tamamen bu yeni sistemin mobil uygulamasına mı evrilecek?
2. Masaüstü hedef yalnızca Windows mu, yoksa macOS da kesin kapsamda mı?
3. Muhasebe yazılımının entegrasyon tipi nedir (REST / SOAP / COM / dosya aktarımı)?
4. Excel verisi nasıl üretiliyor (manuel, OCR, üçüncü parti)?
5. Mobil kullanıcı doğrulama modeli nedir (Supabase auth mı, cihaz bazlı mı)?
6. Barkod eşleşmesi tek barkod mu, çoklu barkod desteği gerekli mi?
7. Aynı irsaliyede çoklu picker eşzamanlı çalışabilecek mi?
8. Offline çalışma zorunluluğu var mı?
9. Projede tek state standardı Riverpod olarak netleşsin mi?

