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

// App Information
const (
	AppName       = "GIN-VPN"
	AppVersion   = "v001"
	AppTitle     = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client"
	AppAuthor    = "VladiMIR+AI (Vladimir Bulantsev - GinCz)"
	DefaultCoreURL = "https://prodvig-saita.ru/vpn/xray64.exe"
	FallbackCoreURL = "http://prodvig-saita.ru/vpn/xray64.exe"
	CheckIPURL    = "http://prodvig-saita.ru/ip/"
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

	procRegisterClassExW     = user32.NewProc("RegisterClassExW")
	procCreateWindowExW      = user32.NewProc("CreateWindowExW")
	procDefWindowProcW       = user32.NewProc("DefWindowProcW")
	procDestroyWindow        = user32.NewProc("DestroyWindow")
	procPostQuitMessage      = user32.NewProc("PostQuitMessage")
	procShowWindow           = user32.NewProc("ShowWindow")
	procUpdateWindow         = user32.NewProc("UpdateWindow")
	procGetMessageW          = user32.NewProc("GetMessageW")
	procTranslateMessage     = user32.NewProc("TranslateMessage")
	procDispatchMessageW     = user32.NewProc("DispatchMessageW")
	procSendMessageW         = user32.NewProc("SendMessageW")
	procSetWindowTextW       = user32.NewProc("SetWindowTextW")
	procGetWindowTextW       = user32.NewProc("GetWindowTextW")
	procGetWindowTextLengthW = user32.NewProc("GetWindowTextLengthW")
	procEnableWindow         = user32.NewProc("EnableWindow")
	procLoadIconW            = user32.NewProc("LoadIconW")
	procLoadCursorW          = user32.NewProc("LoadCursorW")
	procSetTimer             = user32.NewProc("SetTimer")
	procKillTimer            = user32.NewProc("KillTimer")
	procInvalidateRect       = user32.NewProc("InvalidateRect")
	procBeginPaint           = user32.NewProc("BeginPaint")
	procEndPaint             = user32.NewProc("EndPaint")
	procCreatePopupMenu      = user32.NewProc("CreatePopupMenu")
	procAppendMenuW          = user32.NewProc("AppendMenuW")
	procTrackPopupMenu       = user32.NewProc("TrackPopupMenu")
	procDestroyMenu          = user32.NewProc("DestroyMenu")
	procGetCursorPos         = user32.NewProc("GetCursorPos")
	procSetForegroundWindow  = user32.NewProc("SetForegroundWindow")
	procOpenClipboard        = user32.NewProc("OpenClipboard")
	procCloseClipboard       = user32.NewProc("CloseClipboard")
	procEmptyClipboard       = user32.NewProc("EmptyClipboard")
	procSetClipboardData     = user32.NewProc("SetClipboardData")
	procGetClipboardData     = user32.NewProc("GetClipboardData")
	procIsClipboardFormatAvail = user32.NewProc("IsClipboardFormatAvailable")
	procCreateIconIndirect   = user32.NewProc("CreateIconIndirect")
	procDestroyIcon          = user32.NewProc("DestroyIcon")

	procGetStockObject       = gdi32.NewProc("GetStockObject")
	procCreateFontW          = gdi32.NewProc("CreateFontW")
	procSetBkMode            = gdi32.NewProc("SetBkMode")
	procSetTextColor         = gdi32.NewProc("SetTextColor")
	procSetBkColor           = gdi32.NewProc("SetBkColor")
	procCreatePen            = gdi32.NewProc("CreatePen")
	procCreateSolidBrush     = gdi32.NewProc("CreateSolidBrush")
	procSelectObject         = gdi32.NewProc("SelectObject")
	procDeleteObject         = gdi32.NewProc("DeleteObject")
	procCreateCompatibleDC   = gdi32.NewProc("CreateCompatibleDC")
	procCreateBitmap         = gdi32.NewProc("CreateBitmap")
	procDeleteDC             = gdi32.NewProc("DeleteDC")
	procPolygon              = gdi32.NewProc("Polygon")
	procRectangle            = gdi32.NewProc("Rectangle")
	procRoundRect            = gdi32.NewProc("RoundRect")
	procEllipse              = gdi32.NewProc("Ellipse")

	procGetModuleHandleW     = kernel32.NewProc("GetModuleHandleW")
	procGlobalAlloc          = kernel32.NewProc("GlobalAlloc")
	procGlobalLock           = kernel32.NewProc("GlobalLock")
	procGlobalUnlock         = kernel32.NewProc("GlobalUnlock")
	procInitCommonControlsEx = comctl32.NewProc("InitCommonControlsEx")

	procShell_NotifyIconW    = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW        = shell32.NewProc("ShellExecuteW")

	procRegOpenKeyExW        = advapi32.NewProc("RegOpenKeyExW")
	procRegSetValueExW       = advapi32.NewProc("RegSetValueExW")
	procRegDeleteValueW      = advapi32.NewProc("RegDeleteValueW")
	procRegQueryValueExW     = advapi32.NewProc("RegQueryValueExW")
	procRegCloseKey          = advapi32.NewProc("RegCloseKey")

	procInternetSetOptionW   = wininet.NewProc("InternetSetOptionW")
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

	ES_AUTOHSCROLL      = 0x0080
	ES_AUTOVSCROLL      = 0x0040
	ES_MULTILINE        = 0x0004
	ES_READONLY         = 0x0800

	BS_PUSHBUTTON       = 0x0000
	BS_DEFPUSHBUTTON    = 0x0001
	BS_OWNERDRAW        = 0x000B

	SS_NOTIFY           = 0x0100
	SS_CENTER           = 0x0001
	SS_LEFT             = 0x0000
	SS_RIGHT            = 0x0002

	WM_CREATE           = 0x0001
	WM_DESTROY          = 0x0002
	WM_PAINT            = 0x000F
	WM_CLOSE            = 0x0010
	WM_COMMAND          = 0x0111
	WM_TIMER            = 0x0113
	WM_SYSCOMMAND       = 0x0112
	WM_CTLCOLORSTATIC   = 0x0138
	WM_CTLCOLOREDIT     = 0x0133
	WM_CTLCOLORBTN      = 0x0135
	WM_SETFONT          = 0x0030
	WM_SETICON          = 0x0080
	WM_RBUTTONUP        = 0x0205
	WM_LBUTTONDBLCLK    = 0x0203

	SC_MINIMIZE         = 0xF020

	NIM_ADD             = 0x00000000
	NIM_MODIFY          = 0x00000001
	NIM_DELETE          = 0x00000002
	NIF_MESSAGE         = 0x00000001
	NIF_ICON            = 0x00000002
	NIF_TIP             = 0x00000004
	NIF_INFO            = 0x00000010

	NIIF_NONE           = 0x00000000
	NIIF_INFO           = 0x00000001
	NIIF_WARNING        = 0x00000002
	NIIF_ERROR          = 0x00000003

	MF_STRING           = 0x0000
	MF_SEPARATOR        = 0x0800
	TPM_RIGHTBUTTON     = 0x0002

	CF_UNICODETEXT      = 13
	GMEM_MOVEABLE       = 0x0002

	HKEY_CURRENT_USER   = 0x80000001
	KEY_READ            = 0x20019
	KEY_WRITE           = 0x20006
	KEY_ALL_ACCESS      = 0xF003F
	REG_DWORD           = 4
	REG_SZ              = 1
	REG_BINARY          = 3

	INTERNET_OPTION_SETTINGS_CHANGED = 39
	INTERNET_OPTION_REFRESH          = 37

	WM_USER             = 0x0400
	WM_TRAYICON         = WM_USER + 1
	WM_APP_UPDATE_STATE = WM_USER + 10
	WM_APP_APPEND_LOG   = WM_USER + 11

	SW_HIDE             = 0
	SW_SHOWNORMAL       = 1
	SW_RESTORE          = 9

	CREATE_NO_WINDOW    = 0x08000000
)

