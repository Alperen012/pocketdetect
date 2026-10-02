// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YOLO Mobile';

  @override
  String get navHome => 'Home';

  @override
  String get navCapture => 'Capture';

  @override
  String get navPreferences => 'Preferences';

  @override
  String get navProfile => 'Profile';

  @override
  String get dashboardSubtitle =>
      'Open the camera only when you want. A fast and controlled detection flow starts here.';

  @override
  String get activeDetectionProfile => 'Active Detection Profile';

  @override
  String selectedClassCount(int count) {
    return 'Selected classes: $count';
  }

  @override
  String resolutionDisplay(String label) {
    return 'Resolution: $label';
  }

  @override
  String thresholdDisplay(String value) {
    return 'Threshold: $value';
  }

  @override
  String get editPreferences => 'Edit Preferences';

  @override
  String get areYouReady => 'Are you ready?';

  @override
  String get cameraStartsOnTap =>
      'The camera starts only when you tap the button.';

  @override
  String get startCamera => 'Start Camera';

  @override
  String get lowMemoryModeEnabled => 'Low memory mode enabled.';

  @override
  String get cameraInitFailed => 'Camera could not be initialized';

  @override
  String get photoCaptureFailed => 'Failed to capture photo.';

  @override
  String get noClassesSelected => 'No classes selected';

  @override
  String detectingLabels(String labels) {
    return 'Detecting: $labels';
  }

  @override
  String detectingLabelsMore(String first, int count) {
    return 'Detecting: $first +$count more';
  }

  @override
  String get lowMemoryMode => 'Low memory mode';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get flipCamera => 'Flip Camera';

  @override
  String classCount(int count) {
    return '$count classes';
  }

  @override
  String get detectionResults => 'Detection Results';

  @override
  String get analysisSummary => 'Analysis Summary';

  @override
  String get results => 'Results';

  @override
  String get photoReadyTapToProcess =>
      'Photo ready. Tap the button below to start processing.';

  @override
  String analysisError(String error) {
    return 'Analysis error: $error';
  }

  @override
  String get noDetectionsFound => 'No detections found.';

  @override
  String confidenceValue(String value) {
    return 'Confidence: $value';
  }

  @override
  String itemCount(int count) {
    return '$count items';
  }

  @override
  String get retake => 'Retake';

  @override
  String get starting => 'Starting...';

  @override
  String get startProcessing => 'Start Processing';

  @override
  String get processing => 'Processing...';

  @override
  String get save => 'Save';

  @override
  String get shareResult => 'Share Result';

  @override
  String get analysisInProgressWait =>
      'Analysis in progress. Please wait a few seconds.';

  @override
  String get reportSaved => 'Report saved successfully.';

  @override
  String get reportSaveFailed => 'Failed to save report.';

  @override
  String get shareSubject => 'YOLO Mobile Detection Result';

  @override
  String get shareFailedCopied =>
      'Share could not be opened. Summary copied to clipboard.';

  @override
  String get analyzingImage => 'Analyzing image...';

  @override
  String get modelRunningOnDevice => 'Model is running on-device';

  @override
  String get analysisInProgress => 'Analysis in progress';

  @override
  String get analysisSteps =>
      '• Computing object regions\n• Evaluating confidence scores\n• Preparing results';

  @override
  String get reportTitle => 'YOLO Mobile Detection Report';

  @override
  String reportGenerated(String timestamp) {
    return 'Generated: $timestamp';
  }

  @override
  String reportImage(String path) {
    return 'Image: $path';
  }

  @override
  String reportTotalDetections(int count) {
    return 'Total detections: $count';
  }

  @override
  String get reportSummaryHeader => 'Summary:';

  @override
  String get reportDetailedHeader => 'Detailed Detections:';

  @override
  String reportBoundingBox(String x, String y, String w, String h) {
    return '  BBox: [$x, $y, $w, $h]';
  }

  @override
  String get showBoundingBoxes => 'Show bounding boxes';

  @override
  String get hideBoundingBoxes => 'Hide bounding boxes';

  @override
  String inferenceTimeMs(int ms) {
    return '$ms ms';
  }

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get sectionModelArchitecture => 'MODEL ARCHITECTURE';

  @override
  String get activeModel => 'Active Model';

  @override
  String get yoloNanoInt8 => 'YOLOv26 Nano (INT8)';

  @override
  String get nanoModelDescription =>
      'Nano is optimized for real-time inference on mobile devices.';

  @override
  String get customModelActiveWarning =>
      'Custom model active. Built-in models disabled.';

  @override
  String get sectionCustomModel => 'CUSTOM MODEL';

  @override
  String get enableCustomModel => 'Enable custom model';

  @override
  String get useLocalTfliteFile => 'Use a local .tflite model file';

  @override
  String get modelFile => 'Model file';

  @override
  String get notSelected => 'Not selected';

  @override
  String get labelFileOptional => 'Label file (optional)';

  @override
  String get defaultCocoLabels => 'Default COCO labels';

  @override
  String get clearCustomFiles => 'Clear custom files';

  @override
  String get customModelHint =>
      'Tip: Use a YOLO TFLite model with the same output layout.\nIf no label file is provided, COCO labels will be used.';

  @override
  String get sectionDetectionThresholds => 'DETECTION THRESHOLDS';

  @override
  String get confidenceThreshold => 'Confidence Threshold';

  @override
  String get confidenceThresholdDesc =>
      'Minimum probability score to accept a detection.';

  @override
  String get iouThreshold => 'IOU Threshold';

  @override
  String get iouThresholdDesc =>
      'Upper limit of Intersection/Union (IoU) for filtering.';

  @override
  String get sectionPostProcessing => 'POST-PROCESSING';

  @override
  String get nonMaxSuppression => 'Non-Max Suppression';

  @override
  String get suppressDuplicateBoxes => 'Suppress duplicate boxes';

  @override
  String get maxDetections => 'Max Detections';

  @override
  String get perFrame => 'Per frame';

  @override
  String get sectionProcessingResolution => 'PROCESSING RESOLUTION';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get pleaseSelectTfliteFile => 'Please select a .tflite file.';

  @override
  String get customModelSelected => 'Custom model selected.';

  @override
  String get pleaseSelectTxtFile => 'Please select a .txt label file.';

  @override
  String get labelFileSelected => 'Label file selected.';

  @override
  String get customModelCleared => 'Custom model cleared.';

  @override
  String get choose => 'Choose';

  @override
  String get enterNumber => 'Enter a number';

  @override
  String get rangeOneToFiveHundred => '1 – 500';

  @override
  String get detectionPreferences => 'Detection Preferences';

  @override
  String get reset => 'Reset';

  @override
  String get whatToDetect => 'What should we look for?';

  @override
  String get selectCategoriesDesc =>
      'Select the categories you want the AI to recognize in your photos.';

  @override
  String get searchCategories => 'Search categories...';

  @override
  String get noCategoryFound => 'No category matching search criteria found.';

  @override
  String get partiallySelected => 'Partially selected';

  @override
  String goToCamera(int count) {
    return 'Go to Camera  •  $count classes selected';
  }

  @override
  String get profile => 'Profile';

  @override
  String get defaultUserName => 'YOLO Mobile User';

  @override
  String get localProfileOnDevice => 'Local profile • On-device detection';

  @override
  String get selectedClasses => 'Selected Classes';

  @override
  String get category => 'Category';

  @override
  String get detectionStatus => 'Detection Status';

  @override
  String get model => 'Model';

  @override
  String get ready => 'Ready';

  @override
  String get notReady => 'Not ready';

  @override
  String get modelIdLabel => 'Model ID';

  @override
  String get customTfliteLink => 'Custom (.tflite) ↗';

  @override
  String get resolution => 'Resolution';

  @override
  String get nms => 'NMS';

  @override
  String get statusOn => 'On';

  @override
  String get statusOff => 'Off';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get editDetectionPreferences => 'Edit Detection Preferences';

  @override
  String get modelAndPerformanceSettings => 'Model & Performance Settings';

  @override
  String get resetSettingsToDefaults => 'Reset Settings to Defaults';

  @override
  String get resetSettingsTitle => 'Reset settings';

  @override
  String get resetSettingsConfirmation =>
      'All detection preferences will return to default values. Continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsResetSuccess => 'Settings have been reset to defaults.';

  @override
  String get resolutionFast => 'Fast';

  @override
  String get resolutionBalanced => 'Balanced';

  @override
  String get resolutionQuality => 'Quality';

  @override
  String get resolutionMax => 'Maximum';

  @override
  String get categoryVehicles => 'Vehicles';

  @override
  String get categoryTransportInfra => 'Transport & Infrastructure';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryFurniture => 'Furniture';

  @override
  String get categoryClothing => 'Clothing & Accessories';

  @override
  String get categorySports => 'Sports & Outdoor';

  @override
  String get categoryKitchen => 'Kitchen & Tableware';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHomeAppliances => 'Home Appliances';

  @override
  String get categoryHousehold => 'Household Items';

  @override
  String get categoryPlants => 'Plants';

  @override
  String get modelImportWizardTitle => 'Import Custom Model';

  @override
  String get wizardStepFormat => 'Requirements';

  @override
  String get wizardStepModel => 'Model File';

  @override
  String get wizardStepLabels => 'Labels';

  @override
  String get wizardStepSummary => 'Summary';

  @override
  String get formatRequirementsTitle => 'Model Requirements';

  @override
  String get formatRequirementsBody =>
      'Before importing, make sure your model meets the following requirements:';

  @override
  String get formatReqTflite => 'TensorFlow Lite (.tflite) format';

  @override
  String get formatReqInput =>
      'Input tensor: [1, Height, Width, 3] — INT8 or FLOAT32';

  @override
  String get formatReqOutput =>
      'Output tensor: [1, Channels, Detections] — YOLO layout (cx, cy, w, h + class scores)';

  @override
  String get formatReqLabels =>
      'Label file: plain .txt, one class name per line (e.g. person, car, dog)';

  @override
  String get formatReqLabelsNote =>
      'The number of lines in the label file must match the number of classes in the model.';

  @override
  String get wizardContinue => 'Continue';

  @override
  String get wizardBack => 'Back';

  @override
  String get wizardSelectModelFile => 'Select Model File';

  @override
  String get wizardSelectModelDesc =>
      'Choose a .tflite file, or a .zip with the model and a labels.txt, from your device.';

  @override
  String get wizardValidating => 'Validating model…';

  @override
  String get wizardModelValid => 'Model validated successfully';

  @override
  String wizardModelInputSize(int width, int height) {
    return 'Input size: $width×$height';
  }

  @override
  String wizardModelClasses(int count) {
    return 'Classes: $count';
  }

  @override
  String wizardModelQuantType(String type) {
    return 'Quantization: $type';
  }

  @override
  String get wizardErrorFileNotFound =>
      'The selected file could not be found. Please try again.';

  @override
  String get wizardErrorNotValidTflite =>
      'This file is not a valid TensorFlow Lite model. Please select a .tflite file.';

  @override
  String get wizardErrorInputShape =>
      'Unsupported input shape. The model must accept [1, H, W, 3] input.';

  @override
  String get wizardErrorInputType =>
      'Unsupported input type. Only INT8 and FLOAT32 models are supported.';

  @override
  String get wizardErrorOutputShape =>
      'Unsupported output shape. Expected YOLO-style [1, Channels, Detections] output.';

  @override
  String get wizardErrorOutputType =>
      'Unsupported output type. Only INT8 and FLOAT32 outputs are supported.';

  @override
  String get wizardLabelStepTitle => 'Label File';

  @override
  String wizardLabelStepDesc(int count) {
    return 'This model detects $count classes. You can provide a matching label file or use the default COCO labels.';
  }

  @override
  String get wizardSelectLabelFile => 'Select Label File (.txt)';

  @override
  String get wizardUseCocoLabels => 'Use default COCO labels (80 classes)';

  @override
  String wizardLabelFileValid(int count) {
    return 'Label file valid — $count classes loaded';
  }

  @override
  String wizardLabelCountMismatch(int fileCount, int modelCount) {
    return 'Label count mismatch: file has $fileCount labels but model expects $modelCount.';
  }

  @override
  String get wizardLabelFileNotFound =>
      'Label file not found. Please select another file.';

  @override
  String get wizardLabelReadError =>
      'Could not read the label file. Please check the file and try again.';

  @override
  String wizardCocoWarning(int count) {
    return 'The default COCO labels have 80 classes. Your model expects $count — labels may not match correctly.';
  }

  @override
  String get wizardSummaryTitle => 'Import Summary';

  @override
  String get wizardSummaryModel => 'Model';

  @override
  String get wizardSummaryInputSize => 'Input Size';

  @override
  String get wizardSummaryClassCount => 'Class Count';

  @override
  String get wizardSummaryQuantization => 'Quantization';

  @override
  String get wizardSummaryLabelSource => 'Label Source';

  @override
  String get wizardLabelSourceCustom => 'Custom label file';

  @override
  String get wizardLabelSourceCoco => 'Default COCO labels';

  @override
  String get wizardActivateModel => 'Activate Model';

  @override
  String get wizardImportSuccess => 'Custom model imported and activated.';

  @override
  String get wizardChangeModel => 'Change Model';

  @override
  String get wizardRemoveModel => 'Remove Custom Model';

  @override
  String get wizardRemoveConfirm =>
      'Remove the custom model and restore the built-in model?';

  @override
  String get wizardRemove => 'Remove';

  @override
  String get wizardActiveModelInfo => 'Active Custom Model';

  @override
  String get wizardImportNewModel => 'Import Your Own Model';

  @override
  String get wizardImportNewModelDesc =>
      'Use a custom YOLO TFLite model for detection.';

  @override
  String get wizardNoCustomModel =>
      'No custom model loaded. Using the built-in YOLOv26 Nano model.';

  @override
  String customModelInputSize(int width, int height) {
    return '$width×$height';
  }

  @override
  String customModelClassCount(int count) {
    return '$count classes';
  }

  @override
  String get navMarketplace => 'Marketplace';

  @override
  String get marketplaceTitle => 'Model Marketplace';

  @override
  String get marketplaceSearchHint => 'Search models...';

  @override
  String get marketplaceNoResults => 'No models found';

  @override
  String get marketplaceNoResultsHint => 'Try adjusting your search or filters';

  @override
  String get marketplaceRetry => 'Retry';

  @override
  String get marketplacePublish => 'Publish';

  @override
  String get marketplaceSignIn => 'Sign In';

  @override
  String get marketplaceSortNewest => 'Newest';

  @override
  String get marketplaceSortDownloads => 'Most Downloaded';

  @override
  String get marketplaceSortRating => 'Highest Rated';

  @override
  String get marketplaceDownloadModel => 'Download Model';

  @override
  String get marketplaceRetryDownload => 'Retry Download';

  @override
  String get marketplaceActivateModel => 'Activate Model';

  @override
  String marketplaceModelActivated(String name) {
    return '$name activated!';
  }

  @override
  String get marketplaceDeleteModel => 'Delete Model';

  @override
  String marketplaceDeleteConfirm(String name) {
    return 'Remove the downloaded file for $name?';
  }

  @override
  String get marketplaceValidating => 'Validating model...';

  @override
  String get marketplaceLargeFileTitle => 'Large File';

  @override
  String marketplaceLargeFileMsg(String size) {
    return 'This model is $size. You are not on Wi-Fi. Continue anyway?';
  }

  @override
  String get marketplaceDownload => 'Download';

  @override
  String get marketplaceCancel => 'Cancel';

  @override
  String get marketplaceDelete => 'Delete';

  @override
  String get marketplaceReviews => 'Reviews';

  @override
  String get marketplaceNoReviews => 'No reviews yet. Be the first!';

  @override
  String get marketplaceSignInToReview => 'Sign in to write a review';

  @override
  String get marketplaceWriteReview => 'Write your review...';

  @override
  String get marketplaceSubmit => 'Submit';

  @override
  String get marketplaceDescription => 'Description';

  @override
  String get marketplaceLicense => 'License';

  @override
  String get marketplacePublished => 'Published';

  @override
  String get marketplaceUpdated => 'Updated';

  @override
  String get marketplaceDownloads => 'Downloads';

  @override
  String get marketplaceSize => 'Size';

  @override
  String get marketplaceComingSoon => 'Publish feature coming soon!';

  @override
  String get authLoginTitle => 'Welcome Back';

  @override
  String get authLoginSubtitle => 'Sign in to access the marketplace';

  @override
  String get authRegisterTitle => 'Create Account';

  @override
  String get authRegisterSubtitle => 'Join the AI model community';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsername => 'Username';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Create Account';

  @override
  String get authSwitchToRegister => 'Don\'t have an account? Sign up';

  @override
  String get authSwitchToLogin => 'Already have an account? Sign in';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authUsernameRequired => 'Username is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authMarketplaceTitle => 'AI Model Marketplace';

  @override
  String get authInvalidEmail => 'Please enter a valid email';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authJoinCommunity => 'Join the community of AI model creators';

  @override
  String get profileMarketplace => 'Marketplace';

  @override
  String get profileSignInToPublish => 'Sign in to publish and download models';

  @override
  String get profileMarketplaceAccount => 'Marketplace Account';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileDownloadedModels => 'Downloaded Models';

  @override
  String get profileActivate => 'Activate';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authResetPasswordTitle => 'Reset Password';

  @override
  String get authResetPasswordDesc =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get authResetPasswordSend => 'Send Reset Link';

  @override
  String get authResetPasswordSent =>
      'Password reset email sent! Check your inbox.';

  @override
  String get authCheckEmail => 'Check Your Email';

  @override
  String get authCheckEmailDesc =>
      'We\'ve sent a confirmation link to your email. Please verify your account to continue.';

  @override
  String get authCheckEmailOk => 'OK, Got It';

  @override
  String get authUsernameMinLength => 'Username must be at least 3 characters';

  @override
  String get liveMode => 'Live';

  @override
  String get captureMode => 'Capture';

  @override
  String get liveDetection => 'Live Detection';

  @override
  String get liveDetectionOn => 'Real-time detection active';

  @override
  String get liveDetectionOff => 'Live detection paused';

  @override
  String fpsDisplay(String fps) {
    return '$fps FPS';
  }

  @override
  String objectsDetected(int count) {
    return '$count objects detected';
  }

  @override
  String get historyTitle => 'Detection History';

  @override
  String get historyEmpty => 'No detections yet';

  @override
  String get historyEmptyHint =>
      'Captured photos with detections will appear here';

  @override
  String get historyClearAll => 'Clear All';

  @override
  String get historyClearConfirm =>
      'Delete all detection history? This cannot be undone.';

  @override
  String get historyDelete => 'Delete';

  @override
  String historyObjectCount(int count) {
    return '$count objects';
  }

  @override
  String historyInferenceTime(int ms) {
    return '${ms}ms inference';
  }

  @override
  String get batchTitle => 'Batch Detection';

  @override
  String get batchSelectImages => 'Select Images';

  @override
  String batchProcessing(int current, int total) {
    return 'Processing $current of $total...';
  }

  @override
  String get batchComplete => 'Batch complete';

  @override
  String batchSummary(int images, int objects) {
    return '$images images processed, $objects objects detected';
  }

  @override
  String get batchNoImages => 'No images selected';

  @override
  String get batchNoImagesHint =>
      'Tap the button above to select photos from your gallery';

  @override
  String get batchStartProcessing => 'Run Detection';

  @override
  String get modelsTitle => 'Models';

  @override
  String get modelActive => 'Active';

  @override
  String get modelUse => 'Use this model';

  @override
  String get modelBuiltIn => 'Built-in';

  @override
  String get modelDelete => 'Delete';

  @override
  String modelDeleteConfirm(String name) {
    return 'Delete \"$name\" from this device?';
  }

  @override
  String get modelDeleted => 'Model deleted.';

  @override
  String get modelImportFromFile => 'Import from file';

  @override
  String get modelImportFromUrl => 'Import from URL';

  @override
  String get modelUrlDialogTitle => 'Download a model';

  @override
  String get modelUrlHint => 'https://example.com/model.tflite';

  @override
  String get modelUrlInvalid => 'Enter a valid http(s) link.';

  @override
  String get modelDownload => 'Download';

  @override
  String get modelDownloading => 'Downloading…';

  @override
  String get modelValidating => 'Checking model…';

  @override
  String modelDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get modelLoadFailed => 'The active model could not be loaded.';

  @override
  String get modelSourceFile => 'Imported file';

  @override
  String get modelSourceUrl => 'Downloaded from a link';

  @override
  String get modelSourceMarketplace => 'Marketplace';

  @override
  String get wizardErrorNotZip => 'That file is not a valid .zip package.';

  @override
  String get wizardErrorZipNoModel =>
      'The .zip does not contain a .tflite model.';

  @override
  String get benchmarkTitle => 'Benchmark';

  @override
  String get benchmarkIntro =>
      'Measures how fast this model runs on this device with each accelerator. Keep the app open until it finishes; the screen may stutter while it runs.';

  @override
  String get benchmarkRun => 'Run benchmark';

  @override
  String get benchmarkRunAgain => 'Run again';

  @override
  String get benchmarkRunning => 'Running…';

  @override
  String get benchmarkMedian => 'Median';

  @override
  String get benchmarkMean => 'Mean';

  @override
  String get benchmarkP90 => 'p90';

  @override
  String get benchmarkMin => 'Fastest';

  @override
  String get benchmarkLoad => 'Load';

  @override
  String get benchmarkNative => 'Inside TFLite';

  @override
  String benchmarkRanOn(String delegate) {
    return 'Ran on $delegate instead';
  }

  @override
  String benchmarkFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get benchmarkShareText => 'Share summary';

  @override
  String get benchmarkShareJson => 'Share as JSON';

  @override
  String get benchmarkAccelCpu => 'CPU';

  @override
  String get benchmarkAccelGpu => 'GPU';

  @override
  String get benchmarkAccelNnapi => 'NNAPI';

  @override
  String get benchmarkAccelAuto => 'Auto';

  @override
  String get compareTitle => 'Compare models';

  @override
  String get compareModelA => 'Model A';

  @override
  String get compareModelB => 'Model B';

  @override
  String get compareChooseImage => 'Choose image';

  @override
  String get compareChangeImage => 'Change image';

  @override
  String get compareRun => 'Compare';

  @override
  String get compareNeedMore =>
      'Import a second model to compare two models side by side.';

  @override
  String compareResult(int count, int ms) {
    return '$count objects · $ms ms';
  }

  @override
  String compareFailed(String model, String error) {
    return 'Could not run $model: $error';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportJson => 'Share as JSON';

  @override
  String get exportCsv => 'Share as CSV';

  @override
  String get exportImage => 'Share annotated image';

  @override
  String exportFailed(String error) {
    return 'Could not export: $error';
  }

  @override
  String get navModels => 'Models';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingTitle => 'Detect objects on your phone';

  @override
  String get onboardingPrivacyTitle => 'Private by design';

  @override
  String get onboardingPrivacyBody =>
      'Everything runs on your device. Your photos never leave it and no account is needed.';

  @override
  String get onboardingModelsTitle => 'Bring your own model';

  @override
  String get onboardingModelsBody =>
      'Start with the built-in model, or import your own YOLO model and test how fast it runs on this phone.';

  @override
  String get onboardingCameraTitle => 'Camera access';

  @override
  String get onboardingCameraBody =>
      'The camera is used only for live detection and photos. Android asks for permission the first time you open it. You can also pick pictures from your gallery.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get cameraPermissionDenied =>
      'Camera access is off. Allow it in your phone\'s settings, or pick a picture from your gallery instead.';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get aboutLicensesDesc => 'This app is free software (AGPL-3.0)';

  @override
  String get aboutLegalese =>
      'Licensed under the GNU AGPL-3.0. The bundled model is derived from Ultralytics YOLO26 (AGPL-3.0).';
}
