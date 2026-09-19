# 🛡️ Specification & Guide: High-Aesthetic Footer Badges & AdBlock-Safe Counters (32px)

> **Design standards and non-blocking statistical tracking integration for WordPress and modern web applications.**
> 
> *Repository:* [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | *Author:* [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz) & AI Assistant | *Version:* `2026.09.06`

---

## 📌 1. Visual Aesthetics & Dimensions
- **Badge Height:** Strictly fixed at **32px** (seamlessly aligns with standard 88×31 and 31×31 web buttons).
- **Default Appearance (Idle):**
  - Semi-transparent dark background (`rgba(0, 0, 0, 0.45)`)
  - Subtle golden-yellow accent border (`border: 1px solid rgba(251, 191, 36, 0.35)`)
  - Modern rounded corners: `border-radius: 6px`
  - **Dimmed luminosity (50%):** `opacity: 0.5; filter: grayscale(15%); transition: all 0.25s ease-in-out;`
- **Interactive State (Hover):**
  - Smooth ignition to **100% full brightness and vibrant saturation**: `opacity: 1; filter: none;`
  - Highlighting border `#fbbf24` and ambient golden glow: `box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);`
  - Subtle lift elevation: `transform: translateY(-2px);`

---

## 🛡️ 2. AdBlock Immunity Architecture (uBlock / Brave Shield / AdBlock Plus)
Browser privacy extensions typically strip standard analytics counters by detecting telltale DOM signatures:
1. Third-party image URLs (`<img src="https://counter.yadro.ru/...">`)
2. Identifiers containing trigger tokens like `licntA0F6`, `counter`, `analytics`, or `ad-tracker`
3. Hyperlinks with blacklisted query parameters

### 💡 Two-Layer Decoupling Solution:
1. **Visual UI Button:** Fully localized HTML/CSS component referencing locally hosted icons (`/assets/img/stat_logo.png`). It never triggers content-blocking heuristics and renders reliably.
2. **Asynchronous Tracking Beacon:** The actual metric ping is fired silently in background memory via `new Image()` at the page footer, detached from the visual DOM tree.

---

## 💻 3. Production HTML & JavaScript Snippet

```html
<!-- Footer Badges Container -->
<div class="footer-badges">
  <!-- Badge 1: Promotion & Web Development Badge -->
  <a href="https://gincz.com/" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-brand" title="Gin IT — Web Engineering & Infrastructure">
    <img src="/assets/img/gin_it_logo.gif" alt="Gin IT" class="badge-img-icon">
    <span class="badge-text-brand">Gin <strong>IT</strong></span>
  </a>

  <!-- Badge 2: Safe Statistical Monitor Badge -->
  <a href="https://www.liveinternet.ru/stat/domain.example.com/" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-stat" title="LiveInternet Visitor Analytics">
    <img src="/assets/img/stat_logo.png" alt="Statistics" class="badge-img-icon">
    <span class="badge-text-stat">Live<strong>Stat</strong></span>
  </a>
</div>

<!-- Asynchronous Non-Blocking Metric Beacon -->
<script>
(function(d, s) {
  try {
    var i = new Image();
    i.src = "https://counter.yadro.ru/hit?t42.6;r" + escape(d.referrer) +
      ((typeof(s) == "undefined") ? "" : ";s" + s.width + "*" + s.height + "*" +
      (s.colorDepth ? s.colorDepth : s.pixelDepth)) + ";u" + escape(d.URL) +
      ";h" + escape(d.title.substring(0, 150)) + ";" + Math.random();
  } catch(e) {}
})(document, screen);
</script>
```

---

## 🎨 4. CSS Stylesheet (Scoped & Minified)

```css
.footer-badges {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin: 16px 0;
}

.footer-badge-btn {
  display: inline-flex;
  align-items: center;
  height: 32px;
  padding: 0 10px;
  background: rgba(0, 0, 0, 0.45);
  border: 1px solid rgba(251, 191, 36, 0.35);
  border-radius: 6px;
  text-decoration: none;
  opacity: 0.5;
  filter: grayscale(15%);
  transition: all 0.25s ease-in-out;
}

.footer-badge-btn:hover {
  opacity: 1;
  filter: none;
  border-color: #fbbf24;
  box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);
  transform: translateY(-2px);
}

.badge-img-icon {
  height: 18px;
  width: auto;
  margin-right: 6px;
}

.badge-text-brand, .badge-text-stat {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  font-size: 12px;
  font-weight: 500;
  color: #f3f4f6;
  letter-spacing: 0.3px;
}
```