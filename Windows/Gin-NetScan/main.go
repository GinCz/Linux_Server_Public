package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"
)

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	comctl32 = syscall.NewLazyDLL("comctl32.dll")
	iphlpapi = syscall.NewLazyDLL("iphlpapi.dll")

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
	procSetCursor            = user32.NewProc("SetCursor")
	procSetTimer             = user32.NewProc("SetTimer")
	procKillTimer            = user32.NewProc("KillTimer")
	procInvalidateRect       = user32.NewProc("InvalidateRect")
	procBeginPaint           = user32.NewProc("BeginPaint")
	procEndPaint             = user32.NewProc("EndPaint")

	procGetStockObject       = gdi32.NewProc("GetStockObject")
	procCreateFontW          = gdi32.NewProc("CreateFontW")
	procSetBkMode            = gdi32.NewProc("SetBkMode")
	procSetTextColor         = gdi32.NewProc("SetTextColor")
	procCreatePen            = gdi32.NewProc("CreatePen")
	procCreateSolidBrush     = gdi32.NewProc("CreateSolidBrush")
	procSelectObject         = gdi32.NewProc("SelectObject")
	procDeleteObject         = gdi32.NewProc("DeleteObject")
	procMoveToEx             = gdi32.NewProc("MoveToEx")
	procLineTo               = gdi32.NewProc("LineTo")
	procEllipse              = gdi32.NewProc("Ellipse")

	procGetModuleHandleW     = kernel32.NewProc("GetModuleHandleW")
	procInitCommonControlsEx = comctl32.NewProc("InitCommonControlsEx")

	// Context Menu & Clipboard APIs
	procCreatePopupMenu  = user32.NewProc("CreatePopupMenu")
	procAppendMenuW      = user32.NewProc("AppendMenuW")
	procTrackPopupMenu   = user32.NewProc("TrackPopupMenu")
	procDestroyMenu      = user32.NewProc("DestroyMenu")
	procGetCursorPos     = user32.NewProc("GetCursorPos")
	procOpenClipboard    = user32.NewProc("OpenClipboard")
	procCloseClipboard   = user32.NewProc("CloseClipboard")
	procEmptyClipboard   = user32.NewProc("EmptyClipboard")
	procSetClipboardData = user32.NewProc("SetClipboardData")
	procGlobalAlloc         = kernel32.NewProc("GlobalAlloc")
	procGlobalLock          = kernel32.NewProc("GlobalLock")
	procGlobalUnlock        = kernel32.NewProc("GlobalUnlock")
	procGetCurrentProcess   = kernel32.NewProc("GetCurrentProcess")
	procSetPriorityClass    = kernel32.NewProc("SetPriorityClass")

	// Network Hardware APIs
	procSendARP         = iphlpapi.NewProc("SendARP")
	procIcmpCreateFile  = iphlpapi.NewProc("IcmpCreateFile")
	procIcmpCloseHandle = iphlpapi.NewProc("IcmpCloseHandle")
	procIcmpSendEcho    = iphlpapi.NewProc("IcmpSendEcho")
)

const (
	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	WS_TABSTOP          = 0x00010000
	WS_CLIPCHILDREN     = 0x02000000
	WS_CLIPSIBLINGS     = 0x04000000

	ES_AUTOHSCROLL   = 0x0080
	CBS_DROPDOWNLIST = 0x0003
	SS_NOTIFY        = 0x0100
	SS_RIGHT         = 0x0002
	WS_POPUP         = 0x80000000

	CB_ADDSTRING    = 0x0143
	CB_SETCURSEL    = 0x014E
	CB_GETCURSEL    = 0x0147
	CB_GETLBTEXT    = 0x0148
	CB_GETLBTEXTLEN = 0x0149
	CBN_SELCHANGE   = 1

	TTS_ALWAYSTIP      = 0x01
	TTS_NOPREFIX       = 0x02
	TTS_BALLOON        = 0x40
	TTF_SUBCLASS       = 0x0010
	TTF_IDISHWND       = 0x0001
	TTM_ADDTOOLW       = WM_USER + 50
	TTM_SETMAXTIPWIDTH = WM_USER + 24

	LVS_REPORT                   = 0x0001
	LVS_SINGLESEL                = 0x0004
	LVS_SHOWSELALWAYS            = 0x0008
	LVM_FIRST                    = 0x1000
	LVM_INSERTCOLUMNW            = LVM_FIRST + 97
	LVM_INSERTITEMW              = LVM_FIRST + 77
	LVM_SETITEMTEXTW             = LVM_FIRST + 116
	LVM_DELETEALLITEMS           = LVM_FIRST + 9
	LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54
	LVM_GETNEXTITEM              = LVM_FIRST + 12
	LVM_SETCOLUMNWIDTH           = LVM_FIRST + 30
	LVM_GETCOLUMNWIDTH           = LVM_FIRST + 29
	LVNI_SELECTED                = 0x0002
	LVS_EX_FULLROWSELECT         = 0x00000020
	LVS_EX_GRIDLINES             = 0x00000001
	LVS_EX_DOUBLEBUFFER          = 0x00010000

	LVSCW_AUTOSIZE = ^uintptr(0) // -1

	PBM_SETRANGE = 0x0401
	PBM_SETPOS   = 0x0402

	WM_DESTROY        = 0x0002
	WM_PAINT          = 0x000F
	WM_COMMAND        = 0x0111
	WM_NOTIFY         = 0x004E
	WM_TIMER          = 0x0113
	WM_SETCURSOR      = 0x0020
	WM_CTLCOLORSTATIC = 0x0138
	WM_SETICON        = 0x0080
	WM_CONTEXTMENU    = 0x007B
	WM_USER           = 0x0400

	NM_CUSTOMDRAW       = ^uint32(11) // uint32(-12)
	CDDS_PREPAINT       = 0x00000001
	CDDS_ITEM           = 0x00010000
	CDDS_ITEMPREPAINT   = CDDS_ITEM | CDDS_PREPAINT
	CDRF_DODEFAULT      = 0x00000000
	CDRF_NOTIFYITEMDRAW = 0x00000020

	WM_APP_SCAN_DONE = WM_USER + 101

	DEFAULT_GUI_FONT = 17
	WM_SETFONT       = 0x0030

	MF_STRING       = 0x0000
	MF_SEPARATOR    = 0x0800
	TPM_RIGHTBUTTON = 0x0002
	CF_UNICODETEXT  = 13
	GMEM_MOVEABLE   = 0x0002
	IDC_HAND        = 32649
)

type NMHDR struct {
	HwndFrom uintptr
	IdFrom   uintptr
	Code     uint32
}

type NMLVCUSTOMDRAW struct {
	Hdr         NMHDR
	DwDrawStage uint32
	Hdc         uintptr
	Rc          RECT
	DwItemSpec  uintptr
	UItemState  uint32
	LItemlParam uintptr
	ClrText     uint32
	ClrTextBk   uint32
	ISubItem    int32
}

type POINT struct {
	X int32
	Y int32
}

type RECT struct {
	Left, Top, Right, Bottom int32
}

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
	CxMin      int32
	CxDefault  int32
	CxIdeal    int32
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
	GroupId    int32
	CColumns   uint32
	PuColumns  *uint32
	PiColFmt   *int32
	IGroup     int32
}

type IP_OPTION_INFORMATION struct {
	Ttl         byte
	Tos         byte
	Flags       byte
	OptionsSize byte
	OptionsData uintptr
}

type ICMP_ECHO_REPLY struct {
	Address       uint32
	Status        uint32
	RoundTripTime uint32
	DataSize      uint16
	Reserved      uint16
	Data          uintptr
	Options       IP_OPTION_INFORMATION
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

type SubnetInfo struct {
	Name      string
	Subnet    string
	RangeFrom string
	RangeTo   string
}

type DeviceInfo struct {
	Index       int
	TypeIcon    string
	IP          string
	Hostname    string
	MAC         string
	PingTime    string
	Speed       string
	Fingerprint string
	RawIPNum    uint32
	IsOnline    bool
	LastSeen    string
}

var (
	hwndMain         uintptr
	hwndComboSub     uintptr
	hwndIPFrom       uintptr
	hwndIPTo         uintptr
	hwndTimeout      uintptr
	hwndPacket       uintptr
	hwndThreads      uintptr
	hwndBtnStart     uintptr
	hwndBtnStop      uintptr
	hwndBtnDeepScan  uintptr
	hwndBtnScanPorts uintptr
	hwndBtnExport    uintptr
	hwndProgress     uintptr
	hwndListView     uintptr
	hwndStatus       uintptr
	hwndBrand        uintptr

	hwndAbout     uintptr
	hwndAboutAnim uintptr

	hwndPortScan       uintptr
	hwndPortList       uintptr
	hwndPortStatus     uintptr
	portScanTargetIP   string
	portScanTargetHost string

	hInstance   uintptr
	hIconApp    uintptr
	hFontSegoe  uintptr
	hFontBold   uintptr
	hBrushWhite uintptr
	hBrushBlack uintptr
	hCursorHand uintptr

	detectedSubnets []SubnetInfo

	// Persistent Session Cache across rescans for offline tracking
	sessionDeviceHistory = make(map[string]DeviceInfo)
	historyMutex         sync.Mutex

	foundDevices []DeviceInfo
	devicesMutex sync.Mutex
	isScanning   bool
	stopScanFlag bool
	scanMutex    sync.Mutex

	progressCount int32
	totalHosts    int32
	foundCount    int32

	selectedDevice DeviceInfo

	animAngle float64
)

// Apple Hardware Model Mapping
var appleModelMap = map[string]string{
	"iPhone17,4": "iPhone 16 Plus",
	"iPhone17,3": "iPhone 16",
	"iPhone17,2": "iPhone 16 Pro Max",
	"iPhone17,1": "iPhone 16 Pro",
	"iPhone16,2": "iPhone 15 Pro Max",
	"iPhone16,1": "iPhone 15 Pro",
	"iPhone15,5": "iPhone 15 Plus",
	"iPhone15,4": "iPhone 15",
	"iPhone15,3": "iPhone 14 Pro Max",
	"iPhone15,2": "iPhone 14 Pro",
	"iPhone14,8": "iPhone 14 Plus",
	"iPhone14,7": "iPhone 14",
	"iPhone14,5": "iPhone 13",
	"iPhone14,4": "iPhone 13 mini",
	"iPhone14,3": "iPhone 13 Pro Max",
	"iPhone14,2": "iPhone 13 Pro",
	"iPhone13,4": "iPhone 12 Pro Max",
	"iPhone13,3": "iPhone 12 Pro",
	"iPhone13,2": "iPhone 12",
	"iPhone13,1": "iPhone 12 mini",
	"iPhone12,8": "iPhone SE (2nd gen)",
	"iPhone14,6": "iPhone SE (3rd gen)",
	"iPhone12,5": "iPhone 11 Pro Max",
	"iPhone12,3": "iPhone 11 Pro",
	"iPhone12,1": "iPhone 11",
	"iPhone11,8": "iPhone XR",
	"iPhone11,6": "iPhone XS Max",
	"iPhone11,4": "iPhone XS Max",
	"iPhone11,2": "iPhone XS",
	"iPhone10,6": "iPhone X",
	"iPhone10,3": "iPhone X",
	"iPad13,18":  "iPad (10th gen)",
	"iPad14,3":   "iPad Pro 11-inch (M2)",
	"iPad14,5":   "iPad Pro 12.9-inch (M2)",
	"iPad16,3":   "iPad Pro 11-inch (M4)",
	"iPad16,5":   "iPad Pro 13-inch (M4)",
	"MacBookPro18,1": "MacBook Pro 16-inch (M1 Pro)",
	"MacBookPro18,2": "MacBook Pro 16-inch (M1 Max)",
	"MacBookAir10,1": "MacBook Air (M1)",
	"Mac14,2":        "MacBook Air (M2)",
	"Mac14,7":        "MacBook Pro 13-inch (M2)",
	"Mac15,3":        "MacBook Pro 14-inch (M3)",
}

// Known MAC OUI database
var knownOUI = map[string]string{
	"E8:DE:27": "TP-Link Technologies (Archer/Router)",
	"00:EB:D8": "TP-Link / Mercusys (Access Point)",
	"00:24:32": "Intel Corporation (PC / Workstation)",
	"54:DF:1B": "Espressif Systems (ESP IoT Smart Node)",
	"56:4B:59": "Randomized Private MAC (Smartphone)",
	"E0:B9:4D": "Smart IoT Sensor / Camera",
	"68:B9:D3": "Apple, Inc. (iPhone / iOS)",
	"44:DA:30": "Apple, Inc. (iPhone / iOS)",
	"F0:18:98": "Apple, Inc. (iPhone / iOS)",
	"A4:83:E7": "Apple, Inc. (iPhone / iOS)",
	"BC:D1:D3": "Apple, Inc. (iPhone / iOS)",
	"DC:A9:04": "Apple, Inc. (Apple Device)",
	"70:35:60": "Apple, Inc. (Apple Device)",
	"3C:06:30": "Apple, Inc. (Apple Device)",
	"80:E6:50": "Apple, Inc. (Apple Device)",
	"AC:BC:32": "Apple, Inc. (Apple Device)",
	"B8:E8:56": "Apple, Inc. (Apple Device)",
	"38:F9:D3": "Apple, Inc. (Apple Device)",
	"48:D7:05": "Apple, Inc. (Apple Device)",
	"60:F8:1D": "Apple, Inc. (Apple Device)",
	"88:66:5A": "Apple, Inc. (Apple Device)",
	"A8:66:7F": "Apple, Inc. (Apple Device)",
	"CC:29:F5": "Apple, Inc. (Apple Device)",
	"F8:4D:89": "Apple, Inc. (Apple Device)",
	"42:B2:D2": "Infinix / Transsion (Smartphone)",
	"10:BF:48": "Smart IoT Appliance",
	"AC:92:32": "Honor Device Co. (HONOR Smartphone)",
	"C4:AD:34": "Huawei Technologies (Smartphone / Router)",
	"50:D4:F7": "Xiaomi Communications (Mi / Redmi)",
	"BC:D0:74": "Samsung Electronics (Smart TV / Galaxy)",
	"48:2C:A0": "MikroTik RouterBoard (RouterOS)",
	"B8:27:EB": "Raspberry Pi Foundation",
	"DC:A6:32": "Raspberry Pi Foundation",
	"80:7D:3A": "Tuya Smart (IP Camera / IoT)",
	"70:03:9F": "Tuya Smart (Smart Home Node)",
	"D8:F8:83": "Tuya Smart (Wi-Fi Camera)",
	"00:11:32": "Synology Inc. (DiskStation NAS)",
	"00:08:9B": "QNAP Systems (Turbo NAS)",
	"00:1E:06": "Wistron InfoComm",
	"00:0C:29": "VMware Virtual Platform",
	"00:50:56": "VMware Virtual Platform",
	"00:15:5D": "Microsoft Hyper-V VM",
	"F4:6B:8C": "Amazon Technologies (Echo / FireTV)",
	"74:C2:46": "Amazon Technologies (Smart Device)",
	"38:2C:4A": "ASUSTek Computer (Motherboard / Router)",
	"04:D4:C4": "ASUSTek Computer (ROG / Gaming PC)",
	"D0:50:99": "ASRock Incorporation",
	"18:31:BF": "ASUSTek Computer (ZenWiFi / AP)",
	"2C:FD:A1": "Netgear (Nighthawk Router)",
	"A0:04:60": "Netgear (Network Switch / AP)",
	"00:1F:33": "Netgear",
	"3C:37:12": "Google, Inc. (Chromecast / Home)",
	"94:9A:A9": "Google, Inc. (Nest Hub / Audio)",
	"F0:72:EA": "Google, Inc. (Pixel / Android)",
	"B0:BE:76": "LG Electronics (webOS Smart TV)",
	"E8:5B:5B": "LG Electronics (Smart Appliance)",
	"00:23:4D": "Hewlett-Packard (LaserJet / OfficeJet)",
	"10:65:30": "Cisco Systems (Catalyst / SmallBiz)",
	"00:18:BA": "Cisco Systems",
	"00:0F:00": "PC Network Client",
}

func getControlText(hwnd uintptr) string {
	length, _, _ := procGetWindowTextLengthW.Call(hwnd)
	if length == 0 {
		return ""
	}
	buf := make([]uint16, length+1)
	procGetWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(&buf[0])), uintptr(length+1))
	return syscall.UTF16ToString(buf)
}

