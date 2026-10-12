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
	AppVersion    = "v028"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v028]"
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
	TPM_RETURNCMD   = 0x0100

	VK_F4           = 0x73
	VK_F8           = 0x77
	VK_F9           = 0x78
	VK_F10          = 0x79
	VK_F12          = 0x7B
	VK_OEM_3        = 0xC0
	VK_CONTROL      = 0x11
	KEYEVENTF_KEYUP = 0x0002

	MOD_ALT     = 0x0001
	MOD_CONTROL = 0x0002
	MOD_SHIFT   = 0x0004
	MOD_WIN     = 0x0008

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
	WS_VSCROLL          = 0x00200000
	WS_TABSTOP          = 0x00010000
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
	IDM_EXIT           = 1008
	IDM_UPDATE_APP     = 1009
	IDM_CHECK_UPDATE   = 1010
	IDM_SAVE_CLIPBOARD = 1011
	IDM_AUTO_PASTE     = 1012

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
	IDC_COMBO_FONT  = 3009
	IDC_BTN_LANG_EN = 3010
	IDC_BTN_LANG_RU = 3011
	IDC_BTN_RECORD  = 3012

	IDC_LANG_CHK_BASE = 4000

	// Win32 ComboBox & OwnerDraw Constants
	CBS_DROPDOWNLIST   = 0x0003
	CBS_OWNERDRAWFIXED = 0x0010
	CBS_HASSTRINGS     = 0x0200
	CB_ADDSTRING       = 0x0143
	CB_SETCURSEL       = 0x014E
	CB_GETCURSEL       = 0x0147
	CB_GETLBTEXT       = 0x0148
	CB_SETITEMHEIGHT   = 0x0153
	CBN_SELCHANGE      = 1

	WM_DRAWITEM        = 0x002B
	WM_MEASUREITEM     = 0x002C
	WM_CTLCOLORLISTBOX = 0x0134

	ODT_COMBOBOX     = 3
	ODS_SELECTED     = 0x0001
	ODS_FOCUS        = 0x0010
	ODS_COMBOBOXEDIT = 0x1000

	DT_LEFT       = 0x00000000
	DT_VCENTER    = 0x00000004
	DT_SINGLELINE = 0x00000020
	DT_NOPREFIX   = 0x00000800
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
	procIsDialogMessageW     = user32.NewProc("IsDialogMessageW")
	procIsWindowVisible      = user32.NewProc("IsWindowVisible")
	procGetDC                = user32.NewProc("GetDC")
	procReleaseDC            = user32.NewProc("ReleaseDC")
	procFillRect             = user32.NewProc("FillRect")
	procDrawTextW            = user32.NewProc("DrawTextW")

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
	procSelectObject     = gdi32.NewProc("SelectObject")
	procDeleteObject     = gdi32.NewProc("DeleteObject")
	procSetBkMode        = gdi32.NewProc("SetBkMode")
	procEnumFontFamilies = gdi32.NewProc("EnumFontFamiliesExW")

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

type RECT struct {
	Left   int32
	Top    int32
	Right  int32
	Bottom int32
}

type DRAWITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     int32
	ItemAction uint32
	ItemState  uint32
	_          uint32
	HwndItem   uintptr
	HDC        uintptr
	RcItem     RECT
	ItemData   uintptr
}

type MEASUREITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     int32
	ItemWidth  uint32
	ItemHeight uint32
	_          uint32
	ItemData   uintptr
}

type LOGFONTW struct {
	LfHeight         int32
	LfWidth          int32
	LfEscapement     int32
	LfOrientation    int32
	LfWeight         int32
	LfItalic         byte
	LfUnderline      byte
	LfStrikeOut      byte
	LfCharSet        byte
	LfOutPrecision   byte
	LfClipPrecision  byte
	LfQuality        byte
	LfPitchAndFamily byte
	LfFaceName       [32]uint16
}

