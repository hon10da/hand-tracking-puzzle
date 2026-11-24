# Puzzle Cam (hand-tracking puzzle)

A browser game where you solve a 3x3 picture puzzle with your hand in front of the webcam. No mouse or keyboard needed to play.

**[Watch the demo video (MP4)](demo/hand-puzzle-demo.mp4)**

> Demo video: `demo/hand-puzzle-demo.mp4`. The panel on the right side of the video was added in post-production to explain the idea. It shows a schematic and clip-based metrics. It is not live telemetry from the app.

## How it works

- The webcam image is processed in the browser with MediaPipe Hand Landmarker (JavaScript / WASM).
- Hand landmarks give the thumb and index fingertip positions. A pinch (the two tips close together) grabs a piece, and moving your hand drags it. Releasing the pinch drops it.
- Simple rules in `app.js` turn those landmarks into game moves on a 3x3 grid.
- The model and the MediaPipe runtime are bundled in `models/` and `vendor/`, so it runs offline after you download it.

## Run it

You need Chrome or Edge and a webcam. Use a local server, because browsers block the camera on plain `file://` pages.

- Windows: double-click `START-WINDOWS.bat` (uses `server.ps1`).
- Python 3: run `START-PYTHON.bat`, or `python server.py`.
- Open http://localhost:8080/ and allow camera access.

If the camera is busy, close Zoom, Teams or other tabs that use it, then retry.

## Record a clip

Click the page, press **F** to start recording, press **F** again to stop and save. The Start/Stop button on the page does the same thing.

- Clips are saved as `.webm` in the `recordings/` folder, one file per clip.
- Only the time between your two presses is recorded. There is no automatic recording and no audio.
- The video has the camera image with the puzzle and hand overlays, not the browser controls.
- Clips stay on your computer. Nothing is uploaded.
- A 30 minute / 256 MB cap ends very long clips to protect browser memory.

## Project layout

| Path | What it is |
| --- | --- |
| `index.html`, `css/` | Page and styles |
| `app.js` | Camera, hand tracking, pinch logic, puzzle game |
| `recording.js` | Manual F-key recording and saving |
| `server.ps1`, `server.py` | Small local servers that also save recordings into `recordings/` |
| `models/`, `vendor/` | Bundled MediaPipe model and runtime (offline use) |

## Changes in this version

- Runs offline with the model and runtime bundled locally.
- Fixes for camera start-up and runtime errors.
- Manual recording with the F key, saved to the project folder.

## Testing notes

A real gameplay session on a real webcam, recorded by the project owner, confirmed that the game and F-key recording work. Automated checks ran in Chrome with a synthetic camera, with the Python and PowerShell servers tested on Linux. Windows PowerShell itself was not tested by automation.

## Author and third-party licenses

**Author.** Muhannad Salah ([@hon10da](https://github.com/hon10da)).

**Third-party files.** `vendor/` and `models/` hold the MediaPipe Tasks Vision runtime and the Hand Landmarker model bundle from Google MediaPipe. MediaPipe is released under the Apache License 2.0. The license text is in `third_party/MediaPipe-LICENSE.txt`. The Hand Landmarker model file (`models/hand_landmarker.task`, about 7.8 MB) is Google's unmodified MediaPipe Hand Landmarker (full) float16 bundle, downloaded from Google's model storage (https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task). Google's model card for the hand tracking models states they are licensed under the Apache License, Version 2.0: https://storage.googleapis.com/mediapipe-assets/Model%20Card%20Hand%20Tracking%20(Lite_Full)%20with%20Fairness%20Oct%202021.pdf . Model overview: https://developers.google.com/edge/mediapipe/solutions/vision/hand_landmarker