func setControlText(hwnd uintptr, text string) {
	procSetWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(strPtr(text))))
}

func getComboSelectedText(hwnd uintptr) string {
	selIdx, _, _ := procSendMessageW.Call(hwnd, CB_GETCURSEL, 0, 0)
	if int32(selIdx) < 0 {
		return getControlText(hwnd)
	}
	length, _, _ := procSendMessageW.Call(hwnd, CB_GETLBTEXTLEN, selIdx, 0)
	if length == 0 || int32(length) < 0 {
		return getControlText(hwnd)
	}
	buf := make([]uint16, length+1)
	procSendMessageW.Call(hwnd, CB_GETLBTEXT, selIdx, uintptr(unsafe.Pointer(&buf[0])))
	return syscall.UTF16ToString(buf)
}

func extractFirstInt(s string, defaultVal int) int {
	re := regexp.MustCompile(`\d+`)
	match := re.FindString(s)
	if match == "" {
		return defaultVal
	}
	val, err := strconv.Atoi(match)
	if err != nil || val <= 0 {
		return defaultVal
	}
	return val
}

func addTooltip(hwndTip, hwndCtrl uintptr, text string) {
	if hwndTip == 0 || hwndCtrl == 0 || text == "" {
		return
	}
	var ti TOOLINFOW
	ti.CbSize = uint32(unsafe.Sizeof(ti))
	ti.UFlags = TTF_SUBCLASS | TTF_IDISHWND
	ti.Hwnd = hwndMain
	ti.UId = hwndCtrl
	ti.LpszText = strPtr(text)
	procSendMessageW.Call(hwndTip, TTM_ADDTOOLW, 0, uintptr(unsafe.Pointer(&ti)))
}

func getSessionCachePath() string {
	tempDir := os.TempDir()
	return filepath.Join(tempDir, "gin_netscan_session_cache.json")
}

func loadSessionHistoryFromDisk() {
	cachePath := getSessionCachePath()
	data, err := os.ReadFile(cachePath)
	if err != nil {
		return
	}
	historyMutex.Lock()
	defer historyMutex.Unlock()
	_ = json.Unmarshal(data, &sessionDeviceHistory)
}

func saveSessionHistoryToDisk() {
	historyMutex.Lock()
	defer historyMutex.Unlock()
	data, err := json.Marshal(sessionDeviceHistory)
	if err != nil {
		return
	}
	_ = os.WriteFile(getSessionCachePath(), data, 0644)
}

func copyToClipboard(text string) {
	if text == "" {
		return
	}
	utf16, err := syscall.UTF16FromString(text)
	if err != nil {
		return
	}
	size := uintptr(len(utf16) * 2)
	hMem, _, _ := procGlobalAlloc.Call(GMEM_MOVEABLE, size)
	if hMem == 0 {
		return
	}
	ptr, _, _ := procGlobalLock.Call(hMem)
	if ptr == 0 {
		return
	}

	srcSlice := (*[1 << 28]byte)(unsafe.Pointer(&utf16[0]))[:size:size]
	dstSlice := (*[1 << 28]byte)(unsafe.Pointer(ptr))[:size:size]
	copy(dstSlice, srcSlice)
	procGlobalUnlock.Call(hMem)

	procOpenClipboard.Call(hwndMain)
	procEmptyClipboard.Call()
	procSetClipboardData.Call(CF_UNICODETEXT, hMem)
	procCloseClipboard.Call()
}

func parseIPv4(ipStr string) (uint32, error) {
	ip := net.ParseIP(strings.TrimSpace(ipStr))
	if ip == nil {
		return 0, fmt.Errorf("invalid IP")
	}
	ip4 := ip.To4()
	if ip4 == nil {
		return 0, fmt.Errorf("not IPv4")
	}
	return uint32(ip4[0])<<24 | uint32(ip4[1])<<16 | uint32(ip4[2])<<8 | uint32(ip4[3]), nil
}

func formatIPv4(ipNum uint32) string {
	return fmt.Sprintf("%d.%d.%d.%d", byte(ipNum>>24), byte(ipNum>>16), byte(ipNum>>8), byte(ipNum))
}

func detectAllSubnets() []SubnetInfo {
	var results []SubnetInfo
	ifaces, err := net.Interfaces()
	if err != nil {
		return nil
	}

	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ip4 := ipnet.IP.To4(); ip4 != nil {
					sub := fmt.Sprintf("%d.%d.%d", ip4[0], ip4[1], ip4[2])
					from := fmt.Sprintf("%s.0", sub)
					to := fmt.Sprintf("%s.255", sub)
					results = append(results, SubnetInfo{
						Name:      iface.Name,
						Subnet:    sub,
						RangeFrom: from,
						RangeTo:   to,
					})
				}
			}
		}
	}

	return results
}

func readARPTable() map[string]string {
	arpMap := make(map[string]string)
	cmd := exec.Command("arp", "-a")
	out, err := cmd.Output()
	if err != nil {
		return arpMap
	}
	re := regexp.MustCompile(`([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\s+([0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2})`)
	matches := re.FindAllStringSubmatch(string(out), -1)
	for _, m := range matches {
		ip := m[1]
		mac := strings.ToUpper(strings.ReplaceAll(m[2], "-", ":"))
		if mac != "FF:FF:FF:FF:FF:FF" && !strings.HasPrefix(mac, "01:00:5E") {
			arpMap[ip] = mac
		}
	}
	return arpMap
}

