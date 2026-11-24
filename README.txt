Puzzle Cam - manual video recording

1. Extract the whole ZIP into a NEW writable folder. Keep your old working copy as a backup.
2. Close the old Puzzle Cam server window first (both versions use port 8080).
3. Double-click START-WINDOWS.bat. Keep the server window open.
4. Chrome/Edge opens http://localhost:8080/ . Allow camera access.
5. Click the page, then press F to START recording. Press F again to STOP and SAVE.
   The on-page Start/Stop recording button does the same thing. The physical F key also works with an Arabic keyboard layout.
6. Wait for the Saved: recordings/... message. Open recordings inside this project folder to find the .webm video.

Only the period between your two presses is recorded. There is NO automatic/session recording.
Video includes the camera image and the puzzle/hand overlays drawn on it, not the browser controls or photo-strip sidebar. No microphone/audio is recorded.
Each clip gets a different filename; old clips are not overwritten. Videos stay on this computer. Nothing is uploaded online.
If project-folder saving fails, keep the page open and use Retry saving to project or Download unsaved video. A browser download goes to your browser's download location, not necessarily recordings/.
Do not close the page/server while recording or saving. A 30-minute/256-MB safety cap finalizes very long clips to limit browser memory use. For long sessions, record shorter clips.
Use Chrome or Edge. WebM plays in current Chrome/Edge and many video players; this is not an MP4 export.
The runtime and hand model are bundled and work offline.
If camera is busy, close Zoom/Teams/Camera or other camera tabs, then retry.
START-PYTHON.bat is a fallback if Python 3 is installed. It now uses server.py to support recording saves too.

Validation: real Chrome with a synthetic camera; F toggle, multiple clips, WebM playback metadata, local saves through Python 3 and PowerShell 7 on Linux, failure/download/retry flow. Windows PowerShell itself and a real webcam were not available for this new recording test. The base game was retained from the working repaired package.
