package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

// App Metadata
const (
	AppName           = "GIN-VPN"
	AppVersion        = "v004"
	AppTitle          = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client"
	AppAuthor         = "VladiMIR+AI (Vladimir Bulantsev - GinCz)"
	DefaultInstallDir = `C:\Program Files\GIN-VPN`
	RegistryAppKey    = `Software\GinCz\GIN-VPN`
	DefaultCoreURL    = "https://prodvig-saita.ru/vpn/xray64.exe"
	FallbackCoreURL   = "http://prodvig-saita.ru/vpn/xray64.exe"
	CheckIPURL        = "http://prodvig-saita.ru/ip/"
)

// Win32 API DLLs and Procedures
var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	comctl32 = syscall.NewLazyDLL("comctl32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	advapi32 = syscall.NewLazyDLL("advapi32.dll")
	wininet  = syscall.NewLazyDLL("wininet.dll")

	procRegisterClassExW       = user32.NewProc("RegisterClassExW")
	procCreateWindowExW        = user32.NewProc("CreateWindowExW")
	procDefWindowProcW         = user32.NewProc("DefWindowProcW")
	procDestroyWindow          = user32.NewProc("DestroyWindow")
	procPostQuitMessage        = user32.NewProc("PostQuitMessage")
	procShowWindow             = user32.NewProc("ShowWindow")
	procUpdateWindow           = user32.NewProc("UpdateWindow")
	procGetMessageW            = user32.NewProc("GetMessageW")
	procTranslateMessage       = user32.NewProc("TranslateMessage")
	procDispatchMessageW       = user32.NewProc("DispatchMessageW")
	procSendMessageW           = user32.NewProc("SendMessageW")
	procSetWindowTextW         = user32.NewProc("SetWindowTextW")
	procGetWindowTextW         = user32.NewProc("GetWindowTextW")
	procGetWindowTextLengthW   = user32.NewProc("GetWindowTextLengthW")
	procEnableWindow           = user32.NewProc("EnableWindow")
	procLoadIconW              = user32.NewProc("LoadIconW")
	procLoadCursorW            = user32.NewProc("LoadCursorW")
	procSetTimer               = user32.NewProc("SetTimer")
	procKillTimer              = user32.NewProc("KillTimer")
	procInvalidateRect         = user32.NewProc("InvalidateRect")
	procBeginPaint             = user32.NewProc("BeginPaint")
	procEndPaint               = user32.NewProc("EndPaint")
	procCreatePopupMenu        = user32.NewProc("CreatePopupMenu")
	procAppendMenuW            = user32.NewProc("AppendMenuW")
	procTrackPopupMenu         = user32.NewProc("TrackPopupMenu")
	procDestroyMenu            = user32.NewProc("DestroyMenu")
	procGetCursorPos           = user32.NewProc("GetCursorPos")
	procSetForegroundWindow    = user32.NewProc("SetForegroundWindow")
	procOpenClipboard          = user32.NewProc("OpenClipboard")
	procCloseClipboard         = user32.NewProc("CloseClipboard")
	procEmptyClipboard         = user32.NewProc("EmptyClipboard")
	procSetClipboardData       = user32.NewProc("SetClipboardData")
	procGetClipboardData       = user32.NewProc("GetClipboardData")
	procIsClipboardFormatAvail = user32.NewProc("IsClipboardFormatAvailable")
	procCreateIconIndirect     = user32.NewProc("CreateIconIndirect")
	procDestroyIcon            = user32.NewProc("DestroyIcon")

	procGetStockObject     = gdi32.NewProc("GetStockObject")
	procCreateFontW        = gdi32.NewProc("CreateFontW")
	procSetBkMode          = gdi32.NewProc("SetBkMode")
	procSetTextColor       = gdi32.NewProc("SetTextColor")
	procSetBkColor         = gdi32.NewProc("SetBkColor")
	procCreatePen          = gdi32.NewProc("CreatePen")
	procCreateSolidBrush   = gdi32.NewProc("CreateSolidBrush")
	procSelectObject       = gdi32.NewProc("SelectObject")
	procDeleteObject       = gdi32.NewProc("DeleteObject")
	procCreateCompatibleDC = gdi32.NewProc("CreateCompatibleDC")
	procCreateBitmap       = gdi32.NewProc("CreateBitmap")
	procDeleteDC           = gdi32.NewProc("DeleteDC")
	procPolygon            = gdi32.NewProc("Polygon")
	procRectangle          = gdi32.NewProc("Rectangle")
	procRoundRect          = gdi32.NewProc("RoundRect")

	procGetModuleHandleW     = kernel32.NewProc("GetModuleHandleW")
	procGlobalAlloc          = kernel32.NewProc("GlobalAlloc")
	procGlobalLock           = kernel32.NewProc("GlobalLock")
	procGlobalUnlock         = kernel32.NewProc("GlobalUnlock")
	procInitCommonControlsEx = comctl32.NewProc("InitCommonControlsEx")

	procShell_NotifyIconW = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW     = shell32.NewProc("ShellExecuteW")

	procRegCreateKeyExW  = advapi32.NewProc("RegCreateKeyExW")
	procRegOpenKeyExW    = advapi32.NewProc("RegOpenKeyExW")
	procRegSetValueExW   = advapi32.NewProc("RegSetValueExW")
	procRegDeleteValueW  = advapi32.NewProc("RegDeleteValueW")
	procRegQueryValueExW = advapi32.NewProc("RegQueryValueExW")
	procRegCloseKey      = advapi32.NewProc("RegCloseKey")

	procInternetSetOptionW = wininet.NewProc("InternetSetOptionW")
)

// Win32 Constants
const (
	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	WS_TABSTOP          = 0x00010000
	WS_CLIPCHILDREN     = 0x02000000
	WS_CLIPSIBLINGS     = 0x04000000
	WS_VSCROLL          = 0x00200000

	ES_AUTOHSCROLL = 0x0080
	ES_AUTOVSCROLL = 0x0040
	ES_MULTILINE   = 0x0004
	ES_READONLY    = 0x0800

	BS_PUSHBUTTON = 0x0000
	SS_NOTIFY     = 0x0100
	SS_LEFT       = 0x0000
	SS_CENTER     = 0x0001

	LVS_REPORT                   = 0x0001
	LVS_SINGLESEL                = 0x0004
	LVS_SHOWSELALWAYS            = 0x0008
	LVS_EX_FULLROWSELECT         = 0x00000020
	LVS_EX_GRIDLINES             = 0x00000001
	LVM_FIRST                    = 0x1000
	LVM_INSERTCOLUMNW            = LVM_FIRST + 97
	LVM_INSERTITEMW              = LVM_FIRST + 77
	LVM_SETITEMTEXTW             = LVM_FIRST + 116
	LVM_DELETEALLITEMS           = LVM_FIRST + 9
	LVM_DELETEITEM               = LVM_FIRST + 8
	LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54
	LVM_GETNEXTITEM              = LVM_FIRST + 12
	LVNI_SELECTED                = 0x0002

	WM_CREATE         = 0x0001
	WM_DESTROY        = 0x0002
	WM_PAINT          = 0x000F
	WM_CLOSE          = 0x0010
	WM_COMMAND        = 0x0111
	WM_TIMER          = 0x0113
	WM_SYSCOMMAND     = 0x0112
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CTLCOLORBTN    = 0x0135
	WM_SETFONT        = 0x0030
	WM_RBUTTONUP      = 0x0205
	WM_LBUTTONDBLCLK  = 0x0203

	SC_MINIMIZE = 0xF020

	NIM_ADD     = 0x00000000
	NIM_MODIFY  = 0x00000001
	NIM_DELETE  = 0x00000002
	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004
	NIF_INFO    = 0x00000010

	NIIF_INFO    = 0x00000001
	NIIF_WARNING = 0x00000002
	NIIF_ERROR   = 0x00000003

	MF_STRING       = 0x0000
	MF_SEPARATOR    = 0x0800
	TPM_RIGHTBUTTON = 0x0002

	CF_UNICODETEXT = 13
	GMEM_MOVEABLE  = 0x0002

	HKEY_CURRENT_USER = 0x80000001
	KEY_READ          = 0x20019
	KEY_WRITE         = 0x20006
	KEY_ALL_ACCESS    = 0xF003F
	REG_DWORD         = 4
	REG_SZ            = 1
	REG_BINARY        = 3

	INTERNET_OPTION_SETTINGS_CHANGED = 39
	INTERNET_OPTION_REFRESH          = 37

	WM_USER     = 0x0400
	WM_TRAYICON = WM_USER + 1

	SW_HIDE       = 0
	SW_SHOWNORMAL = 1
	SW_RESTORE    = 9

	CREATE_NO_WINDOW = 0x08000000
)

