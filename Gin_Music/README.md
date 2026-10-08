# 🪐 GIN-Music — Unified Ad-Free Music Player & Stream Aggregator

> **An ultra-lightweight, ad-free music streaming engine and progressive web application (PWA) unifying Deezer, Spotify, and VKontakte (VK Music) into a single high-performance player.**  
> *Developed by VladiMIR+AI*

---

## 🌟 Key Features

### 1. 🚫 100% Ad-Free & Subscription-Free Playback
- **Deezer Provider:** Direct MP3 (128 kbps / 320 kbps) and FLAC streaming via ARL session tokens with on-the-fly client/server Blowfish chunk decryption (no injected audio ads).
- **Spotify Provider:** 1-click browser OAuth 2.0 login to fetch personal saved tracks, custom playlists, and top recommendations. Audio playback is seamlessly resolved to ad-free high-bitrate direct streams.
- **VKontakte (VK Music) Provider:** Mobile API integration enabling full access to user audio collections, playlists, and recommendations without background playback time limits or ads.
- **Google Account Synchronization:** 1-click Google Profile linking to persist favorite songs, playlists, and connected accounts across all devices without fees or limits.

### 2. ⚡ Extreme Performance & Zero Bloat
- **Instant Cold Start (< 50ms):** Clean Vanilla HTML5/CSS3/ES6+ frontend with zero heavy frameworks or bloated Electron/CEF runtimes.
- **Offline-First & Local Caching:** SQLite database caching track metadata, search queries, favorites, and previously streamed audio chunks for instant repeat playback.
- **Adaptive Bitrate Selector:**
  - `⚡ Standard (128–192 kbps):` Ultra-fast buffering and minimal bandwidth consumption for mobile networks and headphones.
  - `💎 Hi-Fi (320 kbps / Lossless):` Maximum acoustic fidelity for home cinema systems, external DACs, and TV speaker setups.

### 3. 📱 Full Progressive Web App (PWA) Support
- **Desktop (Windows 10/11, macOS, Linux):** Installable directly from Chromium-based browsers (Chrome, Edge, Cent Browser) with a dedicated desktop shortcut, independent window frame, and native taskbar integration.
- **Mobile (Android & iOS):** Installable as a standalone app on Android (via WebAPK) and iPhone/iPad (via Safari *"Add to Home Screen"*).
- **Hardware Multimedia Controls:** Full integration with the browser's `MediaSession API` for lock screen controls, notification actions, and keyboard media keys (`Play/Pause`, `Next`, `Prev`, `Seek`, `Volume`).

---

## 🏗️ Architecture & Technology Stack

```
   ┌───────────────────────────────────────────────────────────┐
   │             Responsive Frontend (PWA / SPA)               │
   │  (Dark Glassmorphism UI, Virtualized List, Web Audio API) │
   └─────────────────────────────┬─────────────────────────────┘
                                 │ REST / HTTP2 / WebSockets
   ┌─────────────────────────────▼─────────────────────────────┐
   │             Asynchronous Backend (FastAPI / ASGI)         │
   └───────┬─────────────────────┼─────────────────────┬───────┘
           │                     │                     │
   ┌───────▼────────┐    ┌───────▼────────┐    ┌───────▼───────┐
   │ Deezer Engine  │    │ Spotify Engine │    │   VK Engine   │
   │ (ARL / Blowfish│    │ (OAuth 2.0 /   │    │ (Mobile API / │
   │  Decryption)   │    │ Meta Resolver) │    │ Direct MP3)   │
   └───────┬────────┘    └───────┬────────┘    └───────┬───────┘
           │                     │                     │
           └─────────────────────┼─────────────────────┘
                                 │
                     ┌───────────▼───────────┐
                     │ Local SQLite & Storage│
                     │ (Tokens, Cache, Favs) │
                     └───────────────────────┘
```

---

## 🚀 Installation & Deployment

### 1. Prerequisites
- Python 3.10+
- `pip` and `virtualenv`
- Nginx / Reverse Proxy with SSL (HTTPS required for PWA)

### 2. Clone & Setup Environment
```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Gin_Music

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required dependencies
pip install -r requirements.txt
```

### 3. Dependencies (`requirements.txt`)
```text
fastapi>=0.110.0
uvicorn>=0.28.0
aiohttp>=3.9.0
requests>=2.31.0
pycryptodome>=3.20.0
pydantic>=2.6.0
pillow>=10.0.0
```

### 4. Running the Application
```bash
# Launch FastAPI ASGI server
uvicorn backend.main:app --host 127.0.0.1 --port 8899 --workers 2
```

### 5. Production systemd Service (`/etc/systemd/system/gin_music.service`)
```ini
[Unit]
Description=GIN-Music Unified Ad-Free Music Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/gin_music
Environment=PYTHONPATH=/var/www/gin_music
ExecStart=/var/www/gin_music/venv/bin/uvicorn backend.main:app --host 127.0.0.1 --port 8899 --workers 2
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

---

## 🔒 Security & Privacy
- All session cookies (Deezer ARL), OAuth refresh tokens, and VK access tokens are stored in a **local encrypted SQLite database** on the server.
- No telemetry, analytics, or third-party tracking scripts.
- Zero external ad-networks or tracking pixels.

---

## 📄 License & Credits
- **License:** MIT License
- **Author:** [Vladimir Bulancev (GinCz)](https://github.com/GinCz) & VladiMIR+AI
