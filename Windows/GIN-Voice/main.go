// =============================================================================
// Execution Context : Go 1.22+ (Windows AMD64)
// Target Server     : Local Windows Desktop PC
// Description       : GIN-Voice Native Windows Client & Installer with Whisper AI, WaveIn Event Engine, Multi-Language UI, Cyber Dark GUI, On-Screen HUD [v009]
// =============================================================================

package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

const (
	AppName       = "GIN-Voice"
	AppVersion    = "v022"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v022]"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice"
	GroqKeysURL   = "https://console.groq.com/keys"
)

const (
	WM_USER           = 0x0400
	WM_TRAYICON       = WM_USER + 1
	WM_UPDATE_HUD     = WM_USER + 2
	WM_COMMAND        = 0x0111
	WM_DESTROY        = 0x0002
	WM_CLOSE          = 0x0010
	WM_SETFONT        = 0x0030
	WM_SETICON        = 0x0080
	WM_RBUTTONUP      = 0x0205
	WM_LBUTTONDBLCLK  = 0x0203
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CTLCOLORBTN    = 0x0135
	WM_PAINT          = 0x000F

	CALLBACK_EVENT  = 0x00050000
	WAVE_MAPPER     = 0xFFFFFFFF
	WAVE_FORMAT_PCM = 1

	WHDR_DONE     = 0x00000001
	WHDR_PREPARED = 0x00000002
	WHDR_INQUEUE  = 0x00000010

	NIM_ADD     = 0x00000000
	NIM_MODIFY  = 0x00000001
	NIM_DELETE  = 0x00000002
	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x00000800
	MF_CHECKED   = 0x00000008
	MF_UNCHECKED = 0x00000000
	MF_POPUP     = 0x00000010

	TPM_RIGHTBUTTON = 0x0002

	VK_F4           = 0x73
	VK_F8           = 0x77
	VK_F9           = 0x78
	VK_F10          = 0x79
	VK_F12          = 0x7B
	VK_CONTROL      = 0x11
	KEYEVENTF_KEYUP = 0x0002

	CF_UNICODETEXT = 13
	GMEM_MOVEABLE  = 0x0002

	SW_SHOWNORMAL     = 1
	SW_HIDE           = 0
	SW_SHOWNOACTIVATE = 4

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x0010
	LR_DEFAULTSIZE  = 0x0040
	ICON_SMALL      = 0
	ICON_BIG        = 1

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_POPUP            = 0x80000000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	ES_AUTOHSCROLL      = 0x0080
	BS_DEFPUSHBUTTON    = 0x0001
	BS_AUTOCHECKBOX     = 0x0003

	WS_EX_TOPMOST    = 0x00000008
	WS_EX_TOOLWINDOW = 0x00000080

	BIF_RETURNONLYFSDIRS = 0x0001
	BIF_NEWDIALOGSTYLE   = 0x0040

	// Menu Command IDs
	IDM_TOGGLE_RECORD = 1001
	IDM_SETUP_KEY     = 1002
	IDM_OPEN_DICT     = 1003
	IDM_LINK_FOLDER   = 1004
	IDM_OPEN_CONFIG   = 1005
	IDM_AUTOSTART     = 1006
	IDM_OPEN_HELP     = 1007
	IDM_EXIT          = 1008
	IDM_UPDATE_APP    = 1009
	IDM_CHECK_UPDATE  = 1010

	IDM_UI_LANG_BASE = 1500
	IDM_LANG_BASE    = 2000

	// Settings Dialog IDs
	IDC_BTN_SAVE    = 3001
	IDC_BTN_GROQ    = 3002
	IDC_EDIT_KEY    = 3003
	IDC_EDIT_FOLDER = 3004
	IDC_BTN_BROWSE  = 3005
	IDC_EDIT_HOTKEY = 3006
	IDC_BTN_DICT    = 3007
	IDC_BTN_TEST    = 3008
	IDC_EDIT_FONT   = 3009
	IDC_BTN_LANG_EN = 3010
	IDC_BTN_LANG_RU = 3011

	IDC_LANG_CHK_BASE = 4000
)

//go:embed app.ico
var defaultAppIco []byte

//go:embed app_rec.ico
var defaultAppRecIco []byte

//go:embed dictionary.json
var defaultDictionaryJSON []byte

//go:embed setup_guide.html
var defaultSetupGuideHTML []byte

//go:embed uninstall.bat
var defaultUninstallBAT []byte

//go:embed uninstall.ps1
var defaultUninstallPS1 []byte

//go:embed Uninstall.exe
var defaultUninstallEXE []byte

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	ole32    = syscall.NewLazyDLL("ole32.dll")
	uxtheme  = syscall.NewLazyDLL("uxtheme.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procRegisterClassExW     = user32.NewProc("RegisterClassExW")
	procCreateWindowExW      = user32.NewProc("CreateWindowExW")
	procDefWindowProcW       = user32.NewProc("DefWindowProcW")
	procDestroyWindow        = user32.NewProc("DestroyWindow")
	procPostQuitMessage      = user32.NewProc("PostQuitMessage")
	procGetMessageW          = user32.NewProc("GetMessageW")
	procTranslateMessage     = user32.NewProc("TranslateMessage")
	procDispatchMessageW     = user32.NewProc("DispatchMessageW")
	procCreatePopupMenu      = user32.NewProc("CreatePopupMenu")
	procAppendMenuW          = user32.NewProc("AppendMenuW")
	procTrackPopupMenu       = user32.NewProc("TrackPopupMenu")
	procDestroyMenu          = user32.NewProc("DestroyMenu")
	procSetForegroundWindow  = user32.NewProc("SetForegroundWindow")
	procGetCursorPos         = user32.NewProc("GetCursorPos")
	procOpenClipboard        = user32.NewProc("OpenClipboard")
	procCloseClipboard       = user32.NewProc("CloseClipboard")
	procEmptyClipboard       = user32.NewProc("EmptyClipboard")
	procSetClipboardData     = user32.NewProc("SetClipboardData")
	procGetClipboardData     = user32.NewProc("GetClipboardData")
	procIsClipboardAvailable = user32.NewProc("IsClipboardFormatAvailable")
	procKeybdEvent           = user32.NewProc("keybd_event")
	procMessageBoxW          = user32.NewProc("MessageBoxW")
	procLoadIconW            = user32.NewProc("LoadIconW")
	procLoadImageW           = user32.NewProc("LoadImageW")
	procShowWindow           = user32.NewProc("ShowWindow")
	procSendMessageW         = user32.NewProc("SendMessageW")
	procPostMessageW         = user32.NewProc("PostMessageW")
	procGetWindowTextW       = user32.NewProc("GetWindowTextW")
	procSetWindowTextW       = user32.NewProc("SetWindowTextW")
	procGetSystemMetrics     = user32.NewProc("GetSystemMetrics")
	procGetAsyncKeyState       = user32.NewProc("GetAsyncKeyState")
	procInvalidateRect       = user32.NewProc("InvalidateRect")
	procFindWindowW          = user32.NewProc("FindWindowW")

	procShellNotifyIconW     = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW        = shell32.NewProc("ShellExecuteW")
	procSHBrowseForFolderW   = shell32.NewProc("SHBrowseForFolderW")
	procSHGetPathFromIDListW = shell32.NewProc("SHGetPathFromIDListW")
	procCoTaskMemFree        = ole32.NewProc("CoTaskMemFree")

	procSetWindowTheme = uxtheme.NewProc("SetWindowTheme")

	procBeep                = kernel32.NewProc("Beep")
	procGlobalAlloc         = kernel32.NewProc("GlobalAlloc")
	procGlobalLock          = kernel32.NewProc("GlobalLock")
	procGlobalUnlock        = kernel32.NewProc("GlobalUnlock")
	procGlobalFree          = kernel32.NewProc("GlobalFree")
	procGetModuleHandleW    = kernel32.NewProc("GetModuleHandleW")
	procCreateEventW        = kernel32.NewProc("CreateEventW")
	procSetEvent            = kernel32.NewProc("SetEvent")
	procResetEvent          = kernel32.NewProc("ResetEvent")
	procWaitForSingleObject = kernel32.NewProc("WaitForSingleObject")
	procCloseHandle         = kernel32.NewProc("CloseHandle")
	procCreateMutexW        = kernel32.NewProc("CreateMutexW")
	procGetLastError        = kernel32.NewProc("GetLastError")

	procCreateSolidBrush = gdi32.NewProc("CreateSolidBrush")
	procCreateFontW      = gdi32.NewProc("CreateFontW")
	procSetTextColor     = gdi32.NewProc("SetTextColor")
	procSetBkColor       = gdi32.NewProc("SetBkColor")

	procWaveInOpen            = winmm.NewProc("waveInOpen")
	procWaveInPrepareHeader   = winmm.NewProc("waveInPrepareHeader")
	procWaveInUnprepareHeader = winmm.NewProc("waveInUnprepareHeader")
	procWaveInAddBuffer       = winmm.NewProc("waveInAddBuffer")
	procWaveInStart           = winmm.NewProc("waveInStart")
	procWaveInStop            = winmm.NewProc("waveInStop")
	procWaveInReset           = winmm.NewProc("waveInReset")
	procWaveInClose           = winmm.NewProc("waveInClose")
	procPlaySoundW            = winmm.NewProc("PlaySoundW")
)

type POINT struct {
	X int32
	Y int32
}

type WNDCLASSEXW struct {
	CbSize        uint32
	Style         uint32
	LpfnWndProc   uintptr
	CbClsExtra    int32
	CbWndExtra    int32
	HInstance     uintptr
	HIcon         uintptr
	HCursor       uintptr
	HbrBackground uintptr
	LpszMenuName  *uint16
	LpszClassName *uint16
	HIconSm       uintptr
}

type NOTIFYICONDATAW struct {
	CbSize           uint32
	HWnd             uintptr
	UID              uint32
	UFlags           uint32
	UCallbackMessage uint32
	HIcon            uintptr
	SzTip            [128]uint16
}

type MSG struct {
	HWnd    uintptr
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      POINT
}

type BROWSEINFOW struct {
	HwndOwner      uintptr
	PidlRoot       uintptr
	PszDisplayName *uint16
	LpszTitle      *uint16
	UlFlags        uint32
	Lpfn           uintptr
	LParam         uintptr
	IIcon          int32
}

type WAVEFORMATEX struct {
	WFormatTag      uint16
	NChannels       uint16
	NSamplesPerSec  uint32
	NAvgBytesPerSec uint32
	NBlockAlign     uint16
	WBitsPerSample  uint16
	CbSize          uint16
}

type WAVEHDR struct {
	LpData          uintptr
	DwBufferLength  uint32
	DwBytesRecorded uint32
	DwUser          uintptr
	DwFlags         uint32
	DwLoops         uint32
	LpNext          uintptr
	Reserved        uintptr
}

type LanguageItem struct {
	Code string `json:"code"`
	Name string `json:"name"`
}

type UIStringBundle struct {
	MenuStartDictation  string
	MenuStopDictation   string
	MenuSpeechLang      string
	MenuInterfaceLang   string
	MenuKeyConfigured   string
	MenuKeyNotSet       string
	MenuOpenDict        string
	MenuLinkFolder      string
	MenuAutostart       string
	MenuHelp            string
	MenuExit            string
	MenuCheckUpdates    string
	SettingsTitle       string
	SettingsHeader      string
	SettingsKeyLabel    string
	SettingsGetGroq     string
	SettingsTestBtn     string
	SettingsHotkey      string
	SettingsHotkeyTip   string
	SettingsFont        string
	SettingsFontTip     string
	SettingsFolder      string
	SettingsBrowse      string
	SettingsLangs       string
	SettingsSave        string
	SettingsDict        string
	SettingsSavedTitle  string
	SettingsSavedMsg    string
	HudRecording        string
	HudTranscribing     string
	HudPasted           string
	HudEmpty            string
	HudError            string
	HudUpdating         string
	HudUpdateDone       string
	HudUpdateError      string
	HudUpdateNotice     string
	HudCheckingUpdate   string
	HudUpToDate         string
	HudCheckFailed      string
	MenuUpdateAvailable string
	Ready               string
}

type Config struct {
	Version               string         `json:"version"`
	UILanguage            string         `json:"ui_language"` // EN, RU, CS, IT, ES, FR
	FirstRun              bool           `json:"first_run"`
	Hotkey                string         `json:"hotkey"`
	HotkeyVK              uint32         `json:"hotkey_vk"`
	HotkeyMod             uint32         `json:"hotkey_mod"`
	HUDFont               string         `json:"hud_font"`
	ActiveLanguages       []string       `json:"active_languages"`
	AllLanguages          []LanguageItem `json:"all_languages"`
	GroqAPIKey            string         `json:"groq_api_key"`
	SoundFeedback         bool           `json:"sound_feedback"`
	AutoPaste             bool           `json:"auto_paste"`
	RestoreClipboard      bool           `json:"restore_clipboard"`
	Autostart             bool           `json:"autostart"`
	LinkedKnowledgeFolder string         `json:"linked_knowledge_folder"`
}

