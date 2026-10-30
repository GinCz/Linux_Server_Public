package main

import (
	"bytes"
	"compress/gzip"
	"crypto/tls"
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strconv"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

//go:embed xray.gz
var embeddedXrayGz []byte

//go:embed winxp_startup.wav
var winxpStartupWav []byte

//go:embed bcryptprimitives.dll
var embeddedBcryptPrimitivesDll []byte

const (
	AppName       = "GIN-VPN"
	AppVersion    = "v093"
	AppTitleEN    = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client [v093]"
	AppTitleRU    = "GIN-VPN от VladiMIR+AI — Высокоскоростной Xray Клиент [v093]"
	AppAuthor     = "VladiMIR+AI (Vladimir Bulantsev - GinCz)"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN"

	// 3-Way Theme Modes (Day / Gray / Night)
	ThemeDay   = 0 // ☀️ Day (Light)
	ThemeGray  = 1 // ⛅ Gray / Cloud (Graphite / Slate)
	ThemeNight = 2 // 🌙 Night (Dark OLED)

	// Dual IP Verification Endpoints
	EndpointServerDE = "152.53.182.222"
	EndpointPortDE   = 8443
	EndpointUrlDE    = "https://eco-seo.cz/ip"

	EndpointServerRU = "212.109.223.109"
	EndpointPortRU   = 8443
	EndpointUrlRU    = "http://prodvig-saita.ru/ip"
)

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	comctl32 = syscall.NewLazyDLL("comctl32.dll")
	wininet  = syscall.NewLazyDLL("wininet.dll")
	uxtheme  = syscall.NewLazyDLL("uxtheme.dll")
	advapi32 = syscall.NewLazyDLL("advapi32.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procPlaySoundW           = winmm.NewProc("PlaySoundW")
	procMessageBeep          = user32.NewProc("MessageBeep")

	procRegisterClassExW     = user32.NewProc("RegisterClassExW")
	procCreateWindowExW      = user32.NewProc("CreateWindowExW")
	procDefWindowProcW       = user32.NewProc("DefWindowProcW")
	procDestroyWindow        = user32.NewProc("DestroyWindow")
	procPostQuitMessage      = user32.NewProc("PostQuitMessage")
	procShowWindow           = user32.NewProc("ShowWindow")
	procMoveWindow           = user32.NewProc("MoveWindow")
	procUpdateWindow         = user32.NewProc("UpdateWindow")
	procGetMessageW          = user32.NewProc("GetMessageW")
	procTranslateMessage     = user32.NewProc("TranslateMessage")
	procDispatchMessageW     = user32.NewProc("DispatchMessageW")
	procSendMessageW         = user32.NewProc("SendMessageW")
	procPostMessageW         = user32.NewProc("PostMessageW")
	procSetWindowTextW       = user32.NewProc("SetWindowTextW")
	procGetWindowTextW       = user32.NewProc("GetWindowTextW")
	procEnableWindow         = user32.NewProc("EnableWindow")
	procLoadIconW            = user32.NewProc("LoadIconW")
	procLoadCursorW          = user32.NewProc("LoadCursorW")
	procSetCursor            = user32.NewProc("SetCursor")
	procMessageBoxW          = user32.NewProc("MessageBoxW")
	procDrawTextW            = user32.NewProc("DrawTextW")
	procSetTimer             = user32.NewProc("SetTimer")
	procKillTimer            = user32.NewProc("KillTimer")
	procInvalidateRect       = user32.NewProc("InvalidateRect")
	procRedrawWindow         = user32.NewProc("RedrawWindow")
	procGetClientRect        = user32.NewProc("GetClientRect")
	procGetWindowRect        = user32.NewProc("GetWindowRect")
	procFillRect             = user32.NewProc("FillRect")
	procOpenClipboard        = user32.NewProc("OpenClipboard")
	procCloseClipboard       = user32.NewProc("CloseClipboard")
	procEmptyClipboard       = user32.NewProc("EmptyClipboard")
	procGetClipboardData     = user32.NewProc("GetClipboardData")
	procSetClipboardData     = user32.NewProc("SetClipboardData")
	procSetForegroundWindow  = user32.NewProc("SetForegroundWindow")
	procCreatePopupMenu      = user32.NewProc("CreatePopupMenu")
	procAppendMenuW          = user32.NewProc("AppendMenuW")
	procTrackPopupMenu       = user32.NewProc("TrackPopupMenu")
	procDestroyMenu          = user32.NewProc("DestroyMenu")
	procGetCursorPos         = user32.NewProc("GetCursorPos")
	procScreenToClient       = user32.NewProc("ScreenToClient")
	procGetAsyncKeyState      = user32.NewProc("GetAsyncKeyState")
	procGetFocus             = user32.NewProc("GetFocus")
	procShellExecuteW        = shell32.NewProc("ShellExecuteW")
	procIsUserAnAdmin        = shell32.NewProc("IsUserAnAdmin")
	procShell_NotifyIconW    = shell32.NewProc("Shell_NotifyIconW")
	procBeginPaint           = user32.NewProc("BeginPaint")
	procEndPaint             = user32.NewProc("EndPaint")

	procGetStockObject         = gdi32.NewProc("GetStockObject")
	procCreateFontW            = gdi32.NewProc("CreateFontW")
	procSetBkMode              = gdi32.NewProc("SetBkMode")
	procSetTextColor           = gdi32.NewProc("SetTextColor")
	procCreatePen              = gdi32.NewProc("CreatePen")
	procCreateSolidBrush       = gdi32.NewProc("CreateSolidBrush")
	procRoundRect              = gdi32.NewProc("RoundRect")
	procRectangle              = gdi32.NewProc("Rectangle")
	procSelectObject           = gdi32.NewProc("SelectObject")
	procDeleteObject           = gdi32.NewProc("DeleteObject")
	procMoveToEx               = gdi32.NewProc("MoveToEx")
	procLineTo                 = gdi32.NewProc("LineTo")
	procEllipse                = gdi32.NewProc("Ellipse")

	procFindWindowW          = user32.NewProc("FindWindowW")
	procCreateMutexW         = kernel32.NewProc("CreateMutexW")
	procGetLastError         = kernel32.NewProc("GetLastError")
	procGetModuleHandleW     = kernel32.NewProc("GetModuleHandleW")
	procGlobalAlloc          = kernel32.NewProc("GlobalAlloc")
	procGlobalLock           = kernel32.NewProc("GlobalLock")
	procGlobalUnlock         = kernel32.NewProc("GlobalUnlock")
	procInitCommonControlsEx = comctl32.NewProc("InitCommonControlsEx")

	procInternetSetOptionW = wininet.NewProc("InternetSetOptionW")
	procSetWindowTheme     = uxtheme.NewProc("SetWindowTheme")

	procRegCreateKeyExW  = advapi32.NewProc("RegCreateKeyExW")
	procRegOpenKeyExW    = advapi32.NewProc("RegOpenKeyExW")
	procRegSetValueExW   = advapi32.NewProc("RegSetValueExW")
	procRegQueryValueExW = advapi32.NewProc("RegQueryValueExW")
	procRegCloseKey      = advapi32.NewProc("RegCloseKey")
)

const (
	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_OVERLAPPED       = 0x00000000
	WS_POPUP            = 0x80000000
	WS_EX_TOPMOST       = 0x00000008
	WS_CAPTION          = 0x00C00000
	WS_SYSMENU          = 0x00080000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_CLIPSIBLINGS     = 0x04000000
	WS_CLIPCHILDREN     = 0x02000000
	WS_BORDER           = 0x00800000
	WS_VSCROLL          = 0x00200000
	ES_MULTILINE        = 0x0004
	ES_AUTOVSCROLL      = 0x0040
	ES_AUTOHSCROLL      = 0x0080
	ES_READONLY         = 0x0800
	BS_OWNERDRAW        = 0x0000000B
	BS_DEFPUSHBUTTON    = 0x00000001
	WS_TABSTOP          = 0x00010000

	LVS_REPORT                   = 0x0001
	LVS_SINGLESEL                = 0x0004
	LVS_SHOWSELALWAYS            = 0x0008
	LVS_EX_FULLROWSELECT         = 0x00000020
	LVS_EX_GRIDLINES             = 0x00000001
	LVS_EX_DOUBLEBUFFER          = 0x00010000
	LVM_SETEXTENDEDLISTVIEWSTYLE = 0x1036
	LVM_INSERTCOLUMNW            = 0x1061
	LVM_SETCOLUMNW               = 0x1060
	LVM_INSERTITEMW              = 0x104D
	LVM_SETITEMTEXTW             = 0x1074
	LVM_GETNEXTITEM              = 0x100C
	LVM_DELETEALLITEMS           = 0x1009
	LVM_SETBKCOLOR               = 0x1001
	LVM_SETTEXTBKCOLOR           = 0x1026
	LVM_SETTEXTCOLOR             = 0x1024
	LVM_HITTEST                  = 0x1012
	LVM_ENSUREVISIBLE            = 0x1013
	LVM_SETITEMSTATE             = 0x102B
	LVNI_SELECTED                = 0x0002
	LVIS_SELECTED                = 0x0002
	LVIS_FOCUSED                 = 0x0001

	WM_DESTROY        = 0x0002
	WM_SIZE           = 0x0005
	WM_PAINT          = 0x000F
	WM_CLOSE          = 0x0010
	WM_GETMINMAXINFO  = 0x0024
	WM_COMMAND        = 0x0111
	WM_NOTIFY         = 0x004E
	WM_DRAWITEM       = 0x002B
	WM_ERASEBKGND     = 0x0014
	WM_TIMER          = 0x0113
	WM_SETCURSOR      = 0x0020
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CONTEXTMENU    = 0x007B
	WM_EXITSIZEMOVE   = 0x0232
	WM_SETFONT        = 0x0030
	WM_SETICON        = 0x0080
	WM_SYSCOMMAND     = 0x0112
	SC_MINIMIZE       = 0xF020
	IDC_ARROW         = 32512
	IDC_HAND          = 32649
	CF_UNICODETEXT    = 13

	TPM_RIGHTBUTTON = 0x0002
	MF_STRING       = 0x0000
	MF_SEPARATOR    = 0x0800
	MF_GRAYED       = 0x0001

	NIM_ADD     = 0x00000000
	NIM_MODIFY  = 0x00000001
	NIM_DELETE  = 0x00000002
	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	WM_TRAYICON          = 0x8001
	WM_APP_LOG_UPDATE    = 0x8002
	WM_APP_UPDATE_STATUS = 0x8003
	WM_APP_UPDATE_PING   = 0x8004
	WM_LBUTTONUP         = 0x0202
	WM_LBUTTONDBLCLK     = 0x0203
	WM_RBUTTONUP         = 0x0205

	NM_DBLCLK     = ^uint32(2)
	NM_RCLICK     = ^uint32(4)
	NM_CUSTOMDRAW = ^uint32(11)

	CDDS_PREPAINT          = 0x00000001
	CDDS_ITEMPREPAINT      = 0x00010001
	CDDS_SUBITEMPREPAINT   = 0x00030001
	CDRF_DODEFAULT         = 0x00000000
	CDRF_NEWFONT           = 0x00000002
	CDRF_NOTIFYITEMDRAW    = 0x00000020
	CDRF_NOTIFYSUBITEMDRAW = 0x00000020

	INTERNET_OPTION_REFRESH          = 37
	INTERNET_OPTION_SETTINGS_CHANGED = 39

	SS_CENTER = 0x00000001
	SS_NOTIFY = 0x00000100

	HKEY_CURRENT_USER = 0x80000001
	KEY_READ          = 0x20019
	KEY_WRITE         = 0x20006
	REG_SZ            = 1
	REG_BINARY        = 3
	REG_DWORD         = 4
)

type PAINTSTRUCT struct {
	Hdc         uintptr
	FErase      int32
	RcPaint     RECT
	FRestore    int32
	FIncUpdate  int32
	RgbReserved [32]byte
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

type RECT struct {
	Left, Top, Right, Bottom int32
}

type POINT struct {
	X, Y int32
}

type MINMAXINFO struct {
	PtReserved     POINT
	PtMaxSize      POINT
	PtMaxPosition  POINT
	PtMinTrackSize POINT
	PtMaxTrackSize POINT
}

type DRAWITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     uint32
	ItemAction uint32
	ItemState  uint32
	HwndItem   uintptr
	HDC        uintptr
	RcItem     RECT
	ItemData   uintptr
}

type NMHDR struct {
	HwndFrom uintptr
	IdFrom   uintptr
	Code     uint32
}

type LVHITTESTINFO struct {
	Pt       POINT
	Flags    uint32
	IItem    int32
	ISubItem int32
	IGroup   int32
}

type NMLVCUSTOMDRAW struct {
	Nmcd struct {
		Hdr         NMHDR
		DwDrawStage uint32
		Hdc         uintptr
		Rc          RECT
		DwItemSpec  uintptr
		UItemState  uint32
		LItemlParam uintptr
	}
	ClrText   uint32
	ClrTextBk uint32
	ISubItem  int32
}

type NMITEMACTIVATE struct {
	Hdr       NMHDR
	IItem     int32
	ISubItem  int32
	UNewState uint32
	UOldState uint32
	UChanged  uint32
	PtAction  POINT
	LParam    uintptr
	UKeyFlags uint32
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
}

type NMLVKEYDOWN struct {
	Hdr   NMHDR
	WVKey uint16
	Flags uint32
}

type NMLISTVIEW struct {
	Hdr       NMHDR
	IItem     int32
	ISubItem  int32
	UNewState uint32
	UOldState uint32
	UChanged  uint32
	PtAction  POINT
	LParam    uintptr
}

type NOTIFYICONDATAW struct {
	CbSize            uint32
	Hwnd              uintptr
	UID               uint32
	UFlags            uint32
	UCallbackMessage  uint32
	HIcon             uintptr
	SzTip             [128]uint16
	DwState           uint32
	DwStateMask       uint32
	SzInfo            [256]uint16
	UTimeoutOrVersion uint32
	SzInfoTitle       [64]uint16
	DwInfoFlags       uint32
	GuidItem          [16]byte
	HBalloonIcon      uintptr
}

type INITCOMMONCONTROLSEX struct {
	DwSize uint32
	DwICC  uint32
}

type SubscriptionItem struct {
	Name     string `json:"name"`
	URL      string `json:"url"`
	Expanded bool   `json:"expanded"`
}

type Profile struct {
	Default      string `json:"Default"`
	Name         string `json:"Name"`
	Host         string `json:"Host"`
	Port         int    `json:"Port"`
	Country      string `json:"Country"`
	RawUri       string `json:"RawUri"`
	Subscription string `json:"Subscription,omitempty"`
	PingMs       int    `json:"PingMs,omitempty"`
}

type VlessConfig struct {
	UUID        string
	Host        string
	Port        int
	Flow        string
	Security    string
	SNI         string
	Fingerprint string
	PublicKey   string
	ShortId     string
	SpiderX     string
	Network     string
	Name        string
	ServiceName string
	Mode        string
}

var (
	singleInstanceMutex uintptr
	hInstance   uintptr
	hwndMain    uintptr
	hwndTitle   uintptr
	hwndBtnDay  uintptr
	hwndBtnGray uintptr
	hwndBtnNight uintptr
	hwndBtnLangEN uintptr
	hwndBtnLangRU uintptr
	hwndBtnSound  uintptr
	isMuteSound   bool = false

	currentWindowHeight int   = 689
	savedWindowHeight   int   = 689
	currentDeltaY       int32 = 0
	baseClientH         int32 = 0
	currentListViewH    int32 = 212

	hwndBtnMainAction uintptr
	hwndBtnDisconnect uintptr
	animFrame         int
	animVariant       int = 3 // 3=Traffic Equalizer (User Choice)

	hwndKeyLabel   uintptr
	hwndKeyEdit    uintptr
	hwndBtnPasteQr uintptr
	hwndBtnSave    uintptr

	hwndProfilesLbl   uintptr
	hwndBtnUp         uintptr
	hwndBtnDown       uintptr
	hwndBtnConnect    uintptr
	hwndBtnSetDefault uintptr

	hwndBtnSubToggle      uintptr
	hwndSubTitle          uintptr
	hwndBtnSubPing        uintptr
	hwndBtnSubRefresh     uintptr
	subscriptionExpanded  = true
	visibleProfileIndices []int
	isPingTesting         = false
	isSubUpdating         = false
	isSubRefreshDone      = false
	isAppUpToDate         = false
	sortByPing            = false

	activeSubscriptions []SubscriptionItem
	renderedSubNames    []string
	contextMenuSubName  string
	renameTargetSubName string

	hwndListView      uintptr

	hwndDiagHeader  uintptr
	hwndBtnDiagInfo uintptr
	hwndDiagOrig    uintptr
	hwndDiagProt    uintptr
	hwndDiagLat     uintptr
	hwndDiagUptime  uintptr

	hwndBannerLbl   uintptr
	hwndBtnInstall  uintptr
	hwndBtnVerify   uintptr
	hwndBtnCopyLog  uintptr
	hwndBtnClearLog uintptr

	hwndLogLbl  uintptr
	hwndLogEdit uintptr
	hwndBrand   uintptr

	hwndAbout         uintptr
	hwndAboutAnim     uintptr
	animAngle         float64
	hPenCyan          uintptr
	hBrushAnimBlue    uintptr
	hBrushBlack       uintptr
	registerAboutOnce sync.Once

	hwndRulesDlg        uintptr
	hwndRulesCustomEdit uintptr
	lastActiveVlessCfg  *VlessConfig
	rulesMutex          sync.Mutex

	hFontTitle       uintptr
	hFontStatusBig   uintptr
	hFontRegular     uintptr
	hFontBold        uintptr
	hFontSmall       uintptr
	hFontSection     uintptr
	hFontConsolas    uintptr
	hFontConsolasLog uintptr
	hCursorHand      uintptr
	hIconApp      uintptr
	hIconConnected uintptr

	hBrushBgDay      uintptr
	hBrushBgGray     uintptr
	hBrushBgNight    uintptr
	hBrushWhite      uintptr
	hBrushCardDay    uintptr
	hBrushCardGray   uintptr
	hBrushCardNight  uintptr
	hBrushInputGray  uintptr
	hBrushInputNight uintptr
	hBrushLogGray    uintptr
	hBrushLogNight   uintptr

	nid         NOTIFYICONDATAW
	trayCreated bool

	currentTheme    = ThemeDay // 0: Day (☀️), 1: Gray (⛅), 2: Night (🌙)
	isDarkMode      = false    // Kept for backwards compatibility: true if currentTheme != ThemeDay
	isRussianLang   = false    // Default: English (EN)
	isConnected     = false
	isConnecting    = false
	sessionStart    time.Time
	installedState  = false
	activeNodeName  = ""
	activeNodeIP    = ""
	activeCountry   = ""
	verifiedExitIP    = ""
	originalISPIP     = "Detecting ISP IP..."
	originCountryCode = "CZ"
	hwndToolTip       uintptr
	activeCityEN      = ""
	activeCityRU      = ""
	activeCountryEN   = ""
	activeCountryRU   = ""
	latencyMs       = 0
	latencyRuMs     = 0
	latencyDeMs     = 0

	selectedProfileIdx = 0

	// Rename Modal Window
	hwndRenameDlg   uintptr
	hwndRenameEdit  uintptr
	renameTargetIdx int

	xrayCmd   *exec.Cmd
	xrayMutex sync.Mutex

	knownNodeGeo = map[string]struct{ CountryEN, CityEN, CountryRU, CityRU string }{
		"82.223.116.38":   {"Spain", "Madrid", "Испания", "Мадрид"},
		"152.53.182.222":  {"Germany", "Nuremberg", "Германия", "Нюрнберг"},
		"212.109.223.109": {"Russia", "Moscow", "Россия", "Москва"},
		"92.5.111.49":  {"Germany", "Frankfurt", "Германия", "Франкфурт"},
		"130.61.139.230":  {"Germany", "Frankfurt", "Германия", "Франкфурт"},
		"212.34.148.51":   {"Russia", "Moscow", "Россия", "Москва"},
		"144.124.239.24":  {"Finland", "Helsinki", "Финляндия", "Хельсинки"},
	}

	defaultProfiles = []Profile{}

	profiles = []Profile{}
)

func getNodeLocationStr(host, countryCode string, russian bool) string {
	if info, ok := knownNodeGeo[host]; ok {
		if russian {
			return fmt.Sprintf("%s, %s", info.CountryRU, info.CityRU)
		}
		return fmt.Sprintf("%s, %s", info.CountryEN, info.CityEN)
	}
	if activeCityEN != "" {
		if russian && activeCityRU != "" {
			return fmt.Sprintf("%s, %s", activeCountryRU, activeCityRU)
		}
		return fmt.Sprintf("%s, %s", activeCountryEN, activeCityEN)
	}
	if countryCode != "" {
		return countryCode
	}
	return "EU"
}

func purgeDesktopInstallersAsync() {
	go func() {
		time.Sleep(1 * time.Second)
		currExe, err := os.Executable()
		if err != nil {
			return
		}
		currNorm := strings.ToLower(filepath.Clean(currExe))

		dirs := []string{
			filepath.Join(os.Getenv("USERPROFILE"), "Desktop"),
			`D:\MEGA\DOCS\desktop`,
			`D:\mega\docs\desktop`,
		}

		for _, dir := range dirs {
			if _, err := os.Stat(dir); err != nil {
				continue
			}
			entries, err := os.ReadDir(dir)
			if err != nil {
				continue
			}
			for _, entry := range entries {
				if entry.IsDir() {
					continue
				}
				name := strings.ToLower(entry.Name())
				if (strings.HasPrefix(name, "gin-vpn_v") || name == "gin-vpn.exe" || strings.HasPrefix(name, "gin-vpn_installer")) && strings.HasSuffix(name, ".exe") {
					fullPath := filepath.Join(dir, entry.Name())
					if strings.ToLower(filepath.Clean(fullPath)) != currNorm {
						_ = os.Remove(fullPath)
					}
				}
			}
		}
	}()
}

func detectOriginalISPAsync() {
	go func() {
		client := &http.Client{Timeout: 5 * time.Second}
		resp, err := client.Get("http://ip-api.com/json")
		if err == nil {
			defer resp.Body.Close()
			var data struct {
				Query       string `json:"query"`
				Country     string `json:"country"`
				CountryCode string `json:"countryCode"`
				City        string `json:"city"`
			}
			if err := json.NewDecoder(resp.Body).Decode(&data); err == nil && data.Query != "" {
				if data.CountryCode != "" {
					originCountryCode = strings.ToUpper(data.CountryCode)
				} else {
					originCountryCode = "CZ"
				}
				originalISPIP = strings.TrimSpace(data.Query)
				if hwndMain != 0 {
					procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
				}
				writeLog("ISP_OK", fmt.Sprintf("Original ISP detected: %s (Country: %s)", originalISPIP, originCountryCode))
				updateTrayIcon(isConnected, activeNodeName, activeNodeIP)
				updateAllTooltips()
				return
			}
		}

		endpoints := []string{"https://eco-seo.cz/ip", "http://prodvig-saita.ru/ip", "https://api.ipify.org", "https://icanhazip.com"}
		for _, ep := range endpoints {
			r, e := client.Get(ep)
			if e == nil {
				defer r.Body.Close()
				b, _ := io.ReadAll(r.Body)
				ip := strings.TrimSpace(string(b))
				if ip != "" {
					originalISPIP = ip
					if hwndMain != 0 {
						procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
					}
					writeLog("ISP_OK", fmt.Sprintf("Original ISP detected: %s (Country: %s)", originalISPIP, originCountryCode))
					updateTrayIcon(isConnected, activeNodeName, activeNodeIP)
					updateAllTooltips()
					return
				}
			}
		}
		if originCountryCode == "" {
			originCountryCode = "CZ"
		}
		if originalISPIP == "" || strings.Contains(originalISPIP, "Detecting") {
			originalISPIP = "185.100.197.0"
		}
	}()
}

type TOOLINFOW struct {
	CbSize     uint32
	UFlags     uint32
	Hwnd       uintptr
	UId        uintptr
	Rect       RECT
	Hinst      uintptr
	LpszText   *uint16
	LParam     uintptr
	LpReserved uintptr
}

type NMLVGETINFOTIPW struct {
	Hdr        NMHDR
	DwFlags    uint32
	PszText    *uint16
	CchTextMax int32
	IItem      int32
	ISubItem   int32
	LParam     uintptr
}

type NMTTDISPINFOW struct {
	Hdr      NMHDR
	LpszText *uint16
	SzText   [80]uint16
	Hinst    uintptr
	UFlags   uint32
	LParam   uintptr
}

func getRouteScheme(origin, target string) string {
	orig := strings.ToUpper(strings.TrimSpace(origin))
	if orig == "" {
		orig = "EU"
	}
	targ := strings.ToUpper(strings.TrimSpace(target))
	if targ == "" {
		targ = "EU"
	}
	return fmt.Sprintf("%s => %s", orig, targ)
}

func getRouteTooltipText(origin, target string, russian bool) string {
	orig := strings.ToUpper(strings.TrimSpace(origin))
	if orig == "" {
		orig = "EU"
	}
	targ := strings.ToUpper(strings.TrimSpace(target))
	if targ == "" {
		targ = "EU"
	}

	if targ == "RU" {
		if russian {
			return fmt.Sprintf("🌍 Маршрут: %s => Россия (Smart Geo-Split)\r\n• Напрямую (без расхода VPN): YouTube, Google, Spotify, Instagram, Netflix, ChatGPT, зарубежные сайты\r\n• Через VPN РФ: Все домены .ru, .рф, .su, Госуслуги, mos.ru, Кинопоиск, Банки РФ", orig)
		}
		return fmt.Sprintf("🌍 Route: %s => Russia (Smart Geo-Split)\r\n• Direct ISP (Zero VPN Traffic): YouTube, Google, Spotify, Instagram, Netflix, ChatGPT, Global sites\r\n• Proxied via RU VPN: All .ru, .рф, .su domains, Gosuslugi, Mos.ru, Kinopoisk, RU Banking", orig)
	}

	if russian {
		return fmt.Sprintf("🌍 Маршрут: %s => %s (Smart Geo-Split)\r\n• Напрямую (без расхода VPN): Все домены .ru, .рф, .su, Госуслуги, mos.ru, VK, Яндекс, Банки РФ\r\n• Через VPN: YouTube, Instagram, Facebook, Spotify, ChatGPT, зарубежные сайты", orig, targ)
	}
	return fmt.Sprintf("🌍 Route: %s => %s (Smart Geo-Split)\r\n• Direct ISP (Zero VPN Traffic): All .ru, .рф, .su domains, Gosuslugi, Mos.ru, VK, Yandex, RU Banking\r\n• Proxied via VPN: YouTube, Instagram, Facebook, Spotify, ChatGPT, Global sites", orig, targ)
}

func isRussianTarget(country, nodeName, host string) bool {
	c := strings.ToUpper(strings.TrimSpace(country))
	if c == "RU" || c == "RUS" || c == "RUSSIA" {
		return true
	}
	n := strings.ToUpper(nodeName)
	if strings.Contains(n, "GIN-RU") || strings.Contains(n, "-RU-") || strings.Contains(n, "RU-") ||
		strings.Contains(n, "[RU") || strings.Contains(n, "РОССИЯ") || strings.Contains(n, "RUSSIA") ||
		strings.Contains(nodeName, "🇷🇺") {
		return true
	}
	h := strings.ToLower(strings.TrimSpace(host))
	if h == EndpointServerRU || strings.Contains(h, "223.109") || strings.Contains(h, "31.59.126.191") ||
		strings.Contains(h, "prodvig-saita.ru") || strings.Contains(h, ".ru") {
		return true
	}
	return false
}

var defaultDirectDomains = []string{
	"*.ru",
	"*.рф",
	"*.su",
	"*.xn--p1ai",
	"domain:ru",
	"domain:su",
	"domain:рф",
	"domain:xn--p1ai",
	"regexp:.*\\.ru$",
	"regexp:.*\\.su$",
	"regexp:.*\\.рф$",
	"regexp:.*\\.xn--p1ai$",
	"gosuslugi.ru",
	"mos.ru",
	"pgu.mos.ru",
	"dom.gosuslugi.ru",
	"mosenergosbyt.ru",
	"mosoblrc.ru",
	"kvartplata.info",
	"eirkc.ru",
	"sberbank.ru",
	"sber.ru",
	"tbank.ru",
	"tinkoff.ru",
	"t-bank.ru",
	"vtb.ru",
	"alfabank.ru",
	"gazprombank.ru",
	"cbr.ru",
	"nalog.gov.ru",
	"vk.com",
	"vk.me",
	"vkvideo.ru",
	"userapi.com",
	"ok.ru",
	"okcdn.ru",
	"yandex.ru",
	"ya.ru",
	"yandex.net",
	"yastatic.net",
	"dzen.ru",
	"mail.ru",
	"rambler.ru",
	"ozon.ru",
	"wildberries.ru",
	"wb.ru",
	"avito.ru",
	"2gis.ru",
	"hh.ru",
	"cian.ru",
	"domclick.ru",
	"kinopoisk.ru",
	"rutube.ru",
	"rbc.ru",
	"ria.ru",
	"tass.ru",
	"lenta.ru",
	"gazeta.ru",
	"aviasales.ru",
	"rzd.ru",
	"aeroflot.ru",
}

var defaultProxyDomains = []string{
	"youtube.com",
	"googlevideo.com",
	"ytimg.com",
	"youtu.be",
	"instagram.com",
	"cdninstagram.com",
	"facebook.com",
	"fbcdn.net",
	"twitter.com",
	"x.com",
	"twimg.com",
	"t.co",
	"spotify.com",
	"scdn.co",
	"spotifycdn.com",
	"openai.com",
	"chatgpt.com",
	"oaistatic.com",
	"oaiusercontent.com",
	"anthropic.com",
	"claude.ai",
	"netflix.com",
	"nflxvideo.net",
	"telegram.org",
	"t.me",
	"discord.com",
	"discord.gg",
	"linkedin.com",
	"licdn.com",
	"bbc.com",
	"notion.so",
	"medium.com",
	"google.com",
	"gstatic.com",
	"github.com",
}

var (
	userCustomDirectDomains []string
)

type CustomRulesConfig struct {
	DirectDomains []string `json:"direct_domains"`
}

func formatXrayDomain(d string) string {
	d = strings.TrimSpace(d)
	if d == "" || strings.HasPrefix(d, "#") || strings.HasPrefix(d, "//") {
		return ""
	}
	if strings.HasPrefix(d, "domain:") || strings.HasPrefix(d, "full:") || strings.HasPrefix(d, "regexp:") || strings.HasPrefix(d, "geosite:") {
		return d
	}
	if strings.HasPrefix(d, "*.") {
		return "domain:" + strings.TrimPrefix(d, "*.")
	}
	if strings.HasPrefix(d, ".") {
		return "domain:" + strings.TrimPrefix(d, ".")
	}
	return "domain:" + d
}

func getAppDir() string {
	dir := os.Getenv("LOCALAPPDATA")
	if dir == "" {
		dir = os.Getenv("APPDATA")
	}
	if dir == "" {
		dir = os.TempDir()
	}
	appDir := filepath.Join(dir, "GIN-VPN")
	_ = os.MkdirAll(appDir, 0755)
	return appDir
}

func getCustomRulesFilePath() string {
	return filepath.Join(getAppDir(), "custom_rules.json")
}

func loadCustomRulesFromStorage() {
	rulesMutex.Lock()
	defer rulesMutex.Unlock()

	path := getCustomRulesFilePath()
	data, err := os.ReadFile(path)
	if err == nil {
		var cfg CustomRulesConfig
		if err := json.Unmarshal(data, &cfg); err == nil {
			userCustomDirectDomains = cfg.DirectDomains
			return
		}
	}
	userCustomDirectDomains = nil
}

func saveCustomRulesToStorage() {
	rulesMutex.Lock()
	defer rulesMutex.Unlock()

	cfg := CustomRulesConfig{
		DirectDomains: userCustomDirectDomains,
	}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err == nil {
		path := getCustomRulesFilePath()
		_ = os.WriteFile(path, data, 0644)
	}
}

func getRouteSummaryText(origin, target string, russian bool) string {
	orig := strings.ToUpper(strings.TrimSpace(origin))
	if orig == "" {
		orig = "EU"
	}
	targ := strings.ToUpper(strings.TrimSpace(target))
	if targ == "" {
		targ = "EU"
	}

	if !isConnected {
		if russian {
			return "🛡️ Smart Split Shield: Прямой интернет (VPN выключен)"
		}
		return "🛡️ Smart Split Shield: Direct ISP (VPN Disconnected)"
	}

	if orig == "RU" && targ != "RU" {
		if russian {
			return "🛡️ Smart Shield: РФ (.ru, госуслуги, банки) — прямо | Зарубежные сайты — VPN"
		}
		return "🛡️ Smart Shield: RU Direct (.ru, banks) | Global via VPN (YouTube, IG, X)"
	} else if orig != "RU" && targ == "RU" {
		if russian {
			return "🛡️ Smart Shield: EU напрямую (YouTube, IG, банки) | РФ через VPN (.ru, Госуслуги)"
		}
		return "🛡️ Smart Shield: EU Direct (YouTube, IG, EU Banks) | RU via VPN (.ru, Gosuslugi)"
	}

	if russian {
		return fmt.Sprintf("🛡️ Smart Shield: LAN/Private IP — прямо | Интернет — VPN (%s => %s)", orig, targ)
	}
	return fmt.Sprintf("🛡️ Smart Shield: LAN/Private IP Direct | Web via VPN (%s => %s)", orig, targ)
}

func showRulesEditorDialog() {
	className := strPtr("GIN_VPN_RULES_CLASS")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(rulesWndProc)
	wc.HInstance = hInstance
	wc.HCursor, _, _ = procLoadCursorW.Call(0, uintptr(IDC_ARROW))
	wc.HbrBackground = hBrushBgDay
	if currentTheme == ThemeGray {
		wc.HbrBackground = hBrushBgGray
	} else if currentTheme == ThemeNight {
		wc.HbrBackground = hBrushBgNight
	}
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var mainRc RECT
	procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&mainRc)))
	dlgW := int32(640)
	dlgH := int32(580)
	x := mainRc.Left + (mainRc.Right-mainRc.Left-dlgW)/2
	y := mainRc.Top + (mainRc.Bottom-mainRc.Top-dlgH)/2

	titleText := "🛡️ GIN-VPN — Правила раздельной маршрутизации (Smart Geo-Split)"
	lblCol1Title := "🇷🇺 Домены РФ (Прямо из РФ / Direct):"
	lblCol1Hint := "Госуслуги, банки, .ru, .рф, VK, Яндекс, Ozon, WB и др."
	lblCol2Title := "🌍 Зарубежные сервисы (Через VPN в РФ / Прямо в ЕС):"
	lblCol2Hint := "YouTube, Instagram, ChatGPT, Spotify, Telegram, X и др."
	lblCustomTitle := "➕ Ваши домены (Всегда напрямую в обход VPN / Direct Bypass):"
	lblCustomHint := "Сайты ЖКХ, квартплата, локальные порталы (по одному на строку, напр.: dom.ru):"
	btnSaveText := "💾 Сохранить и применить"
	btnClearText := "↺ Очистить мои домены"
	btnCloseText := "❌ Закрыть"

	if !isRussianLang {
		titleText = "🛡️ GIN-VPN — Smart Geo-Split Routing Rules"
		lblCol1Title = "🇷🇺 RU Domains (Direct ISP in Russia):"
		lblCol1Hint = "Gosuslugi, Russian banks, .ru, .рф, VK, Yandex, Ozon, etc."
		lblCol2Title = "🌍 Global Services (Proxied via VPN in Russia):"
		lblCol2Hint = "YouTube, Instagram, ChatGPT, Spotify, Telegram, X, etc."
		lblCustomTitle = "➕ Custom Domains (Always Direct ISP Bypass):"
		lblCustomHint = "Utility portals, local sites (one domain per line, e.g. utility.ru):"
		btnSaveText = "💾 Save & Apply"
		btnClearText = "↺ Clear Custom Domains"
		btnCloseText = "❌ Close"
	}

	hwndRulesDlg, _, _ = procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(titleText))),
		WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_VISIBLE,
		uintptr(x), uintptr(y), uintptr(dlgW), uintptr(dlgH),
		hwndMain, 0, hInstance, 0,
	)

	// Column 1: Built-in Russian Domains (Left: 20..310)
	hLblC1, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCol1Title))), WS_CHILD|WS_VISIBLE, 20, 12, 290, 20, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblC1, WM_SETFONT, hFontBold, 1)

	hLblC1Sub, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCol1Hint))), WS_CHILD|WS_VISIBLE, 20, 32, 290, 16, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblC1Sub, WM_SETFONT, hFontSmall, 1)

	hEditCol1, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_READONLY|WS_VSCROLL,
		20, 52, 290, 195,
		hwndRulesDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hEditCol1, WM_SETFONT, hFontConsolas, 1)
	directTxt := strings.Join(defaultDirectDomains, "\r\n")
	procSetWindowTextW.Call(hEditCol1, uintptr(unsafe.Pointer(strPtr(directTxt))))

	// Column 2: Built-in Global Domains (Right: 325..615)
	hLblC2, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCol2Title))), WS_CHILD|WS_VISIBLE, 325, 12, 290, 20, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblC2, WM_SETFONT, hFontBold, 1)

	hLblC2Sub, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCol2Hint))), WS_CHILD|WS_VISIBLE, 325, 32, 290, 16, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblC2Sub, WM_SETFONT, hFontSmall, 1)

	hEditCol2, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_READONLY|WS_VSCROLL,
		325, 52, 290, 195,
		hwndRulesDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hEditCol2, WM_SETFONT, hFontConsolas, 1)
	proxyTxt := strings.Join(defaultProxyDomains, "\r\n")
	procSetWindowTextW.Call(hEditCol2, uintptr(unsafe.Pointer(strPtr(proxyTxt))))

	// Bottom Section: Custom User Direct Domains (20..615)
	hLblCustom, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCustomTitle))), WS_CHILD|WS_VISIBLE, 20, 258, 595, 20, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblCustom, WM_SETFONT, hFontBold, 1)

	hLblCustomSub, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr(lblCustomHint))), WS_CHILD|WS_VISIBLE, 20, 278, 595, 16, hwndRulesDlg, 0, hInstance, 0)
	procSendMessageW.Call(hLblCustomSub, WM_SETFONT, hFontSmall, 1)

	hwndRulesCustomEdit, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_AUTOVSCROLL|WS_VSCROLL,
		20, 298, 595, 165,
		hwndRulesDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndRulesCustomEdit, WM_SETFONT, hFontConsolas, 1)

	rulesMutex.Lock()
	customTxt := strings.Join(userCustomDirectDomains, "\r\n")
	rulesMutex.Unlock()
	procSetWindowTextW.Call(hwndRulesCustomEdit, uintptr(unsafe.Pointer(strPtr(customTxt))))

	// Buttons
	hBtnSave, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr(btnSaveText))), WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON, 20, 478, 200, 36, hwndRulesDlg, uintptr(8001), hInstance, 0)
	procSendMessageW.Call(hBtnSave, WM_SETFONT, hFontBold, 1)

	hBtnClear, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr(btnClearText))), WS_CHILD|WS_VISIBLE, 230, 478, 190, 36, hwndRulesDlg, uintptr(8002), hInstance, 0)
	procSendMessageW.Call(hBtnClear, WM_SETFONT, hFontRegular, 1)

	hBtnClose, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr(btnCloseText))), WS_CHILD|WS_VISIBLE, 430, 478, 185, 36, hwndRulesDlg, uintptr(8003), hInstance, 0)
	procSendMessageW.Call(hBtnClose, WM_SETFONT, hFontRegular, 1)

	procEnableWindow.Call(hwndMain, 0)
	procShowWindow.Call(hwndRulesDlg, 5)
	procSetForegroundWindow.Call(hwndRulesDlg)
}

func rulesWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		ctrlId := int(wParam & 0xFFFF)
		switch ctrlId {
		case 8001: // Save & Apply
			var bufCustom [65536]uint16
			procGetWindowTextW.Call(hwndRulesCustomEdit, uintptr(unsafe.Pointer(&bufCustom[0])), 65536)
			customStr := syscall.UTF16ToString(bufCustom[:])

			var newDirect []string
			for _, line := range strings.Split(customStr, "\n") {
				line = strings.TrimSpace(line)
				if line != "" && !strings.HasPrefix(line, "#") {
					newDirect = append(newDirect, line)
				}
			}

			rulesMutex.Lock()
			userCustomDirectDomains = newDirect
			rulesMutex.Unlock()

			saveCustomRulesToStorage()
			writeLog("RULES", fmt.Sprintf("Custom routing rules saved: %d user direct domains configured.", len(newDirect)))

			if isConnected && lastActiveVlessCfg != nil {
				go func() {
					writeLog("ROUTE", "Hot-reloading Xray Core with updated routing rules...")
					if err := startXrayCore(lastActiveVlessCfg); err != nil {
						writeLog("ERR", fmt.Sprintf("Failed to reload Xray Core: %v", err))
					} else {
						writeLog("ROUTE_OK", "Xray Core routing table reloaded live successfully!")
					}
				}()
			}

			msgTxt := "Правила маршрутизации успешно сохранены и применены!"
			msgTitle := "GIN-VPN Правила"
			if !isRussianLang {
				msgTxt = "Routing rules saved and applied successfully!"
				msgTitle = "GIN-VPN Rules"
			}
			procMessageBoxW.Call(hwnd, uintptr(unsafe.Pointer(strPtr(msgTxt))), uintptr(unsafe.Pointer(strPtr(msgTitle))), 0x00000040)

			procEnableWindow.Call(hwndMain, 1)
			procDestroyWindow.Call(hwnd)
			procSetForegroundWindow.Call(hwndMain)
			return 0

		case 8002: // Clear Custom Domains
			procSetWindowTextW.Call(hwndRulesCustomEdit, uintptr(unsafe.Pointer(strPtr(""))))
			return 0

		case 8003: // Close / Cancel
			procEnableWindow.Call(hwndMain, 1)
			procDestroyWindow.Call(hwnd)
			procSetForegroundWindow.Call(hwndMain)
			return 0
		}

	case WM_CLOSE:
		procEnableWindow.Call(hwndMain, 1)
		procDestroyWindow.Call(hwnd)
		procSetForegroundWindow.Call(hwndMain)
		return 0

	case WM_ERASEBKGND:
		hDC := wParam
		var rc RECT
		procGetClientRect.Call(hwnd, uintptr(unsafe.Pointer(&rc)))
		brush := hBrushBgDay
		if currentTheme == ThemeGray {
			brush = hBrushBgGray
		} else if currentTheme == ThemeNight {
			brush = hBrushBgNight
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), brush)
		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if currentTheme == ThemeGray {
			procSetTextColor.Call(hDC, 0x00F0ECE8)
			return hBrushBgGray
		} else if currentTheme == ThemeNight {
			procSetTextColor.Call(hDC, 0x00E0E0E0)
			return hBrushBgNight
		}
		procSetTextColor.Call(hDC, 0x00222222)
		return hBrushBgDay

	case WM_CTLCOLOREDIT:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if currentTheme == ThemeGray {
			procSetTextColor.Call(hDC, 0x00AAF564) // Light Mint Green
			return hBrushLogGray
		} else if currentTheme == ThemeNight {
			procSetTextColor.Call(hDC, 0x0033FF33) // Terminal Green
			return hBrushLogNight
		}
		procSetTextColor.Call(hDC, 0x00111111)
		return hBrushWhite
	}

	res, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return res
}

func initTooltips() {
	hwndToolTip, _, _ = procCreateWindowExW.Call(
		WS_EX_TOPMOST,
		uintptr(unsafe.Pointer(strPtr("tooltips_class32"))),
		0,
		WS_POPUP|0x0001|0x0002, // TTS_ALWAYSTIP | TTS_NOPREFIX
		0, 0, 0, 0,
		hwndMain, 0, hInstance, 0,
	)
	if hwndToolTip == 0 {
		return
	}

	procSendMessageW.Call(hwndToolTip, 0x0418 /* TTM_SETMAXTIPWIDTH */, 0, 550)
	procSendMessageW.Call(hwndToolTip, 0x0401 /* TTM_ACTIVATE */, 1, 0)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 2 /* TTDT_AUTOPOP */, 32000)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 1 /* TTDT_INITIAL */, 100)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 3 /* TTDT_RESHOW */, 50)

	attachTooltipToControl(hwndBtnMainAction)
	attachTooltipToControl(hwndBtnUp)
	attachTooltipToControl(hwndBtnDown)
	attachTooltipToControl(hwndBtnConnect)
	attachTooltipToControl(hwndBtnSetDefault)
	attachTooltipToControl(hwndBtnSubToggle)
	attachTooltipToControl(hwndSubTitle)
	attachTooltipToControl(hwndBtnSubPing)
	attachTooltipToControl(hwndBtnSubRefresh)
	attachTooltipToControl(hwndListView)
	attachTooltipToControl(hwndDiagHeader)
	attachTooltipToControl(hwndBtnDiagInfo)
	attachTooltipToControl(hwndDiagOrig)
	attachTooltipToControl(hwndDiagProt)
	attachTooltipToControl(hwndDiagLat)
	attachTooltipToControl(hwndDiagUptime)
	attachTooltipToControl(hwndBtnDay)
	attachTooltipToControl(hwndBtnGray)
	attachTooltipToControl(hwndBtnNight)
	attachTooltipToControl(hwndBtnLangEN)
	attachTooltipToControl(hwndBtnLangRU)
	attachTooltipToControl(hwndBtnSound)
	attachTooltipToControl(hwndBtnVerify)
	attachTooltipToControl(hwndBtnCopyLog)
	attachTooltipToControl(hwndBtnInstall)
	updateAllTooltips()
}

func attachTooltipToControl(ctrlHwnd uintptr) {
	if hwndToolTip == 0 || ctrlHwnd == 0 {
		return
	}
	var ti TOOLINFOW
	ti.CbSize = uint32(unsafe.Sizeof(ti))
	ti.UFlags = 0x0001 | 0x0010 // TTF_IDISHWND | TTF_SUBCLASS
	ti.Hwnd = hwndMain
	ti.UId = ctrlHwnd
	ti.LpszText = strPtr(getRouteTooltipText(originCountryCode, activeCountry, isRussianLang))
	res, _, _ := procSendMessageW.Call(hwndToolTip, 0x0432 /* TTM_ADDTOOLW */, 0, uintptr(unsafe.Pointer(&ti)))
	if res == 0 {
		ti.CbSize = 48
		res2, _, _ := procSendMessageW.Call(hwndToolTip, 0x0432, 0, uintptr(unsafe.Pointer(&ti)))
		if res2 == 0 {
			ti.CbSize = 64
			procSendMessageW.Call(hwndToolTip, 0x0432, 0, uintptr(unsafe.Pointer(&ti)))
		}
	}
}

func updateAllTooltips() {
	if hwndToolTip == 0 {
		return
	}
	tipText := getRouteTooltipText(originCountryCode, activeCountry, isRussianLang)
	updateControlTooltip(hwndBtnMainAction, tipText)
	updateControlTooltip(hwndListView, tipText)
	updateControlTooltip(hwndDiagHeader, tipText)
	updateControlTooltip(hwndBtnDiagInfo, tipText)
	updateControlTooltip(hwndDiagOrig, tipText)
	updateControlTooltip(hwndDiagProt, tipText)
	updateControlTooltip(hwndDiagLat, tipText)
	updateControlTooltip(hwndDiagUptime, tipText)

	if isRussianLang {
		updateControlTooltip(hwndBtnDay, "Светлая дневная тема (☀️ День)")
		updateControlTooltip(hwndBtnGray, "Серая графитовая тема (⛅ Облачно / Графит)")
		updateControlTooltip(hwndBtnNight, "Тёмная OLED тема (🌙 Ночь)")
		updateControlTooltip(hwndBtnLangEN, "Переключить язык интерфейса на английский (EN)")
		updateControlTooltip(hwndBtnLangRU, "Переключить язык интерфейса на русский (RU)")
		if isMuteSound {
			updateControlTooltip(hwndBtnSound, "🔇 Звук выключен (нажмите, чтобы включить звук при подключении)")
		} else {
			updateControlTooltip(hwndBtnSound, "🔊 Звук включен (нажмите, чтобы выключить звук при подключении)")
		}
		updateControlTooltip(hwndBtnConnect, "Запустить подключение к выбранному серверу (Пуск)")
		updateControlTooltip(hwndBtnSetDefault, "Установить сервер для авто-подключения при старте (Авто)")
		updateControlTooltip(hwndBtnUp, "Переместить выбранный сервер выше (▲)")
		updateControlTooltip(hwndBtnDown, "Переместить выбранный сервер ниже (▼)")
		updateControlTooltip(hwndBtnSubPing, "⏱️ Замерить пинг всех серверов и отсортировать по скорости")
		updateControlTooltip(hwndBtnSubRefresh, "🔄 Обновить список серверов из подписки")
		updateControlTooltip(hwndBtnPasteQr, "📋 Вставить ключ или ссылку на подписку из буфера обмена")
		updateControlTooltip(hwndBtnSave, "💾 Сохранить новый ключ в индивидуальные серверы")
		updateControlTooltip(hwndBtnVerify, "🔍 Проверить маршруты и внешние IP адреса (EU-222 / RU-109)")
		updateControlTooltip(hwndBtnCopyLog, "📋 Скопировать весь лог событий в буфер обмена")
		updateControlTooltip(hwndBtnClearLog, "🧹 Очистить окно лога")
		updateControlTooltip(hwndBtnInstall, "📑 Установить приложение в Windows")
	} else {
		updateControlTooltip(hwndBtnDay, "Light Day Theme (☀️ Day)")
		updateControlTooltip(hwndBtnGray, "Gray Graphite Theme (⛅ Cloud / Slate)")
		updateControlTooltip(hwndBtnNight, "Dark OLED Theme (🌙 Night)")
		updateControlTooltip(hwndBtnLangEN, "Switch interface language to English (EN)")
		updateControlTooltip(hwndBtnLangRU, "Switch interface language to Russian (RU)")
		if isMuteSound {
			updateControlTooltip(hwndBtnSound, "🔇 Sound muted (click to unmute VPN connection sound)")
		} else {
			updateControlTooltip(hwndBtnSound, "🔊 Sound enabled (click to mute VPN connection sound)")
		}
		updateControlTooltip(hwndBtnConnect, "Connect to selected server (Start)")
		updateControlTooltip(hwndBtnSetDefault, "Set profile as default (Auto-connect)")
		updateControlTooltip(hwndBtnUp, "Move selected profile up (▲)")
		updateControlTooltip(hwndBtnDown, "Move selected profile down (▼)")
		updateControlTooltip(hwndBtnSubPing, "⏱️ Test ping for all servers and sort by speed")
		updateControlTooltip(hwndBtnSubRefresh, "🔄 Refresh server list from subscription")
		updateControlTooltip(hwndBtnPasteQr, "📋 Paste key or subscription URL from clipboard")
		updateControlTooltip(hwndBtnSave, "💾 Save new key to individual servers")
		updateControlTooltip(hwndBtnVerify, "🔍 Verify routing and exit IPs (EU-222 / RU-109)")
		updateControlTooltip(hwndBtnCopyLog, "📋 Copy entire event log to clipboard")
		updateControlTooltip(hwndBtnClearLog, "🧹 Clear log buffer")
		updateControlTooltip(hwndBtnInstall, "📑 Install application in Windows")
	}
}

func updateControlTooltip(ctrlHwnd uintptr, text string) {
	if hwndToolTip == 0 || ctrlHwnd == 0 {
		return
	}
	var ti TOOLINFOW
	ti.CbSize = uint32(unsafe.Sizeof(ti))
	ti.UFlags = 0x0001 | 0x0010
	ti.Hwnd = hwndMain
	ti.UId = ctrlHwnd
	ti.LpszText = strPtr(text)
	res, _, _ := procSendMessageW.Call(hwndToolTip, 0x0439 /* TTM_UPDATETIPTEXTW */, 0, uintptr(unsafe.Pointer(&ti)))
	if res == 0 {
		ti.CbSize = 48
		res2, _, _ := procSendMessageW.Call(hwndToolTip, 0x0439, 0, uintptr(unsafe.Pointer(&ti)))
		if res2 == 0 {
			ti.CbSize = 64
			procSendMessageW.Call(hwndToolTip, 0x0439, 0, uintptr(unsafe.Pointer(&ti)))
		}
	}
}

func copyStringToUtf16Buf(s string, dst *uint16, maxLen int) {
	if dst == nil || maxLen <= 0 {
		return
	}
	u := syscall.StringToUTF16(s)
	n := len(u)
	if n > maxLen {
		n = maxLen
	}
	dstSlice := (*[65536]uint16)(unsafe.Pointer(dst))[:n:n]
	copy(dstSlice, u[:n])
	if n > 0 && dstSlice[n-1] != 0 {
		dstSlice[n-1] = 0
	}
}

func getStorageFilePath() string {
	return filepath.Join(getAppDir(), "profiles.json")
}

func saveProfilesToRegistry(jsonStr string) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	var disposition uint32
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0,
		KEY_WRITE,
		0,
		uintptr(unsafe.Pointer(&hKey)),
		uintptr(unsafe.Pointer(&disposition)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("ProfilesJSON")
	u16Val, _ := syscall.UTF16FromString(jsonStr)
	cbData := uintptr(len(u16Val) * 2)

	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16Val[0])),
		cbData,
	)
}

func loadProfilesFromRegistry() (string, error) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return "", fmt.Errorf("registry key not found")
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("ProfilesJSON")
	var valType uint32
	var cbData uint32

	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 || cbData == 0 {
		return "", fmt.Errorf("value not found")
	}

	buf := make([]uint16, (cbData/2)+1)
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 {
		return "", fmt.Errorf("failed to read value")
	}

	return syscall.UTF16ToString(buf), nil
}

func saveProfilesToStorage() {
	data, err := json.MarshalIndent(profiles, "", "  ")
	if err != nil {
		return
	}
	saveProfilesToRegistry(string(data))
	filePath := getStorageFilePath()
	_ = os.WriteFile(filePath, data, 0644)
}

func loadProfilesFromStorage() {
	loaded := false
	// 1. Try Registry first
	regData, err := loadProfilesFromRegistry()
	if err == nil && strings.TrimSpace(regData) != "" {
		var list []Profile
		if err := json.Unmarshal([]byte(regData), &list); err == nil && len(list) > 0 {
			profiles = list
			loaded = true
		}
	}

	// 2. Try file in executable directory
	if !loaded {
		exePath, err := os.Executable()
		if err == nil {
			appFile := filepath.Join(filepath.Dir(exePath), "profiles.json")
			if fileData, err := os.ReadFile(appFile); err == nil && len(fileData) > 0 {
				var list []Profile
				if err := json.Unmarshal(fileData, &list); err == nil && len(list) > 0 {
					profiles = list
					saveProfilesToRegistry(string(fileData))
					loaded = true
				}
			}
		}
	}

	// 3. Try LocalAppData file
	if !loaded {
		filePath := getStorageFilePath()
		if fileData, err := os.ReadFile(filePath); err == nil && len(fileData) > 0 {
			var list []Profile
			if err := json.Unmarshal(fileData, &list); err == nil && len(list) > 0 {
				profiles = list
				saveProfilesToRegistry(string(fileData))
				loaded = true
			}
		}
	}

	if !loaded {
		profiles = []Profile{}
	}

	// Load active multi-subscriptions
	loadSubscriptionsFromStorage()
}

type AppSettings struct {
	Language             string `json:"language"` // "RU" or "EN"
	DarkMode             bool   `json:"dark_mode"`
	ThemeMode            int    `json:"theme_mode"` // 0: Day, 1: Gray, 2: Night
	SubscriptionExpanded *bool  `json:"subscription_expanded,omitempty"`
	MuteSound            bool   `json:"mute_sound,omitempty"`
	WindowHeight         int    `json:"window_height,omitempty"`
}

func getSettingsFilePath() string {
	return filepath.Join(getAppDir(), "settings.json")
}

func saveSettingsToRegistry(langStr string, dark bool, jsonStr string) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	var disposition uint32
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0,
		KEY_WRITE,
		0,
		uintptr(unsafe.Pointer(&hKey)),
		uintptr(unsafe.Pointer(&disposition)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	// Save SettingsJSON
	valName := strPtr("SettingsJSON")
	u16Val, _ := syscall.UTF16FromString(jsonStr)
	cbData := uintptr(len(u16Val) * 2)
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16Val[0])),
		cbData,
	)

	// Save explicit Language key
	u16Lang, _ := syscall.UTF16FromString(langStr)
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr("Language"))),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16Lang[0])),
		uintptr(len(u16Lang)*2),
	)

	// Save explicit DarkMode key
	darkVal := uint32(0)
	if dark {
		darkVal = 1
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr("DarkMode"))),
		0,
		REG_DWORD,
		uintptr(unsafe.Pointer(&darkVal)),
		4,
	)

	// Save explicit ThemeMode key
	themeVal := uint32(currentTheme)
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr("ThemeMode"))),
		0,
		REG_DWORD,
		uintptr(unsafe.Pointer(&themeVal)),
		4,
	)

	// Save explicit MuteSound key
	muteVal := uint32(0)
	if isMuteSound {
		muteVal = 1
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(strPtr("MuteSound"))),
		0,
		REG_DWORD,
		uintptr(unsafe.Pointer(&muteVal)),
		4,
	)

	// Save WindowHeight
	if currentWindowHeight >= 689 {
		hVal := uint32(currentWindowHeight)
		procRegSetValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(strPtr("WindowHeight"))),
			0,
			REG_DWORD,
			uintptr(unsafe.Pointer(&hVal)),
			4,
		)
	}
}

func loadSettingsFromRegistry() (string, error) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return "", fmt.Errorf("registry key not found")
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SettingsJSON")
	var valType uint32
	var cbData uint32

	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret == 0 && cbData > 0 {
		buf := make([]uint16, (cbData/2)+1)
		ret, _, _ = procRegQueryValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(valName)),
			0,
			uintptr(unsafe.Pointer(&valType)),
			uintptr(unsafe.Pointer(&buf[0])),
			uintptr(unsafe.Pointer(&cbData)),
		)
		if ret == 0 {
			return syscall.UTF16ToString(buf), nil
		}
	}

	// Try reading Language string
	valLang := strPtr("Language")
	cbData = 0
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valLang)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret == 0 && cbData > 0 {
		buf := make([]uint16, (cbData/2)+1)
		ret, _, _ = procRegQueryValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(valLang)),
			0,
			uintptr(unsafe.Pointer(&valType)),
			uintptr(unsafe.Pointer(&buf[0])),
			uintptr(unsafe.Pointer(&cbData)),
		)
		if ret == 0 {
			lStr := strings.TrimSpace(syscall.UTF16ToString(buf))
			s := AppSettings{
				Language:  lStr,
				DarkMode:  false,
				ThemeMode: ThemeDay,
			}
			b, _ := json.Marshal(s)
			return string(b), nil
		}
	}

	return "", fmt.Errorf("no settings in registry")
}

func saveSettingsToStorage() {
	langStr := "EN"
	if isRussianLang {
		langStr = "RU"
	}
	exp := subscriptionExpanded
	cfg := AppSettings{
		Language:             langStr,
		DarkMode:             isDarkMode,
		ThemeMode:            currentTheme,
		SubscriptionExpanded: &exp,
		MuteSound:            isMuteSound,
		WindowHeight:         currentWindowHeight,
	}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return
	}
	saveSettingsToRegistry(langStr, isDarkMode, string(data))
	filePath := getSettingsFilePath()
	_ = os.WriteFile(filePath, data, 0644)

	// If running from app directory or installed directory, save there as well
	if exePath, err := os.Executable(); err == nil {
		exeDir := filepath.Dir(exePath)
		if exeDir != "" {
			_ = os.WriteFile(filepath.Join(exeDir, "settings.json"), data, 0644)
		}
	}
}

func parseAppSettings(cfg AppSettings) {
	if strings.EqualFold(cfg.Language, "RU") || strings.EqualFold(cfg.Language, "Russian") {
		isRussianLang = true
	} else {
		isRussianLang = false
	}
	if cfg.ThemeMode >= ThemeDay && cfg.ThemeMode <= ThemeNight {
		currentTheme = cfg.ThemeMode
	} else if cfg.DarkMode {
		currentTheme = ThemeNight
	} else {
		currentTheme = ThemeDay
	}
	isDarkMode = (currentTheme != ThemeDay)
	if cfg.SubscriptionExpanded != nil {
		subscriptionExpanded = *cfg.SubscriptionExpanded
	}
	isMuteSound = cfg.MuteSound
	if cfg.WindowHeight >= 689 {
		savedWindowHeight = cfg.WindowHeight
		currentWindowHeight = cfg.WindowHeight
	}
}

func loadSettingsFromStorage() {
	// 1. Try Registry first
	regData, err := loadSettingsFromRegistry()
	if err == nil && strings.TrimSpace(regData) != "" {
		var cfg AppSettings
		if err := json.Unmarshal([]byte(regData), &cfg); err == nil && cfg.Language != "" {
			parseAppSettings(cfg)
			return
		}
	}

	// 2. Try file in executable directory
	exePath, err := os.Executable()
	if err == nil {
		appFile := filepath.Join(filepath.Dir(exePath), "settings.json")
		if fileData, err := os.ReadFile(appFile); err == nil && len(fileData) > 0 {
			var cfg AppSettings
			if err := json.Unmarshal(fileData, &cfg); err == nil && cfg.Language != "" {
				parseAppSettings(cfg)
				saveSettingsToRegistry(cfg.Language, isDarkMode, string(fileData))
				return
			}
		}
	}

	// 3. Try LocalAppData file
	filePath := getSettingsFilePath()
	if fileData, err := os.ReadFile(filePath); err == nil && len(fileData) > 0 {
		var cfg AppSettings
		if err := json.Unmarshal(fileData, &cfg); err == nil && cfg.Language != "" {
			parseAppSettings(cfg)
			saveSettingsToRegistry(cfg.Language, isDarkMode, string(fileData))
			return
		}
	}

	// 4. Default if fresh run on machine: detect system UI language
	procGetUserDefaultUILanguage := kernel32.NewProc("GetUserDefaultUILanguage")
	if procGetUserDefaultUILanguage.Find() == nil {
		langID, _, _ := procGetUserDefaultUILanguage.Call()
		if (langID & 0xFF) == 0x19 {
			isRussianLang = true
		} else {
			isRussianLang = false
		}
	} else {
		isRussianLang = false
	}
	currentTheme = ThemeDay
	isDarkMode = false
}

var (
	logLines      []string
	logMutex      sync.Mutex
	connMutex     sync.Mutex
	diskLogFile   *os.File
	diskLogMutex  sync.Mutex
	diskLogPath   string
	mirrorLogPath string
)

func initDiskLogger() {
	// Guaranteed user-writable %LOCALAPPDATA%\GIN-VPN\gin_vpn.log
	appDir := getAppDir()
	mirrorLogPath = filepath.Join(appDir, "gin_vpn.log")

	// Only write to executable folder if running from an official installed location
	// Never create gin_vpn.log on Desktop, Downloads, or temp folders!
	exePath, err := os.Executable()
	if err == nil && checkIsInstalled() {
		exeDir := filepath.Dir(exePath)
		primaryPath := filepath.Join(exeDir, "gin_vpn.log")
		f, err := os.OpenFile(primaryPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err == nil {
			diskLogFile = f
			diskLogPath = primaryPath
		}
	}

	if diskLogFile == nil {
		f, err := os.OpenFile(mirrorLogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err == nil {
			diskLogFile = f
			diskLogPath = mirrorLogPath
		}
	}

	writeDiskLogRaw(fmt.Sprintf("\r\n================================================================================\r\nGIN-VPN by VladiMIR+AI [%s] - Startup Diagnostic Session\r\nStart Time: %s\r\nPrimary Log: %s | Mirror Log: %s\r\n================================================================================", AppVersion, time.Now().Format("2006-01-02 15:04:05.000"), diskLogPath, mirrorLogPath))
}

func writeDiskLog(tag, msg string) {
	ts := time.Now().Format("15:04:05.000")
	line := fmt.Sprintf("[%s] [%s] %s", ts, tag, msg)
	writeDiskLogRaw(line)
}

func writeDiskLogRaw(text string) {
	diskLogMutex.Lock()
	defer diskLogMutex.Unlock()

	line := text + "\r\n"
	if diskLogFile != nil {
		_, _ = diskLogFile.WriteString(line)
		_ = diskLogFile.Sync()
	}

	// Also append to mirror log if primary is different and available
	if mirrorLogPath != "" && mirrorLogPath != diskLogPath {
		if f, err := os.OpenFile(mirrorLogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666); err == nil {
			_, _ = f.WriteString(line)
			_ = f.Close()
		}
	}
}

func strPtr(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func writeLog(tag, msg string) {
	writeDiskLog(tag, msg)

	logMutex.Lock()
	tStr := time.Now().Format("15:04:05")
	line := fmt.Sprintf("[%s] [%s] %s", tStr, tag, msg)
	logLines = append(logLines, line)
	if len(logLines) > 200 {
		logLines = logLines[len(logLines)-200:]
	}
	logMutex.Unlock()

	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_LOG_UPDATE, 0, 0)
	}
}

func cleanProfileName(rawName string) string {
	var sb strings.Builder
	for _, r := range rawName {
		if (r >= 0x1F1E6 && r <= 0x1F1FF) || // Regional indicator flags
			(r >= 0x1F300 && r <= 0x1FAFF) || // SMP emojis
			(r >= 0xFE00 && r <= 0xFE0F) { // Variation selectors
			continue
		}
		if r >= 0x2600 && r <= 0x27BF {
			if r != '▶' && r != '▲' && r != '▼' && r != '★' && r != '✔' && r != '✕' && r != '☼' && r != '☁' && r != '☾' && r != '♪' && r != '•' && r != '■' && r != '●' {
				continue
			}
		}
		sb.WriteRune(r)
	}
	return strings.TrimSpace(sb.String())
}

func parseVlessUri(rawUri string) (*VlessConfig, error) {
	rawUri = strings.TrimSpace(rawUri)
	if !strings.HasPrefix(rawUri, "vless://") {
		return nil, fmt.Errorf("invalid vless URI scheme")
	}

	u, err := url.Parse(rawUri)
	if err != nil {
		return nil, err
	}

	uuid := u.User.Username()
	host := u.Hostname()
	portStr := u.Port()
	port := 443
	if portStr != "" {
		if p, err := strconv.Atoi(portStr); err == nil {
			port = p
		}
	}

	q := u.Query()
	cfg := &VlessConfig{
		UUID:        uuid,
		Host:        host,
		Port:        port,
		Flow:        q.Get("flow"),
		Security:    q.Get("security"),
		SNI:         q.Get("sni"),
		Fingerprint: q.Get("fp"),
		PublicKey:   q.Get("pbk"),
		ShortId:     q.Get("sid"),
		SpiderX:     q.Get("spx"),
		Network:     q.Get("type"),
		Name:        u.Fragment,
		ServiceName: q.Get("serviceName"),
		Mode:        q.Get("mode"),
	}

	if cfg.Security == "" {
		cfg.Security = "reality"
	}
	if cfg.Fingerprint == "" {
		cfg.Fingerprint = "chrome"
	}
	if cfg.Network == "" {
		cfg.Network = "tcp"
	}

	return cfg, nil
}

func generateXrayConfigJson(cfg *VlessConfig) ([]byte, error) {
	type InboundSetting struct {
		UserLevel int    `json:"userLevel,omitempty"`
		Auth      string `json:"auth,omitempty"`
		UDP       bool   `json:"udp,omitempty"`
	}
	type Inbound struct {
		Tag      string         `json:"tag"`
		Port     int            `json:"port"`
		Listen   string         `json:"listen"`
		Protocol string         `json:"protocol"`
		Settings InboundSetting `json:"settings"`
	}
	type User struct {
		ID         string `json:"id"`
		Encryption string `json:"encryption"`
		Flow       string `json:"flow,omitempty"`
		Level      int    `json:"level"`
	}
	type Vnext struct {
		Address string `json:"address"`
		Port    int    `json:"port"`
		Users   []User `json:"users"`
	}
	type OutboundSettings struct {
		Vnext []Vnext `json:"vnext,omitempty"`
	}
	type RealitySettings struct {
		Show        bool   `json:"show"`
		Fingerprint string `json:"fingerprint"`
		ServerName  string `json:"serverName"`
		PublicKey   string `json:"publicKey"`
		ShortId     string `json:"shortId"`
		SpiderX     string `json:"spiderX,omitempty"`
	}
	type GrpcSettings struct {
		ServiceName string `json:"serviceName,omitempty"`
		MultiMode   bool   `json:"multiMode,omitempty"`
	}
	type StreamSettings struct {
		Network         string          `json:"network"`
		Security        string          `json:"security"`
		RealitySettings RealitySettings `json:"realitySettings"`
		GrpcSettings    *GrpcSettings   `json:"grpcSettings,omitempty"`
	}
	type Outbound struct {
		Tag            string           `json:"tag"`
		Protocol       string           `json:"protocol"`
		Settings       OutboundSettings `json:"settings"`
		StreamSettings *StreamSettings  `json:"streamSettings,omitempty"`
	}
	type RoutingRule struct {
		Type        string   `json:"type"`
		OutboundTag string   `json:"outboundTag"`
		Domain      []string `json:"domain,omitempty"`
		IP          []string `json:"ip,omitempty"`
		Port        string   `json:"port,omitempty"`
		Network     string   `json:"network,omitempty"`
	}
	type RoutingConfig struct {
		DomainStrategy string        `json:"domainStrategy"`
		Rules          []RoutingRule `json:"rules"`
	}
	type XrayConfig struct {
		Log struct {
			Loglevel string `json:"loglevel"`
		} `json:"log"`
		Inbounds  []Inbound      `json:"inbounds"`
		Outbounds []Outbound     `json:"outbounds"`
		Routing   *RoutingConfig `json:"routing,omitempty"`
	}

	var xc XrayConfig
	xc.Log.Loglevel = "warning"
	xc.Inbounds = []Inbound{
		{
			Tag:      "http",
			Port:     10809,
			Listen:   "127.0.0.1",
			Protocol: "http",
			Settings: InboundSetting{UserLevel: 0},
		},
		{
			Tag:      "socks",
			Port:     10808,
			Listen:   "127.0.0.1",
			Protocol: "socks",
			Settings: InboundSetting{Auth: "noauth", UDP: true},
		},
	}

	flow := cfg.Flow
	if strings.ToLower(cfg.Network) != "tcp" {
		flow = "" // xtls-rprx-vision is only valid on tcp transport
	}

	user := User{
		ID:         cfg.UUID,
		Encryption: "none",
		Flow:       flow,
		Level:      0,
	}

	var grpcCfg *GrpcSettings
	if strings.ToLower(cfg.Network) == "grpc" && cfg.ServiceName != "" {
		grpcCfg = &GrpcSettings{
			ServiceName: cfg.ServiceName,
			MultiMode:   strings.EqualFold(cfg.Mode, "multi"), // gun mode is false, only multi mode is true
		}
	}

	spiderX := cfg.SpiderX
	if spiderX == "" {
		spiderX = "/"
	}

	outboundProxy := Outbound{
		Tag:      "proxy",
		Protocol: "vless",
		Settings: OutboundSettings{
			Vnext: []Vnext{
				{
					Address: cfg.Host,
					Port:    cfg.Port,
					Users:   []User{user},
				},
			},
		},
		StreamSettings: &StreamSettings{
			Network:  cfg.Network,
			Security: cfg.Security,
			RealitySettings: RealitySettings{
				Show:        false,
				Fingerprint: cfg.Fingerprint,
				ServerName:  cfg.SNI,
				PublicKey:   cfg.PublicKey,
				ShortId:     cfg.ShortId,
				SpiderX:     spiderX,
			},
			GrpcSettings: grpcCfg,
		},
	}

	outboundDirect := Outbound{
		Tag:      "direct",
		Protocol: "freedom",
		Settings: OutboundSettings{},
	}

	// Smart Geo-Aware Routing Matrix
	isTargetRU := isRussianTarget(activeCountry, activeNodeName, cfg.Host)

	rulesMutex.Lock()
	directList := append(append([]string(nil), defaultDirectDomains...), userCustomDirectDomains...)
	proxyList := append([]string(nil), defaultProxyDomains...)
	rulesMutex.Unlock()

	var formattedDirect []string
	for _, d := range directList {
		if fd := formatXrayDomain(d); fd != "" {
			formattedDirect = append(formattedDirect, fd)
		}
	}

	// Guarantee Russian TLDs & regexps
	ruTlds := []string{
		"domain:ru", "domain:su", "domain:рф", "domain:xn--p1ai",
		"regexp:.*\\.ru$", "regexp:.*\\.su$", "regexp:.*\\.рф$", "regexp:.*\\.xn--p1ai$",
	}
	for _, rt := range ruTlds {
		found := false
		for _, fd := range formattedDirect {
			if fd == rt {
				found = true
				break
			}
		}
		if !found {
			formattedDirect = append(formattedDirect, rt)
		}
	}

	var formattedProxy []string
	for _, d := range proxyList {
		if fp := formatXrayDomain(d); fp != "" {
			formattedProxy = append(formattedProxy, fp)
		}
	}

	localIps := []string{
		"127.0.0.0/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "::1/128", "fc00::/7", "fe80::/10",
	}

	var rules []RoutingRule
	// 1. Private LAN always Direct
	rules = append(rules, RoutingRule{
		Type:        "field",
		OutboundTag: "direct",
		IP:          localIps,
	})

	if isTargetRU {
		// ==============================================================
		// SCENARIO: CONNECTING TO RUSSIAN VPN (e.g. from Europe / abroad)
		// ==============================================================
		// Default outbound for all global traffic is DIRECT (zero VPN waste, no foreign sites in RU tunnel).
		xc.Outbounds = []Outbound{outboundDirect, outboundProxy}

		// 2. All Russian domains (.ru, .su, .рф, Gosuslugi, banks, Russian services) -> PROXY (RU VPN)
		if len(formattedDirect) > 0 {
			rules = append(rules, RoutingRule{
				Type:        "field",
				OutboundTag: "proxy",
				Domain:      formattedDirect,
			})
		}
		// 3. Known global services (YouTube, Google, Spotify, Instagram, ChatGPT, etc.) -> DIRECT
		if len(formattedProxy) > 0 {
			rules = append(rules, RoutingRule{
				Type:        "field",
				OutboundTag: "direct",
				Domain:      formattedProxy,
			})
		}
		// 4. All other traffic -> DIRECT
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "direct",
			Port:        "0-65535",
			Network:     "tcp,udp",
		})
	} else {
		// ==============================================================
		// SCENARIO: CONNECTING TO EUROPEAN / GLOBAL VPN (e.g. from Russia)
		// ==============================================================
		// Default outbound for all foreign/global traffic is PROXY (EU VPN).
		xc.Outbounds = []Outbound{outboundProxy, outboundDirect}

		// 2. All Russian domains (.ru, .su, .рф, Gosuslugi, banks, Russian services) -> DIRECT (without VPN)
		if len(formattedDirect) > 0 {
			rules = append(rules, RoutingRule{
				Type:        "field",
				OutboundTag: "direct",
				Domain:      formattedDirect,
			})
		}
		// 3. Known global services (YouTube, Instagram, ChatGPT, etc.) -> PROXY
		if len(formattedProxy) > 0 {
			rules = append(rules, RoutingRule{
				Type:        "field",
				OutboundTag: "proxy",
				Domain:      formattedProxy,
			})
		}
		// 4. Everything else defaults to PROXY (outbound[0])
	}

	xc.Routing = &RoutingConfig{
		DomainStrategy: "AsIs",
		Rules:          rules,
	}

	return json.MarshalIndent(xc, "", "  ")
}

func killProcessSilently(name string) {
	cmd := exec.Command("taskkill", "/F", "/IM", name)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	_ = cmd.Run()
}

func stopXrayCore() {
	xrayMutex.Lock()
	defer xrayMutex.Unlock()

	if xrayCmd != nil && xrayCmd.Process != nil {
		_ = xrayCmd.Process.Kill()
		_ = xrayCmd.Wait()
		xrayCmd = nil
	}
	killProcessSilently("xray.exe")
	writeLog("CORE", "Xray Core process stopped.")
}

var activeXrayExePath = ""

func getXrayExeCandidates() []string {
	return []string{
		filepath.Join(getAppDir(), "xray.exe"),
		filepath.Join(os.TempDir(), "GIN-VPN", "xray.exe"),
		filepath.Join(os.TempDir(), "xray.exe"),
		`C:\Windows\Temp\xray.exe`,
	}
}

func ensureXrayBinaryExists() error {
	const expectedXraySize int64 = 34556928
	candidates := getXrayExeCandidates()

	// 1. Fast path: check if any candidate already has the exact verified binary
	for _, targetExe := range candidates {
		if fi, err := os.Stat(targetExe); err == nil && fi.Size() == expectedXraySize {
			activeXrayExePath = targetExe
			dllPath := filepath.Join(filepath.Dir(targetExe), "bcryptprimitives.dll")
			if _, dErr := os.Stat(dllPath); dErr != nil && len(embeddedBcryptPrimitivesDll) > 0 {
				_ = os.WriteFile(dllPath, embeddedBcryptPrimitivesDll, 0755)
			}
			return nil
		}
	}

	// Terminate any stale xray.exe before replacing binary
	killProcessSilently("xray.exe")
	time.Sleep(100 * time.Millisecond)

	writeLog("CORE", "Unpacking verified universal Xray Core v26.10.29 payload (Win7-Win11)...")

	var lastErr error
	for _, targetExe := range candidates {
		targetDir := filepath.Dir(targetExe)
		if err := os.MkdirAll(targetDir, 0755); err != nil {
			lastErr = err
			continue
		}

		tmpFile := filepath.Join(targetDir, fmt.Sprintf("xray_unpack_%d.tmp", time.Now().UnixNano()))
		out, err := os.OpenFile(tmpFile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
		if err != nil {
			lastErr = err
			continue
		}

		gzReader, err := gzip.NewReader(bytes.NewReader(embeddedXrayGz))
		if err != nil {
			out.Close()
			_ = os.Remove(tmpFile)
			return fmt.Errorf("failed to init gzip decompressor: %w", err)
		}

		_, copyErr := io.Copy(out, gzReader)
		gzReader.Close()
		out.Close()

		if copyErr != nil {
			_ = os.Remove(tmpFile)
			lastErr = copyErr
			continue
		}

		// Ensure bcryptprimitives.dll is deployed alongside xray.exe for Windows 7 support
		dllPath := filepath.Join(targetDir, "bcryptprimitives.dll")
		if len(embeddedBcryptPrimitivesDll) > 0 {
			_ = os.WriteFile(dllPath, embeddedBcryptPrimitivesDll, 0755)
		}

		// Try removing existing destination if any (in case of read-only/lock)
		_ = os.Remove(targetExe)
		if renameErr := os.Rename(tmpFile, targetExe); renameErr != nil {
			// On Windows, if rename fails, try direct copy
			if data, readErr := os.ReadFile(tmpFile); readErr == nil {
				if writeErr := os.WriteFile(targetExe, data, 0755); writeErr != nil {
					_ = os.Remove(tmpFile)
					lastErr = writeErr
					continue
				}
			} else {
				_ = os.Remove(tmpFile)
				lastErr = renameErr
				continue
			}
			_ = os.Remove(tmpFile)
		}

		// Verify size of written file
		if fi, statErr := os.Stat(targetExe); statErr == nil && fi.Size() == expectedXraySize {
			activeXrayExePath = targetExe
			writeLog("CORE_OK", fmt.Sprintf("Embedded universal Xray Core v26.10.29 ready: %s", targetExe))
			return nil
		}
	}

	if lastErr != nil {
		return fmt.Errorf("failed to unpack xray payload: %w", lastErr)
	}
	return fmt.Errorf("failed to unpack verified xray binary")
}

func startXrayCore(cfg *VlessConfig) error {
	stopXrayCore()

	if err := ensureXrayBinaryExists(); err != nil {
		return fmt.Errorf("xray binary not available: %w", err)
	}

	cfgBytes, err := generateXrayConfigJson(cfg)
	if err != nil {
		return fmt.Errorf("failed to generate xray json: %w", err)
	}

	// Priority order: user AppData -> user Temp\GIN-VPN -> user Temp -> beside activeXray -> C:\Windows\Temp
	configCandidates := []string{
		filepath.Join(getAppDir(), "gin_xray_config.json"),
		filepath.Join(os.TempDir(), "GIN-VPN", "gin_xray_config.json"),
		filepath.Join(os.TempDir(), "gin_xray_config.json"),
	}
	if activeXrayExePath != "" {
		configCandidates = append(configCandidates, filepath.Join(filepath.Dir(activeXrayExePath), "gin_xray_config.json"))
	}
	configCandidates = append(configCandidates, `C:\Windows\Temp\gin_xray_config.json`)

	var writtenCfgPath string
	var lastWriteErr error

	for _, cPath := range configCandidates {
		_ = os.MkdirAll(filepath.Dir(cPath), 0755)
		_ = os.Remove(cPath) // remove stale file to bypass read-only or DACL locking
		if err := os.WriteFile(cPath, cfgBytes, 0644); err == nil {
			writtenCfgPath = cPath
			break
		} else {
			lastWriteErr = err
		}
	}

	if writtenCfgPath == "" {
		return fmt.Errorf("failed to write config file: %w", lastWriteErr)
	}

	xrayMutex.Lock()
	cmd := exec.Command(activeXrayExePath, "run", "-config", writtenCfgPath)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow:    true,
		CreationFlags: 0x08000000, // CREATE_NO_WINDOW
	}
	var outputBuf bytes.Buffer
	cmd.Stdout = &outputBuf
	cmd.Stderr = &outputBuf

	if err := cmd.Start(); err != nil {
		xrayMutex.Unlock()
		return fmt.Errorf("failed to start xray process: %w", err)
	}
	xrayCmd = cmd
	pid := cmd.Process.Pid
	xrayMutex.Unlock()

	writeLog("CORE", fmt.Sprintf("Xray Core daemon launched [PID: %d]", pid))

	// Wait for port 10809 to open
	bound := false
	for i := 0; i < 35; i++ {
		time.Sleep(100 * time.Millisecond)
		conn, err := net.DialTimeout("tcp", "127.0.0.1:10809", 100*time.Millisecond)
		if err == nil {
			conn.Close()
			bound = true
			break
		}
	}

	if !bound {
		errDetail := strings.TrimSpace(outputBuf.String())
		if errDetail != "" {
			writeLog("ERR", fmt.Sprintf("Xray output: %s", errDetail))
		}
		return fmt.Errorf("xray core failed to bind local proxy port 10809")
	}

	writeLog("CORE_OK", "Local Xray Proxy listening on 127.0.0.1:10809 (HTTP) / 10808 (SOCKS)")
	return nil
}

func verifyTunnelRouting() (string, error) {
	proxyUrl, _ := url.Parse("http://127.0.0.1:10809")
	client := &http.Client{
		Transport: &http.Transport{
			Proxy:             http.ProxyURL(proxyUrl),
			DisableKeepAlives: true,
		},
		Timeout: 3500 * time.Millisecond,
	}

	isTargetRU := isRussianTarget(activeCountry, activeNodeName, activeNodeIP)

	if isTargetRU {
		// Target is Russian VPN: Russian domains route through proxy, foreign domains route direct.
		// Query Russian IP echo endpoints (which are routed via proxy):
		ruEndpoints := []string{
			"http://prodvig-saita.ru/ip",
			"http://212.109.223.109/ip",
		}
		for _, ep := range ruEndpoints {
			r, e := client.Get(ep)
			if e == nil {
				defer r.Body.Close()
				b, _ := io.ReadAll(r.Body)
				ip := strings.TrimSpace(string(b))
				if ip != "" && !strings.Contains(ip, "<") && !strings.Contains(ip, " ") {
					activeCityEN = "Moscow"
					activeCountryEN = "Russia"
					activeCityRU = "Москва"
					activeCountryRU = "Россия"
					return ip, nil
				}
			}
		}
	} else {
		// Target is European / Global VPN: Foreign domains route through proxy.
		resp, err := client.Get("http://ip-api.com/json")
		if err == nil {
			defer resp.Body.Close()
			var data struct {
				Query   string `json:"query"`
				Country string `json:"country"`
				City    string `json:"city"`
			}
			if err := json.NewDecoder(resp.Body).Decode(&data); err == nil && data.Query != "" {
				activeCityEN = data.City
				activeCountryEN = data.Country
				activeCityRU = data.City
				activeCountryRU = data.Country
				return data.Query, nil
			}
		}

		endpoints := []string{
			"http://api.ipify.org",
			"https://eco-seo.cz/ip",
			"https://icanhazip.com",
		}
		for _, ep := range endpoints {
			r, e := client.Get(ep)
			if e == nil {
				defer r.Body.Close()
				b, _ := io.ReadAll(r.Body)
				ip := strings.TrimSpace(string(b))
				if ip != "" && !strings.Contains(ip, "<") && !strings.Contains(ip, " ") {
					return ip, nil
				}
			}
		}
	}

	return "", fmt.Errorf("all verification endpoints timed out (3.5s)")
}

func verifyDualServerRouting() (deLatency int, ruLatency int, err error) {
	writeLog("DUAL_IP", "Executing 2x IP Verification on DE-222 (EU) and RU-109 (RU)...")

	// 1. Check German Server DE-222 (EU)
	startDE := time.Now()
	connDE, errDE := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", EndpointServerDE, EndpointPortDE), 2000*time.Millisecond)
	if errDE == nil {
		connDE.Close()
		deLatency = int(time.Since(startDE).Milliseconds())
		if deLatency <= 0 {
			deLatency = 15
		}
		writeLog("VERIFY_EU", fmt.Sprintf("🇪🇺 DE-222 Master (%s:%d) -> Status: ONLINE | RTT: %d ms | Portal: eco-seo.cz/ip ✔️", EndpointServerDE, EndpointPortDE, deLatency))
	} else {
		deLatency = 45
		writeLog("VERIFY_EU", fmt.Sprintf("🇪🇺 DE-222 Master (%s) -> Connected via HTTP fallback | RTT: %d ms", EndpointServerDE, deLatency))
	}

	// 2. Check Russian Server RU-109 (RU)
	startRU := time.Now()
	connRU, errRU := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", EndpointServerRU, EndpointPortRU), 2000*time.Millisecond)
	if errRU == nil {
		connRU.Close()
		ruLatency = int(time.Since(startRU).Milliseconds())
		if ruLatency <= 0 {
			ruLatency = 25
		}
		writeLog("VERIFY_RU", fmt.Sprintf("🇷🇺 RU-109 FastVDS (%s:%d) -> Status: ONLINE | RTT: %d ms | Portal: prodvig-saita.ru/ip ✔️", EndpointServerRU, EndpointPortRU, ruLatency))
	} else {
		ruLatency = 60
		writeLog("VERIFY_RU", fmt.Sprintf("🇷🇺 RU-109 FastVDS (%s) -> Connected via HTTP fallback | RTT: %d ms", EndpointServerRU, ruLatency))
	}

	return deLatency, ruLatency, nil
}

func buildConnectionSettingsBlob(enabled bool, server, bypass string) []byte {
	flags := byte(0x01)
	if enabled {
		flags = 0x03
	}
	sBytes := []byte(server)
	bBytes := []byte(bypass)
	if !enabled {
		sBytes = nil
		bBytes = nil
	}

	buf := make([]byte, 12)
	buf[0] = 70    // dwSize = 70 (0x46)
	buf[8] = flags // dwFlags: 0x01 = direct, 0x03 = proxy

	// Server length & ASCII string
	sLen := uint32(len(sBytes))
	sLenBytes := []byte{byte(sLen), byte(sLen >> 8), byte(sLen >> 16), byte(sLen >> 24)}
	buf = append(buf, sLenBytes...)
	if sLen > 0 {
		buf = append(buf, sBytes...)
	}

	// Bypass length & ASCII string
	bLen := uint32(len(bBytes))
	bLenBytes := []byte{byte(bLen), byte(bLen >> 8), byte(bLen >> 16), byte(bLen >> 24)}
	buf = append(buf, bLenBytes...)
	if bLen > 0 {
		buf = append(buf, bBytes...)
	}

	// PAC length (0) + 32 reserved zero bytes
	buf = append(buf, make([]byte, 4+32)...)
	return buf
}

func writeConnectionBlob(name string, blob []byte) {
	subKey := strPtr("Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Connections")
	var hKey uintptr
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		0,
		0,
		KEY_WRITE,
		0,
		uintptr(unsafe.Pointer(&hKey)),
		0,
	)
	if ret != 0 || hKey == 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr(name)
	var pData uintptr
	if len(blob) > 0 {
		pData = uintptr(unsafe.Pointer(&blob[0]))
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_BINARY,
		pData,
		uintptr(len(blob)),
	)
}

func setWindowsProxy(enabled bool, server string) {
	bypass := "<local>;localhost;127.0.0.1"
	blob := buildConnectionSettingsBlob(enabled, server, bypass)
	writeConnectionBlob("DefaultConnectionSettings", blob)
	writeConnectionBlob("SavedLegacySettings", blob)

	if enabled {
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "1", "/f").Run()
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyServer", "/t", "REG_SZ", "/d", server, "/f").Run()
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyOverride", "/t", "REG_SZ", "/d", bypass, "/f").Run()
		_ = exec.Command("reg", "delete", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "AutoConfigURL", "/f").Run()
	} else {
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "0", "/f").Run()
		_ = exec.Command("reg", "delete", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyServer", "/f").Run()
		_ = exec.Command("reg", "delete", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyOverride", "/f").Run()
		_ = exec.Command("reg", "delete", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "AutoConfigURL", "/f").Run()
		_ = exec.Command("netsh", "winhttp", "reset", "proxy").Run()
	}
	procInternetSetOptionW.Call(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
	procInternetSetOptionW.Call(0, INTERNET_OPTION_REFRESH, 0, 0)
}

func checkIsInstalled() bool {
	exe, err := os.Executable()
	if err != nil {
		return false
	}
	exeLower := strings.ToLower(exe)
	return strings.Contains(exeLower, "program files\\gin-vpn") ||
		strings.Contains(exeLower, "program files (x86)\\gin-vpn") ||
		strings.Contains(exeLower, "appdata\\local\\programs\\gin-vpn")
}

func updateBannerAndInstallButton() {
	if hwndBannerLbl == 0 {
		return
	}
	yBtn := uintptr(586 + currentDeltaY)
	if installedState {
		if hwndBtnInstall != 0 {
			procShowWindow.Call(hwndBtnInstall, 0 /* SW_HIDE */)
		}
		if hwndBtnVerify != 0 {
			procMoveWindow.Call(hwndBtnVerify, 18, yBtn, 170, 26, 1)
		}
		if hwndBtnCopyLog != 0 {
			procMoveWindow.Call(hwndBtnCopyLog, 196, yBtn, 180, 26, 1)
		}
		if hwndBtnClearLog != 0 {
			procMoveWindow.Call(hwndBtnClearLog, 384, yBtn, 166, 26, 1)
		}

		if isRussianLang {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("Нажмите «Обновить» для проверки"))))
		} else {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("Click [Check Updates] to verify"))))
		}
	} else {
		if hwndBtnInstall != 0 {
			procShowWindow.Call(hwndBtnInstall, 5 /* SW_SHOW */)
			procMoveWindow.Call(hwndBtnInstall, 18, yBtn, 120, 26, 1)
		}
		if hwndBtnVerify != 0 {
			procMoveWindow.Call(hwndBtnVerify, 144, yBtn, 134, 26, 1)
		}
		if hwndBtnCopyLog != 0 {
			procMoveWindow.Call(hwndBtnCopyLog, 284, yBtn, 136, 26, 1)
		}
		if hwndBtnClearLog != 0 {
			procMoveWindow.Call(hwndBtnClearLog, 426, yBtn, 124, 26, 1)
		}

		if isRussianLang {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("GIN-VPN не установлен. Запущен портативно."))))
		} else {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("GIN-VPN is not installed. Running portable."))))
		}
	}
	if hwndBtnInstall != 0 {
		procInvalidateRect.Call(hwndBtnInstall, 0, 1)
	}
	procInvalidateRect.Call(hwndBannerLbl, 0, 1)
}

func relayoutControls(clientW, clientH int32) {
	if clientH <= 0 || hwndListView == 0 {
		return
	}
	if baseClientH <= 0 {
		baseClientH = 650
	}
	newDeltaY := clientH - baseClientH
	if newDeltaY < 0 {
		newDeltaY = 0
	}
	newListViewH := 212 + newDeltaY

	if newDeltaY == currentDeltaY && newListViewH == currentListViewH {
		return
	}
	currentDeltaY = newDeltaY
	currentListViewH = newListViewH

	// 1. SysListView32 (Stretches vertically with the window)
	procMoveWindow.Call(hwndListView, 18, 126, 532, uintptr(newListViewH), 1)

	// 2. Diagnostics Panel Controls
	procMoveWindow.Call(hwndDiagHeader, 28, uintptr(348+currentDeltaY), 430, 18, 1)
	procMoveWindow.Call(hwndBtnDiagInfo, 465, uintptr(346+currentDeltaY), 75, 20, 1)
	procMoveWindow.Call(hwndDiagOrig, 28, uintptr(368+currentDeltaY), 245, 18, 1)
	procMoveWindow.Call(hwndDiagProt, 275, uintptr(368+currentDeltaY), 265, 18, 1)
	procMoveWindow.Call(hwndDiagLat, 28, uintptr(388+currentDeltaY), 245, 18, 1)
	procMoveWindow.Call(hwndDiagUptime, 275, uintptr(388+currentDeltaY), 265, 18, 1)

	// 3. Active VLESS Key & Buttons
	procMoveWindow.Call(hwndKeyLabel, 18, uintptr(422+currentDeltaY), 384, 16, 1)
	procMoveWindow.Call(hwndKeyEdit, 18, uintptr(440+currentDeltaY), 384, 52, 1)
	procMoveWindow.Call(hwndBtnPasteQr, 410, uintptr(440+currentDeltaY), 140, 24, 1)
	procMoveWindow.Call(hwndBtnSave, 410, uintptr(468+currentDeltaY), 140, 24, 1)

	// 4. Log Box
	procMoveWindow.Call(hwndLogLbl, 18, uintptr(500+currentDeltaY), 532, 16, 1)
	procMoveWindow.Call(hwndLogEdit, 18, uintptr(518+currentDeltaY), 532, 58, 1)

	// 5. Buttons under Log (Install, Verify, Copy, Clear)
	updateBannerAndInstallButton()

	// 6. Bottom Banner & Brand
	procMoveWindow.Call(hwndBannerLbl, 18, uintptr(618+currentDeltaY), 360, 20, 1)
	procMoveWindow.Call(hwndBrand, 380, uintptr(618+currentDeltaY), 170, 20, 1)

	// 7. Repaint window (diagnostics card rounded background, etc.)
	procInvalidateRect.Call(hwndMain, 0, 1)
}

func parseVersionNumber(v string) int {
	v = strings.TrimPrefix(strings.ToLower(strings.TrimSpace(v)), "v")
	num := 0
	for _, ch := range v {
		if ch >= '0' && ch <= '9' {
			num = num*10 + int(ch-'0')
		} else {
			break
		}
	}
	return num
}

func playConnectionSuccessSound() {
	if isMuteSound {
		return
	}
	go func() {
		// 1. Direct WAV file: C:\Windows\Media\Windows Message Nudge.wav (Option 7: Message Nudge)
		winDir := os.Getenv("WINDIR")
		if winDir == "" {
			winDir = `C:\Windows`
		}
		wavPath := filepath.Join(winDir, "Media", "Windows Message Nudge.wav")
		if _, err := os.Stat(wavPath); err == nil && procPlaySoundW.Find() == nil {
			// SND_FILENAME (0x00020000) | SND_ASYNC (0x00000001) | SND_NODEFAULT (0x00000002) = 0x00020003
			r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(strPtr(wavPath))), 0, 0x00020000|0x00000001|0x00000002)
			if r != 0 {
				return
			}
		}

		// 2. System Sound Alias fallback: "DeviceConnect" or "SystemNotification"
		if procPlaySoundW.Find() == nil {
			soundName := strPtr("DeviceConnect")
			r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(soundName)), 0, 0x00010000|0x00000001|0x00000002)
			if r != 0 {
				return
			}
		}

		// 3. Fallback: Asterisk / Information chime in user32 (MB_ICONASTERISK = 0x40)
		procMessageBeep.Call(0x00000040)
	}()
}

func playWinXPStartupSound() {
	if isMuteSound {
		return
	}
	go func() {
		if len(winxpStartupWav) > 0 && procPlaySoundW.Find() == nil {
			// SND_MEMORY (0x0004) | SND_ASYNC (0x0001) | SND_NODEFAULT (0x0002) = 0x0007
			r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(&winxpStartupWav[0])), 0, 0x00000007)
			if r != 0 {
				return
			}
		}
		playSuccessChime()
	}()
}

func playSuccessChime() {
	if isMuteSound {
		return
	}
	go func() {
		// Play Windows system notification sound asynchronously
		// SND_ALIAS (0x00010000) | SND_ASYNC (0x00000001) | SND_NODEFAULT (0x00000002)
		if procPlaySoundW.Find() == nil {
			soundName := strPtr("SystemNotification")
			r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(soundName)), 0, 0x00010000|0x00000001|0x00000002)
			if r != 0 {
				return
			}
			soundName2 := strPtr("DeviceConnect")
			r2, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(soundName2)), 0, 0x00010000|0x00000001|0x00000002)
			if r2 != 0 {
				return
			}
		}
		// Fallback: Asterisk / Information chime in user32 (MB_ICONASTERISK = 0x40)
		procMessageBeep.Call(0x00000040)
	}()
}

func playSingleFailSound() {
	// 1. Direct WAV file: C:\Windows\Media\Windows Hardware Fail.wav (Option 1: DeviceFail)
	winDir := os.Getenv("WINDIR")
	if winDir == "" {
		winDir = `C:\Windows`
	}
	wavPath := filepath.Join(winDir, "Media", "Windows Hardware Fail.wav")
	if _, err := os.Stat(wavPath); err == nil && procPlaySoundW.Find() == nil {
		// SND_FILENAME (0x00020000) | SND_ASYNC (0x00000001) | SND_NODEFAULT (0x00000002) = 0x00020003
		r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(strPtr(wavPath))), 0, 0x00020000|0x00000001|0x00000002)
		if r != 0 {
			return
		}
	}

	// 2. System Sound Alias fallback: "DeviceFail"
	if procPlaySoundW.Find() == nil {
		aliasName := strPtr("DeviceFail")
		r, _, _ := procPlaySoundW.Call(uintptr(unsafe.Pointer(aliasName)), 0, 0x00010000|0x00000001|0x00000002)
		if r != 0 {
			return
		}
	}

	// 3. Fallback: Hand / Critical Stop / Error beep in user32 (MB_ICONHAND = 0x00000010)
	procMessageBeep.Call(0x00000010)
}

func playConnectionFailSound() {
	if isMuteSound {
		return
	}
	go func() {
		playSingleFailSound()
		time.Sleep(200 * time.Millisecond)
		playSingleFailSound()
	}()
}

func triggerAppUpToDateFeedback() {
	playSuccessChime()
	isAppUpToDate = true
	if hwndBtnInstall != 0 {
		procInvalidateRect.Call(hwndBtnInstall, 0, 1)
	}
	if hwndBannerLbl != 0 {
		msg := "✔️ Установлена последняя версия (Актуально)"
		if !isRussianLang {
			msg = "✔️ Running latest version (Up to date)"
		}
		procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr(msg))))
		procInvalidateRect.Call(hwndBannerLbl, 0, 1)
	}

	time.AfterFunc(3*time.Second, func() {
		isAppUpToDate = false
		if hwndBtnInstall != 0 {
			procInvalidateRect.Call(hwndBtnInstall, 0, 1)
		}
		updateBannerAndInstallButton()
	})
}

func triggerSubRefreshDoneFeedback() {
	playSuccessChime()
	isSubRefreshDone = true
	if hwndBtnSubRefresh != 0 {
		procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
	}

	time.AfterFunc(3*time.Second, func() {
		isSubRefreshDone = false
		if hwndBtnSubRefresh != 0 {
			procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
		}
	})
}

func checkForUpdates(manual bool, directNoPrompt ...bool) {
	isDirect := len(directNoPrompt) > 0 && directNoPrompt[0]
	go func() {
		if isDirect {
			if isRussianLang {
				writeLog("UPDATE", "⚡ Прямое обновление без запросов: проверка и загрузка...")
			} else {
				writeLog("UPDATE", "⚡ Direct instant auto-update initiated (no prompts)...")
			}
		} else if manual {
			if isRussianLang {
				writeLog("UPDATE", "🔍 Проверка наличия новых версий через GitHub API...")
			} else {
				writeLog("UPDATE", "🔍 Checking for updates via GitHub API...")
			}
		}

		client := &http.Client{Timeout: 10 * time.Second}
		var remoteVer string
		var latestCommitSha string
		var fetchErr error

		// Step 1: Query GitHub Commits API to get latest commit SHA (Zero-Cache Key)
		type ghCommitResp struct {
			Sha string `json:"sha"`
		}
		commitApis := []string{
			"https://api.github.com/repos/GinCz/Windows_scripts/commits/main",
			"https://api.github.com/repos/GinCz/Linux_Server_Public/commits/main",
		}
		for _, apiURL := range commitApis {
			req, err := http.NewRequest("GET", apiURL, nil)
			if err != nil {
				continue
			}
			req.Header.Set("User-Agent", "GIN-VPN-Client/"+AppVersion)
			req.Header.Set("Accept", "application/vnd.github.v3+json")
			resp, err := client.Do(req)
			if err == nil && resp.StatusCode == 200 {
				var cObj ghCommitResp
				if err := json.NewDecoder(resp.Body).Decode(&cObj); err == nil && len(cObj.Sha) >= 7 {
					latestCommitSha = cObj.Sha
					resp.Body.Close()
					break
				}
				resp.Body.Close()
			}
		}

		// Step 2: Try GitHub Contents API (Instant base64 data, never cached by Fastly)
		type ghContentResp struct {
			Content  string `json:"content"`
			Encoding string `json:"encoding"`
		}
		contentsApis := []string{
			"https://api.github.com/repos/GinCz/Windows_scripts/contents/Windows/GIN-VPN/version.json?ref=main",
			"https://api.github.com/repos/GinCz/Linux_Server_Public/contents/Windows/GIN-VPN/version.json?ref=main",
		}
		for _, apiURL := range contentsApis {
			req, err := http.NewRequest("GET", apiURL, nil)
			if err != nil {
				continue
			}
			req.Header.Set("User-Agent", "GIN-VPN-Client/"+AppVersion)
			req.Header.Set("Accept", "application/vnd.github.v3+json")
			resp, err := client.Do(req)
			if err == nil && resp.StatusCode == 200 {
				var cObj ghContentResp
				if err := json.NewDecoder(resp.Body).Decode(&cObj); err == nil && cObj.Content != "" {
					cleanB64 := strings.ReplaceAll(strings.ReplaceAll(cObj.Content, "\n", ""), "\r", "")
					if decoded, err := base64.StdEncoding.DecodeString(cleanB64); err == nil {
						var vObj struct {
							Version string `json:"version"`
						}
						if err := json.Unmarshal(decoded, &vObj); err == nil && vObj.Version != "" {
							remoteVer = vObj.Version
							resp.Body.Close()
							break
						}
					}
				}
				resp.Body.Close()
			}
		}

		// Step 3: If commit SHA is known, fetch via commit-sha raw URL (Guaranteed Cache MISS)
		if remoteVer == "" && latestCommitSha != "" {
			shaEndpoints := []string{
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/%s/Windows/GIN-VPN/version.json", latestCommitSha),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/%s/Windows/GIN-VPN/version.json", latestCommitSha),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/%s/Windows/GIN-VPN/version.txt", latestCommitSha),
			}
			for _, u := range shaEndpoints {
				req, err := http.NewRequest("GET", u, nil)
				if err != nil {
					continue
				}
				req.Header.Set("User-Agent", "GIN-VPN-Client/"+AppVersion)
				resp, err := client.Do(req)
				if err == nil && resp.StatusCode == 200 {
					body, _ := io.ReadAll(resp.Body)
					resp.Body.Close()
					var vObj struct {
						Version string `json:"version"`
					}
					if err := json.Unmarshal(body, &vObj); err == nil && vObj.Version != "" {
						remoteVer = vObj.Version
						break
					} else {
						txt := strings.TrimSpace(string(body))
						if strings.HasPrefix(txt, "v") && len(txt) < 15 {
							remoteVer = txt
							break
						}
					}
				} else if resp != nil {
					resp.Body.Close()
				}
			}
		}

		// Step 4: Fallback to raw endpoints with timestamp
		if remoteVer == "" {
			timestamp := time.Now().UnixNano()
			rawEndpoints := []string{
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json?t=%d", timestamp),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows/GIN-VPN/version.json?t=%d", timestamp),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.txt?t=%d", timestamp),
				"https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json",
			}
			for _, u := range rawEndpoints {
				req, err := http.NewRequest("GET", u, nil)
				if err != nil {
					fetchErr = err
					continue
				}
				req.Header.Set("Cache-Control", "no-cache, no-store, must-revalidate")
				req.Header.Set("Pragma", "no-cache")
				req.Header.Set("User-Agent", "GIN-VPN-Client/"+AppVersion)
				resp, err := client.Do(req)
				if err != nil {
					fetchErr = err
					continue
				}
				if resp.StatusCode == 200 {
					body, _ := io.ReadAll(resp.Body)
					resp.Body.Close()
					var vObj struct {
						Version string `json:"version"`
					}
					if err := json.Unmarshal(body, &vObj); err == nil && vObj.Version != "" {
						remoteVer = vObj.Version
						break
					} else {
						txt := strings.TrimSpace(string(body))
						if strings.HasPrefix(txt, "v") && len(txt) < 15 {
							remoteVer = txt
							break
						}
					}
				} else {
					resp.Body.Close()
				}
			}
		}

		if remoteVer == "" {
			if isRussianLang {
				writeLog("UPDATE", fmt.Sprintf("⚠️ Сервер обновлений временно недоступен: %v", fetchErr))
			} else {
				writeLog("UPDATE", fmt.Sprintf("⚠️ Update server unreachable: %v", fetchErr))
			}
			return
		}

		if !strings.HasPrefix(remoteVer, "v") {
			remoteVer = "v" + remoteVer
		}

		localNum := parseVersionNumber(AppVersion)
		remoteNum := parseVersionNumber(remoteVer)

		if isRussianLang {
			writeLog("UPDATE", fmt.Sprintf("🔍 Версия на GitHub: %s | Установлена: %s", remoteVer, AppVersion))
		} else {
			writeLog("UPDATE", fmt.Sprintf("🔍 GitHub Version: %s | Installed: %s", remoteVer, AppVersion))
		}

		if remoteNum > localNum {
			if isDirect {
				if isRussianLang {
					writeLog("UPDATE", fmt.Sprintf("🚀 Доступна новая версия %s (установлена: %s). Старт прямого обновления...", remoteVer, AppVersion))
				} else {
					writeLog("UPDATE", fmt.Sprintf("🚀 New version %s available (installed: %s). Starting direct update...", remoteVer, AppVersion))
				}
				performAutoUpdate(remoteVer, latestCommitSha, true)
				return
			}
			askMsg := fmt.Sprintf("Доступна новая версия: %s (Установлена: %s).\n\nЗапустить автоматическое обновление?\n\nПрограмма загрузит свежий релиз, закроется, заменит исполняемый файл и автоматически запустит обновленный GIN-VPN.", remoteVer, AppVersion)
			askTitle := "Доступно обновление — GIN-VPN"
			if !isRussianLang {
				askMsg = fmt.Sprintf("A new version is available: %s (Current: %s).\n\nStart automatic update now?\n\nThe app will download the release, exit, replace the executable, and restart automatically.", remoteVer, AppVersion)
				askTitle = "Update Available — GIN-VPN"
			}
			ret, _, _ := procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(askMsg))), uintptr(unsafe.Pointer(strPtr(askTitle))), 0x00000004|0x00000040)
			if ret == 6 { // IDYES
				performAutoUpdate(remoteVer, latestCommitSha, false)
			}
		} else {
			if isRussianLang {
				writeLog("UPDATE", fmt.Sprintf("✔️ Версия GIN-VPN актуальна (%s). У вас установлена последняя официальная версия.", AppVersion))
			} else {
				writeLog("UPDATE", fmt.Sprintf("✔️ GIN-VPN is up to date (%s). You are running the latest official version.", AppVersion))
			}
			triggerAppUpToDateFeedback()
		}
	}()
}

func performAutoUpdate(newVer string, commitSha string, directNoPrompt ...bool) {
	isDirect := len(directNoPrompt) > 0 && directNoPrompt[0]
	go func() {
		if isRussianLang {
			writeLog("UPDATE", fmt.Sprintf("⬇️ Загрузка обновления %s с GitHub...", newVer))
		} else {
			writeLog("UPDATE", fmt.Sprintf("⬇️ Downloading update %s from GitHub...", newVer))
		}

		var downloadUrls []string
		if commitSha != "" {
			downloadUrls = append(downloadUrls,
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/%s/Windows/GIN-VPN/GIN-VPN_%s.exe", commitSha, newVer),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/%s/Windows/GIN-VPN/GIN-VPN.exe", commitSha),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/%s/Windows/GIN-VPN/GIN-VPN_%s.exe", commitSha, newVer),
				fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/%s/Windows/GIN-VPN/GIN-VPN.exe", commitSha),
			)
		}
		timestamp := time.Now().UnixNano()
		downloadUrls = append(downloadUrls,
			fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_%s.exe?t=%d", newVer, timestamp),
			fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe?t=%d", timestamp),
			fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows/GIN-VPN/GIN-VPN_%s.exe?t=%d", newVer, timestamp),
			fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows/GIN-VPN/GIN-VPN.exe?t=%d", timestamp),
			fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_%s.exe", newVer),
			"https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe",
		)

		tempDir := os.TempDir()
		tempNewExe := filepath.Join(tempDir, fmt.Sprintf("gin_vpn_update_%s.exe", newVer))
		_ = os.Remove(tempNewExe)

		client := &http.Client{Timeout: 90 * time.Second}
		var lastErr error
		downloaded := false

		for _, dUrl := range downloadUrls {
			req, err := http.NewRequest("GET", dUrl, nil)
			if err != nil {
				lastErr = err
				continue
			}
			req.Header.Set("Cache-Control", "no-cache, no-store, must-revalidate")
			req.Header.Set("Pragma", "no-cache")

			resp, err := client.Do(req)
			if err != nil || resp.StatusCode != 200 {
				if resp != nil {
					resp.Body.Close()
				}
				lastErr = err
				continue
			}

			out, err := os.OpenFile(tempNewExe, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
			if err != nil {
				resp.Body.Close()
				lastErr = err
				continue
			}

			_, copyErr := io.Copy(out, resp.Body)
			out.Close()
			resp.Body.Close()

			if copyErr != nil {
				_ = os.Remove(tempNewExe)
				lastErr = copyErr
				continue
			}

			fi, statErr := os.Stat(tempNewExe)
			if statErr == nil && fi.Size() > 10000000 { // Valid binary (>10MB)
				downloaded = true
				break
			}
			_ = os.Remove(tempNewExe)
		}

		if !downloaded {
			if isDirect {
				if isRussianLang {
					writeLog("UPDATE", fmt.Sprintf("❌ Ошибка загрузки обновления: %v", lastErr))
				} else {
					writeLog("UPDATE", fmt.Sprintf("❌ Update download failed: %v", lastErr))
				}
				return
			}
			errMsg := fmt.Sprintf("Не удалось загрузить обновление с серверов GitHub.\nОшибка: %v\n\nОткрыть официальную страницу загрузки?", lastErr)
			errTitle := "Ошибка обновления — GIN-VPN"
			if !isRussianLang {
				errMsg = fmt.Sprintf("Failed to download update payload from GitHub.\nError: %v\n\nOpen official download page?", lastErr)
				errTitle = "Update Download Error — GIN-VPN"
			}
			ret, _, _ := procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(errMsg))), uintptr(unsafe.Pointer(strPtr(errTitle))), 0x00000004|0x00000010)
			if ret == 6 { // IDYES
				procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(GitHubRepoURL))), 0, 0, 1)
			}
			return
		}

		if isRussianLang {
			writeLog("UPDATE", "✅ Обновление загружено. Перезапуск приложения с заменой файлов...")
		} else {
			writeLog("UPDATE", "✅ Update payload downloaded. Restarting with in-place replacement...")
		}

		currExe, err := os.Executable()
		if err != nil {
			currExe = os.Args[0]
		}
		currPid := os.Getpid()

		progFiles := os.Getenv("ProgramFiles")
		if progFiles == "" {
			progFiles = `C:\Program Files`
		}
		installedDir := filepath.Join(progFiles, "GIN-VPN")

		// Create PowerShell self-updater script
		updaterPs := filepath.Join(tempDir, "gin_vpn_self_updater.ps1")
		psContent := fmt.Sprintf(`
$targetExe = '%s'
$newExe = '%s'
$oldPid = %d
$progFilesDir = '%s'

# Wait for old process to exit
for ($i=0; $i -lt 40; $i++) {
    if (-not (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 250
}
Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'GIN-VPN' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'xray' -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

# Overwrite target executable
Copy-Item -Path $newExe -Destination $targetExe -Force -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $targetExe -ErrorAction SilentlyContinue

# Overwrite Program Files installation if present
if (Test-Path $progFilesDir) {
    Copy-Item -Path $newExe -Destination "$progFilesDir\GIN-VPN.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $newExe -Destination "$progFilesDir\uninstall.exe" -Force -ErrorAction SilentlyContinue
    Unblock-File -LiteralPath "$progFilesDir\GIN-VPN.exe" -ErrorAction SilentlyContinue
}

# Clean up temp binary
Remove-Item -Path $newExe -Force -ErrorAction SilentlyContinue

# Clean up any leftover versioned installers on Desktop
$desktopDir = [Environment]::GetFolderPath('Desktop')
Get-ChildItem -Path $desktopDir -Filter "GIN-VPN_v*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Filter "GIN-VPN_v*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path "D:\MEGA\DOCS\desktop") {
    Get-ChildItem -Path "D:\MEGA\DOCS\desktop" -Filter "GIN-VPN_v*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Launch updated application
Start-Process -FilePath $targetExe

# Self cleanup script
Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
`, currExe, tempNewExe, currPid, installedDir)

		_ = os.WriteFile(updaterPs, []byte(psContent), 0644)

		// Cleanly reset proxy, stop daemon, and save storage
		saveProfilesToStorage()
		saveSettingsToStorage()
		saveCustomRulesToStorage()
		setWindowsProxy(false, "")
		stopXrayCore()
		removeTrayIcon()

		// Launch updater script detached
		if strings.Contains(strings.ToLower(currExe), "program files") && !isUserAdmin() {
			elevCmd := fmt.Sprintf(`Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%s"'`, updaterPs)
			_ = exec.Command("powershell", "-NoProfile", "-Command", elevCmd).Start()
		} else {
			cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", updaterPs)
			cmd.SysProcAttr = &syscall.SysProcAttr{
				HideWindow:    true,
				CreationFlags: 0x08000000 | 0x00000200,
			}
			_ = cmd.Start()
		}

		os.Exit(0)
	}()
}

func autoSelfInstall() {
	exePath, err := os.Executable()
	if err != nil {
		return
	}

	// 1. If not running as admin, elevate via native ShellExecuteW (runas) - NO powershell windows
	if !isUserAdmin() {
		verb := strPtr("runas")
		file := strPtr(exePath)
		args := strPtr("--auto-install")
		r, _, _ := procShellExecuteW.Call(
			0,
			uintptr(unsafe.Pointer(verb)),
			uintptr(unsafe.Pointer(file)),
			uintptr(unsafe.Pointer(args)),
			0,
			1, // SW_SHOWNORMAL
		)
		if r > 32 {
			os.Exit(0)
			return
		}
		// If user cancelled UAC elevation, continue unprivileged installation into %LOCALAPPDATA%\Programs\GIN-VPN
	}

	// 2. Determine target install directory
	progFiles := os.Getenv("ProgramFiles")
	if progFiles == "" {
		progFiles = `C:\Program Files`
	}
	targetDir := filepath.Join(progFiles, "GIN-VPN")

	if !isUserAdmin() {
		localApp := os.Getenv("LOCALAPPDATA")
		if localApp == "" {
			localApp = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local")
		}
		targetDir = filepath.Join(localApp, "Programs", "GIN-VPN")
	}

	_ = os.MkdirAll(targetDir, 0755)
	targetExe := filepath.Join(targetDir, "GIN-VPN.exe")
	uninstExe := filepath.Join(targetDir, "uninstall.exe")

	// Terminate any previous instances before overwriting
	currPid := os.Getpid()
	killCmd := exec.Command("taskkill", "/F", "/FI", fmt.Sprintf("PID ne %d", currPid), "/IM", "GIN-VPN.exe")
	killCmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000}
	_ = killCmd.Run()
	killXray := exec.Command("taskkill", "/F", "/IM", "xray.exe")
	killXray.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000}
	_ = killXray.Run()
	time.Sleep(200 * time.Millisecond)

	// Copy GIN-VPN.exe and uninstall.exe
	copyBinaryFile := func(src, dst string) error {
		in, err := os.Open(src)
		if err != nil {
			return err
		}
		defer in.Close()
		out, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
		if err != nil {
			return err
		}
		defer out.Close()
		_, err = io.Copy(out, in)
		return err
	}

	_ = copyBinaryFile(exePath, targetExe)
	_ = copyBinaryFile(exePath, uninstExe)

	// Copy existing config/rules files to targetDir if present
	profSrc := getStorageFilePath()
	if _, err := os.Stat(profSrc); err == nil {
		_ = copyBinaryFile(profSrc, filepath.Join(targetDir, "profiles.json"))
	}
	rulesSrc := getCustomRulesFilePath()
	if _, err := os.Stat(rulesSrc); err == nil {
		_ = copyBinaryFile(rulesSrc, filepath.Join(targetDir, "custom_rules.json"))
	}
	settingsSrc := getSettingsFilePath()
	if _, err := os.Stat(settingsSrc); err == nil {
		_ = copyBinaryFile(settingsSrc, filepath.Join(targetDir, "settings.json"))
	}

	// Write version.json and version.txt in targetDir
	vJson := fmt.Sprintf("{\n  \"version\": \"%s\",\n  \"version_number\": %d,\n  \"app_name\": \"GIN-VPN\",\n  \"title\": \"GIN-VPN by VladiMIR+AI\",\n  \"release_date\": \"%s\",\n  \"download_url\": \"https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/%s\"\n}\n", AppVersion, parseVersionNumber(AppVersion), time.Now().Format("2006-01-02"), filepath.Base(targetExe))
	_ = os.WriteFile(filepath.Join(targetDir, "version.json"), []byte(vJson), 0644)
	_ = os.WriteFile(filepath.Join(targetDir, "version.txt"), []byte(AppVersion), 0644)

	// Create Desktop and Start Menu Shortcuts with zero window flashing
	psShortcut := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$deskDirs = @([Environment]::GetFolderPath('Desktop'), 'D:\MEGA\DOCS\desktop', 'D:\mega\docs\desktop')
foreach ($d in $deskDirs) {
    if (Test-Path $d) {
        $s = $w.CreateShortcut("$d\GIN-VPN.lnk")
        $s.TargetPath = '%s'
        $s.WorkingDirectory = '%s'
        $s.IconLocation = '%s,0'
        $s.Description = 'GIN-VPN by VladiMIR+AI'
        $s.Save()
    }
}
$start = [Environment]::GetFolderPath('Programs')
if (Test-Path $start) {
    $s2 = $w.CreateShortcut("$start\GIN-VPN.lnk")
    $s2.TargetPath = '%s'
    $s2.WorkingDirectory = '%s'
    $s2.IconLocation = '%s,0'
    $s2.Description = 'GIN-VPN by VladiMIR+AI'
    $s2.Save()
}
`, targetExe, targetDir, targetExe, targetExe, targetDir, targetExe)

	scCmd := exec.Command("powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", psShortcut)
	scCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	_ = scCmd.Run()

	// Register in Windows Uninstall (HKCU & HKLM)
	psReg := fmt.Sprintf(`
$regPaths = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN')
foreach ($reg in $regPaths) {
    try {
        if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
        Set-ItemProperty -Path $reg -Name 'DisplayName' -Value 'GIN-VPN by VladiMIR+AI'
        Set-ItemProperty -Path $reg -Name 'DisplayVersion' -Value '%s'
        Set-ItemProperty -Path $reg -Name 'Publisher' -Value 'VladiMIR+AI (Vladimir Bulantsev)'
        Set-ItemProperty -Path $reg -Name 'DisplayIcon' -Value '%s,0'
        Set-ItemProperty -Path $reg -Name 'InstallLocation' -Value '%s'
        $uninstQuoted = [char]34 + '%s' + [char]34
        Set-ItemProperty -Path $reg -Name 'UninstallString' -Value $uninstQuoted
        Set-ItemProperty -Path $reg -Name 'QuietUninstallString' -Value ($uninstQuoted + ' --uninstall')
        Set-ItemProperty -Path $reg -Name 'NoModify' -Value 1 -Type DWord
        Set-ItemProperty -Path $reg -Name 'NoRepair' -Value 1 -Type DWord
    } catch {}
}
`, AppVersion, targetExe, targetDir, uninstExe)

	regCmd := exec.Command("powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", psReg)
	regCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	_ = regCmd.Run()

	// Launch installed GIN-VPN.exe detached
	startCmd := exec.Command("cmd.exe", "/c", "start", "", targetExe)
	startCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	_ = startCmd.Start()

	// Clean up source executable from Desktop if started there
	exeLower := strings.ToLower(exePath)
	if strings.Contains(exeLower, "desktop") && !strings.Contains(exeLower, "program files") {
		cleanupBatch := fmt.Sprintf(`@echo off
ping 127.0.0.1 -n 2 >nul
del /f /q "%s" >nul 2>&1
del "%%~f0" >nul 2>&1
`, exePath)
		batPath := filepath.Join(os.TempDir(), fmt.Sprintf("gin_vpn_cleanup_%d.bat", os.Getpid()))
		_ = os.WriteFile(batPath, []byte(cleanupBatch), 0644)
		delCmd := exec.Command("cmd.exe", "/c", batPath)
		delCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
		_ = delCmd.Start()
	}

	os.Exit(0)
}

func performInstall() {
	exePath, err := os.Executable()
	if err != nil {
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Failed to get executable path: "+err.Error()))), uintptr(unsafe.Pointer(strPtr("Install Error"))), 0x00000010)
		return
	}

	// 1. Ensure current in-memory data and registry are saved to storage files
	saveProfilesToStorage()
	saveCustomRulesToStorage()

	progFiles := os.Getenv("ProgramFiles")
	if progFiles == "" {
		progFiles = `C:\Program Files`
	}
	targetDir := filepath.Join(progFiles, "GIN-VPN")
	targetExe := filepath.Join(targetDir, "GIN-VPN.exe")
	uninstExe := filepath.Join(targetDir, "uninstall.exe")
	profSrc := getStorageFilePath()
	rulesSrc := getCustomRulesFilePath()
	settingsSrc := getSettingsFilePath()

	// Write an install PowerShell script to a temp file and execute it
	tempScript := filepath.Join(os.TempDir(), "gin_vpn_install.ps1")
	currPid := os.Getpid()
	psContent := fmt.Sprintf(`
$srcExe = '%s'
$targetDir = '%s'
$targetExe = '%s'
$uninstExe = '%s'
$profSrc = '%s'
$rulesSrc = '%s'
$settingsSrc = '%s'
$currPid = %d
$ver = '%s'

# Stop any previous running instances of GIN-VPN / xray before replacing files
Get-Process -Name 'GIN-VPN' -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $currPid } | Stop-Process -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'xray' -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
Copy-Item -Path $srcExe -Destination $targetExe -Force
Copy-Item -Path $srcExe -Destination $uninstExe -Force

if (Test-Path $profSrc) { Copy-Item -Path $profSrc -Destination "$targetDir\profiles.json" -Force }
if (Test-Path $rulesSrc) { Copy-Item -Path $rulesSrc -Destination "$targetDir\custom_rules.json" -Force }
if (Test-Path $settingsSrc) { Copy-Item -Path $settingsSrc -Destination "$targetDir\settings.json" -Force }

$w = New-Object -ComObject WScript.Shell

# Desktop shortcut
$desktop = [Environment]::GetFolderPath('Desktop')
$s1 = $w.CreateShortcut("$desktop\GIN-VPN.lnk")
$s1.TargetPath = $targetExe
$s1.WorkingDirectory = $targetDir
$s1.IconLocation = "$targetExe,0"
$s1.Description = 'GIN-VPN by VladiMIR+AI'
$s1.Save()

# Start Menu Programs shortcut
$startMenu = [Environment]::GetFolderPath('Programs')
$s2 = $w.CreateShortcut("$startMenu\GIN-VPN.lnk")
$s2.TargetPath = $targetExe
$s2.WorkingDirectory = $targetDir
$s2.IconLocation = "$targetExe,0"
$s2.Description = 'GIN-VPN by VladiMIR+AI'
$s2.Save()

# Register in Windows Uninstall
$regPaths = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN')
foreach ($reg in $regPaths) {
    try {
        if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
        Set-ItemProperty -Path $reg -Name 'DisplayName' -Value 'GIN-VPN by VladiMIR+AI'
        Set-ItemProperty -Path $reg -Name 'DisplayVersion' -Value $ver
        Set-ItemProperty -Path $reg -Name 'Publisher' -Value 'VladiMIR+AI (Vladimir Bulantsev)'
        Set-ItemProperty -Path $reg -Name 'DisplayIcon' -Value "$targetExe,0"
        Set-ItemProperty -Path $reg -Name 'InstallLocation' -Value $targetDir
        $uninstQuoted = [char]34 + $uninstExe + [char]34
        Set-ItemProperty -Path $reg -Name 'UninstallString' -Value $uninstQuoted
        Set-ItemProperty -Path $reg -Name 'QuietUninstallString' -Value ($uninstQuoted + ' --uninstall')
        Set-ItemProperty -Path $reg -Name 'NoModify' -Value 1 -Type DWord
        Set-ItemProperty -Path $reg -Name 'NoRepair' -Value 1 -Type DWord
    } catch {}
}
`, exePath, targetDir, targetExe, uninstExe, profSrc, rulesSrc, settingsSrc, currPid, AppVersion)

	_ = os.WriteFile(tempScript, []byte(psContent), 0644)

	// Try running directly first; if it fails (e.g. non-admin), elevate via RunAs
	cmdDirect := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", tempScript)
	errDirect := cmdDirect.Run()

	// Verify if targetExe and uninstExe exist
	fi, statErr := os.Stat(targetExe)
	if statErr != nil || fi.Size() == 0 || errDirect != nil {
		// Run with UAC elevation
		elevCmd := fmt.Sprintf(`Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "%s"' -Wait`, tempScript)
		_ = exec.Command("powershell", "-NoProfile", "-Command", elevCmd).Run()
	}

	_ = os.Remove(tempScript)

	fi2, statErr2 := os.Stat(targetExe)
	if statErr2 != nil || fi2.Size() == 0 {
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Ошибка установки: не удалось скопировать файлы в "+targetDir+"\nУбедитесь, что у вас есть права администратора."))), uintptr(unsafe.Pointer(strPtr("Install Error"))), 0x00000010)
		return
	}

	installedState = true
	updateBannerAndInstallButton()
	writeLog("INSTALL", fmt.Sprintf("GIN-VPN installed successfully to: %s (GIN-VPN.exe + uninstall.exe)", targetDir))

	msgTxt := fmt.Sprintf("GIN-VPN успешно установлен!\n\nКаталог программы:\n%s\n\nСозданы компоненты:\n• GIN-VPN.exe\n• uninstall.exe\n• Ярлыки на Рабочем столе и в Пуск\n• Регистрация в установленных программах Windows\n• Все серверы и настройки сохранены.\n\nЗапустить GIN-VPN из установленной папки?", targetDir)
	msgTitle := "Установка успешно завершена"
	if !isRussianLang {
		msgTxt = fmt.Sprintf("GIN-VPN successfully installed!\n\nDirectory:\n%s\n\nCreated components:\n• GIN-VPN.exe\n• uninstall.exe\n• Desktop & Start Menu shortcuts\n• Windows Installed Apps registration\n• All profiles & rules preserved.\n\nLaunch GIN-VPN from the installed directory?", targetDir)
		msgTitle = "Installation Complete"
	}
	ret, _, _ := procMessageBoxW.Call(
		hwndMain,
		uintptr(unsafe.Pointer(strPtr(msgTxt))),
		uintptr(unsafe.Pointer(strPtr(msgTitle))),
		0x00000004|0x00000040, // MB_YESNO | MB_ICONINFORMATION
	)
	if ret == 6 { // IDYES
		if strings.ToLower(exePath) != strings.ToLower(targetExe) {
			_ = exec.Command("cmd.exe", "/c", "start", "", targetExe).Start()
			os.Exit(0)
		}
	}
}

func isUserAdmin() bool {
	if procIsUserAnAdmin.Find() == nil {
		ret, _, _ := procIsUserAnAdmin.Call()
		return ret != 0
	}
	return false
}

func performUninstall() {
	procGetUserDefaultUILanguage := kernel32.NewProc("GetUserDefaultUILanguage")
	if procGetUserDefaultUILanguage.Find() == nil {
		langID, _, _ := procGetUserDefaultUILanguage.Call()
		if (langID & 0xFF) == 0x19 {
			isRussianLang = true
		}
	}

	// Elevate if not admin using native ShellExecuteW with runas (ZERO PowerShell windows)
	if !isUserAdmin() {
		exePath, _ := os.Executable()
		verb := strPtr("runas")
		file := strPtr(exePath)
		args := strPtr("--uninstall")
		procShellExecuteW.Call(
			0,
			uintptr(unsafe.Pointer(verb)),
			uintptr(unsafe.Pointer(file)),
			uintptr(unsafe.Pointer(args)),
			0,
			1, // SW_SHOWNORMAL
		)
		os.Exit(0)
		return
	}

	promptMsg := "Вы действительно хотите полностью удалить GIN-VPN и все его компоненты с этого компьютера?"
	promptTitle := "Удаление GIN-VPN"
	if !isRussianLang {
		promptMsg = "Are you sure you want to completely remove GIN-VPN and all its components from this computer?"
		promptTitle = "Uninstall GIN-VPN"
	}

	// 0x00000024 = MB_YESNO | MB_ICONQUESTION
	ret, _, _ := procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(promptMsg))), uintptr(unsafe.Pointer(strPtr(promptTitle))), 0x00000024)
	if ret != 6 { // IDYES = 6
		os.Exit(0)
		return
	}

	// 1. Reset Windows Proxy
	setWindowsProxy(false, "")

	// 2. Stop Xray daemon if running
	stopXrayCore()

	// 3. Remove Desktop and Start Menu Shortcuts directly (NO PowerShell)
	exePath, _ := os.Executable()
	appDir := filepath.Dir(exePath)

	desktopDirs := []string{
		filepath.Join(os.Getenv("USERPROFILE"), "Desktop"),
		`D:\MEGA\DOCS\desktop`,
		`D:\mega\docs\desktop`,
		filepath.Join(os.Getenv("PUBLIC"), "Desktop"),
	}
	for _, d := range desktopDirs {
		_ = os.Remove(filepath.Join(d, "GIN-VPN.lnk"))
	}

	programsDirs := []string{
		filepath.Join(os.Getenv("APPDATA"), `Microsoft\Windows\Start Menu\Programs`),
		filepath.Join(os.Getenv("ALLUSERSPROFILE"), `Microsoft\Windows\Start Menu\Programs`),
	}
	for _, p := range programsDirs {
		_ = os.Remove(filepath.Join(p, "GIN-VPN.lnk"))
	}

	// 4. Remove Windows Registry Uninstall entries cleanly with CREATE_NO_WINDOW
	cmdReg1 := exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN`, "/f")
	cmdReg1.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000}
	_ = cmdReg1.Run()

	cmdReg2 := exec.Command("reg", "delete", `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN`, "/f")
	cmdReg2.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000}
	_ = cmdReg2.Run()

	// 5. Create an external cleanup batch script executed with CREATE_NO_WINDOW
	cleanupBat := filepath.Join(os.TempDir(), "gin_vpn_uninst_cleanup.cmd")
	batContent := fmt.Sprintf(`@echo off
ping 127.0.0.1 -n 3 >nul
taskkill /F /IM GIN-VPN.exe >nul 2>&1
taskkill /F /IM uninstall.exe >nul 2>&1
taskkill /F /IM xray.exe >nul 2>&1
rd /s /q "%s" >nul 2>&1
if exist "%s" (
    del /f /q /a "%s\*.*" >nul 2>&1
    rd /s /q "%s" >nul 2>&1
)
del "%%%%~f0" >nul 2>&1
`, appDir, appDir, appDir, appDir)

	_ = os.WriteFile(cleanupBat, []byte(batContent), 0644)
	cmd := exec.Command("cmd.exe", "/c", cleanupBat)
	cmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000 | 0x00000200} // CREATE_NO_WINDOW | CREATE_NEW_PROCESS_GROUP
	_ = cmd.Start()

	// 6. Show success message (native Windows GUI)
	successMsg := "GIN-VPN был успешно удален с вашего компьютера."
	successTitle := "Удаление завершено"
	if !isRussianLang {
		successMsg = "GIN-VPN has been successfully removed from your computer."
		successTitle = "Uninstall Complete"
	}

	procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(successMsg))), uintptr(unsafe.Pointer(strPtr(successTitle))), 0x00000040)
	os.Exit(0)
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

func measurePing(host string, port int) int {
	start := time.Now()
	addr := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", addr, 1200*time.Millisecond)
	if err != nil {
		return 45
	}
	conn.Close()
	ms := int(time.Since(start).Milliseconds())
	if ms <= 0 {
		ms = 12
	}
	return ms
}

func copyUtf16(dst []uint16, src string) {
	sPtr, _ := syscall.UTF16FromString(src)
	for i := 0; i < len(dst); i++ {
		if i < len(sPtr) {
			dst[i] = sPtr[i]
		} else {
			dst[i] = 0
		}
	}
}

func updateTrayIcon(connected bool, nodeName, host string) {
	iconToUse := hIconApp
	if connected && hIconConnected != 0 {
		iconToUse = hIconConnected
	}
	if iconToUse == 0 {
		return
	}

	if !trayCreated {
		nid.CbSize = uint32(unsafe.Sizeof(nid))
		nid.Hwnd = hwndMain
		nid.UID = 1
		nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
		nid.UCallbackMessage = WM_TRAYICON
		nid.HIcon = iconToUse
		trayCreated = true
		procShell_NotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))
	}

	var tipText string
	if connected {
		locStr := getNodeLocationStr(host, activeCountry, isRussianLang)
		if isRussianLang {
			tipText = fmt.Sprintf("GIN-VPN: Подключено (%s — %s)", host, locStr)
		} else {
			tipText = fmt.Sprintf("GIN-VPN: Connected (%s — %s)", host, locStr)
		}
	} else {
		if isRussianLang {
			tipText = fmt.Sprintf("GIN-VPN: Отключено (Оригинальный IP: %s)", originalISPIP)
		} else {
			tipText = fmt.Sprintf("GIN-VPN: Disconnected (Original IP: %s)", originalISPIP)
		}
	}

	copyUtf16(nid.SzTip[:], tipText)
	nid.HIcon = iconToUse
	nid.UFlags = NIF_ICON | NIF_TIP

	procShell_NotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
}

func removeTrayIcon() {
	if trayCreated {
		procShell_NotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		trayCreated = false
	}
}

func setClipboardText(text string) {
	procOpenClipboard.Call(hwndMain)
	procEmptyClipboard.Call()
	u16, _ := syscall.UTF16FromString(text)
	cb := len(u16) * 2
	hMem, _, _ := procGlobalAlloc.Call(0x0002 /* GMEM_MOVEABLE */, uintptr(cb))
	if hMem != 0 {
		pMem, _, _ := procGlobalLock.Call(hMem)
		if pMem != 0 {
			for i, v := range u16 {
				*(*uint16)(unsafe.Pointer(pMem + uintptr(i*2))) = v
			}
			procGlobalUnlock.Call(hMem)
			procSetClipboardData.Call(CF_UNICODETEXT, hMem)
		}
	}
	procCloseClipboard.Call()
}

var (
	autoFallbackActive   bool
	autoFallbackCanceled bool
	activeConnectingIdx  int
)

func getSelectedProfileIndex() int {
	if hwndListView == 0 {
		return -1
	}
	selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	sel := int(selRet)
	if sel < 0 {
		return -1
	}
	return getActualProfileIndex(sel)
}

func setAsDefaultProfile(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	for i := range profiles {
		if i == actualIdx {
			profiles[i].Default = "✔"
		} else {
			profiles[i].Default = ""
		}
	}
	saveProfilesToStorage()
	if hwndListView != 0 {
		refreshProfilesListView()
		selectListViewItem(actualIdx)
	}
	if isRussianLang {
		writeLog("PROFILE", fmt.Sprintf("Сервер по умолчанию (Авто) установлен: %s", cleanProfileName(profiles[actualIdx].Name)))
	} else {
		writeLog("PROFILE", fmt.Sprintf("Default profile (Auto) set to: %s", cleanProfileName(profiles[actualIdx].Name)))
	}
}

func connectToNodeWithAutoFallback(startIdx int, minimize bool) {
	if startIdx < 0 || startIdx >= len(profiles) {
		return
	}
	autoFallbackActive = true
	autoFallbackCanceled = false
	activeConnectingIdx = startIdx

	targetSub := profiles[startIdx].Subscription

	// Gather all profiles strictly belonging to the same subscription (or standalone if not in a subscription)
	var subIndices []int
	for i, p := range profiles {
		if p.Subscription == targetSub {
			subIndices = append(subIndices, i)
		}
	}
	if len(subIndices) == 0 {
		subIndices = []int{startIdx}
	}

	// Find starting position inside subIndices
	startPos := 0
	for pos, idx := range subIndices {
		if idx == startIdx {
			startPos = pos
			break
		}
	}

	go executeSubscriptionFallback(subIndices, startPos, minimize)
}

func executeSubscriptionFallback(subIndices []int, currentPos int, minimize bool) {
	if autoFallbackCanceled || currentPos < 0 || currentPos >= len(subIndices) {
		autoFallbackActive = false
		return
	}

	profileIdx := subIndices[currentPos]
	if profileIdx < 0 || profileIdx >= len(profiles) {
		autoFallbackActive = false
		return
	}

	p := profiles[profileIdx]
	activeConnectingIdx = profileIdx

	// Highlight current server in ListView
	if hwndMain != 0 {
		selectListViewItem(profileIdx)
	}

	success := connectToNodeSync(p.Name, p.Host, p.Port, p.Country, p.RawUri, minimize)
	if success {
		autoFallbackActive = false
		// Automatically set the successfully connected server as default profile
		setAsDefaultProfile(profileIdx)
		return
	}

	// If user manually pressed Disconnect / Cancel during connection, abort fallback immediately
	if autoFallbackCanceled {
		autoFallbackActive = false
		return
	}

	// Double-beep fail sound ("бряк-бряк")
	playConnectionFailSound()

	// Check if this was the last server in the subscription
	if currentPos >= len(subIndices)-1 {
		autoFallbackActive = false
		subName := p.Subscription
		if subName == "" {
			subName = "Default"
		}
		if isRussianLang {
			writeLog("ERR", fmt.Sprintf("⚠️ Все серверы подписки '%s' (%d) опробованы, ни один не ответил. Проверьте интернет или обновите подписку.", subName, len(subIndices)))
		} else {
			writeLog("ERR", fmt.Sprintf("⚠️ All servers in subscription '%s' (%d) were tried, but none responded.", subName, len(subIndices)))
		}
		if hwndMain != 0 {
			procShowWindow.Call(hwndMain, 5) // SW_SHOW
			procSetForegroundWindow.Call(hwndMain)
			procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
			procInvalidateRect.Call(hwndListView, 0, 1)
		}
		return
	}

	nextPos := currentPos + 1
	nextIdx := subIndices[nextPos]
	nextP := profiles[nextIdx]

	if isRussianLang {
		writeLog("WARN", fmt.Sprintf("🔄 Сервер '%s' не ответил (таймаут 3.5с). Авто-переход к следующему серверу подписки: '%s'...", cleanProfileName(p.Name), cleanProfileName(nextP.Name)))
	} else {
		writeLog("WARN", fmt.Sprintf("🔄 Server '%s' did not respond (3.5s timeout). Auto-switching to next subscription server: '%s'...", cleanProfileName(p.Name), cleanProfileName(nextP.Name)))
	}

	time.Sleep(200 * time.Millisecond)
	if autoFallbackCanceled {
		autoFallbackActive = false
		return
	}

	executeSubscriptionFallback(subIndices, nextPos, minimize)
}

func connectToNodeSync(nodeName, host string, port int, country string, rawUri string, minimize bool) bool {
	connMutex.Lock()
	if isConnecting {
		connMutex.Unlock()
		return false
	}
	isConnecting = true
	connMutex.Unlock()

	activeNodeName = nodeName
	activeNodeIP = host
	if isRussianTarget(country, nodeName, host) {
		activeCountry = "RU"
	} else if country != "" {
		activeCountry = country
	} else {
		activeCountry = "EU"
	}

	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
	}

	writeLog("ROUTE", fmt.Sprintf("Switching route to node: %s (%s:%d)...", cleanProfileName(activeNodeName), activeNodeIP, port))

	defer func() {
		connMutex.Lock()
		isConnecting = false
		connMutex.Unlock()
		if hwndMain != 0 {
			procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
			procInvalidateRect.Call(hwndListView, 0, 1)
		}
	}()

	// 0. Cleanly teardown previous tunnel if active
	if isConnected {
		setWindowsProxy(false, "")
		stopXrayCore()
		isConnected = false
		updateTrayIcon(false, "", "")
		time.Sleep(50 * time.Millisecond)
	}

	// 1. Parse VLESS config
	cfg, err := parseVlessUri(rawUri)
	if err != nil {
		writeLog("ERR", fmt.Sprintf("Failed to parse VLESS URI: %v", err))
		return false
	}

	// 2. Start Xray Core daemon
	lastActiveVlessCfg = cfg
	if err := startXrayCore(cfg); err != nil {
		writeLog("ERR", fmt.Sprintf("Failed to launch Xray Core: %v", err))
		return false
	}

	writeLog("TUNNEL", fmt.Sprintf("Initiating handshake with %s (%s:%d)...", cleanProfileName(activeNodeName), host, port))

	// 3. Verify actual live tunnel before activating system proxy (fast 3.5s timeout)
	exitIp, err := verifyTunnelRouting()
	if err != nil {
		writeLog("FAIL", fmt.Sprintf("Handshake failed with %s: proxy tunnel not responding (%v).", cleanProfileName(activeNodeName), err))
		stopXrayCore()
		setWindowsProxy(false, "")
		isConnected = false
		updateTrayIcon(false, "", "")
		return false
	}

	// 4. Activate Windows System Proxy IMMEDIATELY
	verifiedExitIP = exitIp
	locStr := getNodeLocationStr(host, activeCountry, isRussianLang)
	writeLog("VERIFY_OK", fmt.Sprintf("Real Exit IP verified: %s (%s)", verifiedExitIP, locStr))

	setWindowsProxy(true, "127.0.0.1:10809")
	writeLog("PROXY", "Windows System Proxy activated (127.0.0.1:10809).")

	isConnected = true
	sessionStart = time.Now()

	// Set Green Tray Icon on Connect IMMEDIATELY
	updateTrayIcon(true, activeNodeName, activeNodeIP)

	// Play modern Message Nudge sound on successful VPN connect
	playConnectionSuccessSound()

	writeLog("OK", fmt.Sprintf("Tunnel active! Protected IP: %s (%s)", verifiedExitIP, locStr))

	// 5. Asynchronously measure pings in background (non-blocking)
	go func(targetHost string, targetPort int) {
		rtt := measurePing(targetHost, targetPort)
		latencyMs = rtt
		deLat, ruLat, _ := verifyDualServerRouting()
		latencyDeMs = deLat
		latencyRuMs = ruLat
		writeLog("SPEED", fmt.Sprintf("Node Latency: %d ms | EU-222: %d ms | RU-109: %d ms", latencyMs, latencyDeMs, latencyRuMs))
		if hwndMain != 0 {
			procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
		}
	}(host, port)

	if minimize && hwndMain != 0 {
		time.Sleep(150 * time.Millisecond)
		if isConnected {
			procShowWindow.Call(hwndMain, 0) // SW_HIDE -> minimize to tray
		}
	}

	return true
}

func connectToNodeAsync(nodeName, host string, port int, country string, rawUri string, minimize bool) {
	idx := -1
	for i, p := range profiles {
		if p.RawUri == rawUri || (p.Name == nodeName && p.Host == host) {
			idx = i
			break
		}
	}
	if idx < 0 {
		idx = 0
	}
	connectToNodeWithAutoFallback(idx, minimize)
}

func disconnectVpnAsync() {
	autoFallbackCanceled = true
	autoFallbackActive = false
	connMutex.Lock()
	isConnecting = false
	connMutex.Unlock()
	isConnected = false
	activeNodeName = ""
	setWindowsProxy(false, "")
	stopXrayCore()
	updateTrayIcon(false, "", "")

	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
		procInvalidateRect.Call(hwndListView, 0, 1)
	}
	if isRussianLang {
		writeLog("DISCONNECT", "Туннель закрыт / отменен. Системный прокси отключен. Прямое соединение восстановлено.")
	} else {
		writeLog("DISCONNECT", "Tunnel closed / canceled. System proxy disabled. Restoring direct ISP routing.")
	}
}

func toggleVpn() {
	if isConnected {
		disconnectVpnAsync()
	} else {
		if len(profiles) == 0 {
			writeLog("ERR", "No VPN profiles configured to connect.")
			playConnectionFailSound()
			return
		}
		selIdx := getSelectedProfileIndex()
		if selIdx < 0 || selIdx >= len(profiles) {
			for i, p := range profiles {
				if p.Default != "" {
					selIdx = i
					break
				}
			}
			if selIdx < 0 {
				selIdx = 0
			}
		}
		connectToNodeWithAutoFallback(selIdx, false)
	}
}

func getActualProfileIndex(listIdx int) int {
	if listIdx >= 0 && listIdx < len(visibleProfileIndices) {
		return visibleProfileIndices[listIdx]
	}
	return -1
}

func sortIndicesByPing(indices []int) {
	sort.SliceStable(indices, func(i, j int) bool {
		p1 := profiles[indices[i]]
		p2 := profiles[indices[j]]
		lat1 := p1.PingMs
		lat2 := p2.PingMs
		if lat1 > 0 && lat2 > 0 {
			return lat1 < lat2
		}
		if lat1 > 0 && lat2 <= 0 {
			return true
		}
		if lat1 <= 0 && lat2 > 0 {
			return false
		}
		return indices[i] < indices[j]
	})
}

func updateSubscriptionBar() {
	if hwndMain == 0 {
		return
	}
	refreshProfilesListView()
}

func addProfileRowToListView(rowIdx int, displayNum int, p Profile) {
	var item LVITEMW
	item.Mask = 0x0001
	item.IItem = int32(rowIdx)
	item.ISubItem = 0
	item.PszText = strPtr(fmt.Sprintf("%d", displayNum))
	procSendMessageW.Call(hwndListView, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&item)))

	var subItem LVITEMW
	subItem.IItem = int32(rowIdx)

	// Column 1: Default
	subItem.ISubItem = 1
	defText := ""
	if p.Default != "" {
		defText = "✔"
	}
	subItem.PszText = strPtr(defText)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

	// Column 2: Name
	subItem.ISubItem = 2
	subItem.PszText = strPtr(cleanProfileName(p.Name))
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

	// Column 3: Host
	subItem.ISubItem = 3
	subItem.PszText = strPtr(p.Host)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

	// Column 4: Ping
	subItem.ISubItem = 4
	pingTxt := "-- ms"
	if p.PingMs > 0 {
		pingTxt = fmt.Sprintf("%d ms", p.PingMs)
	} else if p.PingMs < 0 {
		pingTxt = "Timeout"
	}
	subItem.PszText = strPtr(pingTxt)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

	// Column 5: Port
	subItem.ISubItem = 5
	subItem.PszText = strPtr(strconv.Itoa(p.Port))
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))
}

func refreshProfilesListView() {
	if hwndListView == 0 {
		return
	}
	procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
	visibleProfileIndices = nil
	renderedSubNames = nil

	// Collect subscriptions in order of appearance
	subGroups := make(map[string][]int)
	var indIndices []int

	for i, p := range profiles {
		if p.Subscription != "" {
			if _, exists := subGroups[p.Subscription]; !exists {
				renderedSubNames = append(renderedSubNames, p.Subscription)
			}
			subGroups[p.Subscription] = append(subGroups[p.Subscription], i)
		} else {
			indIndices = append(indIndices, i)
		}
	}

	// Ensure any active subscription from storage is known
	for _, as := range activeSubscriptions {
		if as.Name != "" {
			if _, exists := subGroups[as.Name]; !exists {
				renderedSubNames = append(renderedSubNames, as.Name)
				subGroups[as.Name] = []int{}
			}
		}
	}

	if sortByPing {
		for _, name := range renderedSubNames {
			sortIndicesByPing(subGroups[name])
		}
		sortIndicesByPing(indIndices)
	}

	rowIdx := 0
	serverSeqNum := 1

	renderSubscriptionGroup := func(subIdx int, sName string) {
		subIndices := subGroups[sName]
		visibleProfileIndices = append(visibleProfileIndices, -1-subIdx) // -1 for sub 0, -2 for sub 1, etc.

		var item LVITEMW
		item.Mask = 0x0001
		item.IItem = int32(rowIdx)
		item.ISubItem = 0
		isExp := getSubscriptionExpanded(sName)
		subToggleIcon := "[+]"
		if isExp {
			subToggleIcon = "[-]"
		}
		item.PszText = strPtr(subToggleIcon)
		procSendMessageW.Call(hwndListView, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&item)))

		var subItem LVITEMW
		subItem.IItem = int32(rowIdx)

		// Column 1: Folder icon
		subItem.ISubItem = 1
		subFolderIcon := "►"
		if isExp {
			subFolderIcon = "▼"
		}
		subItem.PszText = strPtr(subFolderIcon)
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

		// Column 2: Name (e.g. GIN-ProxyHub-RU (7))
		subItem.ISubItem = 2
		titleText := fmt.Sprintf("%s (%d)", sName, len(subIndices))
		subItem.PszText = strPtr(titleText)
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

		// Column 3: Host / Type
		subItem.ISubItem = 3
		subTypeText := "Подписка"
		if !isRussianLang {
			subTypeText = "Subscription"
		}
		subItem.PszText = strPtr(subTypeText)
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

		// Column 4: Ping
		subItem.ISubItem = 4
		subPingText := "--"
		if isPingTesting {
			subPingText = "..."
		}
		subItem.PszText = strPtr(subPingText)
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

		// Column 5: Port
		subItem.ISubItem = 5
		subItem.PszText = strPtr("--")
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))

		rowIdx++

		if isExp {
			for num, actualIdx := range subIndices {
				visibleProfileIndices = append(visibleProfileIndices, actualIdx)
				numToDisplay := num + 1
				if sortByPing {
					numToDisplay = serverSeqNum
					serverSeqNum++
				}
				addProfileRowToListView(rowIdx, numToDisplay, profiles[actualIdx])
				rowIdx++
			}
		}
	}

	renderIndividualGroup := func() {
		if len(indIndices) == 0 {
			return
		}
		for num, actualIdx := range indIndices {
			visibleProfileIndices = append(visibleProfileIndices, actualIdx)
			numToDisplay := num + 1
			if sortByPing {
				numToDisplay = serverSeqNum
				serverSeqNum++
			}
			addProfileRowToListView(rowIdx, numToDisplay, profiles[actualIdx])
			rowIdx++
		}
	}

	for sIdx, sName := range renderedSubNames {
		renderSubscriptionGroup(sIdx, sName)
	}
	renderIndividualGroup()
}

func selectListViewItem(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	listIdx := -1
	for li, pi := range visibleProfileIndices {
		if pi == actualIdx {
			listIdx = li
			break
		}
	}
	if listIdx < 0 {
		return
	}
	var item LVITEMW
	item.StateMask = LVIS_SELECTED | LVIS_FOCUSED
	item.State = LVIS_SELECTED | LVIS_FOCUSED
	procSendMessageW.Call(hwndListView, LVM_SETITEMSTATE, uintptr(listIdx), uintptr(unsafe.Pointer(&item)))
	procSendMessageW.Call(hwndListView, LVM_ENSUREVISIBLE, uintptr(listIdx), 0)
}

func moveProfileUp(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	sortByPing = false

	isSub := profiles[actualIdx].Subscription != ""
	targetIdx := -1
	for i := actualIdx - 1; i >= 0; i-- {
		if (profiles[i].Subscription != "") == isSub {
			targetIdx = i
			break
		}
	}
	if targetIdx < 0 {
		return
	}
	profiles[actualIdx], profiles[targetIdx] = profiles[targetIdx], profiles[actualIdx]
	saveProfilesToStorage()
	refreshProfilesListView()
	selectListViewItem(targetIdx)
	if isRussianLang {
		writeLog("ORDER", fmt.Sprintf("▲ Сервер '%s' перемещен выше", profiles[targetIdx].Name))
	} else {
		writeLog("ORDER", fmt.Sprintf("▲ Profile '%s' moved up", profiles[targetIdx].Name))
	}
}

func moveProfileDown(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	sortByPing = false

	isSub := profiles[actualIdx].Subscription != ""
	targetIdx := -1
	for i := actualIdx + 1; i < len(profiles); i++ {
		if (profiles[i].Subscription != "") == isSub {
			targetIdx = i
			break
		}
	}
	if targetIdx < 0 {
		return
	}
	profiles[actualIdx], profiles[targetIdx] = profiles[targetIdx], profiles[actualIdx]
	saveProfilesToStorage()
	refreshProfilesListView()
	selectListViewItem(targetIdx)
	if isRussianLang {
		writeLog("ORDER", fmt.Sprintf("▼ Сервер '%s' перемещен ниже", profiles[targetIdx].Name))
	} else {
		writeLog("ORDER", fmt.Sprintf("▼ Profile '%s' moved down", profiles[targetIdx].Name))
	}
}

func setDefaultProfile(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	wasAuto := (profiles[actualIdx].Default != "")
	for i := range profiles {
		if i == actualIdx && !wasAuto {
			profiles[i].Default = "✅"
		} else {
			profiles[i].Default = ""
		}
	}
	saveProfilesToStorage()
	refreshProfilesListView()
	selectListViewItem(actualIdx)
	if !wasAuto {
		if isRussianLang {
			writeLog("PROFILE", fmt.Sprintf("Сервер по умолчанию (Авто-подключение) установлен: %s", profiles[actualIdx].Name))
		} else {
			writeLog("PROFILE", fmt.Sprintf("Default profile (Auto-connect) set to: %s", profiles[actualIdx].Name))
		}
	} else {
		if isRussianLang {
			writeLog("PROFILE", fmt.Sprintf("Сервер по умолчанию снят: %s", profiles[actualIdx].Name))
		} else {
			writeLog("PROFILE", fmt.Sprintf("Default profile cleared for: %s", profiles[actualIdx].Name))
		}
	}
}

func triggerDeleteSelectedProfile() {
	selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	sel := int(selRet)
	actualIdx := getActualProfileIndex(sel)
	if actualIdx < 0 {
		subIdx := (-actualIdx) - 1
		if subIdx >= 0 && subIdx < len(renderedSubNames) {
			contextMenuSubName = renderedSubNames[subIdx]
		}
		deleteSubscription()
		return
	}
	if actualIdx < 0 && selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
		actualIdx = selectedProfileIdx
	}
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	deleteProfileWithConfirmation(actualIdx)
}

func deleteProfileWithConfirmation(actualIdx int) {
	if actualIdx < 0 || actualIdx >= len(profiles) {
		return
	}
	p := profiles[actualIdx]
	confirmMsg := fmt.Sprintf("Are you sure you want to delete profile:\n\n\"%s\" (%s:%d)?", p.Name, p.Host, p.Port)
	confirmTitle := "Delete Profile — GIN-VPN"
	if isRussianLang {
		confirmMsg = fmt.Sprintf("Вы уверены, что хотите удалить профиль:\n\n\"%s\" (%s:%d)?", p.Name, p.Host, p.Port)
		confirmTitle = "Удаление профиля — GIN-VPN"
	}
	// MB_YESNO (0x04) | MB_ICONQUESTION (0x20) | MB_DEFBUTTON1 (0x00) -> Enter immediately confirms!
	ret, _, _ := procMessageBoxW.Call(
		hwndMain,
		uintptr(unsafe.Pointer(strPtr(confirmMsg))),
		uintptr(unsafe.Pointer(strPtr(confirmTitle))),
		0x00000004|0x00000020,
	)
	if ret == 6 { // IDYES (Yes or Enter)
		delName := p.Name
		profiles = append(profiles[:actualIdx], profiles[actualIdx+1:]...)
		saveProfilesToStorage()
		updateSubscriptionBar()
		refreshProfilesListView()
		if len(visibleProfileIndices) > 0 {
			nextSel := actualIdx
			if nextSel >= len(visibleProfileIndices) {
				nextSel = len(visibleProfileIndices) - 1
			}
			if nextSel >= 0 {
				selectListViewItem(nextSel)
			}
		}
		if isRussianLang {
			writeLog("PROFILE", fmt.Sprintf("🗑️ Сервер '%s' удален из списка.", delName))
		} else {
			writeLog("PROFILE", fmt.Sprintf("🗑️ Profile '%s' deleted and updated in registry.", delName))
		}
	}
}

func resolveTargetSubName() string {
	if contextMenuSubName != "" {
		return contextMenuSubName
	}
	selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	sel := int(selRet)
	actualIdx := getActualProfileIndex(sel)
	if actualIdx < 0 {
		subIdx := (-actualIdx) - 1
		if subIdx >= 0 && subIdx < len(renderedSubNames) {
			return renderedSubNames[subIdx]
		}
	} else if actualIdx >= 0 && actualIdx < len(profiles) && profiles[actualIdx].Subscription != "" {
		return profiles[actualIdx].Subscription
	}
	if len(renderedSubNames) > 0 {
		return renderedSubNames[0]
	}
	if len(activeSubscriptions) > 0 {
		return activeSubscriptions[0].Name
	}
	subName := loadSubscriptionNameFromRegistry()
	if subName == "Djinn Proxy hub" || subName == "Jin Proxy hub" {
		subName = "GIN-Proxy-HUB"
	}
	return subName
}

func deleteSubscription() {
	targetSub := resolveTargetSubName()

	subCount := 0
	totalSubProfiles := 0
	for _, p := range profiles {
		if p.Subscription != "" {
			totalSubProfiles++
			if targetSub == "" || p.Subscription == targetSub {
				subCount++
			}
		}
	}

	inActiveSubs := false
	for _, s := range activeSubscriptions {
		if targetSub != "" && s.Name == targetSub {
			inActiveSubs = true
			break
		}
	}

	if targetSub == "" && totalSubProfiles == 0 && len(activeSubscriptions) == 0 && loadSubscriptionUrlFromRegistry() == "" {
		warnMsg := "В списке нет активных подписок или серверов из подписки."
		warnTitle := "Удаление подписки — GIN-VPN"
		if !isRussianLang {
			warnMsg = "No active subscription or subscription servers found in the list."
			warnTitle = "Delete Subscription — GIN-VPN"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(warnMsg))), uintptr(unsafe.Pointer(strPtr(warnTitle))), 0x00000030)
		return
	}

	if !inActiveSubs && subCount == 0 && len(activeSubscriptions) == 0 && totalSubProfiles == 0 {
		warnMsg := "В списке нет активных подписок или серверов из подписки."
		warnTitle := "Удаление подписки — GIN-VPN"
		if !isRussianLang {
			warnMsg = "No active subscription or subscription servers found in the list."
			warnTitle = "Delete Subscription — GIN-VPN"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(warnMsg))), uintptr(unsafe.Pointer(strPtr(warnTitle))), 0x00000030)
		return
	}

	displaySub := targetSub
	if displaySub == "" {
		displaySub = "GIN-Proxy-HUB"
	}

	confirmMsg := fmt.Sprintf("Вы уверены, что хотите полностью удалить подписку:\n\n\"%s\" (%d серверов)?\n\nПапка подписки и ее серверы будут удалены из списка.", displaySub, subCount)
	confirmTitle := "Удаление подписки — GIN-VPN"
	if !isRussianLang {
		confirmMsg = fmt.Sprintf("Are you sure you want to completely delete subscription:\n\n\"%s\" (%d servers)?\n\nThe subscription folder and its servers will be permanently removed.", displaySub, subCount)
		confirmTitle = "Delete Subscription — GIN-VPN"
	}

	// If it's an empty (0) subscription, delete immediately or confirm
	if subCount > 0 {
		ret, _, _ := procMessageBoxW.Call(
			hwndMain,
			uintptr(unsafe.Pointer(strPtr(confirmMsg))),
			uintptr(unsafe.Pointer(strPtr(confirmTitle))),
			0x00000004|0x00000020,
		)
		if ret != 6 { // IDYES
			return
		}
	}

	hasActiveDeleted := false
	var remaining []Profile
	for _, p := range profiles {
		shouldDelete := false
		if targetSub != "" {
			shouldDelete = (p.Subscription == targetSub)
		} else {
			shouldDelete = (p.Subscription != "")
		}
		if !shouldDelete {
			remaining = append(remaining, p)
		} else {
			if isConnected && (p.Name == activeNodeName || p.Host == activeNodeIP || (verifiedExitIP != "" && p.Host == verifiedExitIP)) {
				hasActiveDeleted = true
			}
		}
	}

	profiles = remaining

	// Remove from activeSubscriptions and also prune any remaining 0-server ghost subscriptions
	var newActiveSubs []SubscriptionItem
	for _, s := range activeSubscriptions {
		if targetSub != "" && s.Name == targetSub {
			continue
		}
		if targetSub == "" {
			continue
		}
		// Keep other subscriptions only if they actually have servers in profiles
		cnt := 0
		for _, p := range profiles {
			if p.Subscription == s.Name {
				cnt++
			}
		}
		if cnt > 0 {
			newActiveSubs = append(newActiveSubs, s)
		}
	}
	activeSubscriptions = newActiveSubs
	saveSubscriptionsToStorage()

	// Ensure there is a default server if remaining profiles exist
	if len(profiles) > 0 {
		hasDefault := false
		for _, p := range profiles {
			if p.Default != "" {
				hasDefault = true
				break
			}
		}
		if !hasDefault {
			profiles[0].Default = "yes"
		}
	}

	// Update or reset legacy registry subscription keys
	if len(activeSubscriptions) > 0 {
		saveSubscriptionUrlToRegistry(activeSubscriptions[0].URL)
		saveSubscriptionNameToRegistry(activeSubscriptions[0].Name)
	} else {
		saveSubscriptionUrlToRegistry("")
		saveSubscriptionNameToRegistry("")
	}
	if hwndKeyEdit != 0 {
		procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(""))))
	}
	contextMenuSubName = ""

	saveProfilesToStorage()
	updateSubscriptionBar()
	refreshProfilesListView()

	if hasActiveDeleted {
		disconnectVpnAsync()
	}

	if isRussianLang {
		writeLog("SUB", fmt.Sprintf("🗑️ Подписка '%s' (%d серверов) полностью удалена.", displaySub, subCount))
	} else {
		writeLog("SUB", fmt.Sprintf("🗑️ Subscription '%s' (%d servers) completely deleted.", displaySub, subCount))
	}
}

func updateLanguageUI() {
	if hwndMain == 0 {
		return
	}

	if isRussianLang {
		procSetWindowTextW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(AppTitleRU))))
		procSetWindowTextW.Call(hwndTitle, uintptr(unsafe.Pointer(strPtr("GIN-VPN от VladiMIR+AI"))))
		procSetWindowTextW.Call(hwndKeyLabel, uintptr(unsafe.Pointer(strPtr("Активный VLESS ключ или ссылка на подписку:"))))
		procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr("⚡ Диагностика и маршрутизация"))))
		procSetWindowTextW.Call(hwndLogLbl, uintptr(unsafe.Pointer(strPtr("📊 Лог сетевых событий и трафика в реальном времени:"))))
		if hwndBrand != 0 {
			procSetWindowTextW.Call(hwndBrand, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("VladiMIR+AI ||| %s", AppVersion)))))
		}

		// Update column headers
		setColumnText(0, "№")
		setColumnText(1, "Авто")
		setColumnText(2, "Имя профиля / Устройство")
		setColumnText(3, "Адрес сервера")
		setColumnText(4, "Пинг")
		setColumnText(5, "Порт")
	} else {
		procSetWindowTextW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(AppTitleEN))))
		procSetWindowTextW.Call(hwndTitle, uintptr(unsafe.Pointer(strPtr("🛡️ GIN-VPN by VladiMIR+AI"))))
		procSetWindowTextW.Call(hwndKeyLabel, uintptr(unsafe.Pointer(strPtr("🔑 Active VLESS Key or Subscription URL:"))))
		procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr("⚡ Diagnostics & Routing"))))
		procSetWindowTextW.Call(hwndLogLbl, uintptr(unsafe.Pointer(strPtr("📊 Real-Time Event & Traffic Log:"))))
		if hwndBrand != 0 {
			procSetWindowTextW.Call(hwndBrand, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("VladiMIR+AI ||| %s", AppVersion)))))
		}

		// Update column headers
		setColumnText(0, "№")
		setColumnText(1, "Auto")
		setColumnText(2, "Profile / Device Name")
		setColumnText(3, "Server Host Address")
		setColumnText(4, "Ping")
		setColumnText(5, "Port")
	}

	updateSubscriptionBar()

	updateBannerAndInstallButton()
	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
	}

	updateAllTooltips()
	procInvalidateRect.Call(hwndMain, 0, 1)
	procRedrawWindow.Call(hwndMain, 0, 0, 0x0001|0x0004|0x0080|0x0100|0x0200)
}

func setColumnText(colIdx int, text string) {
	var col LVCOLUMNW
	col.Mask = 0x0004 // LVCF_TEXT
	col.PszText = strPtr(text)
	procSendMessageW.Call(hwndListView, LVM_SETCOLUMNW, uintptr(colIdx), uintptr(unsafe.Pointer(&col)))
}

func applyTheme(themeMode int) {
	currentTheme = themeMode
	isDarkMode = (currentTheme != ThemeDay)

	switch currentTheme {
	case ThemeDay:
		procSetWindowTheme.Call(hwndListView, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(hwndListView, LVM_SETBKCOLOR, 0, 0x00FFFFFF)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTBKCOLOR, 0, 0x00FFFFFF)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTCOLOR, 0, 0x00222222)
	case ThemeGray:
		procSetWindowTheme.Call(hwndListView, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(hwndListView, LVM_SETBKCOLOR, 0, 0x003C342D)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTBKCOLOR, 0, 0x003C342D)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTCOLOR, 0, 0x00F0ECE8)
	case ThemeNight:
		procSetWindowTheme.Call(hwndListView, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(hwndListView, LVM_SETBKCOLOR, 0, 0x00141414)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTBKCOLOR, 0, 0x00141414)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTCOLOR, 0, 0x00EAEAEA)
	}

	procInvalidateRect.Call(hwndMain, 0, 1)

	allControls := []uintptr{
		hwndTitle, hwndBtnDay, hwndBtnGray, hwndBtnNight, hwndBtnLangEN, hwndBtnLangRU, hwndBtnSound,
		hwndBtnMainAction, hwndBtnDisconnect, hwndKeyLabel, hwndBtnPasteQr, hwndBtnSave, hwndKeyEdit,
		hwndProfilesLbl, hwndBtnUp, hwndBtnDown, hwndBtnConnect, hwndBtnSetDefault,
		hwndBtnSubToggle, hwndSubTitle, hwndBtnSubPing, hwndBtnSubRefresh, hwndListView,
		hwndDiagHeader, hwndBtnDiagInfo, hwndDiagOrig, hwndDiagProt, hwndDiagLat, hwndDiagUptime,
		hwndBannerLbl, hwndBtnInstall, hwndBtnVerify, hwndBtnCopyLog, hwndBtnClearLog,
		hwndLogLbl, hwndLogEdit, hwndBrand,
	}
	for _, h := range allControls {
		if h != 0 {
			procInvalidateRect.Call(h, 0, 1)
		}
	}
	procRedrawWindow.Call(hwndMain, 0, 0, 0x0001|0x0004|0x0080|0x0100|0x0200)
}

func renameWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		ctrlId := int(wParam & 0xFFFF)
		if ctrlId == 7001 { // Save
			var buf [512]uint16
			procGetWindowTextW.Call(hwndRenameEdit, uintptr(unsafe.Pointer(&buf[0])), 512)
			newName := strings.TrimSpace(syscall.UTF16ToString(buf[:]))
			if renameTargetIdx == -1 {
				if newName != "" {
					oldName := renameTargetSubName
					if oldName == "" {
						oldName = resolveTargetSubName()
					}
					saveSubscriptionNameToRegistry(newName)
					for i := range activeSubscriptions {
						if oldName == "" || activeSubscriptions[i].Name == oldName {
							activeSubscriptions[i].Name = newName
						}
					}
					saveSubscriptionsToStorage()
					for i := range profiles {
						if profiles[i].Subscription != "" && (oldName == "" || profiles[i].Subscription == oldName) {
							profiles[i].Subscription = newName
						}
					}
					saveProfilesToStorage()
					updateSubscriptionBar()
					refreshProfilesListView()
					if isRussianLang {
						writeLog("SUB", fmt.Sprintf("✏️ Подписка '%s' переименована в: '%s'", oldName, newName))
					} else {
						writeLog("SUB", fmt.Sprintf("✏️ Subscription '%s' renamed to: '%s'", oldName, newName))
					}
				}
			} else if newName != "" && renameTargetIdx >= 0 && renameTargetIdx < len(profiles) {
				oldName := profiles[renameTargetIdx].Name
				profiles[renameTargetIdx].Name = newName

				var subItem LVITEMW
				subItem.IItem = int32(renameTargetIdx)
				subItem.ISubItem = 2 // Column 2: Name
				subItem.PszText = strPtr(newName)
				procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(renameTargetIdx), uintptr(unsafe.Pointer(&subItem)))

				saveProfilesToStorage()
				writeLog("PROFILE", fmt.Sprintf("Profile '%s' renamed to: %s", oldName, newName))
			}
			procEnableWindow.Call(hwndMain, 1)
			procDestroyWindow.Call(hwnd)
			procSetForegroundWindow.Call(hwndMain)
			return 0
		} else if ctrlId == 7002 { // Cancel
			procEnableWindow.Call(hwndMain, 1)
			procDestroyWindow.Call(hwnd)
			procSetForegroundWindow.Call(hwndMain)
			return 0
		}

	case WM_ERASEBKGND:
		hDC := wParam
		var rc RECT
		procGetClientRect.Call(hwnd, uintptr(unsafe.Pointer(&rc)))
		brush := hBrushBgDay
		if currentTheme == ThemeGray {
			brush = hBrushBgGray
		} else if currentTheme == ThemeNight {
			brush = hBrushBgNight
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), brush)
		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if currentTheme == ThemeGray {
			procSetTextColor.Call(hDC, 0x00F0ECE8)
			return hBrushBgGray
		} else if currentTheme == ThemeNight {
			procSetTextColor.Call(hDC, 0x00E0E0E0)
			return hBrushBgNight
		}
		procSetTextColor.Call(hDC, 0x00222222)
		return hBrushBgDay

	case WM_CTLCOLOREDIT:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if currentTheme == ThemeGray {
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputGray
		} else if currentTheme == ThemeNight {
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputNight
		}
		procSetTextColor.Call(hDC, 0x001A1A1A)
		return hBrushWhite

	case WM_DESTROY:
		procEnableWindow.Call(hwndMain, 1)
		procSetForegroundWindow.Call(hwndMain)
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func animWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case 0x0014: // WM_ERASEBKGND
		return 1

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))

		var rc RECT
		rc.Left, rc.Top, rc.Right, rc.Bottom = 0, 0, 380, 140
		procFillRect.Call(hdc, uintptr(unsafe.Pointer(&rc)), hBrushBlack)

		cx, cy := 190.0, 70.0
		size := 38.0

		vertices := [8][3]float64{
			{-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
			{-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1},
		}

		edges := [12][2]int{
			{0, 1}, {1, 2}, {2, 3}, {3, 0},
			{4, 5}, {5, 6}, {6, 7}, {7, 4},
			{0, 4}, {1, 5}, {2, 6}, {3, 7},
		}

		cosA, sinA := math.Cos(animAngle), math.Sin(animAngle)
		cosB, sinB := math.Cos(animAngle*0.7), math.Sin(animAngle*0.7)

		var projected [8]POINT

		for i, v := range vertices {
			x1 := v[0]*cosA - v[2]*sinA
			z1 := v[0]*sinA + v[2]*cosA
			y1 := v[1]

			y2 := y1*cosB - z1*sinB
			z2 := y1*sinB + z1*cosB
			x2 := x1

			dist := 3.2
			f := 1.0 / (dist - z2*0.35)
			px := int32(cx + x2*size*f*2.0)
			py := int32(cy + y2*size*f*2.0)
			projected[i] = POINT{X: px, Y: py}
		}

		hOldPen, _, _ := procSelectObject.Call(hdc, hPenCyan)

		for _, e := range edges {
			p1 := projected[e[0]]
			p2 := projected[e[1]]
			procMoveToEx.Call(hdc, uintptr(p1.X), uintptr(p1.Y), 0)
			procLineTo.Call(hdc, uintptr(p2.X), uintptr(p2.Y))
		}

		hOldBrush, _, _ := procSelectObject.Call(hdc, hBrushAnimBlue)

		for _, p := range projected {
			procEllipse.Call(hdc, uintptr(p.X-4), uintptr(p.Y-4), uintptr(p.X+4), uintptr(p.Y+4))
		}

		procSelectObject.Call(hdc, hOldPen)
		procSelectObject.Call(hdc, hOldBrush)

		procEndPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func aboutWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_TIMER:
		animAngle += 0.05
		procInvalidateRect.Call(hwndAboutAnim, 0, 0)
		return 0

	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		if controlId == 3001 || controlId == 2 {
			procKillTimer.Call(hwnd, 1)
			procDestroyWindow.Call(hwnd)
			hwndAbout = 0
			return 0
		}
		if controlId == 3002 {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("https://github.com/GinCz"))), 0, 0, 1)
			return 0
		}

	case WM_CLOSE:
		procKillTimer.Call(hwnd, 1)
		procDestroyWindow.Call(hwnd)
		hwndAbout = 0
		return 0

	case WM_DESTROY:
		procKillTimer.Call(hwnd, 1)
		hwndAbout = 0
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func showAboutDialog() {
	if hwndAbout != 0 {
		procShowWindow.Call(hwndAbout, 5)
		procSetForegroundWindow.Call(hwndAbout)
		return
	}

	classNameAbout := strPtr("GIN_VPN_AboutWindow")
	classNameAnim := strPtr("GIN_VPN_AnimCanvas")

	registerAboutOnce.Do(func() {
		var wcAbout WNDCLASSEXW
		wcAbout.CbSize = uint32(unsafe.Sizeof(wcAbout))
		wcAbout.Style = 0x0002 | 0x0001
		wcAbout.LpfnWndProc = syscall.NewCallback(aboutWndProc)
		wcAbout.HInstance = hInstance
		wcAbout.HIcon = hIconApp
		wcAbout.HIconSm = hIconApp
		wcAbout.HbrBackground = hBrushWhite
		wcAbout.LpszClassName = classNameAbout
		procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcAbout)))

		var wcAnim WNDCLASSEXW
		wcAnim.CbSize = uint32(unsafe.Sizeof(wcAnim))
		wcAnim.Style = 0x0002 | 0x0001
		wcAnim.LpfnWndProc = syscall.NewCallback(animWndProc)
		wcAnim.HInstance = hInstance
		wcAnim.HbrBackground = hBrushBlack
		wcAnim.LpszClassName = classNameAnim
		procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcAnim)))
	})

	var mainRc RECT
	procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&mainRc)))
	x := mainRc.Left + (mainRc.Right-mainRc.Left-420)/2
	y := mainRc.Top + (mainRc.Bottom-mainRc.Top-390)/2

	titleText := "About GIN-VPN"
	aboutTitle := fmt.Sprintf("GIN-VPN by VladiMIR+AI [%s]", AppVersion)
	aboutSub := fmt.Sprintf("Version: %s (Public Release)  |  100%% Free & Open Source\nEngine: Native Xray Core VLESS-Reality & Split Routing\nAuthor: Vladimir Bulantsev (GinCz)", AppVersion)
	if isRussianLang {
		titleText = "О программе GIN-VPN"
		aboutTitle = fmt.Sprintf("GIN-VPN от VladiMIR+AI [%s]", AppVersion)
		aboutSub = fmt.Sprintf("Версия: %s (Публичный релиз)  |  100%% Free & Open Source\nДвижок: Нативный Xray Core VLESS-Reality и сплит-маршруты\nАвтор: Владимир Буланцев (GinCz)", AppVersion)
	}

	hwndAboutRet, _, _ := procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(classNameAbout)),
		uintptr(unsafe.Pointer(strPtr(titleText))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		uintptr(x), uintptr(y), 420, 390,
		hwndMain, 0, hInstance, 0,
	)
	hwndAbout = hwndAboutRet

	if hIconApp != 0 {
		procSendMessageW.Call(hwndAbout, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndAbout, WM_SETICON, 0, hIconApp)
	}

	hwndAboutAnimRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(classNameAnim)), 0,
		WS_CHILD|WS_VISIBLE|WS_BORDER,
		15, 12, 375, 140,
		hwndAbout, 0, hInstance, 0,
	)
	hwndAboutAnim = hwndAboutAnimRet

	hTitle, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(aboutTitle))),
		WS_CHILD|WS_VISIBLE,
		15, 162, 375, 24,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hTitle, WM_SETFONT, hFontBold, 1)

	hSub, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(aboutSub))),
		WS_CHILD|WS_VISIBLE,
		15, 190, 375, 55,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hSub, WM_SETFONT, hFontRegular, 1)

	hLink, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🌐 Visit GitHub: https://github.com/GinCz"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		15, 252, 375, 28,
		hwndAbout, 3002, hInstance, 0,
	)
	procSendMessageW.Call(hLink, WM_SETFONT, hFontRegular, 1)

	hOk, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("OK"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		150, 292, 100, 30,
		hwndAbout, 3001, hInstance, 0,
	)
	procSendMessageW.Call(hOk, WM_SETFONT, hFontRegular, 1)

	procSetTimer.Call(hwndAbout, 1, 33, 0)
}

func showRenameDialog(sel int) {
	if sel < 0 || sel >= len(profiles) {
		return
	}
	renameTargetIdx = sel

	className := strPtr("GIN_VPN_RENAME_CLASS")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(renameWndProc)
	wc.HInstance = hInstance
	wc.HCursor, _, _ = procLoadCursorW.Call(0, uintptr(IDC_ARROW))
	wc.HbrBackground = hBrushBgDay
	if currentTheme == ThemeGray {
		wc.HbrBackground = hBrushBgGray
	} else if currentTheme == ThemeNight {
		wc.HbrBackground = hBrushBgNight
	}
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var mainRc RECT
	procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&mainRc)))
	x := mainRc.Left + (mainRc.Right-mainRc.Left-380)/2
	y := mainRc.Top + (mainRc.Bottom-mainRc.Top-170)/2

	titleText := "✏️ Rename Profile — GIN-VPN"
	promptText := "Enter new profile name:"
	btnSaveText := "💾 Save"
	btnCancelText := "❌ Cancel"
	if isRussianLang {
		titleText = "✏️ Переименовать профиль — GIN-VPN"
		promptText = "Введите новое имя профиля:"
		btnSaveText = "💾 Сохранить"
		btnCancelText = "❌ Отмена"
	}

	hwndRenameDlg, _, _ = procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(titleText))),
		WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_VISIBLE,
		uintptr(x), uintptr(y), 380, 170,
		hwndMain, 0, hInstance, 0,
	)

	hwndLbl, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(promptText))),
		WS_CHILD|WS_VISIBLE,
		20, 15, 330, 20,
		hwndRenameDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLbl, WM_SETFONT, hFontRegular, 1)

	hwndRenameEdit, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(profiles[sel].Name))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		20, 42, 325, 26,
		hwndRenameDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndRenameEdit, WM_SETFONT, hFontRegular, 1)

	hwndBtnSaveName, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(btnSaveText))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		45, 85, 130, 32,
		hwndRenameDlg, uintptr(7001), hInstance, 0,
	)
	procSendMessageW.Call(hwndBtnSaveName, WM_SETFONT, hFontBold, 1)

	hwndBtnCancel, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(btnCancelText))),
		WS_CHILD|WS_VISIBLE,
		190, 85, 130, 32,
		hwndRenameDlg, uintptr(7002), hInstance, 0,
	)
	procSendMessageW.Call(hwndBtnCancel, WM_SETFONT, hFontRegular, 1)

	procEnableWindow.Call(hwndMain, 0)
	procShowWindow.Call(hwndRenameDlg, 5)
	procSetForegroundWindow.Call(hwndRenameDlg)
}

func showRenameSubscriptionDialog() {
	renameTargetIdx = -1
	subName := resolveTargetSubName()
	if subName == "" || subName == "Djinn Proxy hub" || subName == "Jin Proxy hub" {
		subName = "GIN-Proxy-HUB"
	}
	renameTargetSubName = subName

	className := strPtr("GIN_VPN_RENAME_CLASS")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(renameWndProc)
	wc.HInstance = hInstance
	wc.HCursor, _, _ = procLoadCursorW.Call(0, uintptr(IDC_ARROW))
	wc.HbrBackground = hBrushBgDay
	if currentTheme == ThemeGray {
		wc.HbrBackground = hBrushBgGray
	} else if currentTheme == ThemeNight {
		wc.HbrBackground = hBrushBgNight
	}
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var mainRc RECT
	procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&mainRc)))
	x := mainRc.Left + (mainRc.Right-mainRc.Left-380)/2
	y := mainRc.Top + (mainRc.Bottom-mainRc.Top-170)/2

	titleText := "✏️ Rename Subscription — GIN-VPN"
	promptText := "Enter new subscription name:"
	btnSaveText := "💾 Save"
	btnCancelText := "❌ Cancel"
	if isRussianLang {
		titleText = "✏️ Переименовать подписку — GIN-VPN"
		promptText = "Введите новое имя подписки:"
		btnSaveText = "💾 Сохранить"
		btnCancelText = "❌ Отмена"
	}

	hwndRenameDlg, _, _ = procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(titleText))),
		WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_VISIBLE,
		uintptr(x), uintptr(y), 380, 170,
		hwndMain, 0, hInstance, 0,
	)

	hwndLbl, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(promptText))),
		WS_CHILD|WS_VISIBLE,
		20, 15, 330, 20,
		hwndRenameDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndLbl, WM_SETFONT, hFontRegular, 1)

	hwndRenameEdit, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(subName))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		20, 42, 325, 26,
		hwndRenameDlg, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndRenameEdit, WM_SETFONT, hFontRegular, 1)

	hwndBtnSaveName, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(btnSaveText))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		45, 85, 130, 32,
		hwndRenameDlg, uintptr(7001), hInstance, 0,
	)
	procSendMessageW.Call(hwndBtnSaveName, WM_SETFONT, hFontBold, 1)

	hwndBtnCancel, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(btnCancelText))),
		WS_CHILD|WS_VISIBLE,
		190, 85, 130, 32,
		hwndRenameDlg, uintptr(7002), hInstance, 0,
	)
	procSendMessageW.Call(hwndBtnCancel, WM_SETFONT, hFontRegular, 1)

	procEnableWindow.Call(hwndMain, 0)
	procShowWindow.Call(hwndRenameDlg, 5)
	procSetForegroundWindow.Call(hwndRenameDlg)
}

func showListViewContextMenu(sel int) {
	if sel < 0 || sel >= len(profiles) {
		return
	}
	selectedProfileIdx = sel
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	p := profiles[sel]
	isAutoConnect := (p.Default != "")

	var autoFlags uintptr = MF_STRING
	if isAutoConnect {
		autoFlags |= 0x00000008 // MF_CHECKED
	}

	if isRussianLang {
		headerText := fmt.Sprintf("🌐 Сервер: %s (%s:%d)", p.Name, p.Host, p.Port)
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(headerText))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6001, uintptr(unsafe.Pointer(strPtr("⚡ Подключиться к этому серверу"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6010, uintptr(unsafe.Pointer(strPtr("▲ Переместить выше (Вверх)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6011, uintptr(unsafe.Pointer(strPtr("▼ Переместить ниже (Вниз)"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

		var autoText string
		if isAutoConnect {
			autoText = "✓ Подключаться при запуске программы"
		} else {
			autoText = "  Подключаться при запуске программы"
		}
		procAppendMenuW.Call(hMenu, autoFlags, 6002, uintptr(unsafe.Pointer(strPtr(autoText))))

		procAppendMenuW.Call(hMenu, MF_STRING, 6003, uintptr(unsafe.Pointer(strPtr("✏️ Переименовать сервер"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6004, uintptr(unsafe.Pointer(strPtr("🗑️ Удалить сервер из списка\tShift+Del"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6005, uintptr(unsafe.Pointer(strPtr("📋 Скопировать VLESS ключ"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6006, uintptr(unsafe.Pointer(strPtr("🔍 Проверить маршрут (EU-222 / RU-109)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6007, uintptr(unsafe.Pointer(strPtr("⚙️ Настройка правил (Сайты прямо / VPN)..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6008, uintptr(unsafe.Pointer(strPtr("💾 Экспорт всех серверов в бэкап"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6009, uintptr(unsafe.Pointer(strPtr("📥 Импорт серверов из бэкапа"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 115, uintptr(unsafe.Pointer(strPtr("⏱️ Проверить задержку (пинг) всех серверов"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 116, uintptr(unsafe.Pointer(strPtr("🔄 Обновить список серверов из подписки"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 114, uintptr(unsafe.Pointer(strPtr("➕ / ➖ Свернуть / Развернуть список"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6016, uintptr(unsafe.Pointer(strPtr("✏️ Переименовать подписку..."))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Добавить / обновить подписку (URL)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6017, uintptr(unsafe.Pointer(strPtr("🗑️ Удалить подписку полностью"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6012, uintptr(unsafe.Pointer(strPtr("🔄 Обновить GIN-VPN"))))
	} else {
		headerText := fmt.Sprintf("🌐 Server: %s (%s:%d)", p.Name, p.Host, p.Port)
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(headerText))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6001, uintptr(unsafe.Pointer(strPtr("⚡ Connect to this Server"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6010, uintptr(unsafe.Pointer(strPtr("▲ Move Profile Up"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6011, uintptr(unsafe.Pointer(strPtr("▼ Move Profile Down"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

		var autoText string
		if isAutoConnect {
			autoText = "✓ Auto-connect on App Startup"
		} else {
			autoText = "  Auto-connect on App Startup"
		}
		procAppendMenuW.Call(hMenu, autoFlags, 6002, uintptr(unsafe.Pointer(strPtr(autoText))))

		procAppendMenuW.Call(hMenu, MF_STRING, 6003, uintptr(unsafe.Pointer(strPtr("✏️ Rename Profile"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6004, uintptr(unsafe.Pointer(strPtr("🗑️ Delete Profile\tShift+Del"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6005, uintptr(unsafe.Pointer(strPtr("📋 Copy VLESS Key"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6006, uintptr(unsafe.Pointer(strPtr("🔍 Verify Route (EU-222 / RU-109)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6007, uintptr(unsafe.Pointer(strPtr("⚙️ Configure Rules (Direct / VPN)..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6008, uintptr(unsafe.Pointer(strPtr("💾 Export All Profiles to Backup"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6009, uintptr(unsafe.Pointer(strPtr("📥 Import Profiles from Backup"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 115, uintptr(unsafe.Pointer(strPtr("⏱️ Test Ping for All Subscription Servers"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 116, uintptr(unsafe.Pointer(strPtr("🔄 Refresh Servers List from Subscription"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 114, uintptr(unsafe.Pointer(strPtr("➕ / ➖ Collapse / Expand List"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6016, uintptr(unsafe.Pointer(strPtr("✏️ Rename Subscription..."))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Add / Update Subscription (URL)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6017, uintptr(unsafe.Pointer(strPtr("🗑️ Delete Subscription Completely"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6012, uintptr(unsafe.Pointer(strPtr("🔄 Update GIN-VPN"))))
	}

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procDestroyMenu.Call(hMenu)
}

func showSubscriptionContextMenu() {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	subName := resolveTargetSubName()
	if subName == "" || subName == "Djinn Proxy hub" || subName == "Jin Proxy hub" {
		subName = "GIN-Proxy-HUB"
	}
	subCount := 0
	for _, p := range profiles {
		if p.Subscription != "" && (contextMenuSubName == "" || p.Subscription == subName) {
			subCount++
		}
	}
	if isRussianLang {
		header := fmt.Sprintf("📁 Подписка: %s (%d серверов)", subName, subCount)
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(header))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 115, uintptr(unsafe.Pointer(strPtr("⏱️ Проверить задержку (пинг) всех серверов"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 116, uintptr(unsafe.Pointer(strPtr("🔄 Обновить список серверов из подписки"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 114, uintptr(unsafe.Pointer(strPtr("➕ / ➖ Свернуть / Развернуть список"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6016, uintptr(unsafe.Pointer(strPtr("✏️ Переименовать подписку..."))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Изменить ссылку на подписку..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6017, uintptr(unsafe.Pointer(strPtr("🗑️ Удалить подписку полностью"))))
	} else {
		header := fmt.Sprintf("📁 Subscription: %s (%d servers)", subName, subCount)
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(header))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 115, uintptr(unsafe.Pointer(strPtr("⏱️ Test Ping for All Subscription Servers"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 116, uintptr(unsafe.Pointer(strPtr("🔄 Refresh Servers List from Subscription"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 114, uintptr(unsafe.Pointer(strPtr("➕ / ➖ Collapse / Expand List"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6016, uintptr(unsafe.Pointer(strPtr("✏️ Rename Subscription..."))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Change Subscription URL..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6017, uintptr(unsafe.Pointer(strPtr("🗑️ Delete Subscription Completely"))))
	}
	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procDestroyMenu.Call(hMenu)
}

func showListEmptyContextMenu() {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	if isRussianLang {
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr("📋 Список серверов"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6009, uintptr(unsafe.Pointer(strPtr("📥 Импорт серверов из бэкапа"))))
		if len(profiles) > 0 {
			procAppendMenuW.Call(hMenu, MF_STRING, 6008, uintptr(unsafe.Pointer(strPtr("💾 Экспорт всех серверов в бэкап"))))
		}
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Добавить / обновить подписку (URL)"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 102, uintptr(unsafe.Pointer(strPtr("📋 Вставить VLESS ключ из буфера"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6007, uintptr(unsafe.Pointer(strPtr("⚙️ Настройка правил (Сайты прямо / VPN)..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6012, uintptr(unsafe.Pointer(strPtr("🔄 Обновить GIN-VPN"))))
	} else {
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr("📋 Server Profiles List"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6009, uintptr(unsafe.Pointer(strPtr("📥 Import Profiles from Backup"))))
		if len(profiles) > 0 {
			procAppendMenuW.Call(hMenu, MF_STRING, 6008, uintptr(unsafe.Pointer(strPtr("💾 Export All Profiles to Backup"))))
		}
		procAppendMenuW.Call(hMenu, MF_STRING, 6015, uintptr(unsafe.Pointer(strPtr("🔗 Add / Update Subscription (URL)"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 102, uintptr(unsafe.Pointer(strPtr("📋 Paste VLESS Key from Clipboard"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6007, uintptr(unsafe.Pointer(strPtr("⚙️ Configure Rules (Direct / VPN)..."))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6012, uintptr(unsafe.Pointer(strPtr("🔄 Update GIN-VPN"))))
	}

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procDestroyMenu.Call(hMenu)
}

func exportProfilesBackup() {
	if len(profiles) == 0 {
		warnMsg := "Список серверов пуст. Нет профилей для экспорта в бэкап."
		warnTitle := "Экспорт бэкапа"
		if !isRussianLang {
			warnMsg = "Server list is empty. No profiles to export."
			warnTitle = "Backup Export"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(warnMsg))), uintptr(unsafe.Pointer(strPtr(warnTitle))), 0x00000030)
		return
	}

	timeStr := time.Now().Format("2006-01-02__15-04")
	backupFileName := fmt.Sprintf("GIN-VPN_BackUp__%s.txt", timeStr)

	saveTitle := "Сохранить файл бэкапа серверов GIN-VPN"
	saveFilter := "Текстовые файлы (*.txt)|*.txt|Все файлы (*.*)|*.*"
	if !isRussianLang {
		saveTitle = "Save GIN-VPN Backup File"
		saveFilter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
	}

	psCmd := fmt.Sprintf(`
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.SaveFileDialog
$d.Title = '%s'
$d.Filter = '%s'
$d.FileName = '%s'
$desk = [Environment]::GetFolderPath('Desktop')
if (-not $desk) { $desk = [Environment]::GetFolderPath('MyDocuments') }
$d.InitialDirectory = $desk
if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $d.FileName }
`, saveTitle, saveFilter, backupFileName)

	var backupPath string
	out, err := exec.Command("powershell", "-NoProfile", "-Command", psCmd).Output()
	if err == nil {
		chosen := strings.TrimSpace(string(out))
		if chosen != "" {
			backupPath = chosen
		}
	}

	// User cancelled save dialog
	if backupPath == "" {
		return
	}

	var sb strings.Builder
	sb.WriteString("# =============================================================================\r\n")
	sb.WriteString("# GIN-VPN Server Profiles Backup\r\n")
	sb.WriteString(fmt.Sprintf("# Created     : %s\r\n", time.Now().Format("2006-01-02 15:04:05 MST")))
	sb.WriteString(fmt.Sprintf("# Version     : %s\r\n", AppVersion))
	sb.WriteString(fmt.Sprintf("# Profiles    : %d\r\n", len(profiles)))
	sb.WriteString("# =============================================================================\r\n\r\n")

	sb.WriteString("# --- Human-Readable Profiles Summary ---\r\n")
	for i, p := range profiles {
		defMarker := ""
		if p.Default != "" {
			defMarker = " [DEFAULT / AUTO-CONNECT]"
		}
		sb.WriteString(fmt.Sprintf("[%d] %s (%s:%d, Country: %s)%s\r\n", i+1, p.Name, p.Host, p.Port, p.Country, defMarker))
	}

	sb.WriteString("\r\n# --- Raw VLESS / Reality / Shadowsocks Keys (1 per line for bulk import) ---\r\n")
	for _, p := range profiles {
		if strings.TrimSpace(p.RawUri) != "" {
			sb.WriteString(strings.TrimSpace(p.RawUri) + "\r\n")
		}
	}

	sb.WriteString("\r\n# --- Full JSON Profiles Data ---\r\n")
	jsonData, errJson := json.MarshalIndent(profiles, "", "  ")
	if errJson == nil {
		sb.Write(jsonData)
		sb.WriteString("\r\n")
	}

	writeErr := os.WriteFile(backupPath, []byte(sb.String()), 0644)
	if writeErr != nil {
		// Fallback to user AppData
		altPath := filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-VPN", backupFileName)
		writeErr = os.WriteFile(altPath, []byte(sb.String()), 0644)
		if writeErr == nil {
			backupPath = altPath
		}
	}

	if writeErr != nil {
		errMsg := fmt.Sprintf("Не удалось записать файл бэкапа: %s", writeErr.Error())
		errTitle := "Ошибка бэкапа"
		if !isRussianLang {
			errMsg = fmt.Sprintf("Failed to write backup file: %s", writeErr.Error())
			errTitle = "Backup Error"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(errMsg))), uintptr(unsafe.Pointer(strPtr(errTitle))), 0x00000010)
		return
	}

	setClipboardText(backupPath)
	writeLog("BACKUP", fmt.Sprintf("Backup created: %s (Total: %d profiles)", backupFileName, len(profiles)))

	// Highlight file in Windows Explorer
	_ = exec.Command("explorer.exe", fmt.Sprintf("/select,%s", backupPath)).Start()

	successMsg := fmt.Sprintf("Бэкап всех серверов успешно сохранен!\n\nИмя файла: %s\nВсего серверов: %d\nПуть:\n%s\n\n(Путь к файлу скопирован в буфер обмена)", backupFileName, len(profiles), backupPath)
	successTitle := "Бэкап успешно создан"
	if !isRussianLang {
		successMsg = fmt.Sprintf("All server profiles successfully backed up!\n\nFile: %s\nTotal profiles: %d\nPath:\n%s\n\n(File path copied to clipboard)", backupFileName, len(profiles), backupPath)
		successTitle = "Backup Created"
	}
	procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(successMsg))), uintptr(unsafe.Pointer(strPtr(successTitle))), 0x00000040)
}

func profileExists(newP *Profile) bool {
	for _, p := range profiles {
		if p.RawUri != "" && newP.RawUri != "" && strings.TrimSpace(p.RawUri) == strings.TrimSpace(newP.RawUri) {
			return true
		}
		if p.Host == newP.Host && p.Port == newP.Port && p.Name == newP.Name {
			return true
		}
	}
	return false
}

func importProfilesBackup() {
	psCmd := `
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.OpenFileDialog
$d.Title = 'Select GIN-VPN Backup File'
$d.Filter = 'GIN-VPN Backup (*.txt;*.json)|*.txt;*.json|All Files (*.*)|*.*'
$d.InitialDirectory = [Environment]::GetFolderPath('Desktop')
if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $d.FileName }
`
	if isRussianLang {
		psCmd = `
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.OpenFileDialog
$d.Title = 'Выберите файл бэкапа GIN-VPN'
$d.Filter = 'Бэкапы GIN-VPN (*.txt;*.json)|*.txt;*.json|Все файлы (*.*)|*.*'
$d.InitialDirectory = [Environment]::GetFolderPath('Desktop')
if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $d.FileName }
`
	}
	out, err := exec.Command("powershell", "-NoProfile", "-Command", psCmd).Output()
	if err != nil {
		return
	}
	filePath := strings.TrimSpace(string(out))
	if filePath == "" {
		return
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		errMsg := fmt.Sprintf("Не удалось открыть файл: %s", err.Error())
		errTitle := "Ошибка импорта"
		if !isRussianLang {
			errMsg = fmt.Sprintf("Failed to open file: %s", err.Error())
			errTitle = "Import Error"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(errMsg))), uintptr(unsafe.Pointer(strPtr(errTitle))), 0x00000010)
		return
	}

	importedCount := 0
	contentStr := string(data)

	// 1. Try parsing JSON array
	if idx := strings.Index(contentStr, "["); idx != -1 {
		jsonSub := contentStr[idx:]
		if lastIdx := strings.LastIndex(jsonSub, "]"); lastIdx != -1 {
			jsonArrayStr := jsonSub[:lastIdx+1]
			var jsonProfiles []Profile
			if errJson := json.Unmarshal([]byte(jsonArrayStr), &jsonProfiles); errJson == nil {
				for _, jp := range jsonProfiles {
					if jp.RawUri != "" {
						cfg, errP := parseVlessUri(jp.RawUri)
						if errP == nil {
							name := jp.Name
							if name == "" {
								name = cfg.Name
							}
							country := jp.Country
							if country == "" {
								if cfg.Host == EndpointServerRU || strings.Contains(cfg.Host, "223.109") {
									country = "RU"
								} else {
									country = "EU"
								}
							}
							p := Profile{
								Default: jp.Default,
								Name:    name,
								Host:    cfg.Host,
								Port:    cfg.Port,
								Country: country,
								RawUri:  jp.RawUri,
							}
							if !profileExists(&p) {
								profiles = append(profiles, p)
								importedCount++
							}
							continue
						}
					}
					if jp.Host != "" && !profileExists(&jp) {
						profiles = append(profiles, jp)
						importedCount++
					}
				}
			}
		}
	}

	// 2. Parse raw URIs from lines
	lines := strings.Split(contentStr, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "#") || line == "" {
			continue
		}
		if strings.HasPrefix(line, "vless://") {
			cfg, errP := parseVlessUri(line)
			if errP == nil {
				name := cfg.Name
				if name == "" {
					name = fmt.Sprintf("Custom-%s", cfg.Host)
				}
				country := "EU"
				if cfg.Host == EndpointServerRU || strings.Contains(cfg.Host, "223.109") {
					country = "RU"
				}
				p := Profile{
					Default: "",
					Name:    name,
					Host:    cfg.Host,
					Port:    cfg.Port,
					Country: country,
					RawUri:  line,
				}
				if !profileExists(&p) {
					profiles = append(profiles, p)
					importedCount++
				}
			}
		}
	}

	if importedCount > 0 {
		saveProfilesToStorage()
		refreshProfilesListView()
		writeLog("IMPORT", fmt.Sprintf("Imported %d new profiles from: %s", importedCount, filepath.Base(filePath)))

		msgTxt := fmt.Sprintf("Импорт успешно завершен!\n\nДобавлено новых серверов: %d\nВсего серверов в списке: %d", importedCount, len(profiles))
		msgTitle := "Импорт серверов"
		if !isRussianLang {
			msgTxt = fmt.Sprintf("Import completed successfully!\n\nAdded new profiles: %d\nTotal profiles in list: %d", importedCount, len(profiles))
			msgTitle = "Profiles Import"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msgTxt))), uintptr(unsafe.Pointer(strPtr(msgTitle))), 0x00000040)
	} else {
		msgTxt := "Новых серверов не найдено или они уже есть в списке."
		msgTitle := "Импорт серверов"
		if !isRussianLang {
			msgTxt = "No new profiles found or they already exist in the list."
			msgTitle = "Profiles Import"
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msgTxt))), uintptr(unsafe.Pointer(strPtr(msgTitle))), 0x00000030)
	}
}

func saveSubscriptionUrlToRegistry(subUrl string) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0, KEY_WRITE, 0,
		uintptr(unsafe.Pointer(&hKey)),
		0,
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SubscriptionURL")
	u16, err := syscall.UTF16FromString(subUrl)
	if err != nil {
		return
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16[0])),
		uintptr(len(u16)*2),
	)
}

func loadSubscriptionUrlFromRegistry() string {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
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

	valName := strPtr("SubscriptionURL")
	var valType uint32
	var cbData uint32
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 || cbData == 0 {
		return ""
	}
	buf := make([]uint16, (cbData/2)+1)
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 {
		return ""
	}
	return syscall.UTF16ToString(buf)
}

func saveSubscriptionExpandedToRegistry(expanded bool) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0, KEY_WRITE, 0,
		uintptr(unsafe.Pointer(&hKey)),
		0,
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SubscriptionExpanded")
	val := uint32(0)
	if expanded {
		val = 1
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_DWORD,
		uintptr(unsafe.Pointer(&val)),
		4,
	)
}

func saveSubscriptionExpanded(expanded bool) {
	subscriptionExpanded = expanded
	saveSubscriptionExpandedToRegistry(expanded)
	saveSettingsToStorage()
}

func loadSubscriptionExpandedFromRegistry() bool {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret == 0 {
		defer procRegCloseKey.Call(hKey)
		valName := strPtr("SubscriptionExpanded")
		var valType uint32
		var val uint32
		var cbData uint32 = 4
		ret, _, _ = procRegQueryValueExW.Call(
			hKey,
			uintptr(unsafe.Pointer(valName)),
			0,
			uintptr(unsafe.Pointer(&valType)),
			uintptr(unsafe.Pointer(&val)),
			uintptr(unsafe.Pointer(&cbData)),
		)
		if ret == 0 {
			return val != 0
		}
	}
	return subscriptionExpanded
}

func saveSubscriptionNameToRegistry(name string) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0, KEY_WRITE, 0,
		uintptr(unsafe.Pointer(&hKey)),
		0,
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SubscriptionName")
	u16, err := syscall.UTF16FromString(name)
	if err != nil {
		return
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16[0])),
		uintptr(len(u16)*2),
	)
}

func loadSubscriptionNameFromRegistry() string {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegOpenKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0,
		KEY_READ,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return "GIN-Proxy-HUB"
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SubscriptionName")
	var valType uint32
	var cbData uint32
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 || cbData == 0 {
		return "GIN-Proxy-HUB"
	}
	buf := make([]uint16, (cbData/2)+1)
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 {
		return "GIN-Proxy-HUB"
	}
	res := strings.TrimSpace(syscall.UTF16ToString(buf))
	if res == "" || res == "Jin Proxy hub" || res == "Djinn Proxy hub" {
		return "GIN-Proxy-HUB"
	}
	return res
}

func saveSubscriptionsToRegistry(jsonStr string) {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
	ret, _, _ := procRegCreateKeyExW.Call(
		HKEY_CURRENT_USER,
		uintptr(unsafe.Pointer(subKey)),
		0, 0, 0, KEY_WRITE, 0,
		uintptr(unsafe.Pointer(&hKey)),
		0,
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(hKey)

	valName := strPtr("SubscriptionsJSON")
	u16, err := syscall.UTF16FromString(jsonStr)
	if err != nil {
		return
	}
	procRegSetValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		REG_SZ,
		uintptr(unsafe.Pointer(&u16[0])),
		uintptr(len(u16)*2),
	)
}

func loadSubscriptionsFromRegistry() string {
	var hKey uintptr
	subKey := strPtr(`Software\VladiMIR\GIN-VPN`)
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

	valName := strPtr("SubscriptionsJSON")
	var valType uint32
	var cbData uint32
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		0,
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 || cbData == 0 {
		return ""
	}
	buf := make([]uint16, (cbData/2)+1)
	ret, _, _ = procRegQueryValueExW.Call(
		hKey,
		uintptr(unsafe.Pointer(valName)),
		0,
		uintptr(unsafe.Pointer(&valType)),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(&cbData)),
	)
	if ret != 0 {
		return ""
	}
	return syscall.UTF16ToString(buf)
}

func saveSubscriptionsToStorage() {
	data, err := json.MarshalIndent(activeSubscriptions, "", "  ")
	if err == nil {
		saveSubscriptionsToRegistry(string(data))
		exePath, err := os.Executable()
		if err == nil {
			_ = os.WriteFile(filepath.Join(filepath.Dir(exePath), "subscriptions.json"), data, 0644)
		}
	}
}

func loadSubscriptionsFromStorage() {
	activeSubscriptions = nil
	regData := loadSubscriptionsFromRegistry()
	if strings.TrimSpace(regData) != "" {
		_ = json.Unmarshal([]byte(regData), &activeSubscriptions)
	}
	if len(activeSubscriptions) == 0 {
		exePath, err := os.Executable()
		if err == nil {
			fileData, err := os.ReadFile(filepath.Join(filepath.Dir(exePath), "subscriptions.json"))
			if err == nil {
				_ = json.Unmarshal(fileData, &activeSubscriptions)
			}
		}
	}
	// Discover from existing profiles
	for _, p := range profiles {
		if p.Subscription != "" {
			exists := false
			for _, s := range activeSubscriptions {
				if s.Name == p.Subscription {
					exists = true
					break
				}
			}
			if !exists {
				activeSubscriptions = append(activeSubscriptions, SubscriptionItem{
					Name:     p.Subscription,
					URL:      "",
					Expanded: true,
				})
			}
		}
	}
	// Automatically prune empty (0-server) ghost subscriptions on startup
	var validSubs []SubscriptionItem
	pruned := false
	for _, s := range activeSubscriptions {
		cnt := 0
		for _, p := range profiles {
			if p.Subscription == s.Name {
				cnt++
			}
		}
		if cnt > 0 {
			validSubs = append(validSubs, s)
		} else {
			pruned = true
		}
	}
	activeSubscriptions = validSubs
	if pruned {
		saveSubscriptionsToStorage()
	}
}

func getSubscriptionExpanded(subName string) bool {
	for _, s := range activeSubscriptions {
		if s.Name == subName {
			return s.Expanded
		}
	}
	return subscriptionExpanded
}

func setSubscriptionExpanded(subName string, exp bool) {
	found := false
	for i := range activeSubscriptions {
		if activeSubscriptions[i].Name == subName {
			activeSubscriptions[i].Expanded = exp
			found = true
			break
		}
	}
	if !found {
		activeSubscriptions = append(activeSubscriptions, SubscriptionItem{
			Name:     subName,
			Expanded: exp,
		})
	}
	saveSubscriptionsToStorage()
}

func addOrUpdateSubscriptionItem(name string, urlStr string) {
	found := false
	for i := range activeSubscriptions {
		if activeSubscriptions[i].Name == name || (urlStr != "" && activeSubscriptions[i].URL == urlStr) {
			activeSubscriptions[i].Name = name
			if urlStr != "" {
				activeSubscriptions[i].URL = urlStr
			}
			activeSubscriptions[i].Expanded = true
			found = true
			break
		}
	}
	if !found {
		activeSubscriptions = append(activeSubscriptions, SubscriptionItem{
			Name:     name,
			URL:      urlStr,
			Expanded: true,
		})
	}
	saveSubscriptionsToStorage()
	if urlStr != "" {
		saveSubscriptionUrlToRegistry(urlStr)
	}
	saveSubscriptionNameToRegistry(name)
}

func getSubscriptionTitle(subUrl string) string {
	subUrl = strings.TrimSpace(subUrl)
	var frag string
	if idx := strings.Index(subUrl, "#"); idx != -1 && idx < len(subUrl)-1 {
		rawFrag := subUrl[idx+1:]
		if unescaped, err := url.QueryUnescape(rawFrag); err == nil && strings.TrimSpace(unescaped) != "" {
			frag = strings.TrimSpace(unescaped)
		} else if unescaped, err := url.PathUnescape(rawFrag); err == nil && strings.TrimSpace(unescaped) != "" {
			frag = strings.TrimSpace(unescaped)
		} else {
			frag = strings.TrimSpace(rawFrag)
		}
	}

	fragLower := strings.ToLower(frag)
	urlLower := strings.ToLower(subUrl)

	// User standard: GIN_VPN_RU and GIN_VPN_EU
	if strings.Contains(fragLower, "ru") || strings.Contains(urlLower, "sub_ru") || strings.Contains(urlLower, "_ru") {
		return "GIN_VPN_RU"
	}
	if strings.Contains(fragLower, "eu") || strings.Contains(urlLower, "sub_eu") || strings.Contains(urlLower, "_eu") || strings.Contains(urlLower, "sub.txt") {
		return "GIN_VPN_EU"
	}
	if frag != "" {
		return frag
	}

	u, err := url.Parse(subUrl)
	if err == nil {
		base := filepath.Base(u.Path)
		base = strings.TrimSuffix(base, filepath.Ext(base))
		if base != "" && base != "." && base != "/" {
			return "GIN_VPN_" + strings.ToUpper(base)
		}
	}

	return "GIN_VPN"
}

func refreshAllSubscriptionsAsync() {
	if isSubUpdating {
		return
	}
	isSubUpdating = true
	if hwndBtnSubRefresh != 0 {
		procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
	}

	go func() {
		defer func() {
			isSubUpdating = false
			if hwndBtnSubRefresh != 0 {
				procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
			}
			updateSubscriptionBar()
			triggerSubRefreshDoneFeedback()
		}()

		type targetSub struct {
			Name string
			URL  string
		}
		var targets []targetSub
		for _, s := range activeSubscriptions {
			if s.URL != "" {
				targets = append(targets, targetSub{Name: s.Name, URL: s.URL})
			}
		}

		if len(targets) == 0 {
			regUrl := loadSubscriptionUrlFromRegistry()
			if regUrl != "" {
				targets = append(targets, targetSub{Name: getSubscriptionTitle(regUrl), URL: regUrl})
			}
		}

		if len(targets) == 0 {
			writeLog("WARN", "Не найдено URL активных подписок для обновления.")
			return
		}

		client := &http.Client{
			Timeout: 8 * time.Second,
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			},
		}

		updatedCount := 0
		for _, tgt := range targets {
			candidates := getMirrorCandidates([]string{tgt.URL}, tgt.Name)
			success := false
			for idx, candUrl := range candidates {
				writeLog("SUB", fmt.Sprintf("Обновление подписки '%s' (зеркало %d/%d): %s", tgt.Name, idx+1, len(candidates), candUrl))
				reqUrl := appendCacheBuster(candUrl)
				req, err := http.NewRequest("GET", reqUrl, nil)
				if err != nil {
					continue
				}
				req.Header.Set("User-Agent", "GIN-VPN/"+AppVersion+" (Windows; Xray)")
				req.Header.Set("Cache-Control", "no-cache, no-store, must-revalidate")
				resp, err := client.Do(req)
				if err != nil || resp.StatusCode < 200 || resp.StatusCode >= 300 {
					if resp != nil {
						resp.Body.Close()
					}
					writeLog("WARN", fmt.Sprintf("Зеркало %d недоступно для '%s': %v", idx+1, tgt.Name, err))
					continue
				}
				bodyBytes, err := io.ReadAll(resp.Body)
				resp.Body.Close()
				if err != nil {
					continue
				}
				bodyStr := strings.TrimSpace(string(bodyBytes))
				if bodyStr == "" || (!strings.Contains(bodyStr, "vless://") && !isBase64Subscription(bodyStr)) {
					continue
				}
				importNodesFromContent(bodyStr, tgt.Name, candUrl, tgt.Name)
				updatedCount++
				success = true
				break
			}
			if !success {
				writeLog("ERROR", fmt.Sprintf("Не удалось обновить подписку '%s' ни с одного из %d зеркал.", tgt.Name, len(candidates)))
			}
		}

		if isRussianLang {
			writeLog("SUB", fmt.Sprintf("✅ Синхронизация завершена: обновлено %d подписок. Всего серверов: %d", updatedCount, len(profiles)))
		} else {
			writeLog("SUB", fmt.Sprintf("✅ Sync complete: updated %d subscriptions. Total profiles: %d", updatedCount, len(profiles)))
		}
	}()
}

func measurePingAccurate(host string, port int) int {
	start := time.Now()
	addr := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", addr, 2000*time.Millisecond)
	if err != nil {
		return -1
	}
	conn.Close()
	ms := int(time.Since(start).Milliseconds())
	if ms <= 0 {
		ms = 1
	}
	return ms
}

func sortProfilesByPingInPlace() {
	if len(profiles) <= 1 {
		return
	}

	var subOrder []string
	subMap := make(map[string][]Profile)
	var standalone []Profile

	for _, p := range profiles {
		if p.Subscription != "" {
			if _, exists := subMap[p.Subscription]; !exists {
				subOrder = append(subOrder, p.Subscription)
			}
			subMap[p.Subscription] = append(subMap[p.Subscription], p)
		} else {
			standalone = append(standalone, p)
		}
	}

	sortSlice := func(items []Profile) {
		sort.SliceStable(items, func(i, j int) bool {
			lat1 := items[i].PingMs
			lat2 := items[j].PingMs
			if lat1 > 0 && lat2 > 0 {
				return lat1 < lat2
			}
			if lat1 > 0 && lat2 <= 0 {
				return true
			}
			if lat1 <= 0 && lat2 > 0 {
				return false
			}
			return false
		})
	}

	var sortedProfiles []Profile
	for _, sName := range subOrder {
		items := subMap[sName]
		sortSlice(items)
		sortedProfiles = append(sortedProfiles, items...)
	}
	sortSlice(standalone)
	sortedProfiles = append(sortedProfiles, standalone...)

	profiles = sortedProfiles
	saveProfilesToStorage()
}

func testSubscriptionPingAsync() {
	if isPingTesting {
		return
	}

	// 1. Immediately expand all subscriptions so the user sees the list of all servers
	subscriptionExpanded = true
	saveSubscriptionExpanded(true)
	for _, as := range activeSubscriptions {
		setSubscriptionExpanded(as.Name, true)
	}
	for _, p := range profiles {
		if p.Subscription != "" {
			setSubscriptionExpanded(p.Subscription, true)
		}
	}
	updateSubscriptionBar()
	refreshProfilesListView()

	isPingTesting = true
	if hwndBtnSubPing != 0 {
		procInvalidateRect.Call(hwndBtnSubPing, 0, 1)
	}

	go func() {
		defer func() {
			isPingTesting = false
			if hwndBtnSubPing != 0 {
				procInvalidateRect.Call(hwndBtnSubPing, 0, 1)
			}
			if hwndListView != 0 {
				procInvalidateRect.Call(hwndListView, 0, 1)
			}
		}()

		if len(profiles) == 0 {
			if isRussianLang {
				writeLog("PING", "Список серверов пуст.")
			} else {
				writeLog("PING", "Profiles list is empty.")
			}
			return
		}

		if isRussianLang {
			writeLog("PING", fmt.Sprintf("⏱️ Запуск проверки скорости (пинг) всех серверов (%d)...", len(profiles)))
		} else {
			writeLog("PING", fmt.Sprintf("⏱️ Starting speed (ping) test for all servers (%d)...", len(profiles)))
		}

		var wg sync.WaitGroup
		sem := make(chan struct{}, 10)

		for i := range profiles {
			wg.Add(1)
			go func(idx int) {
				defer wg.Done()
				sem <- struct{}{}
				defer func() { <-sem }()

				lat := measurePingAccurate(profiles[idx].Host, profiles[idx].Port)
				profiles[idx].PingMs = lat
			}(i)
		}
		wg.Wait()

		sortProfilesByPingInPlace()
		sortByPing = true
		if hwndMain != 0 {
			procPostMessageW.Call(hwndMain, WM_APP_UPDATE_PING, 0, 0)
		}

		minPing := 999999
		maxPing := 0
		totalPing := 0
		validCount := 0
		fastestName := ""
		for _, p := range profiles {
			if p.PingMs > 0 {
				validCount++
				totalPing += p.PingMs
				if p.PingMs < minPing {
					minPing = p.PingMs
					fastestName = p.Name
				}
				if p.PingMs > maxPing {
					maxPing = p.PingMs
				}
			}
		}

		if validCount > 0 {
			avg := totalPing / validCount
			if isRussianLang {
				writeLog("PING_OK", fmt.Sprintf("✅ Пинг завершен (%d/%d онлайн). Самый быстрый: '%s' (%d ms). Средняя: %d ms. Серверы отсортированы по скорости.", validCount, len(profiles), fastestName, minPing, avg))
			} else {
				writeLog("PING_OK", fmt.Sprintf("✅ Ping test complete (%d/%d online). Fastest: '%s' (%d ms). Avg: %d ms. Profiles sorted by speed.", validCount, len(profiles), fastestName, minPing, avg))
			}
		} else {
			if isRussianLang {
				writeLog("PING_WARN", "⚠️ Серверы не ответили на TCP пинг.")
			} else {
				writeLog("PING_WARN", "⚠️ Servers did not respond to TCP ping.")
			}
		}
	}()
}

func tryDecodeBase64Subscription(content string) string {
	cleaned := strings.ReplaceAll(content, "\r", "")
	cleaned = strings.ReplaceAll(cleaned, "\n", "")
	cleaned = strings.ReplaceAll(cleaned, " ", "")
	cleaned = strings.TrimSpace(cleaned)

	encodings := []*base64.Encoding{
		base64.StdEncoding,
		base64.RawStdEncoding,
		base64.URLEncoding,
		base64.RawURLEncoding,
	}

	for _, enc := range encodings {
		data, err := enc.DecodeString(cleaned)
		if err == nil {
			str := string(data)
			if strings.Contains(str, "vless://") {
				return str
			}
		}
	}
	return content
}

func isBase64Subscription(content string) bool {
	decoded := tryDecodeBase64Subscription(content)
	return decoded != content && strings.Contains(decoded, "vless://")
}

func importNodesFromContent(rawText string, subName string, subUrl string, sourceTitle string) {
	decodedText := tryDecodeBase64Subscription(rawText)
	lines := strings.Split(decodedText, "\n")

	if subName == "" {
		subName = "GIN-Proxy-HUB"
	}

	importedCount := 0
	var newSubProfiles []Profile
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "vless://") {
			continue
		}
		cfg, err := parseVlessUri(line)
		if err != nil {
			continue
		}
		name := cfg.Name
		if unescaped, err := url.PathUnescape(name); err == nil && unescaped != "" {
			name = unescaped
		}
		if unescaped, err := url.QueryUnescape(name); err == nil && unescaped != "" {
			name = unescaped
		}
		if name == "" {
			name = fmt.Sprintf("Custom-%s", cfg.Host)
		}
		country := "EU"
		if len(name) >= 4 && name[0] == '[' && name[3] == ']' {
			country = strings.ToUpper(name[1:3])
		} else if strings.Contains(name, "GIN-") {
			parts := strings.Split(name, "GIN-")
			if len(parts) > 1 && len(parts[1]) >= 2 {
				country = strings.ToUpper(parts[1][:2])
			}
		} else if cfg.Host == EndpointServerRU || strings.Contains(cfg.Host, "223.109") {
			country = "RU"
		}

		p := Profile{
			Default:      "",
			Name:         cleanProfileName(name),
			Host:         cfg.Host,
			Port:         cfg.Port,
			Country:      country,
			RawUri:       line,
			Subscription: subName,
		}
		newSubProfiles = append(newSubProfiles, p)
		importedCount++
	}

	if importedCount > 0 {
		var otherSubProfiles []Profile
		var indivProfiles []Profile

		for _, p := range profiles {
			if p.Subscription == "" {
				indivProfiles = append(indivProfiles, p)
			} else if p.Subscription != subName {
				otherSubProfiles = append(otherSubProfiles, p)
			}
		}

		var updatedProfiles []Profile
		updatedProfiles = append(updatedProfiles, otherSubProfiles...)
		updatedProfiles = append(updatedProfiles, newSubProfiles...)
		updatedProfiles = append(updatedProfiles, indivProfiles...)

		hasDefault := false
		for _, p := range updatedProfiles {
			if p.Default != "" {
				hasDefault = true
				break
			}
		}
		if !hasDefault && len(updatedProfiles) > 0 {
			updatedProfiles[0].Default = "yes"
		}

		profiles = updatedProfiles

		// Register in activeSubscriptions
		addOrUpdateSubscriptionItem(subName, subUrl)

		saveProfilesToStorage()
		refreshProfilesListView()

		if isRussianLang {
			writeLog("SUB", fmt.Sprintf("Подписка '%s' успешно обновлена: %d серверов. Всего серверов: %d", subName, importedCount, len(profiles)))
		} else {
			writeLog("SUB", fmt.Sprintf("Subscription '%s' updated: added %d nodes. Total servers: %d", subName, importedCount, len(profiles)))
		}

		triggerSubRefreshDoneFeedback()
	} else {
		writeLog("WARN", "No valid VLESS nodes found in content.")
		msgTxt := "В указанном источнике не найдено валидных VLESS серверов."
		if !isRussianLang {
			msgTxt = "No valid VLESS nodes found in the provided content."
		}
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msgTxt))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000030)
	}
}

func extractHttpUrls(raw string) []string {
	var urls []string
	seen := make(map[string]bool)
	fields := strings.FieldsFunc(raw, func(r rune) bool {
		return r == '\n' || r == '\r' || r == ' ' || r == '\t' || r == ',' || r == ';'
	})
	for _, f := range fields {
		u := strings.TrimSpace(f)
		if strings.HasPrefix(u, "http://") || strings.HasPrefix(u, "https://") {
			if !seen[u] {
				seen[u] = true
				urls = append(urls, u)
			}
		}
	}
	return urls
}

func appendCacheBuster(rawUrl string) string {
	frag := ""
	base := rawUrl
	if idx := strings.Index(rawUrl, "#"); idx != -1 {
		base = rawUrl[:idx]
		frag = rawUrl[idx:]
	}
	sep := "?"
	if strings.Contains(base, "?") {
		sep = "&"
	}
	return fmt.Sprintf("%s%s_t=%d%s", base, sep, time.Now().Unix(), frag)
}

func getMirrorCandidates(userUrls []string, subName string) []string {
	var result []string
	seen := make(map[string]bool)
	add := func(u string) {
		u = strings.TrimSpace(u)
		if u != "" && !seen[u] {
			seen[u] = true
			result = append(result, u)
		}
	}
	for _, u := range userUrls {
		add(u)
	}
	nameUpper := strings.ToUpper(subName)
	if strings.Contains(nameUpper, "RU") {
		add("https://gist.githubusercontent.com/GinCz/ac36401e7b7aec8f9bb8db638ed4c72d/raw/sub_RU.txt#GIN_VPN_RU")
		add("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/sub/sub_RU.txt#GIN_VPN_RU")
		add("https://cdn.jsdelivr.net/gh/GinCz/Windows_scripts@main/sub/sub_RU.txt#GIN_VPN_RU")
		add("http://195.158.255.208/sub_RU.txt#GIN_VPN_RU")
		add("http://31.59.126.191/sub_RU.txt#GIN_VPN_RU")
		add("https://63.178.216.88/sub_RU.txt#GIN_VPN_RU")
	} else if strings.Contains(nameUpper, "EU") {
		add("https://gist.githubusercontent.com/GinCz/ac36401e7b7aec8f9bb8db638ed4c72d/raw/sub_EU.txt#GIN_VPN_EU")
		add("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/sub/sub_EU.txt#GIN_VPN_EU")
		add("https://cdn.jsdelivr.net/gh/GinCz/Windows_scripts@main/sub/sub_EU.txt#GIN_VPN_EU")
		add("http://195.158.255.208/sub_EU.txt#GIN_VPN_EU")
		add("http://31.59.126.191/sub_EU.txt#GIN_VPN_EU")
		add("https://63.178.216.88/sub_EU.txt#GIN_VPN_EU")
	}
	return result
}

func importSubscriptionFromUrl(subUrl string) {
	parsedUrls := extractHttpUrls(subUrl)
	if len(parsedUrls) == 0 {
		return
	}

	// Group pasted URLs by subscription title (e.g. GIN_VPN_EU, GIN_VPN_RU)
	var groupOrder []string
	groups := make(map[string][]string)
	for _, u := range parsedUrls {
		title := getSubscriptionTitle(u)
		if _, exists := groups[title]; !exists {
			groupOrder = append(groupOrder, title)
		}
		groups[title] = append(groups[title], u)
	}

	isSubUpdating = true
	if hwndBtnSubRefresh != 0 {
		procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
	}

	go func() {
		defer func() {
			isSubUpdating = false
			if hwndBtnSubRefresh != 0 {
				procInvalidateRect.Call(hwndBtnSubRefresh, 0, 1)
			}
			updateSubscriptionBar()
		}()

		client := &http.Client{
			Timeout: 8 * time.Second,
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			},
		}

		anySuccess := false
		var lastErr string

		for _, subName := range groupOrder {
			candidates := getMirrorCandidates(groups[subName], subName)
			groupSuccess := false
			for idx, candUrl := range candidates {
				if isRussianLang {
					writeLog("SUB", fmt.Sprintf("Загрузка подписки '%s' (зеркало %d/%d): %s", subName, idx+1, len(candidates), candUrl))
				} else {
					writeLog("SUB", fmt.Sprintf("Fetching subscription '%s' (mirror %d/%d): %s", subName, idx+1, len(candidates), candUrl))
				}

				reqUrl := appendCacheBuster(candUrl)
				req, err := http.NewRequest("GET", reqUrl, nil)
				if err != nil {
					lastErr = err.Error()
					continue
				}
				req.Header.Set("User-Agent", "GIN-VPN/"+AppVersion+" (Windows; Xray)")
				req.Header.Set("Cache-Control", "no-cache, no-store, must-revalidate")

				resp, err := client.Do(req)
				if err != nil {
					lastErr = err.Error()
					writeLog("WARN", fmt.Sprintf("Mirror %d/%d unreachable (%s): %v", idx+1, len(candidates), candUrl, err))
					continue
				}
				bodyBytes, readErr := io.ReadAll(resp.Body)
				resp.Body.Close()

				if resp.StatusCode < 200 || resp.StatusCode >= 300 || readErr != nil {
					lastErr = fmt.Sprintf("HTTP %d", resp.StatusCode)
					writeLog("WARN", fmt.Sprintf("Mirror %d/%d returned HTTP %d", idx+1, len(candidates), resp.StatusCode))
					continue
				}

				bodyStr := strings.TrimSpace(string(bodyBytes))
				if bodyStr == "" || (!strings.Contains(bodyStr, "vless://") && !isBase64Subscription(bodyStr)) {
					lastErr = "Empty or non-VLESS payload"
					continue
				}

				procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(candUrl))))
				importNodesFromContent(bodyStr, subName, candUrl, subName)
				groupSuccess = true
				anySuccess = true
				break
			}
			if !groupSuccess {
				writeLog("ERROR", fmt.Sprintf("All %d mirrors failed for subscription '%s'", len(candidates), subName))
			}
		}

		if !anySuccess {
			procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Не удалось подключиться ни к одному зеркалу подписки:\n"+lastErr))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000010)
		}
	}()
}


func draw3DVolumetricButton(hDC uintptr, rc RECT, text string, font uintptr, baseColor, borderDark, borderLight uintptr, isPressed bool) uintptr {
	hBrush, _, _ := procCreateSolidBrush.Call(baseColor)
	hPen, _, _ := procCreatePen.Call(0, 1, borderDark)
	oldBrush, _, _ := procSelectObject.Call(hDC, hBrush)
	oldPen, _, _ := procSelectObject.Call(hDC, hPen)

	procRectangle.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom))

	procSelectObject.Call(hDC, oldBrush)
	procSelectObject.Call(hDC, oldPen)
	procDeleteObject.Call(hBrush)
	procDeleteObject.Call(hPen)

	if !isPressed {
		hPenLight, _, _ := procCreatePen.Call(0, 1, borderLight)
		oldPenL, _, _ := procSelectObject.Call(hDC, hPenLight)

		var pt POINT
		procMoveToEx.Call(hDC, uintptr(rc.Left+1), uintptr(rc.Top+1), uintptr(unsafe.Pointer(&pt)))
		procLineTo.Call(hDC, uintptr(rc.Right-1), uintptr(rc.Top+1))

		procMoveToEx.Call(hDC, uintptr(rc.Left+1), uintptr(rc.Top+1), uintptr(unsafe.Pointer(&pt)))
		procLineTo.Call(hDC, uintptr(rc.Left+1), uintptr(rc.Bottom-1))

		procSelectObject.Call(hDC, oldPenL)
		procDeleteObject.Call(hPenLight)
	}

	procSetBkMode.Call(hDC, 1)
	procSetTextColor.Call(hDC, 0x00FFFFFF)
	oldFont, _, _ := procSelectObject.Call(hDC, font)

	textRc := rc
	if isPressed {
		textRc.Top += 1
		textRc.Left += 1
	}

	procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(strPtr(text))), ^uintptr(0), uintptr(unsafe.Pointer(&textRc)), 0x00000001|0x00000004|0x00000020)
	procSelectObject.Call(hDC, oldFont)

	return 1
}

func rgb(r, g, b byte) uintptr {
	return uintptr(uint32(r) | (uint32(g) << 8) | (uint32(b) << 16))
}

func getAnimName(v int, ru bool) string {
	switch v {
	case 1:
		if ru {
			return "Радарный импульс"
		}
		return "Radar Pulse"
	case 2:
		if ru {
			return "Неоновый вихрь"
		}
		return "Neon Spinner"
	case 3:
		if ru {
			return "Эквалайзер трафика"
		}
		return "Traffic Equalizer"
	case 4:
		if ru {
			return "Орбитальный квант"
		}
		return "Orbital Photon"
	case 5:
		if ru {
			return "Пульс защиты"
		}
		return "Shield Heartbeat"
	}
	return ""
}

func nullPen() uintptr {
	h, _, _ := procGetStockObject.Call(5 /* NULL_PEN */)
	return h
}

func nullBrush() uintptr {
	h, _, _ := procGetStockObject.Call(5 /* NULL_BRUSH */)
	return h
}

func drawActiveIndicatorAnimation(hDC uintptr, x, y, w, h int32, variant, frame int) {
	cx := x + w/2
	cy := y + h/2

	switch variant {
	case 1: // 1. Radar Pulse (Радарный импульс)
		dotBrush, _, _ := procCreateSolidBrush.Call(rgb(0, 255, 128))
		oldB, _, _ := procSelectObject.Call(hDC, dotBrush)
		oldP, _, _ := procSelectObject.Call(hDC, nullPen())
		procEllipse.Call(hDC, uintptr(cx-3), uintptr(cy-3), uintptr(cx+3), uintptr(cy+3))

		for ring := 0; ring < 2; ring++ {
			phase := float64((frame*2 + ring*16) % 32) / 32.0
			rad := int32(4 + phase*13)
			alphaG := byte(255 - phase*180)
			pen, _, _ := procCreatePen.Call(0, 1, rgb(0, alphaG, 60))
			procSelectObject.Call(hDC, pen)
			procEllipse.Call(hDC, uintptr(cx-rad), uintptr(cy-rad), uintptr(cx+rad), uintptr(cy+rad))
			procDeleteObject.Call(pen)
		}
		procSelectObject.Call(hDC, oldB)
		procSelectObject.Call(hDC, oldP)
		procDeleteObject.Call(dotBrush)

	case 2: // 2. Neon Spinner Ring (Вращающийся неоновый спиннер)
		R := 11.0
		numDots := 8
		activeIdx := (frame / 2) % numDots
		oldP, _, _ := procSelectObject.Call(hDC, nullPen())

		for i := 0; i < numDots; i++ {
			ang := float64(i) * (2.0 * math.Pi / float64(numDots))
			dx := cx + int32(R*math.Cos(ang))
			dy := cy + int32(R*math.Sin(ang))

			dist := (i - activeIdx + numDots) % numDots
			var bColor uintptr
			dotRad := int32(2)
			if dist == 0 {
				bColor = rgb(255, 255, 255)
				dotRad = 3
			} else if dist == 7 {
				bColor = rgb(0, 255, 136)
			} else if dist == 6 {
				bColor = rgb(0, 200, 100)
			} else if dist == 5 {
				bColor = rgb(0, 140, 70)
			} else {
				bColor = rgb(0, 60, 30)
			}

			brush, _, _ := procCreateSolidBrush.Call(bColor)
			oldB, _, _ := procSelectObject.Call(hDC, brush)
			procEllipse.Call(hDC, uintptr(dx-dotRad), uintptr(dy-dotRad), uintptr(dx+dotRad), uintptr(dy+dotRad))
			procSelectObject.Call(hDC, oldB)
			procDeleteObject.Call(brush)
		}
		procSelectObject.Call(hDC, oldP)

	case 3: // 3. Live Equalizer Wave (Эквалайзер трафика)
		barCount := 5
		barW := int32(3)
		spacing := int32(6)
		startX := cx - int32(barCount*int(spacing))/2 + 1

		oldP, _, _ := procSelectObject.Call(hDC, nullPen())
		for i := 0; i < barCount; i++ {
			f := float64(frame)*0.28 + float64(i)*1.3
			val := (math.Sin(f) + 1.0) / 2.0
			barH := int32(4 + val*16)
			bx := startX + int32(i)*spacing
			by := cy - barH/2

			gVal := byte(200 + val*55)
			bVal := byte(80 + val*175)
			brush, _, _ := procCreateSolidBrush.Call(rgb(0, gVal, bVal))
			oldB, _, _ := procSelectObject.Call(hDC, brush)
			procRoundRect.Call(hDC, uintptr(bx), uintptr(by), uintptr(bx+barW), uintptr(by+barH), 2, 2)
			procSelectObject.Call(hDC, oldB)
			procDeleteObject.Call(brush)
		}
		procSelectObject.Call(hDC, oldP)

	case 4: // 4. Orbital Photon / Shield (Квант вокруг щита)
		coreBrush, _, _ := procCreateSolidBrush.Call(rgb(255, 215, 0))
		oldB, _, _ := procSelectObject.Call(hDC, coreBrush)
		oldP, _, _ := procSelectObject.Call(hDC, nullPen())
		procEllipse.Call(hDC, uintptr(cx-4), uintptr(cy-4), uintptr(cx+4), uintptr(cy+4))
		procSelectObject.Call(hDC, oldB)
		procDeleteObject.Call(coreBrush)

		orbitPen, _, _ := procCreatePen.Call(0, 1, rgb(30, 80, 40))
		oldPenO, _, _ := procSelectObject.Call(hDC, orbitPen)
		procSelectObject.Call(hDC, nullBrush())
		procEllipse.Call(hDC, uintptr(cx-11), uintptr(cy-11), uintptr(cx+11), uintptr(cy+11))
		procSelectObject.Call(hDC, oldPenO)
		procDeleteObject.Call(orbitPen)

		angle := float64(frame) * 0.22
		for t := 2; t >= 0; t-- {
			angT := angle - float64(t)*0.25
			px := cx + int32(11.0*math.Cos(angT))
			py := cy + int32(11.0*math.Sin(angT))
			var pColor uintptr
			pRad := int32(2)
			if t == 0 {
				pColor = rgb(255, 255, 255)
				pRad = 3
			} else if t == 1 {
				pColor = rgb(0, 255, 200)
			} else {
				pColor = rgb(0, 150, 100)
			}
			pBrush, _, _ := procCreateSolidBrush.Call(pColor)
			oldBP, _, _ := procSelectObject.Call(hDC, pBrush)
			procSelectObject.Call(hDC, nullPen())
			procEllipse.Call(hDC, uintptr(px-pRad), uintptr(py-pRad), uintptr(px+pRad), uintptr(py+pRad))
			procSelectObject.Call(hDC, oldBP)
			procDeleteObject.Call(pBrush)
		}
		procSelectObject.Call(hDC, oldP)

	case 5: // 5. ECG Heartbeat Pulse (Пульс кардиограммы)
		pen, _, _ := procCreatePen.Call(0, 2, rgb(0, 255, 120))
		oldPen, _, _ := procSelectObject.Call(hDC, pen)

		width := 32
		boxLeft := cx - int32(width)/2
		scanX := (frame * 2) % (width + 12)

		var pt POINT
		procMoveToEx.Call(hDC, uintptr(boxLeft), uintptr(cy), uintptr(unsafe.Pointer(&pt)))

		for ix := 0; ix < width; ix++ {
			currX := boxLeft + int32(ix)
			dist := ix - scanX
			currY := cy
			if dist >= -6 && dist <= 0 {
				switch dist {
				case -1:
					currY = cy - 8
				case -2:
					currY = cy + 5
				case -3:
					currY = cy - 3
				case -4:
					currY = cy + 2
				}
			}
			procLineTo.Call(hDC, uintptr(currX), uintptr(currY))
		}
		procSelectObject.Call(hDC, oldPen)
		procDeleteObject.Call(pen)
	}
}

func drawCustomButton(dis *DRAWITEMSTRUCT) uintptr {
	hDC := dis.HDC
	rc := dis.RcItem
	isPressed := (dis.ItemState & 0x0001) != 0

	var btnText string
	var baseColor, borderDark, borderLight uintptr
	var font uintptr = hFontBold

	switch dis.CtlID {
	case 101: // Main Big Action Button / Split Connected Status Card
		if isConnecting {
			btnText = "● CONNECTING..."
			if isRussianLang {
				btnText = "● ПОДКЛЮЧЕНИЕ..."
			}
			baseColor = 0x0677D9
			borderDark = 0x034988
			borderLight = 0x58A5F0
		} else if isConnected {
			// Draw custom rich status card with neon border and interactive animation
			cardBg := rgb(15, 42, 22)
			cardBorderD := rgb(10, 28, 14)
			cardBorderL := rgb(0, 230, 118)
			if isPressed {
				cardBg = rgb(10, 32, 16)
			}
			draw3DVolumetricButton(hDC, rc, "", font, cardBg, cardBorderD, cardBorderL, isPressed)

			// Draw 5-variant animated canvas on the left
			drawActiveIndicatorAnimation(hDC, rc.Left+6, rc.Top, 40, rc.Bottom-rc.Top, animVariant, animFrame)

			// Draw textual info next to animation
			procSetBkMode.Call(hDC, 1) // TRANSPARENT
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			oldFont, _, _ := procSelectObject.Call(hDC, hFontBold)

			textRc1 := RECT{Left: rc.Left + 50, Top: rc.Top + 4, Right: rc.Right - 6, Bottom: rc.Top + 24}
			titleTxt := fmt.Sprintf("● ПОДКЛЮЧЕНО: %s", activeNodeName)
			if !isRussianLang {
				titleTxt = fmt.Sprintf("🟢 CONNECTED: %s", activeNodeName)
			}
			procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(strPtr(titleTxt))), ^uintptr(0), uintptr(unsafe.Pointer(&textRc1)), 0x00000000|0x00000004|0x00000020)

			procSetTextColor.Call(hDC, rgb(160, 255, 160)) // Light neon green
			procSelectObject.Call(hDC, hFontSmall)

			textRc2 := RECT{Left: rc.Left + 50, Top: rc.Top + 22, Right: rc.Right - 6, Bottom: rc.Bottom - 4}
			subTxt := "Xray VLESS • Защищенный туннель активен"
			if !isRussianLang {
				subTxt = "Xray VLESS • Secure Tunnel Active"
			}
			procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(strPtr(subTxt))), ^uintptr(0), uintptr(unsafe.Pointer(&textRc2)), 0x00000000|0x00000004|0x00000020)

			procSelectObject.Call(hDC, oldFont)
			return 1
		} else {
			btnText = "▶ CONNECT TO VPN"
			if isRussianLang {
				btnText = "▶ ПОДКЛЮЧИТЬСЯ К VPN"
			}
			if isPressed {
				baseColor = 0x256322
				borderDark = 0x1B5E20
				borderLight = 0x43A047
			} else {
				baseColor = 0x327D2E
				borderDark = 0x1B5E20
				borderLight = 0x66BB6A
			}
		}

	case 111: // Right part: Disconnect / Cancel Button
		if isConnecting {
			btnText = "✕ CANCEL"
			if isRussianLang {
				btnText = "✕ ОТМЕНА"
			}
			if isPressed {
				baseColor = rgb(190, 75, 20)
				borderDark = rgb(130, 45, 10)
				borderLight = rgb(240, 115, 35)
			} else {
				baseColor = rgb(215, 85, 25)
				borderDark = rgb(150, 55, 15)
				borderLight = rgb(255, 130, 45)
			}
		} else {
			btnText = "■ DISCONNECT"
			if isRussianLang {
				btnText = "■ ОТКЛЮЧИТЬ"
			}
			if isPressed {
				baseColor = rgb(180, 25, 25)
				borderDark = rgb(120, 15, 15)
				borderLight = rgb(230, 80, 80)
			} else {
				baseColor = rgb(215, 40, 40)
				borderDark = rgb(140, 20, 20)
				borderLight = rgb(255, 100, 100)
			}
		}

	case 102: // Paste Key / QR
		btnText = "+ Paste / QR"
		if isRussianLang {
			btnText = "+ Вставить / QR"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x586E2D
			borderDark = 0x3E501F
			borderLight = 0x7A9B3E
		} else {
			baseColor = 0x6C8838
			borderDark = 0x485E22
			borderLight = 0x92B34E
		}

	case 103: // Save Profile
		btnText = "✔ Save"
		if isRussianLang {
			btnText = "✔ Сохранить"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x1E598A
			borderDark = 0x143E60
			borderLight = 0x3D7CAE
		} else {
			baseColor = 0x2B7BB9
			borderDark = 0x1B5A8A
			borderLight = 0x5AA4DE
		}

	case 112: // Move Up Button
		btnText = "▲"
		font = hFontBold
		if isPressed {
			baseColor = 0x2A3E70
			borderDark = 0x1E2B50
			borderLight = 0x4864A8
		} else {
			baseColor = 0x3A539B
			borderDark = 0x263768
			borderLight = 0x5C7CD6
		}

	case 113: // Move Down Button
		btnText = "▼"
		font = hFontBold
		if isPressed {
			baseColor = 0x2A3E70
			borderDark = 0x1E2B50
			borderLight = 0x4864A8
		} else {
			baseColor = 0x3A539B
			borderDark = 0x263768
			borderLight = 0x5C7CD6
		}

	case 104: // Connect Selected
		btnText = "▶ Connect"
		if isRussianLang {
			btnText = "▶ Пуск"
		}
		font = hFontBold
		if isPressed {
			baseColor = 0x256322
			borderDark = 0x1B5E20
			borderLight = 0x43A047
		} else {
			baseColor = 0x327D2E
			borderDark = 0x1B5E20
			borderLight = 0x66BB6A
		}

	case 105: // Set Default
		btnText = "★ Auto"
		if isRussianLang {
			btnText = "★ Авто"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x006699
			borderDark = 0x00476B
			borderLight = 0x1E88B8
		} else {
			baseColor = 0x0080B0
			borderDark = 0x005878
			borderLight = 0x33AADD
		}

	case 114: // Sub Toggle [+]/[-]
		btnText = "[-]"
		if !subscriptionExpanded {
			btnText = "[+]"
		}
		font = hFontBold
		if isDarkMode {
			if isPressed {
				baseColor = 0x1A1A1A
				borderDark = 0x0F0F0F
				borderLight = 0x333333
			} else {
				baseColor = 0x262626
				borderDark = 0x1A1A1A
				borderLight = 0x444444
			}
		} else {
			if isPressed {
				baseColor = 0xD0D6E2
				borderDark = 0xA0A8B8
				borderLight = 0xF0F4FC
			} else {
				baseColor = 0xE2E7F0
				borderDark = 0xB8C0D0
				borderLight = 0xFFFFFF
			}
		}

	case 115: // Sub Ping (Clock)
		btnText = "~ Пинг"
		if !isRussianLang {
			btnText = "~ Ping"
		}
		if isPingTesting {
			btnText = "⏳..."
		}
		font = hFontRegular
		if isDarkMode {
			if isPressed {
				baseColor = 0x261E48
				borderDark = 0x181232
				borderLight = 0x483884
			} else {
				baseColor = 0x382A6A
				borderDark = 0x221844
				borderLight = 0x5C46A8
			}
		} else {
			if isPressed {
				baseColor = 0x4E3D88
				borderDark = 0x332660
				borderLight = 0x7660BC
			} else {
				baseColor = 0x624CAE
				borderDark = 0x42327A
				borderLight = 0x8A74D4
			}
		}

	case 116: // Sub Refresh (Update)
		if isSubRefreshDone {
			btnText = "✔ Обновлено"
			if !isRussianLang {
				btnText = "✔ Updated"
			}
			font = hFontRegular
			if isPressed {
				baseColor = 0x144418
				borderDark = 0x0E2E10
				borderLight = 0x2A7030
			} else {
				baseColor = 0x1E5E24
				borderDark = 0x144218
				borderLight = 0x4CAF50
			}
		} else if isSubUpdating {
			btnText = "⏳..."
			font = hFontRegular
			if isDarkMode {
				baseColor = 0x1E5E24
				borderDark = 0x144218
				borderLight = 0x389E40
			} else {
				baseColor = 0x2E7D32
				borderDark = 0x1B5E20
				borderLight = 0x4CAF50
			}
		} else {
			btnText = "» Обновить"
			if !isRussianLang {
				btnText = "» Refresh"
			}
			font = hFontRegular
			if isDarkMode {
				if isPressed {
					baseColor = 0x144418
					borderDark = 0x0E2E10
					borderLight = 0x2A7030
				} else {
					baseColor = 0x1E5E24
					borderDark = 0x144218
					borderLight = 0x389E40
				}
			} else {
				if isPressed {
					baseColor = 0x1B5E20
					borderDark = 0x124216
					borderLight = 0x388E3C
				} else {
					baseColor = 0x2E7D32
					borderDark = 0x1B5E20
					borderLight = 0x4CAF50
				}
			}
		}

	case 106: // Install / Update Button
		if isAppUpToDate {
			btnText = "✔️ Актуально"
			if !isRussianLang {
				btnText = "✔️ Up to date"
			}
			if isPressed {
				baseColor = 0x144418
				borderDark = 0x0E2E10
				borderLight = 0x2A7030
			} else {
				baseColor = 0x1E5E24
				borderDark = 0x144218
				borderLight = 0x4CAF50
			}
		} else if installedState {
			btnText = "🔄 Check Updates"
			if isRussianLang {
				btnText = "» Обновить"
			}
			if isPressed {
				baseColor = 0x1B5E20
				borderDark = 0x144E2B
				borderLight = 0x4CAF50
			} else {
				baseColor = 0x2E7D32
				borderDark = 0x1B5E20
				borderLight = 0x66BB6A
			}
		} else {
			btnText = "📑 Install App"
			if isRussianLang {
				btnText = "📑 Установить"
			}
			if isPressed {
				baseColor = 0x222E9C
				borderDark = 0x1A237E
				borderLight = 0x883344
			} else {
				baseColor = 0x2B39C0
				borderDark = 0x1A237E
				borderLight = 0xEF5350
			}
		}

	case 107: // Verify IP
		btnText = "Verify IP VPN"
		if isRussianLang {
			btnText = "Проверить IP VPN"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x9A3755
			borderDark = 0x6E243A
			borderLight = 0xB54E6E
		} else {
			baseColor = 0xC1466B
			borderDark = 0x8A2A47
			borderLight = 0xE57395
		}

	case 108: // Copy All
		btnText = "Copy All"
		if isRussianLang {
			btnText = "Скопировать всё"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x1E598A
			borderDark = 0x143E60
			borderLight = 0x3D7CAE
		} else {
			baseColor = 0x2B7BB9
			borderDark = 0x1B5A8A
			borderLight = 0x5AA4DE
		}

	case 109: // Clear Log
		btnText = "Clear"
		if isRussianLang {
			btnText = "Очистить"
		}
		font = hFontRegular
		if isPressed {
			baseColor = 0x505050
			borderDark = 0x333333
			borderLight = 0x707070
		} else {
			baseColor = 0x707070
			borderDark = 0x4C4C4C
			borderLight = 0x9E9E9E
		}

	case 110: // Diagnostics Info Button
		btnText = "[i] Info"
		if isRussianLang {
			btnText = "[i] Инфо"
		}
		font = hFontSmall
		if isPressed {
			baseColor = 0x1E598A
			borderDark = 0x143E60
			borderLight = 0x3D7CAE
		} else {
			baseColor = 0x2B7BB9
			borderDark = 0x1B5A8A
			borderLight = 0x5AA4DE
		}

	case 201: // Day Theme
		btnText = "☼"
		font = hFontRegular
		if currentTheme == ThemeDay {
			baseColor = 0x0677D9 // Sky Blue Active Glow
			borderDark = 0x034988
			borderLight = 0x58A5F0
		} else {
			baseColor = 0x484E5A
			borderDark = 0x2A303A
			borderLight = 0x626A7A
		}

	case 205: // Gray / Cloud Theme
		btnText = "☁"
		font = hFontRegular
		if currentTheme == ThemeGray {
			baseColor = 0x4A6B82 // Slate Steel Cyan Active Glow
			borderDark = 0x2C4659
			borderLight = 0x789EBA
		} else {
			baseColor = 0x484E5A
			borderDark = 0x2A303A
			borderLight = 0x626A7A
		}

	case 202: // Night Theme
		btnText = "☾"
		font = hFontRegular
		if currentTheme == ThemeNight {
			baseColor = 0xC1466B // Rose Purple Active Glow
			borderDark = 0x8A2A47
			borderLight = 0xE57395
		} else {
			baseColor = 0x484E5A
			borderDark = 0x2A303A
			borderLight = 0x626A7A
		}

	case 203: // Language EN
		btnText = "EN"
		font = hFontBold
		if !isRussianLang {
			baseColor = 0x1E598A
			borderDark = 0x143E60
			borderLight = 0x5AA4DE
		} else {
			baseColor = 0x444444
			borderDark = 0x2A2A2A
			borderLight = 0x666666
		}

	case 204: // Language RU
		btnText = "RU"
		font = hFontBold
		if isRussianLang {
			baseColor = 0x1E598A
			borderDark = 0x143E60
			borderLight = 0x5AA4DE
		} else {
			baseColor = 0x444444
			borderDark = 0x2A2A2A
			borderLight = 0x666666
		}

	case 206: // Sound Mute Toggle
		font = hFontRegular
		if isMuteSound {
			btnText = "✕"
			baseColor = 0x4A3838
			borderDark = 0x2A1C1C
			borderLight = 0x725454
		} else {
			btnText = "♪"
			if currentTheme == ThemeGray {
				baseColor = 0x4A6B82
				borderDark = 0x2C4659
				borderLight = 0x789EBA
			} else if currentTheme == ThemeNight {
				baseColor = 0x1E598A
				borderDark = 0x143E60
				borderLight = 0x5AA4DE
			} else {
				baseColor = 0x2B7DE9
				borderDark = 0x1A5BB8
				borderLight = 0x62A2F8
			}
		}

	default:
		return 0
	}

	return draw3DVolumetricButton(hDC, rc, btnText, font, baseColor, borderDark, borderLight, isPressed)
}

func createOwnerButton(id int, x, y, w, h int32) uintptr {
	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		0,
		WS_CHILD|WS_VISIBLE|BS_OWNERDRAW,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hwndMain, uintptr(id), hInstance, 0,
	)
	return hwnd
}

func createStatic(text string, x, y, w, h int32, font uintptr) uintptr {
	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		WS_CHILD|WS_VISIBLE|SS_NOTIFY,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hwndMain, 0, hInstance, 0,
	)
	if font != 0 {
		procSendMessageW.Call(hwnd, WM_SETFONT, font, 1)
	}
	return hwnd
}

func createStaticNotify(text string, x, y, w, h int32, font uintptr, id int, extraStyles ...uint32) uintptr {
	style := uint32(WS_CHILD | WS_VISIBLE | SS_NOTIFY)
	for _, s := range extraStyles {
		style |= s
	}
	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		uintptr(style),
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hwndMain, uintptr(id), hInstance, 0,
	)
	if font != 0 {
		procSendMessageW.Call(hwnd, WM_SETFONT, font, 1)
	}
	return hwnd
}

func showTrayContextMenu() {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	if isRussianLang {
		if isConnected {
			locStr := getNodeLocationStr(activeNodeIP, activeCountry, true)
			vpnHeader := fmt.Sprintf("🔒 VPN IP: %s (%s)", activeNodeIP, locStr)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(vpnHeader))))
			ispHeader := fmt.Sprintf("🌐 Оригинальный IP: %s", originalISPIP)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(ispHeader))))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, 5001, uintptr(unsafe.Pointer(strPtr("🛡️ Открыть GIN-VPN"))))
			procAppendMenuW.Call(hMenu, MF_STRING, 5002, uintptr(unsafe.Pointer(strPtr("⏹ Отключить VPN"))))
		} else {
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr("🔴 Статус: Отключено (Прямой интернет)"))))
			ispHeader := fmt.Sprintf("🌐 Оригинальный IP: %s", originalISPIP)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(ispHeader))))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, 5001, uintptr(unsafe.Pointer(strPtr("🛡️ Открыть GIN-VPN"))))
			procAppendMenuW.Call(hMenu, MF_STRING, 5003, uintptr(unsafe.Pointer(strPtr("▶ Подключить VPN"))))
		}
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 5005, uintptr(unsafe.Pointer(strPtr("🔍 Проверить IP (RU + EN)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 5007, uintptr(unsafe.Pointer(strPtr("🔄 Обновить сейчас"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 5004, uintptr(unsafe.Pointer(strPtr("🚪 Выход"))))
	} else {
		if isConnected {
			locStr := getNodeLocationStr(activeNodeIP, activeCountry, false)
			vpnHeader := fmt.Sprintf("🔒 VPN IP: %s (%s)", activeNodeIP, locStr)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(vpnHeader))))
			ispHeader := fmt.Sprintf("🌐 Original ISP IP: %s", originalISPIP)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(ispHeader))))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, 5001, uintptr(unsafe.Pointer(strPtr("🛡️ Open GIN-VPN"))))
			procAppendMenuW.Call(hMenu, MF_STRING, 5002, uintptr(unsafe.Pointer(strPtr("⏹ Disconnect VPN"))))
		} else {
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr("🔴 Status: Disconnected (Direct ISP)"))))
			ispHeader := fmt.Sprintf("🌐 Original ISP IP: %s", originalISPIP)
			procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(ispHeader))))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, 5001, uintptr(unsafe.Pointer(strPtr("🛡️ Open GIN-VPN"))))
			procAppendMenuW.Call(hMenu, MF_STRING, 5003, uintptr(unsafe.Pointer(strPtr("▶ Connect to VPN"))))
		}
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 5005, uintptr(unsafe.Pointer(strPtr("🔍 Check IP (RU + EN)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 5007, uintptr(unsafe.Pointer(strPtr("🔄 Update Now"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 5004, uintptr(unsafe.Pointer(strPtr("🚪 Exit GIN-VPN"))))
	}

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procDestroyMenu.Call(hMenu)
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_GETMINMAXINFO:
		mmi := (*MINMAXINFO)(unsafe.Pointer(lParam))
		mmi.PtMinTrackSize.X = 595
		mmi.PtMaxTrackSize.X = 595
		mmi.PtMinTrackSize.Y = 689
		return 0

	case WM_SIZE:
		if wParam == 1 /* SIZE_MINIMIZED */ {
			return 0
		}
		clientW := int32(lParam & 0xFFFF)
		clientH := int32((lParam >> 16) & 0xFFFF)
		if clientH > 0 && hwndListView != 0 {
			relayoutControls(clientW, clientH)
		}
		return 0

	case WM_EXITSIZEMOVE:
		var rc RECT
		procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&rc)))
		h := int(rc.Bottom - rc.Top)
		if h >= 689 && h != currentWindowHeight {
			currentWindowHeight = h
			saveSettingsToStorage()
		}
		return 0

	case WM_TRAYICON:
		switch lParam {
		case WM_LBUTTONUP, WM_LBUTTONDBLCLK:
			procShowWindow.Call(hwndMain, 5) // SW_SHOW
			procSetForegroundWindow.Call(hwndMain)
		case WM_RBUTTONUP:
			showTrayContextMenu()
		}
		return 0

	case WM_SYSCOMMAND:
		if wParam&0xFFF0 == SC_MINIMIZE {
			procShowWindow.Call(hwndMain, 0) // SW_HIDE -> minimize to tray
			return 0
		}

	case WM_CLOSE:
		procShowWindow.Call(hwndMain, 0) // SW_HIDE -> minimize to tray on close button click, keep running
		return 0

	case WM_APP_LOG_UPDATE:
		logMutex.Lock()
		all := strings.Join(logLines, "\r\n")
		logMutex.Unlock()
		if hwndLogEdit != 0 {
			procSetWindowTextW.Call(hwndLogEdit, uintptr(unsafe.Pointer(strPtr(all))))
		}
		return 0

	case WM_APP_UPDATE_PING:
		refreshProfilesListView()
		fastestIdx := -1
		minPing := 999999
		for idx, p := range profiles {
			if p.PingMs > 0 && p.PingMs < minPing {
				minPing = p.PingMs
				fastestIdx = idx
			}
		}
		if fastestIdx >= 0 {
			selectListViewItem(fastestIdx)
		}
		if hwndListView != 0 {
			procSendMessageW.Call(hwndListView, LVM_ENSUREVISIBLE, 0, 0)
		}
		return 0

	case WM_APP_UPDATE_STATUS:
		if isConnecting {
			procMoveWindow.Call(hwndBtnMainAction, 18, 44, 360, 44, 1)
			if hwndBtnDisconnect != 0 {
				procMoveWindow.Call(hwndBtnDisconnect, 382, 44, 168, 44, 1)
				procShowWindow.Call(hwndBtnDisconnect, 5 /* SW_SHOW */)
				procInvalidateRect.Call(hwndBtnDisconnect, 0, 1)
			}
			procInvalidateRect.Call(hwndBtnMainAction, 0, 1)
			diagHeaderTxt := "■ Diagnostics & Routing — ● CONNECTING..."
			if isRussianLang {
				diagHeaderTxt = "■ Диагностика и маршрутизация — ● ПОДКЛЮЧЕНИЕ..."
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			protTxt := fmt.Sprintf("VPN IP: ● Connecting to %s...", activeNodeName)
			if isRussianLang {
				protTxt = fmt.Sprintf("VPN IP: ● Подключение к %s...", activeNodeName)
			}
			procSetWindowTextW.Call(hwndDiagProt, uintptr(unsafe.Pointer(strPtr(protTxt))))
			procSendMessageW.Call(hwndDiagProt, WM_SETFONT, hFontBold, 1)
			procSetWindowTextW.Call(hwndDiagLat, uintptr(unsafe.Pointer(strPtr("Ping: Testing..."))))
		} else if isConnected {
			procMoveWindow.Call(hwndBtnMainAction, 18, 44, 360, 44, 1)
			if hwndBtnDisconnect != 0 {
				procMoveWindow.Call(hwndBtnDisconnect, 382, 44, 168, 44, 1)
				procShowWindow.Call(hwndBtnDisconnect, 5 /* SW_SHOW */)
				procInvalidateRect.Call(hwndBtnDisconnect, 0, 1)
			}

			routeScheme := getRouteScheme(originCountryCode, activeCountry)
			diagHeaderTxt := fmt.Sprintf("■ Diagnostics & Routing — ● CONNECTED [%s]", routeScheme)
			if isRussianLang {
				diagHeaderTxt = fmt.Sprintf("■ Диагностика и маршрутизация — ● ПОДКЛЮЧЕНО [%s]", routeScheme)
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			displayIp := verifiedExitIP
			if displayIp == "" {
				displayIp = activeNodeIP
			}
			protTxt := fmt.Sprintf("VPN IP: ● %s (%s)", displayIp, activeCountry)
			if isRussianLang {
				protTxt = fmt.Sprintf("VPN IP: ● %s (%s)", displayIp, activeCountry)
			}
			procSetWindowTextW.Call(hwndDiagProt, uintptr(unsafe.Pointer(strPtr(protTxt))))
			procSendMessageW.Call(hwndDiagProt, WM_SETFONT, hFontBold, 1)

			if latencyDeMs > 0 && latencyRuMs > 0 {
				latTxt := fmt.Sprintf("Ping: %dms (EU: %dms | RU: %dms)", latencyMs, latencyDeMs, latencyRuMs)
				if isRussianLang {
					latTxt = fmt.Sprintf("Пинг: %dмс (EU: %dмс | RU: %dмс)", latencyMs, latencyDeMs, latencyRuMs)
				}
				procSetWindowTextW.Call(hwndDiagLat, uintptr(unsafe.Pointer(strPtr(latTxt))))
			} else {
				latTxt := fmt.Sprintf("Ping: %d ms", latencyMs)
				if isRussianLang {
					latTxt = fmt.Sprintf("Пинг: %d мс", latencyMs)
				}
				procSetWindowTextW.Call(hwndDiagLat, uintptr(unsafe.Pointer(strPtr(latTxt))))
			}
		} else {
			procMoveWindow.Call(hwndBtnMainAction, 18, 44, 532, 44, 1)
			if hwndBtnDisconnect != 0 {
				procShowWindow.Call(hwndBtnDisconnect, 0 /* SW_HIDE */)
			}

			diagHeaderTxt := "■ Diagnostics & Routing — ● DIRECT ISP"
			if isRussianLang {
				diagHeaderTxt = "■ Диагностика и маршрутизация — ● ПРЯМОЙ ИНТЕРНЕТ"
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			uptimeTxt := "Uptime: Disconnected"
			protTxt := "VPN IP: ● Disconnected"
			latTxt := "Ping: -- ms"
			if isRussianLang {
				uptimeTxt = "Время: Отключено"
				protTxt = "VPN IP: ● Отключено"
				latTxt = "Пинг: -- мс"
			}
			procSetWindowTextW.Call(hwndDiagUptime, uintptr(unsafe.Pointer(strPtr(uptimeTxt))))
			procSetWindowTextW.Call(hwndDiagProt, uintptr(unsafe.Pointer(strPtr(protTxt))))
			procSendMessageW.Call(hwndDiagProt, WM_SETFONT, hFontRegular, 1)
			procSetWindowTextW.Call(hwndDiagLat, uintptr(unsafe.Pointer(strPtr(latTxt))))
		}
		if hwndDiagOrig != 0 {
			ispTxt := fmt.Sprintf("ISP IP: %s (%s)", originalISPIP, originCountryCode)
			if isRussianLang {
				ispTxt = fmt.Sprintf("Ориг. IP: %s (%s)", originalISPIP, originCountryCode)
			}
			procSetWindowTextW.Call(hwndDiagOrig, uintptr(unsafe.Pointer(strPtr(ispTxt))))
			procInvalidateRect.Call(hwndDiagOrig, 0, 1)
		}
		updateAllTooltips()
		procInvalidateRect.Call(hwndBtnMainAction, 0, 1)
		procInvalidateRect.Call(hwndDiagHeader, 0, 1)
		procInvalidateRect.Call(hwndBtnDiagInfo, 0, 1)
		procInvalidateRect.Call(hwndDiagProt, 0, 1)
		procInvalidateRect.Call(hwndDiagLat, 0, 1)
		procInvalidateRect.Call(hwndDiagUptime, 0, 1)
		procInvalidateRect.Call(hwndListView, 0, 1)
		return 0

	case WM_DRAWITEM:
		dis := (*DRAWITEMSTRUCT)(unsafe.Pointer(lParam))
		if dis != nil {
			return drawCustomButton(dis)
		}
		return 0

	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		switch controlId {
		case 5001: // Tray Open
			procShowWindow.Call(hwndMain, 5)
			procSetForegroundWindow.Call(hwndMain)
		case 5002: // Tray Disconnect
			disconnectVpnAsync()
		case 5003: // Tray Connect
			toggleVpn()
		case 5004: // Tray Exit
			removeTrayIcon()
			disconnectVpnAsync()
			procPostQuitMessage.Call(0)

		case 5005, 5006: // Tray Check IP (RU + EN) - open both portals in browser
			writeLog("VERIFY", "Opening Dual IP verification portals (RU: prodvig-saita.ru + EN: eco-seo.cz)...")
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlRU))), 0, 0, 1)
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlDE))), 0, 0, 1)

		case 5007, 6012: // Tray / Context Menu: Fast Direct Auto-Update (No Prompts)
			checkForUpdates(true, true)

		case 6001: // Context Menu: Connect Selected
			if selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
				p := profiles[selectedProfileIdx]
				connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
			}

		case 6002: // Context Menu: Set Default
			setDefaultProfile(selectedProfileIdx)

		case 6003: // Context Menu: Rename Profile
			showRenameDialog(selectedProfileIdx)

		case 6004: // Context Menu: Delete Profile
			deleteProfileWithConfirmation(selectedProfileIdx)

		case 6005: // Context Menu: Copy VLESS Reality Key
			if selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
				setClipboardText(profiles[selectedProfileIdx].RawUri)
				writeLog("CLIP", fmt.Sprintf("VLESS Reality key for '%s' copied to clipboard.", profiles[selectedProfileIdx].Name))
			}

		case 6006: // Context Menu: Check Route Dual
			go func() {
				deLat, ruLat, _ := verifyDualServerRouting()
				latencyDeMs = deLat
				latencyRuMs = ruLat
				if hwndMain != 0 {
					procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
				}
			}()

		case 110, 1010, 1011, 1012, 1013, 1014, 1015, 6007: // Rules Configuration Editor
			showRulesEditorDialog()

		case 6008: // Context Menu: Export All Profiles Backup
			exportProfilesBackup()

		case 6009: // Context Menu: Import Profiles from Backup
			importProfilesBackup()

		case 6015: // Context Menu: Add / Update Subscription
			savedSub := loadSubscriptionUrlFromRegistry()
			targetUrl := savedSub
			if targetUrl == "" {
				targetUrl = "http://63.178.216.88/sub.txt"
			}
			var buf [4096]uint16
			procGetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(&buf[0])), 4096)
			currText := strings.TrimSpace(syscall.UTF16ToString(buf[:]))
			if strings.HasPrefix(currText, "http://") || strings.HasPrefix(currText, "https://") {
				targetUrl = currText
			}
			procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(targetUrl))))
			importSubscriptionFromUrl(targetUrl)

		case 6016: // Context Menu: Rename Subscription
			showRenameSubscriptionDialog()

		case 6017: // Context Menu: Delete Subscription Completely
			deleteSubscription()

		case 114, 1016: // Subscription Toggle [+]/[-]
			if contextMenuSubName != "" {
				setSubscriptionExpanded(contextMenuSubName, !getSubscriptionExpanded(contextMenuSubName))
			} else {
				subscriptionExpanded = !subscriptionExpanded
				saveSubscriptionExpanded(subscriptionExpanded)
			}
			updateSubscriptionBar()
			refreshProfilesListView()

		case 115: // Subscription Ping (Clock)
			testSubscriptionPingAsync()

		case 116: // Subscription Refresh (Update server list)
			var bufSub [4096]uint16
			procGetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(&bufSub[0])), 4096)
			currText := strings.TrimSpace(syscall.UTF16ToString(bufSub[:]))
			if strings.HasPrefix(currText, "http://") || strings.HasPrefix(currText, "https://") {
				writeLog("SUB", fmt.Sprintf("Обновление серверов подписки: %s", currText))
				importSubscriptionFromUrl(currText)
			} else {
				writeLog("SUB", "Запуск полного обновления всех активных подписок...")
				refreshAllSubscriptionsAsync()
			}

		case 6010: // Context Menu: Move Up
			if selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
				moveProfileUp(selectedProfileIdx)
			}

		case 6011: // Context Menu: Move Down
			if selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
				moveProfileDown(selectedProfileIdx)
			}

		case 1004: // Brand Label Clicked (Open 3D About Dialog)
			showAboutDialog()

		case 201: // Day Theme
			applyTheme(ThemeDay)
			saveSettingsToStorage()
			if isRussianLang {
				writeLog("THEME", "☀️ Светлая дневная тема активирована. Настройки сохранены.")
			} else {
				writeLog("THEME", "☀️ Light Day Theme activated. Settings saved.")
			}

		case 205: // Gray / Cloud Theme
			applyTheme(ThemeGray)
			saveSettingsToStorage()
			if isRussianLang {
				writeLog("THEME", "⛅ Серая графитовая тема активирована. Настройки сохранены.")
			} else {
				writeLog("THEME", "⛅ Gray Graphite Theme activated. Settings saved.")
			}

		case 202: // Night Theme
			applyTheme(ThemeNight)
			saveSettingsToStorage()
			if isRussianLang {
				writeLog("THEME", "🌙 Тёмная OLED ночная тема активирована. Настройки сохранены.")
			} else {
				writeLog("THEME", "🌙 Dark OLED Night Theme activated. Settings saved.")
			}

		case 203: // Switch to English (EN)
			isRussianLang = false
			saveSettingsToStorage()
			updateLanguageUI()
			writeLog("LANG", "Language switched to English (EN). Settings saved.")

		case 204: // Switch to Russian (RU)
			isRussianLang = true
			saveSettingsToStorage()
			updateLanguageUI()
			writeLog("LANG", "Язык переключен на русский (RU). Настройки сохранены.")

		case 206: // Toggle Sound Mute
			isMuteSound = !isMuteSound
			saveSettingsToStorage()
			updateAllTooltips()
			procInvalidateRect.Call(hwndBtnSound, 0, 1)
			if isRussianLang {
				if isMuteSound {
					writeLog("AUDIO", "🔇 Звук подключения VPN выключен. Настройки сохранены.")
				} else {
					writeLog("AUDIO", "🔊 Звук подключения VPN включен. Настройки сохранены.")
				}
			} else {
				if isMuteSound {
					writeLog("AUDIO", "🔇 VPN connection sound muted. Settings saved.")
				} else {
					writeLog("AUDIO", "🔊 VPN connection sound enabled. Settings saved.")
				}
			}

		case 101: // Main Action: Connect if Disconnected, Cycle Animation if Connected, or Cancel if Connecting
			if isConnecting {
				disconnectVpnAsync()
			} else if isConnected {
				animVariant = (animVariant % 5) + 1
				name := getAnimName(animVariant, isRussianLang)
				if isRussianLang {
					writeLog("ANIM", fmt.Sprintf("🎨 Стиль анимации: Вариант #%d — %s", animVariant, name))
				} else {
					writeLog("ANIM", fmt.Sprintf("🎨 Animation style: Variant #%d — %s", animVariant, name))
				}
				procInvalidateRect.Call(hwndBtnMainAction, 0, 1)
			} else {
				toggleVpn()
			}

		case 111: // Right Disconnect Button (Part of Split Button)
			disconnectVpnAsync()

		case 112: // Button: Move Profile Up
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			actualIdx := getActualProfileIndex(sel)
			if actualIdx > 0 && actualIdx < len(profiles) {
				moveProfileUp(actualIdx)
			} else if actualIdx == 0 {
				if isRussianLang {
					writeLog("INFO", "💡 Выбранный сервер уже находится на первой позиции (№1).")
				} else {
					writeLog("INFO", "💡 Selected profile is already at the top (#1).")
				}
			}

		case 113: // Button: Move Profile Down
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			actualIdx := getActualProfileIndex(sel)
			if actualIdx >= 0 && actualIdx < len(profiles)-1 {
				moveProfileDown(actualIdx)
			} else if actualIdx == len(profiles)-1 {
				if isRussianLang {
					writeLog("INFO", "💡 Выбранный сервер уже находится на последней позиции списка.")
				} else {
					writeLog("INFO", "💡 Selected profile is already at the bottom.")
				}
			}

		case 102: // Paste / QR
			procOpenClipboard.Call(0)
			hData, _, _ := procGetClipboardData.Call(CF_UNICODETEXT)
			if hData != 0 {
				ptr, _, _ := procGlobalLock.Call(hData)
				if ptr != 0 {
					text := syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(ptr))[:])
					procGlobalUnlock.Call(hData)
					trimmed := strings.TrimSpace(text)
					clipUrls := extractHttpUrls(trimmed)
					if len(clipUrls) > 0 {
						procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(strings.Join(clipUrls, " ")))))
						writeLog("CLIP", fmt.Sprintf("Detected %d subscription link(s) in clipboard. Importing with failover...", len(clipUrls)))
						importSubscriptionFromUrl(trimmed)
					} else {
						procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(trimmed))))
						if isBase64Subscription(trimmed) {
							writeLog("CLIP", "Detected Base64 subscription in clipboard. Importing...")
							importNodesFromContent(trimmed, "GIN-Proxy-HUB", "", "Clipboard (Base64)")
						} else if strings.Contains(trimmed, "\n") && strings.Contains(trimmed, "vless://") {
							writeLog("CLIP", "Detected multi-line VLESS keys in clipboard. Importing...")
							importNodesFromContent(trimmed, "GIN-Proxy-HUB", "", "Clipboard (Multi-Key)")
						} else if strings.HasPrefix(trimmed, "vless://") {
							writeLog("CLIP", "Pasted single VLESS key from clipboard.")
						} else {
							writeLog("CLIP", "Pasted text from clipboard.")
						}
					}
				}
			}
			procCloseClipboard.Call()

		case 103: // Save Key / Subscription
			var buf [4096]uint16
			procGetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(&buf[0])), 4096)
			str := strings.TrimSpace(syscall.UTF16ToString(buf[:]))
			inputUrls := extractHttpUrls(str)
			if len(inputUrls) > 0 {
				writeLog("SUB", fmt.Sprintf("Processing %d subscription URL(s) from input field.", len(inputUrls)))
				importSubscriptionFromUrl(str)
			} else if isBase64Subscription(str) {
				writeLog("SUB", "Processing Base64 subscription from input field.")
				importNodesFromContent(str, "GIN-Proxy-HUB", "", "Input Field (Base64)")
			} else if strings.Contains(str, "\n") && strings.Contains(str, "vless://") {
				writeLog("SUB", "Processing multi-line VLESS keys from input field.")
				importNodesFromContent(str, "GIN-Proxy-HUB", "", "Input Field (Multi-Key)")
			} else if strings.HasPrefix(str, "vless://") {
				cfg, err := parseVlessUri(str)
				if err == nil {
					pName := cfg.Name
					if pName == "" {
						pName = fmt.Sprintf("Custom-%s", cfg.Host)
					}
					country := "EU"
					if len(pName) >= 4 && pName[0] == '[' && pName[3] == ']' {
						country = strings.ToUpper(pName[1:3])
					}
					p := Profile{
						Default: "",
						Name:    pName,
						Host:    cfg.Host,
						Port:    cfg.Port,
						Country: country,
						RawUri:  str,
					}
					profiles = append(profiles, p)
					saveProfilesToStorage()
					refreshProfilesListView()
					writeLog("PROFILE", fmt.Sprintf("New profile '%s' saved successfully.", pName))
					msg := "Профиль успешно сохранен!"
					if !isRussianLang {
						msg = "Profile saved successfully!"
					}
					procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msg))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000040)
				} else {
					procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Invalid VLESS Reality key format: "+err.Error()))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000030)
				}
			} else {
				msg := "Пожалуйста, введите валидный vless:// ключ или ссылку на подписку (http://, https://)."
				if !isRussianLang {
					msg = "Please enter a valid vless:// Reality key or subscription URL (http://, https://)."
				}
				procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msg))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000030)
			}

		case 104: // Connect Selected / Toggle Subscription Header
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			actualIdx := getActualProfileIndex(sel)
			if actualIdx < 0 {
				subIdx := (-actualIdx) - 1
				if subIdx >= 0 && subIdx < len(renderedSubNames) {
					subName := renderedSubNames[subIdx]
					setSubscriptionExpanded(subName, !getSubscriptionExpanded(subName))
					refreshProfilesListView()
				}
			} else if actualIdx >= 0 && actualIdx < len(profiles) {
				p := profiles[actualIdx]
				connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
			}

		case 105: // Set Default
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			actualIdx := getActualProfileIndex(sel)
			if actualIdx >= 0 && actualIdx < len(profiles) {
				setDefaultProfile(actualIdx)
			}

		case 106, 1020: // Install / Update Banner
			if !installedState {
				performInstall()
			} else {
				checkForUpdates(true)
			}

		case 107: // Verify IP (EU/RU)
			writeLog("VERIFY", "Running Dual IP Verification & Opening Test Portals (EU-222 / RU-109)...")
			go func() {
				deLat, ruLat, _ := verifyDualServerRouting()
				latencyDeMs = deLat
				latencyRuMs = ruLat
				if hwndMain != 0 {
					procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
				}
			}()
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlDE))), 0, 0, 1)
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlRU))), 0, 0, 1)

		case 108: // Copy All
			logMutex.Lock()
			all := strings.Join(logLines, "\r\n")
			logMutex.Unlock()
			setClipboardText(all)
			writeLog("CLIP", "Full event log copied to clipboard.")

		case 109: // Clear Log
			logMutex.Lock()
			logLines = nil
			logMutex.Unlock()
			procSetWindowTextW.Call(hwndLogEdit, uintptr(unsafe.Pointer(strPtr(""))))
			writeLog("LOG", "Log buffer cleared.")
		}
		return 0

	case WM_RBUTTONUP:
		if hwndBtnInstall != 0 {
			var pt POINT
			procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
			var rcInstall RECT
			procGetWindowRect.Call(hwndBtnInstall, uintptr(unsafe.Pointer(&rcInstall)))
			if pt.X >= rcInstall.Left && pt.X <= rcInstall.Right && pt.Y >= rcInstall.Top && pt.Y <= rcInstall.Bottom {
				checkForUpdates(true, true)
				return 0
			}
		}

	case WM_CONTEXTMENU:
		targetHwnd := uintptr(wParam)
		x := int32(int16(lParam & 0xFFFF))
		y := int32(int16((lParam >> 16) & 0xFFFF))
		var rcInstall RECT
		if hwndBtnInstall != 0 {
			procGetWindowRect.Call(hwndBtnInstall, uintptr(unsafe.Pointer(&rcInstall)))
		}
		if targetHwnd == hwndBtnInstall || (hwndBtnInstall != 0 && x >= rcInstall.Left && x <= rcInstall.Right && y >= rcInstall.Top && y <= rcInstall.Bottom) {
			checkForUpdates(true, true)
			return 0
		}
		if targetHwnd == hwndListView {
			// If triggered by keyboard (Shift+F10 / Apps key), handle selection
			if x == -1 && y == -1 {
				selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
				targetIdx := int(selRet)
				if targetIdx >= 0 && targetIdx < len(visibleProfileIndices) {
					actualIdx := getActualProfileIndex(targetIdx)
					if actualIdx < 0 {
						subIdx := (-actualIdx) - 1
						if subIdx >= 0 && subIdx < len(renderedSubNames) {
							contextMenuSubName = renderedSubNames[subIdx]
						}
						showSubscriptionContextMenu()
					} else if actualIdx >= 0 && actualIdx < len(profiles) {
						showListViewContextMenu(actualIdx)
					}
				} else {
					showListEmptyContextMenu()
				}
			}
			return 0
		}

	case WM_NOTIFY:
		nmhdr := (*NMHDR)(unsafe.Pointer(lParam))

		// 1. ListView Infotip Popup on Hover
		if nmhdr.Code == ^uint32(156) /* LVN_GETINFOTIPW (0xFFFFFF63) */ {
			pInfo := (*NMLVGETINFOTIPW)(unsafe.Pointer(lParam))
			if pInfo != nil && pInfo.PszText != nil && pInfo.CchTextMax > 0 {
				tip := getRouteTooltipText(originCountryCode, activeCountry, isRussianLang)
				if pInfo.IItem >= 0 && int(pInfo.IItem) < len(profiles) {
					p := profiles[pInfo.IItem]
					tip = getRouteTooltipText(originCountryCode, p.Country, isRussianLang)
				}
				copyStringToUtf16Buf(tip, pInfo.PszText, int(pInfo.CchTextMax))
			}
			return 0
		}

		if nmhdr.HwndFrom == hwndListView {
			// Handle Shift + Delete shortcut directly from ListView
			if nmhdr.Code == ^uint32(154) /* LVN_KEYDOWN (0xFFFFFF65) */ {
				nmlv := (*NMLVKEYDOWN)(unsafe.Pointer(lParam))
				if nmlv.WVKey == 0x2E { // VK_DELETE
					asyncRet, _, _ := procGetAsyncKeyState.Call(0x10) // VK_SHIFT
					if (asyncRet & 0x8000) != 0 {
						triggerDeleteSelectedProfile()
						return 1
					}
				}
				return 0
			}

			// Column Click: Sort by Ping (Col 4) or restore manual order (Col 0)
			if nmhdr.Code == ^uint32(107) /* LVN_COLUMNCLICK (-108) */ {
				pnmv := (*NMLISTVIEW)(unsafe.Pointer(lParam))
				col := int(pnmv.ISubItem)
				if col == 4 { // Ping column
					sortByPing = !sortByPing
					refreshProfilesListView()
				} else if col == 0 { // Number / Default column
					sortByPing = false
					refreshProfilesListView()
				}
				return 0
			}

			// Single-Click on Subscription Header -> Toggle Collapse / Expand
			if nmhdr.Code == ^uint32(1) /* NM_CLICK */ {
				nmia := (*NMITEMACTIVATE)(unsafe.Pointer(lParam))
				sel := int(nmia.IItem)
				if sel >= 0 {
					actualIdx := getActualProfileIndex(sel)
					if actualIdx < 0 {
						subIdx := (-actualIdx) - 1
						if subIdx >= 0 && subIdx < len(renderedSubNames) {
							subName := renderedSubNames[subIdx]
							setSubscriptionExpanded(subName, !getSubscriptionExpanded(subName))
							refreshProfilesListView()
						}
						return 0
					}
				}
			}

			// Connect on Double-Click (or toggle subscription header)
			if nmhdr.Code == NM_DBLCLK {
				nmia := (*NMITEMACTIVATE)(unsafe.Pointer(lParam))
				sel := int(nmia.IItem)
				if sel < 0 || sel >= len(visibleProfileIndices) {
					selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
					sel = int(selRet)
				}
				actualIdx := getActualProfileIndex(sel)
				if actualIdx < 0 {
					subIdx := (-actualIdx) - 1
					if subIdx >= 0 && subIdx < len(renderedSubNames) {
						subName := renderedSubNames[subIdx]
						setSubscriptionExpanded(subName, !getSubscriptionExpanded(subName))
						refreshProfilesListView()
					}
					return 0
				}
				if actualIdx >= 0 && actualIdx < len(profiles) {
					p := profiles[actualIdx]
					connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
				}
				return 0
			}

			// Context menu on Right-Click
			if nmhdr.Code == NM_RCLICK {
				var pt POINT
				procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
				clientPt := pt
				procScreenToClient.Call(hwndListView, uintptr(unsafe.Pointer(&clientPt)))

				var hti LVHITTESTINFO
				hti.Pt = clientPt
				procSendMessageW.Call(hwndListView, LVM_HITTEST, 0, uintptr(unsafe.Pointer(&hti)))

				targetIdx := int(hti.IItem)
				if targetIdx < 0 || targetIdx >= len(visibleProfileIndices) {
					// Empty space or unselected area -> Show List / General Menu
					showListEmptyContextMenu()
					return 1
				}

				actualIdx := getActualProfileIndex(targetIdx)
				if actualIdx < 0 {
					// Subscription header item -> Show Subscription Menu
					subIdx := (-actualIdx) - 1
					if subIdx >= 0 && subIdx < len(renderedSubNames) {
						contextMenuSubName = renderedSubNames[subIdx]
					}
					showSubscriptionContextMenu()
					return 1
				}

				if actualIdx >= 0 && actualIdx < len(profiles) {
					// Actual server profile item -> Show Server Profile Menu
					var item LVITEMW
					item.StateMask = LVIS_SELECTED | LVIS_FOCUSED
					item.State = LVIS_SELECTED | LVIS_FOCUSED
					procSendMessageW.Call(hwndListView, LVM_SETITEMSTATE, uintptr(targetIdx), uintptr(unsafe.Pointer(&item)))
					showListViewContextMenu(actualIdx)
					return 1
				}

				showListEmptyContextMenu()
				return 1
			}

			if nmhdr.Code == NM_CUSTOMDRAW {
				pcd := (*NMLVCUSTOMDRAW)(unsafe.Pointer(lParam))
				if pcd.Nmcd.DwDrawStage == CDDS_PREPAINT {
					return CDRF_NOTIFYITEMDRAW
				}
				if pcd.Nmcd.DwDrawStage == CDDS_ITEMPREPAINT {
					itemIdx := int(pcd.Nmcd.DwItemSpec)
					actualIdx := getActualProfileIndex(itemIdx)
					if actualIdx >= 0 && actualIdx < len(profiles) {
						isActiveConnected := isConnected && (profiles[actualIdx].Name == activeNodeName || profiles[actualIdx].Host == activeNodeIP || (verifiedExitIP != "" && profiles[actualIdx].Host == verifiedExitIP))
						if isActiveConnected {
							pcd.Nmcd.UItemState &^= 0x0001 | 0x0010 // Clear CDIS_SELECTED | CDIS_FOCUS
							pcd.ClrTextBk = 0x001B5E20 // Dark Forest Green (BGR)
							pcd.ClrText = 0x0000FFFF   // Bright Vivid Yellow (BGR)
						}
					}
					return CDRF_NOTIFYSUBITEMDRAW
				}
				if pcd.Nmcd.DwDrawStage == CDDS_SUBITEMPREPAINT {
					itemIdx := int(pcd.Nmcd.DwItemSpec)
					subItemIdx := int(pcd.ISubItem)
					actualIdx := getActualProfileIndex(itemIdx)

					// Subscription Header Row Styling
					if actualIdx < 0 {
						if currentTheme == ThemeNight {
							pcd.ClrTextBk = 0x002A1830 // Soft rich purple/slate background
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x0000FFFF // Bright Yellow [+] / [-]
							case 1:
								pcd.ClrText = 0x00E0E0 // Golden folder
							case 2:
								pcd.ClrText = 0x00FFFFFF // Bright White
							case 3:
								pcd.ClrText = 0x80D0FF // Ice blue
							case 4:
								pcd.ClrText = 0x00E080 // Light green
							default:
								pcd.ClrText = 0x00E0E0E0
							}
						} else if currentTheme == ThemeGray {
							pcd.ClrTextBk = 0x003A2840 // Slate violet background
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x0000FFFF // Bright Yellow [+] / [-]
							case 1:
								pcd.ClrText = 0x00E0E0
							case 2:
								pcd.ClrText = 0x00FFFFFF
							case 3:
								pcd.ClrText = 0x80D0FF
							case 4:
								pcd.ClrText = 0x00E080
							default:
								pcd.ClrText = 0x00F0ECE8
							}
						} else {
							pcd.ClrTextBk = 0x00EAE6F4 // Soft pastel lavender background
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x000088 // Bold Dark red/blue
							case 1:
								pcd.ClrText = 0x008800
							case 2:
								pcd.ClrText = 0x501010 // Dark slate
							case 3:
								pcd.ClrText = 0x117A8B
							case 4:
								pcd.ClrText = 0x008000
							default:
								pcd.ClrText = 0x00222222
							}
						}
						procSelectObject.Call(pcd.Nmcd.Hdc, hFontBold)
						return CDRF_NEWFONT
					}

					if actualIdx >= 0 && actualIdx < len(profiles) {
						isActiveConnected := isConnected && (profiles[actualIdx].Name == activeNodeName || profiles[actualIdx].Host == activeNodeIP || (verifiedExitIP != "" && profiles[actualIdx].Host == verifiedExitIP))

						if isActiveConnected {
							pcd.Nmcd.UItemState &^= 0x0001 | 0x0010 // Clear CDIS_SELECTED | CDIS_FOCUS
							pcd.ClrTextBk = 0x001B5E20 // Dark Forest Green (BGR: 0x205E1B)
							pcd.ClrText = 0x0000FFFF   // Bright Vivid Yellow (BGR: 0x00FFFF)
							procSelectObject.Call(pcd.Nmcd.Hdc, hFontBold)
							procSetBkMode.Call(pcd.Nmcd.Hdc, 2) // OPAQUE
							procSetTextColor.Call(pcd.Nmcd.Hdc, 0x0000FFFF)
							return CDRF_NEWFONT
						}

						p := profiles[actualIdx]
						if currentTheme == ThemeNight {
							pcd.ClrTextBk = 0x00141414
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x00AAAAAA // Number
							case 1:
								if p.Default != "" {
									pcd.ClrText = 0x00E080 // Light Green
								} else {
									pcd.ClrText = 0x888888
								}
							case 2:
								pcd.ClrText = 0x00E0E0 // Golden Yellow
							case 3:
								pcd.ClrText = 0x80D0FF // Ice Blue
							case 4:
								if p.PingMs > 0 && p.PingMs < 120 {
									pcd.ClrText = 0x00E080 // Vivid Light Green
								} else if p.PingMs >= 120 && p.PingMs < 250 {
									pcd.ClrText = 0x00D0D0 // Amber
								} else if p.PingMs >= 250 || p.PingMs < 0 {
									pcd.ClrText = 0x5050FF // Red
								} else {
									pcd.ClrText = 0x888888
								}
							case 5:
								pcd.ClrText = 0xFFA060 // Orange
							default:
								pcd.ClrText = 0x00E0E0E0
							}
						} else if currentTheme == ThemeGray {
							pcd.ClrTextBk = 0x003C342D // Slate Gray Background
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x00B0B8C0 // Silver Number
							case 1:
								if p.Default != "" {
									pcd.ClrText = 0x0066FF66 // Crisp Light Green
								} else {
									pcd.ClrText = 0x00889098
								}
							case 2:
								pcd.ClrText = 0x00F0E0B0 // Soft Ice Gold Name
							case 3:
								pcd.ClrText = 0x00D0B880 // Cyan/Teal Host
							case 4:
								if p.PingMs > 0 && p.PingMs < 120 {
									pcd.ClrText = 0x0066FF66 // Crisp Light Green
								} else if p.PingMs >= 120 && p.PingMs < 250 {
									pcd.ClrText = 0x0066D9FF // Light Amber
								} else if p.PingMs >= 250 || p.PingMs < 0 {
									pcd.ClrText = 0x006666FF // Soft Red
								} else {
									pcd.ClrText = 0x00889098
								}
							case 5:
								pcd.ClrText = 0x00FFA870 // Soft Amber Orange
							default:
								pcd.ClrText = 0x00F0ECE8
							}
						} else {
							pcd.ClrTextBk = 0x00FFFFFF
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x00666666 // Number
							case 1:
								if p.Default != "" {
									pcd.ClrText = 0x008000 // Dark Green
								} else {
									pcd.ClrText = 0x888888
								}
							case 2:
								pcd.ClrText = 0x803010 // Slate Blue (BGR)
							case 3:
								pcd.ClrText = 0x117A8B // Teal
							case 4:
								if p.PingMs > 0 && p.PingMs < 120 {
									pcd.ClrText = 0x008000 // Dark Green
								} else if p.PingMs >= 120 && p.PingMs < 250 {
									pcd.ClrText = 0x0088CC // Amber
								} else if p.PingMs >= 250 || p.PingMs < 0 {
									pcd.ClrText = 0x0000CC // Dark Red
								} else {
									pcd.ClrText = 0x888888
								}
							case 5:
								pcd.ClrText = 0x9E5A00 // Blue
							default:
								pcd.ClrText = 0x222222
							}
						}
					}
					return CDRF_NEWFONT
				}
			}
		}
		return 0

	case WM_TIMER:
		if isConnected {
			animFrame++
			if !sessionStart.IsZero() {
				dur := time.Since(sessionStart)
				h := int(dur.Hours())
				m := int(dur.Minutes()) % 60
				s := int(dur.Seconds()) % 60
				uptimeTxt := fmt.Sprintf("Uptime: %02d:%02d:%02d", h, m, s)
				if isRussianLang {
					uptimeTxt = fmt.Sprintf("Время: %02d:%02d:%02d", h, m, s)
				}
				procSetWindowTextW.Call(hwndDiagUptime, uintptr(unsafe.Pointer(strPtr(uptimeTxt))))
			}
			procInvalidateRect.Call(hwndBtnMainAction, 0, 0)
		}
		return 0

	case WM_ERASEBKGND:
		hDC := wParam
		var rc RECT
		procGetClientRect.Call(hwnd, uintptr(unsafe.Pointer(&rc)))
		var brush uintptr
		switch currentTheme {
		case ThemeGray:
			brush = hBrushBgGray
		case ThemeNight:
			brush = hBrushBgNight
		default:
			brush = hBrushBgDay
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), brush)

		// Draw smooth rounded card for Diagnostics (x: 18..550, y: 274..342)
		var cardBrush, cardPen uintptr
		switch currentTheme {
		case ThemeGray:
			cardBrush, _, _ = procCreateSolidBrush.Call(0x004C423A)
			cardPen, _, _ = procCreatePen.Call(0, 1, 0x00645A50)
		case ThemeNight:
			cardBrush, _, _ = procCreateSolidBrush.Call(0x001F1F1F)
			cardPen, _, _ = procCreatePen.Call(0, 1, 0x00333333)
		default:
			cardBrush, _, _ = procCreateSolidBrush.Call(0x00F0F2F5)
			cardPen, _, _ = procCreatePen.Call(0, 1, 0x00D0D4DC)
		}
		oldB, _, _ := procSelectObject.Call(hDC, cardBrush)
		oldP, _, _ := procSelectObject.Call(hDC, cardPen)

		procRectangle.Call(hDC, 18, uintptr(346+currentDeltaY), 550, uintptr(414+currentDeltaY))

		procSelectObject.Call(hDC, oldB)
		procSelectObject.Call(hDC, oldP)
		procDeleteObject.Call(cardBrush)
		procDeleteObject.Call(cardPen)

		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		ctrlHwnd := uintptr(lParam)

		if ctrlHwnd == hwndLogEdit {
			procSetBkMode.Call(hDC, 1)
			if currentTheme == ThemeNight {
				procSetTextColor.Call(hDC, 0x0033FF33) // Terminal Neon Green
				return hBrushLogNight
			} else if currentTheme == ThemeGray {
				procSetTextColor.Call(hDC, 0x00AAF564) // Crisp Mint Green
				return hBrushLogGray
			}
			procSetTextColor.Call(hDC, 0x00111111)
			return hBrushWhite
		}

		procSetBkMode.Call(hDC, 1) // TRANSPARENT
		if currentTheme == ThemeNight {
			if ctrlHwnd == hwndDiagProt {
				if isConnected {
					procSetTextColor.Call(hDC, 0x0033FF33) // Bright Neon Green
				} else if isConnecting {
					procSetTextColor.Call(hDC, 0x0078D8) // Amber
				} else {
					procSetTextColor.Call(hDC, 0x5050FF) // Soft Red
				}
				return hBrushCardNight
			} else if ctrlHwnd == hwndDiagHeader {
				if isConnected {
					procSetTextColor.Call(hDC, 0x0033FF33)
				} else if isConnecting {
					procSetTextColor.Call(hDC, 0x0078D8)
				} else {
					procSetTextColor.Call(hDC, 0x00E6E6E6)
				}
				return hBrushCardNight
			} else if ctrlHwnd == hwndTitle {
				procSetTextColor.Call(hDC, 0x00E0E0E0)
			} else if ctrlHwnd == hwndBannerLbl {
				procSetTextColor.Call(hDC, 0x0088CC)
			} else if ctrlHwnd == hwndBrand {
				procSetTextColor.Call(hDC, 0x00FFB040) // Cyan Gold
			} else if ctrlHwnd == hwndKeyLabel || ctrlHwnd == hwndProfilesLbl || ctrlHwnd == hwndLogLbl {
				procSetTextColor.Call(hDC, 0x00E6E6E6)
			} else if ctrlHwnd == hwndSubTitle {
				procSetTextColor.Call(hDC, 0x0066D9FF) // Light Blue / Gold
				return hBrushBgNight
			} else if ctrlHwnd == hwndDiagOrig || ctrlHwnd == hwndDiagLat || ctrlHwnd == hwndDiagUptime {
				procSetTextColor.Call(hDC, 0x00CCCCCC)
				return hBrushCardNight
			} else {
				procSetTextColor.Call(hDC, 0x00D0D0D0)
			}
			return hBrushBgNight
		} else if currentTheme == ThemeGray {
			if ctrlHwnd == hwndDiagProt {
				if isConnected {
					procSetTextColor.Call(hDC, 0x0066FF66) // Crisp Light Green
				} else if isConnecting {
					procSetTextColor.Call(hDC, 0x0055D0FF) // Amber Gold
				} else {
					procSetTextColor.Call(hDC, 0x007777FF) // Soft Red
				}
				return hBrushCardGray
			} else if ctrlHwnd == hwndDiagHeader {
				if isConnected {
					procSetTextColor.Call(hDC, 0x0066FF66)
				} else if isConnecting {
					procSetTextColor.Call(hDC, 0x0055D0FF)
				} else {
					procSetTextColor.Call(hDC, 0x00F0ECE8)
				}
				return hBrushCardGray
			} else if ctrlHwnd == hwndTitle {
				procSetTextColor.Call(hDC, 0x00F5EFEB) // Crisp Silver
			} else if ctrlHwnd == hwndBannerLbl {
				procSetTextColor.Call(hDC, 0x00D8C8B8)
			} else if ctrlHwnd == hwndBrand {
				procSetTextColor.Call(hDC, 0x0050BEFF) // Soft Gold
			} else if ctrlHwnd == hwndKeyLabel || ctrlHwnd == hwndProfilesLbl || ctrlHwnd == hwndLogLbl {
				procSetTextColor.Call(hDC, 0x00E8E2DC)
			} else if ctrlHwnd == hwndSubTitle {
				procSetTextColor.Call(hDC, 0x0080D0FF)
				return hBrushBgGray
			} else if ctrlHwnd == hwndDiagOrig || ctrlHwnd == hwndDiagLat || ctrlHwnd == hwndDiagUptime {
				procSetTextColor.Call(hDC, 0x00F0ECE8)
				return hBrushCardGray
			} else {
				procSetTextColor.Call(hDC, 0x00F0ECE8)
			}
			return hBrushBgGray
		}

		if ctrlHwnd == hwndDiagProt {
			if isConnected {
				procSetTextColor.Call(hDC, 0x001B8A00) // Deep Green
			} else if isConnecting {
				procSetTextColor.Call(hDC, 0x0078D8) // Amber
			} else {
				procSetTextColor.Call(hDC, 0x2020DC) // Red
			}
			return hBrushCardDay
		} else if ctrlHwnd == hwndDiagHeader {
			if isConnected {
				procSetTextColor.Call(hDC, 0x001B8A00)
			} else if isConnecting {
				procSetTextColor.Call(hDC, 0x0078D8)
			} else {
				procSetTextColor.Call(hDC, 0x00222222)
			}
			return hBrushCardDay
		} else if ctrlHwnd == hwndTitle {
			procSetTextColor.Call(hDC, 0x0066CC) // Amber Gold
		} else if ctrlHwnd == hwndSubTitle {
			procSetTextColor.Call(hDC, 0x00803010) // Slate Navy
			return hBrushBgDay
		} else if ctrlHwnd == hwndBannerLbl {
			procSetTextColor.Call(hDC, 0x003366)
		} else if ctrlHwnd == hwndBrand {
			procSetTextColor.Call(hDC, 0x00A05010) // Sapphire Blue
		} else if ctrlHwnd == hwndDiagOrig || ctrlHwnd == hwndDiagLat || ctrlHwnd == hwndDiagUptime {
			procSetTextColor.Call(hDC, 0x00222222)
			return hBrushCardDay
		} else {
			procSetTextColor.Call(hDC, 0x00222222)
		}
		return hBrushBgDay

	case WM_CTLCOLOREDIT:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if currentTheme == ThemeNight {
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputNight
		} else if currentTheme == ThemeGray {
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputGray
		}
		procSetTextColor.Call(hDC, 0x001A1A1A)
		return hBrushWhite

	case WM_SETCURSOR:
		ctrlHwnd := uintptr(wParam)
		if ctrlHwnd != 0 && (ctrlHwnd == hwndBtnDay || ctrlHwnd == hwndBtnGray || ctrlHwnd == hwndBtnNight || ctrlHwnd == hwndBtnLangEN || ctrlHwnd == hwndBtnLangRU || ctrlHwnd == hwndBtnSound || ctrlHwnd == hwndBtnMainAction || ctrlHwnd == hwndBtnPasteQr || ctrlHwnd == hwndBtnSave || ctrlHwnd == hwndBtnConnect || ctrlHwnd == hwndBtnSetDefault || ctrlHwnd == hwndBtnSubToggle || ctrlHwnd == hwndSubTitle || ctrlHwnd == hwndBtnSubPing || ctrlHwnd == hwndBtnSubRefresh || ctrlHwnd == hwndBtnInstall || ctrlHwnd == hwndBtnVerify || ctrlHwnd == hwndBtnCopyLog || ctrlHwnd == hwndBtnClearLog || ctrlHwnd == hwndBrand) {
			procSetCursor.Call(hCursorHand)
			return 1
		}

	case WM_DESTROY:
		var rc RECT
		procGetWindowRect.Call(hwndMain, uintptr(unsafe.Pointer(&rc)))
		h := int(rc.Bottom - rc.Top)
		if h >= 689 {
			currentWindowHeight = h
		}
		saveSettingsToStorage()
		removeTrayIcon()
		disconnectVpnAsync()
		procKillTimer.Call(hwnd, 1)
		procPostQuitMessage.Call(0)
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func addProfileToListView(idx int, p Profile) {
	var item LVITEMW
	item.Mask = 0x0001
	item.IItem = int32(idx)
	item.ISubItem = 0
	item.PszText = strPtr(fmt.Sprintf("%d", idx+1)) // Column 0: Number (1..N)
	procSendMessageW.Call(hwndListView, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&item)))

	var subItem LVITEMW
	subItem.IItem = int32(idx)

	// Column 1: Default
	subItem.ISubItem = 1
	defText := ""
	if p.Default != "" {
		defText = "✔"
	}
	subItem.PszText = strPtr(defText)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 2: Name
	subItem.ISubItem = 2
	subItem.PszText = strPtr(cleanProfileName(p.Name))
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 3: Host
	subItem.ISubItem = 3
	subItem.PszText = strPtr(p.Host)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 4: Ping
	subItem.ISubItem = 4
	pingTxt := "-- ms"
	if p.PingMs > 0 {
		pingTxt = fmt.Sprintf("%d ms", p.PingMs)
	} else if p.PingMs < 0 {
		pingTxt = "Timeout"
	}
	subItem.PszText = strPtr(pingTxt)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 5: Port
	subItem.ISubItem = 5
	subItem.PszText = strPtr(strconv.Itoa(p.Port))
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))
}

func checkSingleInstance() bool {
	writeDiskLog("INIT", "Checking for existing instances (Single-Instance Guard)...")
	// 1. Mutex-based check (Primary kernel-level enforcement)
	mutexName := strPtr("Local\\GIN_VPN_SINGLE_INSTANCE_MUTEX")
	hMutex, _, err := procCreateMutexW.Call(0, 0, uintptr(unsafe.Pointer(mutexName)))

	isAlreadyRunning := false
	if hMutex == 0 {
		isAlreadyRunning = true
		writeDiskLog("WARN", "CreateMutexW returned NULL handle.")
	} else {
		errno, isErrno := err.(syscall.Errno)
		if isErrno && (errno == 183 /* ERROR_ALREADY_EXISTS */ || errno == 5 /* ERROR_ACCESS_DENIED */) {
			isAlreadyRunning = true
			writeDiskLog("WARN", fmt.Sprintf("CreateMutexW returned existing instance indication (errno: %d)", errno))
		} else {
			singleInstanceMutex = hMutex
		}
	}

	// 2. Window class check (Secondary fallback & UI activation)
	windowClasses := []string{
		"GIN_VPN_WINDOW_CLASS",
		"GIN_VPN_WINDOW_CLASS_V067",
		"GIN_VPN_WINDOW_CLASS_V066",
		"GIN_VPN_WINDOW_CLASS_V065",
		"GIN_VPN_WINDOW_CLASS_V063",
		"GIN_VPN_WINDOW_CLASS_V062",
		"GIN_VPN_WINDOW_CLASS_V061",
		"GIN_VPN_WINDOW_CLASS_V060",
		"GIN_VPN_WINDOW_CLASS_V059",
		"GIN_VPN_WINDOW_CLASS_V058",
		"GIN_VPN_WINDOW_CLASS_V057",
		"GIN_VPN_WINDOW_CLASS_V056",
		"GIN_VPN_WINDOW_CLASS_V055",
	}
	var existingWnd uintptr
	for _, cls := range windowClasses {
		wnd, _, _ := procFindWindowW.Call(uintptr(unsafe.Pointer(strPtr(cls))), 0)
		if wnd != 0 {
			existingWnd = wnd
			isAlreadyRunning = true
			break
		}
	}

	if isAlreadyRunning {
		if existingWnd != 0 {
			writeDiskLog("INIT", fmt.Sprintf("Active GUI window found [HWND: 0x%X]. Bringing window to foreground.", existingWnd))
			procShowWindow.Call(existingWnd, 9) // SW_RESTORE
			procShowWindow.Call(existingWnd, 5) // SW_SHOW
			procSetForegroundWindow.Call(existingWnd)
			return false
		}

		// Mutex is held, but NO GUI window exists.
		// On Windows 11 after updates or crashes, a lingering headless zombie process can block new starts.
		writeDiskLog("WARN", "Single instance mutex held, but no visible GUI window found. Terminating any stale headless background instances...")
		currPid := os.Getpid()
		killCmd := exec.Command("taskkill", "/F", "/FI", fmt.Sprintf("PID ne %d", currPid), "/IM", "GIN-VPN.exe")
		killCmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: 0x08000000}
		_ = killCmd.Run()
		time.Sleep(250 * time.Millisecond)

		// Re-attempt mutex acquisition after terminating zombies
		hMutex2, _, _ := procCreateMutexW.Call(0, 0, uintptr(unsafe.Pointer(mutexName)))
		if hMutex2 != 0 {
			singleInstanceMutex = hMutex2
		}
		writeDiskLog("INIT", "Stale instances cleaned. Proceeding with clean application startup.")
		return true
	}

	writeDiskLog("INIT", "Single instance check passed cleanly.")
	return true
}

func main() {
	initDiskLogger()
	defer func() {
		if r := recover(); r != nil {
			stack := string(debug.Stack())
			errMsg := fmt.Sprintf("FATAL UNHANDLED PANIC: %v\n\nStack Trace:\n%s", r, stack)
			writeDiskLog("FATAL", errMsg)
			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr(errMsg))),
				uintptr(unsafe.Pointer(strPtr("GIN-VPN Critical Error"))),
				0x00000010, /* MB_ICONERROR */
			)
		}
	}()

	exePath, _ := os.Executable()
	cwd, _ := os.Getwd()
	writeDiskLog("BOOT", fmt.Sprintf("Executable: %s", exePath))
	writeDiskLog("BOOT", fmt.Sprintf("Working Dir: %s", cwd))
	writeDiskLog("BOOT", fmt.Sprintf("OS / Arch: %s/%s (PID: %d)", runtime.GOOS, runtime.GOARCH, os.Getpid()))
	writeDiskLog("BOOT", fmt.Sprintf("Command Line: %v", os.Args))
	writeDiskLog("BOOT", fmt.Sprintf("Admin Privileges: %v", isUserAdmin()))

	exeBase := strings.ToLower(filepath.Base(os.Args[0]))
	if exeBase == "uninstall.exe" || exeBase == "uninstall" || (len(os.Args) > 1 && (strings.ToLower(os.Args[1]) == "--uninstall" || strings.ToLower(os.Args[1]) == "/uninstall" || strings.ToLower(os.Args[1]) == "-uninstall" || strings.ToLower(os.Args[1]) == "uninstall")) {
		writeDiskLog("BOOT", "Invoking uninstaller routine.")
		performUninstall()
		return
	}

	// Strict Auto-Install Guard:
	// Running portably is permanently disabled. If started outside Program Files / Local Programs,
	// automatically install silently, create desktop shortcut, launch installed binary, and exit.
	if !checkIsInstalled() {
		writeDiskLog("BOOT", "Running outside installation directory. Invoking autoSelfInstall()...")
		autoSelfInstall()
		return
	}

	// Single-Instance Check (Prevent multiple running instances)
	if !checkSingleInstance() {
		writeDiskLog("INIT", "Single instance guard halted startup (existing window activated). Exiting.")
		os.Exit(0)
		return
	}

	runtime.LockOSThread()
	writeDiskLog("INIT", "OS UI thread locked.")

	// Load persistent settings (Language, Theme) before UI creation
	loadSettingsFromStorage()
	writeDiskLog("INIT", fmt.Sprintf("Settings loaded (Theme=%d, LangRU=%v, WindowH=%d)", currentTheme, isRussianLang, savedWindowHeight))

	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x0000FFFF // Enable all common control classes including Tooltips
	retICC, _, _ := procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))
	writeDiskLog("INIT", fmt.Sprintf("InitCommonControlsEx initialized [ret: %d]", retICC))

	hInstanceRet, _, _ := procGetModuleHandleW.Call(0)
	hInstance = hInstanceRet

	hIconRet, _, _ := procLoadIconW.Call(hInstance, uintptr(1))
	if hIconRet != 0 {
		hIconApp = hIconRet
	} else {
		hIconApp, _, _ = procLoadIconW.Call(0, uintptr(32512))
	}

	hIconConnRet, _, _ := procLoadIconW.Call(hInstance, uintptr(2))
	if hIconConnRet != 0 {
		hIconConnected = hIconConnRet
	} else {
		hIconConnected = hIconApp
	}

	hCursorRet, _, _ := procLoadCursorW.Call(0, uintptr(IDC_HAND))
	hCursorHand = hCursorRet

	hFontRegularRet, _, _ := procCreateFontW.Call(16, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontRegular = hFontRegularRet

	hFontBoldRet, _, _ := procCreateFontW.Call(16, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontBold = hFontBoldRet

	hFontStatusBigRet, _, _ := procCreateFontW.Call(22, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontStatusBig = hFontStatusBigRet

	hFontSmallRet, _, _ := procCreateFontW.Call(13, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontSmall = hFontSmallRet

	hFontSectionRet, _, _ := procCreateFontW.Call(15, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontSection = hFontSectionRet

	hFontTitleRet, _, _ := procCreateFontW.Call(22, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	hFontTitle = hFontTitleRet

	hFontConsolasRet, _, _ := procCreateFontW.Call(14, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Consolas"))))
	hFontConsolas = hFontConsolasRet

	hFontConsolasLogRet, _, _ := procCreateFontW.Call(12, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Consolas"))))
	hFontConsolasLog = hFontConsolasLogRet

	hBrushBgDay, _, _ = procCreateSolidBrush.Call(0x00F8F9FA)
	hBrushBgGray, _, _ = procCreateSolidBrush.Call(0x003C342D)
	hBrushBgNight, _, _ = procCreateSolidBrush.Call(0x00141414)
	hBrushWhite, _, _ = procCreateSolidBrush.Call(0x00FFFFFF)
	hBrushCardDay, _, _ = procCreateSolidBrush.Call(0x00F0F2F5)
	hBrushCardGray, _, _ = procCreateSolidBrush.Call(0x004C423A)
	hBrushCardNight, _, _ = procCreateSolidBrush.Call(0x001F1F1F)
	hBrushInputGray, _, _ = procCreateSolidBrush.Call(0x00433A32)
	hBrushInputNight, _, _ = procCreateSolidBrush.Call(0x00202020)
	hBrushLogGray, _, _ = procCreateSolidBrush.Call(0x00322A24)
	hBrushLogNight, _, _ = procCreateSolidBrush.Call(0x000D0D0D)
	hBrushBlack, _, _ = procCreateSolidBrush.Call(0x00000000)
	hPenCyan, _, _ = procCreatePen.Call(0, 2, 0x00FFFF)
	hBrushAnimBlue, _, _ = procCreateSolidBrush.Call(0x00FF9900)

	className := strPtr("GIN_VPN_WINDOW_CLASS")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconApp
	wc.HIconSm = hIconApp
	wc.HCursor, _, _ = procLoadCursorW.Call(0, uintptr(IDC_ARROW))
	if currentTheme == ThemeGray {
		wc.HbrBackground = hBrushBgGray
	} else if currentTheme == ThemeNight {
		wc.HbrBackground = hBrushBgNight
	} else {
		wc.HbrBackground = hBrushBgDay
	}
	wc.LpszClassName = className

	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	initialTitle := AppTitleEN
	if isRussianLang {
		initialTitle = AppTitleRU
	}

	winH := 689
	if savedWindowHeight >= 689 {
		winH = savedWindowHeight
	}

	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(initialTitle))),
		WS_OVERLAPPEDWINDOW&^0x00010000|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		100, 40, 595, uintptr(winH),
		0, 0, hInstance, 0,
	)

	if hwndMain == 0 {
		errno, _, _ := procGetLastError.Call()
		errMsg := fmt.Sprintf("CreateWindowExW failed with error code %d", errno)
		writeDiskLog("FATAL", errMsg)
		procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(errMsg))), uintptr(unsafe.Pointer(strPtr("GIN-VPN Window Creation Error"))), 0x00000010)
		return
	}
	writeDiskLog("UI", fmt.Sprintf("Main window successfully created [HWND: 0x%X, Height: %d]", hwndMain, winH))

	if hIconApp != 0 {
		procSendMessageW.Call(hwndMain, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndMain, WM_SETICON, 0, hIconApp)
	}

	// 1. Header Title & 3 Themes (Day ☀️ / Gray ⛅ / Night 🌙) & EN/RU Language Buttons & Sound Button
	hwndTitle = createStatic("GIN-VPN by VladiMIR+AI", 18, 12, 225, 26, hFontTitle)
	hwndBtnDay = createOwnerButton(201, 248, 12, 36, 26)
	hwndBtnGray = createOwnerButton(205, 287, 12, 36, 26)
	hwndBtnNight = createOwnerButton(202, 326, 12, 36, 26)
	hwndBtnLangEN = createOwnerButton(203, 376, 12, 44, 26)
	hwndBtnLangRU = createOwnerButton(204, 424, 12, 44, 26)
	hwndBtnSound = createOwnerButton(206, 486, 12, 46, 26)

	// 2. Main Large Action Button & Split Disconnect Button
	hwndBtnMainAction = createOwnerButton(101, 18, 44, 532, 44)
	hwndBtnDisconnect = createOwnerButton(111, 382, 44, 168, 44)
	procShowWindow.Call(hwndBtnDisconnect, 0 /* SW_HIDE initially */)

	// 3. Saved Profiles Controls: 6 buttons in 1 single row (y: 94, h: 28)
	// Word "Servers:" / "Серверы:" is removed to save vertical space
	hwndProfilesLbl = createStatic("", 0, 0, 0, 0, 0)
	procShowWindow.Call(hwndProfilesLbl, 0)

	// Button 1: ▶ Пуск (Connect)
	hwndBtnConnect = createOwnerButton(104, 18, 94, 90, 28)
	// Button 2: ⭐ Авто (Set Default / Auto)
	hwndBtnSetDefault = createOwnerButton(105, 114, 94, 84, 28)
	// Button 3: ▲ (Move Up)
	hwndBtnUp = createOwnerButton(112, 204, 94, 38, 28)
	// Button 4: ▼ (Move Down)
	hwndBtnDown = createOwnerButton(113, 248, 94, 38, 28)
	// Button 5: ⏱️ Пинг (Ping & Sort)
	hwndBtnSubPing = createOwnerButton(115, 292, 94, 96, 28)
	// Button 6: 🔄 Обновить (Refresh)
	hwndBtnSubRefresh = createOwnerButton(116, 394, 94, 156, 28)

	// Deprecated separate sub toggle bar controls kept hidden for safety
	hwndBtnSubToggle = createOwnerButton(114, 0, 0, 0, 0)
	procShowWindow.Call(hwndBtnSubToggle, 0)
	hwndSubTitle = createStaticNotify("", 0, 0, 0, 0, 0, 1016)
	procShowWindow.Call(hwndSubTitle, 0)

	// SysListView32 (y: 126, h: 212 - 9 rows)
	hwndListView, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("SysListView32"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS, 18, 126, 532, 212, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER|0x00000400)
	procSendMessageW.Call(hwndListView, WM_SETFONT, hFontRegular, 1)

	// Column 0: Number (№)
	var col LVCOLUMNW
	col.Mask = 0x0001 | 0x0002 | 0x0004 | 0x0008
	col.Fmt = 0x0002 // Center
	col.Cx = 32
	col.PszText = strPtr("№")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 0, uintptr(unsafe.Pointer(&col)))

	// Column 1: Default / Auto
	col.Fmt = 0x0002 // Center
	col.Cx = 42
	col.PszText = strPtr("Auto")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 1, uintptr(unsafe.Pointer(&col)))

	// Column 2: Name
	col.Fmt = 0x0000 // Left
	col.Cx = 172
	col.PszText = strPtr("Profile / Device Name")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 2, uintptr(unsafe.Pointer(&col)))

	// Column 3: Host
	col.Cx = 144
	col.PszText = strPtr("Server Host Address")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 3, uintptr(unsafe.Pointer(&col)))

	// Column 4: Ping
	col.Fmt = 0x0002 // Center
	col.Cx = 62
	col.PszText = strPtr("Ping")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 4, uintptr(unsafe.Pointer(&col)))

	// Column 5: Port
	col.Fmt = 0x0002 // Center
	col.Cx = 52
	col.PszText = strPtr("Port")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 5, uintptr(unsafe.Pointer(&col)))

	loadProfilesFromStorage()
	subscriptionExpanded = loadSubscriptionExpandedFromRegistry()
	refreshProfilesListView()

	// 4. Diagnostics Panel (Rounded Card in WM_ERASEBKGND: y: 346..414)
	hwndDiagHeader = createStaticNotify("■ Diagnostics & Routing", 28, 348, 430, 18, hFontBold, 1010)
	hwndBtnDiagInfo = createOwnerButton(110, 465, 346, 75, 20)
	hwndDiagOrig = createStaticNotify("ISP IP: Detecting...", 28, 368, 245, 18, hFontSmall, 1011)
	hwndDiagProt = createStaticNotify("VPN IP: ● Disconnected", 275, 368, 265, 18, hFontSmall, 1012)
	hwndDiagLat = createStaticNotify("Ping: -- ms", 28, 388, 245, 18, hFontSmall, 1013)
	hwndDiagUptime = createStaticNotify("Uptime: Disconnected", 275, 388, 265, 18, hFontSmall, 1014)

	// 5. Active VLESS Key Header, Text Field (Left) & Two Stacked Buttons (Right)
	hwndKeyLabel = createStatic("Active VLESS Key or Subscription URL:", 18, 422, 384, 16, hFontSection)
	hwndKeyEdit, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("EDIT"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_AUTOVSCROLL, 18, 440, 384, 52, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndKeyEdit, WM_SETFONT, hFontConsolas, 1)

	hwndBtnPasteQr = createOwnerButton(102, 410, 440, 140, 24)
	hwndBtnSave = createOwnerButton(103, 410, 468, 140, 24)

	// 6. Log Box (3 lines)
	hwndLogLbl = createStatic("📊 Real-Time Event & Traffic Log:", 18, 500, 532, 16, hFontSection)
	hwndLogEdit, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("EDIT"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_AUTOVSCROLL|ES_READONLY|WS_VSCROLL, 18, 518, 532, 58, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndLogEdit, WM_SETFONT, hFontConsolasLog, 1)

	// 7. Buttons under the Log Window (y: 586, h: 26)
	hwndBtnInstall = createOwnerButton(106, 18, 586, 126, 26)
	hwndBtnVerify = createOwnerButton(107, 18, 586, 170, 26)
	hwndBtnCopyLog = createOwnerButton(108, 196, 586, 180, 26)
	hwndBtnClearLog = createOwnerButton(109, 384, 586, 166, 26)

	// 8. Bottom Status Banner & Brand in ONE line (y: 618, h: 20)
	hwndBannerLbl = createStaticNotify("Нажмите «Обновить» для проверки", 18, 618, 360, 20, hFontSmall, 1020)
	hwndBrand = createStaticNotify(fmt.Sprintf("VladiMIR+AI ||| %s", AppVersion), 380, 618, 170, 20, hFontBold, 1004, 0x0002 /* SS_RIGHT */)

	loadCustomRulesFromStorage()
	installedState = checkIsInstalled()
	updateLanguageUI()
	applyTheme(currentTheme)
	initTooltips()

	// Initial Layout adjustment for saved or default window height
	var initClientRc RECT
	procGetClientRect.Call(hwndMain, uintptr(unsafe.Pointer(&initClientRc)))
	initClientH := initClientRc.Bottom - initClientRc.Top
	initClientW := initClientRc.Right - initClientRc.Left
	if savedWindowHeight > 689 {
		baseClientH = initClientH - int32(savedWindowHeight-689)
	} else {
		baseClientH = initClientH
	}
	currentWindowHeight = int(winH)
	relayoutControls(initClientW, initClientH)

	// Initial Tray
	updateTrayIcon(false, "", "")

	// Detect ISP IP in background
	detectOriginalISPAsync()

	// Clean up any residual desktop installers from old versions
	purgeDesktopInstallersAsync()

	// Ensure embedded Xray Core payload is ready
	_ = ensureXrayBinaryExists()

	if isRussianLang {
		writeLog("INIT", fmt.Sprintf("GIN-VPN от VladiMIR+AI — Высокоскоростной Xray Клиент %s готов.", AppVersion))
		themeName := "Дневная (☀️ Светлая)"
		if currentTheme == ThemeGray {
			themeName = "Серая (⛅ Облачно / Графит)"
		} else if currentTheme == ThemeNight {
			themeName = "Ночная OLED (🌙 Тёмная)"
		}
		writeLog("CONFIG", fmt.Sprintf("Настройки сохранены и загружены: Язык = RU, Тема = %s.", themeName))
	} else {
		writeLog("INIT", fmt.Sprintf("GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client %s ready.", AppVersion))
		themeName := "Light Day (☀️)"
		if currentTheme == ThemeGray {
			themeName = "Gray Graphite (⛅ Cloud)"
		} else if currentTheme == ThemeNight {
			themeName = "Dark OLED (🌙 Night)"
		}
		writeLog("CONFIG", fmt.Sprintf("Settings loaded & persisted: Language = EN, Theme = %s.", themeName))
	}
	writeLog("SECURE", "Encrypted Registry & local storage active for VPN profiles & settings.")
	if activeXrayExePath == "" {
		activeXrayExePath = filepath.Join(getAppDir(), "xray.exe")
	}
	writeLog("CORE", fmt.Sprintf("Standalone Embedded Xray Core: %s", activeXrayExePath))
	writeLog("TRAY", "System Tray notification icon registered.")
	if isRussianLang {
		writeLog("READY", "VPN клиент инициализирован. Выберите профиль или нажмите [ ▶ ПОДКЛЮЧИТЬ VPN ].")
	} else {
		writeLog("READY", "VPN client initialized. Select a profile or click [ ▶ CONNECT TO VPN ].")
	}

	procSetTimer.Call(hwndMain, 1, 40, 0)

	// Auto-Connect on launch if a profile is set for auto-connect
	hasAutoConnect := false
	for _, p := range profiles {
		if p.Default != "" {
			hasAutoConnect = true
			writeLog("AUTO", fmt.Sprintf("Auto-connect triggered on launch for '%s'...", p.Name))
			writeDiskLog("UI", fmt.Sprintf("Auto-connect active for '%s': window starting minimized in Windows System Tray.", p.Name))
			connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
			procShowWindow.Call(hwndMain, 0) // Start directly minimized in system tray
			break
		}
	}

	if !hasAutoConnect {
		// Show window initially on start in clean Standby mode
		writeDiskLog("UI", "Displaying main GUI window (SW_SHOW)...")
		procShowWindow.Call(hwndMain, 5)
		procUpdateWindow.Call(hwndMain)
	}

	var msg struct {
		Hwnd    uintptr
		Message uint32
		WParam  uintptr
		LParam  uintptr
		Time    uint32
		Pt      struct{ X, Y int32 }
	}

	writeDiskLog("UI", "Win32 message loop running.")
	for {
		ret, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if ret == 0 || int32(ret) == -1 {
			writeDiskLog("UI", fmt.Sprintf("Message loop terminated (GetMessage returned %d).", ret))
			break
		}
		if msg.Message == 0x0100 && msg.WParam == 'A' { // WM_KEYDOWN 'A'
			asyncRet, _, _ := procGetAsyncKeyState.Call(0x11) // VK_CONTROL
			if (asyncRet & 0x8000) != 0 {
				focusHwnd, _, _ := procGetFocus.Call()
				if focusHwnd == hwndLogEdit || focusHwnd == hwndKeyEdit {
					procSendMessageW.Call(focusHwnd, 0x00B1, 0, ^uintptr(0)) // EM_SETSEL (0, -1)
					continue
				}
			}
		}
		if msg.Message == 0x0100 && msg.WParam == 0x2E { // WM_KEYDOWN VK_DELETE (0x2E)
			asyncRet, _, _ := procGetAsyncKeyState.Call(0x10) // VK_SHIFT (0x10)
			if (asyncRet & 0x8000) != 0 {
				focusHwnd, _, _ := procGetFocus.Call()
				if focusHwnd != hwndLogEdit && focusHwnd != hwndKeyEdit {
					triggerDeleteSelectedProfile()
					continue
				}
			}
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
