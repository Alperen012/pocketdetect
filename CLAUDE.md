# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

YOLO Mobile: a Flutter app that runs on-device object detection with a TFLite YOLO model (photo, gallery, batch and live camera), plus a Supabase-backed marketplace for downloading and publishing custom `.tflite` models. UI strings are localized in English and Turkish; the README is in Turkish.

## Commands

```bash
flutter pub get
flutter analyze                    # lints: package:flutter_lints/flutter.yaml, no custom rules
flutter test                       # all tests
flutter test test/core/services/settings_controller_test.dart             # one file
flutter test test/widget_test.dart --plain-name "tapping camera button"   # one test by name
flutter gen-l10n                   # regenerate lib/l10n/generated after editing ARB files
```

Running the app needs Supabase credentials passed as compile-time defines. The defaults in `lib/core/config/supabase_config.dart` are placeholders, and `Supabase.initialize` runs in `main()` before `runApp`:

```bash
flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon key>
```

`R2_PUBLIC_URL` is an optional third define.

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

There is no DI framework. `lib/main.dart` constructs every service by hand and exposes each one through `MultiProvider` as a `ChangeNotifier`: `SettingsController`, `DetectionService`, `AuthService`, `MarketplaceService`, `DownloadManager`, `DetectionHistoryService`. Screens read them with `context.read` / `context.watch`.

`main.dart` also registers a listener on `SettingsController` that calls `DetectionService.reloadIfNeeded`, so any settings change that affects the model (custom model toggle, model path, labels path) hot-swaps the interpreter. Reloads are serialized: a change arriving during a load is parked in `_pendingSettings` and applied when the load finishes.

`HomeShell` is an `IndexedStack` with five tabs (home, capture, preferences, marketplace, profile). All tabs stay mounted, so `CaptureScreen` takes an `isActive` flag and creates or disposes the camera controller when its tab gains or loses focus.

### Detection pipeline (`lib/core/services/detection_service.dart`)

1. Pre-downscale the image so its longest side is at most `ResolutionProfile.size` (`capLongestSide`). The profile is only a cap; the real input size comes from the model's input tensor.
2. Letterbox to the model's square input with gray (114) padding (`LetterboxParams`).
3. Build the input tensor in a `compute()` isolate, quantizing when the input is int8.
4. Run `interpreter.run` on the main isolate, because the interpreter holds native resources.
5. Dequantize the output, then decode and filter by confidence and selected labels in a second `compute()` isolate (`decodeYolo`). Boxes are un-letterboxed into normalized `[0,1]` coordinates relative to the original image.
6. Run NMS (`nonMaxSuppression`), unless disabled in settings.

The pure, unit-tested parts live in `lib/core/detection/`: `letterbox.dart`, `yolo_decoder.dart`, `nms.dart`, `camera_frame.dart` (YUV420/BGRA conversion and rotation for live frames) and `interpreter_factory.dart` (delegate order and fallback). `DetectionService` only orchestrates them.

Things to know before changing it:

- `detectObjects` (file input) and `detectFromImage` (already-decoded image, used by live mode) are thin wrappers over a single private `_detect`. Put pipeline changes there.
- Live camera frames are converted and rotated upright in an isolate before detection, so detections are normalized to the upright frame. The overlay is drawn inside the preview's own box (`CaptureScreen._buildPreview`) so it lines up. Front-camera mirroring and landscape orientation have not been verified on a device.
- Supported model contract: input `[1, H, W, 3]` as int8 or float32; output `[1, 4 + classes, N]` as int8 or float32, with normalized `cx, cy, w, h` followed by class scores. This contract is checked in two places that must stay in sync: `DetectionService._validateModelCompatibility` and `ModelValidator.validate`.
- Interpreter creation tries NNAPI, then the GPU delegate, then CPU. `DetectionService.activeDelegate` and `delegateFailures` report what happened.
- Top-level functions and message classes at the top of the file exist because `compute()` needs top-level entry points and sendable messages. `DetectedObject` is rebuilt on the main isolate after the decode step.

### Custom and marketplace models

Both paths end in the same `SettingsController` calls (`updateCustomModelPath`, `updateCustomLabelsPath`, `updateCustomModelMetadata`, `updateUseCustomModel`):

- Local import: `features/settings/widgets/model_import_wizard.dart`, validated with `ModelValidator`.
- Marketplace: `DownloadManager` downloads with Dio into `<app documents>/marketplace_models/`, validates with `ModelValidator`, and `activateModel` applies it.

Marketplace models are activated with a null labels path, so they use the bundled COCO labels and skip the label-count check. The selected-label filter only makes sense for COCO names, so every caller (results, batch, live) passes `filterBySelectedLabels: !useCustomModel` to the detection methods; the parameter defaults to `true`. The preferences screen's class selection is built from the hard-coded COCO groups in `core/models/category_group.dart`.

### Persistence

Everything local goes through `SharedPreferences`; there is no database.

- `SettingsController` stores one key per setting.
- `DetectionHistoryService` stores a single encoded list, capped at 50 entries, newest first.
- `MarketplaceService` caches the model list.
- `DownloadManager` stores downloaded-model metadata in a hand-rolled format (`key=value` pairs joined by `;`, entries joined by `|||`), not JSON.

### Supabase backend

No schema or migrations live in this repo. The client code expects:

- Tables: `models`, `model_tags`, `model_reviews`, `model_downloads`, `model_favorites`, `profiles`. The models query joins through the `models_user_id_fkey` foreign key.
- Storage buckets: `models`, `thumbnails`.
- RPC: `increment_download_count(model_id_param)`.

### Platform channel

`DeviceCapabilities` calls `isLowRamDevice` on the `mobile_yolo/device` method channel, implemented only in `android/app/src/main/kotlin/com/example/mobile_yolo/MainActivity.kt`. On other platforms it returns false.

## Localization

- Edit `lib/l10n/app_en.arb` (the template) and `lib/l10n/app_tr.arb` together. Never hand-edit `lib/l10n/generated/`.
- `pubspec.yaml` has `generate: true`, so builds regenerate the localizations. Run `flutter gen-l10n` to regenerate without building.
- In widgets use `context.l10n.<key>`, from `core/l10n/l10n_extensions.dart`. Getters are non-nullable (`nullable-getter: false`).
- `ResolutionProfile` and `CategoryGroup` carry hard-coded Turkish labels that serve only as a fallback. UI code should call the `localizedLabel(l10n)` extensions in `l10n_extensions.dart`, and a new profile or category needs a case added there.

## Testing

- Tests live in `test/`, mirroring `lib/`. Services backed by preferences are tested with `SharedPreferences.setMockInitialValues({})`.
- Widget tests wrap the widget in `MultiProvider` plus a `MaterialApp` with the localization delegates and `locale: const Locale('en')`. See `buildTestApp` in `test/widget_test.dart`.
- `AuthService` and `MarketplaceService` read `Supabase.instance.client` in their constructors, and `DownloadManager` depends on `MarketplaceService`. None of them can be constructed in a test without initializing Supabase, and the existing tests avoid them.
- `DetectionService` needs the native TFLite library and has no tests.
