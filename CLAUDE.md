# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PocketDetect: a Flutter app that runs on-device object detection with a TFLite YOLO model (photo, gallery, batch and live camera), with a model library for importing, benchmarking and comparing custom `.tflite` models. A Supabase-backed marketplace and accounts exist but are switched off by default (see Feature flags). UI strings are localized in English and Turkish; the README is in Turkish.

## Commands

```bash
flutter pub get
flutter analyze                    # lints: package:flutter_lints/flutter.yaml, no custom rules
flutter test                       # all tests
flutter test test/core/services/settings_controller_test.dart             # one file
flutter test test/widget_test.dart --plain-name "tapping camera button"   # one test by name
flutter gen-l10n                   # regenerate lib/l10n/generated after editing ARB files
```

`flutter run` works with no configuration: the marketplace is off, so nothing touches Supabase and the app needs no account or network. To turn the marketplace on, pass the flag together with credentials (the defaults in `lib/core/config/supabase_config.dart` are placeholders):

```bash
flutter run --dart-define=MARKETPLACE=true --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon key>
```

`R2_PUBLIC_URL` is an optional extra define.

Re-exporting the bundled model (requires Python with `ultralytics`; run from the repo root, because the script resolves paths from the current directory):

```bash
python tools/export_yolo26_tflite.py   # writes assets/models/yolo26n_int8.tflite
```

It exports `yolo26n.pt` as INT8 TFLite at `imgsz=832` with `end2end=False, nms=False`. NMS is done in Dart, so the export must stay NMS-free.

## Architecture

### Layout

- `lib/core/`: models, services (all app state and logic), theme, l10n helpers, Supabase config.
- `lib/features/<name>/`: one folder per screen, with screen-local widgets under `widgets/`.
- `lib/l10n/`: ARB sources. `lib/l10n/generated/` is generated output.

### State and dependency wiring

There is no DI framework. `lib/main.dart` constructs every service by hand and exposes each one through `MultiProvider` as a `ChangeNotifier`: `SettingsController`, `ModelLibraryService`, `DetectionService`, `AuthService`, `MarketplaceService`, `DownloadManager`, `DetectionHistoryService`. Screens read them with `context.read` / `context.watch`.

`main.dart` also registers a listener on `ModelLibraryService` that calls `DetectionService.reloadIfNeeded(activeModel)`, so activating, importing or deleting a model hot-swaps the interpreter. Reloads are serialized: a request arriving during a load is parked in `_pendingModel` and applied when the load finishes.

`YoloApp` shows `OnboardingScreen` until `AppSettings.onboardingSeen`, then `HomeShell`. `HomeShell` is an `IndexedStack` with four tabs (home, detect, models, settings); the marketplace and profile tabs are appended only when `AppFlags.marketplace` is on. All tabs stay mounted, so `CaptureScreen` takes an `isActive` flag and creates or disposes the camera controller when its tab gains or loses focus. Class preferences are a pushed route (`PreferencesScreen`) opened from the dashboard and the settings tab.

### Feature flags

`AppFlags.marketplace` (`--dart-define=MARKETPLACE=true`) gates Supabase initialization, `AuthService`, `MarketplaceService` and the extra tabs in `main.dart` and `HomeShell`. With it off, `DownloadManager` gets a `NoopDownloadRecorder` and URL import still works. The marketplace, profile and auth screens still contain hard-coded English strings; localize them before enabling the flag in a release.

### Detection pipeline (`lib/core/services/detection_service.dart`)

0. Decode with `decodeUpright` (`image_decode.dart`), which applies EXIF orientation so pixels match what Flutter's `Image` shows. Never call `img.decodeImage` directly: it ignores EXIF (boxes would not line up on sideways photos) and can throw on truncated files.
1. Pre-downscale the image so its longest side is at most `ResolutionProfile.size` (`capLongestSide`). The profile is only a cap; the real input size comes from the model's input tensor.
2. Letterbox to the model's square input with gray (114) padding (`LetterboxParams`).
3. Build the input tensor as flat bytes (`buildInputBytes`, `tensor_io.dart`) in a `compute()` isolate, quantizing when the input is int8.
4. Run `interpreter.runInference` on the main isolate, because the interpreter holds native resources. Feed it the byte buffer directly rather than nested lists.
5. Copy the output tensor out of native memory (`Tensor.data` is a live view that the next run overwrites), split and dequantize it (`parseOutputBytes`), then decode and filter by confidence and selected labels in a second `compute()` isolate (`decodeYolo`). Boxes are un-letterboxed into normalized `[0,1]` coordinates relative to the original image.
6. Run NMS (`nonMaxSuppression`), unless disabled in settings.

The pure, unit-tested parts live in `lib/core/detection/`: `letterbox.dart`, `yolo_decoder.dart`, `nms.dart`, `camera_frame.dart` (YUV420/BGRA conversion and rotation for live frames), `tensor_io.dart` (flat input/output buffers), `image_decode.dart` and `interpreter_factory.dart` (delegate order and fallback). `DetectionService` only orchestrates them.

Things to know before changing it:

