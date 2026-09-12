# Регламент и руководство: Создание стильных футер-баннеров и AdBlock-Safe счётчиков (32px)

## 📌 1. Концепция и визуальный стиль
- **Высота баннеров:** строго фиксированная **32px** (гармонично сочетается со стандартными кнопками 88x31 и 31x31).
- **Базовая эстетика (Idle):**
  - Полупрозрачный тёмный фон (`rgba(0, 0, 0, 0.45)`)
  - Аккуратная тонкая золотисто-жёлтая рамка (`border: 1px solid rgba(251, 191, 36, 0.35)`)
  - Скругление углов `border-radius: 6px`
  - **Приглушение яркости в 2 раза:** `opacity: 0.5; filter: grayscale(15%);`
- **Интерактивный эффект при наведении (Hover):**
  - Плавное зажигание до **100% яркости и сочных цветов**: `opacity: 1; filter: none;`
  - Яркая рамка `#fbbf24`, золотистое свечение: `box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);`
  - Лёгкий подъём кнопки: `transform: translateY(-2px);`

---

## 🛡️ 2. Архитектура защиты от блокировщиков рекламы (AdBlock / uBlock / Brave Shield)
Большинство браузерных блокировщиков (uBlock Origin, AdBlock Plus, встроенный щит Brave) вырезают стандартные баннеры счётчиков (LiveInternet, Mail.ru, Rambler) по ключевым признакам в DOM:
1. Использование сторонних доменов в `<img src="https://counter.yadro.ru/...">`
2. Атрибуты и ID вида `licntA0F6`, `counter`, `analytics`
3. Ссылки с триггерными словами в `href`

### 💡 Решение (Двухуровневая изоляция):
1. **Визуальная кнопка (UI Button):** полностью локальная верстка со своими стилями и локально хостящейся иконкой (`/assets/img/stat_logo.png`). Она никогда не блокируется и всегда отображается в дизайне сайта.
2. **Фоновый маяк сбора статистики (Tracking Beacon):** запрос к счётчику отправляется асинхронно в памяти через объект `new Image()` в конце страницы без привязки к визуальным элементам DOM.

---

## 💻 3. Готовый HTML-код для вставки (WordPress / SPA / HTML)

```html
<!-- Контейнер баннеров в футере -->
<div class="footer-badges">
  <!-- Кнопка 1: Промо-баннер Gin IT (Продвижение сайта) -->
  <a href="http://prodvig-saita.ru/" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-brand" title="Gin IT — Создание и продвижение сайтов (prodvig-saita.ru)">
    <img src="/assets/img/gin_it_logo.gif" alt="Gin IT" class="badge-img-icon">
    <span class="badge-text-brand">Gin <strong>IT</strong></span>
  </a>

  <!-- Кнопка 2: Безопасный баннер LiveInternet (Статистика) -->
  <a href="https://www.liveinternet.ru/stat/eduard-dolgunow.gincz.com/index.html?lang=ru&nohelp=yes" target="_blank" rel="noopener noreferrer" class="footer-badge-btn badge-stat" title="LiveInternet — Статистика посещаемости сайта">
    <img src="/assets/img/stat_logo.png" alt="Статистика" class="badge-img-icon">
    <span class="badge-text-stat">Live<strong>Stat</strong></span>
  </a>
</div>

<!-- Фоновый невидимый сбор статистики LiveInternet -->
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

## 🎨 4. Готовый CSS (style.css / Дополнительные стили WordPress)

```css
/* Контейнер кнопок */
.footer-badges {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

/* Базовый стиль кнопки 32px */
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

/* Эффект зажигания и свечения при наведении */
.footer-badge-btn:hover {
  opacity: 1;
  filter: none;
  border-color: #fbbf24;
  background: rgba(251, 191, 36, 0.15);
  transform: translateY(-2px);
  box-shadow: 0 4px 14px rgba(251, 191, 36, 0.35);
  color: #ffffff;
}

/* Иконки внутри кнопок */
.badge-img-icon {
  height: 22px;
  width: auto;
  max-width: 28px;
  object-fit: contain;
  border-radius: 3px;
  display: block;
}

/* Оформление текста брендов */
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