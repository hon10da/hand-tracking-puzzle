// Local gameplay recording. No microphone and no cloud upload.
export function createRecorder(canvas, video) {
  const button = document.getElementById('recordBtn');
  const status = document.getElementById('recordStatus');
  const fallback = document.getElementById('recordDownload');
  const retry = document.getElementById('recordRetry');
  let recorder = null, stream = null, chunks = [], bytes = 0;
  let started = 0, busy = false, blob = null, filename = '', url = ''; 
  let timer;
  function message(text) { status.textContent = text; }
  function refresh() {
    const active = recorder?.state === 'recording';
    button.textContent = busy ? 'Saving video...' : active ? 'Stop recording (F)' : 'Start recording (F)';
    button.disabled = busy;
    button.classList.toggle('is-recording', !!active);
    if (active) {
      const seconds = Math.floor((performance.now() - started) / 1000);
      message(`REC ${String(Math.floor(seconds / 60)).padStart(2,'0')}:${String(seconds % 60).padStart(2,'0')} | no audio`);
    }
  }
  async function save() {
    busy = true; refresh(); retry.hidden = true;
    message('Saving into recordings/... Keep the server window open.');
    try {
      const response = await fetch('/api/recordings', {
        method: 'POST', headers: { 'Content-Type': 'video/webm', 'X-PuzzleCam': 'recording-v1' }, body: blob
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const result = await response.json();
      if (!result.saved || !/^recordings\/[a-zA-Z0-9_.-]+\.webm$/.test(result.path)) throw new Error('Invalid save response');
      message(`Saved: ${result.path}`);
      fallback.textContent = 'Download another copy';
    } catch (error) {
      message('Project-folder save failed. Retry, or download the video below. Keep this tab open until saved.');
      retry.hidden = false;
      fallback.textContent = 'Download unsaved video';
      console.warn('[PuzzleCam] Local recording save failed', error);
    } finally { busy = false; refresh(); }
  }
  function stop() {
    if (recorder?.state !== 'recording') return;
    busy = true; refresh();
    recorder.stop();
    clearInterval(timer);
  }
  function start() {
    if (busy || recorder?.state === 'recording') return;
    if (video.readyState < 2 || !canvas.width || !canvas.height) {
      message('Wait for the camera to start before recording.'); return;
    }
    if (!window.MediaRecorder || !canvas.captureStream) {
      message('Recording is unavailable. Use a recent Chrome or Edge.'); return;
    }
    if (!retry.hidden && !window.confirm('The previous video is not saved to the project. Download it or retry saving first. Discard it and record a new video?')) return;
    try {
      const mimeType = ['video/webm;codecs=vp9','video/webm;codecs=vp8','video/webm'].find(type => MediaRecorder.isTypeSupported(type));
      if (!mimeType) throw new Error('WebM recording is not supported in this browser');
      stream = canvas.captureStream(30);
      chunks = []; bytes = 0; 
      recorder = new MediaRecorder(stream, { mimeType, videoBitsPerSecond: 4000000 });
      recorder.ondataavailable = event => {
        if (event.data.size) { chunks.push(event.data); bytes += event.data.size; }
        // Bound memory for long sessions. Finalize rather than discard the clip.
        if (bytes > 256 * 1024 * 1024 || performance.now() - started > 30 * 60 * 1000) stop();
      };
      recorder.onerror = () => { message('Recording error. Stopping and saving the available video.'); stop(); };
      recorder.onstop = async () => {
        stream.getTracks().forEach(track => track.stop());
        blob = new Blob(chunks, { type: recorder.mimeType || 'video/webm' }); chunks = [];
        if (url) URL.revokeObjectURL(url);
        if (!blob.size) { busy = false; refresh(); message('No video was captured. Please try again.'); return; }
        filename = `puzzle-${new Date().toISOString().replace(/[:.]/g,'-')}.webm`;
        url = URL.createObjectURL(blob); fallback.href = url; fallback.download = filename; fallback.hidden = false;
        await save();
      };
      retry.hidden = true; fallback.hidden = true;
      recorder.start(1000); started = performance.now(); refresh();
      timer = setInterval(refresh, 250);
    } catch (error) {
      stream?.getTracks().forEach(track => track.stop());
      busy = false; message(`Could not start recording: ${error.message}`); refresh();
    }
  }
  function toggle() { if (busy) return; recorder?.state === 'recording' ? stop() : start(); }
  button.addEventListener('click', toggle);
  retry.addEventListener('click', () => { if (blob && !busy) save(); });
  window.addEventListener('keydown', event => {
    if (event.repeat || event.ctrlKey || event.altKey || event.metaKey || event.target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName)) return;
    if (event.code === 'KeyF' || event.key.toLowerCase() === 'f') { event.preventDefault(); toggle(); }
  });
  window.addEventListener('beforeunload', event => {
    if (busy || recorder?.state === 'recording' || !retry.hidden) { event.preventDefault(); event.returnValue = ''; }
  });
}