// Ultra-fast Hardware ARP probe via iphlpapi.dll SendARP
func sendHardwareARP(ipNum uint32) (bool, string) {
	netOrderIP := ((ipNum & 0xFF) << 24) | (((ipNum >> 8) & 0xFF) << 16) | (((ipNum >> 16) & 0xFF) << 8) | ((ipNum >> 24) & 0xFF)
	var mac [6]byte
	macLen := uint32(6)

	ret, _, _ := procSendARP.Call(
		uintptr(netOrderIP),
		0,
		uintptr(unsafe.Pointer(&mac[0])),
		uintptr(unsafe.Pointer(&macLen)),
	)

	if ret == 0 && macLen == 6 {
		macStr := fmt.Sprintf("%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5])
		return true, macStr
	}
	return false, ""
}

// Domain name label encoder for mDNS / DNS wire format
func encodeDNSName(domain string) []byte {
	var buf bytes.Buffer
	parts := strings.Split(domain, ".")
	for _, p := range parts {
		if len(p) == 0 {
			continue
		}
		buf.WriteByte(byte(len(p)))
		buf.WriteString(p)
	}
	buf.WriteByte(0)
	return buf.Bytes()
}

func buildMDNSQuery(name string, qtype uint16) []byte {
	var b bytes.Buffer
	b.Write([]byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
	b.Write(encodeDNSName(name))
	b.Write([]byte{byte(qtype >> 8), byte(qtype & 0xFF)})
	b.Write([]byte{0x00, 0x01})
	return b.Bytes()
}

func parseDNSLabels(data []byte, offset int) (string, int) {
	var parts []string
	curr := offset
	visited := 0
	maxVisited := 20
	jumped := false
	nextOffset := offset

	for curr < len(data) && visited < maxVisited {
		visited++
		b := data[curr]
		if b == 0 {
			if !jumped {
				nextOffset = curr + 1
			}
			break
		}

		if (b & 0xC0) == 0xC0 {
			if curr+1 >= len(data) {
				break
			}
			ptr := (int(b&0x3F) << 8) | int(data[curr+1])
			if !jumped {
				nextOffset = curr + 2
				jumped = true
			}
			curr = ptr
			continue
		}

		lblLen := int(b)
		curr++
		if curr+lblLen > len(data) {
			break
		}
		parts = append(parts, string(data[curr:curr+lblLen]))
		curr += lblLen
		if !jumped {
			nextOffset = curr
		}
	}

	return strings.Join(parts, "."), nextOffset
}

func parseMDNSResponse(data []byte) (hostname string, model string, friendlyName string) {
	if len(data) < 12 {
		return
	}

	s := string(data)

	// 1. Model ID detection (e.g. model=iPhone14,5)
	if idx := strings.Index(s, "model="); idx != -1 {
		sub := s[idx+6:]
		end := strings.IndexAny(sub, "\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\r\n ")
		if end == -1 {
			end = len(sub)
		}
		if end > 30 {
			end = 30
		}
		rawModel := strings.TrimSpace(sub[:end])
		if nice, ok := appleModelMap[rawModel]; ok {
			model = nice
		} else if rawModel != "" {
			model = rawModel
		}
	}

	// 2. Friendly Name / Device Name (e.g. fn=..., name=..., md=...)
	for _, prefix := range []string{"fn=", "name=", "md=", "am="} {
		if idx := strings.Index(s, prefix); idx != -1 {
			sub := s[idx+len(prefix):]
			end := strings.IndexAny(sub, "\x00\r\n\t")
			if end == -1 {
				end = len(sub)
			}
			if end > 40 {
				end = 40
			}
			val := strings.TrimSpace(sub[:end])
			if val != "" && friendlyName == "" {
				friendlyName = val
			}
		}
	}

	// 3. Walk DNS Answers & Additionals
	qdCount := (int(data[4]) << 8) | int(data[5])
	anCount := (int(data[6]) << 8) | int(data[7])
	arCount := (int(data[10]) << 8) | int(data[11])

	offset := 12
	for i := 0; i < qdCount && offset < len(data); i++ {
		_, next := parseDNSLabels(data, offset)
		offset = next + 4
	}

	totalRRs := anCount + arCount
	for i := 0; i < totalRRs && offset+10 <= len(data); i++ {
		name, next := parseDNSLabels(data, offset)
		offset = next
		if offset+10 > len(data) {
			break
		}
		rtype := (uint16(data[offset]) << 8) | uint16(data[offset+1])
		rdLen := (int(data[offset+8]) << 8) | int(data[offset+9])
		offset += 10

		if offset+rdLen > len(data) {
			rdLen = len(data) - offset
		}

		if rtype == 12 { // PTR
			target, _ := parseDNSLabels(data, offset)
			if target != "" {
				cleanTarget := strings.TrimSuffix(target, ".local")
				cleanTarget = strings.TrimSuffix(cleanTarget, "._companion-link._tcp")
				cleanTarget = strings.TrimSuffix(cleanTarget, "._airplay._tcp")
				cleanTarget = strings.TrimSuffix(cleanTarget, "._googlecast._tcp")
				if hostname == "" && !strings.HasPrefix(cleanTarget, "_") && len(cleanTarget) > 1 {
					hostname = cleanTarget
				}
			}
		}

		if hostname == "" && name != "" && strings.HasSuffix(name, ".local") {
			cleanName := strings.TrimSuffix(name, ".local")
			cleanName = strings.TrimSuffix(cleanName, "._companion-link._tcp")
			cleanName = strings.TrimSuffix(cleanName, "._airplay._tcp")
			if !strings.HasPrefix(cleanName, "_") && len(cleanName) > 1 {
				hostname = cleanName
			}
		}

		offset += rdLen
	}

	// Fallback heuristic for .local
	if hostname == "" {
		if idx := strings.Index(s, ".local"); idx != -1 {
			start := idx - 1
			for start >= 0 && data[start] >= 0x20 && data[start] <= 0x7E && data[start] != ' ' && data[start] != '@' && data[start] != '\x00' {
				start--
			}
			candidate := strings.TrimSpace(s[start+1 : idx])
			candidate = strings.TrimPrefix(candidate, "_")
			if len(candidate) > 2 && !strings.HasPrefix(candidate, "local") && !strings.Contains(candidate, "_tcp") && !strings.Contains(candidate, "_udp") {
				hostname = candidate
			}
		}
	}

	return
}

func queryMDNSHost(ipStr string) (hostname string, model string, friendlyName string) {
	conn, err := net.DialTimeout("udp", ipStr+":5353", 70*time.Millisecond)
	if err != nil {
		return
	}
	defer conn.Close()

	// 1. Reverse in-addr.arpa lookup
	parts := strings.Split(ipStr, ".")
	if len(parts) == 4 {
		revName := fmt.Sprintf("%s.%s.%s.%s.in-addr.arpa", parts[3], parts[2], parts[1], parts[0])
		conn.Write(buildMDNSQuery(revName, 12))
	}

	// 2. Apple Bonjour and Google Cast queries
	conn.Write(buildMDNSQuery("_companion-link._tcp.local", 12))
	conn.Write(buildMDNSQuery("_airplay._tcp.local", 12))
	conn.Write(buildMDNSQuery("_googlecast._tcp.local", 12))

	conn.SetDeadline(time.Now().Add(80 * time.Millisecond))
	buf := make([]byte, 2048)
	n, err := conn.Read(buf)
	if err == nil && n > 12 {
		hostname, model, friendlyName = parseMDNSResponse(buf[:n])
	}
	return
}

func querySSDP(ipStr string) (server string, model string) {
	conn, err := net.DialTimeout("udp", ipStr+":1900", 70*time.Millisecond)
	if err != nil {
		return "", ""
	}
	defer conn.Close()

	msg := "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 1\r\nST: ssdp:all\r\n\r\n"
	conn.Write([]byte(msg))

	conn.SetDeadline(time.Now().Add(80 * time.Millisecond))
	buf := make([]byte, 1500)
	n, err := conn.Read(buf)
	if err == nil && n > 0 {
		raw := string(buf[:n])
		for _, line := range strings.Split(raw, "\r\n") {
			lower := strings.ToLower(line)
			if strings.HasPrefix(lower, "server:") {
				server = strings.TrimSpace(line[7:])
			}
			if strings.HasPrefix(lower, "usn:") && model == "" {
				model = strings.TrimSpace(line[4:])
			}
		}
	}
	return server, model
}

func queryNetBIOSName(ipStr string) string {
	conn, err := net.DialTimeout("udp", ipStr+":137", 70*time.Millisecond)
	if err != nil {
		return ""
	}
	defer conn.Close()

	req := []byte{
		0x81, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x20, 0x43, 0x4b, 0x41, 0x41, 0x41,
		0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
		0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
		0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
		0x41, 0x41, 0x00, 0x00, 0x21, 0x00, 0x01,
	}

	conn.SetDeadline(time.Now().Add(80 * time.Millisecond))
	conn.Write(req)

	resp := make([]byte, 512)
	n, err := conn.Read(resp)
	if err != nil || n < 57 {
		return ""
	}

	numNames := int(resp[56])
	pos := 57
	for i := 0; i < numNames && pos+18 <= n; i++ {
		nameBytes := resp[pos : pos+15]
		typeByte := resp[pos+15]
		nameStr := strings.TrimSpace(string(bytes.Trim(nameBytes, "\x00 ")))
		if typeByte == 0x00 || typeByte == 0x20 {
			if len(nameStr) > 0 && !strings.HasPrefix(nameStr, "IS~") && !strings.HasPrefix(nameStr, "__MS") {
				return nameStr
			}
		}
		pos += 18
	}
	return ""
}

// Deep Multi-Service Fingerprinting: Fully Concurrent NetBIOS + mDNS + SSDP + DNS + HTTP Title + Port Sweep
func deepFingerprintHost(ipStr string) (string, string, []string) {
	var hostname string
	var banner string
	var openPorts []string
	var mu sync.Mutex
	var wg sync.WaitGroup

	// 1. NetBIOS (UDP 137)
	wg.Add(1)
	go func() {
		defer wg.Done()
		nbName := queryNetBIOSName(ipStr)
		if nbName != "" {
			mu.Lock()
			if hostname == "" {
				hostname = nbName
			}
			mu.Unlock()
		}
	}()

	// 2. mDNS (UDP 5353)
	wg.Add(1)
	go func() {
		defer wg.Done()
		mHost, mModel, mFriendly := queryMDNSHost(ipStr)
		mu.Lock()
		if mHost != "" && hostname == "" {
			hostname = mHost
		}
		if mFriendly != "" && hostname == "" {
			hostname = mFriendly
		}
		if mModel != "" && banner == "" {
			banner = mModel
		}
		mu.Unlock()
	}()

	// 3. SSDP (UDP 1900)
	wg.Add(1)
	go func() {
		defer wg.Done()
		ssdpServer, ssdpModel := querySSDP(ipStr)
		mu.Lock()
		if banner == "" && ssdpModel != "" {
			banner = ssdpModel
		} else if banner == "" && ssdpServer != "" {
			banner = ssdpServer
		}
		mu.Unlock()
	}()

	// 4. Reverse DNS (PTR)
	wg.Add(1)
	go func() {
		defer wg.Done()
		names, err := net.LookupAddr(ipStr)
		if err == nil && len(names) > 0 {
			mu.Lock()
			if hostname == "" {
				hostname = strings.TrimSuffix(names[0], ".")
			}
			mu.Unlock()
		}
	}()

	// 5. Signature Port Sweep (Parallel)
	targetPorts := []struct {
		Port int
		Name string
	}{
		{80, "HTTP"},
		{443, "HTTPS"},
		{554, "RTSP-Cam"},
		{9100, "Printer-RAW"},
		{5000, "DSM/AirPlay"},
		{7000, "AirPlay"},
		{8291, "MikroTik-WinBox"},
		{3389, "RDP-PC"},
		{445, "SMB-Share"},
		{8008, "Cast-TV"},
		{8080, "Web-UI"},
		{22, "SSH"},
		{53, "DNS"},
		{62078, "Apple-Sync"},
	}

	for _, tp := range targetPorts {
		wg.Add(1)
		go func(p int, name string) {
			defer wg.Done()
			conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", ipStr, p), 80*time.Millisecond)
			if err == nil {
				conn.Close()
				mu.Lock()
				openPorts = append(openPorts, fmt.Sprintf("%s:%d", name, p))
				mu.Unlock()
			}
		}(tp.Port, tp.Name)
	}

	// 6. HTTP Banner Grab
	wg.Add(1)
	go func() {
		defer wg.Done()
		conn, err := net.DialTimeout("tcp", ipStr+":80", 80*time.Millisecond)
		if err == nil {
			conn.SetDeadline(time.Now().Add(100 * time.Millisecond))
			fmt.Fprintf(conn, "GET / HTTP/1.0\r\nHost: %s\r\nUser-Agent: Mozilla/5.0 (GIN-NetScan)\r\n\r\n", ipStr)
			buf := make([]byte, 1500)
			n, _ := conn.Read(buf)
			conn.Close()
			if n > 0 {
				raw := string(buf[:n])
				reTitle := regexp.MustCompile(`(?i)<title>(.*?)</title>`)
				mTitle := reTitle.FindStringSubmatch(raw)
				mu.Lock()
				if len(mTitle) > 1 {
					t := strings.TrimSpace(mTitle[1])
					if len(t) > 0 && len(t) < 40 {
						if banner == "" {
							banner = t
						}
						if hostname == "" {
							hostname = t
						}
					}
				}
				reServer := regexp.MustCompile(`(?i)Server:\s*([^\r\n]+)`)
				mServer := reServer.FindStringSubmatch(raw)
				if len(mServer) > 1 && banner == "" {
					banner = strings.TrimSpace(mServer[1])
				}
				mu.Unlock()
			}
		}
	}()

	wg.Wait()

	if hostname == "" {
		hostname = "—"
	}

	return hostname, banner, openPorts
}

// Fast ICMP Echo Probe with custom packet size (Clamped to MTU 1472B)
func probeHostICMP(ipStr string, timeoutMs int, packetSize int) (bool, int, string) {
	if packetSize > 1472 {
		packetSize = 1472
	}
	if packetSize < 32 {
		packetSize = 32
	}

	hIcmp, _, _ := procIcmpCreateFile.Call()
	if hIcmp != 0 && hIcmp != ^uintptr(0) {
		defer procIcmpCloseHandle.Call(hIcmp)

		destIP, err := parseIPv4(ipStr)
		if err == nil {
			netOrderIP := ((destIP & 0xFF) << 24) | (((destIP >> 8) & 0xFF) << 16) | (((destIP >> 16) & 0xFF) << 8) | ((destIP >> 24) & 0xFF)

			sendData := make([]byte, packetSize)
			for i := range sendData {
				sendData[i] = byte('A' + (i % 26))
			}

			replySize := uint32(unsafe.Sizeof(ICMP_ECHO_REPLY{})) + uint32(packetSize) + 64
			replyBuf := make([]byte, replySize)

			for retry := 0; retry < 2; retry++ {
				ret, _, _ := procIcmpSendEcho.Call(
					hIcmp,
					uintptr(netOrderIP),
					uintptr(unsafe.Pointer(&sendData[0])),
					uintptr(packetSize),
					0,
					uintptr(unsafe.Pointer(&replyBuf[0])),
					uintptr(replySize),
					uintptr(timeoutMs),
				)

				if ret > 0 {
					reply := (*ICMP_ECHO_REPLY)(unsafe.Pointer(&replyBuf[0]))
					if reply.Status == 0 {
						rtt := int(reply.RoundTripTime)
						speedStr := calculateSpeed(rtt, packetSize)
						return true, rtt, speedStr
					}
				}
			}
		}
	}

	return false, -1, "—"
}

func calculateSpeed(rttMs int, packetSize int) string {
	if rttMs <= 0 {
		return "≥ 1.0 Gbps"
	}
	if rttMs == 1 {
		return "~850 Mbps"
	}
	if rttMs <= 3 {
		return "~500 Mbps"
	}
	if rttMs <= 6 {
		return "~250 Mbps"
	}
	if rttMs <= 15 {
		return "~100 Mbps"
	}
	if rttMs <= 40 {
		return "~45 Mbps"
	}
	if rttMs <= 100 {
		return "~20 Mbps"
	}
	if rttMs <= 250 {
		return "~8.5 Mbps"
	}
	return "~3.2 Mbps"
}

func resolveVendor(mac string) string {
	if len(mac) >= 8 {
		prefix := mac[:8]
		if v, ok := knownOUI[prefix]; ok {
			return v
		}
	}
	return ""
}

func guessTypeAndFormatFingerprint(vendor, hostname, banner string, openPorts []string, ipStr string) (string, string) {
	combined := strings.ToLower(vendor + " " + hostname + " " + banner + " " + strings.Join(openPorts, " "))

	typeIcon := "👻 🕵️ Ghost Node"
	if vendor != "" {
		typeIcon = "💻 📦 Network Device"
	}

	// 1. Gateway / Router (Highest precedence for network core)
	if strings.Contains(combined, "gateway") || strings.Contains(combined, "router") || strings.Contains(combined, "archer") || strings.Contains(combined, "c80") || strings.Contains(combined, "mikrotik") || strings.Contains(combined, "8291") || ipStr == "192.168.33.5" || ipStr == "192.168.33.6" || ipStr == "192.168.33.1" {
		typeIcon = "👑 🌐 Gateway / Router"
	// 2. Apple Devices (iPhone, iPad, Mac, Apple TV)
	} else if strings.Contains(combined, "apple") || strings.Contains(combined, "iphone") || strings.Contains(combined, "ipad") || strings.Contains(combined, "ios") || strings.Contains(combined, "62078") || strings.Contains(combined, "airplay") {
		if strings.Contains(combined, "ipad") {
			typeIcon = "📱 🍎 Apple iPad"
		} else if strings.Contains(combined, "macbook") || strings.Contains(combined, "imac") || strings.Contains(combined, "mac os") {
			typeIcon = "💻 🍎 Apple Mac"
		} else {
			typeIcon = "📱 🍎 Apple iPhone"
		}
	// 3. Smartphones / Mobile Devices (Android & Private MACs)
	} else if strings.Contains(combined, "honor") || strings.Contains(combined, "huawei") || strings.Contains(combined, "infinix") || strings.Contains(combined, "transsion") || strings.Contains(combined, "xiaomi") || strings.Contains(combined, "redmi") || strings.Contains(combined, "pixel") || strings.Contains(combined, "galaxy") || strings.Contains(combined, "mobile") || strings.Contains(combined, "smartphone") || strings.Contains(combined, "randomized private mac") {
		typeIcon = "📱 📶 Smartphone"
	// 4. IP Cameras & Surveillance
	} else if strings.Contains(combined, "rtsp") || strings.Contains(combined, "554") || strings.Contains(combined, "camera") || strings.Contains(combined, "tuya smart (ip camera") || strings.Contains(combined, "wi-fi camera") || strings.Contains(combined, "cam") {
		typeIcon = "📹 👁️ IP Camera"
	// 5. Smart TVs & Media Players
	} else if strings.Contains(combined, "tv") || strings.Contains(combined, "samsung") || strings.Contains(combined, "lg") || strings.Contains(combined, "8008") || strings.Contains(combined, "cast") || strings.Contains(combined, "webos") || strings.Contains(combined, "tizen") || strings.Contains(combined, "chromecast") {
		typeIcon = "📺 🎬 Smart TV"
	// 6. Smart IoT Nodes & Smart Home Sensors
	} else if strings.Contains(combined, "esp") || strings.Contains(combined, "espressif") || strings.Contains(combined, "iot") || strings.Contains(combined, "smart home") || strings.Contains(combined, "smart iot") || strings.Contains(combined, "smart appliance") {
		typeIcon = "⚡ 🔌 Smart IoT Node"
	// 7. Network Access Points & Mesh Nodes (Explicit matching without substring bugs)
	} else if strings.Contains(combined, "access point") || strings.Contains(combined, "wireless ap") || strings.Contains(combined, "mercusys (access point)") || strings.Contains(combined, "unifi") || strings.Contains(combined, "tl-wr") || strings.Contains(combined, "wap") || ipStr == "192.168.33.8" || ipStr == "192.168.33.2" || ipStr == "192.168.33.3" {
		typeIcon = "📡 📶 Access Point"
	// 8. Network Printers
	} else if strings.Contains(combined, "printer") || strings.Contains(combined, "laserjet") || strings.Contains(combined, "9100") || strings.Contains(combined, "officejet") || strings.Contains(combined, "deskjet") {
		typeIcon = "🖨️ 📄 Network Printer"
	// 9. NAS Servers & Storage
	} else if strings.Contains(combined, "synology") || strings.Contains(combined, "qnap") || strings.Contains(combined, "diskstation") || strings.Contains(combined, "nas") || strings.Contains(combined, "5000") {
		typeIcon = "💻 🗄️ NAS Server"
	// 10. PC / Workstations
	} else if strings.Contains(combined, "pc") || strings.Contains(combined, "workstation") || strings.Contains(combined, "3389") || strings.Contains(combined, "445") || strings.Contains(combined, "intel") || strings.Contains(combined, "windows") || strings.Contains(combined, "desktop") || strings.Contains(combined, "laptop") {
		typeIcon = "💻 🖥️ PC / Workstation"
	// 11. Virtual Machines
	} else if strings.Contains(combined, "vmware") || strings.Contains(combined, "hyper-v") || strings.Contains(combined, "virtual") {
		typeIcon = "💻 ☁️ Virtual Machine"
	}

	var parts []string
	if vendor != "" {
		parts = append(parts, vendor)
	} else {
		parts = append(parts, "Ghost Node (Stealth / Unknown OUI)")
	}

	if banner != "" && banner != hostname {
		parts = append(parts, fmt.Sprintf("Model: %s", banner))
	}

	if len(openPorts) > 0 {
		sort.Strings(openPorts)
		parts = append(parts, fmt.Sprintf("Ports: [%s]", strings.Join(openPorts, ", ")))
	}

	fingerprint := strings.Join(parts, " | ")
	return typeIcon, fingerprint
}

func addListViewItem(d DeviceInfo) {
	rowIdx := d.Index - 1

	item := LVITEMW{
		Mask:     0x0001 | 0x0004,
		IItem:    int32(rowIdx),
		ISubItem: 0,
		PszText:  strPtr(fmt.Sprintf("%d", d.Index)),
	}
	procSendMessageW.Call(hwndListView, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&item)))

	subitems := []string{
		d.TypeIcon,
		d.IP,
		d.Hostname,
		d.MAC,
		d.PingTime,
		d.Speed,
		d.Fingerprint,
	}

	for colIdx, text := range subitems {
		subItem := LVITEMW{
			Mask:     0x0001,
			IItem:    int32(rowIdx),
			ISubItem: int32(colIdx + 1),
			PszText:  strPtr(text),
		}
		procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(rowIdx), uintptr(unsafe.Pointer(&subItem)))
	}
}

