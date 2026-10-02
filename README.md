# YOLO Mobile

Flutter tabanlı, cihaz üstünde çalışan nesne tespiti uygulaması. TFLite
formatındaki YOLO modelleriyle fotoğraftan, galeriden, toplu görsellerden ve
canlı kameradan nesne tespiti yapar. Hesap ve internet gerekmez; fotoğraflar
cihazdan çıkmaz.

## Özellikler

- Kamera, galeri, toplu görsel ve canlı kamera ile tespit
- Kendi YOLO TFLite modelini içe aktarma: `.tflite` dosyası, model ve
  `labels.txt` içeren `.zip` paketi ya da bağlantıdan indirme
- Model kütüphanesi: birden çok model, aktif model seçimi, silme
- Performans testi: CPU, GPU ve NNAPI için medyan/ortalama/p90 süreler,
  paylaşılabilir rapor
- İki modeli aynı görselde yan yana karşılaştırma
- Sonuçları JSON, CSV ve kutulu PNG olarak dışa aktarma
- Sınıf bazlı filtre (COCO modelleri için), güven/IoU/NMS/maksimum tespit ayarları
- Çözünürlük profilleri (Hızlı, Dengeli, Kalite, Maksimum)
- İngilizce ve Türkçe arayüz

## Proje yapısı

- `lib/core/detection/`: tespit hattının saf, testli parçaları (letterbox,
  decode, NMS, tensör G/Ç, kamera karesi dönüşümü, delegate seçimi)
- `lib/core/services/`: tespit servisi, model kütüphanesi, indirme, ayarlar
- `lib/core/benchmark/`, `lib/core/export/`: performans testi ve dışa aktarma
- `lib/features/`: ekranlar (`home`, `capture`, `results`, `models`,
  `settings`, `preferences`, `history`, `batch`, `onboarding`; ayrıca bayrağın
  arkasındaki `marketplace`, `profile`, `auth`)
- `assets/models/`, `assets/labels/`: yerleşik model ve COCO etiketleri
- `tools/export_yolo26_tflite.py`: YOLO → TFLite dönüşüm scripti

Ayrıntılı mimari notları için `CLAUDE.md` dosyasına bakın.

## Gereksinimler

- Flutter SDK (3.9+ önerilir)
- Android Studio / Xcode (hedef platforma göre)

## Çalıştırma

```bash
flutter pub get
flutter run
```

Pazaryeri ve hesaplar varsayılan olarak kapalıdır. Açmak için bir Supabase
projesi gerekir:

```bash
flutter run --dart-define=MARKETPLACE=true \
  --dart-define=SUPABASE_URL=https://<proje>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon anahtarı>
```

## Release derlemesi

`android/key.properties` yoksa release derlemesi debug anahtarıyla imzalanır
(yalnızca yerelde denemek için; Play'e yüklenemez). Yayın için bir upload
keystore üretin ve `android/key.properties` dosyasını doldurun (`storePassword`,
`keyPassword`, `keyAlias`, `storeFile`). Dosya ve keystore `.gitignore`'dadır,
depoya girmemelidir.

```bash
flutter build appbundle --release
```

Mağaza metinleri ve veri güvenliği notları `docs/play/store-listing.md`,
gizlilik politikası `docs/privacy-policy.md` dosyasındadır.

## Test ve kalite kontrolleri

- Statik analiz: `flutter analyze`
- Test: `flutter test`

Gerçek TFLite çıkarımı (benchmark, hızlandırıcılar, canlı kamera) yalnızca bir
Android/iOS cihazda doğrulanabilir; birim ve widget testleri bunları taklit eder.

## Model notları

- Varsayılan model: `YOLO26 Nano (INT8)`
- Desteklenen model biçimi: girdi `[1, H, W, 3]`, çıktı `[1, 4 + sınıf, N]`
  (int8 veya float32), NMS modelin dışında yapılır.
- Dışa aktarma: `tools/export_yolo26_tflite.py` Ultralytics ile modeli
  `imgsz=832`, `nms=False` olarak dışa aktarır ve `assets/models/` altına kopyalar.

## Lisans

Bu proje [GNU AGPL-3.0](LICENSE) ile lisanslanmıştır. Gömülü varsayılan model
(`assets/models/yolo26n_int8.tflite`) Ultralytics YOLO26'dan türetilmiştir ve
Ultralytics'in AGPL-3.0 lisansına tabidir; uygulamanın kaynağını açık tutmak bu
koşulun bir parçasıdır.

`assets/labels/coco.txt` ve diğer veri dosyaları kendi lisans koşullarına tabi
olabilir. Kullanmadan önce ilgili dosyalardaki lisans notlarını kontrol edin.