// UI Control IDs
const (
	ID_BTN_CONNECT      = 1001
	ID_BTN_CLEAR_PASTE  = 1002
	ID_BTN_SAVE_KEY     = 1003
	ID_BTN_CHECK_IP     = 1004
	ID_BTN_VIEW_LOG     = 1005
	ID_BTN_CLEAR_LOG    = 1006
	ID_BTN_LIST_CONNECT = 1007
	ID_BTN_LIST_DEFAULT = 1008
	ID_BTN_LIST_DELETE  = 1009
	ID_BTN_INSTALL      = 1010
	ID_BTN_THEME_TOGGLE = 1011
	ID_EDIT_KEY         = 1012
	ID_EDIT_LOG         = 1013
	ID_LIST_PROFILES    = 1014

	// Tray Menu IDs
	ID_TRAY_RESTORE  = 2001
	ID_TRAY_CONNECT  = 2002
	ID_TRAY_DISCONN  = 2003
	ID_TRAY_CHECK_IP = 2004
	ID_TRAY_EDIT_KEY = 2005
	ID_TRAY_VIEW_LOG = 2006
	ID_TRAY_EXIT     = 2007
)

// VPN Connection States
type VPNState int

const (
	StateDisconnected VPNState = iota
	StateConnecting
	StateConnected
	StateError
)

func (s VPNState) String() string {
	switch s {
	case StateDisconnected:
		return "DISCONNECTED"
	case StateConnecting:
		return "CONNECTING"
	case StateConnected:
		return "CONNECTED"
	case StateError:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// VPN Profile Model
type Profile struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Link      string `json:"link"`
	Server    string `json:"server"`
	Port      int    `json:"port"`
	IsDefault bool   `json:"is_default"`
}

type ProfileStore struct {
	DefaultID string    `json:"default_id"`
	Profiles  []Profile `json:"profiles"`
}

// Global Application Context
type AppContext struct {
	mu          sync.Mutex
	hWndMain    uintptr
	hFontNormal uintptr
	hFontBold   uintptr
	hFontTitle  uintptr
	hFontMono   uintptr

	// Theme Palettes
	isDarkMode  bool
	hBrushBg    uintptr
	hBrushCard  uintptr
	hBrushEdit  uintptr
	hPenBorder  uintptr
	textColor   uint32

	// Dynamic Shield Icons
	hIconApp    uintptr
	hIconGreen  uintptr
	hIconOrange uintptr
	hIconRed    uintptr
	hIconGray   uintptr

	// Controls
	hStatusBadge  uintptr
	hStatusDesc   uintptr
	hBtnConnect   uintptr
	hBtnTheme     uintptr
	hLblNodeName  uintptr
	hEditKey      uintptr
	hListProfiles uintptr
	hBtnInstall   uintptr
	hLblOrigIP    uintptr
	hLblVPNIP     uintptr
	hLblLatency   uintptr
	hLblUptime    uintptr
	hEditLog      uintptr

	// State
	state         VPNState
	stateMessage  string
	activeProfile Profile
	origIP        string
	origCode      string
	vpnIP         string
	vpnCode       string
	latencyMs     int
	connectTime   time.Time

	// Profile Storage
	store ProfileStore

	// File Paths
	exePath     string
	appDir      string
	configFile  string
	logFile     string
	xrayPath    string

	// Process & Flags
	cmdXray       *exec.Cmd
	trayData      NOTIFYICONDATAW
	trayInstalled bool
	isExiting     bool
	isInstalled   bool
}

var app AppContext

// Win32 Structures
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

type MSG struct {
	HWnd    uintptr
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      POINT
}

type POINT struct {
	X int32
	Y int32
}

type RECT struct {
	Left   int32
	Top    int32
	Right  int32
	Bottom int32
}

type PAINTSTRUCT struct {
	Hdc         uintptr
	FErase      int32
	RcPaint     RECT
	FRestore    int32
	FIncUpdate  int32
	RgbReserved [32]byte
}

type ICONINFO struct {
	FIcon    int32
	XHotspot uint32
	YHotspot uint32
	HbmMask  uintptr
	HbmColor uintptr
}

type NOTIFYICONDATAW struct {
	CbSize           uint32
	HWnd             uintptr
	UID              uint32
	UFlags           uint32
	UCallbackMessage uint32
	HIcon            uintptr
	SzTip            [128]uint16
	DwState          uint32
	DwStateMask      uint32
	SzInfo           [256]uint16
	UTimeoutOrVersion uint32
	SzInfoTitle      [64]uint16
	DwInfoFlags      uint32
	GuidItem         [16]byte
	HBalloonIcon     uintptr
}

type INITCOMMONCONTROLSEX struct {
	DwSize uint32
	DwICC  uint32
}

type LVCOLUMNW struct {
	Mask       uint32
	Fmt        int32
	Cx         int32
	PszText    *uint16
	CchTextMax int32
	ISubItem   int32
	IImage     int32
	IOrder     int32
}

type LVITEMW struct {
	Mask       uint32
	IItem      int32
	ISubItem   int32
	State      uint32
	StateMask  uint32
	PszText    *uint16
	CchTextMax int32
	IImage     int32
	LParam     uintptr
	IIndent    int32
}

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

func copyUTF16(dst []uint16, src string) {
	chars, _ := syscall.UTF16FromString(src)
	maxLen := len(dst) - 1
	if len(chars) < maxLen {
		maxLen = len(chars)
	}
	for i := 0; i < maxLen; i++ {
		dst[i] = chars[i]
	}
	dst[maxLen] = 0
}

func main() {
	var err error
	app.exePath, err = os.Executable()
	if err == nil {
		app.appDir = filepath.Dir(app.exePath)
	} else {
		app.appDir = "."
		app.exePath = filepath.Join(app.appDir, "GIN-VPN.exe")
	}

	app.isInstalled = strings.EqualFold(filepath.Clean(app.appDir), filepath.Clean(DefaultInstallDir))

	// Secure temporary config path (never leaves cleartext keys in root directory)
	app.configFile = filepath.Join(os.TempDir(), "gin_vpn_active_config.json")
	app.logFile = filepath.Join(app.appDir, "vpn.log")

	app.xrayPath = locateXrayCore(app.appDir)
	pruneLogs(app.logFile)

	// Load Profiles & Theme from Windows Registry
	loadRegistrySettings()

	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x00000008 | 0x00000004 | 0x00000001
	procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))

	hInstance, _, _ := procGetModuleHandleW.Call(0)

	className := "GIN_VPN_UNIVERSAL_WIN7_11_SECURE"
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.Style = 0x0002 | 0x0001
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HCursor, _, _ = procLoadCursorW.Call(0, 32512)
	wc.LpszClassName = strPtr(className)

	app.hIconApp, _, _ = procLoadIconW.Call(hInstance, 1)
	if app.hIconApp == 0 {
		app.hIconApp, _, _ = procLoadIconW.Call(0, 32512)
	}
	wc.HIcon = app.hIconApp
	wc.HIconSm = app.hIconApp

	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	// Fonts
	app.hFontNormal = createFont("Segoe UI", 15, 400)
	app.hFontBold = createFont("Segoe UI", 15, 700)
	app.hFontTitle = createFont("Segoe UI", 20, 700)
	app.hFontMono = createFont("Consolas", 13, 400)

	// Shield Icons
	app.hIconGreen = createShieldHIcon(0x0032CD00, 0x005FF541)
	app.hIconOrange = createShieldHIcon(0x000096F0, 0x003CCDFF)
	app.hIconRed = createShieldHIcon(0x001919E1, 0x005F5FFF)
	app.hIconGray = createShieldHIcon(0x00787878, 0x00A0A0A0)

	// Apply Initial Theme Palette
	applyThemePalette(app.isDarkMode)

	screenWidth := getSystemMetrics(0)
	screenHeight := getSystemMetrics(1)
	winWidth := int32(695)
	winHeight := int32(765)
	posX := (screenWidth - winWidth) / 2
	posY := (screenHeight - winHeight) / 2

	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr(className))),
		uintptr(unsafe.Pointer(strPtr(AppTitle+" ["+AppVersion+"]"))),
		WS_OVERLAPPEDWINDOW&^0x00040000,
		uintptr(posX), uintptr(posY),
		uintptr(winWidth), uintptr(winHeight),
		0, 0, hInstance, 0,
	)

	app.hWndMain = hWnd

	defaultProfile := getDefaultProfile()
	if defaultProfile != nil && defaultProfile.Link != "" {
		procShowWindow.Call(hWnd, SW_HIDE)
		logEvent(fmt.Sprintf("[AUTO] Default profile detected (%s). Connecting in background...", defaultProfile.Name))
		showBalloonTip("GIN-VPN: Auto-Connect", fmt.Sprintf("Auto-connecting to %s in background...", defaultProfile.Name), NIIF_INFO)
		go func() {
			time.Sleep(500 * time.Millisecond)
			startVPNWithProfile(*defaultProfile)
		}()
	} else {
		procShowWindow.Call(hWnd, SW_SHOWNORMAL)
		procUpdateWindow.Call(hWnd)
	}

	var msg MSG
	for {
		ret, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if int32(ret) <= 0 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}

func getSystemMetrics(index int32) int32 {
	proc := user32.NewProc("GetSystemMetrics")
	r, _, _ := proc.Call(uintptr(index))
	return int32(r)
}