// UI Control IDs
const (
	ID_BTN_CONNECT    = 1001
	ID_BTN_PASTE      = 1002
	ID_BTN_EDIT_KEY   = 1003
	ID_BTN_CHECK_IP   = 1004
	ID_BTN_VIEW_LOG   = 1005
	ID_BTN_DOWNLOAD   = 1006
	ID_BTN_CLEAR_LOG  = 1007
	ID_EDIT_KEY       = 1010
	ID_EDIT_LOG       = 1011

	// Tray Menu IDs
	ID_TRAY_RESTORE   = 2001
	ID_TRAY_CONNECT   = 2002
	ID_TRAY_DISCONN   = 2003
	ID_TRAY_CHECK_IP  = 2004
	ID_TRAY_EDIT_KEY  = 2005
	ID_TRAY_VIEW_LOG  = 2006
	ID_TRAY_EXIT      = 2007
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

// Global Application Context
type AppContext struct {
	mu           sync.Mutex
	hWndMain     uintptr
	hFontNormal  uintptr
	hFontBold    uintptr
	hFontTitle   uintptr
	hFontMono    uintptr
	hBrushBg     uintptr
	hBrushCard   uintptr
	hBrushEdit   uintptr

	// Dynamic Tray Icons
	hIconApp     uintptr
	hIconGreen   uintptr
	hIconOrange  uintptr
	hIconRed     uintptr
	hIconGray    uintptr

	// Controls
	hStatusBadge  uintptr
	hStatusDesc   uintptr
	hBtnConnect   uintptr
	hEditKey      uintptr
	hLblServer    uintptr
	hLblOrigIP    uintptr
	hLblVPNIP     uintptr
	hLblLatency   uintptr
	hLblUptime    uintptr
	hEditLog      uintptr

	// State
	state         VPNState
	stateMessage  string
	profileName   string
	serverAddr    string
	serverPort    int
	origIP        string
	origCode      string
	vpnIP         string
	vpnCode       string
	latencyMs     int
	connectTime   time.Time

	// Files
	appDir        string
	linkFile      string
	configFile    string
	logFile       string
	xrayPath      string

	// Process
	cmdXray       *exec.Cmd
	trayData      NOTIFYICONDATAW
	trayInstalled bool
	isExiting     bool
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
	// Initialize paths
	exePath, err := os.Executable()
	if err == nil {
		app.appDir = filepath.Dir(exePath)
	} else {
		app.appDir = "."
	}

	app.linkFile = filepath.Join(app.appDir, "link.txt")
	app.configFile = filepath.Join(app.appDir, "config.json")
	app.logFile = filepath.Join(app.appDir, "vpn.log")

	// If link.txt not in appDir, also check standard C:\XRAY_VPN
	if _, err := os.Stat(app.linkFile); os.IsNotExist(err) {
		fallbackLink := `C:\XRAY_VPN\link.txt`
		if _, err2 := os.Stat(fallbackLink); err2 == nil {
			app.linkFile = fallbackLink
		}
	}

	// Locate xray.exe
	app.xrayPath = locateXrayCore(app.appDir)

	// Clean up old log files (>30 days)
	pruneLogs(app.logFile)

	// Initialize Common Controls
	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x00000008 | 0x00000004 | 0x00000001
	procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))

	hInstance, _, _ := procGetModuleHandleW.Call(0)

	// Register Window Class
	className := "GIN_VPN_MAIN_WINDOW"
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.Style = 0x0002 | 0x0001 // CS_HREDRAW | CS_VREDRAW
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HCursor, _, _ = procLoadCursorW.Call(0, 32512) // IDC_ARROW
	wc.LpszClassName = strPtr(className)

	// Load Application Icon
	app.hIconApp, _, _ = procLoadIconW.Call(hInstance, 1)
	if app.hIconApp == 0 {
		app.hIconApp, _, _ = procLoadIconW.Call(0, 32512)
	}
	wc.HIcon = app.hIconApp
	wc.HIconSm = app.hIconApp

	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	// Create Dark Mode Brushes & Fonts
	app.hBrushBg, _, _ = procCreateSolidBrush.Call(0x00201B18)   // #181B20 (BGR)
	app.hBrushCard, _, _ = procCreateSolidBrush.Call(0x002E2722) // #22272E (BGR)
	app.hBrushEdit, _, _ = procCreateSolidBrush.Call(0x001B1612) // #12161B (BGR)

	app.hFontNormal = createFont("Segoe UI", 15, 400)
	app.hFontBold = createFont("Segoe UI", 15, 700)
	app.hFontTitle = createFont("Segoe UI", 20, 700)
	app.hFontMono = createFont("Consolas", 14, 400)

	// Create Dynamic Shield Icons (Green, Orange, Red, Gray)
	app.hIconGreen = createShieldHIcon(0x0032CD00, 0x005FF541)  // #00CD32 (BGR)
	app.hIconOrange = createShieldHIcon(0x000096F0, 0x003CCDFF) // #F09600 (BGR)
	app.hIconRed = createShieldHIcon(0x001919E1, 0x005F5FFF)    // #E11919 (BGR)
	app.hIconGray = createShieldHIcon(0x00787878, 0x00A0A0A0)   // #787878 (BGR)

	// Create Main Window (640x580, Centered)
	screenWidth := getSystemMetrics(0)
	screenHeight := getSystemMetrics(1)
	winWidth := int32(650)
	winHeight := int32(590)
	posX := (screenWidth - winWidth) / 2
	posY := (screenHeight - winHeight) / 2

	hWnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr(className))),
		uintptr(unsafe.Pointer(strPtr(AppTitle+" ["+AppVersion+"]"))),
		WS_OVERLAPPEDWINDOW&^0x00040000, // Non-resizable
		uintptr(posX), uintptr(posY),
		uintptr(winWidth), uintptr(winHeight),
		0, 0, hInstance, 0,
	)

	app.hWndMain = hWnd

	procShowWindow.Call(hWnd, SW_SHOWNORMAL)
	procUpdateWindow.Call(hWnd)

	// Main Message Loop
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

		// 1. Header Title Label
		createStatic(hWnd, hInstance, "🛡️ GIN-VPN by VladiMIR+AI", 20, 16, 380, 32, app.hFontTitle)

		// 2. Status Badge Button / Label
		app.hStatusBadge = createStatic(hWnd, hInstance, "⚪ DISCONNECTED", 430, 16, 185, 30, app.hFontBold)
		app.hStatusDesc = createStatic(hWnd, hInstance, "Proxy inactive. Direct Internet connection.", 20, 52, 595, 20, app.hFontNormal)

		// 3. VLESS Key Group Panel
		createStatic(hWnd, hInstance, "VLESS Reality Key / Subscription Link (link.txt):", 20, 80, 420, 20, app.hFontBold)
		createButton(hWnd, hInstance, "📋 Paste Key", ID_BTN_PASTE, 450, 76, 95, 24, app.hFontNormal)
		createButton(hWnd, hInstance, "💾 Save", ID_BTN_EDIT_KEY, 550, 76, 65, 24, app.hFontNormal)

		app.hEditKey = createEdit(hWnd, hInstance, "", ID_EDIT_KEY, 20, 104, 595, 48, app.hFontMono, true)

		// 4. Large Action Button: Connect / Disconnect
		app.hBtnConnect = createButton(hWnd, hInstance, "▶ CONNECT VPN", ID_BTN_CONNECT, 20, 162, 595, 42, app.hFontBold)

		// 5. Diagnostics & Node Information Dashboard (Card)
		createStatic(hWnd, hInstance, "Connection Diagnostics & IP Routing:", 20, 215, 400, 20, app.hFontBold)

		app.hLblServer = createStatic(hWnd, hInstance, "Node / Profile:   — (Not connected)", 30, 240, 575, 20, app.hFontNormal)
		app.hLblOrigIP = createStatic(hWnd, hInstance, "Original ISP IP:  Detecting...", 30, 264, 280, 20, app.hFontNormal)
		app.hLblVPNIP  = createStatic(hWnd, hInstance, "Protected VPN IP: —", 320, 264, 285, 20, app.hFontNormal)
		app.hLblLatency = createStatic(hWnd, hInstance, "Gateway Latency:  —", 30, 288, 280, 20, app.hFontNormal)
		app.hLblUptime  = createStatic(hWnd, hInstance, "Session Uptime:   00:00:00", 320, 288, 285, 20, app.hFontNormal)

		// 6. Action Toolbar Buttons
		createButton(hWnd, hInstance, "🌐 Check IP (Browser)", ID_BTN_CHECK_IP, 20, 318, 142, 28, app.hFontNormal)
		createButton(hWnd, hInstance, "📜 Open vpn.log", ID_BTN_VIEW_LOG, 170, 318, 135, 28, app.hFontNormal)
		createButton(hWnd, hInstance, "📥 Download Core", ID_BTN_DOWNLOAD, 313, 318, 142, 28, app.hFontNormal)
		createButton(hWnd, hInstance, "🧹 Clear Log", ID_BTN_CLEAR_LOG, 463, 318, 152, 28, app.hFontNormal)

		// 7. Live Activity & Diagnostics Log
		createStatic(hWnd, hInstance, "Real-Time Activity & Core Event Log:", 20, 355, 400, 20, app.hFontBold)
		app.hEditLog = createEdit(hWnd, hInstance, "", ID_EDIT_LOG, 20, 378, 595, 155, app.hFontMono, false)

		// Initialize Tray Icon
		initTrayIcon(hWnd)

		// Load Saved Key
		loadSavedKey()

		// Initial Log Message
		logEvent("[INIT] " + AppTitle + " " + AppVersion + " started.")
		if app.xrayPath != "" {
			logEvent("[CORE] Detected Xray binary: " + app.xrayPath)
		} else {
			logEvent("[WARN] Xray core not found! Click [📥 Download Core] to install.")
		}

		// Background fetch Original IP
		go resolveOriginalIP()

		// UI Refresh Timer (1 sec)
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
			showBalloonTip("GIN-VPN Active", "GIN-VPN is minimized to the system tray.", NIIF_INFO)
			return 0
		}

	case WM_COMMAND:
		cmdID := int(wParam & 0xFFFF)
		switch cmdID {
		case ID_BTN_CONNECT:
			toggleVPN()
		case ID_BTN_PASTE:
			pasteKeyFromClipboard()
		case ID_BTN_EDIT_KEY:
			saveKeyFromEdit()
		case ID_BTN_CHECK_IP, ID_TRAY_CHECK_IP:
			openBrowser(CheckIPURL)
		case ID_BTN_VIEW_LOG, ID_TRAY_VIEW_LOG:
			openNotepad(app.logFile)
		case ID_BTN_DOWNLOAD:
			go downloadXrayCore()
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
			openNotepad(app.linkFile)
		case ID_TRAY_EXIT:
			app.isExiting = true
			procDestroyWindow.Call(hWnd)
		}
		return 0

	case WM_CTLCOLORSTATIC, WM_CTLCOLOREDIT, WM_CTLCOLORBTN:
		hdc := wParam
		ctlHwnd := lParam

		// Status Badge Special Colors
		if ctlHwnd == app.hStatusBadge {
			procSetBkMode.Call(hdc, 1) // TRANSPARENT
			switch app.state {
			case StateConnected:
				procSetTextColor.Call(hdc, 0x0032CD00) // Neon Green
			case StateConnecting:
				procSetTextColor.Call(hdc, 0x0000B0FF) // Amber/Cyan
			case StateError:
				procSetTextColor.Call(hdc, 0x005252FF) // Red
			default:
				procSetTextColor.Call(hdc, 0x00A0A0A0) // Gray
			}
			return app.hBrushCard
		}

		if ctlHwnd == app.hEditKey || ctlHwnd == app.hEditLog {
			procSetBkColor.Call(hdc, 0x001B1612)
			procSetTextColor.Call(hdc, 0x00E0E6ED)
			return app.hBrushEdit
		}

		procSetBkMode.Call(hdc, 1) // TRANSPARENT
		procSetTextColor.Call(hdc, 0x00E0E6ED)
		return app.hBrushBg

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hWnd, uintptr(unsafe.Pointer(&ps)))

		// Fill Background
		var rc RECT
		rc.Left = ps.RcPaint.Left
		rc.Top = ps.RcPaint.Top
		rc.Right = ps.RcPaint.Right
		rc.Bottom = ps.RcPaint.Bottom
		hBrush, _, _ := procCreateSolidBrush.Call(0x00201B18)
		user32.NewProc("FillRect").Call(hdc, uintptr(unsafe.Pointer(&rc)), hBrush)
		procDeleteObject.Call(hBrush)

		// Draw Diagnostics Card Background
		hCardBrush, _, _ := procCreateSolidBrush.Call(0x002E2722)
		var cardRc RECT
		cardRc.Left = 20
		cardRc.Top = 232
		cardRc.Right = 615
		cardRc.Bottom = 310
		user32.NewProc("FillRect").Call(hdc, uintptr(unsafe.Pointer(&cardRc)), hCardBrush)
		procDeleteObject.Call(hCardBrush)

		procEndPaint.Call(hWnd, uintptr(unsafe.Pointer(&ps)))
		return 0

	case WM_CLOSE:
		// Clean exit: Reset proxy and kill core
		stopVPN(true)
		removeTrayIcon()
		procDestroyWindow.Call(hWnd)
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