type ENUMLOGFONTEXW struct {
	ElfLogFont  LOGFONTW
	ElfFullName [64]uint16
	ElfStyle    [32]uint16
	ElfScript   [32]uint16
}

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
	MenuSaveClipboard   string
	MenuAutoPaste       string
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
	SettingsRecordBtn   string
	SettingsRecording   string
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
	SaveClipboard         bool           `json:"save_clipboard"`
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
	hwndEditHotkey    uintptr
	hwndBtnRecord     uintptr
	isRecordingHotkey bool
	hwndComboFont     uintptr
	systemFontsList   []string
	fontCache         = make(map[string]uintptr)
	fontCacheMutex    sync.Mutex
	btnLangEN         uintptr
	btnLangRU         uintptr
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
			MenuKeyConfigured:   "⚙️ Settings - API Key Setup",
			MenuKeyNotSet:       "⚠️ Settings - API Key Setup (Key not set)",
			MenuOpenDict:        "📖 Open Dictionary (dictionary.json)",
			MenuLinkFolder:      "📁 Link Knowledge Folder...",
			MenuAutostart:       "⚡ Autostart on Windows Boot",
			MenuSaveClipboard:   "📋 Keep Recognized Text in Clipboard",
			MenuAutoPaste:       "⌨️ Auto-Paste Text at Cursor",
			MenuHelp:            "❓ Setup Guide & Help",
			MenuCheckUpdates:    "🔄 Check for Updates...",
			MenuExit:            "❌ Exit GIN-Voice",
			SettingsTitle:       "GIN-Voice - Settings & Control Center",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Instant Voice Typing",
			SettingsKeyLabel:    "🔑 Groq Whisper API Key:",
			SettingsGetGroq:     "🌐 Get Free Key at Groq.com",
			SettingsTestBtn:     "🧪 Test Key",
			SettingsHotkey:      "⚡ Hotkey:",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Record...",
			SettingsRecording:   "⏳ Press keys...",
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
			MenuKeyConfigured:   "⚙️ Настройки - Ввод ключа",
			MenuKeyNotSet:       "⚠️ Настройки - Ввод ключа (Ключ не задан)",
			MenuOpenDict:        "📖 Открыть словарь автозамен (dictionary.json)",
			MenuLinkFolder:      "📁 Привязать общую папку с базами знаний...",
			MenuAutostart:       "⚡ Автозапуск при старте Windows",
			MenuSaveClipboard:   "📋 Сохранять распознанный текст в буфер обмена",
			MenuAutoPaste:       "⌨️ Автоматическая вставка текста у курсора",
			MenuHelp:            "❓ Инструкция и справка",
			MenuCheckUpdates:    "🔄 Проверить обновления...",
			MenuExit:            "❌ Выход из GIN-Voice",
			SettingsTitle:       "GIN-Voice - Центр Управления",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Мгновенный Голосовой Ввод",
			SettingsKeyLabel:    "🔑 Groq Whisper API Key:",
			SettingsGetGroq:     "🌐 Получить бесплатный ключ на Groq.com",
			SettingsTestBtn:     "🧪 Проверить",
			SettingsHotkey:      "⚡ Горячая клавиша:",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Записать...",
			SettingsRecording:   "⏳ Нажмите клавиши...",
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
			MenuKeyConfigured:   "⚙️ Nastavení - Zadání klíče",
			MenuKeyNotSet:       "⚠️ Nastavení - Zadání klíče (Klíč nezadán)",
			MenuOpenDict:        "📖 Otevřít slovník (dictionary.json)",
			MenuLinkFolder:      "📁 Propojit složku znalostí...",
			MenuAutostart:       "⚡ Automatické spuštění při startu Windows",
			MenuSaveClipboard:   "📋 Ponechat rozpoznaný text ve schránce",
			MenuAutoPaste:       "⌨️ Automaticky vložit text u kurzoru",
			MenuHelp:            "❓ Nápověda a průvodce",
			MenuCheckUpdates:    "🔄 Zkontrolovat aktualizace...",
			MenuExit:            "❌ Ukončit GIN-Voice",
			SettingsTitle:       "GIN-Voice - Nastavení a Ovládací Centrum",
			SettingsHeader:      "🎙️ GIN-Voice od VladiMIR+AI — Okamžité Hlasové Psaní",
			SettingsKeyLabel:    "🔑 Groq Whisper API Klíč:",
			SettingsGetGroq:     "🌐 Získat klíč zdarma na Groq.com",
			SettingsTestBtn:     "🧪 Otestovat",
			SettingsHotkey:      "⚡ Klávesová zkratka:",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Zaznamenat...",
			SettingsRecording:   "⏳ Stiskněte klávesy...",
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
			MenuKeyConfigured:   "⚙️ Impostazioni - Inserisci chiave",
			MenuKeyNotSet:       "⚠️ Impostazioni - Inserisci chiave (Non impostata)",
			MenuOpenDict:        "📖 Apri dizionario (dictionary.json)",
			MenuLinkFolder:      "📁 Collega cartella progetti...",
			MenuAutostart:       "⚡ Avvio automatico con Windows",
			MenuSaveClipboard:   "📋 Mantieni il testo negli appunti",
			MenuAutoPaste:       "⌨️ Incolla automaticamente al cursore",
			MenuHelp:            "❓ Guida e supporto",
			MenuCheckUpdates:    "🔄 Controlla aggiornamenti...",
			MenuExit:            "❌ Esci da GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centro di controllo",
			SettingsHeader:      "🎙️ GIN-Voice by VladiMIR+AI — Digitazione vocale istantanea",
			SettingsKeyLabel:    "🔑 Chiave Groq Whisper API:",
			SettingsGetGroq:     "🌐 Ottieni chiave gratuita su Groq.com",
			SettingsTestBtn:     "🧪 Verifica",
			SettingsHotkey:      "⚡ Tasto rapido:",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Registra...",
			SettingsRecording:   "⏳ Premi i tasti...",
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
			MenuKeyConfigured:   "⚙️ Configuración - Ingreso de clave",
			MenuKeyNotSet:       "⚠️ Configuración - Ingreso de clave (No configurada)",
			MenuOpenDict:        "📖 Abrir diccionario (dictionary.json)",
			MenuLinkFolder:      "📁 Vincular carpeta de conocimientos...",
			MenuAutostart:       "⚡ Inicio automático con Windows",
			MenuSaveClipboard:   "📋 Mantener texto en el portapapeles",
			MenuAutoPaste:       "⌨️ Pegar automáticamente en el cursor",
			MenuHelp:            "❓ Guía y ayuda",
			MenuCheckUpdates:    "🔄 Buscar actualizaciones...",
			MenuExit:            "❌ Salir de GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centro de control",
			SettingsHeader:      "🎙️ GIN-Voice por VladiMIR+AI — Dictado por voz instantáneo",
			SettingsKeyLabel:    "🔑 Clave Groq Whisper API:",
			SettingsGetGroq:     "🌐 Obtener clave gratis en Groq.com",
			SettingsTestBtn:     "🧪 Probar clave",
			SettingsHotkey:      "⚡ Tecla rápida:",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Grabar...",
			SettingsRecording:   "⏳ Presione teclas...",
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
			MenuKeyConfigured:   "⚙️ Paramètres - Clé API",
			MenuKeyNotSet:       "⚠️ Paramètres - Clé API (Non configurée)",
			MenuOpenDict:        "📖 Ouvrir le dictionnaire (dictionary.json)",
			MenuLinkFolder:      "📁 Lier le dossier de connaissances...",
			MenuAutostart:       "⚡ Démarrage automatique avec Windows",
			MenuSaveClipboard:   "📋 Conserver le texte dans le presse-papiers",
			MenuAutoPaste:       "⌨️ Coller automatiquement au curseur",
			MenuHelp:            "❓ Guide d'installation et aide",
			MenuCheckUpdates:    "🔄 Vérifier les mises à jour...",
			MenuExit:            "❌ Quitter GIN-Voice",
			SettingsTitle:       "GIN-Voice - Centre de configuration",
			SettingsHeader:      "🎙️ GIN-Voice par VladiMIR+AI — Saisie vocale instantanée",
			SettingsKeyLabel:    "🔑 Clé Groq Whisper API :",
			SettingsGetGroq:     "🌐 Obtenir une clé gratuite sur Groq.com",
			SettingsTestBtn:     "🧪 Tester",
			SettingsHotkey:      "⚡ Raccourci :",
			SettingsHotkeyTip:   "(Alt+~, Ctrl+Shift+S, F13-F24)",
			SettingsRecordBtn:   "🔴 Enregistrer...",
			SettingsRecording:   "⏳ Appuyez sur touches...",
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
				0x0001|0x0004|0x0002, // SND_ASYNC | SND_MEMORY | SND_NODEFAULT
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
		Hotkey:                "Alt + ~",
		HotkeyVK:              VK_OEM_3,
		HotkeyMod:             MOD_ALT,
		HUDFont:               "Comfortaa",
		ActiveLanguages:       []string{"EN"}, // Only English selected by default upon initial installation
		AllLanguages:          MasterLanguages,
		GroqAPIKey:            "", // Strictly empty by default - no hardcoded keys, no env fallback
		SoundFeedback:         true,
		AutoPaste:             true,
		RestoreClipboard:      true,
		SaveClipboard:         true, // Keeps recognized text in clipboard by default
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

	if config.Hotkey == "" || config.HotkeyVK == 0 {
		config.Hotkey = "Alt + ~"
		config.HotkeyVK = VK_OEM_3
		config.HotkeyMod = MOD_ALT
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
		pattern *regexp.Regexp
		value   string
	}
	var entries []dictEntry
	for k, v := range dictionary {
		trimmedKey := strings.TrimSpace(k)
		if trimmedKey == "" {
			continue
		}
		// Match whole word or phrase, surrounded by start/end, whitespace, or punctuation
		escaped := regexp.QuoteMeta(trimmedKey)
		re, err := regexp.Compile(`(?i)(?:^|[\s\p{P}])(` + escaped + `)(?:$|[\s\p{P}])`)
		if err == nil {
			entries = append(entries, dictEntry{pattern: re, value: v})
		}
	}

	result := input
	for _, entry := range entries {
		result = entry.pattern.ReplaceAllStringFunc(result, func(m string) string {
			// Preserve leading/trailing punctuation or space
			lead := ""
			trail := ""
			inner := m
			if len(m) > 0 {
				rFirst := rune(m[0])
				if rFirst == ' ' || (rFirst < 'A' || (rFirst > 'Z' && rFirst < 'a') || (rFirst > 'z' && rFirst < 0x0400)) {
					lead = string(m[0])
					inner = inner[1:]
				}
			}
			if len(inner) > 0 {
				rLast := rune(inner[len(inner)-1])
				if rLast == ' ' || (rLast < 'A' || (rLast > 'Z' && rLast < 'a') || (rLast > 'z' && rLast < 0x0400)) {
					trail = string(inner[len(inner)-1])
					inner = inner[:len(inner)-1]
				}
			}
			return lead + entry.value + trail
		})
	}
	return result
}