func createFont(name string, size int32, weight int32) uintptr {
	h, _, _ := procCreateFontW.Call(
		uintptr(-size), 0, 0, 0,
		uintptr(weight), 0, 0, 0,
		1, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr(name))),
	)
	return h
}

func locateXrayCore(appDir string) string {
	candidates := []string{
		filepath.Join(appDir, "xray.exe"),
		filepath.Join(appDir, "xray64.exe"),
		filepath.Join(DefaultInstallDir, "xray.exe"),
		filepath.Join(os.TempDir(), "xray.exe"),
		`C:\XRAY_VPN\xray.exe`,
		`C:\XRAY_VPN\xray64.exe`,
		`C:\Program Files\Xray\xray.exe`,
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}
	return ""
}

// Window Procedure
func wndProc(hWnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_CREATE:
		hInstance, _, _ := procGetModuleHandleW.Call(0)

		// 1. Header Title & Day/Night Theme Button
		createStatic(hWnd, hInstance, "🛡️ GIN-VPN by VladiMIR+AI", 22, 16, 380, 30, app.hFontTitle)

		themeBtnText := "🌙 Dark Mode"
		if app.isDarkMode {
			themeBtnText = "☀️ Light Mode"
		}
		app.hBtnTheme = createButton(hWnd, hInstance, themeBtnText, ID_BTN_THEME_TOGGLE, 545, 14, 117, 28, app.hFontBold)

		app.hStatusBadge = createStatic(hWnd, hInstance, "⚪ DISCONNECTED", 455, 46, 205, 26, app.hFontBold)
		app.hStatusDesc = createStatic(hWnd, hInstance, "Proxy inactive. Direct Internet connection.", 24, 48, 420, 20, app.hFontNormal)

		// 2. Large Action Button: Connect / Disconnect
		app.hBtnConnect = createButton(hWnd, hInstance, "▶ CONNECT VPN", ID_BTN_CONNECT, 22, 74, 640, 42, app.hFontBold)

		// 3. Active VLESS Key Box Section (Word Wrapped)
		app.hLblNodeName = createStatic(hWnd, hInstance, "Active VLESS Reality Key: (Empty)", 24, 126, 320, 20, app.hFontBold)
		createButton(hWnd, hInstance, "📋 Clear & Paste from Buffer", ID_BTN_CLEAR_PASTE, 350, 122, 200, 26, app.hFontNormal)
		createButton(hWnd, hInstance, "💾 Save", ID_BTN_SAVE_KEY, 558, 122, 104, 26, app.hFontNormal)

		app.hEditKey = createEditWrap(hWnd, hInstance, "", ID_EDIT_KEY, 22, 152, 640, 52, app.hFontMono)

		// 4. Saved Profiles Table
		createStatic(hWnd, hInstance, "Saved VPN Profile Keys (Registry Encrypted):", 24, 212, 300, 20, app.hFontBold)
		createButton(hWnd, hInstance, "▶ Connect", ID_BTN_LIST_CONNECT, 325, 208, 98, 26, app.hFontNormal)
		createButton(hWnd, hInstance, "★ Set Default", ID_BTN_LIST_DEFAULT, 429, 208, 120, 26, app.hFontNormal)
		createButton(hWnd, hInstance, "🗑️ Delete", ID_BTN_LIST_DELETE, 555, 208, 107, 26, app.hFontNormal)

		app.hListProfiles = createListView(hWnd, hInstance, ID_LIST_PROFILES, 22, 238, 640, 115)
		initProfileListView(app.hListProfiles)
		populateProfileList()

		// 5. Diagnostics Card
		createStatic(hWnd, hInstance, "Connection Diagnostics & Real-Time Routing:", 24, 362, 400, 20, app.hFontBold)
		app.hLblOrigIP = createStatic(hWnd, hInstance, "Original ISP IP:  Detecting...", 34, 386, 290, 20, app.hFontNormal)
		app.hLblVPNIP = createStatic(hWnd, hInstance, "Protected VPN IP: —", 335, 386, 310, 20, app.hFontNormal)
		app.hLblLatency = createStatic(hWnd, hInstance, "Gateway Latency:  —", 34, 408, 290, 20, app.hFontNormal)
		app.hLblUptime = createStatic(hWnd, hInstance, "Session Uptime:   00:00:00", 335, 408, 310, 20, app.hFontNormal)

		// 6. Action Toolbar Buttons
		createButton(hWnd, hInstance, "🌐 Verify IP + Speed Test", ID_BTN_CHECK_IP, 22, 438, 200, 28, app.hFontNormal)
		createButton(hWnd, hInstance, "📜 View vpn.log", ID_BTN_VIEW_LOG, 232, 438, 140, 28, app.hFontNormal)

		installBtnText := "💾 Install App"
		if app.isInstalled {
			installBtnText = "✅ Installed (Repair)"
		}
		app.hBtnInstall = createButton(hWnd, hInstance, installBtnText, ID_BTN_INSTALL, 382, 438, 280, 28, app.hFontBold)

		// 7. Activity Log Viewer
		createStatic(hWnd, hInstance, "Real-Time Event & Traffic Log:", 24, 474, 350, 20, app.hFontBold)
		createButton(hWnd, hInstance, "🧹 Clear Log", ID_BTN_CLEAR_LOG, 562, 470, 100, 24, app.hFontNormal)
		app.hEditLog = createEditScroll(hWnd, hInstance, "", ID_EDIT_LOG, 22, 498, 640, 215, app.hFontMono)

		initTrayIcon(hWnd)

		logEvent("[INIT] " + AppTitle + " " + AppVersion + " started.")
		logEvent("[SECURE] Configuration is encrypted in Windows Registry: " + RegistryAppKey)
		if app.xrayPath != "" {
			logEvent("[CORE] Detected Xray binary: " + app.xrayPath)
		} else {
			logEvent("[CORE] Core will be auto-fetched silently on first connection if needed.")
		}

		go resolveOriginalIP()

		procSetTimer.Call(hWnd, 1, 1000, 0)
		return 0

	case WM_TIMER:
		updateSessionTimer()
		return 0

	case WM_TRAYICON:
		switch lParam {
		case WM_RBUTTONUP:
			showTrayMenu(hWnd)
		case WM_LBUTTONDBLCLK:
			procShowWindow.Call(hWnd, SW_RESTORE)
			procSetForegroundWindow.Call(hWnd)
		}
		return 0

	case WM_SYSCOMMAND:
		if wParam == SC_MINIMIZE {
			procShowWindow.Call(hWnd, SW_HIDE)
			showBalloonTip("GIN-VPN Minimized", "GIN-VPN is running in system tray. Double-click icon to open.", NIIF_INFO)
			return 0
		}

	case WM_COMMAND:
		cmdID := int(wParam & 0xFFFF)
		switch cmdID {
		case ID_BTN_THEME_TOGGLE:
			toggleDayNightTheme()
		case ID_BTN_CONNECT:
			toggleVPN()
		case ID_BTN_CLEAR_PASTE:
			clearAndPasteKeyWithValidation()
		case ID_BTN_SAVE_KEY:
			saveKeyToProfiles()
		case ID_BTN_LIST_CONNECT:
			connectSelectedProfile()
		case ID_BTN_LIST_DEFAULT:
			setDefaultSelectedProfile()
		case ID_BTN_LIST_DELETE:
			deleteSelectedProfile()
		case ID_BTN_CHECK_IP, ID_TRAY_CHECK_IP:
			openBrowser(CheckIPURL)
		case ID_BTN_VIEW_LOG, ID_TRAY_VIEW_LOG:
			openNotepad(app.logFile)
		case ID_BTN_INSTALL:
			go installApplication()
		case ID_BTN_CLEAR_LOG:
			clearLogView()
		case ID_TRAY_RESTORE:
			procShowWindow.Call(hWnd, SW_RESTORE)
			procSetForegroundWindow.Call(hWnd)
		case ID_TRAY_CONNECT:
			if app.state != StateConnected && app.state != StateConnecting {
				toggleVPN()
			}
		case ID_TRAY_DISCONN:
			if app.state == StateConnected || app.state == StateConnecting {
				toggleVPN()
			}
		case ID_TRAY_EDIT_KEY:
			procShowWindow.Call(hWnd, SW_RESTORE)
			procSetForegroundWindow.Call(hWnd)
		case ID_TRAY_EXIT:
			app.isExiting = true
			stopVPN(true)
			removeTrayIcon()
			procDestroyWindow.Call(hWnd)
		}
		return 0

	case WM_CTLCOLORSTATIC, WM_CTLCOLOREDIT, WM_CTLCOLORBTN:
		hdc := wParam
		ctlHwnd := lParam

		if ctlHwnd == app.hStatusBadge {
			procSetBkMode.Call(hdc, 1)
			switch app.state {
			case StateConnected:
				procSetTextColor.Call(hdc, 0x00008000)
			case StateConnecting:
				procSetTextColor.Call(hdc, 0x00007EE6)
			case StateError:
				procSetTextColor.Call(hdc, 0x002F2FD3)
			default:
				if app.isDarkMode {
					procSetTextColor.Call(hdc, 0x00A0A0A0)
				} else {
					procSetTextColor.Call(hdc, 0x0068625A)
				}
			}
			return app.hBrushCard
		}

		if ctlHwnd == app.hEditKey || ctlHwnd == app.hEditLog {
			if app.isDarkMode {
				procSetBkColor.Call(hdc, 0x001B1612)
				procSetTextColor.Call(hdc, 0x00E0E6ED)
			} else {
				procSetBkColor.Call(hdc, 0x00FFFFFF)
				procSetTextColor.Call(hdc, 0x002C201A)
			}
			return app.hBrushEdit
		}

		procSetBkMode.Call(hdc, 1)
		procSetTextColor.Call(hdc, uintptr(app.textColor))
		return app.hBrushBg

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hWnd, uintptr(unsafe.Pointer(&ps)))

		var rc RECT
		rc.Left = ps.RcPaint.Left
		rc.Top = ps.RcPaint.Top
		rc.Right = ps.RcPaint.Right
		rc.Bottom = ps.RcPaint.Bottom
		user32.NewProc("FillRect").Call(hdc, uintptr(unsafe.Pointer(&rc)), app.hBrushBg)

		hOldPen, _, _ := procSelectObject.Call(hdc, app.hPenBorder)
		hOldBrush, _, _ := procSelectObject.Call(hdc, app.hBrushCard)

		procRoundRect.Call(hdc, 22, 380, 662, 432, 6, 6)

		procSelectObject.Call(hdc, hOldPen)
		procSelectObject.Call(hdc, hOldBrush)

		procEndPaint.Call(hWnd, uintptr(unsafe.Pointer(&ps)))
		return 0

	case WM_CLOSE:
		procShowWindow.Call(hWnd, SW_HIDE)
		showBalloonTip("GIN-VPN Active", "GIN-VPN is minimized to system tray. VPN remains active.", NIIF_INFO)
		return 0

	case WM_DESTROY:
		stopVPN(true)
		removeTrayIcon()
		procPostQuitMessage.Call(0)
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hWnd, uintptr(msg), wParam, lParam)
	return ret
}