var (
	appDir          string
	configFile      string
	dictFile        string
	helpFile        string
	logFile         string
	config          Config
	dictionary      map[string]string
	dictMutex       sync.RWMutex
	hwndMain        uintptr
	hwndSetup       uintptr
	hwndHUD         uintptr
	hwndHUDText     uintptr
	hwndHeader      uintptr
	hwndLblKey      uintptr
	hwndLblHot      uintptr
	hwndLblHotTip   uintptr
	hwndLblFont     uintptr
	hwndLblFolder   uintptr
	hwndLblLangs    uintptr
	hwndEditKey     uintptr
	hwndEditFolder  uintptr
	hwndEditHotkey  uintptr
	hwndEditFont    uintptr
	btnLangEN       uintptr
	btnLangRU       uintptr
	btnGroq         uintptr
	btnTest         uintptr
	btnBrowse       uintptr
	btnSave         uintptr
	btnDict         uintptr
	langCheckHWnd   = make(map[string]uintptr)
	nid             NOTIFYICONDATAW
	isRecording     bool
	recordMutex     sync.Mutex
	trayCreated     bool
	updateAvailable string
	updateMutex     sync.Mutex
	isUpdating      bool
	updateExecMutex sync.Mutex
	hIconNormal     uintptr
	hIconRec        uintptr
	hBrushDarkBg    uintptr
	hBrushEditBg    uintptr
	hFontNormal     uintptr
	hFontBold       uintptr
	hFontHeader     uintptr
	hFontHUD        uintptr

	// WaveIn Event Audio Engine
	hWaveIn       uintptr
	hWaveEvent    uintptr
	waveBuffers   [8][]byte
	waveHeaders   [8]WAVEHDR
	capturedAudio []byte
	audioMutex    sync.Mutex

	// UI Languages supported
	UILanguages = []LanguageItem{
		{"EN", "English"},
		{"RU", "Русский"},
		{"CS", "Čeština"},
		{"IT", "Italiano"},
		{"ES", "Español"},
		{"FR", "Français"},
	}

	// Recognition languages: 18 items (6 rows x 3 columns) perfectly balanced
	MasterLanguages = []LanguageItem{
		{"EN", "English (Английский)"},
		{"CS", "Čeština (Czech)"},
		{"RU", "Русский (Russian)"},
		{"DE", "Deutsch (German)"},
		{"UK", "Українська (Ukrainian)"},
		{"ES", "Español (Spanish)"},
		{"FR", "Français (French)"},
		{"IT", "Italiano (Italian)"},
		{"PL", "Polski (Polish)"},
		{"ZH", "中文 (Chinese)"},
		{"JA", "日本語 (Japanese)"},
		{"KO", "한국어 (Korean)"},
		{"AR", "العربية (Arabic)"},
		{"HE", "עברית (Hebrew)"},
		{"TR", "Türkçe (Turkish)"},
		{"PT", "Português (Portuguese)"},
		{"NL", "Nederlands (Dutch)"},
		{"SV", "Svenska (Swedish)"},
	}

	UIStrings = map[string]UIStringBundle{
		"EN": {
			MenuStartDictation:  "🔴 Start Dictation [%s]",
			MenuStopDictation:   "⏹️ Stop Dictation [%s]",
			MenuUpdateAvailable: "✨ Update Available: %s (Click to Update)",
			MenuSpeechLang:      "🌐 Speech Recognition (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Interface Language",
			MenuKeyConfigured:   "🔑 Groq API Key: Configured",
			MenuKeyNotSet:       "⚠️ Groq API Key: NOT configured (Click to set)",
			MenuOpenDict:        "📖 Open Dictionary (dictionary.json)",
			MenuLinkFolder:      "📁 Link Knowledge Folder...",
			MenuAutostart:       "⚡ Autostart on Windows Boot",
			MenuHelp:            "❓ Setup Guide & Help",
			MenuCheckUpdates:    "🔄 Check for Updates...",
			MenuExit:            "❌ Exit GIN-Voice",
			SettingsTitle:       "GIN-Voice - Settings & Control Center",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Instant Voice Typing",
			SettingsKeyLabel:    "🔑 Groq Whisper API Key:",
			SettingsGetGroq:     "🌐 Get Free Key at Groq.com",
			SettingsTestBtn:     "🧪 Test Key",
			SettingsHotkey:      "⚡ Hotkey:",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 HUD Font:",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift, Consolas)",
			SettingsFolder:      "📁 Linked Knowledge / Project Folder (Auto-Dictionary):",
			SettingsBrowse:      "📂 Browse...",
			SettingsLangs:       "🌐 Active Recognition Languages (Whisper AI):",
			SettingsSave:        "💾 Save & Apply",
			SettingsDict:        "📖 Edit Dictionary",
			SettingsSavedTitle:  "GIN-Voice - Ready",
			SettingsSavedMsg:    "✅ Settings saved successfully!\n\n• GIN-Voice is active in the System Tray (near clock).\n• Hotkey: [%s] (Press anytime to start/stop speaking).\n• HUD Font: %s",
			HudRecording:        "🔴 RECORDING... Speak now [%s to Finish]",
			HudTranscribing:     "⚡ Transcribing with Whisper AI...",
			HudPasted:           "✅ Pasted: %s",
			HudEmpty:            "⚠️ Audio recording was empty.",
			HudError:            "❌ Error: %s",
			HudUpdating:         "⬇️ Downloading GIN-Voice %s update...",
			HudUpdateDone:       "✅ Update downloaded! Restarting...",
			HudUpdateError:      "❌ Update failed: %s",
			HudUpdateNotice:     "✨ GIN-Voice %s update is available!",
			HudCheckingUpdate:   "🔍 Checking for updates...",
			HudUpToDate:         "✅ GIN-Voice is up to date (%s)",
			HudCheckFailed:      "⚠️ Update check failed: %s",
			Ready:               "Ready",
		},
		"RU": {
			MenuStartDictation:  "🔴 Начать диктовку [%s]",
			MenuStopDictation:   "⏹️ Остановить диктовку [%s]",
			MenuUpdateAvailable: "✨ Доступно обновление: %s (Нажмите для обновления)",
			MenuSpeechLang:      "🌐 Языки распознавания (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Язык интерфейса",
			MenuKeyConfigured:   "🔑 Groq API Ключ: Настроен",
			MenuKeyNotSet:       "⚠️ Groq API Ключ: НЕ задан (Нажмите для ввода)",
			MenuOpenDict:        "📖 Открыть словарь автозамен (dictionary.json)",
			MenuLinkFolder:      "📁 Привязать общую папку с базами знаний...",
			MenuAutostart:       "⚡ Автозапуск при старте Windows",
			MenuHelp:            "❓ Инструкция и справка",
			MenuCheckUpdates:    "🔄 Проверить обновления...",
			MenuExit:            "❌ Выход из GIN-Voice",
			SettingsTitle:       "GIN-Voice - Центр Управления",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Мгновенный Голосовой Ввод",
			SettingsKeyLabel:    "🔑 Groq Whisper API Key:",
			SettingsGetGroq:     "🌐 Получить бесплатный ключ на Groq.com",
			SettingsTestBtn:     "🧪 Проверить",
			SettingsHotkey:      "⚡ Горячая клавиша:",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 Шрифт HUD:",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift, Consolas)",
			SettingsFolder:      "📁 Общая папка с базами знаний / проектами (Автословарь):",
			SettingsBrowse:      "📂 Обзор...",
			SettingsLangs:       "🌐 Активные языки распознавания (Whisper AI):",
			SettingsSave:        "💾 Сохранить и Применить",
			SettingsDict:        "📖 Редактировать словарь",
			SettingsSavedTitle:  "GIN-Voice - Готов к работе",
			SettingsSavedMsg:    "✅ Настройки успешно сохранены!\n\n• GIN-Voice активен и работает в системном трее (возле часов).\n• Горячая клавиша: [%s] (Нажмите в любом месте для диктовки).\n• Шрифт HUD: %s",
			HudRecording:        "🔴 ИДЁТ ЗАПИСЬ... Говорите [%s для Завершения]",
			HudTranscribing:     "⚡ Распознавание речи через Whisper AI...",
			HudPasted:           "✅ Вставлено: %s",
			HudEmpty:            "⚠️ Запись звука оказалась пустой.",
			HudError:            "❌ Ошибка: %s",
			HudUpdating:         "⬇️ Загрузка обновления GIN-Voice %s...",
			HudUpdateDone:       "✅ Обновление загружено! Перезапуск...",
			HudUpdateError:      "❌ Ошибка обновления: %s",
			HudUpdateNotice:     "✨ Доступна новая версия GIN-Voice %s!",
			HudCheckingUpdate:   "🔍 Проверка обновлений...",
			HudUpToDate:         "✅ У вас последняя версия GIN-Voice (%s)",
			HudCheckFailed:      "⚠️ Ошибка проверки обновлений: %s",
			Ready:               "Готов к работе",
		},
		"CS": {
			MenuStartDictation:  "🔴 Spustit diktování [%s]",
			MenuStopDictation:   "⏹️ Zastavit diktování [%s]",
			MenuUpdateAvailable: "✨ Dostupná aktualizace: %s (Klikněte pro instalaci)",
			MenuSpeechLang:      "🌐 Jazyky rozpoznávání (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Jazyk rozhraní",
			MenuKeyConfigured:   "🔑 Groq API Klíč: Nastaven",
			MenuKeyNotSet:       "⚠️ Groq API Klíč: NENÍ nastaven (Klikněte pro zadání)",
			MenuOpenDict:        "📖 Otevřít slovník (dictionary.json)",
			MenuLinkFolder:      "📁 Propojit složku znalostí...",
			MenuAutostart:       "⚡ Automatické spuštění při startu Windows",
			MenuHelp:            "❓ Nápověda a průvodce",
			MenuCheckUpdates:    "🔄 Zkontrolovat aktualizace...",
			MenuExit:            "❌ Ukončit GIN-Voice",
			SettingsTitle:       "GIN-Voice - Nastavení a Ovládací Centrum",
			SettingsHeader:      "🎙️ GIN-Voice od VladiMIR+AI — Okamžité Hlasové Psaní",
			SettingsKeyLabel:    "🔑 Groq Whisper API Klíč:",
			SettingsGetGroq:     "🌐 Získat klíč zdarma na Groq.com",
			SettingsTestBtn:     "🧪 Otestovat",
			SettingsHotkey:      "⚡ Klávesová zkratka:",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 Písmo HUD:",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift)",
			SettingsFolder:      "📁 Propojená složka projektů (Automatický slovník):",
			SettingsBrowse:      "📂 Procházet...",
			SettingsLangs:       "🌐 Aktivní jazyky rozpoznávání (Whisper AI):",
			SettingsSave:        "💾 Uložit a Použít",
			SettingsDict:        "📖 Upravit slovník",
			SettingsSavedTitle:  "GIN-Voice - Připraven",
			SettingsSavedMsg:    "✅ Nastavení bylo úspěšně uloženo!\n\n• GIN-Voice je aktivní v systémové liště.\n• Klávesová zkratka: [%s]\n• Písmo HUD: %s",
			HudRecording:        "🔴 NAHRÁVÁNÍ... Mluvte [%s pro Dokončení]",
			HudTranscribing:     "⚡ Přepisuji řeč pomocí Whisper AI...",
			HudPasted:           "✅ Vloženo: %s",
			HudEmpty:            "⚠️ Záznam byl prázdný.",
			HudError:            "❌ Chyba: %s",
			HudUpdating:         "⬇️ Stahování aktualizace GIN-Voice %s...",
			HudUpdateDone:       "✅ Aktualizace stažena! Restartuji...",
			HudUpdateError:      "❌ Chyba aktualizace: %s",
			HudUpdateNotice:     "✨ Je k dispozici nová verze GIN-Voice %s!",
			HudCheckingUpdate:   "🔍 Kontrola aktualizací...",
			HudUpToDate:         "✅ Používáte nejnovější verzi GIN-Voice (%s)",
			HudCheckFailed:      "⚠️ Kontrola aktualizací selhala: %s",
			Ready:               "Připraven",
		},
		"IT": {
			MenuStartDictation:  "🔴 Avvia dettatura [%s]",
			MenuStopDictation:   "⏹️ Ferma dettatura [%s]",
			MenuUpdateAvailable: "✨ Aggiornamento disponibile: %s (Clicca per aggiornare)",
			MenuSpeechLang:      "🌐 Lingue di riconoscimento (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Lingua dell'interfaccia",
			MenuKeyConfigured:   "🔑 Chiave Groq API: Configurato",
			MenuKeyNotSet:       "⚠️ Chiave Groq API: NON impostata (Clicca per inserire)",
			MenuOpenDict:        "📖 Apri dizionario (dictionary.json)",
			MenuLinkFolder:      "📁 Collega cartella progetti...",
			MenuAutostart:       "⚡ Avvio automatico con Windows",
			MenuHelp:            "❓ Guida e supporto",
			MenuCheckUpdates:    "🔄 Controlla aggiornamenti...",
			MenuExit:            "❌ Esci da GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centro di controllo",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Digitazione vocale istantanea",
			SettingsKeyLabel:    "🔑 Chiave Groq Whisper API:",
			SettingsGetGroq:     "🌐 Ottieni chiave gratuita su Groq.com",
			SettingsTestBtn:     "🧪 Verifica",
			SettingsHotkey:      "⚡ Tasto rapido:",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 Font HUD:",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift)",
			SettingsFolder:      "📁 Cartella progetti collegata (Dizionario automatico):",
			SettingsBrowse:      "📂 Sfoglia...",
			SettingsLangs:       "🌐 Lingue di riconoscimento attive (Whisper AI):",
			SettingsSave:        "💾 Salva e applica",
			SettingsDict:        "📖 Modifica dizionario",
			SettingsSavedTitle:  "GIN-Voice - Pronto",
			SettingsSavedMsg:    "✅ Impostazioni salvate!\n\n• GIN-Voice è attivo nella barra delle applicazioni.\n• Tasto rapido: [%s]\n• Font HUD: %s",
			HudRecording:        "🔴 REGISTRAZIONE... Parla [%s per Terminare]",
			HudTranscribing:     "⚡ Trascrizione vocale con Whisper AI...",
			HudPasted:           "✅ Incollato: %s",
			HudEmpty:            "⚠️ La registrazione audio era vuota.",
			HudError:            "❌ Errore: %s",
			HudUpdating:         "⬇️ Download aggiornamento GIN-Voice %s...",
			HudUpdateDone:       "✅ Aggiornamento pronto! Riavvio...",
			HudUpdateError:      "❌ Errore aggiornamento: %s",
			HudUpdateNotice:     "✨ È disponibile una nuova versione di GIN-Voice %s!",
			HudCheckingUpdate:   "🔍 Controllo aggiornamenti...",
			HudUpToDate:         "✅ GIN-Voice è aggiornato (%s)",
			HudCheckFailed:      "⚠️ Controllo aggiornamenti fallito: %s",
			Ready:               "Pronto",
		},
		"ES": {
			MenuStartDictation:  "🔴 Iniciar dictado [%s]",
			MenuStopDictation:   "⏹️ Detener dictado [%s]",
			MenuUpdateAvailable: "✨ Actualización disponible: %s (Haga clic para actualizar)",
			MenuSpeechLang:      "🌐 Idiomas de reconocimiento (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Idioma de la interfaz",
			MenuKeyConfigured:   "🔑 Clave Groq API: Configurada",
			MenuKeyNotSet:       "⚠️ Clave Groq API: NO configurada (Haga clic para ingresar)",
			MenuOpenDict:        "📖 Abrir diccionario (dictionary.json)",
			MenuLinkFolder:      "📁 Vincular carpeta de conocimientos...",
			MenuAutostart:       "⚡ Inicio automático con Windows",
			MenuHelp:            "❓ Guía y ayuda",
			MenuCheckUpdates:    "🔄 Buscar actualizaciones...",
			MenuExit:            "❌ Salir de GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centro de control",
			SettingsHeader:      "🎙️ GIN-Voice por VladiMIR+AI — Dictado por voz instantáneo",
			SettingsKeyLabel:    "🔑 Clave Groq Whisper API:",
			SettingsGetGroq:     "🌐 Obtener clave gratis en Groq.com",
			SettingsTestBtn:     "🧪 Probar clave",
			SettingsHotkey:      "⚡ Tecla rápida:",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 Fuente HUD:",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift)",
			SettingsFolder:      "📁 Carpeta vinculada de proyectos (Diccionario automático):",
			SettingsBrowse:      "📂 Examinar...",
			SettingsLangs:       "🌐 Idiomas de reconocimiento activos (Whisper AI):",
			SettingsSave:        "💾 Guardar y aplicar",
			SettingsDict:        "📖 Editar diccionario",
			SettingsSavedTitle:  "GIN-Voice - Listo",
			SettingsSavedMsg:    "✅ ¡Configuración guardada!\n\n• GIN-Voice está activo en la bandeja del sistema.\n• Tecla rápida: [%s]\n• Fuente HUD: %s",
			HudRecording:        "🔴 GRABANDO... Hable [%s para Terminar]",
			HudTranscribing:     "⚡ Transcribiendo voz con Whisper AI...",
			HudPasted:           "✅ Pegado: %s",
			HudEmpty:            "⚠️ La grabación de audio estaba vacía.",
			HudError:            "❌ Error: %s",
			HudUpdating:         "⬇️ Descargando actualización GIN-Voice %s...",
			HudUpdateDone:       "✅ Actualización lista! Reiniciando...",
			HudUpdateError:      "❌ Error al actualizar: %s",
			HudUpdateNotice:     "✨ ¡Nueva versión de GIN-Voice %s disponible!",
			HudCheckingUpdate:   "🔍 Buscando actualizaciones...",
			HudUpToDate:         "✅ GIN-Voice está actualizado (%s)",
			HudCheckFailed:      "⚠️ Error al buscar actualizaciones: %s",
			Ready:               "Listo",
		},
		"FR": {
			MenuStartDictation:  "🔴 Démarrer la dictée [%s]",
			MenuStopDictation:   "⏹️ Arrêter la dictée [%s]",
			MenuUpdateAvailable: "✨ Mise à jour disponible : %s (Cliquez pour installer)",
			MenuSpeechLang:      "🌐 Langues de reconnaissance (Whisper AI)",
			MenuInterfaceLang:   "🖥️ Langue de l'interface",
			MenuKeyConfigured:   "🔑 Clé Groq API : Configurée",
			MenuKeyNotSet:       "⚠️ Clé Groq API : NON configurée (Cliquez pour définir)",
			MenuOpenDict:        "📖 Ouvrir le dictionnaire (dictionary.json)",
			MenuLinkFolder:      "📁 Lier le dossier de connaissances...",
			MenuAutostart:       "⚡ Démarrage automatique avec Windows",
			MenuHelp:            "❓ Guide d'installation et aide",
			MenuCheckUpdates:    "🔄 Vérifier les mises à jour...",
			MenuExit:            "❌ Quitter GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centre de configuration",
			SettingsHeader:      "🎙️ GIN-Voice par VladiMIR+AI — Saisie vocale instantanée",
			SettingsKeyLabel:    "🔑 Clé Groq Whisper API :",
			SettingsGetGroq:     "🌐 Obtenir une clé gratuite sur Groq.com",
			SettingsTestBtn:     "🧪 Tester",
			SettingsHotkey:      "⚡ Raccourci :",
			SettingsHotkeyTip:   "(F8, F4, F9, F10, F12)",
			SettingsFont:        "🎨 Police HUD :",
			SettingsFontTip:     "(Comfortaa, Segoe UI, Bahnschrift)",
			SettingsFolder:      "📁 Dossier de projets lié (Dictionnaire automatique) :",
			SettingsBrowse:      "📂 Parcourir...",
			SettingsLangs:       "🌐 Langues de reconnaissance actives (Whisper AI) :",
			SettingsSave:        "💾 Enregistrer et appliquer",
			SettingsDict:        "📖 Modifier le dictionnaire",
			SettingsSavedTitle:  "GIN-Voice - Prêt",
			SettingsSavedMsg:    "✅ Paramètres enregistrés !\n\n• GIN-Voice est actif dans la barre des tâches.\n• Raccourci : [%s]\n• Police HUD : %s",
			HudRecording:        "🔴 ENREGISTREMENT... Parlez [%s pour Terminer]",
			HudTranscribing:     "⚡ Transcription vocale avec Whisper AI...",
			HudPasted:           "✅ Collé : %s",
			HudEmpty:            "⚠️ L'enregistrement audio était vide.",
			HudError:            "❌ Erreur : %s",
			HudUpdating:         "⬇️ Téléchargement de la mise à jour GIN-Voice %s...",
			HudUpdateDone:       "✅ Mise à jour prête ! Redémarrage...",
			HudUpdateError:      "❌ Échec de la mise à jour : %s",
			HudUpdateNotice:     "✨ Une nouvelle version de GIN-Voice %s est disponible !",
			HudCheckingUpdate:   "🔍 Vérification des mises à jour...",
			HudUpToDate:         "✅ GIN-Voice est à jour (%s)",
			HudCheckFailed:      "⚠️ Échec de la vérification : %s",
			Ready:               "Prêt",
		},
	}
)

