# Guide: Modern AdBlock-Safe Footer Badges & Analytics Counters (32px)

## 📌 1. Concept & Visual Style
- **Banner Height:** Fixed **32px** (harmonizes with standard 88x31 and 31x31 web buttons).
- **Idle Aesthetic:**
  - Translucent dark backdrop (`rgba(0, 0, 0, 0.45)`)
  - Subtle golden accent border (`border: 1px solid rgba(251, 191, 36, 0.35)`)
  - Smooth rounded corners (`border-radius: 6px`)
  - **Dimmed Idle State:** `opacity: 0.5; filter: grayscale(15%);`
- **Interactive Hover Effect:**
  - Smooth transition to **100% full opacity & color**: `opacity: 1; filter: none;`
  - Glowing gold border: `border-color: #fbbf24; box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);`
  - Subtle upward lift: `transform: translateY(-2px);`

---

## 🛡️ 2. AdBlock / uBlock / Brave Shield Immunity Architecture
Most browser ad-blockers (uBlock Origin, AdBlock Plus, Brave Shields) remove analytics badges based on DOM pattern heuristics:
1. Third-party domains in `<img src="https://counter.yadro.ru/...">`
2. Element IDs and class attributes like `licntA0F6`, `counter`, `analytics`
3. Links containing tracked URLs in `href`

### 💡 Solution (Two-Tier Isolation):
1. **Visual UI Button:** Completely local markup styled with local CSS and hosted icons (`/assets/img/stat_logo.png`). Never blocked by filters because it contains no tracking selectors.
2. **Background Analytics Beacon:** The tracking pixel request is executed asynchronously in memory via a JavaScript `new Image()` object, completely uncoupled from the visible DOM elements.

---

## 💻 3. HTML Snippet (WordPress / Static HTML / SPA)

```html
<!-- Footer Badges Container -->
<div class="footer-badges">
  <!-- Badge 1: Brand Promotion (Gin IT) -->
  <a href="http://prodvig-saita.ru/" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-brand" title="Gin IT — Web Development & SEO (prodvig-saita.ru)">
    <img src="/assets/img/gin_it_logo.gif" alt="Gin IT" class="badge-img-icon">
    <span class="badge-text-brand">Gin <strong>IT</strong></span>
  </a>

  <!-- Badge 2: Safe Analytics Counter (LiveInternet) -->
  <a href="https://www.liveinternet.ru/stat/eduard-dolgunow.gincz.com/index.html?lang=en&nohelp=yes" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-stat" title="LiveInternet — Traffic Analytics">
    <img src="/assets/img/stat_logo.png" alt="Statistics" class="badge-img-icon">
    <span class="badge-text-stat">Live<strong>Stat</strong></span>
  </a>
</div>

<!-- Background Invisible Beacon -->
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

## 🎨 4. CSS Styles (style.css / Customizer CSS)

```css
/* Badges Container */
.footer-badges {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

/* 32px Button Base */
.footer-badge-btn {
  height: 32px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 10px 0 6px;
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.45);
  border: 1px solid rgba(251, 191, 36, 0.35);
  color: #cbd5e1;
  text-decoration: none;
  font-size: 0.82rem;
  font-weight: 600;
  opacity: 0.5;
  filter: grayscale(15%);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
  box-sizing: border-box;
}

/* Hover Glowing Effect */
.footer-badge-btn:hover {
  opacity: 1;
  filter: none;
  border-color: #fbbf24;
  background: rgba(251, 191, 36, 0.15);
  transform: translateY(-2px);
  box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);
  color: #ffffff;
}

/* Icons Inside Badges */
.badge-img-icon {
  height: 22px;
  width: auto;
  max-width: 28px;
  object-fit: contain;
  border-radius: 3px;
  display: block;
}

/* Brand Typography */
.badge-text-brand {
  color: #fbbf24;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.badge-text-brand strong {
  color: #38bdf8;
  font-weight: 800;
}

.badge-text-stat {
  color: #fbbf24;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.badge-text-stat strong {
  color: #38bdf8;
  font-weight: 800;
}
```