using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;
using System.Security.Principal;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using Microsoft.Win32;

[assembly: AssemblyTitle("GIN-VPN Installer")]
[assembly: AssemblyDescription("GIN-VPN by VladiMIR+AI Autonomous Installer")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("VladiMIR+AI (Vladimir Bulantsev)")]
[assembly: AssemblyProduct("GIN-VPN")]
[assembly: AssemblyCopyright("Copyright © 2026 Vladimir Bulantsev")]
[assembly: AssemblyTrademark("GIN-VPN")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("1.0.90.0")]
[assembly: AssemblyFileVersion("1.0.90.0")]
[assembly: AssemblyInformationalVersion("v091")]

namespace GinVpnBootstrap {
    static class Program {
        [STAThread]
        static void Main() {
            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Local\\GIN_VPN_BOOTSTRAP_INSTALLER_MUTEX", out createdNew)) {
                if (!createdNew) {
                    return;
                }

                if (!IsAdministrator()) {
                    try {
                        ProcessStartInfo psi = new ProcessStartInfo();
                        psi.FileName = Application.ExecutablePath;
                        psi.UseShellExecute = true;
                        psi.Verb = "runas";
                        Process.Start(psi);
                        return;
                    } catch {}
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new InstallerForm());
            }
        }

        static bool IsAdministrator() {
            try {
                WindowsIdentity identity = WindowsIdentity.GetCurrent();
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            } catch {
                return false;
            }
        }
    }

    /// <summary>
    /// High-performance WebClient that:
    /// 1. Disables WPAD proxy auto-discovery (Proxy = null).
    /// 2. Resolves and forces IPv4 connections to avoid Windows .NET IPv6 connection hangs.
    /// 3. Enforces strict timeouts and SSL callback.
    /// </summary>
    public class IPv4WebClient : WebClient {
        private readonly int _timeoutMs;
        public IPv4WebClient(int timeoutMs = 8000) {
            _timeoutMs = timeoutMs;
            this.Proxy = null;
        }

        protected override WebRequest GetWebRequest(Uri address) {
            Uri targetUri = address;
            string originalHost = address.Host;

            try {
                if (address.HostNameType == UriHostNameType.Dns) {
                    IPAddress[] ips = Dns.GetHostAddresses(address.Host);
                    foreach (IPAddress ip in ips) {
                        if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork) {
                            UriBuilder ub = new UriBuilder(address);
                            ub.Host = ip.ToString();
                            targetUri = ub.Uri;
                            break;
                        }
                    }
                }
            } catch {}

            WebRequest wr = base.GetWebRequest(targetUri);
            if (wr != null) {
                wr.Timeout = _timeoutMs;
                HttpWebRequest hwr = wr as HttpWebRequest;
                if (hwr != null) {
                    hwr.Host = originalHost;
                    hwr.ReadWriteTimeout = _timeoutMs;
                    hwr.KeepAlive = false;
                    hwr.ServerCertificateValidationCallback = (sender, cert, chain, errors) => true;
                }
            }
            return wr;
        }
    }

    public class InstallerForm : Form {
        private const string FALLBACK_VERSION = "v091";
        private const string BCRYPT_PRIMITIVES_B64 = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAwAAADopAAAADAAABQAAAAQoECgUKBYoGCgAAAAQAAAMAAAACCgQKBIoFCgWKDgofChAKIQoiCiMKJAolCiYKJwooCikKKgorCiAAAAoAAAEAAAABigMKA4oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        private Label lblTitle;
        private Label lblStatus;
        private ProgressBar progressBar;
        private Label lblPercent;
        private PictureBox picIcon;
        private Thread workerThread;
        private bool isRussian;

        public InstallerForm() {
            ConfigureSecurityAndRegistry();
            DetectLanguage();
            InitializeUI();
            this.Shown += (s, e) => StartInstall();
            this.FormClosing += (s, e) => {
                if (workerThread != null && workerThread.IsAlive) {
                    try { workerThread.Abort(); } catch {}
                }
            };
        }

        private void DetectLanguage() {
            try {
                string uiLang = CultureInfo.InstalledUICulture.TwoLetterISOLanguageName.ToLower();
                string curLang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName.ToLower();
                isRussian = (uiLang == "ru" || uiLang == "be" || uiLang == "uk" || curLang == "ru");
            } catch {
                isRussian = false;
            }
        }

        private string L(string ru, string en) {
            return isRussian ? ru : en;
        }

        private void InitializeUI() {
            // Strictly "Установка и запуск" / "Install & Launch" without "Быстрая"
            this.Text = L("GIN-VPN — Установка и запуск", "GIN-VPN — Install & Launch");
            this.Size = new Size(500, 210);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(28, 28, 30);
            this.ForeColor = Color.White;

            try {
                this.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            } catch {}

            picIcon = new PictureBox();
            picIcon.Location = new Point(20, 25);
            picIcon.Size = new Size(54, 54);
            picIcon.SizeMode = PictureBoxSizeMode.Zoom;
            if (this.Icon != null) {
                picIcon.Image = this.Icon.ToBitmap();
            }
            this.Controls.Add(picIcon);

            lblTitle = new Label();
            lblTitle.Text = "GIN-VPN by VladiMIR+AI";
            lblTitle.Font = new Font("Segoe UI", 13, FontStyle.Bold);
            lblTitle.Location = new Point(88, 22);
            lblTitle.Size = new Size(385, 26);
            lblTitle.ForeColor = Color.FromArgb(0, 230, 118);
            this.Controls.Add(lblTitle);

            lblStatus = new Label();
            lblStatus.Text = L("Подготовка к установке...", "Preparing installation...");
            lblStatus.Font = new Font("Segoe UI", 9, FontStyle.Regular);
            lblStatus.Location = new Point(88, 52);
            lblStatus.Size = new Size(385, 20);
            lblStatus.ForeColor = Color.FromArgb(200, 200, 200);
            this.Controls.Add(lblStatus);

            progressBar = new ProgressBar();
            progressBar.Location = new Point(24, 105);
            progressBar.Size = new Size(436, 24);
            progressBar.Style = ProgressBarStyle.Continuous;
            this.Controls.Add(progressBar);

            lblPercent = new Label();
            lblPercent.Text = "0%";
            lblPercent.Font = new Font("Segoe UI", 8, FontStyle.Regular);
            lblPercent.Location = new Point(24, 135);
            lblPercent.Size = new Size(436, 20);
            lblPercent.TextAlign = ContentAlignment.TopRight;
            lblPercent.ForeColor = Color.FromArgb(160, 160, 160);
            this.Controls.Add(lblPercent);
        }

        private void SetStatus(string text) {
            if (this.InvokeRequired) {
                this.BeginInvoke(new Action<string>(SetStatus), text);
                return;
            }
            lblStatus.Text = text;
        }

        private void SetProgress(int percent, string details) {
            if (this.InvokeRequired) {
                this.BeginInvoke(new Action<int, string>(SetProgress), percent, details);
                return;
            }
            progressBar.Value = Math.Max(0, Math.Min(100, percent));
            lblPercent.Text = details;
        }

        private void ConfigureSecurityAndRegistry() {
            // 1. Safe cascade TLS protocol initialization for all Windows versions (Win 7/8/10/11)
            try {
                // TLS 1.2 (3072) + TLS 1.1 (768) + TLS 1.0 (192)
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | (SecurityProtocolType)768 | SecurityProtocolType.Tls;
            } catch {
                try {
                    ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | SecurityProtocolType.Tls;
                } catch {
                    try {
                        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls;
                    } catch {}
                }
            }

            // 2. Safely add TLS 1.3 (12288) only on modern Windows 10/11 / Server 2022+ where supported
            try {
                if (Environment.OSVersion.Version.Major >= 10) {
                    ServicePointManager.SecurityProtocol |= (SecurityProtocolType)12288;
                }
            } catch {}

            // 3. Autonomous self-healing for Legacy Windows (Windows 7 / 8 / 8.1 / Server 2008 R2 / 2012)
            try {
                if (Environment.OSVersion.Version.Major < 10) {
                    // Enable TLS 1.2 in Schannel
                    using (RegistryKey key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client")) {
                        if (key != null) {
                            key.SetValue("DisabledByDefault", 0, RegistryValueKind.DWord);
                            key.SetValue("Enabled", 1, RegistryValueKind.DWord);
                        }
                    }
                    // Enable TLS 1.1 in Schannel
                    using (RegistryKey key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client")) {
                        if (key != null) {
                            key.SetValue("DisabledByDefault", 0, RegistryValueKind.DWord);
                            key.SetValue("Enabled", 1, RegistryValueKind.DWord);
                        }
                    }
                    // Enable strong crypto in .NET Framework
                    string[] netPaths = new[] {
                        @"SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
                        @"SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319",
                        @"SOFTWARE\Microsoft\.NETFramework\v2.0.50727",
                        @"SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"
                    };
                    foreach (string path in netPaths) {
                        try {
                            using (RegistryKey key = Registry.LocalMachine.CreateSubKey(path)) {
                                if (key != null) {
                                    key.SetValue("SchUseStrongCrypto", 1, RegistryValueKind.DWord);
                                    key.SetValue("SystemDefaultTlsVersions", 1, RegistryValueKind.DWord);
                                }
                            }
                        } catch {}
                    }
                }
            } catch {}

            // 4. Bypass certificate validation failures due to outdated root CA certificates on Windows 7 SP1
            try {
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            } catch {}
        }

        private void StartInstall() {
            workerThread = new Thread(InstallProcess);
            workerThread.IsBackground = true;
            workerThread.Start();
        }

        private void InstallProcess() {
            try {
                // 1. Reset proxy silently (Windows 7/8/10/11 WinINet & WinHTTP deep clean)
                try {
                    using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings", true)) {
                        if (rk != null) {
                            rk.SetValue("ProxyEnable", 0, RegistryValueKind.DWord);
                            try { rk.DeleteValue("ProxyServer"); } catch {}
                            try { rk.DeleteValue("ProxyOverride"); } catch {}
                            try { rk.DeleteValue("AutoConfigURL"); } catch {}
                        }
                    }
                    using (RegistryKey rkConn = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections", true)) {
                        if (rkConn != null) {
                            foreach (string v in rkConn.GetValueNames()) {
                                try { rkConn.DeleteValue(v); } catch {}
                            }
                        }
                    }
                } catch {}

                try {
                    ProcessStartInfo psi = new ProcessStartInfo("netsh", "winhttp reset proxy");
                    psi.CreateNoWindow = true;
                    psi.UseShellExecute = false;
                    psi.WindowStyle = ProcessWindowStyle.Hidden;
                    Process p = Process.Start(psi);
                    if (p != null) p.WaitForExit(1000);
                } catch {}

                // 2. Terminate old processes
                SetStatus(L("Закрытие активных процессов...", "Closing active processes..."));
                KillProcess("GIN-VPN");
                KillProcess("uninstall");
                KillProcess("xray");
                Thread.Sleep(200);

                // 3. Setup target directories
                string progFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                if (string.IsNullOrEmpty(progFiles)) {
                    progFiles = @"C:\Program Files";
                }
                string targetDir = Path.Combine(progFiles, "GIN-VPN");
                try {
                    if (!Directory.Exists(targetDir)) {
                        Directory.CreateDirectory(targetDir);
                    }
                } catch {
                    string localApp = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    targetDir = Path.Combine(localApp, "GIN-VPN");
                    if (!Directory.Exists(targetDir)) {
                        Directory.CreateDirectory(targetDir);
                    }
                }

                string targetExe = Path.Combine(targetDir, "GIN-VPN.exe");
                string uninstExe = Path.Combine(targetDir, "uninstall.exe");
                string tempFile = Path.Combine(Path.GetTempPath(), "GIN-VPN_Setup_" + Guid.NewGuid().ToString("N") + ".tmp");

                ConfigureSecurityAndRegistry();

                // 4. Quick Version Check (Max 2.0s, falls back to FALLBACK_VERSION instantly)
                SetStatus(L("Проверка актуальной версии...", "Checking release version..."));
                string directUrl = null;
                string latestVer = DetectLatestVersion(out directUrl);

                // 5. Check if binary is ALREADY present locally on this PC (Instant local install!)
                bool localFound = false;
                List<string> localCandidates = new List<string> {
                    Path.Combine(Application.StartupPath, "GIN-VPN_" + latestVer + ".exe"),
                    Path.Combine(Application.StartupPath, "GIN-VPN.exe"),
                    @"D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\VPN\GIN-VPN_" + latestVer + ".exe",
                    @"D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\VPN\GIN-VPN.exe",
                    @"D:\AI\GitHub\Windows_scripts\Windows\GIN-VPN\GIN-VPN_" + latestVer + ".exe",
                    @"D:\AI\GitHub\Windows_scripts\Windows\GIN-VPN\GIN-VPN.exe"
                };

                try {
                    foreach (string f in Directory.GetFiles(Application.StartupPath, "GIN-VPN*.exe")) {
                        if (!string.Equals(f, Application.ExecutablePath, StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(f, targetExe, StringComparison.OrdinalIgnoreCase) &&
                            !localCandidates.Contains(f)) {
                            localCandidates.Add(f);
                        }
                    }
                } catch {}

                foreach (string localPath in localCandidates) {
                    if (File.Exists(localPath) && !string.Equals(localPath, targetExe, StringComparison.OrdinalIgnoreCase)) {
                        try {
                            if (VerifyBinaryVersion(localPath, latestVer) || (new FileInfo(localPath).Length >= 15000000 && VerifyBinaryVersion(localPath, "GIN-VPN"))) {
                                SetStatus(L("Копирование локального пакета...", "Copying local package..."));
                                SetProgress(50, L("Копирование...", "Copying..."));
                                File.Copy(localPath, tempFile, true);
                                localFound = true;
                                break;
                            }
                        } catch {}
                    }
                }

                // 6. If not found locally, download over the internet using IPv4 forced client
                if (!localFound) {
                    List<MirrorEntry> mirrors = new List<MirrorEntry>();

                    if (!string.IsNullOrEmpty(directUrl)) {
                        mirrors.Add(new MirrorEntry("Direct Release URL", directUrl));
                    }
                    mirrors.Add(new MirrorEntry("GitHub Raw (" + latestVer + ")",
                        "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_" + latestVer + ".exe"));
                    mirrors.Add(new MirrorEntry("GitHub Raw (GIN-VPN.exe)",
                        "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"));
                    mirrors.Add(new MirrorEntry("RU-109 Mirror (Dedicated HTTP)",
                        "http://prodvig-saita.ru/vpn/GIN-VPN.exe"));
                    mirrors.Add(new MirrorEntry("CloudCore-191 Mirror (Dedicated HTTPS)",
                        "https://4at.gincz.com/download/GIN-VPN.exe"));

                    bool success = false;

                    foreach (MirrorEntry m in mirrors) {
                        SetStatus(L("Загрузка " + latestVer + " c ", "Downloading " + latestVer + " from ") + m.Name + "...");
                        try {
                            if (File.Exists(tempFile)) {
                                File.Delete(tempFile);
                            }

                            using (IPv4WebClient wc = new IPv4WebClient(8000)) {
                                wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-VPN-Installer");

                                ManualResetEvent downloadDone = new ManualResetEvent(false);
                                Exception downloadErr = null;

                                wc.DownloadProgressChanged += (s, e) => {
                                    double mbRecv = e.BytesReceived / 1048576.0;
                                    double mbTotal = e.TotalBytesToReceive / 1048576.0;
                                    string info = string.Format("{0:F1} MB / {1:F1} MB ({2}%)", mbRecv, mbTotal, e.ProgressPercentage);
                                    SetProgress(e.ProgressPercentage, info);
                                };

                                wc.DownloadFileCompleted += (s, e) => {
                                    if (e.Error != null) downloadErr = e.Error;
                                    downloadDone.Set();
                                };

                                wc.DownloadFileAsync(new Uri(m.Url), tempFile);

                                bool finished = downloadDone.WaitOne(60000);
                                if (!finished) {
                                    try { wc.CancelAsync(); } catch {}
                                }

                                if (finished && downloadErr == null && File.Exists(tempFile)) {
                                    long len = new FileInfo(tempFile).Length;
                                    if (len >= 12000000) {
                                        SetStatus(L("Проверка целостности " + latestVer + "...", "Verifying integrity of " + latestVer + "..."));
                                        if (VerifyBinaryVersion(tempFile, latestVer) || (len >= 15000000 && VerifyBinaryVersion(tempFile, "GIN-VPN"))) {
                                            success = true;
                                            break;
                                        } else {
                                            try { File.Delete(tempFile); } catch {}
                                        }
                                    }
                                }
                            }
                        } catch {}
                    }

                    if (!success || !File.Exists(tempFile)) {
                        MessageBox.Show(
                            L(
                                "Не удалось загрузить актуальную версию " + latestVer + " GIN-VPN.\n\nПожалуйста, проверьте интернет-соединение.",
                                "Failed to download latest version " + latestVer + " of GIN-VPN.\n\nPlease check your internet connection."
                            ),
                            L("Ошибка загрузки GIN-VPN", "GIN-VPN Download Error"),
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error
                        );
                        this.BeginInvoke(new Action(Close));
                        return;
                    }
                }

                // 7. Deploy Full Components Suite into Target Directory
                SetStatus(L("Установка " + latestVer + " в " + targetDir + "...", "Installing " + latestVer + " to " + targetDir + "..."));
                SetProgress(90, L("Копирование файлов...", "Copying files..."));

                File.Copy(tempFile, targetExe, true);
                File.Copy(tempFile, uninstExe, true);

                try {
                    if (Environment.OSVersion.Version.Major < 10) {
                        byte[] dllBytes = Convert.FromBase64String(BCRYPT_PRIMITIVES_B64);
                        File.WriteAllBytes(Path.Combine(targetDir, "bcryptprimitives.dll"), dllBytes);

                        string localApp = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                        string localDir = Path.Combine(localApp, "GIN-VPN");
                        if (!Directory.Exists(localDir)) Directory.CreateDirectory(localDir);
                        File.WriteAllBytes(Path.Combine(localDir, "bcryptprimitives.dll"), dllBytes);

                        string tempDir = Path.Combine(Path.GetTempPath(), "GIN-VPN");
                        if (!Directory.Exists(tempDir)) Directory.CreateDirectory(tempDir);
                        File.WriteAllBytes(Path.Combine(tempDir, "bcryptprimitives.dll"), dllBytes);
                    }
                } catch {}

                try {
                    string jsonContent = string.Format("{{\n  \"version\": \"{0}\",\n  \"app_name\": \"GIN-VPN\",\n  \"title\": \"GIN-VPN by VladiMIR+AI\",\n  \"install_date\": \"{1}\"\n}}\n",
                        latestVer, DateTime.UtcNow.ToString("yyyy-MM-dd"));
                    File.WriteAllText(Path.Combine(targetDir, "version.json"), jsonContent);
                    File.WriteAllText(Path.Combine(targetDir, "version.txt"), latestVer);
                } catch {}

                try { File.Delete(tempFile); } catch {}

                // 8. Shortcuts
                SetStatus(L("Создание ярлыков...", "Creating shortcuts..."));
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                CreateShortcut(Path.Combine(desktop, "GIN-VPN.lnk"), targetExe, targetDir, "GIN-VPN by VladiMIR+AI");

                string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                if (Directory.Exists(startMenu)) {
                    CreateShortcut(Path.Combine(startMenu, "GIN-VPN.lnk"), targetExe, targetDir, "GIN-VPN by VladiMIR+AI");
                }

                try {
                    string stray = Path.Combine(desktop, "GIN-VPN.exe");
                    if (File.Exists(stray) && !string.Equals(stray, targetExe, StringComparison.OrdinalIgnoreCase)) {
                        File.Delete(stray);
                    }
                    foreach (var old in Directory.GetFiles(desktop, "GIN-VPN_v*.exe")) {
                        try { File.Delete(old); } catch {}
                    }
                } catch {}

                // 9. Windows Installed Apps Registration
                SetStatus(L("Регистрация программы в Windows...", "Registering in Windows Installed Apps..."));
                RegisterUninstaller(targetDir, targetExe, uninstExe, latestVer);

                // 10. Launch
                SetStatus(L("Запуск GIN-VPN " + latestVer + "...", "Launching GIN-VPN " + latestVer + "..."));
                SetProgress(100, L("Готово!", "Ready!"));
                Thread.Sleep(300);

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = targetExe;
                startInfo.WorkingDirectory = targetDir;
                startInfo.UseShellExecute = true;
                Process.Start(startInfo);

                Thread.Sleep(500);
                this.BeginInvoke(new Action(Close));
            } catch (Exception ex) {
                MessageBox.Show(
                    L("Ошибка во время установки: ", "Installation error: ") + ex.Message,
                    "GIN-VPN",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                this.BeginInvoke(new Action(Close));
            }
        }

        private static void RegisterUninstaller(string targetDir, string targetExe, string uninstExe, string version) {
            try {
                RegistryKey[] rootKeys = new[] { Registry.CurrentUser, Registry.LocalMachine };
                foreach (RegistryKey root in rootKeys) {
                    try {
                        using (RegistryKey key = root.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN")) {
                            if (key != null) {
                                key.SetValue("DisplayName", "GIN-VPN by VladiMIR+AI");
                                key.SetValue("DisplayVersion", version);
                                key.SetValue("Publisher", "VladiMIR+AI (Vladimir Bulantsev)");
                                key.SetValue("DisplayIcon", targetExe + ",0");
                                key.SetValue("InstallLocation", targetDir);
                                key.SetValue("UninstallString", "\"" + uninstExe + "\"");
                                key.SetValue("QuietUninstallString", "\"" + uninstExe + "\" --uninstall");
                                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                                key.SetValue("EstimatedSize", 19484, RegistryValueKind.DWord);
                            }
                        }
                    } catch {}
                }
            } catch {}
        }

        private static string DetectLatestVersion(out string directDownloadUrl) {
            directDownloadUrl = null;
            string url = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json?t=" + DateTime.UtcNow.Ticks;

            try {
                using (IPv4WebClient wc = new IPv4WebClient(2000)) {
                    wc.Headers.Add("User-Agent", "GIN-VPN-Installer");
                    string content = wc.DownloadString(url).Trim();
                    if (!string.IsNullOrEmpty(content) && content.StartsWith("{")) {
                        Match mv = Regex.Match(content, "\"version\"\\s*:\\s*\"([^\"]+)\"");
                        Match mu = Regex.Match(content, "\"download_url\"\\s*:\\s*\"([^\"]+)\"");
                        if (mu.Success) directDownloadUrl = mu.Groups[1].Value.Trim();
                        if (mv.Success) return mv.Groups[1].Value.Trim();
                    }
                }
            } catch {}

            return FALLBACK_VERSION;
        }

        private static bool VerifyBinaryVersion(string filePath, string targetVer) {
            try {
                FileInfo fi = new FileInfo(filePath);
                if (fi.Length < 12000000) return false;

                byte[] pattern = System.Text.Encoding.ASCII.GetBytes(targetVer);
                using (FileStream fs = File.OpenRead(filePath)) {
                    byte[] buffer = new byte[65536];
                    int bytesRead;
                    int matched = 0;
                    while ((bytesRead = fs.Read(buffer, 0, buffer.Length)) > 0) {
                        for (int i = 0; i < bytesRead; i++) {
                            if (buffer[i] == pattern[matched]) {
                                matched++;
                                if (matched == pattern.Length) return true;
                            } else {
                                matched = (buffer[i] == pattern[0]) ? 1 : 0;
                            }
                        }
                    }
                }
            } catch {}
            return false;
        }

        private static void KillProcess(string name) {
            try {
                foreach (var p in Process.GetProcessesByName(name)) {
                    try { p.Kill(); } catch {}
                }
            } catch {}
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDir, string description) {
            try {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                if (shellType == null) return;
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath = targetPath;
                shortcut.WorkingDirectory = workingDir;
                shortcut.IconLocation = targetPath + ",0";
                shortcut.Description = description;
                shortcut.Save();
            } catch {}
        }

        private class MirrorEntry {
            public string Name { get; set; }
            public string Url { get; set; }
            public MirrorEntry(string name, string url) {
                Name = name;
                Url = url;
            }
        }
    }
}