func autoFitListViewColumns() {
	for colIdx := 0; colIdx < 8; colIdx++ {
		procSendMessageW.Call(hwndListView, LVM_SETCOLUMNWIDTH, uintptr(colIdx), LVSCW_AUTOSIZE)
		w, _, _ := procSendMessageW.Call(hwndListView, LVM_GETCOLUMNWIDTH, uintptr(colIdx), 0)
		procSendMessageW.Call(hwndListView, LVM_SETCOLUMNWIDTH, uintptr(colIdx), w+16)
	}
}

func queryQuickDNS(ipStr string) string {
	resChan := make(chan string, 1)
	go func() {
		names, err := net.LookupAddr(ipStr)
		if err == nil && len(names) > 0 {
			resChan <- strings.TrimSuffix(names[0], ".")
			return
		}
		resChan <- "—"
	}()

	select {
	case name := <-resChan:
		return name
	case <-time.After(30 * time.Millisecond):
		return "—"
	}
}

func startScanThread() {
	scanMutex.Lock()
	if isScanning {
		scanMutex.Unlock()
		return
	}
	isScanning = true
	stopScanFlag = false
	scanMutex.Unlock()

	procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
	procSendMessageW.Call(hwndProgress, PBM_SETPOS, 0, 0)
	procEnableWindow.Call(hwndBtnStart, 0)
	procEnableWindow.Call(hwndBtnDeepScan, 0)
	procEnableWindow.Call(hwndBtnScanPorts, 0)
	procEnableWindow.Call(hwndBtnStop, 1)

	ipFromStr := getControlText(hwndIPFrom)
	ipToStr := getControlText(hwndIPTo)
	timeoutStr := getComboSelectedText(hwndTimeout)
	packetStr := getComboSelectedText(hwndPacket)
	threadsStr := getComboSelectedText(hwndThreads)

	timeoutMs := extractFirstInt(timeoutStr, 1000)
	if timeoutMs < 100 || timeoutMs > 10000 {
		timeoutMs = 1000
	}

	packetSize := extractFirstInt(packetStr, 1472)
	if packetSize > 1472 {
		packetSize = 1472
	}
	if packetSize < 32 {
		packetSize = 32
	}

	threadCount := extractFirstInt(threadsStr, 100)
	if threadCount < 1 || threadCount > 250 {
		threadCount = 100
	}

	ipStart, err1 := parseIPv4(ipFromStr)
	ipEnd, err2 := parseIPv4(ipToStr)
	if err1 != nil || err2 != nil || ipStart > ipEnd {
		subs := detectAllSubnets()
		if len(subs) == 0 {
			setControlText(hwndStatus, "😢 Error: No active network adapter found. Please connect to a Wi-Fi or Ethernet network.")
			scanMutex.Lock()
			isScanning = false
			scanMutex.Unlock()
			procEnableWindow.Call(hwndBtnStart, 0)
			procEnableWindow.Call(hwndBtnStop, 0)
			return
		}
		activeSub := subs[0].Subnet
		ipStart, _ = parseIPv4(fmt.Sprintf("%s.0", activeSub))
		ipEnd, _ = parseIPv4(fmt.Sprintf("%s.255", activeSub))
	}

	total := int(ipEnd - ipStart + 1)
	atomic.StoreInt32(&totalHosts, int32(total))
	atomic.StoreInt32(&progressCount, 0)
	atomic.StoreInt32(&foundCount, 0)
	procSendMessageW.Call(hwndProgress, PBM_SETRANGE, 0, uintptr((total<<16)|0))

	devicesMutex.Lock()
	foundDevices = nil
	devicesMutex.Unlock()

	go func() {
		spinChars := []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
		i := 0
		for {
			scanMutex.Lock()
			scanning := isScanning
			scanMutex.Unlock()
			if !scanning {
				break
			}
			curProg := atomic.LoadInt32(&progressCount)
			curFound := atomic.LoadInt32(&foundCount)
			spin := spinChars[i%len(spinChars)]
			setControlText(hwndStatus, fmt.Sprintf("%s Fast ARP & Latency Scan: %d / %d hosts (%d active found)...", spin, curProg, total, curFound))
			i++
			time.Sleep(100 * time.Millisecond)
		}
	}()

	go func(start, end uint32, tMs, pSize, workers int) {
		startTime := time.Now()
		currentTimeStr := time.Now().Format("15:04:05")

		arpMap := readARPTable()

		type scanTarget struct {
			ipNum uint32
			ipStr string
		}

		jobs := make(chan scanTarget, total)
		results := make(chan DeviceInfo, total)

		var wg sync.WaitGroup

		for w := 0; w < workers; w++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for target := range jobs {
					scanMutex.Lock()
					stop := stopScanFlag
					scanMutex.Unlock()
					if stop {
						atomic.AddInt32(&progressCount, 1)
						cur := atomic.LoadInt32(&progressCount)
						procSendMessageW.Call(hwndProgress, PBM_SETPOS, uintptr(cur), 0)
						continue
					}

					// 1. Hardware ARP Request (2 fast retries)
					arpOk, mac := sendHardwareARP(target.ipNum)
					if !arpOk {
						time.Sleep(10 * time.Millisecond)
						arpOk, mac = sendHardwareARP(target.ipNum)
					}
					if !arpOk {
						if m, exists := arpMap[target.ipStr]; exists {
							mac = m
							arpOk = true
						}
					}

					// 2. Measure ICMP Echo Latency & Speed
					icmpOk, rtt, speedStr := probeHostICMP(target.ipStr, tMs, pSize)

					alive := arpOk || icmpOk

					if alive {
						vendor := resolveVendor(mac)
						hostname := queryQuickDNS(target.ipStr)
						icon, fingerprint := guessTypeAndFormatFingerprint(vendor, hostname, "", nil, target.ipStr)

						pingDisplay := "0 ms"
						if rtt >= 0 {
							pingDisplay = fmt.Sprintf("%d ms", rtt)
						} else {
							pingDisplay = "< 1 ms"
							speedStr = "≥ 1.0 Gbps"
						}

						dev := DeviceInfo{
							IP:          target.ipStr,
							Hostname:    hostname,
							MAC:         mac,
							PingTime:    pingDisplay,
							Speed:       speedStr,
							Fingerprint: fingerprint,
							TypeIcon:    icon,
							RawIPNum:    target.ipNum,
							IsOnline:    true,
							LastSeen:    currentTimeStr,
						}
						results <- dev
						atomic.AddInt32(&foundCount, 1)

						// Save to session history cache
						historyMutex.Lock()
						sessionDeviceHistory[target.ipStr] = dev
						historyMutex.Unlock()
					}

					atomic.AddInt32(&progressCount, 1)
					cur := atomic.LoadInt32(&progressCount)
					procSendMessageW.Call(hwndProgress, PBM_SETPOS, uintptr(cur), 0)
				}
			}()
		}

		for ipNum := start; ipNum <= end; ipNum++ {
			jobs <- scanTarget{ipNum: ipNum, ipStr: formatIPv4(ipNum)}
		}
		close(jobs)

		wg.Wait()
		close(results)

		// Collect active devices
		var collected []DeviceInfo
		currentActiveIPs := make(map[string]bool)

		for dev := range results {
			collected = append(collected, dev)
			currentActiveIPs[dev.IP] = true
		}

		// Check Session History for devices that went OFFLINE (Grayed-out / Lost Nodes)
		historyMutex.Lock()
		for histIP, histDev := range sessionDeviceHistory {
			histNum, err := parseIPv4(histIP)
			if err == nil && histNum >= start && histNum <= end {
				if !currentActiveIPs[histIP] {
					offlineDev := DeviceInfo{
						IP:          histDev.IP,
						Hostname:    histDev.Hostname,
						MAC:         histDev.MAC,
						PingTime:    "Offline",
						Speed:       "0 Mbps",
						Fingerprint: fmt.Sprintf("💤 [Offline / Last seen %s] %s", histDev.LastSeen, histDev.Fingerprint),
						TypeIcon:    "💤 📴 Disconnected Node",
						RawIPNum:    histDev.RawIPNum,
						IsOnline:    false,
						LastSeen:    histDev.LastSeen,
					}
					collected = append(collected, offlineDev)
				}
			}
		}
		historyMutex.Unlock()

		sort.Slice(collected, func(i, j int) bool {
			return collected[i].RawIPNum < collected[j].RawIPNum
		})

		for i := range collected {
			collected[i].Index = i + 1
		}

		devicesMutex.Lock()
		foundDevices = collected
		devicesMutex.Unlock()

		dur := time.Since(startTime)
		scanMutex.Lock()
		isScanning = false
		scanMutex.Unlock()

		activeCount := len(currentActiveIPs)
		offlineCount := len(collected) - activeCount
		procSendMessageW.Call(hwndMain, WM_APP_SCAN_DONE, uintptr(activeCount), uintptr((offlineCount<<16)|int(dur.Milliseconds()/10)))
	}(ipStart, ipEnd, timeoutMs, packetSize, threadCount)
}

