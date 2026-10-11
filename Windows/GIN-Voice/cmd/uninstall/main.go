// ==========================================================================================
// Execution Context : Go 1.22+ (Windows AMD64 Console Executable)
// Target Application: GIN-Voice
// Description       : Native Standalone Uninstaller for GIN-Voice with Vladimir's ANSI 90-char Styling
// ==========================================================================================

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

var (
	kernel32             = syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitleW = kernel32.NewProc("SetConsoleTitleW")
	procSetConsoleMode   = kernel32.NewProc("SetConsoleMode")
	procGetStdHandle     = kernel32.NewProc("GetStdHandle")
)

const (
	STD_OUTPUT_HANDLE                  = ^uintptr(10) // -11
	ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
)

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

func enableVTMode() {
	hOut, _, _ := procGetStdHandle.Call(STD_OUTPUT_HANDLE)
	if hOut != 0 && hOut != ^uintptr(0) {
		var mode uint32
		procSetConsoleMode.Call(hOut, uintptr(mode|ENABLE_VIRTUAL_TERMINAL_PROCESSING))
	}
}

func terminateAllGINVoiceProcesses() {
	// Method 1: taskkill exact executable name
	_ = exec.Command("taskkill", "/F", "/IM", "GIN-Voice.exe", "/T").Run()

	// Method 2: taskkill filter wildcard
	_ = exec.Command("taskkill", "/F", "/FI", "IMAGENAME eq GIN-Voice*").Run()

	// Method 3: PowerShell Stop-Process
	_ = exec.Command("powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", "Get-Process -Name 'GIN-Voice*' -ErrorAction SilentlyContinue | Stop-Process -Force").Run()

	// Method 4: wmic terminate fallback
	_ = exec.Command("wmic", "process", "where", "name like 'GIN-Voice%'", "call", "terminate").Run()

	time.Sleep(800 * time.Millisecond)
}

func main() {
	procSetConsoleTitleW.Call(uintptr(unsafe.Pointer(strPtr("GIN-Voice Clean Uninstaller by VladiMIR+AI"))))
	enableVTMode()

	line90 := strings.Repeat("=", 90)

	// ANSI Colors: Cyan \033[96m, Green \033[92m, Gray \033[90m, Reset \033[0m
	fmt.Println("\033[96m" + line90)
	fmt.Println("   GIN-Voice by VladiMIR+AI — Clean Uninstaller")
	fmt.Println("   Fast Multilingual Voice Typing Tool for Windows 10/11\033[90m")
	fmt.Println("\033[96m" + line90 + "\033[0m\n")

	fmt.Println("\033[92m[1/4] Stopping all active GIN-Voice background processes...\033[0m")
	terminateAllGINVoiceProcesses()
	fmt.Println("\033[90m      Done. All GIN-Voice processes terminated.\033[0m\n")

	fmt.Println("\033[92m[2/4] Removing desktop, start menu, and cloud shortcuts...\033[0m")
	userProfile := os.Getenv("USERPROFILE")
	appData := os.Getenv("APPDATA")
	localAppData := os.Getenv("LOCALAPPDATA")
	tempDir := os.TempDir()

	desktopDir := filepath.Join(userProfile, "Desktop")
	startMenuDir := filepath.Join(appData, "Microsoft", "Windows", "Start Menu", "Programs")
	megaDesktopDir := `D:\MEGA\DOCS\desktop`

	// Remove shortcuts only (NEVER touch installers or other executables on Desktop/MEGA)
	_ = os.Remove(filepath.Join(desktopDir, "GIN-Voice.lnk"))
	_ = os.Remove(filepath.Join(startMenuDir, "GIN-Voice.lnk"))
	_ = os.Remove(filepath.Join(startMenuDir, "Uninstall GIN-Voice.lnk"))
	_ = os.RemoveAll(filepath.Join(startMenuDir, "GIN-Voice"))
	_ = os.Remove(filepath.Join(megaDesktopDir, "GIN-Voice.lnk"))
	fmt.Println("\033[90m      Done. Shortcuts removed (installers preserved).\033[0m\n")

	fmt.Println("\033[92m[3/4] Cleaning Windows Autostart and Registry entries...\033[0m")
	_ = exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "GIN-Voice", "/f").Run()
	_ = exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice`, "/f").Run()
	_ = exec.Command("reg", "delete", `HKCU\Software\GIN-Voice`, "/f").Run()
	fmt.Println("\033[90m      Done. Registry cleaned.\033[0m\n")

	fmt.Println("\033[92m[4/4] Removing application directory and local data...\033[0m")
	installDir := filepath.Join(localAppData, "GIN-Voice")

	// Delete all files in installDir except the running uninstaller binary
	currExe, _ := os.Executable()
	currExeName := filepath.Base(currExe)

	if entries, err := os.ReadDir(installDir); err == nil {
		for _, e := range entries {
			if !strings.EqualFold(e.Name(), currExeName) {
				_ = os.RemoveAll(filepath.Join(installDir, e.Name()))
			}
		}
	}

	fmt.Println("\033[90m      Done. Application folder cleared.\033[0m\n")

	fmt.Println("\033[92m" + line90)
	fmt.Println("   GIN-Voice was successfully and completely uninstalled from your system!")
	fmt.Println(line90 + "\033[0m\n")
	fmt.Println("\033[90mThis window will close automatically in 3 seconds...\033[0m")

	// Create a detached cleanup batch in %TEMP% to wipe the installDir after this uninstaller exits
	cleanBatPath := filepath.Join(tempDir, "gin_voice_uninst_cleanup.bat")
	cleanBatContent := fmt.Sprintf("@echo off\r\ncd /d \"%s\"\r\nping -n 3 127.0.0.1 >nul\r\nrd /s /q \"%s\" 2>nul\r\ndel \"%%~f0\" 2>nul\r\n", tempDir, installDir)
	_ = os.WriteFile(cleanBatPath, []byte(cleanBatContent), 0755)

	cmd := exec.Command("cmd.exe", "/c", "start", "/b", cleanBatPath)
	cmd.Dir = tempDir
	_ = cmd.Start()

	time.Sleep(3 * time.Second)
}
