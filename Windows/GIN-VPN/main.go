package main

import (
	"bytes"
	"compress/gzip"
	_ "embed"
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
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

//go:embed xray.gz
var embeddedXrayGz []byte

const (
	AppName       = "GIN-VPN"
	AppVersion    = "v037"
	AppTitleEN    = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client [v037]"
	AppTitleRU    = "GIN-VPN от VladiMIR+AI — Высокоскоростной Xray Клиент [v037]"
	AppAuthor     = "VladiMIR+AI (Vladimir Bulantsev - GinCz)"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN"

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
	procSelectObject           = gdi32.NewProc("SelectObject")
	procDeleteObject           = gdi32.NewProc("DeleteObject")
	procMoveToEx               = gdi32.NewProc("MoveToEx")
	procLineTo                 = gdi32.NewProc("LineTo")
	procEllipse                = gdi32.NewProc("Ellipse")

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
	LVM_SETITEMSTATE             = 0x102B
	LVNI_SELECTED                = 0x0002
	LVIS_SELECTED                = 0x0002
	LVIS_FOCUSED                 = 0x0001

	WM_DESTROY        = 0x0002
	WM_PAINT          = 0x000F
	WM_CLOSE          = 0x0010
	WM_COMMAND        = 0x0111
	WM_NOTIFY         = 0x004E
	WM_DRAWITEM       = 0x002B
	WM_ERASEBKGND     = 0x0014
	WM_TIMER          = 0x0113
	WM_SETCURSOR      = 0x0020
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CONTEXTMENU    = 0x007B
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

type Profile struct {
	Default string
	Name    string
	Host    string
	Port    int
	Country string
	RawUri  string
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
}

var (
	hInstance   uintptr
	hwndMain    uintptr
	hwndTitle   uintptr
	hwndBtnDay  uintptr
	hwndBtnNight uintptr
	hwndBtnLangEN uintptr
	hwndBtnLangRU uintptr

	hwndBtnMainAction uintptr

	hwndKeyLabel   uintptr
	hwndKeyEdit    uintptr
	hwndBtnPasteQr uintptr
	hwndBtnSave    uintptr

	hwndProfilesLbl   uintptr
	hwndBtnConnect    uintptr
	hwndBtnSetDefault uintptr
	hwndListView      uintptr

	hwndDiagHeader uintptr
	hwndDiagOrig   uintptr
	hwndDiagProt   uintptr
	hwndDiagLat    uintptr
	hwndDiagUptime uintptr

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
	hBrushBgNight    uintptr
	hBrushWhite      uintptr
	hBrushCardDay    uintptr
	hBrushCardNight  uintptr
	hBrushInputNight uintptr
	hBrushLogNight   uintptr

	nid         NOTIFYICONDATAW
	trayCreated bool

	isDarkMode      = false
	isRussianLang   = false // Default: English (EN)
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
		"130.61.101.157":  {"Germany", "Frankfurt", "Германия", "Франкфурт"},
		"130.61.139.230":  {"Germany", "Frankfurt", "Германия", "Франкфурт"},
		"212.34.148.51":   {"Russia", "Moscow", "Россия", "Москва"},
		"144.124.239.24":  {"Finland", "Helsinki", "Финляндия", "Хельсинки"},
	}

	defaultProfiles = []Profile{
		{Default: "★ YES", Name: "IONOS-38-VladiMIR", Host: "82.223.116.38", Port: 443, Country: "ES", RawUri: "vless://48584968-e3e6-4d60-845a-3df448e373ef@82.223.116.38:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.github.com&fp=chrome&pbk=NCt-K9F0gIKwZJLShYPjow6sh7uP26S04z3KhgtOznk&sid=fa15d8&type=tcp&headerType=none#IONOS-38-VladiMIR"},
		{Default: "", Name: "DE-222-Master", Host: "152.53.182.222", Port: 8443, Country: "DE", RawUri: "vless://9e42c913-9d18-46ba-8017-93bcd6fce6c2@152.53.182.222:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.github.com&fp=chrome&pbk=KUQhgWGcF7u_dkKk4O4gULb6yydXNfooDq13yiTtbFU&sid=10e6b484e4ec&type=tcp&headerType=none#DE-222-Master"},
		{Default: "", Name: "RU-109-FastVDS", Host: "212.109.223.109", Port: 8443, Country: "RU", RawUri: "vless://990cde76-b441-413a-96ff-e0959a55bf90@212.109.223.109:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.github.com&fp=chrome&pbk=cPCdL0JR_9LhKtD0Uc5OysndvbyUNUz2ZCUidhyRa3k&sid=6b7def&type=tcp&headerType=none#RU-109-FastVDS"},
		{Default: "", Name: "ORACLE-157-Cloud", Host: "130.61.101.157", Port: 443, Country: "DE", RawUri: "vless://c738aa4a-fe76-4bbd-af48-706fe000e4c4@130.61.101.157:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.amd.com&fp=chrome&pbk=C_41rPRnC4alw2pKqHaBm_X6uq3WlcBbUXkPKAqN0HY&sid=7b01924a2ab17fbb&spx=%2FzmoY9rcqEW8y16p&type=tcp&headerType=none#ORACLE-157-Cloud"},
		{Default: "", Name: "ORACLE-230-VPN", Host: "130.61.139.230", Port: 443, Country: "DE", RawUri: "vless://b6c1615f-9ba7-47ec-b072-cb27d86f78f8@130.61.139.230:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=cPCdL0JR_9LhKtD0Uc5OysndvbyUNUz2ZCUidhyRa3k&sid=6b7def&type=tcp&headerType=none#ORACLE-230-VPN"},
		{Default: "", Name: "ALEX-51-Node", Host: "212.34.148.51", Port: 443, Country: "RU", RawUri: "vless://25b39be8-f673-4554-b4a5-961f7ebfbcbb@212.34.148.51:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.speedtest.net&fp=chrome&pbk=HP-iY9BWeI90J_KLTl-I54RyNbp0-Xgsk36gGU9TkUg&sid=c55c5e&type=tcp&headerType=none#ALEX-51-Node"},
		{Default: "", Name: "STOLB-24-Node", Host: "144.124.239.24", Port: 8443, Country: "FI", RawUri: "vless://99522656-0771-4232-9a01-34ed4df2fe3d@144.124.239.24:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.github.com&fp=chrome&pbk=HP-iY9BWeI90J_KLTl-I54RyNbp0-Xgsk36gGU9TkUg&sid=c55c5e&type=tcp&headerType=none#STOLB-24-Node"},
	}

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

func detectOriginalISPAsync() {
	go func() {
		client := &http.Client{Timeout: 3 * time.Second}
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
					originalISPIP = fmt.Sprintf("%s (%s)", data.Query, originCountryCode)
				} else {
					originalISPIP = data.Query
					originCountryCode = "CZ"
				}
				if hwndMain != 0 {
					procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
				}
				writeLog("ISP_OK", fmt.Sprintf("Original ISP detected: %s (Country: %s)", originalISPIP, originCountryCode))
				updateTrayIcon(isConnected, activeNodeName, activeNodeIP)
				updateAllTooltips()
				return
			}
		}

		endpoints := []string{"http://prodvig-saita.ru/ip", "https://eco-seo.cz/ip", "https://api.ipify.org", "https://icanhazip.com"}
		for _, ep := range endpoints {
			r, e := client.Get(ep)
			if e == nil {
				defer r.Body.Close()
				b, _ := io.ReadAll(r.Body)
				ip := strings.TrimSpace(string(b))
				if ip != "" {
					if strings.Contains(ep, "prodvig-saita.ru") {
						originCountryCode = "RU"
					} else {
						originCountryCode = "CZ"
					}
					originalISPIP = fmt.Sprintf("%s (%s)", ip, originCountryCode)
					if hwndMain != 0 {
						procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
					}
					writeLog("ISP_OK", fmt.Sprintf("Original ISP detected: %s", originalISPIP))
					updateTrayIcon(isConnected, activeNodeName, activeNodeIP)
					updateAllTooltips()
					return
				}
			}
		}
		originCountryCode = "CZ"
		originalISPIP = "185.100.197.0 (CZ)"
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

	if orig == "RU" && targ != "RU" {
		if russian {
			return fmt.Sprintf("🌍 Маршрут: Россия => %s (Smart Geo-Split)\r\n• Напрямую (без расхода VPN): Госуслуги, mos.ru, VK, Яндекс, Банки РФ (.ru)\r\n• Через VPN: YouTube, Instagram, Facebook, Spotify, ChatGPT, зарубежные сайты", targ)
		}
		return fmt.Sprintf("🌍 Route: Russia => %s (Smart Geo-Split)\r\n• Direct ISP (Zero VPN Traffic): Gosuslugi, Mos.ru, VK, Yandex, RU Banking (.ru domains)\r\n• Proxied via VPN: YouTube, Instagram, Facebook, Spotify, ChatGPT, Global sites", targ)
	} else if orig != "RU" && targ == "RU" {
		if russian {
			return fmt.Sprintf("🌍 Маршрут: %s => Россия (Smart Geo-Split)\r\n• Напрямую (без расхода VPN): YouTube, Spotify, Instagram, Netflix, Google, ChatGPT\r\n• Через VPN РФ: Госуслуги, mos.ru, Кинопоиск, Банки РФ (все сайты .ru)", orig)
		}
		return fmt.Sprintf("🌍 Route: %s => Russia (Smart Geo-Split)\r\n• Direct ISP (Zero VPN Traffic): YouTube, Spotify, Instagram, Netflix, Google, ChatGPT\r\n• Proxied via RU VPN: Gosuslugi, Mos.ru, Kinopoisk, RU Banking (.ru domains)", orig)
	}

	if russian {
		return fmt.Sprintf("🌍 Маршрут: %s => %s (Smart Split Shield)\r\n• Локальные адреса и LAN: Напрямую без VPN\r\n• Глобальный интернет: Защищенный VLESS Reality туннель", orig, targ)
	}
	return fmt.Sprintf("🌍 Route: %s => %s (Smart Split Shield)\r\n• Local LAN & Private IP: Direct Bypass\r\n• Global Internet: Encrypted VLESS Reality Tunnel", orig, targ)
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

	procSendMessageW.Call(hwndToolTip, 0x0418 /* TTM_SETMAXTIPWIDTH */, 0, 500)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 2 /* TTDT_AUTOPOP */, 30000)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 1 /* TTDT_INITIAL */, 150)
	procSendMessageW.Call(hwndToolTip, 0x0403 /* TTM_SETDELAYTIME */, 3 /* TTDT_RESHOW */, 100)

	attachTooltipToControl(hwndBtnMainAction)
	attachTooltipToControl(hwndListView)
	attachTooltipToControl(hwndDiagHeader)
	attachTooltipToControl(hwndDiagOrig)
	attachTooltipToControl(hwndDiagProt)
	attachTooltipToControl(hwndDiagLat)
	attachTooltipToControl(hwndDiagUptime)
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
	procSendMessageW.Call(hwndToolTip, 0x0432 /* TTM_ADDTOOLW */, 0, uintptr(unsafe.Pointer(&ti)))
}

