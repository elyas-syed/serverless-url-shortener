const form = document.getElementById("shorten-form");
const result = document.getElementById("result");
const errorBox = document.getElementById("error");
const shortUrlLink = document.getElementById("short-url");
const clickCountEl = document.getElementById("click-count");
const expiresAtEl = document.getElementById("expires-at");
const copyBtn = document.getElementById("copy-btn");
const copyLabel = document.getElementById("copy-label");
const refreshStats = document.getElementById("refresh-stats");
const submitBtn = document.getElementById("submit-btn");
const btnLabel = submitBtn.querySelector(".btn-label");
const btnSpinner = submitBtn.querySelector(".btn-spinner");
const slugPrefix = document.getElementById("slug-prefix");

let currentSlug = null;

slugPrefix.textContent = `${window.location.host}/`;

function showError(message) {
  errorBox.textContent = message;
  errorBox.classList.remove("hidden");
  result.classList.add("hidden");
}

function hideError() {
  errorBox.classList.add("hidden");
}

function setLoading(loading) {
  submitBtn.disabled = loading;
  btnLabel.classList.toggle("hidden", loading);
  btnSpinner.classList.toggle("hidden", !loading);
}

function absoluteShortUrl(pathOrUrl) {
  if (pathOrUrl.startsWith("http")) {
    return pathOrUrl;
  }
  return `${window.location.origin}${pathOrUrl.startsWith("/") ? "" : "/"}${pathOrUrl}`;
}

function formatExpiry(unixSeconds) {
  return new Date(unixSeconds * 1000).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

function updateStats(data) {
  clickCountEl.textContent = String(data.click_count ?? 0);
  expiresAtEl.textContent = data.expires_at ? formatExpiry(data.expires_at) : "—";
}

async function refreshClickCount() {
  if (!currentSlug) return;

  refreshStats.disabled = true;
  try {
    const response = await fetch(`/api/links/${encodeURIComponent(currentSlug)}`);
    const data = await response.json();
    if (!response.ok) {
      showError(data.error || "Unable to load stats.");
      return;
    }
    updateStats(data);
  } finally {
    refreshStats.disabled = false;
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideError();
  setLoading(true);

  const url = document.getElementById("url").value.trim();
  const slug = document.getElementById("slug").value.trim();

  const payload = { url };
  if (slug) payload.slug = slug;

  try {
    const response = await fetch("/api/links", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await response.json();
    if (!response.ok) {
      showError(data.error || "Unable to create short link.");
      return;
    }

    currentSlug = data.slug;
    const fullShortUrl = absoluteShortUrl(data.short_url);
    shortUrlLink.href = fullShortUrl;
    shortUrlLink.textContent = fullShortUrl;
    updateStats(data);
    result.classList.remove("hidden");
    copyBtn.classList.remove("copied");
    copyLabel.textContent = "Copy";
  } catch {
    showError("Network error. Please try again.");
  } finally {
    setLoading(false);
  }
});

copyBtn.addEventListener("click", async () => {
  await navigator.clipboard.writeText(shortUrlLink.href);
  copyBtn.classList.add("copied");
  copyLabel.textContent = "Copied!";
  setTimeout(() => {
    copyBtn.classList.remove("copied");
    copyLabel.textContent = "Copy";
  }, 2000);
});

refreshStats.addEventListener("click", refreshClickCount);