// Day / Night Theme Switcher
func applyThemePalette(darkMode bool) {
	if app.hBrushBg != 0 {
		procDeleteObject.Call(app.hBrushBg)
	}
	if app.hBrushCard != 0 {
		procDeleteObject.Call(app.hBrushCard)
	}
	if app.hBrushEdit != 0 {
		procDeleteObject.Call(app.hBrushEdit)
	}
	if app.hPenBorder != 0 {
		procDeleteObject.Call(app.hPenBorder)
	}

	app.isDarkMode = darkMode
	if darkMode {
		app.hBrushBg, _, _ = procCreateSolidBrush.Call(0x00201B18)   // #181B20 Dark
		app.hBrushCard, _, _ = procCreateSolidBrush.Call(0x002E2722) // #22272E Card
		app.hBrushEdit, _, _ = procCreateSolidBrush.Call(0x001B1612) // #12161B Edit
		app.hPenBorder, _, _ = procCreatePen.Call(0, 1, 0x004A3E38)  // #383E4A Border
		app.textColor = 0x00EDE6E0                                   // Soft White
	} else {
		app.hBrushBg, _, _ = procCreateSolidBrush.Call(0x00FFFFFF)   // #FFFFFF White
		app.hBrushCard, _, _ = procCreateSolidBrush.Call(0x00F9F6F4) // #F4F6F9 Card
		app.hBrushEdit, _, _ = procCreateSolidBrush.Call(0x00FFFFFF) // #FFFFFF Edit
		app.hPenBorder, _, _ = procCreatePen.Call(0, 1, 0x003A302B)  // #2B303A Border
		app.textColor = 0x002C201A                                   // Deep Charcoal
	}
}

func toggleDayNightTheme() {
	app.isDarkMode = !app.isDarkMode
	applyThemePalette(app.isDarkMode)

	themeText := "🌙 Dark Mode"
	themeVal := "Light"
	if app.isDarkMode {
		themeText = "☀️ Light Mode"
		themeVal = "Dark"
	}
	setControlText(app.hBtnTheme, themeText)

	// Save Theme to Registry
	saveRegistryString("ThemeMode", themeVal)

	procInvalidateRect.Call(app.hWndMain, 0, 1)
	logEvent("[THEME] Switched theme to: " + themeVal)
}

// GUI Control Creation Helpers
func createStatic(hParent, hInst uintptr, text string, x, y, w, h int32, hFont uintptr) uintptr {
	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		WS_CHILD|WS_VISIBLE|SS_LEFT|SS_NOTIFY,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hParent, 0, hInst, 0,
	)
	if hFont != 0 {
		procSendMessageW.Call(hWnd, WM_SETFONT, hFont, 1)
	}
	return hWnd
}

func createButton(hParent, hInst uintptr, text string, id int, x, y, w, h int32, hFont uintptr) uintptr {
	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_PUSHBUTTON,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hParent, uintptr(id), hInst, 0,
	)
	if hFont != 0 {
		procSendMessageW.Call(hWnd, WM_SETFONT, hFont, 1)
	}
	return hWnd
}

func createEditWrap(hParent, hInst uintptr, text string, id int, x, y, w, h int32, hFont uintptr) uintptr {
	style := uintptr(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_TABSTOP | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL)
	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		style,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hParent, uintptr(id), hInst, 0,
	)
	if hFont != 0 {
		procSendMessageW.Call(hWnd, WM_SETFONT, hFont, 1)
	}
	return hWnd
}

func createEditScroll(hParent, hInst uintptr, text string, id int, x, y, w, h int32, hFont uintptr) uintptr {
	style := uintptr(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY)
	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		style,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hParent, uintptr(id), hInst, 0,
	)
	if hFont != 0 {
		procSendMessageW.Call(hWnd, WM_SETFONT, hFont, 1)
	}
	return hWnd
}

func createListView(hParent, hInst uintptr, id int, x, y, w, h int32) uintptr {
	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("SysListView32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hParent, uintptr(id), hInst, 0,
	)
	procSendMessageW.Call(hWnd, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES)
	if app.hFontNormal != 0 {
		procSendMessageW.Call(hWnd, WM_SETFONT, app.hFontNormal, 1)
	}
	return hWnd
}

func initProfileListView(hList uintptr) {
	insertColumn(hList, 0, "Default", 65)
	insertColumn(hList, 1, "Profile / Device Name", 230)
	insertColumn(hList, 2, "Server Host Address", 210)
	insertColumn(hList, 3, "Port", 80)
}

func insertColumn(hList uintptr, colIndex int32, title string, width int32) {
	var lvc LVCOLUMNW
	lvc.Mask = 0x0001 | 0x0002 | 0x0004
	lvc.Fmt = 0
	lvc.Cx = width
	lvc.PszText = strPtr(title)
	procSendMessageW.Call(hList, LVM_INSERTCOLUMNW, uintptr(colIndex), uintptr(unsafe.Pointer(&lvc)))
}

func populateProfileList() {
	procSendMessageW.Call(app.hListProfiles, LVM_DELETEALLITEMS, 0, 0)
	for i, p := range app.store.Profiles {
		defStr := ""
		if p.IsDefault || p.ID == app.store.DefaultID {
			defStr = "★ YES"
		}

		var lvi LVITEMW
		lvi.Mask = 0x0001
		lvi.IItem = int32(i)
		lvi.ISubItem = 0
		lvi.PszText = strPtr(defStr)
		procSendMessageW.Call(app.hListProfiles, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&lvi)))

		setListViewSubItem(app.hListProfiles, int32(i), 1, p.Name)
		setListViewSubItem(app.hListProfiles, int32(i), 2, p.Server)
		setListViewSubItem(app.hListProfiles, int32(i), 3, strconv.Itoa(p.Port))
	}
}

func setListViewSubItem(hList uintptr, item, subItem int32, text string) {
	var lvi LVITEMW
	lvi.Mask = 0x0001
	lvi.IItem = item
	lvi.ISubItem = subItem
	lvi.PszText = strPtr(text)
	procSendMessageW.Call(hList, LVM_SETITEMTEXTW, uintptr(item), uintptr(unsafe.Pointer(&lvi)))
}

// System Tray Notification Area
func initTrayIcon(hWnd uintptr) {
	app.trayData.CbSize = uint32(unsafe.Sizeof(app.trayData))
	app.trayData.HWnd = hWnd
	app.trayData.UID = 100
	app.trayData.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	app.trayData.UCallbackMessage = WM_TRAYICON
	app.trayData.HIcon = app.hIconGray
	copyUTF16(app.trayData.SzTip[:], "GIN-VPN: Disconnected")

	procShell_NotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&app.trayData)))
	app.trayInstalled = true
}

func updateTrayIcon(state VPNState, tooltip string) {
	if !app.trayInstalled {
		return
	}
	app.trayData.UFlags = NIF_ICON | NIF_TIP
	switch state {
	case StateConnected:
		app.trayData.HIcon = app.hIconGreen
	case StateConnecting:
		app.trayData.HIcon = app.hIconOrange
	case StateError:
		app.trayData.HIcon = app.hIconRed
	default:
		app.trayData.HIcon = app.hIconGray
	}
	if len(tooltip) > 63 {
		tooltip = tooltip[:60] + "..."
	}
	copyUTF16(app.trayData.SzTip[:], tooltip)
	procShell_NotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&app.trayData)))
}