func startDeepScanThread() {
	devicesMutex.Lock()
	if len(foundDevices) == 0 {
		devicesMutex.Unlock()
		setControlText(hwndStatus, "⚠️ No devices in the list. Run '▶ Start Scan' first.")
		return
	}
	devCount := len(foundDevices)
	devicesMutex.Unlock()

	scanMutex.Lock()
	if isScanning {
		scanMutex.Unlock()
		return
	}
	isScanning = true
	stopScanFlag = false
	scanMutex.Unlock()

	procEnableWindow.Call(hwndBtnStart, 0)
	procEnableWindow.Call(hwndBtnDeepScan, 0)
	procEnableWindow.Call(hwndBtnScanPorts, 0)
	procEnableWindow.Call(hwndBtnStop, 1)

	go func() {
		defer func() {
			scanMutex.Lock()
			isScanning = false
			scanMutex.Unlock()
			procEnableWindow.Call(hwndBtnStart, 1)
			procEnableWindow.Call(hwndBtnDeepScan, 1)
			procEnableWindow.Call(hwndBtnScanPorts, 1)
			procEnableWindow.Call(hwndBtnStop, 0)
		}()

		updatedCount := 0
		for i := 0; i < devCount; i++ {
			scanMutex.Lock()
			if stopScanFlag {
				scanMutex.Unlock()
				setControlText(hwndStatus, "Deep scan stopped by user.")
				return
			}
			scanMutex.Unlock()

			devicesMutex.Lock()
			dev := foundDevices[i]
			devicesMutex.Unlock()

			if !dev.IsOnline {
				continue
			}

			setControlText(hwndStatus, fmt.Sprintf("🔬 Deep Probing: Device %d/%d (%s)...", i+1, devCount, dev.IP))

			hostname, banner, openPorts := deepFingerprintHost(dev.IP)
			vendor := resolveVendor(dev.MAC)
			newIcon, newFingerprint := guessTypeAndFormatFingerprint(vendor, hostname, banner, openPorts, dev.IP)

			devicesMutex.Lock()
			if hostname != "" && hostname != "—" {
				foundDevices[i].Hostname = hostname
			}
			foundDevices[i].TypeIcon = newIcon
			foundDevices[i].Fingerprint = newFingerprint
			devUpdated := foundDevices[i]
			devicesMutex.Unlock()

			sub1 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 1, PszText: strPtr(devUpdated.TypeIcon)}
			procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&sub1)))

			sub3 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 3, PszText: strPtr(devUpdated.Hostname)}
			procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&sub3)))

			sub7 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 7, PszText: strPtr(devUpdated.Fingerprint)}
			procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&sub7)))

			updatedCount++
		}

		autoFitListViewColumns()
		setControlText(hwndStatus, fmt.Sprintf("Ready. Deep scan complete across %d active devices (mDNS Bonjour, Apple ID & NetBIOS).", updatedCount))
	}()
}

func startPortScanAllThread() {
	devicesMutex.Lock()
	if len(foundDevices) == 0 {
		devicesMutex.Unlock()
		setControlText(hwndStatus, "⚠️ No devices in the list. Run '▶ Start Scan' first.")
		return
	}
	devCount := len(foundDevices)
	devicesMutex.Unlock()

	scanMutex.Lock()
	if isScanning {
		scanMutex.Unlock()
		return
	}
	isScanning = true
	stopScanFlag = false
	scanMutex.Unlock()

	procEnableWindow.Call(hwndBtnStart, 0)
	procEnableWindow.Call(hwndBtnDeepScan, 0)
	procEnableWindow.Call(hwndBtnScanPorts, 0)
	procEnableWindow.Call(hwndBtnStop, 1)

	go func() {
		defer func() {
			scanMutex.Lock()
			isScanning = false
			scanMutex.Unlock()
			procEnableWindow.Call(hwndBtnStart, 1)
			procEnableWindow.Call(hwndBtnDeepScan, 1)
			procEnableWindow.Call(hwndBtnScanPorts, 1)
			procEnableWindow.Call(hwndBtnStop, 0)
		}()

		totalOpenFound := 0

		for i := 0; i < devCount; i++ {
			scanMutex.Lock()
			if stopScanFlag {
				scanMutex.Unlock()
				setControlText(hwndStatus, "Port scan stopped by user.")
				return
			}
			scanMutex.Unlock()

			devicesMutex.Lock()
			dev := foundDevices[i]
			devicesMutex.Unlock()

			if !dev.IsOnline {
				continue
			}

			setControlText(hwndStatus, fmt.Sprintf("🔍 Auditing open ports: Host %d/%d (%s)...", i+1, devCount, dev.IP))

			var openPorts []string
			var pWg sync.WaitGroup
			var pMu sync.Mutex
			sem := make(chan struct{}, 15)

			for _, p := range commonPortsToScan {
				pWg.Add(1)
				go func(portNum int, svcName string) {
					defer pWg.Done()
					sem <- struct{}{}
					defer func() { <-sem }()

					addr := fmt.Sprintf("%s:%d", dev.IP, portNum)
					conn, err := net.DialTimeout("tcp", addr, 150*time.Millisecond)
					if err == nil {
						conn.Close()
						pMu.Lock()
						openPorts = append(openPorts, fmt.Sprintf("%s:%d", svcName, portNum))
						pMu.Unlock()
					}
				}(p.Port, p.Name)
			}
			pWg.Wait()

			if len(openPorts) > 0 {
				totalOpenFound += len(openPorts)
				vendor := resolveVendor(dev.MAC)
				newIcon, newFingerprint := guessTypeAndFormatFingerprint(vendor, dev.Hostname, "", openPorts, dev.IP)

				devicesMutex.Lock()
				foundDevices[i].TypeIcon = newIcon
				foundDevices[i].Fingerprint = newFingerprint
				devicesMutex.Unlock()

				sub1 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 1, PszText: strPtr(newIcon)}
				procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&sub1)))

				sub7 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 7, PszText: strPtr(newFingerprint)}
				procSendMessageW.Call(hwndListView, LVM_SETITEMTEXTW, uintptr(i), uintptr(unsafe.Pointer(&sub7)))
			}
		}

		autoFitListViewColumns()
		setControlText(hwndStatus, fmt.Sprintf("Ready. Port audit completed across %d hosts (%d open services found). Click 'Save Log' to export.", devCount, totalOpenFound))
	}()
}

func exportReport() {
	devicesMutex.Lock()
	devs := make([]DeviceInfo, len(foundDevices))
	copy(devs, foundDevices)
	devicesMutex.Unlock()

	desktopDir := `D:\MEGA\DOCS\desktop`
	if _, err := os.Stat(desktopDir); os.IsNotExist(err) {
		homeDir, _ := os.UserHomeDir()
		desktopDir = filepath.Join(homeDir, "Desktop")
	}
	reportFile := filepath.Join(desktopDir, "Network_Deep_Audit_Report.txt")

	var reportLines []string
	reportLines = append(reportLines, "=========================================================================================================")
	reportLines = append(reportLines, "                               GIN-NetScan Deep Network Inventory Audit Report                           ")
	reportLines = append(reportLines, fmt.Sprintf("Date: %s   Total Nodes: %d   Engine & Author: VladiMIR+AI", time.Now().Format("2006-01-02 15:04:05"), len(devs)))
	reportLines = append(reportLines, "=========================================================================================================")
	reportLines = append(reportLines, "")

	if len(devs) == 0 {
		reportLines = append(reportLines, "No devices discovered in the scanned network range.")
	} else {
		for _, d := range devs {
			statusTag := "ONLINE"
			if !d.IsOnline {
				statusTag = "OFFLINE"
			}
			host := d.Hostname
			if host == "" || host == "—" {
				host = "None"
			}

			reportLines = append(reportLines, fmt.Sprintf("[%d] IP Address:  %s  (%s)", d.Index, d.IP, statusTag))
			reportLines = append(reportLines, fmt.Sprintf("    Device Type: %s", d.TypeIcon))
			reportLines = append(reportLines, fmt.Sprintf("    Host Name:   %s", host))
			reportLines = append(reportLines, fmt.Sprintf("    MAC Address: %s", d.MAC))
			reportLines = append(reportLines, fmt.Sprintf("    Latency RTT: %s   Speed: %s", d.PingTime, d.Speed))
			reportLines = append(reportLines, fmt.Sprintf("    Fingerprint: %s", d.Fingerprint))
			reportLines = append(reportLines, "---------------------------------------------------------------------------------------------------------")
		}
	}

	reportLines = append(reportLines, "")
	reportLines = append(reportLines, "=========================================================================================================")
	reportLines = append(reportLines, "                  GIN-NetScan by VladiMIR+AI (GinCz)  -  100% Free & Open Source                         ")
	reportLines = append(reportLines, "                  GitHub Repository: https://github.com/GinCz/Linux_Server_Public                        ")
	reportLines = append(reportLines, "=========================================================================================================")

	bom := []byte{0xEF, 0xBB, 0xBF}
	content := append(bom, []byte(strings.Join(reportLines, "\r\n"))...)

	os.WriteFile(reportFile, content, 0644)
	setControlText(hwndStatus, fmt.Sprintf("Log successfully saved and opened: %s", reportFile))

	exec.Command("cmd.exe", "/c", "start", "", reportFile).Start()
}

func showContextMenu(x, y int32) {
	selIdx, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	if int32(selIdx) < 0 {
		return
	}

	devicesMutex.Lock()
	if int(selIdx) >= len(foundDevices) {
		devicesMutex.Unlock()
		return
	}
	selectedDevice = foundDevices[selIdx]
	dev := selectedDevice
	devicesMutex.Unlock()

	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	defer procDestroyMenu.Call(hMenu)

	procAppendMenuW.Call(hMenu, MF_STRING, 2001, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("📋 Copy IP Address:  %s", dev.IP)))))
	if dev.Hostname != "" && dev.Hostname != "—" {
		procAppendMenuW.Call(hMenu, MF_STRING, 2002, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("📋 Copy Host Name:   %s", dev.Hostname)))))
	}
	if dev.MAC != "" {
		procAppendMenuW.Call(hMenu, MF_STRING, 2003, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("📋 Copy MAC Address: %s", dev.MAC)))))
	}
	if dev.Fingerprint != "" {
		procAppendMenuW.Call(hMenu, MF_STRING, 2004, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("📋 Copy Device Info: %s", dev.Fingerprint)))))
	}
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, 2005, uintptr(unsafe.Pointer(strPtr("📑 Copy All Info (Multiline)"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, 2008, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("🔍 Scan All Open Ports for %s", dev.IP)))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, 2006, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("🌐 Open Web Browser (http://%s)", dev.IP)))))
	procAppendMenuW.Call(hMenu, MF_STRING, 2007, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("⚡ Ping %s in Command Prompt", dev.IP)))))

	if x == -1 && y == -1 {
		var pt POINT
		procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
		x, y = pt.X, pt.Y
	}

	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(x), uintptr(y), 0, hwndMain, 0)
}

