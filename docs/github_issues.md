# GitHub Issue Şablonları — Kurumsal İrsaliye ve Depo Otomasyonu

Bu dosya, [kurumsal_irsaliye_otomasyonu.md](../kurumsal_irsaliye_otomasyonu.md) nihai revize planına dayanan, GitHub'a doğrudan kopyalanabilir issue metinlerini içerir. Her issue Title / Labels / Milestone başlıklarıyla birlikte verilmiştir.

Notlar:
- Plan tek-repo + `mobile/`, `desktop/`, `backend/` workspace yaklaşımını esas alır (Melos kullanılmaz). Issue 1 başlığında "Monorepo" terimi geçse de teknik içerik bu karara uygundur.
- Varyant eşleşme sırası, admin kilit devralma ve muhasebe payload kuralları ilgili issue'ların `Technical Details & Context` bölümlerinde teknik not olarak yer alır.

---

## Issue 1: Monorepo Workspace İskeleti (mobile / desktop / backend)

**Labels:** `chore`, `infra`
**Milestone:** `v1.0-MVP`

### 📝 Description
Kod tabanını `mobile/`, `desktop/`, `backend/` ayrımıyla tek repoda kuran iskelet kurulumu. Cursor / VS Code üzerinde tek pencerede çalışmak için `mavikalem.code-workspace` eklenir. (Melos kullanılmaz; nihai kararla sade workspace yaklaşımı seçilmiştir.)

### ✅ Tasks (Yapılacaklar)
- [ ] Mevcut Flutter uygulamasını `mobile/` klasörüne taşı.
- [ ] `desktop/` klasörünü Electron + React + TypeScript projesi için ayır.
- [ ] Supabase SQL/migration dosyalarını `backend/supabase/` altında topla.
- [ ] Kökte `mavikalem.code-workspace` oluştur ve üç klasörü ekle.
- [ ] Köke `README.md` güncellemesi: yeni klasör ağacı + çalışma komutları.
- [ ] CI/CD path'lerini gözden geçir, kırılma varsa güncelle.

### 🛠 Technical Details & Context
- **Affected Packages:** `mobile/`, `desktop/`, `backend/supabase/`, `tools/waybill-importer/` (sadece path değişimi etkisi).
- **Database Changes:** Yok.
- **Edge Cases:** Flutter asset path bozulması, Supabase CLI komutlarının çalıştığı klasörün değişmesi, mevcut commit geçmişinin korunması (git mv tercih edilmeli).

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] `mavikalem.code-workspace` üç klasörü tek pencerede gösteriyor.
- [ ] `mobile/` projesi taşımanın ardından sorunsuz build/test ediliyor.
- [ ] `backend/supabase` komutları yeni klasörde çalışıyor.

---

## Issue 2: Supabase Şeması, RLS ve Lock RPC'leri

**Labels:** `database`, `backend`, `feature`
**Milestone:** `v1.0-MVP`

### 📝 Description
İrsaliye süreci için tüm tablo şemasını, RLS politikalarını, realtime publication'ları ve tek-picker locking RPC'lerini kuran backend issue'su. Aynı zamanda admin'in zorunlu gerekçeyle kilit devralmasına imkân veren RPC ve audit yapısını içerir.

### ✅ Tasks (Yapılacaklar)
- [ ] `waybills(id, waybill_number, status, locked_by_user_id, locked_at, ...)` tablosunu oluştur.
- [ ] `expected_items(id, waybill_id, parent_barcode, product_name, total_expected_qty, enrichment_status)` tablosunu oluştur.
- [ ] `expected_item_variants(id, expected_item_id, variant_barcode, variant_options, ideasoft_product_id)` tablosunu oluştur.
- [ ] `picked_items(id, waybill_id, parent_expected_item_id, actual_variant_barcode, quantity, ...)` tablosunu oluştur.
- [ ] `picking_sessions` ve `accounting_submissions` tablolarını oluştur.
- [ ] `picked_items` üzerinde unique key: `(waybill_id, actual_variant_barcode)`.
- [ ] `lock_waybill(p_waybill_id)` ve `release_waybill(p_waybill_id)` RPC'leri.
- [ ] `force_unlock_waybill(p_waybill_id, p_reason text)` admin-only RPC.
- [ ] `lock_audit(id, waybill_id, action, actor_user_id, reason, created_at)` audit tablosu.
- [ ] Realtime publication: `picked_items`, `waybills`.
- [ ] RLS politikaları: tüm tablolar `authenticated` rolü; importer için `service_role`.
- [ ] Migration dosyalarını `backend/supabase/migrations/` altında düzenle.

