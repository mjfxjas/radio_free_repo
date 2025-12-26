const STREAM_URL = "https://radio.theatrico.org/stream";

let audioEl, playButton, statusEl, streamUrlEl, copyButton, copyHintEl;

try {
  audioEl = document.querySelector("[data-audio]");
  playButton = document.querySelector("[data-play]");
  statusEl = document.querySelector("[data-status]");
  streamUrlEl = document.querySelector("[data-stream-url]");
  copyButton = document.querySelector("[data-copy]");
  copyHintEl = copyButton?.querySelector(".copy-hint");

  if (!audioEl || !playButton || !statusEl) {
    throw new Error("Missing required elements");
  }
} catch (err) {
  console.error("[stream] DOM initialization failed:", err);
  throw err;
}

const setStatus = (text, state = "idle") => {
  if (!statusEl) return;
  const label = text.toUpperCase();
  statusEl.textContent = label;
  statusEl.dataset.state = state;
};

const updatePlayUI = (isPlaying) => {
  if (!playButton) return;
  const icon = playButton.querySelector(".icon");
  if (!icon) return;
  icon.className = `icon ${isPlaying ? "icon-pause" : "icon-play"}`;
  playButton.setAttribute("aria-pressed", String(isPlaying));
};

const applyStreamUrl = () => {
  if (!audioEl) return;
  audioEl.src = STREAM_URL;
  if (streamUrlEl) streamUrlEl.textContent = STREAM_URL;
  if (copyHintEl) {
    try {
      const { host } = new URL(STREAM_URL);
      copyHintEl.textContent = host;
    } catch {
      copyHintEl.textContent = "copy";
    }
  }
};

applyStreamUrl();

const playStream = async () => {
  if (!audioEl) return;
  if (!audioEl.src) applyStreamUrl();
  setStatus("Buffering", "loading");
  updatePlayUI(true);
  try {
    await audioEl.play();
    setStatus("Live", "playing");
  } catch (err) {
    console.error("[stream] play failed", err);
    setStatus("Error", "error");
    updatePlayUI(false);
  }
};

playButton?.addEventListener("click", () => {
  if (audioEl.paused) {
    playStream();
  } else {
    audioEl.pause();
    setStatus("Paused", "idle");
    updatePlayUI(false);
  }
});

copyButton?.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(STREAM_URL);
    if (copyHintEl) {
      const original = copyHintEl.textContent;
      copyHintEl.textContent = "copied";
      setTimeout(() => {
        copyHintEl.textContent = original || "copy";
      }, 1200);
    }
  } catch (err) {
    console.error("[stream] copy failed", err);
  }
});

audioEl.addEventListener("playing", () => {
  setStatus("Live", "playing");
  updatePlayUI(true);
});

audioEl.addEventListener("pause", () => {
  setStatus("Paused", "idle");
  updatePlayUI(false);
});

audioEl.addEventListener("waiting", () => setStatus("Buffering", "loading"));
audioEl.addEventListener("stalled", () => setStatus("Reconnecting", "loading"));
audioEl.addEventListener("ended", () => {
  setStatus("Idle", "idle");
  updatePlayUI(false);
});

audioEl.addEventListener("error", () => {
  setStatus("Unavailable", "error");
  updatePlayUI(false);
});

setStatus("Idle", "idle");