func openDictionaryEditor() {
	dictMutex.RLock()
	targetFile := dictFile
	dictMutex.RUnlock()

	if targetFile == "" {
		targetFile = filepath.Join(appDir, "dictionary.json")
	}

	// Ensure file exists before opening
	if _, err := os.Stat(targetFile); os.IsNotExist(err) {
		if len(defaultDictionaryJSON) > 0 {
			_ = os.WriteFile(targetFile, defaultDictionaryJSON, 0644)
		} else {
			_ = os.WriteFile(targetFile, []byte("{\n}\n"), 0644)
		}
	}

	go func(fPath string) {
		// Launch notepad safely in background without blocking Win32 message loop
		cmd := exec.Command("notepad.exe", fPath)
		_ = cmd.Start()
	}(targetFile)
}

func openHelpFile() {
	if _, err := os.Stat(helpFile); os.IsNotExist(err) && len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(helpFile, defaultSetupGuideHTML, 0644)
	}
	go func(fPath string) {
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(fPath))), 0, 0, SW_SHOWNORMAL)
	}(helpFile)
}

func openBrowserURL(urlStr string) {
	go func(target string) {
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(target))), 0, 0, SW_SHOWNORMAL)
	}(urlStr)
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

	// Trailing conversational fillers and common trailing hallucination artifacts
	regexp.MustCompile(`(?i)(?:,\s*|\s+)?(и\s+так\s+далее|и\s+т\.\s*д\.|и\s+тому\s+подобное|and\s+so\s+on|etc\.|a\s+tak\s+dále|a\s+pod\.)[\.\s]*$`),
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

	// Note: We intentionally do NOT pass raw brand keywords into Whisper's 'prompt' field,
	// because Whisper Large v3 tends to hallucinate and inject prompt words (like 'GIN-Cinema')
	// during silent pauses or low-confidence segments.
	// Accurate vocabulary mapping is handled cleanly post-transcription by applyDictionary()!

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
	// 1. If user wants recognized text to stay in clipboard, we set it and do NOT restore old clipboard
	if config.SaveClipboard {
		setClipboardText(text)
		if !config.AutoPaste {
			return
		}
		time.Sleep(30 * time.Millisecond)
		procKeybdEvent.Call(VK_CONTROL, 0, 0, 0)
		procKeybdEvent.Call(uintptr('V'), 0, 0, 0)
		procKeybdEvent.Call(uintptr('V'), 0, KEYEVENTF_KEYUP, 0)
		procKeybdEvent.Call(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)
		return
	}

	// 2. Normal mode (RestoreClipboard enabled): backup old clipboard, inject text, paste, wait 600ms, then restore
	if !config.AutoPaste {
		return
	}

	oldClip := ""
	if config.RestoreClipboard {
		oldClip = getClipboardText()
	}

	setClipboardText(text)
	time.Sleep(40 * time.Millisecond)

	procKeybdEvent.Call(VK_CONTROL, 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, KEYEVENTF_KEYUP, 0)
	procKeybdEvent.Call(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)

	if config.RestoreClipboard && oldClip != "" {
		go func(prev string) {
			// Allow 600ms for web applications (like ChatGPT Lexical editor) to finish reading clipboard
			time.Sleep(600 * time.Millisecond)
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

	// 1. Settings (Настройка)
	cleanKey := strings.TrimSpace(config.GroqAPIKey)
	statusKey := ui.MenuKeyConfigured
	if cleanKey == "" {
		statusKey = ui.MenuKeyNotSet
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETUP_KEY, uintptr(unsafe.Pointer(strPtr(statusKey))))

	// 2. Interface Language Submenu (Язык интерфейса: EN, RU, CS, IT, ES, FR)
	hUILangSubMenu, _, _ := procCreatePopupMenu.Call()
	for i, uiItem := range UILanguages {
		flags := uintptr(MF_STRING)
		if strings.EqualFold(config.UILanguage, uiItem.Code) {
			flags |= MF_CHECKED
		}
		procAppendMenuW.Call(hUILangSubMenu, flags, IDM_UI_LANG_BASE+uintptr(i), uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("[%s] %s", uiItem.Code, uiItem.Name)))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hUILangSubMenu, uintptr(unsafe.Pointer(strPtr(ui.MenuInterfaceLang))))

	// 3. Speech Recognition Languages Submenu (Язык распознавания)
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
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	// 4. Autostart (Автозапуск)
	autoFlags := uintptr(MF_STRING)
	if config.Autostart {
		autoFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autoFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr(ui.MenuAutostart))))

	// 5. Keep Text in Clipboard (Сохранять текст в буфер)
	clipFlags := uintptr(MF_STRING)
	if config.SaveClipboard {
		clipFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, clipFlags, IDM_SAVE_CLIPBOARD, uintptr(unsafe.Pointer(strPtr(ui.MenuSaveClipboard))))

	// 6. Auto-Paste at Cursor (Автоматическая вставка текста у курсора)
	pasteFlags := uintptr(MF_STRING)
	if config.AutoPaste {
		pasteFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, pasteFlags, IDM_AUTO_PASTE, uintptr(unsafe.Pointer(strPtr(ui.MenuAutoPaste))))

	// 7. Help & Guide (Инструкция и справка)
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr(ui.MenuHelp))))

	// 8. Check for Updates (Обновление)
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHECK_UPDATE, uintptr(unsafe.Pointer(strPtr(ui.MenuCheckUpdates))))

	// 9. Exit (Выход)
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr(ui.MenuExit))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	cmd, _, _ := procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON|TPM_RETURNCMD, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procPostMessageW.Call(hwndMain, 0, 0, 0)
	if cmd != 0 {
		procPostMessageW.Call(hwndMain, WM_COMMAND, cmd, 0)
	}
}