### 🛠 Technical Details & Context
- **Affected Packages:** `backend/supabase/`.
- **Database Changes:** 5 ana tablo + audit tablosu + 3 RPC + RLS + realtime publication.
- **Edge Cases:**
  - `lock_waybill` aynı kullanıcı için idempotent olmalı, başka kullanıcı kilitliyse hata fırlatmalı.
  - `force_unlock_waybill` yalnızca admin role claim ile yetkili; çağrı sırasında zorunlu `reason` audit'e yazılır.
  - `picked_items` upsert anahtarı `(waybill_id, actual_variant_barcode)` olduğundan parent bağı yalnızca foreign key olarak tutulur, unique key bileşeni değildir.
  - `add_picked_item` RPC, mevcut quantity'yi artıracak şekilde upsert davranışı sağlamalı.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] `supabase db reset` ile şema temiz çalışıyor.
- [ ] Bir test client'ı `picked_items` realtime event'ini alıyor.
- [ ] `lock_waybill` ikinci kullanıcı için hata, aynı kullanıcı için idempotent davranışı doğrulanıyor.
- [ ] `force_unlock_waybill` admin olmayan kullanıcıda reddediliyor; admin için zorunlu `reason` audit'e yazılıyor.

---

## Issue 4 & 4.5: Excel Parse ve IdeaSoft Variant Enrichment

**Labels:** `feature`, `desktop`, `infra`
**Milestone:** `v1.0-MVP`

### 📝 Description
Desktop importer Excel girdisini parse eder ve her parent barkod için IdeaSoft API üzerinden varyantları zenginleştirir. Varyantlı barkod modeli (`8...` parent, `8...01`, `8...02` varyantlar) bu adımda kurulur. Manuel cache yenileme akışı ve `enrichment_failed` durumunda warning ile devam etme kararı bu issue ile uygulanır.

### ✅ Tasks (Yapılacaklar)
- [ ] Dosya seçici UI ve IPC fonksiyonu (`xlsx`, `xls`, `csv` kabul eder).
- [ ] `exceljs` ile sheet okuma modülü.
- [ ] Header mapping tablosu: `irsaliye_no`, `parent_barcode`, `urun_adi`, `adet` + opsiyonel `tedarikci`, `fatura_no`.
- [ ] Satır validator: `parent_barcode` zorunlu, sayı formatı, boş satır, tekrar eden parent kontrolü.
- [ ] Parse sonucu modeli: `validRows`, `invalidRows`, `warnings`, `source: 'manual' | 'ocr'`.
- [ ] IdeaSoft client (env token ile): `q[barcode_start]` ve gerekirse `q[barcode_cont]` aramaları.
- [ ] `enrichVariants(parentBarcode)` fonksiyonu — varyantları çekip `expected_item_variants` adaylarını üretir.
- [ ] `enrichment_status` alanını `ok | failed` olarak güncelle.
- [ ] Varyant bulunamayan parentlar için `parent == variant` fallback üret.
- [ ] `enrichment_failed` satırlar için kısa retry sonrası işaretleme + importu durdurmama.
- [ ] Manuel "Varyant cache yenile" UI aksiyonu ekle.

