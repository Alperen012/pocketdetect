// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'YOLO Mobile';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navCapture => 'Çekim';

  @override
  String get navPreferences => 'Tercihler';

  @override
  String get navProfile => 'Profil';

  @override
  String get dashboardSubtitle =>
      'Kamerayı yalnızca istediğinizde açın. Hızlı ve kontrollü bir tespit akışı burada başlar.';

  @override
  String get activeDetectionProfile => 'Aktif Tespit Profili';

  @override
  String selectedClassCount(int count) {
    return 'Seçili sınıf: $count';
  }

  @override
  String resolutionDisplay(String label) {
    return 'Çözünürlük: $label';
  }

  @override
  String thresholdDisplay(String value) {
    return 'Eşik: $value';
  }

  @override
  String get editPreferences => 'Tercihleri Düzenle';

  @override
  String get areYouReady => 'Hazır mısınız?';

  @override
  String get cameraStartsOnTap =>
      'Kamera yalnızca düğmeye bastığınızda başlar.';

  @override
  String get startCamera => 'Kamerayı Başlat';

  @override
  String get lowMemoryModeEnabled => 'Düşük bellek modu etkin.';

  @override
  String get cameraInitFailed => 'Kamera başlatılamadı';

  @override
  String get photoCaptureFailed => 'Fotoğraf çekilemedi.';

  @override
  String get noClassesSelected => 'Sınıf seçilmedi';

  @override
  String detectingLabels(String labels) {
    return 'Tespit: $labels';
  }

  @override
  String detectingLabelsMore(String first, int count) {
    return 'Tespit: $first +$count daha';
  }

  @override
  String get lowMemoryMode => 'Düşük bellek modu';

  @override
  String get pickFromGallery => 'Galeriden Seç';

  @override
  String get flipCamera => 'Kamerayı Çevir';

  @override
  String classCount(int count) {
    return '$count sınıf';
  }

  @override
  String get detectionResults => 'Tespit Sonuçları';

  @override
  String get analysisSummary => 'Analiz Özeti';

  @override
  String get results => 'Sonuçlar';

  @override
  String get photoReadyTapToProcess =>
      'Fotoğraf hazır. İşlemeye başlamak için aşağıdaki düğmeye dokunun.';

  @override
  String analysisError(String error) {
    return 'Analiz hatası: $error';
  }

  @override
  String get noDetectionsFound => 'Tespit bulunamadı.';

  @override
  String confidenceValue(String value) {
    return 'Güven: $value';
  }

  @override
  String itemCount(int count) {
    return '$count adet';
  }

  @override
  String get retake => 'Tekrar Çek';

  @override
  String get starting => 'Başlatılıyor...';

  @override
  String get startProcessing => 'İşlemeye Başla';

  @override
  String get processing => 'İşleniyor...';

  @override
  String get save => 'Kaydet';

  @override
  String get shareResult => 'Sonucu Paylaş';

  @override
  String get analysisInProgressWait =>
      'Analiz devam ediyor. Lütfen birkaç saniye bekleyin.';

  @override
  String get reportSaved => 'Rapor başarıyla kaydedildi.';

  @override
  String get reportSaveFailed => 'Rapor kaydedilemedi.';

  @override
  String get shareSubject => 'YOLO Mobile Tespit Sonucu';

  @override
  String get shareFailedCopied => 'Paylaşım açılamadı. Özet panoya kopyalandı.';

  @override
  String get analyzingImage => 'Görüntü analiz ediliyor...';

  @override
  String get modelRunningOnDevice => 'Model cihaz üzerinde çalışıyor';

  @override
  String get analysisInProgress => 'Analiz devam ediyor';

  @override
  String get analysisSteps =>
      '• Nesne bölgeleri hesaplanıyor\n• Güven skorları değerlendiriliyor\n• Sonuçlar hazırlanıyor';

  @override
  String get reportTitle => 'YOLO Mobile Tespit Raporu';

  @override
  String reportGenerated(String timestamp) {
    return 'Oluşturulma: $timestamp';
  }

  @override
  String reportImage(String path) {
    return 'Görüntü: $path';
  }

  @override
  String reportTotalDetections(int count) {
    return 'Toplam tespit: $count';
  }

  @override
  String get reportSummaryHeader => 'Özet:';

  @override
  String get reportDetailedHeader => 'Detaylı Tespitler:';

  @override
  String reportBoundingBox(String x, String y, String w, String h) {
    return '  BBox: [$x, $y, $w, $h]';
  }

  @override
  String get showBoundingBoxes => 'Sınır kutularını göster';

  @override
  String get hideBoundingBoxes => 'Sınır kutularını gizle';

  @override
  String inferenceTimeMs(int ms) {
    return '$ms ms';
  }

  @override
  String get advancedSettings => 'Gelişmiş Ayarlar';

  @override
  String get sectionModelArchitecture => 'MODEL MİMARİSİ';

  @override
  String get activeModel => 'Aktif Model';

  @override
  String get yoloNanoInt8 => 'YOLOv26 Nano (INT8)';

  @override
  String get nanoModelDescription =>
      'Nano, mobil cihazlarda gerçek zamanlı çıkarım için optimize edilmiştir.';

  @override
  String get customModelActiveWarning =>
      'Özel model etkin. Yerleşik modeller devre dışı.';

  @override
  String get sectionCustomModel => 'ÖZEL MODEL';

  @override
  String get enableCustomModel => 'Özel modeli etkinleştir';

  @override
  String get useLocalTfliteFile => 'Yerel bir .tflite model dosyası kullanın';

  @override
  String get modelFile => 'Model dosyası';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String get labelFileOptional => 'Etiket dosyası (isteğe bağlı)';

  @override
  String get defaultCocoLabels => 'Varsayılan COCO etiketleri';

  @override
  String get clearCustomFiles => 'Özel dosyaları temizle';

  @override
  String get customModelHint =>
      'İpucu: Aynı çıktı düzenine sahip bir YOLO TFLite modeli kullanın.\nEtiket dosyası sağlanmazsa COCO etiketleri kullanılır.';

  @override
  String get sectionDetectionThresholds => 'TESPİT EŞİKLERİ';

  @override
  String get confidenceThreshold => 'Güven Eşiği';

  @override
  String get confidenceThresholdDesc =>
      'Tespiti kabul etmek için minimum olasılık skoru.';

  @override
  String get iouThreshold => 'IOU Eşiği';

  @override
  String get iouThresholdDesc =>
      'Filtreleme için Kesişim/Birleşim (IoU) üst sınırı.';

  @override
  String get sectionPostProcessing => 'SON İŞLEME';

  @override
  String get nonMaxSuppression => 'Non-Max Suppression';

  @override
  String get suppressDuplicateBoxes => 'Yinelenen kutuları engelle';

  @override
  String get maxDetections => 'Maks. Tespit';

  @override
  String get perFrame => 'Tek kare başına';

  @override
  String get sectionProcessingResolution => 'İŞLEME ÇÖZÜNÜRLÜĞÜ';

  @override
  String get resetToDefaults => 'Varsayılana Sıfırla';

  @override
  String get pleaseSelectTfliteFile => 'Lütfen bir .tflite dosyası seçin.';

  @override
  String get customModelSelected => 'Özel model seçildi.';

  @override
  String get pleaseSelectTxtFile => 'Lütfen bir .txt etiket dosyası seçin.';

  @override
  String get labelFileSelected => 'Etiket dosyası seçildi.';

  @override
  String get customModelCleared => 'Özel model temizlendi.';

  @override
  String get choose => 'Seç';

  @override
  String get enterNumber => 'Sayı girin';

  @override
  String get rangeOneToFiveHundred => '1 – 500';

  @override
  String get detectionPreferences => 'Tespit Tercihleri';

  @override
  String get reset => 'Sıfırla';

  @override
  String get whatToDetect => 'Ne aramalıyız?';

  @override
  String get selectCategoriesDesc =>
      'Yapay zekanın fotoğraflarınızda tanımasını istediğiniz kategorileri seçin.';

  @override
  String get searchCategories => 'Kategori ara...';

  @override
  String get noCategoryFound => 'Arama kriterine uygun kategori bulunamadı.';

  @override
  String get partiallySelected => 'Kısmen seçili';

  @override
  String goToCamera(int count) {
    return 'Kamera\'ya Geç  •  $count sınıf seçili';
  }

  @override
  String get profile => 'Profil';

  @override
  String get defaultUserName => 'YOLO Mobile Kullanıcı';

  @override
  String get localProfileOnDevice => 'Yerel profil • Cihaz üstü tespit';

  @override
  String get selectedClasses => 'Seçili Sınıf';

  @override
  String get category => 'Kategori';

  @override
  String get detectionStatus => 'Tespit Durumu';

  @override
  String get model => 'Model';

  @override
  String get ready => 'Hazır';

  @override
  String get notReady => 'Hazır değil';

  @override
  String get modelIdLabel => 'Model kimliği';

  @override
  String get customTfliteLink => 'Özel (.tflite) ↗';

  @override
  String get resolution => 'Çözünürlük';

  @override
  String get nms => 'NMS';

  @override
  String get statusOn => 'Açık';

  @override
  String get statusOff => 'Kapalı';

  @override
  String get quickActions => 'Hızlı İşlemler';

  @override
  String get editDetectionPreferences => 'Tespit Tercihlerini Düzenle';

  @override
  String get modelAndPerformanceSettings => 'Model ve Performans Ayarları';

  @override
  String get resetSettingsToDefaults => 'Ayarları Varsayılana Sıfırla';

  @override
  String get resetSettingsTitle => 'Ayarları sıfırla';

  @override
  String get resetSettingsConfirmation =>
      'Tüm tespit tercihleri varsayılan değerlere dönecek. Devam edilsin mi?';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get settingsResetSuccess => 'Ayarlar varsayılan değerlere sıfırlandı.';

  @override
  String get resolutionFast => 'Hızlı';

  @override
  String get resolutionBalanced => 'Dengeli';

  @override
  String get resolutionQuality => 'Kalite';

  @override
  String get resolutionMax => 'Maksimum';

  @override
  String get categoryVehicles => 'Araçlar';

  @override
  String get categoryTransportInfra => 'Ulaşım & Altyapı';

  @override
  String get categoryAnimals => 'Hayvanlar';

  @override
  String get categoryElectronics => 'Elektronik';

  @override
  String get categoryFurniture => 'Mobilya';

  @override
  String get categoryClothing => 'Giyim & Aksesuar';

  @override
  String get categorySports => 'Spor & Outdoor';

  @override
  String get categoryKitchen => 'Mutfak & Sofra';

  @override
  String get categoryFood => 'Yiyecek';

  @override
  String get categoryHomeAppliances => 'Ev Aletleri';

  @override
  String get categoryHousehold => 'Ev Eşyaları';

  @override
  String get categoryPlants => 'Bitkiler';

  @override
  String get modelImportWizardTitle => 'Özel Model İçe Aktar';

  @override
  String get wizardStepFormat => 'Gereksinimler';

  @override
  String get wizardStepModel => 'Model Dosyası';

  @override
  String get wizardStepLabels => 'Etiketler';

  @override
  String get wizardStepSummary => 'Özet';

  @override
  String get formatRequirementsTitle => 'Model Gereksinimleri';

  @override
  String get formatRequirementsBody =>
      'İçe aktarmadan önce modelinizin aşağıdaki gereksinimleri karşıladığından emin olun:';

  @override
  String get formatReqTflite => 'TensorFlow Lite (.tflite) formatı';

  @override
  String get formatReqInput =>
      'Giriş tensörü: [1, Yükseklik, Genişlik, 3] — INT8 veya FLOAT32';

  @override
  String get formatReqOutput =>
      'Çıkış tensörü: [1, Kanal, Tespit] — YOLO düzeni (cx, cy, w, h + sınıf skorları)';

  @override
  String get formatReqLabels =>
      'Etiket dosyası: düz .txt, her satırda bir sınıf adı (ör. kişi, araba, köpek)';

  @override
  String get formatReqLabelsNote =>
      'Etiket dosyasındaki satır sayısı, modeldeki sınıf sayısıyla eşleşmelidir.';

  @override
  String get wizardContinue => 'Devam Et';

  @override
  String get wizardBack => 'Geri';

  @override
  String get wizardSelectModelFile => 'Model Dosyası Seç';

  @override
  String get wizardSelectModelDesc =>
      'Cihazınızdan bir .tflite dosyası ya da model ve labels.txt içeren bir .zip seçin.';

  @override
  String get wizardValidating => 'Model doğrulanıyor…';

  @override
  String get wizardModelValid => 'Model başarıyla doğrulandı';

  @override
  String wizardModelInputSize(int width, int height) {
    return 'Giriş boyutu: $width×$height';
  }

  @override
  String wizardModelClasses(int count) {
    return 'Sınıf sayısı: $count';
  }

  @override
  String wizardModelQuantType(String type) {
    return 'Kuantizasyon: $type';
  }

  @override
  String get wizardErrorFileNotFound =>
      'Seçilen dosya bulunamadı. Lütfen tekrar deneyin.';

  @override
  String get wizardErrorNotValidTflite =>
      'Bu dosya geçerli bir TensorFlow Lite modeli değil. Lütfen bir .tflite dosyası seçin.';

  @override
  String get wizardErrorInputShape =>
      'Desteklenmeyen giriş şekli. Model [1, Y, G, 3] girişi kabul etmelidir.';

  @override
  String get wizardErrorInputType =>
      'Desteklenmeyen giriş tipi. Yalnızca INT8 ve FLOAT32 modeller destekleniyor.';

  @override
  String get wizardErrorOutputShape =>
      'Desteklenmeyen çıkış şekli. YOLO tarzı [1, Kanal, Tespit] çıkışı bekleniyor.';

  @override
  String get wizardErrorOutputType =>
      'Desteklenmeyen çıkış tipi. Yalnızca INT8 ve FLOAT32 çıkışlar destekleniyor.';

  @override
  String get wizardLabelStepTitle => 'Etiket Dosyası';

  @override
  String wizardLabelStepDesc(int count) {
    return 'Bu model $count sınıf tespit ediyor. Eşleşen bir etiket dosyası sağlayabilir veya varsayılan COCO etiketlerini kullanabilirsiniz.';
  }

  @override
  String get wizardSelectLabelFile => 'Etiket Dosyası Seç (.txt)';

  @override
  String get wizardUseCocoLabels =>
      'Varsayılan COCO etiketlerini kullan (80 sınıf)';

  @override
  String wizardLabelFileValid(int count) {
    return 'Etiket dosyası geçerli — $count sınıf yüklendi';
  }

  @override
  String wizardLabelCountMismatch(int fileCount, int modelCount) {
    return 'Etiket sayısı uyuşmuyor: dosyada $fileCount etiket var ama model $modelCount bekliyor.';
  }

  @override
  String get wizardLabelFileNotFound =>
      'Etiket dosyası bulunamadı. Lütfen başka bir dosya seçin.';

  @override
  String get wizardLabelReadError =>
      'Etiket dosyası okunamadı. Lütfen dosyayı kontrol edip tekrar deneyin.';

  @override
  String wizardCocoWarning(int count) {
    return 'Varsayılan COCO etiketleri 80 sınıf içerir. Modeliniz $count sınıf bekliyor — etiketler doğru eşleşmeyebilir.';
  }

  @override
  String get wizardSummaryTitle => 'İçe Aktarım Özeti';

  @override
  String get wizardSummaryModel => 'Model';

  @override
  String get wizardSummaryInputSize => 'Giriş Boyutu';

  @override
  String get wizardSummaryClassCount => 'Sınıf Sayısı';

  @override
  String get wizardSummaryQuantization => 'Kuantizasyon';

  @override
  String get wizardSummaryLabelSource => 'Etiket Kaynağı';

  @override
  String get wizardLabelSourceCustom => 'Özel etiket dosyası';

  @override
  String get wizardLabelSourceCoco => 'Varsayılan COCO etiketleri';

  @override
  String get wizardActivateModel => 'Modeli Etkinleştir';

  @override
  String get wizardImportSuccess =>
      'Özel model içe aktarıldı ve etkinleştirildi.';

  @override
  String get wizardChangeModel => 'Modeli Değiştir';

  @override
  String get wizardRemoveModel => 'Özel Modeli Kaldır';

  @override
  String get wizardRemoveConfirm =>
      'Özel model kaldırılıp yerleşik model geri yüklensin mi?';

  @override
  String get wizardRemove => 'Kaldır';

  @override
  String get wizardActiveModelInfo => 'Aktif Özel Model';

  @override
  String get wizardImportNewModel => 'Kendi Modelinizi Yükleyin';

  @override
  String get wizardImportNewModelDesc =>
      'Tespit için özel bir YOLO TFLite modeli kullanın.';

  @override
  String get wizardNoCustomModel =>
      'Özel model yüklenmedi. Yerleşik YOLOv26 Nano modeli kullanılıyor.';

  @override
  String customModelInputSize(int width, int height) {
    return '$width×$height';
  }

  @override
  String customModelClassCount(int count) {
    return '$count sınıf';
  }

  @override
  String get navMarketplace => 'Mağaza';

  @override
  String get marketplaceTitle => 'Model Mağazası';

  @override
  String get marketplaceSearchHint => 'Model ara...';

  @override
  String get marketplaceNoResults => 'Model bulunamadı';

  @override
  String get marketplaceNoResultsHint =>
      'Arama veya filtreleri değiştirmeyi deneyin';

  @override
  String get marketplaceRetry => 'Tekrar Dene';

  @override
  String get marketplacePublish => 'Yayınla';

  @override
  String get marketplaceSignIn => 'Giriş Yap';

  @override
  String get marketplaceSortNewest => 'En Yeni';

  @override
  String get marketplaceSortDownloads => 'En Çok İndirilen';

  @override
  String get marketplaceSortRating => 'En Yüksek Puan';

  @override
  String get marketplaceDownloadModel => 'Modeli İndir';

  @override
  String get marketplaceRetryDownload => 'İndirmeyi Tekrar Dene';

  @override
  String get marketplaceActivateModel => 'Modeli Etkinleştir';

  @override
  String marketplaceModelActivated(String name) {
    return '$name etkinleştirildi!';
  }

  @override
  String get marketplaceDeleteModel => 'Modeli Sil';

  @override
  String marketplaceDeleteConfirm(String name) {
    return '$name için indirilen dosyayı kaldırmak istiyor musunuz?';
  }

  @override
  String get marketplaceValidating => 'Model doğrulanıyor...';

  @override
  String get marketplaceLargeFileTitle => 'Büyük Dosya';

  @override
  String marketplaceLargeFileMsg(String size) {
    return 'Bu model $size boyutunda. Wi-Fi bağlantısı yok. Yine de devam edilsin mi?';
  }

  @override
  String get marketplaceDownload => 'İndir';

  @override
  String get marketplaceCancel => 'İptal';

  @override
  String get marketplaceDelete => 'Sil';

  @override
  String get marketplaceReviews => 'Yorumlar';

  @override
  String get marketplaceNoReviews => 'Henüz yorum yok. İlk yorumu siz yazın!';

  @override
  String get marketplaceSignInToReview => 'Yorum yazmak için giriş yapın';

  @override
  String get marketplaceWriteReview => 'Yorumunuzu yazın...';

  @override
  String get marketplaceSubmit => 'Gönder';

  @override
  String get marketplaceDescription => 'Açıklama';

  @override
  String get marketplaceLicense => 'Lisans';

  @override
  String get marketplacePublished => 'Yayınlanma';

  @override
  String get marketplaceUpdated => 'Güncelleme';

  @override
  String get marketplaceDownloads => 'İndirmeler';

  @override
  String get marketplaceSize => 'Boyut';

  @override
  String get marketplaceComingSoon => 'Yayınlama özelliği yakında!';

  @override
  String get authLoginTitle => 'Hoş Geldiniz';

  @override
  String get authLoginSubtitle => 'Mağazaya erişmek için giriş yapın';

  @override
  String get authRegisterTitle => 'Hesap Oluştur';

  @override
  String get authRegisterSubtitle => 'AI model topluluğuna katılın';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authUsername => 'Kullanıcı Adı';

  @override
  String get authSignIn => 'Giriş Yap';

  @override
  String get authSignUp => 'Hesap Oluştur';

  @override
  String get authSwitchToRegister => 'Hesabınız yok mu? Kayıt olun';

  @override
  String get authSwitchToLogin => 'Zaten hesabınız var mı? Giriş yapın';

  @override
  String get authEmailRequired => 'E-posta gereklidir';

  @override
  String get authPasswordRequired => 'Şifre gereklidir';

  @override
  String get authUsernameRequired => 'Kullanıcı adı gereklidir';

  @override
  String get authPasswordTooShort => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get authMarketplaceTitle => 'AI Model Mağazası';

  @override
  String get authInvalidEmail => 'Lütfen geçerli bir e-posta girin';

  @override
  String get authUsernameTooShort => 'Kullanıcı adı en az 3 karakter olmalıdır';

  @override
  String get authJoinCommunity => 'AI model topluluğuna katılın';

  @override
  String get profileMarketplace => 'Mağaza';

  @override
  String get profileSignInToPublish =>
      'Model yayınlamak ve indirmek için giriş yapın';

  @override
  String get profileMarketplaceAccount => 'Mağaza Hesabı';

  @override
  String get profileSignOut => 'Çıkış Yap';

  @override
  String get profileDownloadedModels => 'İndirilen Modeller';

  @override
  String get profileActivate => 'Etkinleştir';

  @override
  String get authForgotPassword => 'Şifremi Unuttum?';

  @override
  String get authResetPasswordTitle => 'Şifre Sıfırla';

  @override
  String get authResetPasswordDesc =>
      'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.';

  @override
  String get authResetPasswordSend => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get authResetPasswordSent =>
      'Şifre sıfırlama e-postası gönderildi! Gelen kutunuzu kontrol edin.';

  @override
  String get authCheckEmail => 'E-postanızı Kontrol Edin';

  @override
  String get authCheckEmailDesc =>
      'Hesabınıza bir doğrulama bağlantısı gönderdik. Devam etmek için e-postanızı doğrulayın.';

  @override
  String get authCheckEmailOk => 'Tamam, Anladım';

  @override
  String get authUsernameMinLength =>
      'Kullanıcı adı en az 3 karakter olmalıdır';

  @override
  String get liveMode => 'Canlı';

  @override
  String get captureMode => 'Çekim';

  @override
  String get liveDetection => 'Canlı Tespit';

  @override
  String get liveDetectionOn => 'Gerçek zamanlı tespit aktif';

  @override
  String get liveDetectionOff => 'Canlı tespit durduruldu';

  @override
  String fpsDisplay(String fps) {
    return '$fps FPS';
  }

  @override
  String objectsDetected(int count) {
    return '$count nesne tespit edildi';
  }

  @override
  String get historyTitle => 'Tespit Geçmişi';

  @override
  String get historyEmpty => 'Henüz tespit yok';

  @override
  String get historyEmptyHint => 'Tespit edilen fotoğraflar burada görünecek';

  @override
  String get historyClearAll => 'Tümünü Temizle';

  @override
  String get historyClearConfirm =>
      'Tüm tespit geçmişi silinsin mi? Bu işlem geri alınamaz.';

  @override
  String get historyDelete => 'Sil';

  @override
  String historyObjectCount(int count) {
    return '$count nesne';
  }

  @override
  String historyInferenceTime(int ms) {
    return '${ms}ms çıkarım';
  }

  @override
  String get batchTitle => 'Toplu Tespit';

  @override
  String get batchSelectImages => 'Resim Seç';

  @override
  String batchProcessing(int current, int total) {
    return '$total’den $current işleniyor...';
  }

  @override
  String get batchComplete => 'Toplu tespit tamamlandı';

  @override
  String batchSummary(int images, int objects) {
    return '$images resim işlendi, $objects nesne tespit edildi';
  }

  @override
  String get batchNoImages => 'Resim seçilmedi';

  @override
  String get batchNoImagesHint =>
      'Galeriden fotoğraf seçmek için yukarıdaki düğmeye dokunun';

  @override
  String get batchStartProcessing => 'Tespiti Başlat';

  @override
  String get modelsTitle => 'Modeller';

  @override
  String get modelActive => 'Aktif';

  @override
  String get modelUse => 'Bu modeli kullan';

  @override
  String get modelBuiltIn => 'Yerleşik';

  @override
  String get modelDelete => 'Sil';

  @override
  String modelDeleteConfirm(String name) {
    return '\"$name\" bu cihazdan silinsin mi?';
  }

  @override
  String get modelDeleted => 'Model silindi.';

  @override
  String get modelImportFromFile => 'Dosyadan içe aktar';

  @override
  String get modelImportFromUrl => 'Bağlantıdan içe aktar';

  @override
  String get modelUrlDialogTitle => 'Model indir';

  @override
  String get modelUrlHint => 'https://example.com/model.tflite';

  @override
  String get modelUrlInvalid => 'Geçerli bir http(s) bağlantısı girin.';

  @override
  String get modelDownload => 'İndir';

  @override
  String get modelDownloading => 'İndiriliyor…';

  @override
  String get modelValidating => 'Model kontrol ediliyor…';

  @override
  String modelDownloadFailed(String error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get modelLoadFailed => 'Aktif model yüklenemedi.';

  @override
  String get modelSourceFile => 'İçe aktarılan dosya';

  @override
  String get modelSourceUrl => 'Bağlantıdan indirildi';

  @override
  String get modelSourceMarketplace => 'Pazaryeri';

  @override
  String get wizardErrorNotZip => 'Bu dosya geçerli bir .zip paketi değil.';

  @override
  String get wizardErrorZipNoModel => 'Bu .zip içinde .tflite modeli yok.';

  @override
  String get benchmarkTitle => 'Performans testi';

  @override
  String get benchmarkIntro =>
      'Bu modelin bu cihazda her hızlandırıcıyla ne kadar hızlı çalıştığını ölçer. Bitene kadar uygulamayı açık tutun; çalışırken ekran takılabilir.';

  @override
  String get benchmarkRun => 'Testi başlat';

  @override
  String get benchmarkRunAgain => 'Tekrar çalıştır';

  @override
  String get benchmarkRunning => 'Çalışıyor…';

  @override
  String get benchmarkMedian => 'Medyan';

  @override
  String get benchmarkMean => 'Ortalama';

  @override
  String get benchmarkP90 => 'p90';

  @override
  String get benchmarkMin => 'En hızlı';

  @override
  String get benchmarkLoad => 'Yükleme';

  @override
  String get benchmarkNative => 'TFLite içinde';

  @override
  String benchmarkRanOn(String delegate) {
    return 'Bunun yerine $delegate üzerinde çalıştı';
  }

  @override
  String benchmarkFailed(String error) {
    return 'Başarısız: $error';
  }

  @override
  String get benchmarkShareText => 'Özeti paylaş';

  @override
  String get benchmarkShareJson => 'JSON olarak paylaş';

  @override
  String get benchmarkAccelCpu => 'CPU';

  @override
  String get benchmarkAccelGpu => 'GPU';

  @override
  String get benchmarkAccelNnapi => 'NNAPI';

  @override
  String get benchmarkAccelAuto => 'Otomatik';

  @override
  String get compareTitle => 'Modelleri karşılaştır';

  @override
  String get compareModelA => 'Model A';

  @override
  String get compareModelB => 'Model B';

  @override
  String get compareChooseImage => 'Görsel seç';

  @override
  String get compareChangeImage => 'Görseli değiştir';

  @override
  String get compareRun => 'Karşılaştır';

  @override
  String get compareNeedMore =>
      'İki modeli yan yana karşılaştırmak için ikinci bir model içe aktarın.';

  @override
  String compareResult(int count, int ms) {
    return '$count nesne · $ms ms';
  }

  @override
  String compareFailed(String model, String error) {
    return '$model çalıştırılamadı: $error';
  }

  @override
  String get exportTitle => 'Dışa aktar';

  @override
  String get exportJson => 'JSON olarak paylaş';

  @override
  String get exportCsv => 'CSV olarak paylaş';

  @override
  String get exportImage => 'Kutulu görseli paylaş';

  @override
  String exportFailed(String error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String get navModels => 'Modeller';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get onboardingTitle => 'Telefonunuzda nesne tespiti';

  @override
  String get onboardingPrivacyTitle => 'Tasarımdan gizli';

  @override
  String get onboardingPrivacyBody =>
      'Her şey cihazınızda çalışır. Fotoğraflarınız cihazdan çıkmaz ve hesap gerekmez.';

  @override
  String get onboardingModelsTitle => 'Kendi modelinizi getirin';

  @override
  String get onboardingModelsBody =>
      'Yerleşik modelle başlayın ya da kendi YOLO modelinizi içe aktarıp bu telefonda ne kadar hızlı çalıştığını test edin.';

  @override
  String get onboardingCameraTitle => 'Kamera erişimi';

  @override
  String get onboardingCameraBody =>
      'Kamera yalnızca canlı tespit ve fotoğraf için kullanılır. Android, ilk açılışta izin ister. Galerinizden resim de seçebilirsiniz.';

  @override
  String get onboardingStart => 'Başlayın';

  @override
  String get cameraPermissionDenied =>
      'Kamera erişimi kapalı. Telefonunuzun ayarlarından izin verin ya da bunun yerine galeriden bir resim seçin.';
}