func showSettingsDialog() {
	if hwndSetup != 0 {
		procSetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(strPtr(config.GroqAPIKey))))
		procSetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(strPtr(config.Hotkey))))
		curIdx := -1
		for i, f := range systemFontsList {
			if strings.EqualFold(f, config.HUDFont) {
				curIdx = i
				break
			}
		}
		if curIdx >= 0 {
			procSendMessageW.Call(hwndComboFont, CB_SETCURSEL, uintptr(curIdx), 0)
		}
		procSetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(strPtr(config.LinkedKnowledgeFolder))))
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
		0,
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
		24, 20, 570, 32, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndHeader, WM_SETFONT, hFontHeader, 1)

	// Top Language Switcher in Settings Window (🇬🇧 EN / 🇷🇺 RU)
	btnLangEN, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🇬🇧 EN"))),
		WS_CHILD|WS_VISIBLE,
		610, 16, 90, 34, hwndSetup, uintptr(IDC_BTN_LANG_EN), hInstance, 0,
	)
	procSendMessageW.Call(btnLangEN, WM_SETFONT, hFontBold, 1)

	btnLangRU, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🇷🇺 RU"))),
		WS_CHILD|WS_VISIBLE,
		710, 16, 90, 34, hwndSetup, uintptr(IDC_BTN_LANG_RU), hInstance, 0,
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
		24, 146, 140, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblHot, WM_SETFONT, hFontBold, 1)

	hwndEditHotkey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.Hotkey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		168, 142, 170, 32, hwndSetup, uintptr(IDC_EDIT_HOTKEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditHotkey, WM_SETFONT, hFontBold, 1)

	hwndBtnRecord, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsRecordBtn))),
		WS_CHILD|WS_VISIBLE,
		346, 141, 125, 34, hwndSetup, uintptr(IDC_BTN_RECORD), hInstance, 0,
	)
	procSendMessageW.Call(hwndBtnRecord, WM_SETFONT, hFontBold, 1)

	hwndLblFont, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsFont))),
		WS_CHILD|WS_VISIBLE,
		485, 146, 95, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLblFont, WM_SETFONT, hFontBold, 1)

	initSystemFonts()

	hwndComboFont, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_VSCROLL|WS_TABSTOP|CBS_DROPDOWNLIST|CBS_OWNERDRAWFIXED|CBS_HASSTRINGS,
		584, 142, 220, 360, hwndSetup, uintptr(IDC_COMBO_FONT), hInstance, 0,
	)
	procSendMessageW.Call(hwndComboFont, WM_SETFONT, hFontNormal, 1)
	procSendMessageW.Call(hwndComboFont, CB_SETITEMHEIGHT, ^uintptr(0), 28)
	procSendMessageW.Call(hwndComboFont, CB_SETITEMHEIGHT, 0, 30)

	for _, fontName := range systemFontsList {
		procSendMessageW.Call(hwndComboFont, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr(fontName))))
	}

	curIdx := -1
	for i, f := range systemFontsList {
		if strings.EqualFold(f, config.HUDFont) {
			curIdx = i
			break
		}
	}
	if curIdx >= 0 {
		procSendMessageW.Call(hwndComboFont, CB_SETCURSEL, uintptr(curIdx), 0)
	} else {
		procSendMessageW.Call(hwndComboFont, CB_SETCURSEL, 0, 0)
	}
	hwndLblHotTip = 0

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
	if !isRecordingHotkey && hwndBtnRecord != 0 {
		procSetWindowTextW.Call(hwndBtnRecord, uintptr(unsafe.Pointer(strPtr(ui.SettingsRecordBtn))))
	}
	procSetWindowTextW.Call(hwndLblFont, uintptr(unsafe.Pointer(strPtr(ui.SettingsFont))))
	if hwndLblHotTip != 0 {
		procSetWindowTextW.Call(hwndLblHotTip, uintptr(unsafe.Pointer(strPtr(ui.SettingsFontTip))))
	}
	if btnLangEN != 0 {
		procSetWindowTextW.Call(btnLangEN, uintptr(unsafe.Pointer(strPtr("🇬🇧 EN"))))
	}
	if btnLangRU != 0 {
		procSetWindowTextW.Call(btnLangRU, uintptr(unsafe.Pointer(strPtr("🇷🇺 RU"))))
	}
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