func getUI() UIStringBundle {
	code := strings.ToUpper(config.UILanguage)
	if b, exists := UIStrings[code]; exists {
		return b
	}
	return UIStrings["EN"]
}

func writeLog(msg string) {
	if logFile == "" {
		return
	}
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		defer f.Close()
		ts := time.Now().Format("2006-01-02 15:04:05")
		f.WriteString(fmt.Sprintf("[%s] %s\n", ts, msg))
	}
}

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

func loadIconFromFile(fileName string, defaultBytes []byte) uintptr {
	iconPath := filepath.Join(appDir, fileName)
	if _, err := os.Stat(iconPath); os.IsNotExist(err) && len(defaultBytes) > 0 {
		_ = os.WriteFile(iconPath, defaultBytes, 0644)
	}

	h, _, _ := procLoadImageW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr(iconPath))),
		IMAGE_ICON,
		0, 0,
		LR_LOADFROMFILE|LR_DEFAULTSIZE,
	)
	if h != 0 {
		return h
	}

	hSys, _, _ := procLoadIconW.Call(0, 32512) // IDI_APPLICATION
	return hSys
}

func loadIcons() {
	hIconNormal = loadIconFromFile("app.ico", defaultAppIco)
	hIconRec = loadIconFromFile("app_rec.ico", defaultAppRecIco)
}

func createGentleTone(freq float64, durationMs int, volume float64) []byte {
	sampleRate := 44100
	numSamples := sampleRate * durationMs / 1000
	pcm := make([]byte, numSamples*2)

	for i := 0; i < numSamples; i++ {
		t := float64(i) / float64(sampleRate)
		envelope := math.Sin(math.Pi * float64(i) / float64(numSamples))
		sample := int16(math.Sin(2*math.Pi*freq*t) * envelope * volume * 32767.0)

		pcm[i*2] = byte(sample)
		pcm[i*2+1] = byte(sample >> 8)
	}

	dataLen := len(pcm)
	totalLen := 36 + dataLen
	byteRate := sampleRate * 1 * 2
	blockAlign := 2

	buf := make([]byte, 44+dataLen)
	copy(buf[0:], []byte("RIFF"))
	buf[4] = byte(totalLen)
	buf[5] = byte(totalLen >> 8)
	buf[6] = byte(totalLen >> 16)
	buf[7] = byte(totalLen >> 24)
	copy(buf[8:], []byte("WAVE"))
	copy(buf[12:], []byte("fmt "))
	buf[16] = 16
	buf[20] = 1 // PCM
	buf[22] = 1 // mono
	buf[24] = byte(sampleRate)
	buf[25] = byte(sampleRate >> 8)
	buf[26] = byte(sampleRate >> 16)
	buf[27] = byte(sampleRate >> 24)
	buf[28] = byte(byteRate)
	buf[29] = byte(byteRate >> 8)
	buf[30] = byte(byteRate >> 16)
	buf[31] = byte(byteRate >> 24)
	buf[32] = byte(blockAlign)
	buf[33] = byte(blockAlign >> 8)
	buf[34] = 16 // 16 bits
	buf[35] = 0
	copy(buf[36:], []byte("data"))
	buf[40] = byte(dataLen)
	buf[41] = byte(dataLen >> 8)
	buf[42] = byte(dataLen >> 16)
	buf[43] = byte(dataLen >> 24)
	copy(buf[44:], pcm)
	return buf
}

var (
	soundStartRecord = createGentleTone(580.0, 85, 0.16) // Gentle high soft chime
	soundStopRecord  = createGentleTone(440.0, 85, 0.14) // Gentle low soft chime
	soundSave        = createGentleTone(620.0, 90, 0.15) // Gentle save confirmation
	soundNotice      = createGentleTone(350.0, 110, 0.14) // Subtle soft blip
)

func playGentleSound(soundType string) {
	if !config.SoundFeedback {
		return
	}
	var soundData []byte
	switch soundType {
	case "start":
		soundData = soundStartRecord
	case "stop":
		soundData = soundStopRecord
	case "save":
		soundData = soundSave
	default:
		soundData = soundNotice
	}

	if len(soundData) > 0 {
		go func(data []byte) {
			procPlaySoundW.Call(
				uintptr(unsafe.Pointer(&data[0])),
				0,
				0x0000|0x0004|0x0002, // SND_SYNC | SND_MEMORY | SND_NODEFAULT on dedicated thread
			)
		}(soundData)
	}
}