- `detectObjects` (file input) and `detectFromImage` (already-decoded image, used by live mode) are thin wrappers over a single private `_detect`. Put pipeline changes there.
- Live camera frames are converted and rotated upright in an isolate before detection, so detections are normalized to the upright frame. The overlay is drawn inside the preview's own box (`CaptureScreen._buildPreview`) so it lines up. Front-camera mirroring and landscape orientation have not been verified on a device.
- Supported model contract: input `[1, H, W, 3]` as int8 or float32; output `[1, 4 + classes, N]` as int8 or float32, with normalized `cx, cy, w, h` followed by class scores. This contract is checked in two places that must stay in sync: `DetectionService._validateModelCompatibility` and `ModelValidator.validate`.
- Interpreter creation tries NNAPI, then the GPU delegate, then CPU. `DetectionService.activeDelegate` and `delegateFailures` report what happened.
- Top-level functions and message classes at the top of the file exist because `compute()` needs top-level entry points and sendable messages. `DetectedObject` is rebuilt on the main isolate after the decode step.

### Model library

`ModelLibraryService` owns which models exist and which one is active. `InstalledModel` describes one (id, name, file or asset path, labels, input size, class count, quantization, origin). The bundled model is always present as `InstalledModel.builtIn` and cannot be removed; there is no "use custom model" toggle anymore, and `AppSettings` holds only detection tuning.

- Imported `.tflite` files are copied to `<app documents>/models/<id>/model.tflite` so they outlive the file picker's temp path. Entries whose file has vanished are dropped on startup.
- All import paths end in `ModelLibraryService.installFile`, which takes a successful `ModelValidator` result: the wizard in `features/settings/widgets/model_import_wizard.dart` (a `.tflite`, or a `.zip` with the model and an optional label list, unpacked by `extractModelPackage` in `core/services/model_package.dart`), `DownloadManager.importFromUrl` (link) and `DownloadManager.downloadModel` (marketplace; the download is counted only after it installs). `features/models/models_screen.dart` is the UI.
- Labels: an explicit list wins; otherwise `usesCocoLabels` means the bundled COCO names; otherwise `class_N` is generated. Downloads carry no label file, so they assume COCO only when the model has 80 classes.
- The class-selection filter is built from the hard-coded COCO groups in `core/models/category_group.dart` and only applies when `InstalledModel.supportsLabelFilter` (COCO labels). Every detection caller passes `filterBySelectedLabels: model.supportsLabelFilter`; the parameter defaults to `true`.
- The old single-custom-model settings keys are migrated into the library once on first start, then deleted (`ModelLibraryService._migrateLegacySettings`).

### Benchmark, comparison and export

- `core/benchmark/`: `benchmark_report.dart` (timing statistics and the shareable report, pure and tested) and `model_benchmark.dart` (runs the model on CPU/GPU/NNAPI with a zero input; needs native TFLite). `features/models/benchmark_screen.dart` takes an injectable runner.
- `features/models/compare_screen.dart` runs two models one after the other, each in a throw-away `DetectionService`, so the app's active model is untouched.
- `core/export/`: `detection_export.dart` builds JSON/CSV and annotated PNGs (pure; CSV neutralizes formula-looking labels because labels come from user files), `share_service.dart` wraps the system share sheet and is replaced in tests. The results screen's export menu uses them; the PNG is rendered in an isolate via `renderAnnotatedFromBytes`.

### Persistence

Everything local goes through `SharedPreferences`; there is no database.

- `SettingsController` stores one key per setting, including `onboarding_seen`. `applyDeviceDefaults` starts low-RAM devices on the balanced resolution unless one was already stored. `ModelLibraryService` stores the imported-model list as JSON (`installed_models_v1`) plus `active_model_id`.
- `DetectionHistoryService` stores a single encoded list, capped at 50 entries, newest first.
- `MarketplaceService` caches the model list.

### Supabase backend

No schema or migrations live in this repo. The client code expects:

- Tables: `models`, `model_tags`, `model_reviews`, `model_downloads`, `model_favorites`, `profiles`. The models query joins through the `models_user_id_fkey` foreign key.
- Storage buckets: `models`, `thumbnails`.
- RPC: `increment_download_count(model_id_param)`.

### Platform channel

`DeviceCapabilities` calls `isLowRamDevice` on the `pocketdetect/device` method channel, implemented only in `android/app/src/main/kotlin/io/github/alperen012/pocketdetect/MainActivity.kt`. On other platforms it returns false.

## Localization

- Edit `lib/l10n/app_en.arb` (the template) and `lib/l10n/app_tr.arb` together. Never hand-edit `lib/l10n/generated/`.
- `pubspec.yaml` has `generate: true`, so builds regenerate the localizations. Run `flutter gen-l10n` to regenerate without building.
- In widgets use `context.l10n.<key>`, from `core/l10n/l10n_extensions.dart`. Getters are non-nullable (`nullable-getter: false`).
- `ResolutionProfile` and `CategoryGroup` carry hard-coded Turkish labels that serve only as a fallback. UI code should call the `localizedLabel(l10n)` extensions in `l10n_extensions.dart`, and a new profile or category needs a case added there.

## Testing

- Tests live in `test/`, mirroring `lib/`. Services backed by preferences are tested with `SharedPreferences.setMockInitialValues({})`.
- Widget tests wrap the widget in `MultiProvider` plus a `MaterialApp` with the localization delegates and `locale: const Locale('en')`. See `buildTestApp` in `test/widget_test.dart`.
- `AuthService` and `MarketplaceService` read `Supabase.instance.client` in their constructors, so they cannot be constructed in a test without initializing Supabase. `DownloadManager` depends only on the small `DownloadRecorder` interface (which `MarketplaceService` implements) and takes an injectable downloader, validator and temp directory, so it is tested with fakes. `ModelLibraryService` tests use real temp directories.
- `DetectionService`, `ModelValidator` and `createInterpreter` need the native TFLite library and have no tests; their pure helpers (`lib/core/detection/`) do.