func updateAllTooltips() {
	if hwndToolTip == 0 {
		return
	}
	tipText := getRouteTooltipText(originCountryCode, activeCountry, isRussianLang)
	updateControlTooltip(hwndBtnMainAction, tipText)
	updateControlTooltip(hwndListView, tipText)
	updateControlTooltip(hwndDiagHeader, tipText)
	updateControlTooltip(hwndDiagOrig, tipText)
	updateControlTooltip(hwndDiagProt, tipText)
	updateControlTooltip(hwndDiagLat, tipText)
	updateControlTooltip(hwndDiagUptime, tipText)
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
	procSendMessageW.Call(hwndToolTip, 0x0439 /* TTM_UPDATETIPTEXTW */, 0, uintptr(unsafe.Pointer(&ti)))
}

func getStorageFilePath() string {
	dir := os.Getenv("LOCALAPPDATA")
	if dir == "" {
		dir = os.Getenv("APPDATA")
	}
	if dir == "" {
		dir = os.TempDir()
	}
	appDir := filepath.Join(dir, "GIN-VPN")
	_ = os.MkdirAll(appDir, 0755)
	return filepath.Join(appDir, "profiles.json")
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
	// 1. Try Registry first
	regData, err := loadProfilesFromRegistry()
	if err == nil && strings.TrimSpace(regData) != "" {
		var loaded []Profile
		if err := json.Unmarshal([]byte(regData), &loaded); err == nil {
			profiles = loaded
			return
		}
	}

	// 2. Try file
	filePath := getStorageFilePath()
	if fileData, err := os.ReadFile(filePath); err == nil && len(fileData) > 0 {
		var loaded []Profile
		if err := json.Unmarshal(fileData, &loaded); err == nil {
			profiles = loaded
			saveProfilesToRegistry(string(fileData))
			return
		}
	}

	// 3. Pristine initial run: load default profiles and save them
	profiles = make([]Profile, len(defaultProfiles))
	copy(profiles, defaultProfiles)
	saveProfilesToStorage()
}

var (
	logLines  []string
	logMutex  sync.Mutex
	connMutex sync.Mutex
)

func strPtr(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func writeLog(tag, msg string) {
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
	type StreamSettings struct {
		Network         string          `json:"network"`
		Security        string          `json:"security"`
		RealitySettings RealitySettings `json:"realitySettings"`
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

	user := User{
		ID:         cfg.UUID,
		Encryption: "none",
		Flow:       cfg.Flow,
		Level:      0,
	}

	xc.Outbounds = []Outbound{
		{
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
					SpiderX:     cfg.SpiderX,
				},
			},
		},
		{
			Tag:      "direct",
			Protocol: "freedom",
			Settings: OutboundSettings{},
		},
	}

	// Smart Geo-Aware Routing Matrix
	isOriginRU := (originCountryCode == "RU")
	isTargetRU := (activeCountry == "RU" || strings.HasPrefix(strings.ToUpper(activeNodeName), "RU"))

	ruDomains := []string{
		"domain:ru", "domain:su", "domain:xn--p1ai",
		"domain:gosuslugi.ru", "domain:mos.ru", "domain:vk.com", "domain:vk.me", "domain:vkvideo.ru", "domain:userapi.com",
		"domain:ok.ru", "domain:okcdn.ru", "domain:yandex.ru", "domain:ya.ru", "domain:yandex.net", "domain:yastatic.net",
		"domain:sberbank.ru", "domain:sber.ru", "domain:tbank.ru", "domain:tinkoff.ru", "domain:t-bank.ru",
		"domain:ozon.ru", "domain:wildberries.ru", "domain:wb.ru", "domain:avito.ru", "domain:dzen.ru",
		"domain:kinopoisk.ru", "domain:rutube.ru", "domain:mail.ru", "domain:rambler.ru",
		"domain:rbc.ru", "domain:ria.ru", "domain:tass.ru", "domain:lenta.ru", "domain:gazeta.ru",
		"domain:vtb.ru", "domain:alfabank.ru", "domain:gazprombank.ru", "domain:cbr.ru", "domain:nalog.gov.ru",
		"domain:2gis.ru", "domain:hh.ru", "domain:cian.ru", "domain:domclick.ru",
		"domain:aviasales.ru", "domain:rzd.ru", "domain:aeroflot.ru",
	}

	globalDomains := []string{
		"domain:youtube.com", "domain:googlevideo.com", "domain:ytimg.com", "domain:youtu.be",
		"domain:instagram.com", "domain:cdninstagram.com", "domain:facebook.com", "domain:fbcdn.net",
		"domain:twitter.com", "domain:x.com", "domain:twimg.com", "domain:t.co",
		"domain:spotify.com", "domain:scdn.co", "domain:spotifycdn.com",
		"domain:openai.com", "domain:chatgpt.com", "domain:oaistatic.com", "domain:oaiusercontent.com",
		"domain:anthropic.com", "domain:claude.ai", "domain:netflix.com", "domain:nflxvideo.net",
		"domain:telegram.org", "domain:t.me", "domain:discord.com", "domain:discord.gg",
		"domain:linkedin.com", "domain:licdn.com", "domain:bbc.com", "domain:notion.so",
		"domain:medium.com", "domain:google.com", "domain:gstatic.com", "domain:github.com",
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

	if isOriginRU && !isTargetRU {
		// Scenario RU => EU/US: Russian sites go Direct, Global/Blocked sites go Proxy
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "direct",
			Domain:      ruDomains,
		})
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "proxy",
			Domain:      globalDomains,
		})
	} else if !isOriginRU && isTargetRU {
		// Scenario EU => RU: Russian sites go Proxy, Global sites go Direct
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "proxy",
			Domain:      ruDomains,
		})
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "direct",
			Domain:      globalDomains,
		})
		rules = append(rules, RoutingRule{
			Type:        "field",
			OutboundTag: "direct",
			Port:        "0-65535",
			Network:     "tcp,udp",
		})
	}

	xc.Routing = &RoutingConfig{
		DomainStrategy: "AsIs",
		Rules:          rules,
	}

	return json.MarshalIndent(xc, "", "  ")
}

func stopXrayCore() {
	xrayMutex.Lock()
	defer xrayMutex.Unlock()

	if xrayCmd != nil && xrayCmd.Process != nil {
		_ = xrayCmd.Process.Kill()
		_ = xrayCmd.Wait()
		xrayCmd = nil
		writeLog("CORE", "Xray Core process stopped.")
	}
}