### 🛠 Technical Details & Context
- **Affected Packages:** `desktop/` (renderer + preload + main IPC), `tools/waybill-importer/` (paralel mantık referansı).
- **Database Changes:** Yok (yazım Issue 6'da). Ancak `enrichment_status` alanı şemada hazır olmalı.
- **Edge Cases:**
  - Parent barkod IdeaSoft'ta yoksa: parent kalemi tek varyant kabul et (`parent == variant`), `enrichment_status='ok'`.
  - Parent barkodun varyantları varsa: tüm varyantları `expected_item_variants` olarak listeye al; mobilde okutulurken seçim yapılacak.
  - IdeaSoft 5xx / timeout: kısa retry, sonra `enrichment_failed` ile işaretle, kullanıcı warning + onay ile devam edebilir.
  - Cache stratejisi `manual_refresh_only` — TTL yok; "Varyant cache yenile" butonu ile temizlenir.
  - Token modeli: `preconfigured_env_token` (env değişkeni üzerinden, OAuth UI bu sürümde yok).
- **Referans:** Mevcut Flutter mantığı [lib/features/product_check/data/datasources/product_remote_datasource.dart](../lib/features/product_check/data/datasources/product_remote_datasource.dart) içindeki `fetchByBarcodeCandidates` deseni desktop tarafına uyarlanır.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Örnek 3 farklı Excel formatı parse oluyor; hatalı satırlar satır/alan bilgisiyle raporlanıyor.
- [ ] Varyantlı bir parent için `expected_item_variants` adayları preview'da listeleniyor.
- [ ] Varyantı olmayan parent fallback ile importtan düşmüyor.
- [ ] IdeaSoft hatası simüle edildiğinde import durmuyor; ilgili satır `enrichment_failed` olarak görünüyor.

---

## Issue 5 & 6: Onay Ekranı ve Supabase'e Yazım

**Labels:** `feature`, `desktop`, `database`
**Milestone:** `v1.0-MVP`

### 📝 Description
Parse + enrichment sonrası verilerin önizlenip onaylanması ve Supabase'e idempotent şekilde yazılması. `enrichment_failed` satırlar warning ile dahil edilebilir; yazım sırası ve conflict anahtarları sabittir.

### ✅ Tasks (Yapılacaklar)
- [ ] İrsaliye listesi tablosu (numara, tedarikçi, satır sayısı, toplam adet).
- [ ] Detay paneli: parent kalemler + varyant alt liste (accordion).
- [ ] Hatalı/eksik satır rozet ve filtreleri.
- [ ] `enrichment_failed` satırlar için warning rozeti + "yine de ekle" onayı.
- [ ] "Yalnızca doğrulananları gönder" ve "Sadece varyantı çözülen kalemler" filtreleri.
- [ ] Yazım sırası: `waybills` → `expected_items` → `expected_item_variants`.
- [ ] Upsert conflict anahtarları:
  - `waybills(waybill_number)`
  - `expected_items(waybill_id, parent_barcode)`
  - `expected_item_variants(expected_item_id, variant_barcode)`
- [ ] Batch/chunk gönderim (örn. 500 satır).
- [ ] Yazım sonrası inserted/updated/error sayaçlı rapor ekranı.
- [ ] Audit log kaydı (kim, ne zaman, hangi dosya, kaç satır).

### 🛠 Technical Details & Context
- **Affected Packages:** `desktop/` (renderer UI + persistence service), `backend/supabase/` (yalnızca tablo/policy).
- **Database Changes:** Yok (Issue 2'de tanımlı şema ile çalışır).
- **Edge Cases:**
  - Aynı dosyanın tekrar gönderilmesi duplicate üretmemeli (idempotent upsert).
  - `enrichment_failed` satır gönderilirse `expected_item_variants` boş kalır; mobil tarafta yalnızca parent prefix eşleşmesi geçerli olur.
  - Yazım kısmen başarısız olursa kullanıcıya net "kısmi sonuç" raporu gösterilmeli.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Kullanıcı parent + varyant detayını görerek en az bir irsaliyeyi onaylayabiliyor.
- [ ] Aynı dosya iki kez gönderildiğinde duplicate üretilmiyor.
- [ ] `enrichment_failed` satırlar warning onayıyla başarıyla yazılıyor.
- [ ] Sonuç ekranında inserted/updated/error sayıları görünüyor.

---

## Issue 7: Desktop Doğrulama ve Karşılaştırma Ekranı

**Labels:** `feature`, `desktop`
**Milestone:** `v1.0-MVP`

### 📝 Description
Yazım sonrası DB'deki kayıtları kaynak Excel ile parent + variant seviyesinde karşılaştırıp uyumlu/uyumsuz raporu üreten ekran. Eksik veya fazla varyant durumlarını ayrı rozetlerle gösterir.

### ✅ Tasks (Yapılacaklar)
- [ ] Import sonrası ilgili irsaliyeleri DB'den tekrar çek.
- [ ] Kaynak Excel ile parent + variant seviyesinde karşılaştırma.
- [ ] Eksik varyant / fazla varyant rozeti ayrımı.
- [ ] Uyumlu/uyumsuz sonuçların tablo ve özet görünümü.
- [ ] "Doğrulandı" flag'i ve audit log kaydı.
- [ ] Karşılaştırma için `line_signature` (hash) opsiyonu (performans için ileri sürüm).

### 🛠 Technical Details & Context
- **Affected Packages:** `desktop/` (renderer + persistence read).
- **Database Changes:** İsteğe bağlı `import_verifications` audit tablosu (admin görünürlüğü için faydalı).
- **Edge Cases:**
  - Kaynak dosya yazımdan sonra değişirse karşılaştırmada yanlış fark alarmı verebilir; kullanıcı uyarılmalı.
  - IdeaSoft tarafında varyant değiştiğinde önceden yazılan veri ile fark görülebilir; UI'da "eski snapshot" ifadesi net olmalı.
  - `enrichment_failed` parent'lar için varyant satırı olmadığından yalnızca parent miktar bazlı karşılaştırma yapılır.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Importtan sonra kullanıcı tek ekranda parent + varyant uyum özetini görüyor.
- [ ] Eksik/çok varyant senaryoları doğru rozetleniyor.
- [ ] "Doğrulandı" işareti audit log'a yazılıyor.

---

## Issue 9: Mobil Barkod Okutma (Prefix Matcher & Variant Upsert)

**Labels:** `feature`, `mobile`, `ui`
**Milestone:** `v1.0-MVP`

### 📝 Description
Saha personelinin gerçek varyant barkodunu okutarak adet girmesi ve `picked_items` tablosuna gerçek barkodun upsert edilmesi. Eşleşme önceliği plan tarafından netleştirilmiştir.

### ✅ Tasks (Yapılacaklar)
- [ ] Kamera barkod okuma ekranı (mevcut `mobile_scanner`).
- [ ] Eşleşme akışı:
  1. `expected_item_variants.variant_barcode` exact eşleşme
  2. `expected_item_variants.variant_barcode` prefix eşleşme
  3. `expected_items.parent_barcode` prefix eşleşme
  4. Manuel arama ekranı (parent / ürün adı)
- [ ] Adet giriş modalı (default 1, +/− kontrolü).
- [ ] `add_picked_item` RPC çağrısı; payload: `waybill_id`, `parent_expected_item_id`, `actual_variant_barcode`, `quantity`.
- [ ] Upsert anahtarı: `(waybill_id, actual_variant_barcode)` ile quantity artır.
- [ ] Unknown barkod uyarısı + manuel arama yönlendirmesi.
- [ ] Tarayıcı throttle: 300-500ms.
- [ ] Geri bildirim: ses/vibrasyon (opsiyonel ama tavsiye).

### 🛠 Technical Details & Context
- **Affected Packages:** `mobile/lib/features/picking/`, `mobile/lib/features/scanner/`.
- **Database Changes:** Yok (Issue 2'deki RPC + unique key kullanılır).
- **Edge Cases:**
  - Aynı barkodun farklı ürünlere işaret etmesi durumunda kullanıcıya ambiguity uyarısı gösterilir.
  - Prefix eşleşme uzunluk farkı limiti `BarcodePrefixMatcher.maxExtraDigits` ile sınırlandırılır; minimum karakter zorunluluğu yoktur.
  - Manuel eşleştirilen okutmalar da `actual_variant_barcode` alanına gerçek okutulan kodu yazmalı.
  - Aggregation: aynı varyant tekrar okutulduğunda yeni satır değil, mevcut satırın quantity alanı artırılır (`upsert_single_row`).
- **Referans:** [lib/features/product_check/domain/barcode_prefix_matcher.dart](../lib/features/product_check/domain/barcode_prefix_matcher.dart) içindeki prefix kuralı korunur.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Varyant barkod okutulduğunda doğru parent kalemine bağlanıyor ve quantity artıyor.
- [ ] `picked_items.actual_variant_barcode` gerçek okutulan kodla yazılıyor.
- [ ] Aynı varyant tekrar okutulduğunda yeni satır değil, quantity artışı oluyor.
- [ ] Unknown kod manuel arama ekranına yönlendiriyor.

---

## Issue 10: Mobil Realtime Kilit ve Tamamlama Flow'u

**Labels:** `feature`, `mobile`, `infra`
**Milestone:** `v1.0-MVP`

### 📝 Description
Sayım ekranına girişte tek-picker kilidi alınması, realtime ilerlemenin yansıtılması, tamamlama dialogu ve admin için kilit devralma akışı.

### ✅ Tasks (Yapılacaklar)
- [ ] Sayım ekranına girişte `lock_waybill` RPC çağrısı.
- [ ] `picked_items` realtime subscription.
- [ ] Beklenen vs sayılan ilerleme hesaplama.
- [ ] Tamamlama dialogu (eksik/fazla kalem özeti).
- [ ] İrsaliye durumunu `completed` olarak güncelle.
- [ ] Çıkış / tamamlama / iptal anlarında `release_waybill` çağrısı.
- [ ] Desktop tarafında admin için "Kilidi devral" / "Kaldır" UI aksiyonu.
- [ ] Lock takeover sırasında zorunlu `reason` form alanı.
- [ ] `picking_sessions` tablosuna açılış/kapanış kayıt yazımı.

### 🛠 Technical Details & Context
- **Affected Packages:** `mobile/lib/features/picking/`, `desktop/src/renderer/admin/`.
- **Database Changes:** Yok (Issue 2'deki `lock_waybill`, `release_waybill`, `force_unlock_waybill` ve `lock_audit` kullanılır).
- **Edge Cases:**
  - Kilit alınamazsa kullanıcıya başka picker'ın aktif olduğu bilgisi gösterilir.
  - Admin lock takeover yalnızca admin role claim olan kullanıcılar tarafından yapılabilir; her takeover audit'e zorunlu `reason` ile yazılır.
  - Mobil uygulama beklenmedik kapanışta kilidin manuel release ihtiyacı doğabilir; admin devralma ile çözülür.
  - TTL veya zombie cleanup yok (v1 kararı). Stuck kilitler yalnızca admin müdahalesiyle açılır.

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Aynı irsaliyede ikinci picker kilit alamıyor.
- [ ] Mobildeki güncellemeler desktop tarafında anlık görünüyor.
- [ ] Tamamlanan irsaliye `completed` durumuna geçiyor ve listeden düşüyor.
- [ ] Admin "Kilidi devral" akışı zorunlu gerekçe ile audit'e yazıyor.

---

## Issue 12 & 13: Muhasebe Gateway (REST/Mock) ve Gönderim Akışı (Retry)

**Labels:** `feature`, `desktop`, `infra`, `accounting`
**Milestone:** `v1.0-MVP`

### 📝 Description
Muhasebe entegrasyonunu uygulama kodundan ayıran adapter katmanı (Mock + REST) ve masaüstünden tamamlanan irsaliyeleri gönderme akışı. Payload, parent toplam değil **gerçekte okutulan varyant barkod + adet** olarak kurulur. Otomatik 3 deneme exponential backoff ile yapılır.

### ✅ Tasks (Yapılacaklar)
- [ ] `AccountingGateway` interface tanımı.
- [ ] `MockAccountingGateway` (development/test).
- [ ] `RestAccountingGateway` (prod, env: `ACCOUNTING_ADAPTER=rest`).
- [ ] Timeout, retryable / non-retryable hata sınıflandırması.
- [ ] Payload modeli (TypeScript):

```ts
type AccountingLine = {
  parent_barcode: string;
  actual_variant_barcode: string;
  quantity: number;
};
```

- [ ] "Muhasebeye Gönder" UI aksiyonu (Issue 7 sonrası onaylı irsaliyeler için).
- [ ] Payload'u `picked_items` üzerinden kur:
  - `actual_variant_barcode` ve `quantity` alanlarını kullan.
  - `parent_expected_item_id` üzerinden `expected_items.parent_barcode` resolve et.
- [ ] `accounting_submissions(payload jsonb, status, attempts, last_error)` insert/update.
- [ ] Otomatik retry: 3 deneme, exponential backoff (1s, 2s, 4s).
- [ ] Başarısız sonuç manuel "Tekrar Dene" butonu açar (in-flight kilidiyle duplicate engellenir).
- [ ] Sonuç durumu rozetleri: `pending`, `sent`, `failed`.
- [ ] Son başarılı gönderim tarih/saat bilgisi listede görünür.

### 🛠 Technical Details & Context
- **Affected Packages:** `desktop/src/main/accounting/`, `desktop/src/renderer/features/accounting/`, `backend/supabase/sql/` (yalnızca `accounting_submissions` indeksleri).
- **Database Changes:** Yok (tablo Issue 2'de tanımlı). `payload jsonb` alanı varyant satırlarını saklar.
- **Edge Cases:**
  - Payload'da parent toplam yer almaz; muhasebeye gönderilen miktar her zaman varyant bazlıdır.
  - Aynı varyant barkod birden fazla kez okutulduğunda tek satır upsert nedeniyle quantity tek değer olur (Issue 9 ile tutarlı).
  - Otomatik retry ile manuel retry çakışmamalı (in-flight kilidi).
  - REST adapter v1'de aktif değil; env değiştirildiğinde kod değişikliği gerekmeden devreye alınmalı.
  - `variant_options` (renk/beden) muhasebeye gönderilmez (karar gereği).

### 🏁 Definition of Done (Bitti Diyebilmek İçin)
- [ ] Mock adapter ile uçtan uca submission akışı geçiyor.
- [ ] Retry simülasyonunda 3 deneme exponential backoff doğrulanıyor.
- [ ] Başarısız sonuç sonrası manuel retry başarılı senaryoyu tamamlıyor.
- [ ] Gönderilen payload jsonb içinde `parent_barcode + actual_variant_barcode + quantity` üçlüsünden oluşuyor.
- [ ] `ACCOUNTING_ADAPTER=mock|rest` env değiştirildiğinde uygulama kod değişikliği olmadan adapter değiştiriyor.

---

## Etiket ve Milestone Önerileri

- Etiketler: `chore`, `feature`, `database`, `ui`, `infra`, `mobile`, `desktop`, `backend`, `accounting`, `bug`.
- Milestone'lar:
  - `v1.0-MVP` — Issue 1, 2, 4&4.5, 5&6, 7, 9, 10, 12&13
  - `v1.1-OCR-Auto` — OCR pipeline otomasyonu, varyant cache TTL.
  - `v1.2-MultiPicker` — Çoklu picker eşzamanlı sayım.
  - `v2.0-Offline` — Offline-first sync queue.