func vkToName(vk uint32) string {
	switch {
	case vk >= 0x70 && vk <= 0x87: // F1 to F24
		return fmt.Sprintf("F%d", vk-0x70+1)
	case vk >= 0x30 && vk <= 0x39: // '0'..'9'
		return string(rune('0' + (vk - 0x30)))
	case vk >= 0x41 && vk <= 0x5A: // 'A'..'Z'
		return string(rune('A' + (vk - 0x41)))
	case vk >= 0x60 && vk <= 0x69: // NumPad 0..9
		return fmt.Sprintf("Num%d", vk-0x60)
	}
	switch vk {
	case 0xC0:
		return "~" // Tilde / Backtick (Ё)
	case 0x20:
		return "Space"
	case 0x09:
		return "Tab"
	case 0x1B:
		return "Esc"
	case 0x2D:
		return "Insert"
	case 0x2E:
		return "Delete"
	case 0x24:
		return "Home"
	case 0x23:
		return "End"
	case 0x21:
		return "PageUp"
	case 0x22:
		return "PageDown"
	case 0x25:
		return "Left"
	case 0x26:
		return "Up"
	case 0x27:
		return "Right"
	case 0x28:
		return "Down"
	case 0x14:
		return "CapsLock"
	case 0x90:
		return "NumLock"
	case 0x91:
		return "ScrollLock"
	case 0x2C:
		return "PrintScreen"
	case 0x13:
		return "Pause"
	case 0xBA:
		return ";"
	case 0xBB:
		return "="
	case 0xBC:
		return ","
	case 0xBD:
		return "-"
	case 0xBE:
		return "."
	case 0xBF:
		return "/"
	case 0xDB:
		return "["
	case 0xDC:
		return "\\"
	case 0xDD:
		return "]"
	case 0xDE:
		return "'"
	// Media and extended keys
	case 0xAD:
		return "VolumeMute"
	case 0xAE:
		return "VolumeDown"
	case 0xAF:
		return "VolumeUp"
	case 0xB0:
		return "MediaNext"
	case 0xB1:
		return "MediaPrev"
	case 0xB2:
		return "MediaStop"
	case 0xB3:
		return "MediaPlayPause"
	case 0xA6:
		return "BrowserBack"
	case 0xA7:
		return "BrowserForward"
	case 0xA8:
		return "BrowserRefresh"
	case 0xAA:
		return "BrowserHome"
	}
	return fmt.Sprintf("Key_0x%X", vk)
}

func formatHotkeyName(mod, vk uint32) string {
	var parts []string
	if (mod & MOD_CONTROL) != 0 {
		parts = append(parts, "Ctrl")
	}
	if (mod & MOD_ALT) != 0 {
		parts = append(parts, "Alt")
	}
	if (mod & MOD_SHIFT) != 0 {
		parts = append(parts, "Shift")
	}
	if (mod & MOD_WIN) != 0 {
		parts = append(parts, "Win")
	}
	parts = append(parts, vkToName(vk))
	return strings.Join(parts, " + ")
}

