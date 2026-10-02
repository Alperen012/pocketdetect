from __future__ import annotations

import shutil
from pathlib import Path

from ultralytics import YOLO

MODEL_NAME = "yolo26n.pt"
EXPORT_DIR = Path.cwd() / "runs" / "export"
SAVED_MODEL_DIR = Path.cwd() / "yolo26n_saved_model"
TARGET = Path.cwd() / "assets" / "models" / "yolo26n_int8.tflite"


def find_latest_tflite() -> Path | None:
    preferred = SAVED_MODEL_DIR / "yolo26n_int8.tflite"
    if preferred.exists():
        return preferred

    if EXPORT_DIR.exists():
        candidates = sorted(EXPORT_DIR.rglob("*.tflite"), key=lambda p: p.stat().st_mtime)
        if candidates:
            return candidates[-1]

    fallback = sorted(Path.cwd().rglob("*.tflite"), key=lambda p: p.stat().st_mtime)
    if fallback:
        return fallback[-1]
    return None


def main() -> None:
    model = YOLO(MODEL_NAME)
    model.export(
        format="tflite",
        imgsz=832,
        int8=True,
        data="coco8.yaml",
        batch=1,
        device="cpu",
        end2end=False,
        nms=False,
    )

    latest = find_latest_tflite()
    if latest is None:
        raise RuntimeError("TFLite export output not found.")

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(latest, TARGET)
    print(f"Saved: {TARGET}")


if __name__ == "__main__":
    main()