// GUI Helper Functions
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

func createEdit(hParent, hInst uintptr, text string, id int, x, y, w, h int32, hFont uintptr, isKey bool) uintptr {
	style := uintptr(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_TABSTOP | ES_AUTOHSCROLL)
	if !isKey {
		style = uintptr(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY)
	}
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
	// Strict 63-char limit for Windows Shell compatibility
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

	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_CHECK_IP, uintptr(unsafe.Pointer(strPtr("🌐 Verify IP in Browser"))))
	procAppendMenuW.Call(hMenu, MF_STRING, ID_TRAY_EDIT_KEY, uintptr(unsafe.Pointer(strPtr("📝 Edit Key (link.txt)"))))
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

	// Draw Background transparent
	hBrushBlack, _, _ := procCreateSolidBrush.Call(0x00000000)
	var rc RECT
	rc.Right = 16
	rc.Bottom = 16
	user32.NewProc("FillRect").Call(hDC, uintptr(unsafe.Pointer(&rc)), hBrushBlack)
	procDeleteObject.Call(hBrushBlack)

	// Draw Shield Outer Border (Black)
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

	// Highlight / Core
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

// VLESS Link Parser & Config Generator
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
		return nil, fmt.Errorf("missing core VLESS parameters (id, server, or port)")
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

