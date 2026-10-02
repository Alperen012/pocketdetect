import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Application title shown in task switcher
  ///
  /// In en, this message translates to:
  /// **'YOLO Mobile'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get navCapture;

  /// No description provided for @navPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get navPreferences;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the camera only when you want. A fast and controlled detection flow starts here.'**
  String get dashboardSubtitle;

  /// No description provided for @activeDetectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Active Detection Profile'**
  String get activeDetectionProfile;

  /// No description provided for @selectedClassCount.
  ///
  /// In en, this message translates to:
  /// **'Selected classes: {count}'**
  String selectedClassCount(int count);

  /// No description provided for @resolutionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {label}'**
  String resolutionDisplay(String label);

  /// No description provided for @thresholdDisplay.
  ///
  /// In en, this message translates to:
  /// **'Threshold: {value}'**
  String thresholdDisplay(String value);

  /// No description provided for @editPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get editPreferences;

  /// No description provided for @areYouReady.
  ///
  /// In en, this message translates to:
  /// **'Are you ready?'**
  String get areYouReady;

  /// No description provided for @cameraStartsOnTap.
  ///
  /// In en, this message translates to:
  /// **'The camera starts only when you tap the button.'**
  String get cameraStartsOnTap;

  /// No description provided for @startCamera.
  ///
  /// In en, this message translates to:
  /// **'Start Camera'**
  String get startCamera;

  /// No description provided for @lowMemoryModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Low memory mode enabled.'**
  String get lowMemoryModeEnabled;

  /// No description provided for @cameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera could not be initialized'**
  String get cameraInitFailed;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo.'**
  String get photoCaptureFailed;

  /// No description provided for @noClassesSelected.
  ///
  /// In en, this message translates to:
  /// **'No classes selected'**
  String get noClassesSelected;

  /// No description provided for @detectingLabels.
  ///
  /// In en, this message translates to:
  /// **'Detecting: {labels}'**
  String detectingLabels(String labels);

  /// No description provided for @detectingLabelsMore.
  ///
  /// In en, this message translates to:
  /// **'Detecting: {first} +{count} more'**
  String detectingLabelsMore(String first, int count);

  /// No description provided for @lowMemoryMode.
  ///
  /// In en, this message translates to:
  /// **'Low memory mode'**
  String get lowMemoryMode;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @flipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip Camera'**
  String get flipCamera;

  /// No description provided for @classCount.
  ///
  /// In en, this message translates to:
  /// **'{count} classes'**
  String classCount(int count);

  /// No description provided for @detectionResults.
  ///
  /// In en, this message translates to:
  /// **'Detection Results'**
  String get detectionResults;

  /// No description provided for @analysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Analysis Summary'**
  String get analysisSummary;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @photoReadyTapToProcess.
  ///
  /// In en, this message translates to:
  /// **'Photo ready. Tap the button below to start processing.'**
  String get photoReadyTapToProcess;

  /// No description provided for @analysisError.
  ///
  /// In en, this message translates to:
  /// **'Analysis error: {error}'**
  String analysisError(String error);

  /// No description provided for @noDetectionsFound.
  ///
  /// In en, this message translates to:
  /// **'No detections found.'**
  String get noDetectionsFound;

  /// No description provided for @confidenceValue.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {value}'**
  String confidenceValue(String value);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(int count);

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get starting;

  /// No description provided for @startProcessing.
  ///
  /// In en, this message translates to:
  /// **'Start Processing'**
  String get startProcessing;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get shareResult;

  /// No description provided for @analysisInProgressWait.
  ///
  /// In en, this message translates to:
  /// **'Analysis in progress. Please wait a few seconds.'**
  String get analysisInProgressWait;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved successfully.'**
  String get reportSaved;

  /// No description provided for @reportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save report.'**
  String get reportSaveFailed;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'YOLO Mobile Detection Result'**
  String get shareSubject;

  /// No description provided for @shareFailedCopied.
  ///
  /// In en, this message translates to:
  /// **'Share could not be opened. Summary copied to clipboard.'**
  String get shareFailedCopied;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get analyzingImage;

  /// No description provided for @modelRunningOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Model is running on-device'**
  String get modelRunningOnDevice;

  /// No description provided for @analysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'Analysis in progress'**
  String get analysisInProgress;

  /// No description provided for @analysisSteps.
  ///
  /// In en, this message translates to:
  /// **'• Computing object regions\n• Evaluating confidence scores\n• Preparing results'**
  String get analysisSteps;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'YOLO Mobile Detection Report'**
  String get reportTitle;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {timestamp}'**
  String reportGenerated(String timestamp);

  /// No description provided for @reportImage.
  ///
  /// In en, this message translates to:
  /// **'Image: {path}'**
  String reportImage(String path);

  /// No description provided for @reportTotalDetections.
  ///
  /// In en, this message translates to:
  /// **'Total detections: {count}'**
  String reportTotalDetections(int count);

  /// No description provided for @reportSummaryHeader.
  ///
  /// In en, this message translates to:
  /// **'Summary:'**
  String get reportSummaryHeader;

  /// No description provided for @reportDetailedHeader.
  ///
  /// In en, this message translates to:
  /// **'Detailed Detections:'**
  String get reportDetailedHeader;

  /// No description provided for @reportBoundingBox.
  ///
  /// In en, this message translates to:
  /// **'  BBox: [{x}, {y}, {w}, {h}]'**
  String reportBoundingBox(String x, String y, String w, String h);

  /// No description provided for @showBoundingBoxes.
  ///
  /// In en, this message translates to:
  /// **'Show bounding boxes'**
  String get showBoundingBoxes;

  /// No description provided for @hideBoundingBoxes.
  ///
  /// In en, this message translates to:
  /// **'Hide bounding boxes'**
  String get hideBoundingBoxes;

  /// No description provided for @inferenceTimeMs.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String inferenceTimeMs(int ms);

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @sectionModelArchitecture.
  ///
  /// In en, this message translates to:
  /// **'MODEL ARCHITECTURE'**
  String get sectionModelArchitecture;

  /// No description provided for @activeModel.
  ///
  /// In en, this message translates to:
  /// **'Active Model'**
  String get activeModel;

  /// No description provided for @yoloNanoInt8.
  ///
  /// In en, this message translates to:
  /// **'YOLOv26 Nano (INT8)'**
  String get yoloNanoInt8;

  /// No description provided for @nanoModelDescription.
  ///
  /// In en, this message translates to:
  /// **'Nano is optimized for real-time inference on mobile devices.'**
  String get nanoModelDescription;

  /// No description provided for @customModelActiveWarning.
  ///
  /// In en, this message translates to:
  /// **'Custom model active. Built-in models disabled.'**
  String get customModelActiveWarning;

  /// No description provided for @sectionCustomModel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM MODEL'**
  String get sectionCustomModel;

  /// No description provided for @enableCustomModel.
  ///
  /// In en, this message translates to:
  /// **'Enable custom model'**
  String get enableCustomModel;

  /// No description provided for @useLocalTfliteFile.
  ///
  /// In en, this message translates to:
  /// **'Use a local .tflite model file'**
  String get useLocalTfliteFile;

  /// No description provided for @modelFile.
  ///
  /// In en, this message translates to:
  /// **'Model file'**
  String get modelFile;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @labelFileOptional.
  ///
  /// In en, this message translates to:
  /// **'Label file (optional)'**
  String get labelFileOptional;

  /// No description provided for @defaultCocoLabels.
  ///
  /// In en, this message translates to:
  /// **'Default COCO labels'**
  String get defaultCocoLabels;

  /// No description provided for @clearCustomFiles.
  ///
  /// In en, this message translates to:
  /// **'Clear custom files'**
  String get clearCustomFiles;

  /// No description provided for @customModelHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: Use a YOLO TFLite model with the same output layout.\nIf no label file is provided, COCO labels will be used.'**
  String get customModelHint;

  /// No description provided for @sectionDetectionThresholds.
  ///
  /// In en, this message translates to:
  /// **'DETECTION THRESHOLDS'**
  String get sectionDetectionThresholds;

  /// No description provided for @confidenceThreshold.
  ///
  /// In en, this message translates to:
  /// **'Confidence Threshold'**
  String get confidenceThreshold;

  /// No description provided for @confidenceThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum probability score to accept a detection.'**
  String get confidenceThresholdDesc;

  /// No description provided for @iouThreshold.
  ///
  /// In en, this message translates to:
  /// **'IOU Threshold'**
  String get iouThreshold;

  /// No description provided for @iouThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Upper limit of Intersection/Union (IoU) for filtering.'**
  String get iouThresholdDesc;

  /// No description provided for @sectionPostProcessing.
  ///
  /// In en, this message translates to:
  /// **'POST-PROCESSING'**
  String get sectionPostProcessing;

  /// No description provided for @nonMaxSuppression.
  ///
  /// In en, this message translates to:
  /// **'Non-Max Suppression'**
  String get nonMaxSuppression;

  /// No description provided for @suppressDuplicateBoxes.
  ///
  /// In en, this message translates to:
  /// **'Suppress duplicate boxes'**
  String get suppressDuplicateBoxes;

  /// No description provided for @maxDetections.
  ///
  /// In en, this message translates to:
  /// **'Max Detections'**
  String get maxDetections;

  /// No description provided for @perFrame.
  ///
  /// In en, this message translates to:
  /// **'Per frame'**
  String get perFrame;

  /// No description provided for @sectionProcessingResolution.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING RESOLUTION'**
  String get sectionProcessingResolution;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @pleaseSelectTfliteFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a .tflite file.'**
  String get pleaseSelectTfliteFile;

  /// No description provided for @customModelSelected.
  ///
  /// In en, this message translates to:
  /// **'Custom model selected.'**
  String get customModelSelected;

  /// No description provided for @pleaseSelectTxtFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a .txt label file.'**
  String get pleaseSelectTxtFile;

  /// No description provided for @labelFileSelected.
  ///
  /// In en, this message translates to:
  /// **'Label file selected.'**
  String get labelFileSelected;

  /// No description provided for @customModelCleared.
  ///
  /// In en, this message translates to:
  /// **'Custom model cleared.'**
  String get customModelCleared;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterNumber;

  /// No description provided for @rangeOneToFiveHundred.
  ///
  /// In en, this message translates to:
  /// **'1 – 500'**
  String get rangeOneToFiveHundred;

  /// No description provided for @detectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Detection Preferences'**
  String get detectionPreferences;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @whatToDetect.
  ///
  /// In en, this message translates to:
  /// **'What should we look for?'**
  String get whatToDetect;

  /// No description provided for @selectCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the categories you want the AI to recognize in your photos.'**
  String get selectCategoriesDesc;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @noCategoryFound.
  ///
  /// In en, this message translates to:
  /// **'No category matching search criteria found.'**
  String get noCategoryFound;

  /// No description provided for @partiallySelected.
  ///
  /// In en, this message translates to:
  /// **'Partially selected'**
  String get partiallySelected;

  /// No description provided for @goToCamera.
  ///
  /// In en, this message translates to:
  /// **'Go to Camera  •  {count} classes selected'**
  String goToCamera(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'YOLO Mobile User'**
  String get defaultUserName;

  /// No description provided for @localProfileOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Local profile • On-device detection'**
  String get localProfileOnDevice;

  /// No description provided for @selectedClasses.
  ///
  /// In en, this message translates to:
  /// **'Selected Classes'**
  String get selectedClasses;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @detectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Detection Status'**
  String get detectionStatus;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReady;

  /// No description provided for @modelIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelIdLabel;

  /// No description provided for @customTfliteLink.
  ///
  /// In en, this message translates to:
  /// **'Custom (.tflite) ↗'**
  String get customTfliteLink;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @nms.
  ///
  /// In en, this message translates to:
  /// **'NMS'**
  String get nms;

  /// No description provided for @statusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get statusOn;

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get statusOff;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @editDetectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit Detection Preferences'**
  String get editDetectionPreferences;

  /// No description provided for @modelAndPerformanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Model & Performance Settings'**
  String get modelAndPerformanceSettings;

  /// No description provided for @resetSettingsToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings to Defaults'**
  String get resetSettingsToDefaults;

  /// No description provided for @resetSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get resetSettingsTitle;

  /// No description provided for @resetSettingsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'All detection preferences will return to default values. Continue?'**
  String get resetSettingsConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings have been reset to defaults.'**
  String get settingsResetSuccess;

  /// No description provided for @resolutionFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get resolutionFast;

  /// No description provided for @resolutionBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get resolutionBalanced;

  /// No description provided for @resolutionQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get resolutionQuality;

  /// No description provided for @resolutionMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get resolutionMax;

  /// No description provided for @categoryVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get categoryVehicles;

  /// No description provided for @categoryTransportInfra.
  ///
  /// In en, this message translates to:
  /// **'Transport & Infrastructure'**
  String get categoryTransportInfra;

  /// No description provided for @categoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get categoryAnimals;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get categoryFurniture;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing & Accessories'**
  String get categoryClothing;

  /// No description provided for @categorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Outdoor'**
  String get categorySports;

  /// No description provided for @categoryKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen & Tableware'**
  String get categoryKitchen;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryHomeAppliances.
  ///
  /// In en, this message translates to:
  /// **'Home Appliances'**
  String get categoryHomeAppliances;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household Items'**
  String get categoryHousehold;

  /// No description provided for @categoryPlants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get categoryPlants;

  /// No description provided for @modelImportWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Custom Model'**
  String get modelImportWizardTitle;

  /// No description provided for @wizardStepFormat.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get wizardStepFormat;

  /// No description provided for @wizardStepModel.
  ///
  /// In en, this message translates to:
  /// **'Model File'**
  String get wizardStepModel;

  /// No description provided for @wizardStepLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get wizardStepLabels;

  /// No description provided for @wizardStepSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get wizardStepSummary;

  /// No description provided for @formatRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Model Requirements'**
  String get formatRequirementsTitle;

  /// No description provided for @formatRequirementsBody.
  ///
  /// In en, this message translates to:
  /// **'Before importing, make sure your model meets the following requirements:'**
  String get formatRequirementsBody;

  /// No description provided for @formatReqTflite.
  ///
  /// In en, this message translates to:
  /// **'TensorFlow Lite (.tflite) format'**
  String get formatReqTflite;

  /// No description provided for @formatReqInput.
  ///
  /// In en, this message translates to:
  /// **'Input tensor: [1, Height, Width, 3] — INT8 or FLOAT32'**
  String get formatReqInput;

  /// No description provided for @formatReqOutput.
  ///
  /// In en, this message translates to:
  /// **'Output tensor: [1, Channels, Detections] — YOLO layout (cx, cy, w, h + class scores)'**
  String get formatReqOutput;

  /// No description provided for @formatReqLabels.
  ///
  /// In en, this message translates to:
  /// **'Label file: plain .txt, one class name per line (e.g. person, car, dog)'**
  String get formatReqLabels;

  /// No description provided for @formatReqLabelsNote.
  ///
  /// In en, this message translates to:
  /// **'The number of lines in the label file must match the number of classes in the model.'**
  String get formatReqLabelsNote;

  /// No description provided for @wizardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wizardContinue;

  /// No description provided for @wizardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizardBack;

  /// No description provided for @wizardSelectModelFile.
  ///
  /// In en, this message translates to:
  /// **'Select Model File'**
  String get wizardSelectModelFile;

  /// No description provided for @wizardSelectModelDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a .tflite file from your device.'**
  String get wizardSelectModelDesc;

  /// No description provided for @wizardValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating model…'**
  String get wizardValidating;

  /// No description provided for @wizardModelValid.
  ///
  /// In en, this message translates to:
  /// **'Model validated successfully'**
  String get wizardModelValid;

  /// No description provided for @wizardModelInputSize.
  ///
  /// In en, this message translates to:
  /// **'Input size: {width}×{height}'**
  String wizardModelInputSize(int width, int height);

  /// No description provided for @wizardModelClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes: {count}'**
  String wizardModelClasses(int count);

  /// No description provided for @wizardModelQuantType.
  ///
  /// In en, this message translates to:
  /// **'Quantization: {type}'**
  String wizardModelQuantType(String type);

  /// No description provided for @wizardErrorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected file could not be found. Please try again.'**
  String get wizardErrorFileNotFound;

  /// No description provided for @wizardErrorNotValidTflite.
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid TensorFlow Lite model. Please select a .tflite file.'**
  String get wizardErrorNotValidTflite;

  /// No description provided for @wizardErrorInputShape.
  ///
  /// In en, this message translates to:
  /// **'Unsupported input shape. The model must accept [1, H, W, 3] input.'**
  String get wizardErrorInputShape;

  /// No description provided for @wizardErrorInputType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported input type. Only INT8 and FLOAT32 models are supported.'**
  String get wizardErrorInputType;

  /// No description provided for @wizardErrorOutputShape.
  ///
  /// In en, this message translates to:
  /// **'Unsupported output shape. Expected YOLO-style [1, Channels, Detections] output.'**
  String get wizardErrorOutputShape;

  /// No description provided for @wizardErrorOutputType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported output type. Only INT8 and FLOAT32 outputs are supported.'**
  String get wizardErrorOutputType;

  /// No description provided for @wizardLabelStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Label File'**
  String get wizardLabelStepTitle;

  /// No description provided for @wizardLabelStepDesc.
  ///
  /// In en, this message translates to:
  /// **'This model detects {count} classes. You can provide a matching label file or use the default COCO labels.'**
  String wizardLabelStepDesc(int count);

  /// No description provided for @wizardSelectLabelFile.
  ///
  /// In en, this message translates to:
  /// **'Select Label File (.txt)'**
  String get wizardSelectLabelFile;

  /// No description provided for @wizardUseCocoLabels.
  ///
  /// In en, this message translates to:
  /// **'Use default COCO labels (80 classes)'**
  String get wizardUseCocoLabels;

  /// No description provided for @wizardLabelFileValid.
  ///
  /// In en, this message translates to:
  /// **'Label file valid — {count} classes loaded'**
  String wizardLabelFileValid(int count);

  /// No description provided for @wizardLabelCountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Label count mismatch: file has {fileCount} labels but model expects {modelCount}.'**
  String wizardLabelCountMismatch(int fileCount, int modelCount);

  /// No description provided for @wizardLabelFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Label file not found. Please select another file.'**
  String get wizardLabelFileNotFound;

  /// No description provided for @wizardLabelReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the label file. Please check the file and try again.'**
  String get wizardLabelReadError;

  /// No description provided for @wizardCocoWarning.
  ///
  /// In en, this message translates to:
  /// **'The default COCO labels have 80 classes. Your model expects {count} — labels may not match correctly.'**
  String wizardCocoWarning(int count);

  /// No description provided for @wizardSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Summary'**
  String get wizardSummaryTitle;

  /// No description provided for @wizardSummaryModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get wizardSummaryModel;

  /// No description provided for @wizardSummaryInputSize.
  ///
  /// In en, this message translates to:
  /// **'Input Size'**
  String get wizardSummaryInputSize;

  /// No description provided for @wizardSummaryClassCount.
  ///
  /// In en, this message translates to:
  /// **'Class Count'**
  String get wizardSummaryClassCount;

  /// No description provided for @wizardSummaryQuantization.
  ///
  /// In en, this message translates to:
  /// **'Quantization'**
  String get wizardSummaryQuantization;

  /// No description provided for @wizardSummaryLabelSource.
  ///
  /// In en, this message translates to:
  /// **'Label Source'**
  String get wizardSummaryLabelSource;

  /// No description provided for @wizardLabelSourceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom label file'**
  String get wizardLabelSourceCustom;

  /// No description provided for @wizardLabelSourceCoco.
  ///
  /// In en, this message translates to:
  /// **'Default COCO labels'**
  String get wizardLabelSourceCoco;

  /// No description provided for @wizardActivateModel.
  ///
  /// In en, this message translates to:
  /// **'Activate Model'**
  String get wizardActivateModel;

  /// No description provided for @wizardImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Custom model imported and activated.'**
  String get wizardImportSuccess;

  /// No description provided for @wizardChangeModel.
  ///
  /// In en, this message translates to:
  /// **'Change Model'**
  String get wizardChangeModel;

  /// No description provided for @wizardRemoveModel.
  ///
  /// In en, this message translates to:
  /// **'Remove Custom Model'**
  String get wizardRemoveModel;

  /// No description provided for @wizardRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the custom model and restore the built-in model?'**
  String get wizardRemoveConfirm;

  /// No description provided for @wizardRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get wizardRemove;

  /// No description provided for @wizardActiveModelInfo.
  ///
  /// In en, this message translates to:
  /// **'Active Custom Model'**
  String get wizardActiveModelInfo;

  /// No description provided for @wizardImportNewModel.
  ///
  /// In en, this message translates to:
  /// **'Import Your Own Model'**
  String get wizardImportNewModel;

  /// No description provided for @wizardImportNewModelDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a custom YOLO TFLite model for detection.'**
  String get wizardImportNewModelDesc;

  /// No description provided for @wizardNoCustomModel.
  ///
  /// In en, this message translates to:
  /// **'No custom model loaded. Using the built-in YOLOv26 Nano model.'**
  String get wizardNoCustomModel;

  /// No description provided for @customModelInputSize.
  ///
  /// In en, this message translates to:
  /// **'{width}×{height}'**
  String customModelInputSize(int width, int height);

  /// No description provided for @customModelClassCount.
  ///
  /// In en, this message translates to:
  /// **'{count} classes'**
  String customModelClassCount(int count);

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get navMarketplace;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Model Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search models...'**
  String get marketplaceSearchHint;

  /// No description provided for @marketplaceNoResults.
  ///
  /// In en, this message translates to:
  /// **'No models found'**
  String get marketplaceNoResults;

  /// No description provided for @marketplaceNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get marketplaceNoResultsHint;

  /// No description provided for @marketplaceRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get marketplaceRetry;

  /// No description provided for @marketplacePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get marketplacePublish;

  /// No description provided for @marketplaceSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get marketplaceSignIn;

  /// No description provided for @marketplaceSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get marketplaceSortNewest;

  /// No description provided for @marketplaceSortDownloads.
  ///
  /// In en, this message translates to:
  /// **'Most Downloaded'**
  String get marketplaceSortDownloads;

  /// No description provided for @marketplaceSortRating.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get marketplaceSortRating;

  /// No description provided for @marketplaceDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'Download Model'**
  String get marketplaceDownloadModel;

  /// No description provided for @marketplaceRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry Download'**
  String get marketplaceRetryDownload;

  /// No description provided for @marketplaceActivateModel.
  ///
  /// In en, this message translates to:
  /// **'Activate Model'**
  String get marketplaceActivateModel;

  /// No description provided for @marketplaceModelActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} activated!'**
  String marketplaceModelActivated(String name);

  /// No description provided for @marketplaceDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get marketplaceDeleteModel;

  /// No description provided for @marketplaceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the downloaded file for {name}?'**
  String marketplaceDeleteConfirm(String name);

  /// No description provided for @marketplaceValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating model...'**
  String get marketplaceValidating;

  /// No description provided for @marketplaceLargeFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Large File'**
  String get marketplaceLargeFileTitle;

  /// No description provided for @marketplaceLargeFileMsg.
  ///
  /// In en, this message translates to:
  /// **'This model is {size}. You are not on Wi-Fi. Continue anyway?'**
  String marketplaceLargeFileMsg(String size);

  /// No description provided for @marketplaceDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get marketplaceDownload;

  /// No description provided for @marketplaceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get marketplaceCancel;

  /// No description provided for @marketplaceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get marketplaceDelete;

  /// No description provided for @marketplaceReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get marketplaceReviews;

  /// No description provided for @marketplaceNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first!'**
  String get marketplaceNoReviews;

  /// No description provided for @marketplaceSignInToReview.
  ///
  /// In en, this message translates to:
  /// **'Sign in to write a review'**
  String get marketplaceSignInToReview;

  /// No description provided for @marketplaceWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write your review...'**
  String get marketplaceWriteReview;

  /// No description provided for @marketplaceSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get marketplaceSubmit;

  /// No description provided for @marketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get marketplaceDescription;

  /// No description provided for @marketplaceLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get marketplaceLicense;

  /// No description provided for @marketplacePublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get marketplacePublished;

  /// No description provided for @marketplaceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get marketplaceUpdated;

  /// No description provided for @marketplaceDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get marketplaceDownloads;

  /// No description provided for @marketplaceSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get marketplaceSize;

  /// No description provided for @marketplaceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Publish feature coming soon!'**
  String get marketplaceComingSoon;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access the marketplace'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the AI model community'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignUp;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authSwitchToRegister;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToLogin;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get authUsernameRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Model Marketplace'**
  String get authMarketplaceTitle;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get authUsernameTooShort;

  /// No description provided for @authJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the community of AI model creators'**
  String get authJoinCommunity;

  /// No description provided for @profileMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get profileMarketplace;

  /// No description provided for @profileSignInToPublish.
  ///
  /// In en, this message translates to:
  /// **'Sign in to publish and download models'**
  String get profileSignInToPublish;

  /// No description provided for @profileMarketplaceAccount.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Account'**
  String get profileMarketplaceAccount;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileDownloadedModels.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Models'**
  String get profileDownloadedModels;

  /// No description provided for @profileActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get profileActivate;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get authResetPasswordDesc;

  /// No description provided for @authResetPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authResetPasswordSend;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get authResetPasswordSent;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get authCheckEmail;

  /// No description provided for @authCheckEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation link to your email. Please verify your account to continue.'**
  String get authCheckEmailDesc;

  /// No description provided for @authCheckEmailOk.
  ///
  /// In en, this message translates to:
  /// **'OK, Got It'**
  String get authCheckEmailOk;

  /// No description provided for @authUsernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get authUsernameMinLength;

  /// No description provided for @liveMode.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveMode;

  /// No description provided for @captureMode.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureMode;

  /// No description provided for @liveDetection.
  ///
  /// In en, this message translates to:
  /// **'Live Detection'**
  String get liveDetection;

  /// No description provided for @liveDetectionOn.
  ///
  /// In en, this message translates to:
  /// **'Real-time detection active'**
  String get liveDetectionOn;

  /// No description provided for @liveDetectionOff.
  ///
  /// In en, this message translates to:
  /// **'Live detection paused'**
  String get liveDetectionOff;

  /// No description provided for @fpsDisplay.
  ///
  /// In en, this message translates to:
  /// **'{fps} FPS'**
  String fpsDisplay(String fps);

  /// No description provided for @objectsDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} objects detected'**
  String objectsDetected(int count);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Detection History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No detections yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Captured photos with detections will appear here'**
  String get historyEmptyHint;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all detection history? This cannot be undone.'**
  String get historyClearConfirm;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// No description provided for @historyObjectCount.
  ///
  /// In en, this message translates to:
  /// **'{count} objects'**
  String historyObjectCount(int count);

  /// No description provided for @historyInferenceTime.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms inference'**
  String historyInferenceTime(int ms);

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Detection'**
  String get batchTitle;

  /// No description provided for @batchSelectImages.
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get batchSelectImages;

  /// No description provided for @batchProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing {current} of {total}...'**
  String batchProcessing(int current, int total);

  /// No description provided for @batchComplete.
  ///
  /// In en, this message translates to:
  /// **'Batch complete'**
  String get batchComplete;

  /// No description provided for @batchSummary.
  ///
  /// In en, this message translates to:
  /// **'{images} images processed, {objects} objects detected'**
  String batchSummary(int images, int objects);

  /// No description provided for @batchNoImages.
  ///
  /// In en, this message translates to:
  /// **'No images selected'**
  String get batchNoImages;

  /// No description provided for @batchNoImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button above to select photos from your gallery'**
  String get batchNoImagesHint;

  /// No description provided for @batchStartProcessing.
  ///
  /// In en, this message translates to:
  /// **'Run Detection'**
  String get batchStartProcessing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
