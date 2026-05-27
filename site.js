const THEME_KEY = "portfolio-theme";
const THEMES = ["editorial", "swiss", "lab"];

function getTheme() {
  const t = localStorage.getItem(THEME_KEY);
  return THEMES.includes(t) ? t : "editorial";
}

function setTheme(name) {
  if (!THEMES.includes(name)) return;
  document.documentElement.setAttribute("data-theme", name);
  localStorage.setItem(THEME_KEY, name);
  const label = document.getElementById("theme-cycle-label");
  if (label) {
    const labels = { editorial: "Editorial", swiss: "Swiss", lab: "Lab" };
    label.textContent = labels[name] || name;
  }
}

function cycleTheme() {
  const cur = document.documentElement.getAttribute("data-theme") || "editorial";
  const i = THEMES.indexOf(cur);
  const next = THEMES[(i + 1) % THEMES.length];
  setTheme(next);
}

document.addEventListener("DOMContentLoaded", () => {
  const y = document.getElementById("year");
  if (y) y.textContent = String(new Date().getFullYear());

  setTheme(getTheme());

  const cycleBtn = document.getElementById("theme-cycle");
  if (cycleBtn) cycleBtn.addEventListener("click", cycleTheme);

  if (typeof initI18n === "function") initI18n();
});
