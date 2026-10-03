# Play Store listing draft

Fill the placeholders (`<...>`) once the app name and package id are final.
Check that the name does not misuse the "YOLO" trademark before publishing.

## Data safety form (v1)

- Data collected: **none**. Data shared: **none**.
- Data encrypted in transit: not applicable (no data is sent). URL model import is a plain download initiated by the user.
- Account creation: none. Data deletion: not applicable.
- Permissions: `CAMERA` (live detection), `INTERNET` (URL model import only).
- Privacy policy URL: host `docs/privacy-policy.md` (for example GitHub Pages) and enter the link.

## English

**Title (30):** PocketDetect: Object Detection
**Short description (80):** Offline AI object detection with your own YOLO models. No account needed.

**Full description:**
Detect objects with your camera or photos, entirely on your device. Nothing is uploaded, no account is needed, and it works offline.

For everyone
• Live camera, photo, gallery and batch detection
• Works right away with a built-in YOLO26 model
• Choose what to detect, tune confidence and speed

For tinkerers
• Import your own YOLO TFLite model (.tflite, or .zip with labels, or a link)
• Benchmark models on CPU, GPU and NNAPI and share the report
• Compare two models side by side on the same image
• Export results as JSON, CSV or an annotated image

Free and open source (AGPL-3.0): https://github.com/Alperen012/pocketdetect

## Türkçe

**Başlık (30):** PocketDetect: Nesne Tespiti
**Kısa açıklama (80):** Kendi YOLO modellerinle çevrimdışı yapay zekâ nesne tespiti. Hesap gerekmez.

**Tam açıklama:**
Kameranla veya fotoğraflarla nesneleri tamamen cihazında tespit et. Hiçbir şey yüklenmez, hesap gerekmez, internetsiz çalışır.

Herkes için
• Canlı kamera, fotoğraf, galeri ve toplu tespit
• Yerleşik YOLO26 modeliyle hemen çalışır
• Neyi tespit edeceğini seç, güven ve hız ayarlarını yap

Meraklılar için
• Kendi YOLO TFLite modelini içe aktar (.tflite, etiketli .zip veya bağlantı)
• Modelleri CPU, GPU ve NNAPI'de ölç, raporu paylaş
• İki modeli aynı görselde yan yana karşılaştır
• Sonuçları JSON, CSV veya kutulu görsel olarak dışa aktar

Ücretsiz ve açık kaynak (AGPL-3.0): https://github.com/Alperen012/pocketdetect

## Release checklist

1. Create an upload keystore (never commit it), then `android/key.properties`:
   `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (path relative to `android/`).
2. `flutter build appbundle --release` and upload to the internal test track.
3. Closed test (check the current tester count and duration rule in Play Console), then production.