func updateHUD(visible bool, text string) {
	if hwndHUD == 0 {
		return
	}
	if visible {
		procSetWindowTextW.Call(hwndHUDText, uintptr(unsafe.Pointer(strPtr(text))))
		procShowWindow.Call(hwndHUD, SW_SHOWNOACTIVATE)
	} else {
		procShowWindow.Call(hwndHUD, SW_HIDE)
	}
}

func updateTrayState(recording bool, tipText string) {
	if !trayCreated {
		return
	}
	if recording {
		nid.HIcon = hIconRec
	} else {
		nid.HIcon = hIconNormal
	}

	for i := range nid.SzTip {
		nid.SzTip[i] = 0
	}
	uTip, _ := syscall.UTF16FromString(tipText)
	copy(nid.SzTip[:], uTip)

	nid.UFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE
	procShellNotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
}

func initTrayIcon() {
	if trayCreated {
		return
	}
	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.HWnd = hwndMain
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconNormal

	ui := getUI()
	tip := fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey)
	uTip, _ := syscall.UTF16FromString(tip)
	copy(nid.SzTip[:], uTip)

	procShellNotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))
	trayCreated = true
}

func loadConfig() {
	config = Config{
		Version:               AppVersion,
		UILanguage:            "EN", // English by default
		FirstRun:              true,
		Hotkey:                "F4",
		HotkeyVK:              VK_F4,
		HotkeyMod:             0,
		HUDFont:               "Comfortaa",
		ActiveLanguages:       []string{"EN"}, // Only English selected by default upon initial installation
		AllLanguages:          MasterLanguages,
		GroqAPIKey:            "", // Strictly empty by default - no hardcoded keys, no env fallback
		SoundFeedback:         true,
		AutoPaste:             true,
		RestoreClipboard:      true,
		Autostart:             false,
		LinkedKnowledgeFolder: `D:\AI\BASE`,
	}

	data, err := os.ReadFile(configFile)
	if err == nil {
		_ = json.Unmarshal(data, &config)
	}

	if config.UILanguage == "" {
		config.UILanguage = "EN"
	}

	if config.Hotkey == "" {
		config.Hotkey = "F4"
		config.HotkeyVK = VK_F4
	}

	if config.HUDFont == "" {
		config.HUDFont = "Comfortaa"
	}

	if config.LinkedKnowledgeFolder == "" {
		config.LinkedKnowledgeFolder = `D:\AI\BASE`
	}

	if len(config.ActiveLanguages) == 0 {
		config.ActiveLanguages = []string{"EN"}
	}

	config.AllLanguages = MasterLanguages
	saveConfig()
}

func saveConfig() {
	data, err := json.MarshalIndent(config, "", "  ")
	if err == nil {
		_ = os.WriteFile(configFile, data, 0644)
	}
}

func loadDictionary() {
	dictMutex.Lock()
	defer dictMutex.Unlock()

	dictionary = make(map[string]string)
	data, err := os.ReadFile(dictFile)
	if err == nil {
		_ = json.Unmarshal(data, &dictionary)
	} else {
		if len(defaultDictionaryJSON) > 0 {
			_ = json.Unmarshal(defaultDictionaryJSON, &dictionary)
		}
		data, _ := json.MarshalIndent(dictionary, "", "  ")
		_ = os.WriteFile(dictFile, data, 0644)
	}
}

func applyDictionary(input string) string {
	dictMutex.RLock()
	defer dictMutex.RUnlock()

	type dictEntry struct {
		key   string
		value string
	}
	var entries []dictEntry
	for k, v := range dictionary {
		entries = append(entries, dictEntry{key: k, value: v})
	}

	sort.Slice(entries, func(i, j int) bool {
		return len(entries[i].key) > len(entries[j].key)
	})

	result := input
	for _, entry := range entries {
		pattern := strings.ToLower(entry.key)
		lowerRes := strings.ToLower(result)

		idx := strings.Index(lowerRes, pattern)
		for idx != -1 {
			result = result[:idx] + entry.value + result[idx+len(pattern):]
			lowerRes = strings.ToLower(result)
			idx = strings.Index(lowerRes, pattern)
		}
	}
	return result
}

var hallucinationRegexes = []*regexp.Regexp{
	// Subtitles / Credits / Translators (Whisper training artifacts)
	regexp.MustCompile(`(?i)(субтитры\s+(создавал[аи]?|делал[аи]?|переводил[аи]?|добавил[аи]?|подготовил[аи]?|оформил[аи]?|редактировал[аи]?).*)`),
	regexp.MustCompile(`(?i)((редактор|автор|перевод|синхронизация)\s+субтитров.*)`),
	regexp.MustCompile(`(?i)(субтитры\s*:\s*.*)`),
	regexp.MustCompile(`(?i)(dimatorzok.*)`),
	regexp.MustCompile(`(?i)(dima\s*torzok.*)`),
	regexp.MustCompile(`(?i)(amara\.org.*)`),
	regexp.MustCompile(`(?i)(opensubtitles(\.org)?.*)`),
	regexp.MustCompile(`(?i)(titulky\s+(vytvořil|připravil|přeložil).*)`),
	regexp.MustCompile(`(?i)(překlad\s+titulků.*)`),
	regexp.MustCompile(`(?i)(untertitel\s+(von|erstellt).*)`),
	regexp.MustCompile(`(?i)(subtitles\s+by.*)`),
	regexp.MustCompile(`(?i)(translated\s+by.*)`),
	regexp.MustCompile(`(?i)(sous-titres\s+par.*)`),
	regexp.MustCompile(`(?i)(sottotitoli\s+a\s+cura\s+di.*)`),
	regexp.MustCompile(`(?i)(subtítulos\s+por.*)`),

	// YouTube / Social media outros
	regexp.MustCompile(`(?i)((подписывайтесь|подпишитесь)\s+на\s+канал.*)`),
	regexp.MustCompile(`(?i)(ставьте\s+лайки.*)`),
	regexp.MustCompile(`(?i)(спасибо\s+за\s+(просмотр|внимание).*)`),
	regexp.MustCompile(`(?i)(не\s+забудьте\s+подписаться.*)`),
	regexp.MustCompile(`(?i)(до\s+новых\s+встреч.*)`),
	regexp.MustCompile(`(?i)(продолжение\s+следует.*)`),
	regexp.MustCompile(`(?i)(thank\s+you\s+for\s+watching.*)`),
	regexp.MustCompile(`(?i)(thanks\s+for\s+watching.*)`),
	regexp.MustCompile(`(?i)(please\s+subscribe.*)`),
	regexp.MustCompile(`(?i)(like\s+and\s+subscribe.*)`),
	regexp.MustCompile(`(?i)(danke\s+fürs\s+zuschauen.*)`),
	regexp.MustCompile(`(?i)(merci\s+d'avoir\s+regardé.*)`),
	regexp.MustCompile(`(?i)(grazie\s+per\s+la\s+visione.*)`),
	regexp.MustCompile(`(?i)(gracias\s+por\s+ver.*)`),

	// Acoustic markers in brackets
	regexp.MustCompile(`(?i)\[(музыка|аплодисменты|смех|вздох|тишина|шум|звонок|music|applause|laughter|silence|noise|bell|cough)\]`),
	regexp.MustCompile(`(?i)\((музыка|аплодисменты|смех|вздох|тишина|шум|звонок|music|applause|laughter|silence|noise|bell|cough)\)`),
}

var trailingSpamRegex = regexp.MustCompile(`(?i)(?:,\s*|\s+)?(?:GIN-[A-Za-z0-9]+[,\s]*){2,}$`)

func removeRepetitiveLoops(text string) string {
	trimmed := strings.TrimSpace(text)
	// 1. Remove trailing spam bursts of GIN-* brands (caused by Whisper prompt loop artifacts)
	trimmed = trailingSpamRegex.ReplaceAllString(trimmed, "")

	// 2. Detect and strip trailing word/phrase repetition loops (n words repeated >= 2 times at the end)
	words := strings.Fields(trimmed)
	if len(words) >= 4 {
		for n := 1; n <= 4 && n*2 <= len(words); n++ {
			phrase1 := strings.ToLower(strings.Join(words[len(words)-n:], " "))
			phrase2 := strings.ToLower(strings.Join(words[len(words)-2*n:len(words)-n], " "))
			if phrase1 == phrase2 && len(phrase1) > 2 {
				for len(words) >= 2*n {
					p1 := strings.ToLower(strings.Join(words[len(words)-n:], " "))
					p2 := strings.ToLower(strings.Join(words[len(words)-2*n:len(words)-n], " "))
					if p1 == p2 {
						words = words[:len(words)-n]
					} else {
						break
					}
				}
				trimmed = strings.Join(words, " ")
				break
			}
		}
	}
	return strings.TrimSpace(trimmed)
}

func cleanHallucinations(text string) string {
	res := text
	for _, re := range hallucinationRegexes {
		res = re.ReplaceAllString(res, "")
	}
	res = removeRepetitiveLoops(res)
	res = strings.TrimSpace(res)
	res = strings.TrimRight(res, " ,;:-–—")
	return res
}

func trimAudioSilence(pcm []byte) []byte {
	// Whisper Large v3 naturally ignores silence and performs with peak accuracy on full sentences.
	// Returning full PCM preserves natural speech cadence and prevents dropping trailing words.
	return pcm
}

func createWAV(pcm []byte, sampleRate int, channels int, bits int) []byte {
	dataLen := len(pcm)
	totalLen := 36 + dataLen
	byteRate := sampleRate * channels * (bits / 8)
	blockAlign := channels * (bits / 8)

	buf := make([]byte, 44+dataLen)
	copy(buf[0:], []byte("RIFF"))
	buf[4] = byte(totalLen)
	buf[5] = byte(totalLen >> 8)
	buf[6] = byte(totalLen >> 16)
	buf[7] = byte(totalLen >> 24)
	copy(buf[8:], []byte("WAVE"))

	copy(buf[12:], []byte("fmt "))
	buf[16] = 16
	buf[20] = 1 // PCM
	buf[22] = byte(channels)
	buf[24] = byte(sampleRate)
	buf[25] = byte(sampleRate >> 8)
	buf[26] = byte(sampleRate >> 16)
	buf[27] = byte(sampleRate >> 24)
	buf[28] = byte(byteRate)
	buf[29] = byte(byteRate >> 8)
	buf[30] = byte(byteRate >> 16)
	buf[31] = byte(byteRate >> 24)
	buf[32] = byte(blockAlign)
	buf[33] = byte(blockAlign >> 8)
	buf[34] = byte(bits)
	buf[35] = byte(bits >> 8)

	copy(buf[36:], []byte("data"))
	buf[40] = byte(dataLen)
	buf[41] = byte(dataLen >> 8)
	buf[42] = byte(dataLen >> 16)
	buf[43] = byte(dataLen >> 24)
	copy(buf[44:], pcm)

	return buf
}