func parseHotkeyString(s string) (uint32, uint32) {
	s = strings.TrimSpace(s)
	if s == "" {
		return VK_OEM_3, MOD_ALT
	}
	var mod uint32
	var mainKey string

	parts := strings.Split(s, "+")
	for i, p := range parts {
		trimmed := strings.TrimSpace(p)
		upper := strings.ToUpper(trimmed)
		if i < len(parts)-1 || upper == "CTRL" || upper == "CONTROL" || upper == "ALT" || upper == "SHIFT" || upper == "WIN" {
			switch upper {
			case "CTRL", "CONTROL":
				mod |= MOD_CONTROL
				continue
			case "ALT":
				mod |= MOD_ALT
				continue
			case "SHIFT":
				mod |= MOD_SHIFT
				continue
			case "WIN", "WINDOWS":
				mod |= MOD_WIN
				continue
			}
		}
		mainKey = trimmed
	}

	u := strings.ToUpper(mainKey)
	var vk uint32

	// Check F1..F24
	if strings.HasPrefix(u, "F") && len(u) >= 2 {
		var fNum int
		if _, err := fmt.Sscanf(u[1:], "%d", &fNum); err == nil && fNum >= 1 && fNum <= 24 {
			vk = uint32(0x70 + (fNum - 1))
		}
	}

	if vk == 0 {
		switch u {
		case "~", "`", "Ё", "TILDE":
			vk = VK_OEM_3
		case "SPACE", "ПРОБЕЛ":
			vk = 0x20
		case "TAB":
			vk = 0x09
		case "ESC", "ESCAPE":
			vk = 0x1B
		case "INSERT", "INS":
			vk = 0x2D
		case "DELETE", "DEL":
			vk = 0x2E
		case "HOME":
			vk = 0x24
		case "END":
			vk = 0x23
		case "PAGEUP", "PGUP":
			vk = 0x21
		case "PAGEDOWN", "PGDN":
			vk = 0x22
		case "LEFT":
			vk = 0x25
		case "UP":
			vk = 0x26
		case "RIGHT":
			vk = 0x27
		case "DOWN":
			vk = 0x28
		case ";":
			vk = 0xBA
		case "=":
			vk = 0xBB
		case ",":
			vk = 0xBC
		case "-":
			vk = 0xBD
		case ".":
			vk = 0xBE
		case "/":
			vk = 0xBF
		case "[":
			vk = 0xDB
		case "\\":
			vk = 0xDC
		case "]":
			vk = 0xDD
		case "'":
			vk = 0xDE
		default:
			if len(u) == 1 {
				ch := u[0]
				if ch >= '0' && ch <= '9' {
					vk = uint32(ch)
				} else if ch >= 'A' && ch <= 'Z' {
					vk = uint32(ch)
				}
			}
		}
	}

	if vk == 0 {
		vk = VK_OEM_3
		mod = MOD_ALT
	}

	return vk, mod
}

func matchModifiers(targetMod uint32) bool {
	ctrlDown := isKeyPhysicallyDown(0x11) || isKeyPhysicallyDown(0xA2) || isKeyPhysicallyDown(0xA3) // VK_CONTROL, LCONTROL, RCONTROL
	altDown := isKeyPhysicallyDown(0x12) || isKeyPhysicallyDown(0xA4) || isKeyPhysicallyDown(0xA5)  // VK_MENU, LMENU, RMENU
	shiftDown := isKeyPhysicallyDown(0x10) || isKeyPhysicallyDown(0xA0) || isKeyPhysicallyDown(0xA1) // VK_SHIFT, LSHIFT, RSHIFT
	winDown := isKeyPhysicallyDown(0x5B) || isKeyPhysicallyDown(0x5C)                                // LWIN, RWIN

	targetCtrl := (targetMod & MOD_CONTROL) != 0
	targetAlt := (targetMod & MOD_ALT) != 0
	targetShift := (targetMod & MOD_SHIFT) != 0
	targetWin := (targetMod & MOD_WIN) != 0

	return ctrlDown == targetCtrl && altDown == targetAlt && shiftDown == targetShift && winDown == targetWin
}

func isKeyPhysicallyDown(vk uint32) bool {
	state, _, _ := procGetAsyncKeyState.Call(uintptr(vk))
	return (state & 0x8000) != 0
}

func startRecordingHotkeyUI() {
	if isRecordingHotkey {
		return
	}
	isRecordingHotkey = true
	ui := getUI()
	if hwndBtnRecord != 0 {
		procSetWindowTextW.Call(hwndBtnRecord, uintptr(unsafe.Pointer(strPtr(ui.SettingsRecording))))
	}

	go func() {
		// Wait for existing pressed keys to be released first
		time.Sleep(300 * time.Millisecond)

		for isRecordingHotkey {
			time.Sleep(15 * time.Millisecond)

			// Check modifier keys currently pressed
			ctrlDown := isKeyPhysicallyDown(0x11) || isKeyPhysicallyDown(0xA2) || isKeyPhysicallyDown(0xA3)
			altDown := isKeyPhysicallyDown(0x12) || isKeyPhysicallyDown(0xA4) || isKeyPhysicallyDown(0xA5)
			shiftDown := isKeyPhysicallyDown(0x10) || isKeyPhysicallyDown(0xA0) || isKeyPhysicallyDown(0xA1)
			winDown := isKeyPhysicallyDown(0x5B) || isKeyPhysicallyDown(0x5C)

			var mod uint32
			if ctrlDown {
				mod |= MOD_CONTROL
			}
			if altDown {
				mod |= MOD_ALT
			}
			if shiftDown {
				mod |= MOD_SHIFT
			}
			if winDown {
				mod |= MOD_WIN
			}

			// Scan non-modifier key presses:
			var hitVK uint32

			// 1. Function keys F1..F24 (0x70..0x87)
			for k := uint32(0x70); k <= 0x87; k++ {
				if isKeyPhysicallyDown(k) {
					hitVK = k
					break
				}
			}

			// 2. Letters A..Z (0x41..0x5A)
			if hitVK == 0 {
				for k := uint32(0x41); k <= 0x5A; k++ {
					if isKeyPhysicallyDown(k) {
						hitVK = k
						break
					}
				}
			}

			// 3. Digits 0..9 (0x30..0x39)
			if hitVK == 0 {
				for k := uint32(0x30); k <= 0x39; k++ {
					if isKeyPhysicallyDown(k) {
						hitVK = k
						break
					}
				}
			}

			// 4. NumPad keys (0x60..0x69)
			if hitVK == 0 {
				for k := uint32(0x60); k <= 0x69; k++ {
					if isKeyPhysicallyDown(k) {
						hitVK = k
						break
					}
				}
			}

			// 5. Special OEM and punctuation keys: OEM_3 (~/`), Space, Tab, Esc, Navigation, Multimedia
			if hitVK == 0 {
				specialKeys := []uint32{
					0xC0, 0x20, 0x09, 0x1B, 0x2D, 0x2E, 0x24, 0x23, 0x21, 0x22,
					0x25, 0x26, 0x27, 0x28, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF,
					0xDB, 0xDC, 0xDD, 0xDE, 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3,
					0xA6, 0xA7, 0xA8, 0xAA,
				}
				for _, k := range specialKeys {
					if isKeyPhysicallyDown(k) {
						hitVK = k
						break
					}
				}
			}

			if hitVK != 0 {
				// We captured a full hotkey combination!
				newHotkeyStr := formatHotkeyName(mod, hitVK)
				config.Hotkey = newHotkeyStr
				config.HotkeyVK = hitVK
				config.HotkeyMod = mod

				if hwndEditHotkey != 0 {
					procSetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(strPtr(newHotkeyStr))))
				}
				stopRecordingHotkeyUI()
				go playGentleSound("save")
				return
			}
		}
	}()
}

