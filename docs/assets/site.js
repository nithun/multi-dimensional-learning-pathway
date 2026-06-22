// MDLP site — theme toggle, copy buttons, syntax highlighting, active-nav.
(function () {
  // --- theme (persisted) ---
  var root = document.documentElement;
  var saved = localStorage.getItem("mdlp-theme");
  if (saved) root.setAttribute("data-theme", saved);
  var btn = document.getElementById("theme");
  if (btn) {
    btn.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
      root.setAttribute("data-theme", next);
      localStorage.setItem("mdlp-theme", next);
    });
  }

  // --- syntax highlighting ---
  if (window.hljs) {
    document.querySelectorAll("pre code").forEach(function (el) {
      try { window.hljs.highlightElement(el); } catch (e) {}
    });
  }

  // --- copy buttons ---
  document.querySelectorAll(".code .copy").forEach(function (b) {
    b.addEventListener("click", function () {
      var code = b.closest(".code").querySelector("code");
      var text = code ? code.innerText : "";
      navigator.clipboard.writeText(text).then(function () {
        var old = b.textContent;
        b.textContent = "Copied ✓";
        setTimeout(function () { b.textContent = old; }, 1400);
      });
    });
  });

  // --- active nav on scroll ---
  var links = Array.prototype.slice.call(document.querySelectorAll(".nav-links a[href^='#']"));
  var sections = links
    .map(function (a) { return document.querySelector(a.getAttribute("href")); })
    .filter(Boolean);
  if ("IntersectionObserver" in window && sections.length) {
    var byId = {};
    links.forEach(function (a) { byId[a.getAttribute("href").slice(1)] = a; });
    var obs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        var a = byId[e.target.id];
        if (a && e.isIntersecting) {
          links.forEach(function (l) { l.style.color = ""; });
          a.style.color = "var(--text)";
        }
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    sections.forEach(function (s) { obs.observe(s); });
  }
})();