// WaveIn Event-Driven Engine: Direct low-latency asynchronous audio recording
func startRecordingWaveIn() error {
	audioMutex.Lock()
	capturedAudio = nil
	audioMutex.Unlock()

	var wfx WAVEFORMATEX
	wfx.WFormatTag = WAVE_FORMAT_PCM
	wfx.NChannels = 1
	wfx.NSamplesPerSec = 16000
	wfx.WBitsPerSample = 16
	wfx.NBlockAlign = 2
	wfx.NAvgBytesPerSec = 32000
	wfx.CbSize = 0

	hEv, _, _ := procCreateEventW.Call(0, 0, 0, 0)
	if hEv == 0 {
		return fmt.Errorf("failed to create audio sync event")
	}

	var newWaveIn uintptr
	ret, _, _ := procWaveInOpen.Call(
		uintptr(unsafe.Pointer(&newWaveIn)),
		WAVE_MAPPER,
		uintptr(unsafe.Pointer(&wfx)),
		hEv,
		0,
		CALLBACK_EVENT,
	)
	if ret != 0 {
		procCloseHandle.Call(hEv)
		return fmt.Errorf("waveInOpen error: %d", ret)
	}

	audioMutex.Lock()
	hWaveIn = newWaveIn
	hWaveEvent = hEv
	audioMutex.Unlock()

	bufSize := 8000 // 250ms chunks
	for i := 0; i < 8; i++ {
		waveBuffers[i] = make([]byte, bufSize)
		waveHeaders[i] = WAVEHDR{
			LpData:         uintptr(unsafe.Pointer(&waveBuffers[i][0])),
			DwBufferLength: uint32(bufSize),
		}
		procWaveInPrepareHeader.Call(hWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
		procWaveInAddBuffer.Call(hWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
	}

	ret, _, _ = procWaveInStart.Call(hWaveIn)
	if ret != 0 {
		audioMutex.Lock()
		curWaveIn := hWaveIn
		curEvent := hWaveEvent
		hWaveIn = 0
		hWaveEvent = 0
		audioMutex.Unlock()

		procWaveInClose.Call(curWaveIn)
		procCloseHandle.Call(curEvent)
		return fmt.Errorf("waveInStart error: %d", ret)
	}

	// Dedicated background event capture goroutine (100% decoupled from Windows GUI message loop)
	go func(targetWaveIn, targetEvent uintptr) {
		for {
			r, _, _ := procWaitForSingleObject.Call(targetEvent, 60)
			if r != 0 && r != 258 {
				break
			}

			audioMutex.Lock()
			active := isRecording && hWaveIn == targetWaveIn
			if !active {
				audioMutex.Unlock()
				break
			}

			for i := 0; i < 8; i++ {
				if (waveHeaders[i].DwFlags & WHDR_DONE) != 0 {
					if waveHeaders[i].DwBytesRecorded > 0 {
						chunk := (*[1 << 20]byte)(unsafe.Pointer(waveHeaders[i].LpData))[:waveHeaders[i].DwBytesRecorded]
						capturedAudio = append(capturedAudio, chunk...)
					}
					waveHeaders[i].DwFlags &^= WHDR_DONE
					if isRecording && hWaveIn == targetWaveIn {
						procWaveInAddBuffer.Call(targetWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
					}
				}
			}
			audioMutex.Unlock()
		}
	}(hWaveIn, hWaveEvent)

	return nil
}

func stopRecordingWaveIn() []byte {
	// Allow 200ms for in-flight audio DMA buffers to flush final spoken words into memory
	time.Sleep(200 * time.Millisecond)

	audioMutex.Lock()
	curWaveIn := hWaveIn
	curEvent := hWaveEvent
	hWaveIn = 0
	hWaveEvent = 0
	audioMutex.Unlock()

	if curWaveIn == 0 {
		return nil
	}

	procWaveInStop.Call(curWaveIn)
	procWaveInReset.Call(curWaveIn)

	audioMutex.Lock()
	for i := 0; i < 8; i++ {
		if waveHeaders[i].DwBytesRecorded > 0 {
			chunk := (*[1 << 20]byte)(unsafe.Pointer(waveHeaders[i].LpData))[:waveHeaders[i].DwBytesRecorded]
			capturedAudio = append(capturedAudio, chunk...)
		}
		procWaveInUnprepareHeader.Call(curWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
	}

	pcm := make([]byte, len(capturedAudio))
	copy(pcm, capturedAudio)
	audioMutex.Unlock()

	procWaveInClose.Call(curWaveIn)
	if curEvent != 0 {
		procCloseHandle.Call(curEvent)
	}

	return createWAV(pcm, 16000, 1, 16)
}

func startRecording() {
	recordMutex.Lock()
	defer recordMutex.Unlock()

	if isRecording {
		return
	}

	cleanKey := strings.TrimSpace(config.GroqAPIKey)
	if cleanKey == "" {
		playGentleSound("notice")
		showSettingsDialog()
		return
	}

	err := startRecordingWaveIn()
	if err != nil {
		writeLog("WaveIn start error: " + err.Error())
		playGentleSound("notice")
		return
	}

	isRecording = true
	playGentleSound("start")
	ui := getUI()
	updateTrayState(true, fmt.Sprintf("%s | %s", AppTitle, fmt.Sprintf(ui.HudRecording, config.Hotkey)))
	updateHUD(true, fmt.Sprintf(ui.HudRecording, config.Hotkey))
	writeLog("Direct WaveIn Event recording active.")
}

func stopRecordingAndTranscribe() {
	recordMutex.Lock()
	if !isRecording {
		recordMutex.Unlock()
		return
	}
	isRecording = false
	recordMutex.Unlock()

	ui := getUI()
	playGentleSound("stop")
	updateTrayState(false, AppTitle+" | "+ui.HudTranscribing)
	updateHUD(true, ui.HudTranscribing)

	wavBytes := stopRecordingWaveIn()

	go func() {
		defer updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))
		defer func() {
			time.Sleep(1400 * time.Millisecond)
			updateHUD(false, "")
		}()

		if len(wavBytes) < 2000 {
			writeLog(fmt.Sprintf("Audio recording too short: %d bytes", len(wavBytes)))
			playGentleSound("notice")
			updateHUD(true, ui.HudEmpty)
			return
		}

		text, err := transcribeAudioBytes(wavBytes)
		if err != nil {
			writeLog("Transcription error: " + err.Error())
			playGentleSound("notice")
			updateHUD(true, fmt.Sprintf(ui.HudError, err.Error()))
			return
		}

		text = cleanHallucinations(text)
		text = strings.TrimSpace(text)
		if text == "" {
			return
		}

		text = applyDictionary(text)
		text = cleanHallucinations(text)
		text = strings.TrimSpace(text)
		if text == "" {
			return
		}

		writeLog(fmt.Sprintf("Pasted text: [%s]", text))
		updateHUD(true, fmt.Sprintf(ui.HudPasted, text))
		pasteText(text)
	}()
}

func toggleRecording() {
	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	if !rec {
		startRecording()
	} else {
		stopRecordingAndTranscribe()
	}
}

func getTranscriptionLanguage() string {
	// If only 1 specific language is selected, enforce it.
	// If multiple languages are selected (e.g. EN+RU+CS), return "" so Whisper automatically detects and transcribes without translation!
	if len(config.ActiveLanguages) == 1 {
		return strings.ToLower(config.ActiveLanguages[0])
	}
	return ""
}

func transcribeAudioBytes(wavBytes []byte) (string, error) {
	apiKey := strings.TrimSpace(config.GroqAPIKey)
	if apiKey == "" {
		return "", fmt.Errorf("Groq API Key is not configured. Please open settings and enter your key.")
	}

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, err := writer.CreateFormFile("file", "speech.wav")
	if err != nil {
		return "", fmt.Errorf("failed to create form file: %w", err)
	}
	_, err = part.Write(wavBytes)
	if err != nil {
		return "", fmt.Errorf("failed to write wav bytes: %w", err)
	}

	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "json")
	_ = writer.WriteField("temperature", "0.0")

	langCode := getTranscriptionLanguage()
	if langCode != "" {
		_ = writer.WriteField("language", langCode)
	}

	dictMutex.RLock()
	var dictTerms []string
	seenTerms := make(map[string]bool)
	for _, v := range dictionary {
		val := strings.TrimSpace(v)
		if val != "" && !seenTerms[strings.ToLower(val)] {
			seenTerms[strings.ToLower(val)] = true
			dictTerms = append(dictTerms, val)
		}
	}
	dictMutex.RUnlock()

	defaultTerms := []string{"GIN-Voice", "GIN-Cinema", "GIN-TV", "GIN-NetScan", "GIN-Chat", "GIN-VPN", "Secret_Privat", "ORACLE_157", "Server_222", "Antigravity", "Gemini", "Python", "Windows 11"}
	for _, dt := range defaultTerms {
		if !seenTerms[strings.ToLower(dt)] {
			seenTerms[strings.ToLower(dt)] = true
			dictTerms = append(dictTerms, dt)
		}
	}
	// Limit to max 12 unique terms to prevent Whisper decoder repetition loops
	if len(dictTerms) > 12 {
		dictTerms = dictTerms[:12]
	}
	promptContext := strings.Join(dictTerms, ", ")
	_ = writer.WriteField("prompt", promptContext)

	err = writer.Close()
	if err != nil {
		return "", fmt.Errorf("failed to close multipart writer: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/audio/transcriptions", body)
	if err != nil {
		return "", fmt.Errorf("failed to build HTTP request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Groq API request failed: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Groq API error (%d): %s", resp.StatusCode, string(respBytes))
	}

	var parsed struct {
		Text string `json:"text"`
	}
	if err := json.Unmarshal(respBytes, &parsed); err != nil {
		return "", fmt.Errorf("failed to parse json response: %w", err)
	}

	return parsed.Text, nil
}

func testGroqAPIKey(key string) (bool, string) {
	key = strings.TrimSpace(key)
	if key == "" {
		return false, "API Key cannot be empty."
	}

	dummyWAV := createWAV(make([]byte, 16000), 16000, 1, 16)
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, _ := writer.CreateFormFile("file", "test.wav")
	_, _ = part.Write(dummyWAV)
	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "json")
	_ = writer.Close()

	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/audio/transcriptions", body)
	if err != nil {
		return false, "Error creating request: " + err.Error()
	}

	req.Header.Set("Authorization", "Bearer "+key)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 8 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return false, "Connection error with Groq: " + err.Error()
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusOK {
		return true, "✅ Success! Groq Whisper AI API key is valid and fully operational."
	}
	return false, fmt.Sprintf("❌ API Key Error (%d): %s", resp.StatusCode, string(respBytes))
}

type RemoteVersionInfo struct {
	Version     string `json:"version"`
	Name        string `json:"name"`
	ReleaseDate string `json:"release_date"`
}

func parseVerDigits(v string) int {
	v = strings.TrimPrefix(strings.ToLower(v), "v")
	v = strings.TrimLeft(v, "0")
	var n int
	fmt.Sscanf(v, "%d", &n)
	return n
}

func isNewerVersion(remote, local string) bool {
	rNum := parseVerDigits(remote)
	lNum := parseVerDigits(local)
	if rNum > 0 && lNum > 0 {
		return rNum > lNum
	}
	return remote != "" && remote != local
}

func triggerCheckForUpdates(manual bool) {
	ui := getUI()
	if manual {
		updateHUD(true, ui.HudCheckingUpdate)
		playGentleSound("notice")
	}

	go func() {
		client := &http.Client{Timeout: 8 * time.Second}
		url := "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json"
		resp, err := client.Get(url)
		if err != nil {
			if manual {
				writeLog("Manual update check failed: " + err.Error())
				updateHUD(true, fmt.Sprintf(ui.HudCheckFailed, "Connection error"))
				time.Sleep(3 * time.Second)
				updateHUD(false, "")
			}
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			if manual {
				writeLog(fmt.Sprintf("Manual update HTTP error: %d", resp.StatusCode))
				updateHUD(true, fmt.Sprintf(ui.HudCheckFailed, fmt.Sprintf("HTTP %d", resp.StatusCode)))
				time.Sleep(3 * time.Second)
				updateHUD(false, "")
			}
			return
		}

		var info RemoteVersionInfo
		if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
			if manual {
				updateHUD(true, fmt.Sprintf(ui.HudCheckFailed, "Invalid response"))
				time.Sleep(3 * time.Second)
				updateHUD(false, "")
			}
			return
		}

		remoteVer := strings.TrimSpace(info.Version)
		if remoteVer != "" && isNewerVersion(remoteVer, AppVersion) {
			updateMutex.Lock()
			updateAvailable = remoteVer
			updateMutex.Unlock()

			writeLog(fmt.Sprintf("Update detected: %s (Current: %s)", remoteVer, AppVersion))
			performSelfUpdate(remoteVer)
		} else {
			if manual {
				updateHUD(true, fmt.Sprintf(ui.HudUpToDate, AppVersion))
				playGentleSound("save")
				time.Sleep(3 * time.Second)
				updateHUD(false, "")
			}
		}
	}()
}

func performSelfUpdate(latestVer string) {
	updateExecMutex.Lock()
	if isUpdating {
		updateExecMutex.Unlock()
		return
	}
	isUpdating = true
	updateExecMutex.Unlock()

	ui := getUI()
	updateHUD(true, fmt.Sprintf(ui.HudUpdating, latestVer))
	playGentleSound("notice")

	go func() {
		defer func() {
			updateExecMutex.Lock()
			isUpdating = false
			updateExecMutex.Unlock()
		}()

		client := &http.Client{Timeout: 60 * time.Second}
		exeURL := "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/GIN-Voice.exe"
		resp, err := client.Get(exeURL)
		if err != nil {
			writeLog("Update download failed: " + err.Error())
			updateHUD(true, fmt.Sprintf(ui.HudUpdateError, err.Error()))
			time.Sleep(3 * time.Second)
			updateHUD(false, "")
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			writeLog(fmt.Sprintf("Update HTTP status error: %d", resp.StatusCode))
			updateHUD(true, fmt.Sprintf(ui.HudUpdateError, fmt.Sprintf("HTTP %d", resp.StatusCode)))
			time.Sleep(3 * time.Second)
			updateHUD(false, "")
			return
		}

		tempExe := filepath.Join(os.TempDir(), fmt.Sprintf("GIN-Voice_Update_%s_%d.exe", latestVer, time.Now().Unix()))
		f, err := os.Create(tempExe)
		if err != nil {
			writeLog("Update temp file create failed: " + err.Error())
			updateHUD(true, fmt.Sprintf(ui.HudUpdateError, err.Error()))
			time.Sleep(3 * time.Second)
			updateHUD(false, "")
			return
		}

		written, err := io.Copy(f, resp.Body)
		f.Close()

		if err != nil || written < 1000000 {
			_ = os.Remove(tempExe)
			writeLog(fmt.Sprintf("Update file too small or incomplete: %d bytes", written))
			updateHUD(true, fmt.Sprintf(ui.HudUpdateError, "Incomplete download"))
			time.Sleep(3 * time.Second)
			updateHUD(false, "")
			return
		}

		currExe, err := os.Executable()
		if err != nil {
			_ = os.Remove(tempExe)
			return
		}

		updateHUD(true, ui.HudUpdateDone)
		playGentleSound("save")
		time.Sleep(900 * time.Millisecond)

		pid := os.Getpid()

		// PowerShell script gracefully stops current process, replaces GIN-Voice.exe, preserves config.json and dictionary.json 100%, and relaunches GIN-Voice.exe
		psScript := fmt.Sprintf(`
Start-Sleep -Milliseconds 400
Stop-Process -Id %d -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 400
$tries = 0
while ($tries -lt 25) {
    try {
        Copy-Item -Path '%s' -Destination '%s' -Force
        break
    } catch {
        Start-Sleep -Milliseconds 300
        $tries++
    }
}
Remove-Item -Path '%s' -Force -ErrorAction SilentlyContinue
Start-Process -FilePath '%s'
`, pid, tempExe, currExe, tempExe, currExe)

		cmd := exec.Command("powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", psScript)
		_ = cmd.Start()

		os.Exit(0)
	}()
}