func stopRecordingHotkeyUI() {
	isRecordingHotkey = false
	ui := getUI()
	if hwndBtnRecord != 0 {
		procSetWindowTextW.Call(hwndBtnRecord, uintptr(unsafe.Pointer(strPtr(ui.SettingsRecordBtn))))
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
		openDictionaryEditor()
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
	case cmdID == IDM_SAVE_CLIPBOARD:
		config.SaveClipboard = !config.SaveClipboard
		saveConfig()
	case cmdID == IDM_AUTO_PASTE:
		config.AutoPaste = !config.AutoPaste
		saveConfig()
	case cmdID == IDM_OPEN_HELP:
		openHelpFile()
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
	case WM_MEASUREITEM:
		mis := (*MEASUREITEMSTRUCT)(unsafe.Pointer(lParam))
		if mis.CtlID == IDC_COMBO_FONT {
			mis.ItemHeight = 30
			return 1
		}
		return 0
	case WM_DRAWITEM:
		dis := (*DRAWITEMSTRUCT)(unsafe.Pointer(lParam))
		if dis.CtlID == IDC_COMBO_FONT {
			if dis.ItemID < 0 {
				hBrush, _, _ := procCreateSolidBrush.Call(0x0028211C)
				procFillRect.Call(dis.HDC, uintptr(unsafe.Pointer(&dis.RcItem)), hBrush)
				procDeleteObject.Call(hBrush)
				return 1
			}

			var fontName string
			if int(dis.ItemID) < len(systemFontsList) {
				fontName = systemFontsList[dis.ItemID]
			} else {
				var buf [128]uint16
				procSendMessageW.Call(dis.HwndItem, CB_GETLBTEXT, uintptr(dis.ItemID), uintptr(unsafe.Pointer(&buf[0])))
				fontName = syscall.UTF16ToString(buf[:])
			}

			isSelected := (dis.ItemState & ODS_SELECTED) != 0
			isEdit := (dis.ItemState & ODS_COMBOBOXEDIT) != 0

			var bgColor uint32 = 0x0028211C // Deep Slate (#1C2128)
			var textColor uint32 = 0x00FCFAF8 // Crisp White (#F8FAFC)

			if isSelected && !isEdit {
				bgColor = 0x008A3B0E // Highlight
				textColor = 0x00FFFFFF
			} else if isEdit {
				bgColor = 0x0028211C
				textColor = 0x00FFE500 // Cyan text for active font preview
			}

			hBrush, _, _ := procCreateSolidBrush.Call(uintptr(bgColor))
			procFillRect.Call(dis.HDC, uintptr(unsafe.Pointer(&dis.RcItem)), hBrush)
			procDeleteObject.Call(hBrush)

			procSetBkMode.Call(dis.HDC, 1) // TRANSPARENT
			procSetTextColor.Call(dis.HDC, uintptr(textColor))

			hItemFont := getCachedFont(fontName, 19)
			oldFont, _, _ := procSelectObject.Call(dis.HDC, hItemFont)

			rcText := dis.RcItem
			rcText.Left += 8
			rcText.Right -= 4

			procDrawTextW.Call(
				dis.HDC,
				uintptr(unsafe.Pointer(strPtr(fontName))),
				uintptr(len([]rune(fontName))),
				uintptr(unsafe.Pointer(&rcText)),
				DT_SINGLELINE|DT_VCENTER|DT_NOPREFIX,
			)

			procSelectObject.Call(dis.HDC, oldFont)
			return 1
		}
		return 0
	case WM_CTLCOLORLISTBOX:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00FCFAF8)
		procSetBkColor.Call(hdc, 0x0028211C)
		return hBrushEditBg
	case WM_CTLCOLOREDIT:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00FCFAF8) // Crisp White Text
		procSetBkColor.Call(hdc, 0x0028211C) // Deep Slate #1C2128
		return hBrushEditBg
	case WM_CTLCOLORBTN:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00FCFAF8)
		procSetBkColor.Call(hdc, 0x002E2722)
		return hBrushDarkBg
	case WM_COMMAND:
		cmdID := wParam & 0xFFFF
		cmdCode := (wParam >> 16) & 0xFFFF
		if cmdID == IDC_COMBO_FONT && cmdCode == CBN_SELCHANGE {
			selIdx, _, _ := procSendMessageW.Call(hwndComboFont, CB_GETCURSEL, 0, 0)
			if int(int32(selIdx)) >= 0 && int(selIdx) < len(systemFontsList) {
				selectedFont := systemFontsList[selIdx]
				config.HUDFont = selectedFont
				updateHUDFont()
			}
			return 0
		} else if cmdID == IDC_BTN_LANG_EN {
			config.UILanguage = "EN"
			saveConfig()
			refreshSettingsDialogUI()
			return 0
		} else if cmdID == IDC_BTN_LANG_RU {
			config.UILanguage = "RU"
			saveConfig()
			refreshSettingsDialogUI()
			return 0
		} else if cmdID == IDC_BTN_RECORD {
			if isRecordingHotkey {
				stopRecordingHotkeyUI()
			} else {
				startRecordingHotkeyUI()
			}
			return 0
		} else if cmdID == IDC_BTN_SAVE {
			if isRecordingHotkey {
				stopRecordingHotkeyUI()
			}
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			config.GroqAPIKey = strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))

			var bufHotkey [64]uint16
			procGetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(&bufHotkey[0])), 64)
			newHotkey := strings.TrimSpace(syscall.UTF16ToString(bufHotkey[:]))
			if newHotkey != "" {
				config.Hotkey = newHotkey
				vk, mod := parseHotkeyString(newHotkey)
				config.HotkeyVK = vk
				config.HotkeyMod = mod
			}

			selIdx, _, _ := procSendMessageW.Call(hwndComboFont, CB_GETCURSEL, 0, 0)
			if int(int32(selIdx)) >= 0 && int(selIdx) < len(systemFontsList) {
				config.HUDFont = systemFontsList[selIdx]
			} else {
				var bufFont [128]uint16
				procGetWindowTextW.Call(hwndComboFont, uintptr(unsafe.Pointer(&bufFont[0])), 128)
				newFont := strings.TrimSpace(syscall.UTF16ToString(bufFont[:]))
				if newFont != "" {
					config.HUDFont = newFont
				} else {
					config.HUDFont = "Comfortaa"
				}
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
			openBrowserURL(GroqKeysURL)
			return 0
		} else if cmdID == IDC_BTN_BROWSE {
			folder := pickFolderNative(hwnd)
			if folder != "" {
				procSetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(strPtr(folder))))
			}
			return 0
		} else if cmdID == IDC_BTN_DICT {
			openDictionaryEditor()
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

func getCachedFont(fontName string, height int32) uintptr {
	key := fmt.Sprintf("%s_%d", fontName, height)
	fontCacheMutex.Lock()
	defer fontCacheMutex.Unlock()
	if hf, ok := fontCache[key]; ok && hf != 0 {
		return hf
	}
	hf, _, _ := procCreateFontW.Call(
		uintptr(height), 0, 0, 0, 600, 0, 0, 0,
		1, // DEFAULT_CHARSET
		0, 0, 5, // CLEARTYPE_QUALITY
		0,
		uintptr(unsafe.Pointer(strPtr(fontName))),
	)
	if hf != 0 {
		fontCache[key] = hf
	}
	return hf
}

func initSystemFonts() {
	if len(systemFontsList) > 0 {
		return
	}
	seen := make(map[string]bool)
	var fonts []string

	curated := []string{
		"Comfortaa",
		"Segoe UI",
		"Arial",
		"Bahnschrift",
		"Calibri",
		"Cascadia Code",
		"Century Gothic",
		"Comic Sans MS",
		"Consolas",
		"Constantia",
		"Corbel",
		"Courier New",
		"Franklin Gothic Medium",
		"Gabriola",
		"Georgia",
		"Impact",
		"Lucida Console",
		"Lucida Sans Unicode",
		"Palatino Linotype",
		"Segoe Print",
		"Segoe Script",
		"Sitka Text",
		"Tahoma",
		"Times New Roman",
		"Trebuchet MS",
		"Verdana",
	}

	hdc, _, _ := procGetDC.Call(0)
	if hdc != 0 {
		var lf LOGFONTW
		lf.LfCharSet = 1 // DEFAULT_CHARSET
		cb := syscall.NewCallback(func(lpelfe uintptr, lpntme uintptr, fontType uint32, lParam uintptr) uintptr {
			elf := (*ENUMLOGFONTEXW)(unsafe.Pointer(lpelfe))
			name := strings.TrimSpace(syscall.UTF16ToString(elf.ElfLogFont.LfFaceName[:]))
			if name != "" && !strings.HasPrefix(name, "@") {
				lower := strings.ToLower(name)
				if !seen[lower] {
					seen[lower] = true
					fonts = append(fonts, name)
				}
			}
			return 1
		})
		procEnumFontFamilies.Call(hdc, uintptr(unsafe.Pointer(&lf)), cb, 0, 0)
		procReleaseDC.Call(0, hdc)
	}

	for _, c := range curated {
		lower := strings.ToLower(c)
		if !seen[lower] {
			seen[lower] = true
			fonts = append(fonts, c)
		}
	}

	if config.HUDFont != "" {
		lower := strings.ToLower(config.HUDFont)
		if !seen[lower] {
			seen[lower] = true
			fonts = append(fonts, config.HUDFont)
		}
	}

	sort.Slice(fonts, func(i, j int) bool {
		return strings.ToLower(fonts[i]) < strings.ToLower(fonts[j])
	})

	systemFontsList = fonts
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

			if isRecordingHotkey {
				time.Sleep(50 * time.Millisecond)
				continue
			}

			vk := config.HotkeyVK
			mod := config.HotkeyMod
			if vk == 0 {
				vk = VK_OEM_3
				mod = MOD_ALT
			}

			state, _, _ := procGetAsyncKeyState.Call(uintptr(vk))
			isDown := (state & 0x8000) != 0

			if isDown && !wasPressed {
				if matchModifiers(mod) {
					wasPressed = true
					if time.Since(lastToggle) > 300*time.Millisecond {
						lastToggle = time.Now()
						writeLog(fmt.Sprintf("Hardware hotkey press: [%s] (VK %d, MOD %d)", config.Hotkey, vk, mod))
						go toggleRecording()
					}
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
				uintptr(unsafe.Pointer(strPtr("GIN-Voice is already active and running in the System Tray (near the clock).\n\n• Press [Alt + ~] (or your hotkey) to dictate.\n• Right-click the microphone icon in tray to open settings."))),
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
		if hwndSetup != 0 {
			vis, _, _ := procIsWindowVisible.Call(hwndSetup)
			if vis != 0 {
				isDlg, _, _ := procIsDialogMessageW.Call(hwndSetup, uintptr(unsafe.Pointer(&msg)))
				if isDlg != 0 {
					continue
				}
			}
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