// VPN Connection Lifecycle
func toggleVPN() {
	if app.state == StateConnected || app.state == StateConnecting {
		stopVPN(false)
	} else {
		startVPN()
	}
}

func startVPN() {
	app.mu.Lock()
	defer app.mu.Unlock()

	// 1. Check Core Path
	if app.xrayPath == "" {
		app.xrayPath = locateXrayCore(app.appDir)
	}
	if app.xrayPath == "" {
		logEvent("[ERROR] xray.exe binary is missing. Please click [📥 Download Core].")
		showBalloonTip("GIN-VPN: Core Missing", "xray.exe is missing. Click Download Core to auto-install.", NIIF_ERROR)
		setState(StateError, "Error: xray.exe missing. Download core to connect.")
		return
	}

	// 2. Read and Validate Key
	keyText := getControlText(app.hEditKey)
	if strings.TrimSpace(keyText) == "" {
		// Read from link.txt
		data, err := os.ReadFile(app.linkFile)
		if err == nil {
			keyText = strings.TrimSpace(string(data))
			setControlText(app.hEditKey, keyText)
		}
	}

	if strings.TrimSpace(keyText) == "" {
		logEvent("[ERROR] No VLESS key provided. Paste your key in the box or link.txt.")
		showBalloonTip("GIN-VPN: No Key", "Please paste your VLESS key into the box or link.txt.", NIIF_WARNING)
		setState(StateError, "Error: VLESS key is empty.")
		return
	}

	cfg, err := parseVLESSLink(keyText)
	if err != nil {
		logEvent("[ERROR] Invalid VLESS key: " + err.Error())
		showBalloonTip("GIN-VPN: Invalid Key", "Failed to parse VLESS key syntax.", NIIF_ERROR)
		setState(StateError, "Error: "+err.Error())
		return
	}

	// Save parsed info
	app.profileName = cfg.ProfileName
	app.serverAddr = cfg.Server
	app.serverPort = cfg.Port

	// Save link.txt
	_ = os.WriteFile(app.linkFile, []byte(keyText), 0644)

	// 3. Generate config.json
	configContent := generateXrayJSON(cfg)
	err = os.WriteFile(app.configFile, []byte(configContent), 0644)
	if err != nil {
		logEvent("[ERROR] Could not write config.json: " + err.Error())
		setState(StateError, "Error writing config.json")
		return
	}

	logEvent(fmt.Sprintf("[CONFIG] Generated config for %s (%s:%d)", cfg.ProfileName, cfg.Server, cfg.Port))

	// 4. Terminate any previous Xray instances
	killXrayProcesses()

	setState(StateConnecting, "Connecting to "+cfg.ProfileName+"...")
	logEvent("[START] Launching Xray Core...")

	// 5. Launch xray.exe process hidden
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

	// 6. Set System Proxy
	setWindowsProxy(true, "127.0.0.1:10809", "localhost;127.*;10.*;192.168.*;<local>")
	logEvent("[PROXY] System proxy activated (127.0.0.1:10809).")

	// 7. Background Verification of Tunnel
	go verifyConnection()
}