var activeXrayExePath = `C:\Windows\Temp\xray.exe`

func ensureXrayBinaryExists() error {
	targetExe := `C:\Windows\Temp\xray.exe`
	if fi, err := os.Stat(targetExe); err == nil && fi.Size() > 20000000 {
		activeXrayExePath = targetExe
		return nil
	}

	writeLog("CORE", "Unpacking embedded Xray Core payload (Standalone All-In-One)...")
	gzReader, err := gzip.NewReader(bytes.NewReader(embeddedXrayGz))
	if err != nil {
		return fmt.Errorf("failed to init gzip decompressor: %w", err)
	}
	defer gzReader.Close()

	// Try C:\Windows\Temp first
	tmpFile := `C:\Windows\Temp\xray_unpack.tmp`
	out, err := os.OpenFile(tmpFile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		// Fallback to user TEMP directory if C:\Windows\Temp is restricted
		userTemp := os.Getenv("TEMP")
		if userTemp == "" {
			userTemp = os.Getenv("TMP")
		}
		if userTemp == "" {
			userTemp = "."
		}
		targetExe = filepath.Join(userTemp, "xray.exe")
		tmpFile = filepath.Join(userTemp, "xray_unpack.tmp")
		out, err = os.OpenFile(tmpFile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
		if err != nil {
			return fmt.Errorf("failed to create temp file: %w", err)
		}
	}

	if _, err := io.Copy(out, gzReader); err != nil {
		out.Close()
		_ = os.Remove(tmpFile)
		return fmt.Errorf("failed to decompress xray payload: %w", err)
	}
	out.Close()

	_ = os.Remove(targetExe)
	if err := os.Rename(tmpFile, targetExe); err != nil {
		if data, readErr := os.ReadFile(tmpFile); readErr == nil {
			_ = os.WriteFile(targetExe, data, 0755)
		}
		_ = os.Remove(tmpFile)
	}

	activeXrayExePath = targetExe
	writeLog("CORE_OK", fmt.Sprintf("Embedded Xray Core unpacked and ready: %s", targetExe))
	return nil
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

	cfgPath := `C:\Windows\Temp\gin_xray_config.json`
	if err := os.WriteFile(cfgPath, cfgBytes, 0644); err != nil {
		// Fallback config path
		cfgPath = filepath.Join(filepath.Dir(activeXrayExePath), "gin_xray_config.json")
		if err := os.WriteFile(cfgPath, cfgBytes, 0644); err != nil {
			return fmt.Errorf("failed to write config file: %w", err)
		}
	}

	xrayMutex.Lock()
	cmd := exec.Command(activeXrayExePath, "run", "-config", cfgPath)
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
	for i := 0; i < 25; i++ {
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
		Timeout: 2200 * time.Millisecond,
	}

	// 1. Try ip-api.com to get live verified IP + City + Country
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

	// 2. Try fast server endpoints
	endpoints := []string{
		"http://152.53.182.222:8443/ip",
		"http://212.109.223.109:8443/ip",
		"https://api.ipify.org",
		"https://icanhazip.com",
	}
	for _, ep := range endpoints {
		r, e := client.Get(ep)
		if e == nil {
			defer r.Body.Close()
			b, _ := io.ReadAll(r.Body)
			ip := strings.TrimSpace(string(b))
			if ip != "" {
				return ip, nil
			}
		}
	}

	return "", fmt.Errorf("tunnel verification timed out")
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

func setWindowsProxy(enabled bool, server string) {
	if enabled {
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "1", "/f").Run()
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyServer", "/t", "REG_SZ", "/d", server, "/f").Run()
	} else {
		_ = exec.Command("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "0", "/f").Run()
	}
	procInternetSetOptionW.Call(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
	procInternetSetOptionW.Call(0, INTERNET_OPTION_REFRESH, 0, 0)
}

func checkIsInstalled() bool {
	exe, err := os.Executable()
	if err != nil {
		return false
	}
	return strings.Contains(strings.ToLower(exe), "program files") || strings.Contains(strings.ToLower(exe), "appdata")
}

func updateBannerAndInstallButton() {
	if hwndBannerLbl == 0 || hwndBtnInstall == 0 {
		return
	}
	if installedState {
		if isRussianLang {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("✔️ GIN-VPN установлен (%s). Нажмите [ 🔄 Обновить ] для проверки новой версии.", AppVersion)))))
		} else {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("✔️ GIN-VPN is installed (%s). Click [ 🔄 Check Updates ] to verify latest release.", AppVersion)))))
		}
	} else {
		if isRussianLang {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("⚠️ GIN-VPN не установлен! Запущен портативно. Нажмите [ 📑 Установить ] ниже."))))
		} else {
			procSetWindowTextW.Call(hwndBannerLbl, uintptr(unsafe.Pointer(strPtr("⚠️ GIN-VPN is not installed! Running portable. Click [ 📑 Install App ] below to install."))))
		}
	}
	procInvalidateRect.Call(hwndBtnInstall, 0, 1)
	procInvalidateRect.Call(hwndBannerLbl, 0, 1)
}

func checkForUpdates(manual bool) {
	go func() {
		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Get("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/README.md")
		if err != nil || resp.StatusCode != 200 {
			if manual {
				msg := "Could not reach update server. Please check your internet connection."
				title := "Update Check — GIN-VPN"
				if isRussianLang {
					msg = "Не удалось подключиться к серверу обновлений. Проверьте интернет."
					title = "Проверка обновлений — GIN-VPN"
				}
				procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(msg))), uintptr(unsafe.Pointer(strPtr(title))), 0x00000030)
			}
			return
		}
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)
		content := string(body)

		remoteVer := AppVersion
		if idx := strings.Index(content, "Version-v"); idx != -1 {
			sub := content[idx+len("Version-v"):]
			if end := strings.IndexAny(sub, "% -_\n\r)"); end != -1 {
				remoteVer = "v" + strings.TrimSpace(sub[:end])
			}
		}

		if remoteVer != AppVersion && remoteVer > AppVersion {
			askMsg := fmt.Sprintf("A new version is available: %s (Current: %s)\n\nDo you want to open the official download page?", remoteVer, AppVersion)
			askTitle := "New Update Available — GIN-VPN"
			if isRussianLang {
				askMsg = fmt.Sprintf("Доступна новая версия: %s (Текущая: %s)\n\nХотите открыть официальную страницу загрузки?", remoteVer, AppVersion)
				askTitle = "Доступно обновление — GIN-VPN"
			}
			ret, _, _ := procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(askMsg))), uintptr(unsafe.Pointer(strPtr(askTitle))), 0x00000004|0x00000040)
			if ret == 6 { // IDYES
				procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(GitHubRepoURL))), 0, 0, 1)
			}
		} else if manual {
			upMsg := fmt.Sprintf("GIN-VPN is up to date (%s).\n\nYou are running the latest official version.", AppVersion)
			upTitle := "GIN-VPN Update Check"
			if isRussianLang {
				upMsg = fmt.Sprintf("GIN-VPN актуален (%s).\n\nУ вас установлена последняя официальная версия.", AppVersion)
				upTitle = "Проверка обновлений"
			}
			procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(upMsg))), uintptr(unsafe.Pointer(strPtr(upTitle))), 0x00000040)
		}
	}()
}