func showBalloonTip(title, message string, infoFlags uint32) {
	if !app.trayInstalled {
		return
	}
	app.trayData.UFlags = NIF_INFO
	copyUTF16(app.trayData.SzInfoTitle[:], title)
	copyUTF16(app.trayData.SzInfo[:], message)
	app.trayData.DwInfoFlags = infoFlags
	procShell_NotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&app.trayData)))
}

func removeTrayIcon() {
	if app.trayInstalled {
		procShell_NotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&app.trayData)))
		app.trayInstalled = false
	}
}

func showTrayMenu(hWnd uintptr) {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	statusText := "GIN-VPN: Disconnected"
	if app.state == StateConnected {
		statusText = fmt.Sprintf("VPN: %s (%s)", app.vpnIP, app.vpnCode)
	} else if app.state == StateConnecting {
		statusText = "VPN: Connecting..."
	}
	procAppendMenuW.Call(hMenu, MF_STRING, 0, uintptr(unsafe.Pointer(strPtr(statusText))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_RESTORE, uintptr(unsafe.Pointer(strPtr("📂 Open GIN-VPN Dashboard"))))
	if app.state == StateConnected {
		procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_DISCONN, uintptr(unsafe.Pointer(strPtr("⏹ Disconnect VPN"))))
	} else {
		procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_CONNECT, uintptr(unsafe.Pointer(strPtr("▶ Connect VPN"))))
	}

	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_CHECK_IP, uintptr(unsafe.Pointer(strPtr("🌐 Verify IP + Speed Test"))))
	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_EDIT_KEY, uintptr(unsafe.Pointer(strPtr("📝 Open Dashboard"))))
	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_VIEW_LOG, uintptr(unsafe.Pointer(strPtr("📋 View vpn.log"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_EXIT, uintptr(unsafe.Pointer(strPtr("❌ Disconnect & Exit"))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hWnd)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hWnd, 0)
	procDestroyMenu.Call(hMenu)
}

// Dynamic GDI Shield Icon Generator
func createShieldHIcon(mainColorBGR, highlightBGR uint32) uintptr {
	hDC, _, _ := procCreateCompatibleDC.Call(0)
	if hDC == 0 {
		return 0
	}
	defer procDeleteDC.Call(hDC)

	hBmp, _, _ := procCreateBitmap.Call(16, 16, 1, 32, 0)
	hMask, _, _ := procCreateBitmap.Call(16, 16, 1, 1, 0)
	if hBmp == 0 || hMask == 0 {
		return 0
	}

	hOldBmp, _, _ := procSelectObject.Call(hDC, hBmp)

	hBrushBlack, _, _ := procCreateSolidBrush.Call(0x00000000)
	var rc RECT
	rc.Right = 16
	rc.Bottom = 16
	user32.NewProc("FillRect").Call(hDC, uintptr(unsafe.Pointer(&rc)), hBrushBlack)
	procDeleteObject.Call(hBrushBlack)

	hPenBlack, _, _ := procCreatePen.Call(0, 1, 0x000C1C0C)
	hBrushMain, _, _ := procCreateSolidBrush.Call(uintptr(mainColorBGR))
	procSelectObject.Call(hDC, hPenBlack)
	procSelectObject.Call(hDC, hBrushMain)

	points := []POINT{
		{X: 8, Y: 1},
		{X: 14, Y: 3},
		{X: 14, Y: 9},
		{X: 8, Y: 15},
		{X: 2, Y: 9},
		{X: 2, Y: 3},
	}
	procPolygon.Call(hDC, uintptr(unsafe.Pointer(&points[0])), uintptr(len(points)))

	hBrushHigh, _, _ := procCreateSolidBrush.Call(uintptr(highlightBGR))
	procSelectObject.Call(hDC, hBrushHigh)
	innerPts := []POINT{
		{X: 8, Y: 3},
		{X: 12, Y: 5},
		{X: 12, Y: 8},
		{X: 8, Y: 13},
		{X: 4, Y: 8},
		{X: 4, Y: 5},
	}
	procPolygon.Call(hDC, uintptr(unsafe.Pointer(&innerPts[0])), uintptr(len(innerPts)))

	procSelectObject.Call(hDC, hOldBmp)
	procDeleteObject.Call(hPenBlack)
	procDeleteObject.Call(hBrushMain)
	procDeleteObject.Call(hBrushHigh)

	var ii ICONINFO
	ii.FIcon = 1
	ii.HbmMask = hMask
	ii.HbmColor = hBmp

	hIcon, _, _ := procCreateIconIndirect.Call(uintptr(unsafe.Pointer(&ii)))
	procDeleteObject.Call(hBmp)
	procDeleteObject.Call(hMask)

	return hIcon
}

// VLESS Parser & Config Generator
type VLESSConfig struct {
	ID          string
	Server      string
	Port        int
	PublicKey   string
	ShortID     string
	ServerName  string
	Fingerprint string
	Flow        string
	SpiderX     string
	ProfileName string
}

func parseVLESSLink(link string) (*VLESSConfig, error) {
	link = strings.TrimSpace(link)
	if !strings.HasPrefix(link, "vless://") {
		return nil, fmt.Errorf("link does not start with vless://")
	}

	re := regexp.MustCompile(`^vless://(?P<id>[^@]+)@(?P<ip>[^:]+):(?P<port>\d+)\?(?P<params>[^#]+)(#(?P<name>.*))?$`)
	match := re.FindStringSubmatch(link)
	if match == nil {
		return nil, fmt.Errorf("invalid VLESS URI syntax")
	}

	cfg := &VLESSConfig{
		Fingerprint: "chrome",
		SpiderX:     "/",
		ProfileName: "GIN-VPN Node",
	}

	for i, name := range re.SubexpNames() {
		if i == 0 || name == "" {
			continue
		}
		val := match[i]
		switch name {
		case "id":
			cfg.ID = val
		case "ip":
			cfg.Server = val
		case "port":
			cfg.Port, _ = strconv.Atoi(val)
		case "name":
			if val != "" {
				unescaped, err := url.QueryUnescape(val)
				if err == nil {
					cfg.ProfileName = unescaped
				} else {
					cfg.ProfileName = val
				}
			}
		case "params":
			params, _ := url.ParseQuery(val)
			if pbk := params.Get("pbk"); pbk != "" {
				cfg.PublicKey = pbk
			}
			if sid := params.Get("sid"); sid != "" {
				cfg.ShortID = sid
			}
			if sni := params.Get("sni"); sni != "" {
				cfg.ServerName = sni
			}
			if fp := params.Get("fp"); fp != "" {
				cfg.Fingerprint = fp
			}
			if flow := params.Get("flow"); flow != "" {
				cfg.Flow = flow
			}
			if spx := params.Get("spx"); spx != "" {
				cfg.SpiderX = spx
			}
		}
	}

	if cfg.ID == "" || cfg.Server == "" || cfg.Port == 0 {
		return nil, fmt.Errorf("missing core VLESS parameters")
	}

	return cfg, nil
}

func generateXrayJSON(cfg *VLESSConfig) string {
	jsonObj := map[string]interface{}{
		"log": map[string]interface{}{
			"loglevel": "warning",
		},
		"inbounds": []map[string]interface{}{
			{
				"port":     10808,
				"listen":   "127.0.0.1",
				"protocol": "socks",
				"settings": map[string]interface{}{
					"udp": true,
				},
			},
			{
				"port":     10809,
				"listen":   "127.0.0.1",
				"protocol": "http",
				"settings": map[string]interface{}{},
			},
		},
		"outbounds": []map[string]interface{}{
			{
				"protocol": "vless",
				"settings": map[string]interface{}{
					"vnext": []map[string]interface{}{
						{
							"address": cfg.Server,
							"port":    cfg.Port,
							"users": []map[string]interface{}{
								{
									"id":         cfg.ID,
									"encryption": "none",
									"flow":       cfg.Flow,
								},
							},
						},
					},
				},
				"streamSettings": map[string]interface{}{
					"network":  "tcp",
					"security": "reality",
					"realitySettings": map[string]interface{}{
						"publicKey":   cfg.PublicKey,
						"fingerprint": cfg.Fingerprint,
						"serverName":  cfg.ServerName,
						"shortId":     cfg.ShortID,
						"spiderX":     cfg.SpiderX,
					},
				},
			},
		},
	}

	data, _ := json.MarshalIndent(jsonObj, "", "  ")
	return string(data)
}

// Secure Windows Registry Storage
func loadRegistrySettings() {
	app.store = ProfileStore{Profiles: []Profile{}}

	rawProfiles := readRegistryString("Profiles")
	if rawProfiles != "" {
		_ = json.Unmarshal([]byte(rawProfiles), &app.store)
	}

	themeStr := readRegistryString("ThemeMode")
	if strings.EqualFold(themeStr, "Dark") {
		app.isDarkMode = true
	}

	// Auto-migrate legacy profiles.json if found and registry is empty
	if len(app.store.Profiles) == 0 {
		legacyProfiles := filepath.Join(app.appDir, "profiles.json")
		if data, err := os.ReadFile(legacyProfiles); err == nil {
			_ = json.Unmarshal(data, &app.store)
			saveRegistrySettings()
			_ = os.Remove(legacyProfiles) // Clean up disk
		}
	}
}

func saveRegistrySettings() {
	data, err := json.Marshal(app.store)
	if err == nil {
		saveRegistryString("Profiles", string(data))
		saveRegistryString("DefaultID", app.store.DefaultID)
	}
}

func saveRegistryString(valName, valData string) {
	subKey := strPtr(RegistryAppKey)
	var hKey uintptr
	var disp uint32

	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0,
		KEY_ALL_ACCESS,
		0,
		uintptr(unsafe.Pointer(&hKey)),
		uintptr(unsafe.Pointer(&disp)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	pVal := strPtr(valData)
	bytesLen := (len(valData) + 1) * 2
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr(valName))),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(pVal)),
		uintptr(bytesLen),
	)
}