func stopVPN(silent bool) {
	app.mu.Lock()
	defer app.mu.Unlock()

	// 1. Reset System Proxy
	setWindowsProxy(false, "", "")
	logEvent("[PROXY] System proxy disabled. Direct connection restored.")

	// 2. Kill Xray Core
	if app.cmdXray != nil && app.cmdXray.Process != nil {
		_ = app.cmdXray.Process.Kill()
		app.cmdXray = nil
	}
	killXrayProcesses()

	setState(StateDisconnected, "Proxy inactive. Direct Internet connection.")
	logEvent("[STOP] VPN Disconnected.")

	if !silent {
		showBalloonTip("GIN-VPN Disconnected", "VPN disconnected. System proxy has been reset.", NIIF_INFO)
	}
}

func verifyConnection() {
	// Wait a moment for Xray socket to bind
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
		showBalloonTip("GIN-VPN: Connected", fmt.Sprintf("VPN Active: %s (%s)\nProfile: %s", vpnIP, vpnCode, app.profileName), NIIF_INFO)

		// Test Ping / Latency
		go measureLatency(app.serverAddr)
	} else {
		setState(StateError, "Connection timeout: unable to reach server via proxy.")
		logEvent("[ERROR] Proxy verification failed. Check server address or Reality keys.")
		showBalloonTip("GIN-VPN: Connection Timeout", "Could not reach server through proxy. Check network or key.", NIIF_ERROR)
	}
}