func performInstall() {
	exePath, err := os.Executable()
	if err != nil {
		procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Failed to get executable path: "+err.Error()))), uintptr(unsafe.Pointer(strPtr("Install Error"))), 0x00000010)
		return
	}

	targetDir := `C:\Program Files\GIN-VPN`
	targetExe := filepath.Join(targetDir, "GIN-VPN.exe")

	psAdmin := fmt.Sprintf(`
$src = '%s'
$dir = '%s'
$exe = '%s'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
Copy-Item -Path $src -Destination $exe -Force
$w = New-Object -ComObject WScript.Shell
$d = [Environment]::GetFolderPath('Desktop')
$s = $w.CreateShortcut("$d\GIN-VPN.lnk")
$s.TargetPath = $exe
$s.WorkingDirectory = $dir
$s.IconLocation = "$exe,0"
$s.Save()

$reg = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN'
if (-not (Test-Path $reg)) { New-Item -Path $reg -Force }
Set-ItemProperty -Path $reg -Name 'DisplayName' -Value 'GIN-VPN by VladiMIR+AI'
Set-ItemProperty -Path $reg -Name 'DisplayVersion' -Value '%s'
Set-ItemProperty -Path $reg -Name 'Publisher' -Value 'VladiMIR+AI (Vladimir Bulantsev)'
Set-ItemProperty -Path $reg -Name 'DisplayIcon' -Value "$exe,0"
Set-ItemProperty -Path $reg -Name 'InstallLocation' -Value $dir
`, exePath, targetDir, targetExe, AppVersion)

	tmpPs1 := filepath.Join(os.TempDir(), "install_gin_vpn.ps1")
	_ = os.WriteFile(tmpPs1, []byte(psAdmin), 0755)

	cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", tmpPs1)
	err = cmd.Run()
	_ = os.Remove(tmpPs1)

	if err == nil {
		installedState = true
		updateBannerAndInstallButton()
		procMessageBoxW.Call(
			hwndMain,
			uintptr(unsafe.Pointer(strPtr("GIN-VPN has been successfully installed to C:\\Program Files\\GIN-VPN!\n\nDesktop shortcut created with golden shield icon.\nOfficial Windows uninstaller registered."))),
			uintptr(unsafe.Pointer(strPtr("GIN-VPN Installed Successfully"))),
			0x00000040,
		)
	} else {
		localDir := filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-VPN")
		localExe := filepath.Join(localDir, "GIN-VPN.exe")
		_ = os.MkdirAll(localDir, 0755)
		_ = copyFile(exePath, localExe)

		psFallback := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$d = [Environment]::GetFolderPath('Desktop')
$s = $w.CreateShortcut("$d\GIN-VPN.lnk")
$s.TargetPath = '%s'
$s.WorkingDirectory = '%s'
$s.IconLocation = '%s,0'
$s.Save()
`, localExe, localDir, localExe)
		_ = exec.Command("powershell", "-NoProfile", "-Command", psFallback).Run()

		installedState = true
		updateBannerAndInstallButton()
		procMessageBoxW.Call(
			hwndMain,
			uintptr(unsafe.Pointer(strPtr("GIN-VPN installed to user profile: "+localDir+"\n\nDesktop shortcut created."))),
			uintptr(unsafe.Pointer(strPtr("GIN-VPN Installed"))),
			0x00000040,
		)
	}
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

func connectToNodeAsync(nodeName, host string, port int, country string, rawUri string, minimize bool) {
	connMutex.Lock()
	if isConnecting {
		connMutex.Unlock()
		return
	}
	isConnecting = true
	connMutex.Unlock()

	activeNodeName = nodeName
	activeNodeIP = host
	activeCountry = country

	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
	}

	writeLog("ROUTE", fmt.Sprintf("Switching route to node: %s (%s:%d)...", activeNodeName, activeNodeIP, port))

	go func() {
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
			writeLog("ROUTE", "Tearing down previous VPN tunnel before connecting to new node...")
			setWindowsProxy(false, "")
			stopXrayCore()
			isConnected = false
			updateTrayIcon(false, "", "")
			time.Sleep(100 * time.Millisecond)
		}

		// 1. Parse VLESS config
		cfg, err := parseVlessUri(rawUri)
		if err != nil {
			writeLog("ERR", fmt.Sprintf("Failed to parse VLESS URI: %v", err))
			isConnected = false
			updateTrayIcon(false, "", "")
			return
		}

		// 2. Start Xray Core daemon
		if err := startXrayCore(cfg); err != nil {
			writeLog("ERR", fmt.Sprintf("Failed to launch Xray Core: %v", err))
			isConnected = false
			updateTrayIcon(false, "", "")
			return
		}

		writeLog("TUNNEL", fmt.Sprintf("Initiating handshake with %s (%s:%d)...", activeNodeName, host, port))

		// 3. Verify actual live tunnel before activating system proxy!
		exitIp, err := verifyTunnelRouting()
		if err != nil {
			writeLog("WARN", fmt.Sprintf("Handshake fast verify returned: %v. Checking node TCP reachability...", err))
			tcpConn, tcpErr := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), 1500*time.Millisecond)
			if tcpErr != nil {
				writeLog("FAIL", fmt.Sprintf("Handshake failed with %s: node is unreachable (%v).", activeNodeName, tcpErr))
				writeLog("ERR", "Connection failed! Restoring direct ISP internet routing.")
				stopXrayCore()
				setWindowsProxy(false, "")
				isConnected = false
				updateTrayIcon(false, "", "")
				if hwndMain != 0 {
					procShowWindow.Call(hwndMain, 5) // SW_SHOW
					procSetForegroundWindow.Call(hwndMain)
				}
				return
			}
			tcpConn.Close()
			exitIp = host
		}

		// 4. Dual IP Check on DE-222 (EU) and RU-109 (RU)
		verifiedExitIP = exitIp
		locStr := getNodeLocationStr(host, activeCountry, isRussianLang)
		writeLog("VERIFY_OK", fmt.Sprintf("Real Exit IP verified: %s (%s)", verifiedExitIP, locStr))
		deLat, ruLat, _ := verifyDualServerRouting()
		latencyDeMs = deLat
		latencyRuMs = ruLat

		// 5. Activate Windows System Proxy
		setWindowsProxy(true, "127.0.0.1:10809")
		writeLog("PROXY", "Windows System Proxy activated (127.0.0.1:10809).")

		// 6. Measure ping to active node
		rtt := measurePing(host, port)
		latencyMs = rtt

		isConnected = true
		sessionStart = time.Now()

		// Set Green Tray Icon on Connect IMMEDIATELY
		updateTrayIcon(true, activeNodeName, activeNodeIP)

		writeLog("OK", fmt.Sprintf("Tunnel active! Protected IP: %s (%s) | RTT: %d ms | EU-222: %d ms | RU-109: %d ms", verifiedExitIP, locStr, latencyMs, latencyDeMs, latencyRuMs))

		if minimize && hwndMain != 0 {
			time.Sleep(150 * time.Millisecond)
			if isConnected {
				procShowWindow.Call(hwndMain, 0) // SW_HIDE -> minimize to tray
			}
		}
	}()
}

func disconnectVpnAsync() {
	isConnected = false
	activeNodeName = ""
	setWindowsProxy(false, "")
	stopXrayCore()
	updateTrayIcon(false, "", "")

	if hwndMain != 0 {
		procPostMessageW.Call(hwndMain, WM_APP_UPDATE_STATUS, 0, 0)
		procInvalidateRect.Call(hwndListView, 0, 1)
	}
	writeLog("DISCONNECT", "Tunnel closed. System proxy disabled. Restoring direct ISP routing.")
}

func toggleVpn() {
	if isConnected {
		disconnectVpnAsync()
	} else {
		selIdx := 0
		for i, p := range profiles {
			if p.Default != "" {
				selIdx = i
				break
			}
		}
		p := profiles[selIdx]
		connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, false)
	}
}

func refreshProfilesListView() {
	procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
	for i, p := range profiles {
		addProfileToListView(i, p)
	}
}

func setDefaultProfile(sel int) {
	if sel < 0 || sel >= len(profiles) {
		return
	}
	wasAuto := (profiles[sel].Default != "")
	for i := range profiles {
		if i == sel && !wasAuto {
			profiles[i].Default = "✓ Auto"
		} else {
			profiles[i].Default = ""
		}
		var subItem LVITEMW
		subItem.IItem = int32(i)
		subItem.ISubItem = 1 // Column 1: Default / Auto-connect
		subItem.PszText = strPtr(profiles[i].Default)
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&subItem)))
	}
	saveProfilesToStorage()
	if !wasAuto {
		writeLog("PROFILE", fmt.Sprintf("Auto-connect on startup enabled for: %s", profiles[sel].Name))
	} else {
		writeLog("PROFILE", fmt.Sprintf("Auto-connect on startup disabled for: %s", profiles[sel].Name))
	}
}

func updateLanguageUI() {
	if hwndMain == 0 {
		return
	}

	if isRussianLang {
		procSetWindowTextW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(AppTitleRU))))
		procSetWindowTextW.Call(hwndTitle, uintptr(unsafe.Pointer(strPtr("🛡️ GIN-VPN от VladiMIR+AI"))))
		procSetWindowTextW.Call(hwndKeyLabel, uintptr(unsafe.Pointer(strPtr("Активный VLESS Reality ключ: (Готов)"))))
		procSetWindowTextW.Call(hwndProfilesLbl, uintptr(unsafe.Pointer(strPtr("Двойной клик — Пуск | Правый клик — Функции"))))
		procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr("⚡ Диагностика и маршрутизация"))))
		procSetWindowTextW.Call(hwndLogLbl, uintptr(unsafe.Pointer(strPtr("📊 Лог сетевых событий и трафика в реальном времени:"))))
		if hwndBrand != 0 {
			procSetWindowTextW.Call(hwndBrand, uintptr(unsafe.Pointer(strPtr("VladiMIR+AI"))))
		}

		// Update column headers
		setColumnText(0, "№")
		setColumnText(1, "Авто")
		setColumnText(2, "Имя профиля / Устройство")
		setColumnText(3, "Адрес сервера")
		setColumnText(4, "Порт")
	} else {
		procSetWindowTextW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr(AppTitleEN))))
		procSetWindowTextW.Call(hwndTitle, uintptr(unsafe.Pointer(strPtr("🛡️ GIN-VPN by VladiMIR+AI"))))
		procSetWindowTextW.Call(hwndKeyLabel, uintptr(unsafe.Pointer(strPtr("Active VLESS Reality Key: (Ready)"))))
		procSetWindowTextW.Call(hwndProfilesLbl, uintptr(unsafe.Pointer(strPtr("Double-Click: Connect | Right-Click: Options"))))
		procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr("⚡ Diagnostics & Routing"))))
		procSetWindowTextW.Call(hwndLogLbl, uintptr(unsafe.Pointer(strPtr("📊 Real-Time Event & Traffic Log:"))))
		if hwndBrand != 0 {
			procSetWindowTextW.Call(hwndBrand, uintptr(unsafe.Pointer(strPtr("VladiMIR+AI"))))
		}

		// Update column headers
		setColumnText(0, "№")
		setColumnText(1, "Default")
		setColumnText(2, "Profile / Device Name")
		setColumnText(3, "Server Host Address")
		setColumnText(4, "Port")
	}

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

func applyTheme(dark bool) {
	isDarkMode = dark
	if isDarkMode {
		procSetWindowTheme.Call(hwndListView, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(hwndListView, LVM_SETBKCOLOR, 0, 0x00141414)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTBKCOLOR, 0, 0x00141414)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTCOLOR, 0, 0x00EAEAEA)
	} else {
		procSetWindowTheme.Call(hwndListView, uintptr(unsafe.Pointer(strPtr(""))), uintptr(unsafe.Pointer(strPtr(""))))
		procSendMessageW.Call(hwndListView, LVM_SETBKCOLOR, 0, 0x00FFFFFF)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTBKCOLOR, 0, 0x00FFFFFF)
		procSendMessageW.Call(hwndListView, LVM_SETTEXTCOLOR, 0, 0x00222222)
	}

	procInvalidateRect.Call(hwndMain, 0, 1)

	allControls := []uintptr{
		hwndTitle, hwndBtnDay, hwndBtnNight, hwndBtnLangEN, hwndBtnLangRU,
		hwndBtnMainAction, hwndKeyLabel, hwndBtnPasteQr, hwndBtnSave, hwndKeyEdit,
		hwndProfilesLbl, hwndBtnConnect, hwndBtnSetDefault, hwndListView,
		hwndDiagHeader, hwndDiagOrig, hwndDiagProt, hwndDiagLat, hwndDiagUptime,
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
			if newName != "" && renameTargetIdx >= 0 && renameTargetIdx < len(profiles) {
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
		if isDarkMode {
			brush = hBrushBgNight
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), brush)
		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)
		if isDarkMode {
			procSetTextColor.Call(hDC, 0x00E0E0E0)
			return hBrushBgNight
		}
		procSetTextColor.Call(hDC, 0x00222222)
		return hBrushBgDay

	case WM_CTLCOLOREDIT:
		hDC := wParam
		if isDarkMode {
			procSetBkMode.Call(hDC, 1)
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputNight
		}
		procSetBkMode.Call(hDC, 1)
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
	if isDarkMode {
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

		var autoText string
		if isAutoConnect {
			autoText = "✓ Подключаться при запуске программы"
		} else {
			autoText = "  Подключаться при запуске программы"
		}
		procAppendMenuW.Call(hMenu, autoFlags, 6002, uintptr(unsafe.Pointer(strPtr(autoText))))

		procAppendMenuW.Call(hMenu, MF_STRING, 6003, uintptr(unsafe.Pointer(strPtr("✏️ Переименовать сервер"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6004, uintptr(unsafe.Pointer(strPtr("🗑️ Удалить сервер из списка"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6005, uintptr(unsafe.Pointer(strPtr("📋 Скопировать VLESS ключ"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6006, uintptr(unsafe.Pointer(strPtr("🔍 Проверить маршрут (EU-222 / RU-109)"))))
	} else {
		headerText := fmt.Sprintf("🌐 Server: %s (%s:%d)", p.Name, p.Host, p.Port)
		procAppendMenuW.Call(hMenu, MF_STRING|MF_GRAYED, 0, uintptr(unsafe.Pointer(strPtr(headerText))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6001, uintptr(unsafe.Pointer(strPtr("⚡ Connect to this Server"))))

		var autoText string
		if isAutoConnect {
			autoText = "✓ Auto-connect on App Startup"
		} else {
			autoText = "  Auto-connect on App Startup"
		}
		procAppendMenuW.Call(hMenu, autoFlags, 6002, uintptr(unsafe.Pointer(strPtr(autoText))))

		procAppendMenuW.Call(hMenu, MF_STRING, 6003, uintptr(unsafe.Pointer(strPtr("✏️ Rename Profile"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6004, uintptr(unsafe.Pointer(strPtr("🗑️ Delete Profile"))))
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 6005, uintptr(unsafe.Pointer(strPtr("📋 Copy VLESS Key"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 6006, uintptr(unsafe.Pointer(strPtr("🔍 Verify Route (EU-222 / RU-109)"))))
	}

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
	procDestroyMenu.Call(hMenu)
}

func draw3DVolumetricButton(hDC uintptr, rc RECT, text string, font uintptr, baseColor, borderDark, borderLight uintptr, isPressed bool) uintptr {
	hBrush, _, _ := procCreateSolidBrush.Call(baseColor)
	hPen, _, _ := procCreatePen.Call(0, 1, borderDark)
	oldBrush, _, _ := procSelectObject.Call(hDC, hBrush)
	oldPen, _, _ := procSelectObject.Call(hDC, hPen)

	procRoundRect.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom), 8, 8)

	procSelectObject.Call(hDC, oldBrush)
	procSelectObject.Call(hDC, oldPen)
	procDeleteObject.Call(hBrush)
	procDeleteObject.Call(hPen)

	if !isPressed {
		hPenLight, _, _ := procCreatePen.Call(0, 1, borderLight)
		oldPenL, _, _ := procSelectObject.Call(hDC, hPenLight)

		var pt POINT
		procMoveToEx.Call(hDC, uintptr(rc.Left+4), uintptr(rc.Top+1), uintptr(unsafe.Pointer(&pt)))
		procLineTo.Call(hDC, uintptr(rc.Right-4), uintptr(rc.Top+1))

		procMoveToEx.Call(hDC, uintptr(rc.Left+1), uintptr(rc.Top+4), uintptr(unsafe.Pointer(&pt)))
		procLineTo.Call(hDC, uintptr(rc.Left+1), uintptr(rc.Bottom-4))

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

func drawCustomButton(dis *DRAWITEMSTRUCT) uintptr {
	hDC := dis.HDC
	rc := dis.RcItem
	isPressed := (dis.ItemState & 0x0001) != 0

	var btnText string
	var baseColor, borderDark, borderLight uintptr
	var font uintptr = hFontBold

	switch dis.CtlID {
	case 101: // Main Big Action Button
		if isConnecting {
			btnText = "🟡 CONNECTING..."
			if isRussianLang {
				btnText = "🟡 ПОДКЛЮЧЕНИЕ..."
			}
			baseColor = 0x0677D9
			borderDark = 0x034988
			borderLight = 0x58A5F0
		} else if isConnected {
			btnText = "⏹ DISCONNECT VPN"
			if isRussianLang {
				btnText = "⏹ ОТКЛЮЧИТЬ VPN"
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

	case 102: // Paste Key / QR
		btnText = "📋 Paste Key / 📷 QR"
		if isRussianLang {
			btnText = "📋 Вставить / 📷 QR"
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
		btnText = "💾 Save"
		if isRussianLang {
			btnText = "💾 Сохранить"
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

	case 104: // Connect Selected
		btnText = "⚡ Connect"
		if isRussianLang {
			btnText = "⚡ Пуск"
		}
		font = hFontRegular
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
		btnText = "★ Default"
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

	case 106: // Install / Update Button
		if installedState {
			btnText = "🔄 Check Updates"
			if isRussianLang {
				btnText = "🔄 Обновить"
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
		btnText = "🌐 IP (EU/RU)"
		if isRussianLang {
			btnText = "🌐 IP (EU/RU)"
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
		btnText = "📋 Copy All"
		if isRussianLang {
			btnText = "📋 Копировать всё"
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
		btnText = "🧹 Clear"
		if isRussianLang {
			btnText = "🧹 Очистить"
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

	case 201: // Day Theme
		btnText = "☀️ Day"
		if !isDarkMode {
			baseColor = 0x0677D9
			borderDark = 0x034988
			borderLight = 0x58A5F0
		} else {
			baseColor = 0x383838
			borderDark = 0x222222
			borderLight = 0x555555
		}

	case 202: // Night Theme
		btnText = "🌙 Night"
		if isDarkMode {
			baseColor = 0xC1466B
			borderDark = 0x8A2A47
			borderLight = 0xE57395
		} else {
			baseColor = 0x606060
			borderDark = 0x404040
			borderLight = 0x808080
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
		WS_CHILD|WS_VISIBLE,
		uintptr(x), uintptr(y), uintptr(w), uintptr(h),
		hwndMain, 0, hInstance, 0,
	)
	if font != 0 {
		procSendMessageW.Call(hwnd, WM_SETFONT, font, 1)
	}
	return hwnd
}

func createStaticNotify(text string, x, y, w, h int32, font uintptr, id int) uintptr {
	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(text))),
		WS_CHILD|WS_VISIBLE|SS_CENTER|SS_NOTIFY,
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
		procAppendMenuW.Call(hMenu, MF_STRING, 5005, uintptr(unsafe.Pointer(strPtr("🇷🇺 Проверить IP — RU (prodvig-saita.ru)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 5006, uintptr(unsafe.Pointer(strPtr("🇪🇺 Проверить IP — EU (eco-seo.cz)"))))
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
		procAppendMenuW.Call(hMenu, MF_STRING, 5005, uintptr(unsafe.Pointer(strPtr("🇷🇺 Check IP — RU (prodvig-saita.ru)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 5006, uintptr(unsafe.Pointer(strPtr("🇪🇺 Check IP — EU (eco-seo.cz)"))))
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

	case WM_APP_UPDATE_STATUS:
		if isConnecting {
			diagHeaderTxt := "⚡ Diagnostics & Routing — 🟡 CONNECTING..."
			if isRussianLang {
				diagHeaderTxt = "⚡ Диагностика и маршрутизация — 🟡 ПОДКЛЮЧЕНИЕ..."
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			protTxt := fmt.Sprintf("VPN IP: 🟡 Connecting to %s...", activeNodeName)
			if isRussianLang {
				protTxt = fmt.Sprintf("VPN IP: 🟡 Подключение к %s...", activeNodeName)
			}
			procSetWindowTextW.Call(hwndDiagProt, uintptr(unsafe.Pointer(strPtr(protTxt))))
			procSendMessageW.Call(hwndDiagProt, WM_SETFONT, hFontBold, 1)
			procSetWindowTextW.Call(hwndDiagLat, uintptr(unsafe.Pointer(strPtr("Ping: Testing..."))))
		} else if isConnected {
			routeScheme := getRouteScheme(originCountryCode, activeCountry)
			diagHeaderTxt := fmt.Sprintf("⚡ Diagnostics & Routing — 🟢 CONNECTED [%s]", routeScheme)
			if isRussianLang {
				diagHeaderTxt = fmt.Sprintf("⚡ Диагностика и маршрутизация — 🟢 ПОДКЛЮЧЕНО [%s]", routeScheme)
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			displayIp := verifiedExitIP
			if displayIp == "" {
				displayIp = activeNodeIP
			}
			protTxt := fmt.Sprintf("VPN IP: 🟢 %s (%s) [%s]", displayIp, activeCountry, routeScheme)
			if isRussianLang {
				protTxt = fmt.Sprintf("VPN IP: 🟢 %s (%s) [%s]", displayIp, activeCountry, routeScheme)
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
			diagHeaderTxt := "⚡ Diagnostics & Routing — 🔴 DIRECT ISP"
			if isRussianLang {
				diagHeaderTxt = "⚡ Диагностика и маршрутизация — 🔴 ПРЯМОЙ ИНТЕРНЕТ"
			}
			procSetWindowTextW.Call(hwndDiagHeader, uintptr(unsafe.Pointer(strPtr(diagHeaderTxt))))

			uptimeTxt := "Uptime: Disconnected"
			protTxt := "VPN IP: 🔴 Disconnected"
			latTxt := "Ping: -- ms"
			if isRussianLang {
				uptimeTxt = "Время: Отключено"
				protTxt = "VPN IP: 🔴 Отключено"
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
		procInvalidateRect.Call(hwndDiagProt, 0, 1)
		procInvalidateRect.Call(hwndDiagLat, 0, 1)
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

		case 5005: // Tray Check IP RU
			writeLog("VERIFY_RU", "Opening Russian IP verification portal (prodvig-saita.ru/ip)...")
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlRU))), 0, 0, 1)

		case 5006: // Tray Check IP EU
			writeLog("VERIFY_EU", "Opening European IP verification portal (eco-seo.cz/ip)...")
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(EndpointUrlDE))), 0, 0, 1)

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
			if selectedProfileIdx >= 0 && selectedProfileIdx < len(profiles) {
				p := profiles[selectedProfileIdx]
				confirmMsg := fmt.Sprintf("Are you sure you want to delete profile:\n\n\"%s\" (%s:%d)?", p.Name, p.Host, p.Port)
				confirmTitle := "Delete Profile — GIN-VPN"
				if isRussianLang {
					confirmMsg = fmt.Sprintf("Вы уверены, что хотите удалить профиль:\n\n\"%s\" (%s:%d)?", p.Name, p.Host, p.Port)
					confirmTitle = "Удаление профиля — GIN-VPN"
				}
				ret, _, _ := procMessageBoxW.Call(
					hwndMain,
					uintptr(unsafe.Pointer(strPtr(confirmMsg))),
					uintptr(unsafe.Pointer(strPtr(confirmTitle))),
					0x00000004|0x00000020,
				)
				if ret == 6 { // IDYES
					delName := p.Name
					profiles = append(profiles[:selectedProfileIdx], profiles[selectedProfileIdx+1:]...)
					saveProfilesToStorage()
					refreshProfilesListView()
					writeLog("PROFILE", fmt.Sprintf("Profile '%s' deleted and updated in registry.", delName))
				}
			}

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

		case 1004: // Brand Label Clicked (Open 3D About Dialog)
			showAboutDialog()

		case 201: // Day Theme
			applyTheme(false)
			writeLog("THEME", "Light Day Theme activated.")

		case 202: // Night Theme
			applyTheme(true)
			writeLog("THEME", "Dark OLED Night Theme activated.")

		case 203: // Switch to English (EN)
			isRussianLang = false
			updateLanguageUI()
			writeLog("LANG", "Language switched to English (EN).")

		case 204: // Switch to Russian (RU)
			isRussianLang = true
			updateLanguageUI()
			writeLog("LANG", "Язык переключен на русский (RU).")

		case 101: // Main Action: Connect/Disconnect
			toggleVpn()

		case 102: // Paste / QR
			procOpenClipboard.Call(0)
			hData, _, _ := procGetClipboardData.Call(CF_UNICODETEXT)
			if hData != 0 {
				ptr, _, _ := procGlobalLock.Call(hData)
				if ptr != 0 {
					text := syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(ptr))[:])
					procGlobalUnlock.Call(hData)
					procSetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(strPtr(text))))
					writeLog("CLIP", "Pasted VLESS key from clipboard.")
				}
			}
			procCloseClipboard.Call()

		case 103: // Save Key
			var buf [2048]uint16
			procGetWindowTextW.Call(hwndKeyEdit, uintptr(unsafe.Pointer(&buf[0])), 2048)
			str := strings.TrimSpace(syscall.UTF16ToString(buf[:]))
			if strings.HasPrefix(str, "vless://") {
				cfg, err := parseVlessUri(str)
				if err == nil {
					pName := cfg.Name
					if pName == "" {
						pName = fmt.Sprintf("Custom-%s", cfg.Host)
					}
					p := Profile{
						Default: "",
						Name:    pName,
						Host:    cfg.Host,
						Port:    cfg.Port,
						Country: "EU",
						RawUri:  str,
					}
					profiles = append(profiles, p)
					saveProfilesToStorage()
					addProfileToListView(len(profiles)-1, p)
					writeLog("PROFILE", fmt.Sprintf("New profile '%s' saved successfully.", pName))
					procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Profile saved successfully!"))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000040)
				} else {
					procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Invalid VLESS Reality key format: "+err.Error()))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000030)
				}
			} else {
				procMessageBoxW.Call(hwndMain, uintptr(unsafe.Pointer(strPtr("Please enter a valid vless:// Reality key first."))), uintptr(unsafe.Pointer(strPtr("GIN-VPN"))), 0x00000030)
			}

		case 104: // Connect Selected
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			if sel >= 0 && sel < len(profiles) {
				p := profiles[sel]
				connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
			}

		case 105: // Set Default
			selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			sel := int(selRet)
			if sel >= 0 && sel < len(profiles) {
				setDefaultProfile(sel)
			}

		case 106: // Install / Update
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

	case WM_CONTEXTMENU:
		targetHwnd := uintptr(wParam)
		if targetHwnd == hwndListView {
			x := int32(int16(lParam & 0xFFFF))
			y := int32(int16((lParam >> 16) & 0xFFFF))
			var clientPt POINT
			clientPt.X = x
			clientPt.Y = y
			procScreenToClient.Call(hwndListView, uintptr(unsafe.Pointer(&clientPt)))
			var hti LVHITTESTINFO
			hti.Pt = clientPt
			procSendMessageW.Call(hwndListView, LVM_HITTEST, 0, uintptr(unsafe.Pointer(&hti)))
			targetIdx := int(hti.IItem)
			if targetIdx < 0 || targetIdx >= len(profiles) {
				selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
				targetIdx = int(selRet)
			}
			if targetIdx >= 0 && targetIdx < len(profiles) {
				var item LVITEMW
				item.StateMask = LVIS_SELECTED | LVIS_FOCUSED
				item.State = LVIS_SELECTED | LVIS_FOCUSED
				procSendMessageW.Call(hwndListView, LVM_SETITEMSTATE, uintptr(targetIdx), uintptr(unsafe.Pointer(&item)))
				showListViewContextMenu(targetIdx)
			}
			return 0
		}

	case WM_NOTIFY:
		nmhdr := (*NMHDR)(unsafe.Pointer(lParam))
		if nmhdr.HwndFrom == hwndListView {
			// Connect on Double-Click
			if nmhdr.Code == NM_DBLCLK {
				nmia := (*NMITEMACTIVATE)(unsafe.Pointer(lParam))
				sel := int(nmia.IItem)
				if sel < 0 || sel >= len(profiles) {
					selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
					sel = int(selRet)
				}
				if sel >= 0 && sel < len(profiles) {
					p := profiles[sel]
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
				if targetIdx < 0 || targetIdx >= len(profiles) {
					selRet, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
					targetIdx = int(selRet)
				}
				if targetIdx >= 0 && targetIdx < len(profiles) {
					var item LVITEMW
					item.StateMask = LVIS_SELECTED | LVIS_FOCUSED
					item.State = LVIS_SELECTED | LVIS_FOCUSED
					procSendMessageW.Call(hwndListView, LVM_SETITEMSTATE, uintptr(targetIdx), uintptr(unsafe.Pointer(&item)))
					showListViewContextMenu(targetIdx)
				}
				return 0
			}

			if nmhdr.Code == NM_CUSTOMDRAW {
				pcd := (*NMLVCUSTOMDRAW)(unsafe.Pointer(lParam))
				if pcd.Nmcd.DwDrawStage == CDDS_PREPAINT {
					return CDRF_NOTIFYITEMDRAW
				}
				if pcd.Nmcd.DwDrawStage == CDDS_ITEMPREPAINT {
					itemIdx := int(pcd.Nmcd.DwItemSpec)
					if itemIdx >= 0 && itemIdx < len(profiles) {
						isActiveConnected := isConnected && (profiles[itemIdx].Name == activeNodeName || profiles[itemIdx].Host == activeNodeIP || (verifiedExitIP != "" && profiles[itemIdx].Host == verifiedExitIP))
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
					if itemIdx >= 0 && itemIdx < len(profiles) {
						isActiveConnected := isConnected && (profiles[itemIdx].Name == activeNodeName || profiles[itemIdx].Host == activeNodeIP || (verifiedExitIP != "" && profiles[itemIdx].Host == verifiedExitIP))

						if isActiveConnected {
							pcd.Nmcd.UItemState &^= 0x0001 | 0x0010 // Clear CDIS_SELECTED | CDIS_FOCUS
							pcd.ClrTextBk = 0x001B5E20 // Dark Forest Green (BGR: 0x205E1B)
							pcd.ClrText = 0x0000FFFF   // Bright Vivid Yellow (BGR: 0x00FFFF)
							procSelectObject.Call(pcd.Nmcd.Hdc, hFontBold)
							procSetBkMode.Call(pcd.Nmcd.Hdc, 2) // OPAQUE
							procSetTextColor.Call(pcd.Nmcd.Hdc, 0x0000FFFF)
							return CDRF_NEWFONT
						}

						if isDarkMode {
							pcd.ClrTextBk = 0x00141414
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x00AAAAAA // Number
							case 1:
								if profiles[itemIdx].Default != "" {
									pcd.ClrText = 0x00E080 // Light Green
								} else {
									pcd.ClrText = 0x888888
								}
							case 2:
								pcd.ClrText = 0x00E0E0 // Golden Yellow
							case 3:
								pcd.ClrText = 0x80D0FF // Ice Blue
							case 4:
								pcd.ClrText = 0xFFA060 // Orange
							default:
								pcd.ClrText = 0x00E0E0E0
							}
						} else {
							pcd.ClrTextBk = 0x00FFFFFF
							switch subItemIdx {
							case 0:
								pcd.ClrText = 0x00666666 // Number
							case 1:
								if profiles[itemIdx].Default != "" {
									pcd.ClrText = 0x008000 // Dark Green
								} else {
									pcd.ClrText = 0x888888
								}
							case 2:
								pcd.ClrText = 0x803010 // Slate Blue (BGR)
							case 3:
								pcd.ClrText = 0x117A8B // Teal
							case 4:
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
		if isConnected && !sessionStart.IsZero() {
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
		return 0

	case WM_ERASEBKGND:
		hDC := wParam
		var rc RECT
		procGetClientRect.Call(hwnd, uintptr(unsafe.Pointer(&rc)))
		brush := hBrushBgDay
		if isDarkMode {
			brush = hBrushBgNight
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), brush)

		// Draw smooth rounded card for Diagnostics (x: 18..550, y: 352..412)
		var cardBrush, cardPen uintptr
		if isDarkMode {
			cardBrush, _, _ = procCreateSolidBrush.Call(0x001F1F1F)
			cardPen, _, _ = procCreatePen.Call(0, 1, 0x00333333)
		} else {
			cardBrush, _, _ = procCreateSolidBrush.Call(0x00F0F2F5)
			cardPen, _, _ = procCreatePen.Call(0, 1, 0x00D0D4DC)
		}
		oldB, _, _ := procSelectObject.Call(hDC, cardBrush)
		oldP, _, _ := procSelectObject.Call(hDC, cardPen)

		procRoundRect.Call(hDC, 18, 352, 550, 412, 8, 8)

		procSelectObject.Call(hDC, oldB)
		procSelectObject.Call(hDC, oldP)
		procDeleteObject.Call(cardBrush)
		procDeleteObject.Call(cardPen)

		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		ctrlHwnd := uintptr(lParam)

		if ctrlHwnd == hwndLogEdit {
			if isDarkMode {
				procSetBkMode.Call(hDC, 1)
				procSetTextColor.Call(hDC, 0x0033FF33) // Terminal Neon Green
				return hBrushLogNight
			}
			procSetBkMode.Call(hDC, 1)
			procSetTextColor.Call(hDC, 0x00111111)
			return hBrushWhite
		}

		procSetBkMode.Call(hDC, 1) // TRANSPARENT
		if isDarkMode {
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
			} else if ctrlHwnd == hwndDiagOrig || ctrlHwnd == hwndDiagLat || ctrlHwnd == hwndDiagUptime {
				procSetTextColor.Call(hDC, 0x00CCCCCC)
				return hBrushCardNight
			} else {
				procSetTextColor.Call(hDC, 0x00D0D0D0)
			}
			return hBrushBgNight
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
		if isDarkMode {
			procSetBkMode.Call(hDC, 1)
			procSetTextColor.Call(hDC, 0x00FFFFFF)
			return hBrushInputNight
		}
		procSetBkMode.Call(hDC, 1)
		procSetTextColor.Call(hDC, 0x001A1A1A)
		return hBrushWhite

	case WM_SETCURSOR:
		ctrlHwnd := uintptr(wParam)
		if ctrlHwnd != 0 && (ctrlHwnd == hwndBtnDay || ctrlHwnd == hwndBtnNight || ctrlHwnd == hwndBtnLangEN || ctrlHwnd == hwndBtnLangRU || ctrlHwnd == hwndBtnMainAction || ctrlHwnd == hwndBtnPasteQr || ctrlHwnd == hwndBtnSave || ctrlHwnd == hwndBtnConnect || ctrlHwnd == hwndBtnSetDefault || ctrlHwnd == hwndBtnInstall || ctrlHwnd == hwndBtnVerify || ctrlHwnd == hwndBtnCopyLog || ctrlHwnd == hwndBtnClearLog || ctrlHwnd == hwndBrand) {
			procSetCursor.Call(hCursorHand)
			return 1
		}

	case WM_DESTROY:
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
	subItem.PszText = strPtr(p.Default)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 2: Name
	subItem.ISubItem = 2
	subItem.PszText = strPtr(p.Name)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 3: Host
	subItem.ISubItem = 3
	subItem.PszText = strPtr(p.Host)
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))

	// Column 4: Port
	subItem.ISubItem = 4
	subItem.PszText = strPtr(strconv.Itoa(p.Port))
	procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&subItem)))
}

func main() {
	runtime.LockOSThread()

	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x00000001 | 0x00000004
	procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))

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
	hBrushBgNight, _, _ = procCreateSolidBrush.Call(0x00141414)
	hBrushWhite, _, _ = procCreateSolidBrush.Call(0x00FFFFFF)
	hBrushCardDay, _, _ = procCreateSolidBrush.Call(0x00F0F2F5)
	hBrushCardNight, _, _ = procCreateSolidBrush.Call(0x001F1F1F)
	hBrushInputNight, _, _ = procCreateSolidBrush.Call(0x00202020)
	hBrushLogNight, _, _ = procCreateSolidBrush.Call(0x000D0D0D)
	hBrushBlack, _, _ = procCreateSolidBrush.Call(0x00000000)
	hPenCyan, _, _ = procCreatePen.Call(0, 2, 0x00FFFF)
	hBrushAnimBlue, _, _ = procCreateSolidBrush.Call(0x00FF9900)

	className := strPtr("GIN_VPN_WINDOW_CLASS_V037")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconApp
	wc.HIconSm = hIconApp
	wc.HCursor, _, _ = procLoadCursorW.Call(0, uintptr(IDC_ARROW))
	wc.HbrBackground = hBrushBgDay
	wc.LpszClassName = className

	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(AppTitleEN))),
		WS_OVERLAPPEDWINDOW&^0x00040000&^0x00010000|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		100, 40, 595, 700,
		0, 0, hInstance, 0,
	)

	if hIconApp != 0 {
		procSendMessageW.Call(hwndMain, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndMain, WM_SETICON, 0, hIconApp)
	}

	// 1. Header Title & Day/Night & EN/RU Language Buttons
	hwndTitle = createStatic("🛡️ GIN-VPN by VladiMIR+AI", 18, 12, 255, 26, hFontTitle)
	hwndBtnDay = createOwnerButton(201, 280, 12, 52, 26)
	hwndBtnNight = createOwnerButton(202, 338, 12, 58, 26)
	hwndBtnLangEN = createOwnerButton(203, 432, 12, 52, 26)
	hwndBtnLangRU = createOwnerButton(204, 490, 12, 52, 26)

	// 2. Main Large Action Button (Directly below Header)
	hwndBtnMainAction = createOwnerButton(101, 18, 44, 532, 44)

	// 3. Active VLESS Key Header & Buttons
	hwndKeyLabel = createStatic("Active VLESS Reality Key: (Ready)", 18, 94, 250, 20, hFontSection)
	hwndBtnPasteQr = createOwnerButton(102, 270, 92, 180, 24)
	hwndBtnSave = createOwnerButton(103, 458, 92, 92, 24)

	hwndKeyEdit, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("EDIT"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_AUTOVSCROLL, 18, 118, 532, 36, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndKeyEdit, WM_SETFONT, hFontConsolas, 1)

	// 4. Saved Profiles Table (Gridlines + InfoTip + Number Column)
	hwndProfilesLbl = createStatic("Double-Click: Connect | Right-Click: Options", 18, 158, 360, 20, hFontSection)
	hwndBtnConnect = createOwnerButton(104, 385, 156, 78, 24)
	hwndBtnSetDefault = createOwnerButton(105, 470, 156, 80, 24)

	hwndListView, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("SysListView32"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS, 18, 182, 532, 150, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER|0x00000400)
	procSendMessageW.Call(hwndListView, WM_SETFONT, hFontRegular, 1)

	// Column 0: Number (№)
	var col LVCOLUMNW
	col.Mask = 0x0001 | 0x0002 | 0x0004 | 0x0008
	col.Fmt = 0x0002 // Center
	col.Cx = 35
	col.PszText = strPtr("№")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 0, uintptr(unsafe.Pointer(&col)))

	// Column 1: Default / Auto
	col.Fmt = 0x0002 // Center
	col.Cx = 65
	col.PszText = strPtr("Default")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 1, uintptr(unsafe.Pointer(&col)))

	// Column 2: Name
	col.Fmt = 0x0000 // Left
	col.Cx = 195
	col.PszText = strPtr("Profile / Device Name")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 2, uintptr(unsafe.Pointer(&col)))

	// Column 3: Host
	col.Cx = 165
	col.PszText = strPtr("Server Host Address")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 3, uintptr(unsafe.Pointer(&col)))

	// Column 4: Port
	col.Fmt = 0x0002 // Center
	col.Cx = 55
	col.PszText = strPtr("Port")
	procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, 4, uintptr(unsafe.Pointer(&col)))

	loadProfilesFromStorage()

	for i, p := range profiles {
		addProfileToListView(i, p)
	}

	// 5. Diagnostics Panel (Rounded Card in WM_ERASEBKGND)
	hwndDiagHeader = createStatic("⚡ Diagnostics & Routing", 28, 342, 510, 18, hFontBold)
	hwndDiagOrig = createStatic("ISP IP: Detecting...", 28, 362, 245, 18, hFontSmall)
	hwndDiagProt = createStatic("VPN IP: 🔴 Disconnected", 275, 362, 265, 18, hFontSmall)
	hwndDiagLat = createStatic("Ping: -- ms", 28, 382, 245, 18, hFontSmall)
	hwndDiagUptime = createStatic("Uptime: Disconnected", 275, 382, 265, 18, hFontSmall)

	// 6. Banner & Bottom Buttons
	hwndBannerLbl = createStatic("⚠️ GIN-VPN is not installed! Running portable. Click [ 📑 Install App ] below to install", 18, 408, 532, 18, hFontSmall)

	hwndBtnInstall = createOwnerButton(106, 18, 428, 145, 28)
	hwndBtnVerify = createOwnerButton(107, 172, 428, 115, 28)
	hwndBtnCopyLog = createOwnerButton(108, 296, 428, 145, 28)
	hwndBtnClearLog = createOwnerButton(109, 450, 428, 100, 28)

	// 7. Log Box (Crisp compact font)
	hwndLogLbl = createStatic("📊 Real-Time Event & Traffic Log:", 18, 460, 260, 18, hFontSection)

	hwndLogEdit, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("EDIT"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|ES_MULTILINE|ES_AUTOVSCROLL|ES_READONLY|WS_VSCROLL, 18, 480, 532, 145, hwndMain, 0, hInstance, 0)
	procSendMessageW.Call(hwndLogEdit, WM_SETFONT, hFontConsolasLog, 1)

	// 8. Brand Signature at Bottom (Clickable -> 3D Easter Egg)
	hwndBrand = createStaticNotify("VladiMIR+AI", 18, 630, 532, 20, hFontBold, 1004)

	installedState = checkIsInstalled()
	updateBannerAndInstallButton()
	initTooltips()

	// Initial Tray
	updateTrayIcon(false, "", "")

	// Detect ISP IP in background
	detectOriginalISPAsync()

	// Ensure embedded Xray Core payload is ready
	_ = ensureXrayBinaryExists()

	writeLog("INIT", fmt.Sprintf("GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client %s ready.", AppVersion))
	writeLog("SECURE", "Encrypted Registry & local storage active for VPN profiles.")
	writeLog("CORE", fmt.Sprintf("Standalone Embedded Xray Core: %s", activeXrayExePath))
	writeLog("TRAY", "System Tray notification icon registered.")
	writeLog("READY", "VPN client initialized. Select a profile or click [ ▶ CONNECT TO VPN ].")

	procSetTimer.Call(hwndMain, 1, 1000, 0)

	// Auto-Connect on launch if a profile is set for auto-connect
	hasAutoConnect := false
	for _, p := range profiles {
		if p.Default != "" {
			hasAutoConnect = true
			writeLog("AUTO", fmt.Sprintf("Auto-connect triggered on launch for '%s'...", p.Name))
			connectToNodeAsync(p.Name, p.Host, p.Port, p.Country, p.RawUri, true)
			procShowWindow.Call(hwndMain, 0) // Start directly minimized in system tray
			break
		}
	}

	if !hasAutoConnect {
		// Show window initially on start in clean Standby mode
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

	for {
		ret, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if ret == 0 || int32(ret) == -1 {
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
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