var commonPortsToScan = []struct {
	Port int
	Name string
}{
	{21, "FTP (File Transfer)"},
	{22, "SSH (Secure Shell)"},
	{23, "Telnet (Remote CLI)"},
	{25, "SMTP (Mail Server)"},
	{53, "DNS (Domain Name)"},
	{80, "HTTP (Web Server)"},
	{110, "POP3 (Mail Client)"},
	{135, "MSRPC (Windows RPC)"},
	{139, "NetBIOS-SSN (SMB)"},
	{143, "IMAP (Mail Client)"},
	{443, "HTTPS (Secure Web)"},
	{445, "SMB / Microsoft-DS"},
	{554, "RTSP (IP Camera Video)"},
	{993, "IMAPS (Secure Mail)"},
	{995, "POP3S (Secure Mail)"},
	{1433, "MS-SQL Server"},
	{1521, "Oracle Database"},
	{1723, "PPTP VPN"},
	{1883, "MQTT (IoT Broker)"},
	{3306, "MySQL / MariaDB"},
	{3389, "RDP (Remote Desktop)"},
	{5000, "UPnP / Synology DSM"},
	{5432, "PostgreSQL Database"},
	{5900, "VNC (Remote Display)"},
	{6379, "Redis Key-Value DB"},
	{7000, "Apple AirPlay Streaming"},
	{8000, "HTTP-Alt / Dev Server"},
	{8080, "HTTP-Proxy / Tomcat"},
	{8443, "HTTPS-Alt / Admin"},
	{8888, "HTTP-Alt / Admin GUI"},
	{9000, "Portainer / SonarQube"},
	{9090, "Cockpit Web Admin"},
	{9100, "Raw JetDirect Printer"},
	{9200, "Elasticsearch"},
	{27017, "MongoDB Database"},
	{62078, "Apple Mobile Device Sync"},
}

func portScanWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		if controlId == 4001 || controlId == 2 {
			procDestroyWindow.Call(hwnd)
			hwndPortScan = 0
			return 0
		}
		if controlId == 4002 {
			itemCount, _, _ := procSendMessageW.Call(hwndPortList, 0x1004 /* LVM_GETITEMCOUNT */, 0, 0)
			var lines []string
			lines = append(lines, fmt.Sprintf("=== Open Ports Audit Report: %s (%s) ===", portScanTargetIP, portScanTargetHost))
			lines = append(lines, fmt.Sprintf("Generated: %s | Tool: GIN-NetScan by VladiMIR+AI", time.Now().Format("2006-01-02 15:04:05")))
			lines = append(lines, "")
			for i := 0; i < int(itemCount); i++ {
				buf0 := make([]uint16, 64)
				item0 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 0, PszText: &buf0[0], CchTextMax: 64}
				procSendMessageW.Call(hwndPortList, 0x1073, uintptr(i), uintptr(unsafe.Pointer(&item0)))

				buf1 := make([]uint16, 64)
				item1 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 1, PszText: &buf1[0], CchTextMax: 64}
				procSendMessageW.Call(hwndPortList, 0x1073, uintptr(i), uintptr(unsafe.Pointer(&item1)))

				buf2 := make([]uint16, 64)
				item2 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 2, PszText: &buf2[0], CchTextMax: 64}
				procSendMessageW.Call(hwndPortList, 0x1073, uintptr(i), uintptr(unsafe.Pointer(&item2)))

				buf3 := make([]uint16, 256)
				item3 := LVITEMW{Mask: 0x0001, IItem: int32(i), ISubItem: 3, PszText: &buf3[0], CchTextMax: 256}
				procSendMessageW.Call(hwndPortList, 0x1073, uintptr(i), uintptr(unsafe.Pointer(&item3)))

				lines = append(lines, fmt.Sprintf("Port: %-7s  Service: %-24s  State: %-6s  Info: %s",
					syscall.UTF16ToString(buf0), syscall.UTF16ToString(buf1), syscall.UTF16ToString(buf2), syscall.UTF16ToString(buf3)))
			}
			copyToClipboard(strings.Join(lines, "\r\n"))
			setControlText(hwndPortStatus, "Copied open ports audit to clipboard!")
			return 0
		}
	case WM_DESTROY:
		hwndPortScan = 0
		return 0
	}
	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func showPortScanDialog(targetIP, hostname string) {
	if targetIP == "" {
		return
	}
	portScanTargetIP = targetIP
	portScanTargetHost = hostname
	if portScanTargetHost == "" || portScanTargetHost == "—" {
		portScanTargetHost = "Generic Host"
	}

	classNamePort := strPtr("GINNetScanPortScannerWindow")
	var wcPort WNDCLASSEXW
	wcPort.CbSize = uint32(unsafe.Sizeof(wcPort))
	wcPort.Style = 0x0002 | 0x0001
	wcPort.LpfnWndProc = syscall.NewCallback(portScanWndProc)
	wcPort.HInstance = hInstance
	wcPort.HIcon = hIconApp
	wcPort.HIconSm = hIconApp
	wcPort.HbrBackground = hBrushWhite
	wcPort.LpszClassName = classNamePort
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcPort)))

	title := fmt.Sprintf("Port Scanner — %s (%s)", targetIP, portScanTargetHost)
	hwndPortRet, _, _ := procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(classNamePort)),
		uintptr(unsafe.Pointer(strPtr(title))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		140, 140, 590, 490,
		hwndMain, 0, hInstance, 0,
	)
	hwndPortScan = hwndPortRet
	if hIconApp != 0 {
		procSendMessageW.Call(hwndPortScan, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndPortScan, WM_SETICON, 0, hIconApp)
	}

	// Header
	hHeader, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("🔍 Deep Port Audit for Host: %s (%s)", targetIP, portScanTargetHost)))),
		WS_CHILD|WS_VISIBLE,
		15, 12, 545, 22,
		hwndPortScan, 0, hInstance, 0,
	)
	procSendMessageW.Call(hHeader, WM_SETFONT, hFontBold, 1)

	// ListView
	hwndPortListRet, _, _ := procCreateWindowExW.Call(
		0x00000200, uintptr(unsafe.Pointer(strPtr("SysListView32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS,
		15, 38, 545, 350,
		hwndPortScan, 0, hInstance, 0,
	)
	hwndPortList = hwndPortListRet
	procSendMessageW.Call(hwndPortList, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER)
	procSendMessageW.Call(hwndPortList, WM_SETFONT, hFontSegoe, 1)

	portCols := []struct {
		Title string
		Width int32
	}{
		{"Port", 65},
		{"Service", 155},
		{"State", 65},
		{"Banner / Details", 240},
	}
	for i, col := range portCols {
		lvc := LVCOLUMNW{
			Mask:    0x0001 | 0x0002 | 0x0004,
			Fmt:     0,
			Cx:      col.Width,
			PszText: strPtr(col.Title),
		}
		procSendMessageW.Call(hwndPortList, LVM_INSERTCOLUMNW, uintptr(i), uintptr(unsafe.Pointer(&lvc)))
	}

	// Status Label
	hwndPortStatusRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Scanning ports..."))),
		WS_CHILD|WS_VISIBLE,
		15, 405, 340, 24,
		hwndPortScan, 0, hInstance, 0,
	)
	hwndPortStatus = hwndPortStatusRet
	procSendMessageW.Call(hwndPortStatus, WM_SETFONT, hFontSegoe, 1)

	// Button: Copy Port Report
	hBtnCopy, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📋 Copy Results"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		365, 400, 120, 28,
		hwndPortScan, 4002, hInstance, 0,
	)
	procSendMessageW.Call(hBtnCopy, WM_SETFONT, hFontSegoe, 1)

	// Button: Close
	hBtnClose, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Close"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		495, 400, 65, 28,
		hwndPortScan, 4001, hInstance, 0,
	)
	procSendMessageW.Call(hBtnClose, WM_SETFONT, hFontSegoe, 1)

	// Background Scanner Goroutine
	go func(target string) {
		type portResult struct {
			port    int
			service string
			details string
		}
		resChan := make(chan portResult, len(commonPortsToScan))
		var pwg sync.WaitGroup
		sem := make(chan struct{}, 15)

		for _, p := range commonPortsToScan {
			pwg.Add(1)
			go func(portNum int, svcName string) {
				defer pwg.Done()
				sem <- struct{}{}
				defer func() { <-sem }()

				addr := fmt.Sprintf("%s:%d", target, portNum)
				conn, err := net.DialTimeout("tcp", addr, 400*time.Millisecond)
				if err == nil {
					conn.Close()
					details := "Open / Listening"
					if portNum == 80 || portNum == 8080 || portNum == 8000 || portNum == 8888 || portNum == 9000 {
						details = "HTTP Web Service"
					} else if portNum == 443 || portNum == 8443 {
						details = "HTTPS SSL/TLS Encrypted"
					} else if portNum == 22 {
						details = "SSH Remote Terminal"
					} else if portNum == 3389 {
						details = "Microsoft RDP Remote Desktop"
					} else if portNum == 445 || portNum == 139 {
						details = "Windows SMB / File Sharing"
					} else if portNum == 554 {
						details = "RTSP Video Stream (IP Camera)"
					} else if portNum == 53 {
						details = "DNS Resolver Service"
					}
					resChan <- portResult{port: portNum, service: svcName, details: details}
				}
			}(p.Port, p.Name)
		}

		pwg.Wait()
		close(resChan)

		var openList []portResult
		for r := range resChan {
			openList = append(openList, r)
		}
		sort.Slice(openList, func(i, j int) bool {
			return openList[i].port < openList[j].port
		})

		for idx, r := range openList {
			item := LVITEMW{
				Mask:     0x0001,
				IItem:    int32(idx),
				ISubItem: 0,
				PszText:  strPtr(fmt.Sprintf("%d", r.port)),
			}
			procSendMessageW.Call(hwndPortList, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&item)))

			sub1 := LVITEMW{Mask: 0x0001, IItem: int32(idx), ISubItem: 1, PszText: strPtr(r.service)}
			procSendMessageW.Call(hwndPortList, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&sub1)))

			sub2 := LVITEMW{Mask: 0x0001, IItem: int32(idx), ISubItem: 2, PszText: strPtr("OPEN")}
			procSendMessageW.Call(hwndPortList, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&sub2)))

			sub3 := LVITEMW{Mask: 0x0001, IItem: int32(idx), ISubItem: 3, PszText: strPtr(r.details)}
			procSendMessageW.Call(hwndPortList, LVM_SETITEMTEXTW, uintptr(idx), uintptr(unsafe.Pointer(&sub3)))
		}

		if len(openList) == 0 {
			setControlText(hwndPortStatus, "No open ports found.")
		} else if len(openList) == 1 {
			setControlText(hwndPortStatus, "Found 1 Open Port.")
		} else {
			setControlText(hwndPortStatus, fmt.Sprintf("Found %d Open Ports.", len(openList)))
		}
	}(targetIP)
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
			exec.Command("cmd.exe", "/c", "start", "https://github.com/GinCz").Start()
			return 0
		}

	case WM_DESTROY:
		procKillTimer.Call(hwnd, 1)
		hwndAbout = 0
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func animWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))

		var rc RECT
		rc.Left, rc.Top, rc.Right, rc.Bottom = 0, 0, 380, 140
		procFillRect(hdc, &rc, hBrushBlack)

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

		hPenCyan, _, _ := procCreatePen.Call(0, 2, 0x00FFFF)
		hOldPen, _, _ := procSelectObject.Call(hdc, hPenCyan)

		for _, e := range edges {
			p1 := projected[e[0]]
			p2 := projected[e[1]]
			procMoveToEx.Call(hdc, uintptr(p1.X), uintptr(p1.Y), 0)
			procLineTo.Call(hdc, uintptr(p2.X), uintptr(p2.Y))
		}

		hBrushBlue, _, _ := procCreateSolidBrush.Call(0xFF9900)
		procSelectObject.Call(hdc, hBrushBlue)

		for _, p := range projected {
			procEllipse.Call(hdc, uintptr(p.X-4), uintptr(p.Y-4), uintptr(p.X+4), uintptr(p.Y+4))
		}

		procSelectObject.Call(hdc, hOldPen)
		procDeleteObject.Call(hPenCyan)
		procDeleteObject.Call(hBrushBlue)

		procEndPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func procFillRect(hdc uintptr, rc *RECT, hbr uintptr) {
	user32.NewProc("FillRect").Call(hdc, uintptr(unsafe.Pointer(rc)), hbr)
}