func getClipboardText() string {
	r, _, _ := procIsClipboardAvailable.Call(CF_UNICODETEXT)
	if r == 0 {
		return ""
	}

	r, _, _ = procOpenClipboard.Call(0)
	if r == 0 {
		return ""
	}
	defer procCloseClipboard.Call()

	hData, _, _ := procGetClipboardData.Call(CF_UNICODETEXT)
	if hData == 0 {
		return ""
	}

	pData, _, _ := procGlobalLock.Call(hData)
	if pData == 0 {
		return ""
	}
	defer procGlobalUnlock.Call(hData)

	return syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(pData))[:])
}

func setClipboardText(text string) bool {
	utf16Chars, err := syscall.UTF16FromString(text)
	if err != nil {
		return false
	}
	bytesSize := len(utf16Chars) * 2

	hMem, _, _ := procGlobalAlloc.Call(GMEM_MOVEABLE, uintptr(bytesSize))
	if hMem == 0 {
		return false
	}

	pMem, _, _ := procGlobalLock.Call(hMem)
	if pMem == 0 {
		procGlobalFree.Call(hMem)
		return false
	}

	dest := (*[1 << 20]byte)(unsafe.Pointer(pMem))
	src := (*[1 << 20]byte)(unsafe.Pointer(&utf16Chars[0]))
	copy(dest[:bytesSize], src[:bytesSize])
	procGlobalUnlock.Call(hMem)

	r, _, _ := procOpenClipboard.Call(0)
	if r == 0 {
		procGlobalFree.Call(hMem)
		return false
	}
	defer procCloseClipboard.Call()

	procEmptyClipboard.Call()
	procSetClipboardData.Call(CF_UNICODETEXT, hMem)
	return true
}

func pasteText(text string) {
	oldClip := ""
	if config.RestoreClipboard {
		oldClip = getClipboardText()
	}

	setClipboardText(text)
	time.Sleep(30 * time.Millisecond)

	procKeybdEvent.Call(VK_CONTROL, 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, KEYEVENTF_KEYUP, 0)
	procKeybdEvent.Call(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)

	if config.RestoreClipboard && oldClip != "" {
		go func(prev string) {
			time.Sleep(250 * time.Millisecond)
			setClipboardText(prev)
		}(oldClip)
	}
}

func pickFolderNative(owner uintptr) string {
	var bi BROWSEINFOW
	title := "Select knowledge base / project folder for GIN-Voice:"
	bi.HwndOwner = owner
	bi.LpszTitle = strPtr(title)
	bi.UlFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE

	pidl, _, _ := procSHBrowseForFolderW.Call(uintptr(unsafe.Pointer(&bi)))
	if pidl == 0 {
		return ""
	}
	defer procCoTaskMemFree.Call(pidl)

	var pathBuf [1024]uint16
	procSHGetPathFromIDListW.Call(pidl, uintptr(unsafe.Pointer(&pathBuf[0])))
	return syscall.UTF16ToString(pathBuf[:])
}

func linkKnowledgeFolder(folderPath string) int {
	if folderPath == "" {
		return 0
	}
	dictMutex.Lock()
	defer dictMutex.Unlock()

	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return 0
	}

	addedCount := 0
	for _, entry := range entries {
		name := entry.Name()
		if strings.HasPrefix(name, ".") {
			continue
		}

		baseName := name
		if !entry.IsDir() {
			baseName = strings.TrimSuffix(name, filepath.Ext(name))
		}

		if len(baseName) < 2 {
			continue
		}

		cleanKey := strings.ToLower(strings.ReplaceAll(baseName, "_", " "))
		cleanKey = strings.ReplaceAll(cleanKey, "-", " ")

		if _, exists := dictionary[cleanKey]; !exists {
			dictionary[cleanKey] = baseName
			addedCount++
		}
	}

	if addedCount > 0 {
		data, _ := json.MarshalIndent(dictionary, "", "  ")
		_ = os.WriteFile(dictFile, data, 0644)
	}

	return addedCount
}

func setAutostart(enabled bool) error {
	exePath, err := os.Executable()
	if err != nil {
		return err
	}

	keyCmd := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	if enabled {
		cmd := exec.Command("reg", "add", keyCmd, "/v", "GIN-Voice", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", exePath), "/f")
		return cmd.Run()
	} else {
		cmd := exec.Command("reg", "delete", keyCmd, "/v", "GIN-Voice", "/f")
		return cmd.Run()
	}
}

func toggleAutostart() {
	config.Autostart = !config.Autostart
	_ = setAutostart(config.Autostart)
	saveConfig()
}

func showContextMenu() {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	defer procDestroyMenu.Call(hMenu)

	ui := getUI()
	var titleText string
	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	if rec {
		titleText = fmt.Sprintf(ui.MenuStopDictation, config.Hotkey)
	} else {
		titleText = fmt.Sprintf(ui.MenuStartDictation, config.Hotkey)
	}

	updateMutex.Lock()
	latestUpdate := updateAvailable
	updateMutex.Unlock()

	if latestUpdate != "" {
		updateText := fmt.Sprintf(ui.MenuUpdateAvailable, latestUpdate)
		procAppendMenuW.Call(hMenu, MF_STRING, IDM_UPDATE_APP, uintptr(unsafe.Pointer(strPtr(updateText))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	}

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_TOGGLE_RECORD, uintptr(unsafe.Pointer(strPtr(titleText))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	// Speech Recognition Languages Submenu
	hLangSubMenu, _, _ := procCreatePopupMenu.Call()
	for i, lang := range config.AllLanguages {
		flags := uintptr(MF_STRING)
		if hasLang(lang.Code) {
			flags |= MF_CHECKED
		}
		itemText := fmt.Sprintf("[%s] %s", lang.Code, lang.Name)
		procAppendMenuW.Call(hLangSubMenu, flags, IDM_LANG_BASE+uintptr(i), uintptr(unsafe.Pointer(strPtr(itemText))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hLangSubMenu, uintptr(unsafe.Pointer(strPtr(ui.MenuSpeechLang))))

	// Interface Language Submenu (EN, RU, CS, IT, ES, FR)
	hUILangSubMenu, _, _ := procCreatePopupMenu.Call()
	for i, uiItem := range UILanguages {
		flags := uintptr(MF_STRING)
		if strings.EqualFold(config.UILanguage, uiItem.Code) {
			flags |= MF_CHECKED
		}
		procAppendMenuW.Call(hUILangSubMenu, flags, IDM_UI_LANG_BASE+uintptr(i), uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("[%s] %s", uiItem.Code, uiItem.Name)))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hUILangSubMenu, uintptr(unsafe.Pointer(strPtr(ui.MenuInterfaceLang))))

	cleanKey := strings.TrimSpace(config.GroqAPIKey)
	statusKey := ui.MenuKeyConfigured
	if cleanKey == "" {
		statusKey = ui.MenuKeyNotSet
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETUP_KEY, uintptr(unsafe.Pointer(strPtr(statusKey))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DICT, uintptr(unsafe.Pointer(strPtr(ui.MenuOpenDict))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_LINK_FOLDER, uintptr(unsafe.Pointer(strPtr(ui.MenuLinkFolder))))

	autoFlags := uintptr(MF_STRING)
	if config.Autostart {
		autoFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autoFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr(ui.MenuAutostart))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr(ui.MenuHelp))))

	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHECK_UPDATE, uintptr(unsafe.Pointer(strPtr(ui.MenuCheckUpdates))))

	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr(ui.MenuExit))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procPostMessageW.Call(hwndMain, 0, 0, 0)
}

func showSettingsDialog() {
	if hwndSetup != 0 {
		procShowWindow.Call(hwndSetup, SW_SHOWNORMAL)
		procSetForegroundWindow.Call(hwndSetup)
		return
	}

	ui := getUI()
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	screenHeight, _, _ := procGetSystemMetrics.Call(1)

	winW := int32(840)
	winH := int32(640)
	posX := (int32(screenWidth) - winW) / 2
	posY := (int32(screenHeight) - winH) / 2

	hwndSetup, _, _ = procCreateWindowExW.Call(
		WS_EX_TOPMOST,
		uintptr(unsafe.Pointer(strPtr("GIN_VOICE_CYBER_SETTINGS"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle+" - "+ui.SettingsTitle))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		uintptr(posX), uintptr(posY), uintptr(winW), uintptr(winH),
		0, 0, hInstance, 0,
	)

	// Header Banner
	hwndHeader, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsHeader))),
		WS_CHILD|WS_VISIBLE,
		24, 20, 510, 32, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndHeader, WM_SETFONT, hFontHeader, 1)

	// Top Language Switcher in Settings Window
	btnLangEN, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🇬🇧 English"))),
		WS_CHILD|WS_VISIBLE,
		550, 16, 114, 34, hwndSetup, uintptr(IDC_BTN_LANG_EN), hInstance, 0,
	)
	procSendMessageW.Call(btnLangEN, WM_SETFONT, hFontBold, 1)

	btnLangRU, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🇷🇺 Русский"))),
		WS_CHILD|WS_VISIBLE,
		674, 16, 130, 34, hwndSetup, uintptr(IDC_BTN_LANG_RU), hInstance, 0,
	)
	procSendMessageW.Call(btnLangRU, WM_SETFONT, hFontBold, 1)

	// 1. Groq API Key Row
	hwndLblKey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsKeyLabel))),
		WS_CHILD|WS_VISIBLE,
		24, 68, 260, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblKey, WM_SETFONT, hFontBold, 1)

	btnGroq, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsGetGroq))),
		WS_CHILD|WS_VISIBLE,
		470, 62, 334, 30, hwndSetup, uintptr(IDC_BTN_GROQ), hInstance, 0,
	)
	procSendMessageW.Call(btnGroq, WM_SETFONT, hFontNormal, 1)

	hwndEditKey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.GroqAPIKey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 98, 640, 34, hwndSetup, uintptr(IDC_EDIT_KEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditKey, WM_SETFONT, hFontNormal, 1)

	btnTest, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsTestBtn))),
		WS_CHILD|WS_VISIBLE,
		674, 98, 130, 34, hwndSetup, uintptr(IDC_BTN_TEST), hInstance, 0,
	)
	procSendMessageW.Call(btnTest, WM_SETFONT, hFontBold, 1)

	// 2. Hotkey Config & HUD Font Row
	hwndLblHot, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsHotkey))),
		WS_CHILD|WS_VISIBLE,
		24, 146, 170, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblHot, WM_SETFONT, hFontBold, 1)

	hwndEditHotkey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.Hotkey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		198, 142, 80, 32, hwndSetup, uintptr(IDC_EDIT_HOTKEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditHotkey, WM_SETFONT, hFontBold, 1)

	hwndLblFont, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsFont))),
		WS_CHILD|WS_VISIBLE,
		296, 146, 140, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblFont, WM_SETFONT, hFontBold, 1)

	hwndEditFont, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.HUDFont))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		440, 142, 160, 32, hwndSetup, uintptr(IDC_EDIT_FONT), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditFont, WM_SETFONT, hFontNormal, 1)

	hwndLblHotTip, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsFontTip))),
		WS_CHILD|WS_VISIBLE,
		610, 146, 200, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblHotTip, WM_SETFONT, hFontNormal, 1)

	// 3. Knowledge Base Linking
	hwndLblFolder, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsFolder))),
		WS_CHILD|WS_VISIBLE,
		24, 186, 520, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblFolder, WM_SETFONT, hFontBold, 1)

	hwndEditFolder, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.LinkedKnowledgeFolder))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 216, 640, 34, hwndSetup, uintptr(IDC_EDIT_FOLDER), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditFolder, WM_SETFONT, hFontNormal, 1)

	btnBrowse, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsBrowse))),
		WS_CHILD|WS_VISIBLE,
		674, 216, 130, 34, hwndSetup, uintptr(IDC_BTN_BROWSE), hInstance, 0,
	)
	procSendMessageW.Call(btnBrowse, WM_SETFONT, hFontBold, 1)

	// 4. Recognition Language Checklist (18 languages: 6 rows x 3 columns)
	hwndLblLangs, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsLangs))),
		WS_CHILD|WS_VISIBLE,
		24, 264, 780, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblLangs, WM_SETFONT, hFontBold, 1)

	startX := int32(24)
	startY := int32(296)
	colW := int32(260)
	rowH := int32(28)

	for i, lang := range MasterLanguages {
		col := int32(i % 3)
		row := int32(i / 3)
		cX := startX + (col * colW)
		cY := startY + (row * rowH)

		chkHwnd, _, _ := procCreateWindowExW.Call(
			0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
			uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("[%s] %s", lang.Code, lang.Name)))),
			WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
			uintptr(cX), uintptr(cY), uintptr(colW-12), uintptr(rowH-4),
			hwndSetup, uintptr(IDC_LANG_CHK_BASE+i), hInstance, 0,
		)
		procSetWindowTheme.Call(chkHwnd, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(chkHwnd, WM_SETFONT, hFontNormal, 1)

		if hasLang(lang.Code) {
			procSendMessageW.Call(chkHwnd, 0x00F1, 1, 0)
		}
		langCheckHWnd[lang.Code] = chkHwnd
	}

	// 5. Action Buttons (Save, Dictionary)
	btnSave, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsSave))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		24, 480, 380, 46, hwndSetup, uintptr(IDC_BTN_SAVE), hInstance, 0,
	)
	procSendMessageW.Call(btnSave, WM_SETFONT, hFontBold, 1)

	btnDict, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsDict))),
		WS_CHILD|WS_VISIBLE,
		424, 480, 380, 46, hwndSetup, uintptr(IDC_BTN_DICT), hInstance, 0,
	)
	procSendMessageW.Call(btnDict, WM_SETFONT, hFontNormal, 1)

	procSetForegroundWindow.Call(hwndSetup)
}