func measureLatency(server string) {
	start := time.Now()
	conn, err := net.DialTimeout("tcp", net.JoinHostPort(server, strconv.Itoa(app.serverPort)), 3*time.Second)
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
		updateTrayIcon(StateConnecting, "GIN-VPN: Connecting to server...")
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
		setControlText(app.hLblServer, fmt.Sprintf("Node / Profile:   %s (%s:%d)", app.profileName, app.serverAddr, app.serverPort))
		setControlText(app.hLblVPNIP, fmt.Sprintf("Protected VPN IP: %s (%s)", app.vpnIP, app.vpnCode))
	} else if s == StateDisconnected {
		setControlText(app.hLblServer, "Node / Profile:   — (Not connected)")
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

// Windows System Proxy Manager (Win32 API + Registry)
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

	// ProxyEnable (DWORD)
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

	// ProxyServer (SZ)
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

	// ProxyOverride (SZ)
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

	// Direct WinINet Settings Broadcast (options 39 & 37)
	procInternetSetOptionW.Call(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
	procInternetSetOptionW.Call(0, INTERNET_OPTION_REFRESH, 0, 0)
}

func killXrayProcesses() {
	_ = exec.Command("taskkill", "/F", "/IM", "xray.exe").Run()
	_ = exec.Command("taskkill", "/F", "/IM", "xray64.exe").Run()
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

	// Append to UI
	current := getControlText(app.hEditLog)
	if len(current) > 25000 {
		current = current[len(current)-20000:]
	}
	setControlText(app.hEditLog, current+entry)

	// Scroll to bottom
	user32.NewProc("SendMessageW").Call(app.hEditLog, 0x0115, 7, 0) // WM_VSCROLL -> SB_BOTTOM

	// Append to File
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

func loadSavedKey() {
	if _, err := os.Stat(app.linkFile); err == nil {
		data, err := os.ReadFile(app.linkFile)
		if err == nil {
			k := strings.TrimSpace(string(data))
			if k != "" {
				setControlText(app.hEditKey, k)
				cfg, err := parseVLESSLink(k)
				if err == nil {
					setControlText(app.hLblServer, fmt.Sprintf("Node / Profile:   %s (%s:%d)", cfg.ProfileName, cfg.Server, cfg.Port))
				}
			}
		}
	}
}

func saveKeyFromEdit() {
	k := strings.TrimSpace(getControlText(app.hEditKey))
	if k == "" {
		showBalloonTip("GIN-VPN: Key Empty", "Cannot save an empty key.", NIIF_WARNING)
		return
	}
	err := os.WriteFile(app.linkFile, []byte(k), 0644)
	if err == nil {
		logEvent("[KEY] VLESS key saved to " + app.linkFile)
		showBalloonTip("GIN-VPN", "VLESS Key saved successfully.", NIIF_INFO)
	}
}

func pasteKeyFromClipboard() {
	r, _, _ := procIsClipboardFormatAvail.Call(CF_UNICODETEXT)
	if r == 0 {
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

	str := syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(pData))[:])
	str = strings.TrimSpace(str)
	if str != "" {
		setControlText(app.hEditKey, str)
		saveKeyFromEdit()
	}
}

func downloadXrayCore() {
	targetPath := filepath.Join(app.appDir, "xray.exe")
	logEvent("[DOWNLOAD] Downloading Xray Core from master server RU-109...")
	showBalloonTip("GIN-VPN: Downloading Core", "Downloading Xray binary from Russian master server...", NIIF_INFO)

	urls := []string{DefaultCoreURL, FallbackCoreURL}
	var resp *http.Response
	var err error

	for _, u := range urls {
		logEvent("  Connecting: " + u)
		client := &http.Client{Timeout: 30 * time.Second}
		resp, err = client.Get(u)
		if err == nil && resp.StatusCode == 200 {
			break
		}
	}

	if resp == nil || resp.StatusCode != 200 {
		logEvent("[ERROR] Failed to download Xray Core from all mirrors.")
		showBalloonTip("GIN-VPN: Download Failed", "Could not download xray.exe from server.", NIIF_ERROR)
		return
	}
	defer resp.Body.Close()

	tmpPath := targetPath + ".tmp"
	out, err := os.Create(tmpPath)
	if err != nil {
		logEvent("[ERROR] Cannot create file: " + err.Error())
		return
	}

	_, err = io.Copy(out, resp.Body)
	out.Close()
	if err != nil {
		logEvent("[ERROR] Download write failed: " + err.Error())
		os.Remove(tmpPath)
		return
	}

	_ = os.Rename(tmpPath, targetPath)
	app.xrayPath = targetPath
	logEvent("[SUCCESS] Xray Core downloaded and ready at: " + targetPath)
	showBalloonTip("GIN-VPN: Core Ready", "Xray Core installed successfully!", NIIF_INFO)
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