func readRegistryString(valName string) string {
	subKey := strPtr(RegistryAppKey)
	var hKey uintptr

	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return ""
	}
	defer procRegCloseKey.Call(hKey)

	var valType uint32
	var dataLen uint32 = 65536
	buf := make([]uint16, 32768)
	r, _, _ := procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr(valName))),
		0,
		uintptr(unsafe.Pointer(&valType)),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(&dataLen)),
	)
	if r == 0 {
		return syscall.UTF16ToString(buf)
	}
	return ""
}

func getDefaultProfile() *Profile {
	if len(app.store.Profiles) == 0 {
		return nil
	}
	for i := range app.store.Profiles {
		if app.store.Profiles[i].IsDefault || app.store.Profiles[i].ID == app.store.DefaultID {
			return &app.store.Profiles[i]
		}
	}
	return &app.store.Profiles[0]
}

// Paste from Buffer with Duplicate Validation
func clearAndPasteKeyWithValidation() {
	r, _, _ := procIsClipboardFormatAvail.Call(CF_UNICODETEXT)
	if r == 0 {
		showBalloonTip("GIN-VPN: Clipboard Empty", "No text found in clipboard buffer.", NIIF_WARNING)
		return
	}
	r, _, _ = procOpenClipboard.Call(app.hWndMain)
	if r == 0 {
		return
	}
	defer procCloseClipboard.Call()

	hData, _, _ := procGetClipboardData.Call(CF_UNICODETEXT)
	if hData == 0 {
		return
	}

	pData, _, _ := procGlobalLock.Call(hData)
	if pData == 0 {
		return
	}
	defer procGlobalUnlock.Call(hData)

	rawStr := syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(pData))[:])
	rawStr = strings.TrimSpace(rawStr)

	if rawStr == "" {
		showBalloonTip("GIN-VPN: Empty Key", "Clipboard content is empty.", NIIF_WARNING)
		return
	}

	cfg, err := parseVLESSLink(rawStr)
	if err != nil {
		setControlText(app.hEditKey, rawStr)
		showBalloonTip("GIN-VPN: Invalid Key Syntax", "Failed to parse VLESS URI: "+err.Error(), NIIF_ERROR)
		logEvent("[WARN] Invalid VLESS key in clipboard: " + err.Error())
		return
	}

	// 1. Check for Duplicate Profile
	exists := false
	existingName := ""
	for _, p := range app.store.Profiles {
		if p.ID == cfg.ID || (p.Server == cfg.Server && p.Port == cfg.Port) || p.Name == cfg.ProfileName {
			exists = true
			existingName = p.Name
			break
		}
	}

	setControlText(app.hEditKey, rawStr)
	setControlText(app.hLblNodeName, fmt.Sprintf("Active Node: 📌 %s", cfg.ProfileName))

	if exists {
		// Display Yellow Warning for Duplicate
		warnMsg := fmt.Sprintf("⚠️ Profile '%s' (%s:%d) is already added in your list.", existingName, cfg.Server, cfg.Port)
		logEvent("[WARN] " + warnMsg)
		showBalloonTip("⚠️ Profile Already Exists", warnMsg, NIIF_WARNING)
		return
	}

	// 2. Add New Profile & Save to Registry
	newProfile := Profile{
		ID:        cfg.ID,
		Name:      cfg.ProfileName,
		Link:      rawStr,
		Server:    cfg.Server,
		Port:      cfg.Port,
		IsDefault: len(app.store.Profiles) == 0,
	}
	if newProfile.IsDefault {
		app.store.DefaultID = newProfile.ID
	}
	app.store.Profiles = append(app.store.Profiles, newProfile)

	saveRegistrySettings()
	populateProfileList()

	successMsg := fmt.Sprintf("Added Server: %s (%s:%d)", cfg.ProfileName, cfg.Server, cfg.Port)
	logEvent("[ADD] " + successMsg)
	showBalloonTip("✅ Server Added", successMsg, NIIF_INFO)
}

func saveKeyToProfiles() {
	k := strings.TrimSpace(getControlText(app.hEditKey))
	if k == "" {
		showBalloonTip("GIN-VPN: Key Empty", "Please paste or enter a valid VLESS key.", NIIF_WARNING)
		return
	}

	cfg, err := parseVLESSLink(k)
	if err != nil {
		showBalloonTip("GIN-VPN: Invalid Key", "Failed to parse VLESS link syntax: "+err.Error(), NIIF_ERROR)
		return
	}

	setControlText(app.hLblNodeName, fmt.Sprintf("Active Node: 📌 %s", cfg.ProfileName))

	found := false
	for i := range app.store.Profiles {
		if app.store.Profiles[i].ID == cfg.ID || app.store.Profiles[i].Name == cfg.ProfileName {
			app.store.Profiles[i].Link = k
			app.store.Profiles[i].Server = cfg.Server
			app.store.Profiles[i].Port = cfg.Port
			found = true
			break
		}
	}

	if !found {
		p := Profile{
			ID:        cfg.ID,
			Name:      cfg.ProfileName,
			Link:      k,
			Server:    cfg.Server,
			Port:      cfg.Port,
			IsDefault: len(app.store.Profiles) == 0,
		}
		if p.IsDefault {
			app.store.DefaultID = p.ID
		}
		app.store.Profiles = append(app.store.Profiles, p)
	}

	saveRegistrySettings()
	populateProfileList()

	logEvent(fmt.Sprintf("[KEY] Saved profile '%s' (%s:%d) to registry", cfg.ProfileName, cfg.Server, cfg.Port))
	showBalloonTip("GIN-VPN: Key Saved", fmt.Sprintf("Profile '%s' saved to registry!", cfg.ProfileName), NIIF_INFO)
}

