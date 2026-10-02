# YOLO Mobile

Flutter tabanlı mobil nesne tespit uygulaması. Uygulama, TFLite formatındaki
YOLO modelini kullanarak fotoğraftan nesne tespiti yapar ve sonuçları kutular
ve özet liste olarak gösterir.

## Özellikler

- Kamera veya galeriden görsel ile tespit
- Sınıf bazlı tercih yönetimi (kategori ve etiket seçimi)
- Confidence/IoU/NMS/max detections ayarları
- Çözünürlük profilleri (Hızlı, Dengeli, Kalite, Maksimum)
- Düşük bellek cihazı uyarısı (Android method channel)
- Sonuç özeti kaydetme ve paylaşım için panoya kopyalama

## Proje yapısı

- `lib/core/models/`: Veri modelleri (`AppSettings`, `DetectedObject`, vb.)
- `lib/core/services/`: Tespit servisi, cihaz yetenekleri, ayar kontrolcüsü
- `lib/features/`: Ekranlar (`capture`, `results`, `preferences`, `settings`)
- `assets/models/`: Çalışma zamanı TFLite model dosyası
- `assets/labels/`: Etiket dosyası (`coco.txt`)
- `tools/export_yolo26_tflite.py`: YOLO -> TFLite dönüşüm scripti

## Gereksinimler

- Flutter SDK (3.9+ önerilir)
- Dart SDK (Flutter ile gelen)
- Android Studio / Xcode (hedef platforma göre)

## Kurulum

1. Bağımlılıkları yükleyin.
2. Model ve etiket dosyalarının doğru konumda olduğundan emin olun:
	 - `assets/models/yolo26n_int8.tflite`
	 - `assets/labels/coco.txt`
3. Uygulamayı çalıştırın.

## Test ve kalite kontrolleri

- Statik analiz: `flutter analyze`
- Test: `flutter test`

## Model notları

- Varsayılan model: `YOLOv26 Nano (INT8)`
- TFLite export scripti:
	- `tools/export_yolo26_tflite.py`
	- Ultralytics ile model export edip çıktıyı `assets/models/` altına kopyalar.

## Bilinen sınırlamalar

- Model seçim menüsünde şu an tek model seçeneği bulunmaktadır.

## Lisans

Proje içindeki model/etiket/dataset dosyaları kendi lisans koşullarına tabi olabilir.
Kullanmadan önce ilgili dosyalardaki lisans notlarını kontrol edin.