func showAboutDialog() {
	if hwndAbout != 0 {
		procShowWindow.Call(hwndAbout, 5)
		return
	}

	hInstance, _, _ := procGetModuleHandleW.Call(0)
	classNameAbout := strPtr("GINNetScanAboutWindow")
	classNameAnim := strPtr("GINNetScanAnimCanvas")

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

	hwndAboutRet, _, _ := procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(classNameAbout)),
		uintptr(unsafe.Pointer(strPtr("About GIN-NetScan"))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		200, 200, 420, 390,
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
		uintptr(unsafe.Pointer(strPtr("GIN NetScan by VladiMIR+AI__v016"))),
		WS_CHILD|WS_VISIBLE,
		15, 162, 375, 24,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hTitle, WM_SETFONT, hFontBold, 1)

	hSub, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Version: v016 (Public Release)  |  100% Free & Open Source\nEngine: Ultra-Fast Hardware SendARP & Multi-Service Probe\nAuthor: Vladimir Bulantsev (GinCz)"))),
		WS_CHILD|WS_VISIBLE,
		15, 190, 375, 55,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hSub, WM_SETFONT, hFontSegoe, 1)

	hLink, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🌐 Visit GitHub: https://github.com/GinCz"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		15, 252, 375, 28,
		hwndAbout, 3002, hInstance, 0,
	)
	procSendMessageW.Call(hLink, WM_SETFONT, hFontSegoe, 1)

	hOk, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("OK"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		150, 292, 100, 30,
		hwndAbout, 3001, hInstance, 0,
	)
	procSendMessageW.Call(hOk, WM_SETFONT, hFontSegoe, 1)

	procSetTimer.Call(hwndAbout, 1, 33, 0)
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		notificationCode := int((wParam >> 16) & 0xFFFF)

		if notificationCode == CBN_SELCHANGE {
			switch controlId {
			case 1000: // Subnet Combo
				selIdx, _, _ := procSendMessageW.Call(hwndComboSub, CB_GETCURSEL, 0, 0)
				if int(selIdx) >= 0 && int(selIdx) < len(detectedSubnets) {
					sub := detectedSubnets[selIdx]
					setControlText(hwndIPFrom, sub.RangeFrom)
					setControlText(hwndIPTo, sub.RangeTo)
					setControlText(hwndStatus, fmt.Sprintf("Selected subnet: %s (%s). Click '▶ Start Scan' to audit.", sub.Subnet, sub.Name))
				}
				return 0
			case 1010: // Timeout Combo
				selIdx, _, _ := procSendMessageW.Call(hwndTimeout, CB_GETCURSEL, 0, 0)
				switch selIdx {
				case 0:
					setControlText(hwndStatus, "⏱️ Timeout: 1000 ms (Standard) - Optimal balance for home & office Wi-Fi / Ethernet.")
				case 1:
					setControlText(hwndStatus, "⏱️ Timeout: 500 ms (Fast) - Rapid discovery for low-latency wired Ethernet networks.")
				case 2:
					setControlText(hwndStatus, "⏱️ Timeout: 1500 ms (Deep) - Higher tolerance for weak Wi-Fi, mesh repeaters & distant nodes.")
				case 3:
					setControlText(hwndStatus, "⏱️ Timeout: 2500 ms (Max) - Deep reach for battery-saving IoT devices & sleeping phones.")
				}
				return 0
			case 1011: // Packet Combo
				selIdx, _, _ := procSendMessageW.Call(hwndPacket, CB_GETCURSEL, 0, 0)
				switch selIdx {
				case 0:
					setControlText(hwndStatus, "📦 Packet: 1472 B (MTU) - Maximum non-fragmented Ethernet payload for precise bandwidth speed estimation.")
				case 1:
					setControlText(hwndStatus, "📦 Packet: 32 B (Ping) - Standard Windows echo ping; minimal network bandwidth footprint.")
				case 2:
					setControlText(hwndStatus, "📦 Packet: 64 B (Std) - Traditional Unix/Linux ping packet payload for lightweight latency testing.")
				case 3:
					setControlText(hwndStatus, "📦 Packet: 512 B (Mid) - Medium packet size for testing wireless throughput and link quality.")
				}
				return 0
			case 1012: // Threads Combo
				selIdx, _, _ := procSendMessageW.Call(hwndThreads, CB_GETCURSEL, 0, 0)
				switch selIdx {
				case 0:
					setControlText(hwndStatus, "⚡ Concurrency: 100 (Normal) - High-speed parallel host probing without router overload.")
				case 1:
					setControlText(hwndStatus, "⚡ Concurrency: 50 (Low) - Gentle scan; prevents congestion on weak or budget Wi-Fi routers.")
				case 2:
					setControlText(hwndStatus, "⚡ Concurrency: 150 (Turbo) - Maximum parallel throughput for high-performance Gigabit LANs.")
				}
				return 0
			}
		}

		switch controlId {
		case 1001: // Start Scan
			startScanThread()
		case 1002: // Stop
			scanMutex.Lock()
			stopScanFlag = true
			scanMutex.Unlock()
			setControlText(hwndStatus, "Scan stopped by user.")
			procEnableWindow.Call(hwndBtnStart, 1)
			procEnableWindow.Call(hwndBtnDeepScan, 1)
			procEnableWindow.Call(hwndBtnScanPorts, 1)
			procEnableWindow.Call(hwndBtnStop, 0)
		case 1003: // Save Log
			exportReport()
		case 1004: // Brand Label Clicked (Open 3D About Dialog)
			showAboutDialog()
		case 1005: // Scan All Open Ports
			startPortScanAllThread()
		case 1006: // Deep Scan Discovered Hosts
			startDeepScanThread()
		case 2001: // Copy IP
			copyToClipboard(selectedDevice.IP)
			setControlText(hwndStatus, fmt.Sprintf("Copied IP Address (%s) to clipboard.", selectedDevice.IP))
		case 2002: // Copy Hostname
			copyToClipboard(selectedDevice.Hostname)
			setControlText(hwndStatus, fmt.Sprintf("Copied Host Name (%s) to clipboard.", selectedDevice.Hostname))
		case 2003: // Copy MAC
			copyToClipboard(selectedDevice.MAC)
			setControlText(hwndStatus, fmt.Sprintf("Copied MAC Address (%s) to clipboard.", selectedDevice.MAC))
		case 2004: // Copy Fingerprint
			copyToClipboard(selectedDevice.Fingerprint)
			setControlText(hwndStatus, "Copied Device Fingerprint to clipboard.")
		case 2005: // Copy All Info (Multiline)
			statusStr := "ONLINE"
			if !selectedDevice.IsOnline {
				statusStr = "OFFLINE"
			}
			host := selectedDevice.Hostname
			if host == "" || host == "—" {
				host = "None"
			}
			cardText := fmt.Sprintf("IP Address:   %s\r\nDevice Type:  %s\r\nHost Name:    %s\r\nMAC Address:  %s\r\nLatency RTT:  %s\r\nSpeed:        %s\r\nFingerprint:  %s\r\nStatus:       %s",
				selectedDevice.IP,
				selectedDevice.TypeIcon,
				host,
				selectedDevice.MAC,
				selectedDevice.PingTime,
				selectedDevice.Speed,
				selectedDevice.Fingerprint,
				statusStr)
			copyToClipboard(cardText)
			setControlText(hwndStatus, fmt.Sprintf("Copied all info for %s to clipboard (multiline format).", selectedDevice.IP))
		case 2006: // Open Browser
			exec.Command("cmd.exe", "/c", "start", fmt.Sprintf("http://%s", selectedDevice.IP)).Start()
			setControlText(hwndStatus, fmt.Sprintf("Opening http://%s in web browser...", selectedDevice.IP))
		case 2007: // Ping in CMD
			exec.Command("cmd.exe", "/c", "start", "cmd.exe", "/k", fmt.Sprintf("ping -t %s", selectedDevice.IP)).Start()
			setControlText(hwndStatus, fmt.Sprintf("Started continuous ping for %s in Command Prompt.", selectedDevice.IP))
		case 2008: // Scan All Open Ports for Single Host
			showPortScanDialog(selectedDevice.IP, selectedDevice.Hostname)
			setControlText(hwndStatus, fmt.Sprintf("Opened Port Scanner for %s.", selectedDevice.IP))
		}
		return 0

	case WM_NOTIFY:
		nmhdr := (*NMHDR)(unsafe.Pointer(lParam))
		if nmhdr.HwndFrom == hwndListView && nmhdr.Code == NM_CUSTOMDRAW {
			pcd := (*NMLVCUSTOMDRAW)(unsafe.Pointer(lParam))
			if pcd.DwDrawStage == CDDS_PREPAINT {
				return CDRF_NOTIFYITEMDRAW
			}
			if pcd.DwDrawStage == CDDS_ITEMPREPAINT {
				itemIdx := int(pcd.DwItemSpec)
				devicesMutex.Lock()
				if itemIdx >= 0 && itemIdx < len(foundDevices) {
					if !foundDevices[itemIdx].IsOnline {
						pcd.ClrText = 0x888888 // Gray text color for offline / disconnected devices
					}
				}
				devicesMutex.Unlock()
				return CDRF_DODEFAULT
			}
		}
		return 0

	case WM_SETCURSOR:
		if uintptr(wParam) == hwndBrand {
			procSetCursor.Call(hCursorHand)
			return 1
		}

	case WM_CONTEXTMENU:
		if wParam == hwndListView {
			x := int32(lParam & 0xFFFF)
			y := int32((lParam >> 16) & 0xFFFF)
			showContextMenu(x, y)
			return 0
		}

	case WM_CTLCOLORSTATIC:
		hdc := wParam
		if uintptr(lParam) == hwndBrand {
			procSetBkMode.Call(hdc, 1)
			procSetTextColor.Call(hdc, 0xAA3300)
			return hBrushWhite
		}
		procSetBkMode.Call(hdc, 1)
		return hBrushWhite

	case WM_APP_SCAN_DONE:
		procEnableWindow.Call(hwndBtnStart, 1)
		procEnableWindow.Call(hwndBtnDeepScan, 1)
		procEnableWindow.Call(hwndBtnScanPorts, 1)
		procEnableWindow.Call(hwndBtnStop, 0)
		procSendMessageW.Call(hwndProgress, PBM_SETPOS, uintptr(atomic.LoadInt32(&totalHosts)), 0)

		devicesMutex.Lock()
		for _, d := range foundDevices {
			addListViewItem(d)
		}
		devicesMutex.Unlock()

		autoFitListViewColumns()

		activeCount := int(wParam)
		offlineCount := int((lParam >> 16) & 0xFFFF)
		durSec := float64(lParam&0xFFFF) / 100.0

		tipText := "💡 (Tip: Click '🔬 Deep Scan' for mDNS/Apple ID or '🔍 Scan Ports')"
		statusMsg := fmt.Sprintf("Ready. Found: %d active devices (%.2fs)   |||   %s   |||   Click 'Save Log' to export", activeCount, durSec, tipText)
		if offlineCount > 0 {
			statusMsg = fmt.Sprintf("Ready. Found: %d active + %d offline nodes (%.2fs)   |||   %s   |||   Click 'Save Log' to export", activeCount, offlineCount, durSec, tipText)
		}
		setControlText(hwndStatus, statusMsg)
		return 0

	case WM_DESTROY:
		procPostQuitMessage.Call(0)
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func main() {
	loadSessionHistoryFromDisk()

	// Set Below Normal Process Priority so network scanner never lags OS / CPU
	hCurProc, _, _ := procGetCurrentProcess.Call()
	procSetPriorityClass.Call(hCurProc, 0x00004000) // BELOW_NORMAL_PRIORITY_CLASS

	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x00000001 | 0x00000004 | 0x00000020
	procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))

	hInstanceRet, _, _ := procGetModuleHandleW.Call(0)
	hInstance = hInstanceRet
	className := strPtr("GINNetScanMainWindow")

	hBrushWhiteRet, _, _ := procGetStockObject.Call(0)
	hBrushWhite = hBrushWhiteRet

	hBrushBlackRet, _, _ := procGetStockObject.Call(4)
	hBrushBlack = hBrushBlackRet

	hIconAppRet, _, _ := procLoadIconW.Call(hInstance, uintptr(1))
	if hIconAppRet == 0 {
		hIconAppRet, _, _ = procLoadIconW.Call(hInstance, uintptr(101))
	}
	hIconApp = hIconAppRet
	hCursorHandRet, _, _ := procLoadCursorW.Call(0, uintptr(IDC_HAND))
	hCursorHand = hCursorHandRet

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.Style = 0x0002 | 0x0001
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconApp
	wc.HIconSm = hIconApp
	wc.HbrBackground = hBrushWhite
	wc.LpszClassName = className

	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hFontSegoeRet, _, _ := procCreateFontW.Call(
		uintptr(17), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	if hFontSegoeRet != 0 {
		hFontSegoe = hFontSegoeRet
	} else {
		hFontDefault, _, _ := procGetStockObject.Call(DEFAULT_GUI_FONT)
		hFontSegoe = hFontDefault
	}

	hFontBoldRet, _, _ := procCreateFontW.Call(
		uintptr(17), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	if hFontBoldRet != 0 {
		hFontBold = hFontBoldRet
	} else {
		hFontBold = hFontSegoe
	}

	detectedSubnets = detectAllSubnets()
	hasNoNetwork := len(detectedSubnets) == 0
	var activeSub SubnetInfo
	if hasNoNetwork {
		activeSub = SubnetInfo{
			Name:      "No Network Adapter",
			Subnet:    "",
			RangeFrom: "—",
			RangeTo:   "—",
		}
	} else {
		activeSub = detectedSubnets[0]
	}
	hasMultipleSubnets := len(detectedSubnets) > 1

	// Main Window (v016)
	hwndMainRet, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("GIN NetScan by VladiMIR+AI__v016"))),
		WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		40, 40, 1200, 680,
		0, 0, hInstance, 0,
	)
	hwndMain = hwndMainRet

	if hIconApp != 0 {
		procSendMessageW.Call(hwndMain, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndMain, WM_SETICON, 0, hIconApp)
	}

	xOffset := 10
	if hasMultipleSubnets {
		procCreateWindowExW.Call(
			0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
			uintptr(unsafe.Pointer(strPtr("⚠️ Subnet:"))),
			WS_CHILD|WS_VISIBLE,
			uintptr(xOffset), 13, 54, 22,
			hwndMain, 0, hInstance, 0,
		)
		xOffset += 56

		hwndComboSubRet, _, _ := procCreateWindowExW.Call(
			0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))),
			0,
			WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST,
			uintptr(xOffset), 10, 125, 200,
			hwndMain, 1000, hInstance, 0,
		)
		hwndComboSub = hwndComboSubRet
		xOffset += 130

		for _, sub := range detectedSubnets {
			entry := fmt.Sprintf("%s (%s.0/24)", sub.Name, sub.Subnet)
			procSendMessageW.Call(hwndComboSub, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr(entry))))
		}
		procSendMessageW.Call(hwndComboSub, CB_SETCURSEL, 0, 0)
		procSendMessageW.Call(hwndComboSub, WM_SETFONT, hFontSegoe, 1)
	}

	// Label: IP:
	procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("IP:"))),
		WS_CHILD|WS_VISIBLE,
		uintptr(xOffset), 13, 22, 22,
		hwndMain, 0, hInstance, 0,
	)
	xOffset += 24

	// Edit: IP From
	hwndIPFromRet, _, _ := procCreateWindowExW.Call(
		0x00000200, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(activeSub.RangeFrom))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		uintptr(xOffset), 11, 90, 23,
		hwndMain, 0, hInstance, 0,
	)
	hwndIPFrom = hwndIPFromRet
	xOffset += 92

	// Label: -
	procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("-"))),
		WS_CHILD|WS_VISIBLE,
		uintptr(xOffset), 13, 8, 22,
		hwndMain, 0, hInstance, 0,
	)
	xOffset += 9

	// Edit: IP To
	hwndIPToRet, _, _ := procCreateWindowExW.Call(
		0x00000200, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(activeSub.RangeTo))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		uintptr(xOffset), 11, 90, 23,
		hwndMain, 0, hInstance, 0,
	)
	hwndIPTo = hwndIPToRet
	xOffset += 94

	// Label: Timeout:
	procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Timeout:"))),
		WS_CHILD|WS_VISIBLE,
		uintptr(xOffset), 13, 48, 22,
		hwndMain, 0, hInstance, 0,
	)
	xOffset += 50

	// Dropdown ComboBox: Timeout (Compact)
	hwndTimeoutRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST,
		uintptr(xOffset), 10, 105, 200,
		hwndMain, 1010, hInstance, 0,
	)
	hwndTimeout = hwndTimeoutRet
	procSendMessageW.Call(hwndTimeout, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("1000 ms (Standard)"))))
	procSendMessageW.Call(hwndTimeout, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("500 ms (Fast LAN)"))))
	procSendMessageW.Call(hwndTimeout, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("1500 ms (Deep Scan)"))))
	procSendMessageW.Call(hwndTimeout, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("2500 ms (Max IoT)"))))
	procSendMessageW.Call(hwndTimeout, CB_SETCURSEL, 0, 0)
	xOffset += 109

	// Label: Packet:
	procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Packet:"))),
		WS_CHILD|WS_VISIBLE,
		uintptr(xOffset), 13, 40, 22,
		hwndMain, 0, hInstance, 0,
	)
	xOffset += 42

	// Dropdown ComboBox: Packet (Compact)
	hwndPacketRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST,
		uintptr(xOffset), 10, 95, 200,
		hwndMain, 1011, hInstance, 0,
	)
	hwndPacket = hwndPacketRet
	procSendMessageW.Call(hwndPacket, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("1472 B (MTU Speed)"))))
	procSendMessageW.Call(hwndPacket, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("32 B (Light Ping)"))))
	procSendMessageW.Call(hwndPacket, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("64 B (Unix Echo)"))))
	procSendMessageW.Call(hwndPacket, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("512 B (Mid Payload)"))))
	procSendMessageW.Call(hwndPacket, CB_SETCURSEL, 0, 0)
	xOffset += 99

	// Label: Threads:
	procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Threads:"))),
		WS_CHILD|WS_VISIBLE,
		uintptr(xOffset), 13, 46, 22,
		hwndMain, 0, hInstance, 0,
	)
	xOffset += 48

	// Dropdown ComboBox: Threads (Compact)
	hwndThreadsRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST,
		uintptr(xOffset), 10, 85, 200,
		hwndMain, 1012, hInstance, 0,
	)
	hwndThreads = hwndThreadsRet
	procSendMessageW.Call(hwndThreads, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("100 (Normal)"))))
	procSendMessageW.Call(hwndThreads, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("50 (Low Load)"))))
	procSendMessageW.Call(hwndThreads, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("150 (Turbo)"))))
	procSendMessageW.Call(hwndThreads, CB_SETCURSEL, 0, 0)
	xOffset += 89

	// Button: Start Scan (▶)
	hwndBtnStartRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("▶ Start Scan"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		uintptr(xOffset), 9, 84, 26,
		hwndMain, 1001, hInstance, 0,
	)
	hwndBtnStart = hwndBtnStartRet
	if hasNoNetwork {
		procEnableWindow.Call(hwndBtnStart, 0)
	}
	xOffset += 88

	// Button: Stop (⏹)
	hwndBtnStopRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("⏹ Stop"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		uintptr(xOffset), 9, 54, 26,
		hwndMain, 1002, hInstance, 0,
	)
	hwndBtnStop = hwndBtnStopRet
	procEnableWindow.Call(hwndBtnStop, 0)
	xOffset += 58

	// Button: Deep Scan (🔬)
	hwndBtnDeepScanRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🔬 Deep Scan"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		uintptr(xOffset), 9, 86, 26,
		hwndMain, 1006, hInstance, 0,
	)
	hwndBtnDeepScan = hwndBtnDeepScanRet
	procEnableWindow.Call(hwndBtnDeepScan, 0)
	xOffset += 90

	// Button: Scan Ports (🔍)
	hwndBtnScanPortsRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🔍 Scan Ports"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		uintptr(xOffset), 9, 84, 26,
		hwndMain, 1005, hInstance, 0,
	)
	hwndBtnScanPorts = hwndBtnScanPortsRet
	procEnableWindow.Call(hwndBtnScanPorts, 0)
	xOffset += 88

	// Button: Save Log (💾)
	hwndBtnExportRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("💾 Save Log"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		uintptr(xOffset), 9, 78, 26,
		hwndMain, 1003, hInstance, 0,
	)
	hwndBtnExport = hwndBtnExportRet

	// Progress Bar
	hwndProgressRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("msctls_progress32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER,
		12, 42, 1160, 14,
		hwndMain, 0, hInstance, 0,
	)
	hwndProgress = hwndProgressRet

	// --- ROW 2: ListView Grid ---
	hwndListViewRet, _, _ := procCreateWindowExW.Call(
		0x00000200, uintptr(unsafe.Pointer(strPtr("SysListView32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS,
		12, 62, 1160, 540,
		hwndMain, 0, hInstance, 0,
	)
	hwndListView = hwndListViewRet

	procSendMessageW.Call(hwndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER)

	cols := []struct {
		Title string
		Width int32
	}{
		{"№", 38},
		{"Device Type", 155},
		{"IP Address", 112},
		{"Host Name", 155},
		{"MAC Address", 138},
		{"Ping (RTT)", 84},
		{"Speed", 98},
		{"Hardware & Service Fingerprint", 480},
	}

	for i, col := range cols {
		lvc := LVCOLUMNW{
			Mask:    0x0001 | 0x0002 | 0x0004,
			Fmt:     0,
			Cx:      col.Width,
			PszText: strPtr(col.Title),
		}
		procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, uintptr(i), uintptr(unsafe.Pointer(&lvc)))
	}

	// Status Bar Label (Left)
	statusInitText := "Ready. Click '▶ Start Scan' to begin discovery.   |||   💡 (Tip: Use '🔬 Deep Scan' for mDNS/Apple ID or '🔍 Scan Ports')"
	if hasNoNetwork {
		statusInitText = "😢 ⚠️ No active network adapter or IP found! Network card not detected or drivers not installed."
	} else if hasMultipleSubnets {
		statusInitText = "⚠️ Multiple Subnets Detected! Select subnet from dropdown above or click '▶ Start Scan'."
	}

	hwndStatusRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(statusInitText))),
		WS_CHILD|WS_VISIBLE,
		12, 608, 970, 22,
		hwndMain, 0, hInstance, 0,
	)
	hwndStatus = hwndStatusRet

	// Brand Signature Label
	hwndBrandRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("VladiMIR+AI"))),
		WS_CHILD|WS_VISIBLE|SS_RIGHT|SS_NOTIFY,
		990, 608, 180, 22,
		hwndMain, 1004, hInstance, 0,
	)
	hwndBrand = hwndBrandRet

	// Attach Rich Tooltips on Hover
	hwndTipRet, _, _ := procCreateWindowExW.Call(
		0x00000008, // WS_EX_TOPMOST
		uintptr(unsafe.Pointer(strPtr("tooltips_class32"))),
		0,
		WS_POPUP|TTS_ALWAYSTIP|TTS_NOPREFIX|TTS_BALLOON,
		0, 0, 0, 0,
		hwndMain, 0, hInstance, 0,
	)
	hwndTip := hwndTipRet
	if hwndTip != 0 {
		procSendMessageW.Call(hwndTip, TTM_SETMAXTIPWIDTH, 0, 480)
		if hasMultipleSubnets {
			addTooltip(hwndTip, hwndComboSub, "Network Adapter & Subnet:\nSelect the active network card and IPv4 subnet to scan.")
		}
		addTooltip(hwndTip, hwndIPFrom, "Scan Range Start:\nFirst IP address to probe in the subnet.")
		addTooltip(hwndTip, hwndIPTo, "Scan Range End:\nLast IP address to probe in the subnet.")
		addTooltip(hwndTip, hwndTimeout, "Response Timeout:\nHow long to wait for each device to respond before marking it as inactive.\n• 1000 ms: Recommended for home & office LAN\n• 500 ms: Ultra-fast scan for wired LAN\n• 1500 ms: Deep scan for weak Wi-Fi\n• 2500 ms: Maximum reach for sleeping IoT")
		addTooltip(hwndTip, hwndPacket, "ICMP Packet Payload:\nSize of ping packet sent to calculate response time & link speed.\n• 1472 B: Max Ethernet MTU without fragmentation (Best speed test)\n• 32 B: Standard Windows ping\n• 64 B: Standard Unix ping\n• 512 B: Mid-size packet")
		addTooltip(hwndTip, hwndThreads, "Parallel Scan Threads:\nNumber of simultaneous IP target probes.\n• 100: Optimal balance between speed and reliability (Recommended)\n• 50: Lower load on weak Wi-Fi routers\n• 150: Turbo speed for Gigabit LANs")

		if hasNoNetwork {
			addTooltip(hwndTip, hwndBtnStart, "Start Scan (▶):\n😢 Disabled: No active network adapter detected.")
		} else {
			addTooltip(hwndTip, hwndBtnStart, "Start Scan (▶):\nPerform ultra-fast hardware ARP detection, ICMP latency measurement, and basic hostname discovery.")
		}
		addTooltip(hwndTip, hwndBtnStop, "Stop Scan (⏹):\nAbort current scanning process immediately.")
		addTooltip(hwndTip, hwndBtnDeepScan, "Deep Scan (🔬):\nDeeply audit discovered online devices using mDNS Bonjour, Apple Model ID translation, NetBIOS, SSDP UPnP, and HTTP banners.")
		addTooltip(hwndTip, hwndBtnScanPorts, "Scan All Ports (🔍):\nAudit 36 common service ports across all discovered online hosts and update the grid in real-time.")
		addTooltip(hwndTip, hwndBtnExport, "Save Log (💾):\nExport full network inventory audit report to Desktop in UTF-8.")
		addTooltip(hwndTip, hwndBrand, "About GIN-NetScan")
	}

	// Apply Fonts
	allHwnds := []uintptr{
		hwndIPFrom, hwndIPTo, hwndTimeout, hwndPacket, hwndThreads,
		hwndBtnStart, hwndBtnStop, hwndBtnDeepScan, hwndBtnScanPorts, hwndBtnExport, hwndListView, hwndStatus,
	}
	for _, h := range allHwnds {
		procSendMessageW.Call(h, WM_SETFONT, hFontSegoe, 1)
	}
	procSendMessageW.Call(hwndBrand, WM_SETFONT, hFontBold, 1)

	procShowWindow.Call(hwndMain, 5)
	procUpdateWindow.Call(hwndMain)

	if !hasMultipleSubnets && !hasNoNetwork {
		startScanThread()
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
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