func getSelectedProfileIndex() int {
	res, _, _ := procSendMessageW.Call(app.hListProfiles, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	return int(int32(res))
}

func connectSelectedProfile() {
	idx := getSelectedProfileIndex()
	if idx < 0 || idx >= len(app.store.Profiles) {
		showBalloonTip("GIN-VPN", "Please select a profile from the list to connect.", NIIF_WARNING)
		return
	}
	p := app.store.Profiles[idx]
	setControlText(app.hEditKey, p.Link)
	setControlText(app.hLblNodeName, fmt.Sprintf("Active Node: 📌 %s", p.Name))
	startVPNWithProfile(p)
}

func setDefaultSelectedProfile() {
	idx := getSelectedProfileIndex()
	if idx < 0 || idx >= len(app.store.Profiles) {
		return
	}
	for i := range app.store.Profiles {
		app.store.Profiles[i].IsDefault = (i == idx)
	}
	app.store.DefaultID = app.store.Profiles[idx].ID
	saveRegistrySettings()
	populateProfileList()
	logEvent(fmt.Sprintf("[PROFILE] Default profile set to: %s", app.store.Profiles[idx].Name))
	showBalloonTip("GIN-VPN", fmt.Sprintf("Default profile set to '%s'", app.store.Profiles[idx].Name), NIIF_INFO)
}

func deleteSelectedProfile() {
	idx := getSelectedProfileIndex()
	if idx < 0 || idx >= len(app.store.Profiles) {
		return
	}
	deletedName := app.store.Profiles[idx].Name
	app.store.Profiles = append(app.store.Profiles[:idx], app.store.Profiles[idx+1:]...)
	if len(app.store.Profiles) > 0 && (app.store.DefaultID == "" || idx == 0) {
		app.store.Profiles[0].IsDefault = true
		app.store.DefaultID = app.store.Profiles[0].ID
	}
	saveRegistrySettings()
	populateProfileList()
	logEvent(fmt.Sprintf("[PROFILE] Deleted profile: %s", deletedName))
}

// VPN Connection Lifecycle
func toggleVPN() {
	if app.state == StateConnected || app.state == StateConnecting {
		stopVPN(false)
	} else {
		keyText := strings.TrimSpace(getControlText(app.hEditKey))
		if keyText == "" {
			def := getDefaultProfile()
			if def != nil {
				keyText = def.Link
				setControlText(app.hEditKey, keyText)
				setControlText(app.hLblNodeName, fmt.Sprintf("Active Node: 📌 %s", def.Name))
			}
		}

		if keyText == "" {
			logEvent("[ERROR] No VLESS key available to connect.")
			showBalloonTip("GIN-VPN: No Key", "Please paste or select a VLESS key to connect.", NIIF_WARNING)
			return
		}

		cfg, err := parseVLESSLink(keyText)
		if err != nil {
			logEvent("[ERROR] Invalid VLESS key: " + err.Error())
			showBalloonTip("GIN-VPN: Invalid Key", err.Error(), NIIF_ERROR)
			return
		}

		p := Profile{
			ID:     cfg.ID,
			Name:   cfg.ProfileName,
			Link:   keyText,
			Server: cfg.Server,
			Port:   cfg.Port,
		}
		startVPNWithProfile(p)
	}
}

func startVPNWithProfile(p Profile) {
	app.mu.Lock()
	defer app.mu.Unlock()

	// Ensure Xray core is ready (silent auto-fetch if missing)
	if app.xrayPath == "" {
		app.xrayPath = locateXrayCore(app.appDir)
	}
	if app.xrayPath == "" {
		logEvent("[CORE] Core binary missing. Auto-downloading Xray Core silently...")
		go downloadXrayCoreSilent(func() {
			startVPNWithProfile(p)
		})
		setState(StateConnecting, "Fetching Xray Core silently...")
		return
	}

	cfg, err := parseVLESSLink(p.Link)
	if err != nil {
		logEvent("[ERROR] Invalid VLESS key: " + err.Error())
		setState(StateError, "Error: "+err.Error())
		return
	}

	app.activeProfile = p

	// Write runtime config to secure temp path
	configContent := generateXrayJSON(cfg)
	_ = os.WriteFile(app.configFile, []byte(configContent), 0600)

	killXrayProcesses()

	setState(StateConnecting, "Connecting to "+p.Name+"...")
	logEvent(fmt.Sprintf("[START] Launching Xray Core for %s (%s:%d)...", p.Name, p.Server, p.Port))

	cmd := exec.Command(app.xrayPath, "run", "-c", app.configFile)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		CreationFlags: CREATE_NO_WINDOW,
	}

	err = cmd.Start()
	if err != nil {
		logEvent("[ERROR] Failed to start xray.exe: " + err.Error())
		setState(StateError, "Failed to launch xray.exe")
		return
	}
	app.cmdXray = cmd

	setWindowsProxy(true, "127.0.0.1:10809", "localhost;127.*;10.*;192.168.*;<local>")
	logEvent("[PROXY] System proxy activated (127.0.0.1:10809).")

	go verifyConnection()
}

func stopVPN(silent bool) {
	app.mu.Lock()
	defer app.mu.Unlock()

	setWindowsProxy(false, "", "")
	logEvent("[PROXY] System proxy disabled. Direct connection restored.")

	if app.cmdXray != nil && app.cmdXray.Process != nil {
		_ = app.cmdXray.Process.Kill()
		app.cmdXray = nil
	}
	killXrayProcesses()

	// Wipe temporary config file for security
	_ = os.Remove(app.configFile)

	setState(StateDisconnected, "Proxy inactive. Direct Internet connection.")
	logEvent("[STOP] VPN Disconnected.")

	if !silent {
		showBalloonTip("GIN-VPN Disconnected", "VPN disconnected. System proxy has been reset.", NIIF_INFO)
	}
}

func verifyConnection() {
	time.Sleep(1200 * time.Millisecond)

	proxyURL, _ := url.Parse("http://127.0.0.1:10809")
	client := &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyURL(proxyURL),
		},
		Timeout: 5 * time.Second,
	}

	attempts := 0
	maxAttempts := 8
	var vpnIP, vpnCode string

	for attempts < maxAttempts {
		if app.state != StateConnecting {
			return
		}
		attempts++

		resp, err := client.Get("http://ip-api.com/line/?fields=query,countryCode")
		if err == nil && resp.StatusCode == 200 {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			lines := strings.Split(strings.TrimSpace(string(body)), "\n")
			for _, l := range lines {
				t := strings.TrimSpace(l)
				if net.ParseIP(t) != nil {
					vpnIP = t
				} else if len(t) == 2 {
					vpnCode = strings.ToUpper(t)
				}
			}
			if vpnIP != "" {
				break
			}
		}
		time.Sleep(1500 * time.Millisecond)
	}

	app.mu.Lock()
	defer app.mu.Unlock()

	if vpnIP != "" {
		app.vpnIP = vpnIP
		app.vpnCode = vpnCode
		app.connectTime = time.Now()
		setState(StateConnected, fmt.Sprintf("Connected via %s (%s)", vpnIP, vpnCode))
		logEvent(fmt.Sprintf("[OK] Tunnel verified! Protected IP: %s (%s)", vpnIP, vpnCode))
		showBalloonTip("GIN-VPN: Connected", fmt.Sprintf("VPN Active: %s (%s)\nNode: %s", vpnIP, vpnCode, app.activeProfile.Name), NIIF_INFO)

		procShowWindow.Call(app.hWndMain, SW_HIDE)

		go measureLatency(app.activeProfile.Server, app.activeProfile.Port)
	} else {
		setState(StateError, "Connection timeout: unable to reach server via proxy.")
		logEvent("[ERROR] Proxy verification failed. Check server address or Reality keys.")
		showBalloonTip("GIN-VPN: Timeout", "Could not reach server. Check network or key.", NIIF_ERROR)
	}
}

func measureLatency(server string, port int) {
	start := time.Now()
	conn, err := net.DialTimeout("tcp", net.JoinHostPort(server, strconv.Itoa(port)), 3*time.Second)
	if err == nil {
		conn.Close()
		rtt := int(time.Since(start).Milliseconds())
		app.mu.Lock()
		app.latencyMs = rtt
		setControlText(app.hLblLatency, fmt.Sprintf("Gateway Latency:  %d ms (RTT)", rtt))
		app.mu.Unlock()
		logEvent(fmt.Sprintf("[PING] Server RTT latency: %d ms", rtt))
	}
}

func resolveOriginalIP() {
	client := &http.Client{Timeout: 4 * time.Second}
	resp, err := client.Get("http://ip-api.com/line/?fields=query,countryCode")
	if err == nil && resp.StatusCode == 200 {
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		lines := strings.Split(strings.TrimSpace(string(body)), "\n")
		var ip, code string
		for _, l := range lines {
			t := strings.TrimSpace(l)
			if net.ParseIP(t) != nil {
				ip = t
			} else if len(t) == 2 {
				code = strings.ToUpper(t)
			}
		}
		if ip != "" {
			app.mu.Lock()
			app.origIP = ip
			app.origCode = code
			setControlText(app.hLblOrigIP, fmt.Sprintf("Original ISP IP:  %s (%s)", ip, code))
			app.mu.Unlock()
			logEvent(fmt.Sprintf("[IP] Original ISP detected: %s (%s)", ip, code))
		}
	}
}

func setState(s VPNState, desc string) {
	app.state = s
	app.stateMessage = desc

	badgeText := "⚪ DISCONNECTED"
	btnText := "▶ CONNECT VPN"

	switch s {
	case StateConnected:
		badgeText = "🟢 CONNECTED"
		btnText = "⏹ DISCONNECT VPN"
		updateTrayIcon(StateConnected, fmt.Sprintf("VPN: %s (%s) | Orig: %s", app.vpnIP, app.vpnCode, app.origIP))
	case StateConnecting:
		badgeText = "🟠 CONNECTING..."
		btnText = "⏳ CANCEL"
		updateTrayIcon(StateConnecting, "GIN-VPN: Connecting...")
	case StateError:
		badgeText = "🔴 ERROR"
		btnText = "▶ RETRY CONNECT"
		updateTrayIcon(StateError, "GIN-VPN: Error connecting")
	default:
		badgeText = "⚪ DISCONNECTED"
		btnText = "▶ CONNECT VPN"
		updateTrayIcon(StateDisconnected, "GIN-VPN: Disconnected")
	}

	setControlText(app.hStatusBadge, badgeText)
	setControlText(app.hStatusDesc, desc)
	setControlText(app.hBtnConnect, btnText)

	if s == StateConnected {
		setControlText(app.hLblVPNIP, fmt.Sprintf("Protected VPN IP: %s (%s)", app.vpnIP, app.vpnCode))
	} else if s == StateDisconnected {
		setControlText(app.hLblVPNIP, "Protected VPN IP: —")
		setControlText(app.hLblLatency, "Gateway Latency:  —")
		setControlText(app.hLblUptime, "Session Uptime:   00:00:00")
	}

	procInvalidateRect.Call(app.hWndMain, 0, 1)
}

func updateSessionTimer() {
	if app.state == StateConnected && !app.connectTime.IsZero() {
		dur := time.Since(app.connectTime)
		h := int(dur.Hours())
		m := int(dur.Minutes()) % 60
		s := int(dur.Seconds()) % 60
		setControlText(app.hLblUptime, fmt.Sprintf("Session Uptime:   %02d:%02d:%02d", h, m, s))
	}
}