func refreshSettingsDialogUI() {
	if hwndSetup == 0 {
		return
	}
	ui := getUI()
	procSetWindowTextW.Call(hwndSetup, uintptr(unsafe.Pointer(strPtr(AppTitle+" - "+ui.SettingsTitle))))
	procSetWindowTextW.Call(hwndHeader, uintptr(unsafe.Pointer(strPtr(ui.SettingsHeader))))
	procSetWindowTextW.Call(hwndLblKey, uintptr(unsafe.Pointer(strPtr(ui.SettingsKeyLabel))))
	procSetWindowTextW.Call(btnGroq, uintptr(unsafe.Pointer(strPtr(ui.SettingsGetGroq))))
	procSetWindowTextW.Call(btnTest, uintptr(unsafe.Pointer(strPtr(ui.SettingsTestBtn))))
	procSetWindowTextW.Call(hwndLblHot, uintptr(unsafe.Pointer(strPtr(ui.SettingsHotkey))))
	procSetWindowTextW.Call(hwndLblFont, uintptr(unsafe.Pointer(strPtr(ui.SettingsFont))))
	procSetWindowTextW.Call(hwndLblHotTip, uintptr(unsafe.Pointer(strPtr(ui.SettingsFontTip))))
	procSetWindowTextW.Call(hwndLblFolder, uintptr(unsafe.Pointer(strPtr(ui.SettingsFolder))))
	procSetWindowTextW.Call(btnBrowse, uintptr(unsafe.Pointer(strPtr(ui.SettingsBrowse))))
	procSetWindowTextW.Call(hwndLblLangs, uintptr(unsafe.Pointer(strPtr(ui.SettingsLangs))))
	procSetWindowTextW.Call(btnSave, uintptr(unsafe.Pointer(strPtr(ui.SettingsSave))))
	procSetWindowTextW.Call(btnDict, uintptr(unsafe.Pointer(strPtr(ui.SettingsDict))))
	updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))
}

func hasLang(code string) bool {
	for _, l := range config.ActiveLanguages {
		if strings.EqualFold(l, code) {
			return true
		}
	}
	return false
}

func parseVK(keyStr string) uint32 {
	u := strings.ToUpper(strings.TrimSpace(keyStr))
	switch u {
	case "F4":
		return VK_F4
	case "F8":
		return VK_F8
	case "F9":
		return VK_F9
	case "F10":
		return VK_F10
	case "F12":
		return VK_F12
	default:
		return VK_F8
	}
}

func handleMenuCommand(cmdID uintptr) {
	switch {
	case cmdID == IDM_TOGGLE_RECORD:
		go toggleRecording()
	case cmdID == IDM_CHECK_UPDATE || cmdID == IDM_UPDATE_APP:
		triggerCheckForUpdates(true)
	case cmdID == IDM_SETUP_KEY || cmdID == IDM_OPEN_CONFIG:
		showSettingsDialog()
	case cmdID >= IDM_UI_LANG_BASE && cmdID < IDM_UI_LANG_BASE+uintptr(len(UILanguages)):
		idx := int(cmdID - IDM_UI_LANG_BASE)
		if idx >= 0 && idx < len(UILanguages) {
			config.UILanguage = UILanguages[idx].Code
			saveConfig()
			refreshSettingsDialogUI()
		}
	case cmdID >= IDM_LANG_BASE && cmdID < IDM_LANG_BASE+uintptr(len(config.AllLanguages)):
		idx := int(cmdID - IDM_LANG_BASE)
		if idx >= 0 && idx < len(config.AllLanguages) {
			code := config.AllLanguages[idx].Code
			found := false
			var updated []string
			for _, c := range config.ActiveLanguages {
				if strings.EqualFold(c, code) {
					found = true
				} else {
					updated = append(updated, c)
				}
			}
			if !found {
				updated = append(updated, code)
			}
			if len(updated) == 0 {
				updated = []string{"EN"}
			}
			config.ActiveLanguages = updated
			saveConfig()
		}
	case cmdID == IDM_OPEN_DICT:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
	case cmdID == IDM_LINK_FOLDER:
		folder := pickFolderNative(hwndMain)
		if folder != "" {
			count := linkKnowledgeFolder(folder)
			config.LinkedKnowledgeFolder = folder
			saveConfig()
			msg := fmt.Sprintf("Successfully linked!\nFolder: %s\nNew terms added to dictionary: %d", folder, count)
			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr(msg))),
				uintptr(unsafe.Pointer(strPtr(AppTitle+" - Folder Linked"))),
				0x00000040,
			)
		}
	case cmdID == IDM_AUTOSTART:
		toggleAutostart()
	case cmdID == IDM_OPEN_HELP:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(helpFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_EXIT:
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
	}
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_TRAYICON:
		if lParam == WM_RBUTTONUP {
			showContextMenu()
		} else if lParam == WM_LBUTTONDBLCLK {
			go toggleRecording()
		}
		return 0
	case WM_COMMAND:
		handleMenuCommand(wParam)
		return 0
	case WM_DESTROY:
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
		return 0
	default:
		r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
		return r
	}
}

func setupWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_CTLCOLORSTATIC:
		hdc := wParam
		ctrlHwnd := lParam
		if ctrlHwnd == hwndHeader {
			procSetTextColor.Call(hdc, 0x00FFE500) // Vibrant Cyan #00E5FF for Main Header Banner
		} else if ctrlHwnd == hwndLblKey || ctrlHwnd == hwndLblHot || ctrlHwnd == hwndLblFont || ctrlHwnd == hwndLblFolder || ctrlHwnd == hwndLblLangs {
			procSetTextColor.Call(hdc, 0x005EC522) // Emerald Green #22C55E for Section Titles
		} else if ctrlHwnd == hwndLblHotTip {
			procSetTextColor.Call(hdc, 0x00FCD37D) // Sky Blue #7DD3FC for Helper Tips
		} else {
			procSetTextColor.Call(hdc, 0x00FCFAF8) // Bright Crisp White #F8FAFC for Checkbox Labels
		}
		procSetBkColor.Call(hdc, 0x002E2722) // Cool Slate Gray #22272E
		return hBrushDarkBg
	case WM_CTLCOLOREDIT:
		hdc := wParam
		ctrlHwnd := lParam
		procSetTextColor.Call(hdc, 0x00FCFAF8) // Crisp White Text
		if ctrlHwnd == hwndEditFont {
			procSetTextColor.Call(hdc, 0x00FFE500) // Cyan text for HUD Font preview
		}
		procSetBkColor.Call(hdc, 0x0028211C) // Deep Slate #1C2128
		return hBrushEditBg
	case WM_CTLCOLORBTN:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00FCFAF8)
		procSetBkColor.Call(hdc, 0x002E2722)
		return hBrushDarkBg
	case WM_COMMAND:
		cmdID := wParam & 0xFFFF
		if cmdID == IDC_BTN_LANG_EN {
			config.UILanguage = "EN"
			saveConfig()
			refreshSettingsDialogUI()
			return 0
		} else if cmdID == IDC_BTN_LANG_RU {
			config.UILanguage = "RU"
			saveConfig()
			refreshSettingsDialogUI()
			return 0
		} else if cmdID == IDC_BTN_SAVE {
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			config.GroqAPIKey = strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))

			var bufHotkey [64]uint16
			procGetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(&bufHotkey[0])), 64)
			newHotkey := strings.TrimSpace(syscall.UTF16ToString(bufHotkey[:]))
			if newHotkey != "" {
				config.Hotkey = newHotkey
				config.HotkeyVK = parseVK(newHotkey)
			}

			var bufFont [128]uint16
			procGetWindowTextW.Call(hwndEditFont, uintptr(unsafe.Pointer(&bufFont[0])), 128)
			newFont := strings.TrimSpace(syscall.UTF16ToString(bufFont[:]))
			if newFont != "" {
				config.HUDFont = newFont
			} else {
				config.HUDFont = "Comfortaa"
			}
			updateHUDFont()

			var bufFolder [1024]uint16
			procGetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(&bufFolder[0])), 1024)
			config.LinkedKnowledgeFolder = strings.TrimSpace(syscall.UTF16ToString(bufFolder[:]))

			var langs []string
			for _, lang := range MasterLanguages {
				if chkHwnd, exists := langCheckHWnd[lang.Code]; exists {
					r, _, _ := procSendMessageW.Call(chkHwnd, 0x00F0, 0, 0)
					if r == 1 {
						langs = append(langs, strings.ToUpper(lang.Code))
					}
				}
			}
			if len(langs) == 0 {
				langs = []string{"EN"}
			}
			config.ActiveLanguages = langs

			saveConfig()
			playGentleSound("save")
			initTrayIcon()
			ui := getUI()
			updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))

			// Show visual HUD notification
			updateHUD(true, fmt.Sprintf("✅ %s | [%s]", ui.Ready, config.Hotkey))
			go func() {
				time.Sleep(2500 * time.Millisecond)
				updateHUD(false, "")
			}()

			// Show confirmation message box to user
			msgText := fmt.Sprintf(ui.SettingsSavedMsg, config.Hotkey, config.HUDFont)
			procMessageBoxW.Call(
				hwndSetup,
				uintptr(unsafe.Pointer(strPtr(msgText))),
				uintptr(unsafe.Pointer(strPtr(ui.SettingsSavedTitle))),
				0x00000040, // MB_ICONINFORMATION
			)

			procShowWindow.Call(hwnd, SW_HIDE)
			return 0
		} else if cmdID == IDC_BTN_TEST {
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			testKey := strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))
			go func(k string) {
				ok, resMsg := testGroqAPIKey(k)
				iconType := uintptr(0x00000040)
				if !ok {
					iconType = 0x00000010
				}
				procMessageBoxW.Call(
					hwndSetup,
					uintptr(unsafe.Pointer(strPtr(resMsg))),
					uintptr(unsafe.Pointer(strPtr(AppTitle+" - API Key Test"))),
					iconType,
				)
			}(testKey)
			return 0
		} else if cmdID == IDC_BTN_GROQ {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(GroqKeysURL))), 0, 0, SW_SHOWNORMAL)
			return 0
		} else if cmdID == IDC_BTN_BROWSE {
			folder := pickFolderNative(hwnd)
			if folder != "" {
				procSetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(strPtr(folder))))
			}
			return 0
		} else if cmdID == IDC_BTN_DICT {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
			return 0
		}
	case WM_CLOSE:
		procShowWindow.Call(hwnd, SW_HIDE)
		initTrayIcon()
		return 0
	}
	r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return r
}

func hudWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_CTLCOLORSTATIC:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00FFE500) // Vibrant Cyan #00E5FF
		procSetBkColor.Call(hdc, 0x002E2722)  // Cool Slate Gray #22272E
		return hBrushDarkBg
	default:
		r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
		return r
	}
}

func createHUDFont(fontName string) uintptr {
	fontName = strings.TrimSpace(fontName)
	if fontName == "" {
		fontName = "Comfortaa"
	}
	hFont, _, _ := procCreateFontW.Call(
		20, 0, 0, 0, 400, 0, 0, 0, // 400: non-bold, aesthetic, clean
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr(fontName))),
	)
	return hFont
}

func updateHUDFont() {
	hFontHUD = createHUDFont(config.HUDFont)
	if hwndHUDText != 0 {
		procSendMessageW.Call(hwndHUDText, WM_SETFONT, hFontHUD, 1)
	}
}

func initHUD() {
	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	hudWidth := int32(480)
	hudHeight := int32(50)
	hudX := (int32(screenWidth) - hudWidth) / 2
	hudY := int32(24)

	hInstance, _, _ := procGetModuleHandleW.Call(0)
	className := strPtr("GIN_VOICE_HUD_CLASS")

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(hudWndProc)
	wc.HInstance = hInstance
	wc.HbrBackground = hBrushDarkBg
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hwndHUD, _, _ = procCreateWindowExW.Call(
		WS_EX_TOPMOST|WS_EX_TOOLWINDOW,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("GIN-Voice HUD"))),
		WS_POPUP,
		uintptr(hudX), uintptr(hudY), uintptr(hudWidth), uintptr(hudHeight),
		0, 0, hInstance, 0,
	)

	hwndHUDText, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Ready"))),
		WS_CHILD|WS_VISIBLE,
		16, 12, uintptr(hudWidth-32), 26,
		hwndHUD, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndHUDText, WM_SETFONT, hFontHUD, 1)
}

func startHotkeyListener() {
	go func() {
		var wasPressed bool
		var lastToggle time.Time
		for {
			time.Sleep(15 * time.Millisecond)
			vk := config.HotkeyVK
			if vk == 0 {
				vk = VK_F8
			}

			state, _, _ := procGetAsyncKeyState.Call(uintptr(vk))
			isDown := (state & 0x8000) != 0

			if isDown && !wasPressed {
				wasPressed = true
				if time.Since(lastToggle) > 300*time.Millisecond {
					lastToggle = time.Now()
					writeLog(fmt.Sprintf("Hardware hotkey press: [%s] (VK %d)", config.Hotkey, vk))
					go toggleRecording()
				}
			} else if !isDown && wasPressed {
				wasPressed = false
			}
		}
	}()
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}

func createShortcuts(exePath, targetDir string) {
	icoPath := filepath.Join(targetDir, "app.ico")
	recIcoPath := filepath.Join(targetDir, "app_rec.ico")
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")

	psCmd := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$s1 = $w.CreateShortcut("$desktop\GIN-Voice.lnk")
$s1.TargetPath = '%s'
$s1.WorkingDirectory = '%s'
$s1.IconLocation = '%s'
$s1.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s1.Save()

$startMenu = [Environment]::GetFolderPath('Programs')
$s2 = $w.CreateShortcut("$startMenu\GIN-Voice.lnk")
$s2.TargetPath = '%s'
$s2.WorkingDirectory = '%s'
$s2.IconLocation = '%s'
$s2.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s2.Save()

$sUn = $w.CreateShortcut("$startMenu\Uninstall GIN-Voice.lnk")
$sUn.TargetPath = '%s'
$sUn.WorkingDirectory = '%s'
$sUn.IconLocation = '%s'
$sUn.Description = 'Uninstall GIN-Voice'
$sUn.Save()

if (Test-Path 'D:\MEGA\DOCS\desktop') {
    $s3 = $w.CreateShortcut("D:\MEGA\DOCS\desktop\GIN-Voice.lnk")
    $s3.TargetPath = '%s'
    $s3.WorkingDirectory = '%s'
    $s3.IconLocation = '%s'
    $s3.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
    $s3.Save()
}
`, exePath, targetDir, icoPath, exePath, targetDir, icoPath, uninstExe, targetDir, recIcoPath, exePath, targetDir, icoPath)

	_ = exec.Command("powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", psCmd).Run()
}

func registerUninstallRegistry(targetDir, targetExe string) {
	uninstKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice`
	icoPath := filepath.Join(targetDir, "app.ico")
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")

	_ = exec.Command("reg", "add", uninstKey, "/v", "DisplayName", "/t", "REG_SZ", "/d", "GIN-Voice", "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", AppVersion, "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "Publisher", "/t", "REG_SZ", "/d", "VladiMIR+AI", "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "DisplayIcon", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", icoPath), "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "InstallLocation", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", targetDir), "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "UninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", uninstExe), "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "QuietUninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", uninstExe), "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "EstimatedSize", "/t", "REG_DWORD", "/d", "18000", "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "URLInfoAbout", "/t", "REG_SZ", "/d", "https://github.com/GinCz/Windows_scripts", "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "NoModify", "/t", "REG_DWORD", "/d", "1", "/f").Run()
	_ = exec.Command("reg", "add", uninstKey, "/v", "NoRepair", "/t", "REG_DWORD", "/d", "1", "/f").Run()
}

func checkAndSelfInstall() {
	currExe, err := os.Executable()
	if err != nil {
		return
	}

	localAppData := os.Getenv("LOCALAPPDATA")
	if localAppData == "" {
		localAppData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local")
	}
	targetDir := filepath.Join(localAppData, "GIN-Voice")
	targetExe := filepath.Join(targetDir, "GIN-Voice.exe")

	if strings.EqualFold(filepath.Dir(currExe), targetDir) {
		registerUninstallRegistry(targetDir, targetExe)
		return
	}

	// Terminate any currently running GIN-Voice instances before copying
	_ = exec.Command("taskkill", "/F", "/IM", "GIN-Voice.exe").Run()
	time.Sleep(400 * time.Millisecond)

	_ = os.MkdirAll(targetDir, 0755)

	// Clean up all old version binaries and installers in targetDir
	if entries, err := os.ReadDir(targetDir); err == nil {
		for _, entry := range entries {
			name := entry.Name()
			if strings.HasPrefix(name, "GIN-Voice_v") || strings.HasPrefix(name, "GIN-Voice_Setup") {
				_ = os.Remove(filepath.Join(targetDir, name))
			}
		}
	}

	// Copy runtime executable only (no redundant installer copies inside targetDir)
	_ = copyFile(currExe, targetExe)

	dstIco := filepath.Join(targetDir, "app.ico")
	if len(defaultAppIco) > 0 {
		_ = os.WriteFile(dstIco, defaultAppIco, 0644)
	}

	dstRecIco := filepath.Join(targetDir, "app_rec.ico")
	if len(defaultAppRecIco) > 0 {
		_ = os.WriteFile(dstRecIco, defaultAppRecIco, 0644)
	}

	dstUninst := filepath.Join(targetDir, "uninstall.bat")
	if len(defaultUninstallBAT) > 0 {
		_ = os.WriteFile(dstUninst, defaultUninstallBAT, 0644)
	}

	dstUninstPS1 := filepath.Join(targetDir, "uninstall.ps1")
	if len(defaultUninstallPS1) > 0 {
		_ = os.WriteFile(dstUninstPS1, defaultUninstallPS1, 0644)
	}

	dstUninstEXE := filepath.Join(targetDir, "Uninstall.exe")
	if len(defaultUninstallEXE) > 0 {
		_ = os.WriteFile(dstUninstEXE, defaultUninstallEXE, 0755)
	}

	dictDest := filepath.Join(targetDir, "dictionary.json")
	if _, err := os.Stat(dictDest); os.IsNotExist(err) && len(defaultDictionaryJSON) > 0 {
		_ = os.WriteFile(dictDest, defaultDictionaryJSON, 0644)
	}

	guideDest := filepath.Join(targetDir, "setup_guide.html")
	if len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(guideDest, defaultSetupGuideHTML, 0644)
	}

	createShortcuts(targetExe, targetDir)
	registerUninstallRegistry(targetDir, targetExe)

	// Open Setup Guide in Default Web Browser upon installation
	procShellExecuteW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("open"))),
		uintptr(unsafe.Pointer(strPtr(guideDest))),
		0,
		0,
		SW_SHOWNORMAL,
	)

	// Launch installed main application
	procShellExecuteW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("open"))),
		uintptr(unsafe.Pointer(strPtr(targetExe))),
		0,
		uintptr(unsafe.Pointer(strPtr(targetDir))),
		SW_SHOWNORMAL,
	)
	os.Exit(0)
}

func main() {
	checkAndSelfInstall()

	// Single Instance Mutex
	hMutex, _, _ := procCreateMutexW.Call(0, 1, uintptr(unsafe.Pointer(strPtr("Global\\GIN_VOICE_RUNNING_MUTEX"))))
	lastErr, _, _ := procGetLastError.Call()
	if lastErr == 183 && hMutex != 0 { // ERROR_ALREADY_EXISTS
		hwndExisting, _, _ := procFindWindowW.Call(
			uintptr(unsafe.Pointer(strPtr("GIN_VOICE_CYBER_SETTINGS"))),
			0,
		)
		if hwndExisting != 0 {
			procShowWindow.Call(hwndExisting, SW_SHOWNORMAL)
			procSetForegroundWindow.Call(hwndExisting)
		} else {
			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr("GIN-Voice is already active and running in the System Tray (near the clock).\n\n• Press [F4] (or your hotkey) to dictate.\n• Right-click the microphone icon in tray to open settings."))),
				uintptr(unsafe.Pointer(strPtr("GIN-Voice - Already Running"))),
				0x00000040,
			)
		}
		os.Exit(0)
	}

	exePath, _ := os.Executable()
	appDir = filepath.Dir(exePath)
	configFile = filepath.Join(appDir, "config.json")
	dictFile = filepath.Join(appDir, "dictionary.json")
	helpFile = filepath.Join(appDir, "setup_guide.html")
	logFile = filepath.Join(appDir, "gin_voice.log")

	// Ensure setup guide is extracted
	if _, err := os.Stat(helpFile); os.IsNotExist(err) && len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(helpFile, defaultSetupGuideHTML, 0644)
	}

	// Clean up any installer or legacy version binaries from app directory
	if entries, err := os.ReadDir(appDir); err == nil {
		for _, entry := range entries {
			name := entry.Name()
			if !entry.IsDir() {
				if strings.HasPrefix(name, "GIN-Voice_Setup") || (strings.HasPrefix(name, "GIN-Voice_v") && !strings.EqualFold(name, filepath.Base(exePath))) {
					_ = os.Remove(filepath.Join(appDir, name))
				}
			}
		}
	}

	writeLog("=== GIN-Voice [" + AppVersion + "] Starting ===")

	loadConfig()
	loadDictionary()
	loadIcons()

	bDark, _, _ := procCreateSolidBrush.Call(0x002E2722) // Cool Slate Gray #22272E
	hBrushDarkBg = bDark
	bEdit, _, _ := procCreateSolidBrush.Call(0x0028211C) // Deep Slate #1C2128
	hBrushEditBg = bEdit

	hFontNormal, _, _ = procCreateFontW.Call(
		19, 0, 0, 0, 400, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontBold, _, _ = procCreateFontW.Call(
		20, 0, 0, 0, 700, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontHeader, _, _ = procCreateFontW.Call(
		21, 0, 0, 0, 700, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontHUD = createHUDFont(config.HUDFont)

	hInstance, _, _ := procGetModuleHandleW.Call(0)

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconNormal
	wc.LpszClassName = strPtr("GIN_VOICE_WINDOW_CLASS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var sc WNDCLASSEXW
	sc.CbSize = uint32(unsafe.Sizeof(sc))
	sc.LpfnWndProc = syscall.NewCallback(setupWndProc)
	sc.HInstance = hInstance
	sc.HIcon = hIconNormal
	sc.HbrBackground = hBrushDarkBg
	sc.LpszClassName = strPtr("GIN_VOICE_CYBER_SETTINGS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&sc)))

	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_VOICE_WINDOW_CLASS"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		0, 0, 0, 0, 0,
		0, 0, hInstance, 0,
	)

	initTrayIcon()
	initHUD()
	startHotkeyListener()

	go func() {
		time.Sleep(3 * time.Second)
		triggerCheckForUpdates(false)
		ticker := time.NewTicker(2 * time.Hour)
		for range ticker.C {
			triggerCheckForUpdates(false)
		}
	}()

	apiKey := strings.TrimSpace(config.GroqAPIKey)
	if apiKey == "" || config.FirstRun {
		if config.FirstRun {
			config.FirstRun = false
			saveConfig()
		}
		showSettingsDialog()
	}

	var msg MSG
	for {
		r, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if int32(r) <= 0 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
