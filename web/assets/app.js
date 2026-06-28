const form = document.getElementById("shorten-form");
const result = document.getElementById("result");
const errorBox = document.getElementById("error");
const shortUrlLink = document.getElementById("short-url");
const meta = document.getElementById("meta");
const copyBtn = document.getElementById("copy-btn");
const refreshStats = document.getElementById("refresh-stats");

let currentSlug = null;

function showError(message) {
  errorBox.textContent = message;
  errorBox.classList.remove("hidden");
  result.classList.add("hidden");
}

function hideError() {
  errorBox.classList.add("hidden");
}

function absoluteShortUrl(pathOrUrl) {
  if (pathOrUrl.startsWith("http")) {
    return pathOrUrl;
  }
  return `${window.location.origin}${pathOrUrl.startsWith("/") ? "" : "/"}${pathOrUrl}`;
}

async function refreshClickCount() {
  if (!currentSlug) return;
  const response = await fetch(`/api/links/${encodeURIComponent(currentSlug)}`);
  const data = await response.json();
  if (!response.ok) {
    showError(data.error || "Unable to load stats.");
    return;
  }
  meta.textContent = `Clicks: ${data.click_count} · Expires: ${new Date(data.expires_at * 1000).toLocaleString()}`;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideError();

  const url = document.getElementById("url").value.trim();
  const slug = document.getElementById("slug").value.trim();

  const payload = { url };
  if (slug) payload.slug = slug;

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
  meta.textContent = `Clicks: ${data.click_count} · Expires: ${new Date(data.expires_at * 1000).toLocaleString()}`;
  result.classList.remove("hidden");
});

copyBtn.addEventListener("click", async () => {
  await navigator.clipboard.writeText(shortUrlLink.href);
  copyBtn.textContent = "Copied!";
  setTimeout(() => {
    copyBtn.textContent = "Copy";
  }, 1500);
});

refreshStats.addEventListener("click", refreshClickCount);