// Windows System Proxy Manager
func setWindowsProxy(enable bool, proxyServer string, proxyOverride string) {
	subKey := strPtr(`Software\Microsoft\Windows\CurrentVersion\Internet Settings`)
	var hKey uintptr

	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_WRITE|KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valEnable := uint32(0)
	if enable {
		valEnable = 1
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr("ProxyEnable"))),
		0,
		REG_DWORD,
		uintptr(unsafe.Pointer(&valEnable)),
		4,
	)

	if enable && proxyServer != "" {
		pServer := strPtr(proxyServer)
		bytesLen := (len(proxyServer) + 1) * 2
		procRegSetValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(strPtr("ProxyServer"))),
			0,
			REG_SZ,
			uintptr(unsafe.Pointer(pServer)),
			uintptr(bytesLen),
		)
	} else {
		procRegDeleteValueW.Call(hKey, uintptr(unsafe.Pointer(strPtr("ProxyServer"))))
	}

	if enable && proxyOverride != "" {
		pOverride := strPtr(proxyOverride)
		bytesLen := (len(proxyOverride) + 1) * 2
		procRegSetValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(strPtr("ProxyOverride"))),
			0,
			REG_SZ,
			uintptr(unsafe.Pointer(pOverride)),
			uintptr(bytesLen),
		)
	}

	syncLegacyConnSettings(enable, proxyServer, proxyOverride)

	procInternetSetOptionW.Call(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
	procInternetSetOptionW.Call(0, INTERNET_OPTION_REFRESH, 0, 0)
}

func syncLegacyConnSettings(enable bool, proxyServer string, proxyOverride string) {
	subKey := strPtr(`Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections`)
	var hKey uintptr
	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_WRITE|KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	names := []string{"DefaultConnectionSettings", "SavedLegacySettings"}
	for _, n := range names {
		var valType uint32
		var dataLen uint32 = 1024
		buf := make([]byte, dataLen)
		r, _, _ := procRegQueryValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(strPtr(n))),
			0,
			uintptr(unsafe.Pointer(&valType)),
			uintptr(unsafe.Pointer(&buf[0])),
			uintptr(unsafe.Pointer(&dataLen)),
		)
		if r == 0 && dataLen >= 9 {
			if enable {
				buf[8] = 0x03
			} else {
				buf[8] = 0x01
			}
			procRegSetValueExW.Call(
				hKey,
				uintptr(unsafe.Pointer(strPtr(n))),
				0,
				REG_BINARY,
				uintptr(unsafe.Pointer(&buf[0])),
				uintptr(dataLen),
			)
		}
	}
}

func killXrayProcesses() {
	_ = exec.Command("taskkill", "/F", "/IM", "xray.exe").Run()
	_ = exec.Command("taskkill", "/F", "/IM", "xray64.exe").Run()
}

// Installation Engine & Desktop Shortcut
func installApplication() {
	logEvent("[INSTALL] Starting installation to: " + DefaultInstallDir)
	showBalloonTip("GIN-VPN Installation", "Installing GIN-VPN to Program Files...", NIIF_INFO)

	err := os.MkdirAll(DefaultInstallDir, 0777)
	if err != nil {
		logEvent("[ERROR] Could not create installation directory: " + err.Error())
		showBalloonTip("GIN-VPN Install Failed", "Failed to create folder: "+err.Error(), NIIF_ERROR)
		return
	}

	_ = exec.Command("icacls", DefaultInstallDir, "/grant", "*S-1-5-32-545:(OI)(CI)F", "/T", "/C", "/Q").Run()
	_ = exec.Command("icacls", DefaultInstallDir, "/grant", "Users:(OI)(CI)F", "/T", "/C", "/Q").Run()

	targetExe := filepath.Join(DefaultInstallDir, "GIN-VPN.exe")
	if !strings.EqualFold(filepath.Clean(app.exePath), filepath.Clean(targetExe)) {
		err = copyFile(app.exePath, targetExe)
		if err != nil {
			logEvent("[ERROR] Failed to copy executable: " + err.Error())
			showBalloonTip("GIN-VPN Install Failed", "Failed to copy GIN-VPN.exe: "+err.Error(), NIIF_ERROR)
			return
		}
	}

	migrateFiles := []string{"xray.exe", "GIN-VPN.ico"}
	for _, f := range migrateFiles {
		src := filepath.Join(app.appDir, f)
		dst := filepath.Join(DefaultInstallDir, f)
		if _, err := os.Stat(src); err == nil && !strings.EqualFold(filepath.Clean(src), filepath.Clean(dst)) {
			_ = copyFile(src, dst)
		}
	}

	psScript := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell

$desktopPath = [Environment]::GetFolderPath('Desktop')
$s1 = $w.CreateShortcut("$desktopPath\GIN-VPN.lnk")
$s1.TargetPath = '%s'
$s1.WorkingDirectory = '%s'
$s1.Description = 'GIN-VPN by VladiMIR+AI'
$s1.Save()

$pubDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
if (Test-Path $pubDesktop) {
    try {
        $s2 = $w.CreateShortcut("$pubDesktop\GIN-VPN.lnk")
        $s2.TargetPath = '%s'
        $s2.WorkingDirectory = '%s'
        $s2.Description = 'GIN-VPN by VladiMIR+AI'
        $s2.Save()
    } catch {}
}

$programsPath = [Environment]::GetFolderPath('Programs')
$s3 = $w.CreateShortcut("$programsPath\GIN-VPN.lnk")
$s3.TargetPath = '%s'
$s3.WorkingDirectory = '%s'
$s3.Description = 'GIN-VPN by VladiMIR+AI'
$s3.Save()
`, targetExe, DefaultInstallDir, targetExe, DefaultInstallDir, targetExe, DefaultInstallDir)

	_ = exec.Command("powershell", "-NoProfile", "-NonInteractive", "-Command", psScript).Run()

	app.isInstalled = true
	setControlText(app.hBtnInstall, "✅ Installed (Repair)")

	logEvent("[SUCCESS] GIN-VPN installed successfully to: " + DefaultInstallDir)
	logEvent("[SHORTCUT] Desktop & Start Menu shortcuts created!")
	showBalloonTip("GIN-VPN Installed", "Installation complete! Desktop shortcut created.", NIIF_INFO)
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

// Helper Utilities
func getControlText(hWnd uintptr) string {
	length, _, _ := procGetWindowTextLengthW.Call(hWnd)
	if length == 0 {
		return ""
	}
	buf := make([]uint16, length+1)
	procGetWindowTextW.Call(hWnd, uintptr(unsafe.Pointer(&buf[0])), uintptr(length+1))
	return syscall.UTF16ToString(buf)
}

func setControlText(hWnd uintptr, text string) {
	procSetWindowTextW.Call(hWnd, uintptr(unsafe.Pointer(strPtr(text))))
}

func logEvent(msg string) {
	ts := time.Now().Format("2006-01-02 15:04:05")
	entry := fmt.Sprintf("[%s] %s\r\n", ts, msg)

	current := getControlText(app.hEditLog)
	if len(current) > 25000 {
		current = current[len(current)-20000:]
	}
	setControlText(app.hEditLog, current+entry)

	user32.NewProc("SendMessageW").Call(app.hEditLog, 0x0115, 7, 0)

	f, err := os.OpenFile(app.logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		_, _ = f.WriteString(entry)
		f.Close()
	}
}

func clearLogView() {
	setControlText(app.hEditLog, "")
	logEvent("[LOG] Log view cleared.")
}

func downloadXrayCoreSilent(onSuccess func()) {
	targetPath := filepath.Join(os.TempDir(), "xray.exe")
	urls := []string{DefaultCoreURL, FallbackCoreURL}
	var resp *http.Response
	var err error

	for _, u := range urls {
		client := &http.Client{Timeout: 30 * time.Second}
		resp, err = client.Get(u)
		if err == nil && resp.StatusCode == 200 {
			break
		}
	}

	if resp == nil || resp.StatusCode != 200 {
		logEvent("[ERROR] Failed to download Xray Core.")
		return
	}
	defer resp.Body.Close()

	out, err := os.Create(targetPath)
	if err != nil {
		return
	}
	_, err = io.Copy(out, resp.Body)
	out.Close()
	if err != nil {
		return
	}

	app.xrayPath = targetPath
	logEvent("[SUCCESS] Xray Core ready in background: " + targetPath)
	if onSuccess != nil {
		onSuccess()
	}
}

func openBrowser(urlStr string) {
	procShellExecuteW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("open"))),
		uintptr(unsafe.Pointer(strPtr(urlStr))),
		0, 0, SW_SHOWNORMAL,
	)
}

func openNotepad(filePath string) {
	_ = exec.Command("notepad.exe", filePath).Start()
}

func pruneLogs(filePath string) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return
	}
	lines := strings.Split(string(data), "\n")
	if len(lines) > 2000 {
		lines = lines[len(lines)-1500:]
		_ = os.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
	}
}
