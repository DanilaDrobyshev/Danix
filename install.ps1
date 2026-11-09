<#
.SYNOPSIS
  Installs or updates Danix on Windows (no admin rights) and connects it to Claude Code. Non-interactive: an AI agent
  can run it as is.

.DESCRIPTION
  1. Takes the latest release of the Danix repository on GitHub (or -Version), downloads the installer
     Danix-<version>-win-x64-setup.exe and SHA256SUMS.txt and checks its SHA-256. Stops if it does not match.
  2. Runs the installer silently for the current user (no admin) into %LOCALAPPDATA%\Programs\Danix (or -Dir): the
     folder goes to PATH and Apps, and Danix then updates itself with "Update". Your data (strategies, bots, settings,
     keys) lives in the user folder %LOCALAPPDATA%\Danix and is never touched by an update or by -Uninstall.
  3. Checks the Microsoft Visual C++ runtime (x64) and says how to install it if it is missing.
  4. If the `claude` command (Claude Code) is in PATH, registers the MCP server: claude mcp add danix --scope user,
     with the research profile (strategies and backtests, no trading requests) unless -McpProfile full.
  5. Prints the path to Danix.exe and ready MCP configs for Claude Desktop, Cursor and VS Code.
  Exit code 0 = done, 1 = failed (the message says why).

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DanilaDrobyshev/Danix/main/install.ps1 | iex"
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Version 0.2.0 -McpProfile full
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Uninstall
#>
param(
    [string]$Version = '',                                     # e.g. 0.2.0; empty = latest release
    [string]$Dir = '',                                         # install folder; default %LOCALAPPDATA%\Programs\Danix
    [ValidateSet('research', 'full')][string]$McpProfile = 'research', # research: strategies and backtests only; full: also trading requests, each confirmed by you in Danix
    [switch]$NoMcp,                                            # do not run `claude mcp add`
    [switch]$Uninstall,                                        # remove the program (your data stays)
    [string]$SetupPath = '',                                   # install from a local Danix-*-setup.exe instead of GitHub
    [string]$SumsPath = '',                                    # SHA256SUMS.txt for -SetupPath (default: next to it)
    [string]$Repo = 'DanilaDrobyshev/Danix'   # GitHub repository with the releases
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Fail([string]$message) {
    Write-Host "Danix install failed: $message" -ForegroundColor Red
    exit 1
}
function Info([string]$message) { Write-Host $message }

if (-not $Dir) { $Dir = Join-Path $env:LOCALAPPDATA 'Programs\Danix' }
$Dir = [IO.Path]::GetFullPath($Dir)
$exe = Join-Path $Dir 'Danix.exe'
$dataDir = Join-Path $env:LOCALAPPDATA 'Danix'
$claude = Get-Command claude -ErrorAction SilentlyContinue

function Test-DanixRunning {
    # Danix.exe from the install folder is running (Danix itself or an MCP client keeps it): files can't be replaced
    $running = Get-Process -Name Danix -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq $exe) } catch { $false }
    }
    return @($running).Count -gt 0
}

function Remove-ClaudeMcp {
    if (-not $claude) { return }
    # No entry yet: claude answers with an error, that is fine
    $ErrorActionPreference = 'Continue'
    & $claude.Source mcp remove danix --scope user 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
}

# ---------- uninstall ----------

if ($Uninstall) {
    if (-not (Test-Path -LiteralPath $exe)) { Fail "Danix is not installed in $Dir" }
    if (Test-DanixRunning) { Fail "Danix.exe in $Dir is running. Quit Danix (quit in its console) and close MCP clients (Claude Desktop, Cursor, VS Code), then run this again." }
    if (-not $NoMcp) { Remove-ClaudeMcp }
    $uninstaller = Get-ChildItem -LiteralPath $Dir -Filter 'unins*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($uninstaller) {
        # Installed by Setup: its uninstaller also removes the folder from PATH and the Apps entry
        $p = Start-Process -FilePath $uninstaller.FullName -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
        if ($p.ExitCode -ne 0) { Fail "the uninstaller exited with code $($p.ExitCode)" }
    }
    elseif (Test-Path -LiteralPath (Join-Path $Dir 'installed.txt')) {
        # Unpacked by an older install.ps1 (0.2.1 and before)
        Remove-Item -LiteralPath $Dir -Recurse -Force
    }
    else { Fail "$Dir was not created by this installer: remove it by hand." }
    Info "Danix removed from $Dir."
    Info "Your data was not touched: $dataDir (strategies, bots, settings, keys). Delete that folder yourself if you no longer need it."
    Info 'Remove the "danix" entry from Claude Desktop / Cursor / VS Code MCP configs if you added it.'
    exit 0
}

# ---------- download ----------

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('danix-install-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    if ($SetupPath) {
        if (-not (Test-Path -LiteralPath $SetupPath)) { Fail "no file $SetupPath" }
        $setup = (Resolve-Path -LiteralPath $SetupPath).Path
        if (-not $SumsPath) { $SumsPath = Join-Path (Split-Path $setup) 'SHA256SUMS.txt' }
        if (-not (Test-Path -LiteralPath $SumsPath)) { Fail "no checksum file $SumsPath" }
        $sums = $SumsPath
        Info "Installing from $setup"
    }
    else {
        $api = if ($Version) { "https://api.github.com/repos/$Repo/releases/tags/v$($Version.TrimStart('v'))" } else { "https://api.github.com/repos/$Repo/releases/latest" }
        try { $release = Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{ 'User-Agent' = 'danix-install' } }
        catch { Fail "can't read the release from $api ($($_.Exception.Message)). Check the internet connection and that the release exists." }
        # Danix-X.Y.Z-win-x64-setup.exe since 0.2.2, DanixSetup-X.Y.Z.exe before
        $setupAsset = $release.assets | Where-Object { $_.name -like 'Danix-*-win-x64-setup.exe' -or $_.name -like 'DanixSetup-*.exe' } | Select-Object -First 1
        $sumsAsset = $release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1
        if (-not $setupAsset) { Fail "release $($release.tag_name) has no Danix-*-win-x64-setup.exe" }
        if (-not $sumsAsset) { Fail "release $($release.tag_name) has no SHA256SUMS.txt" }
        $setup = Join-Path $tmp $setupAsset.name
        $sums = Join-Path $tmp 'SHA256SUMS.txt'
        Info "Downloading Danix $($release.tag_name): $($setupAsset.name) ($([math]::Round($setupAsset.size / 1MB, 1)) MB)"
        try {
            Invoke-WebRequest -Uri $setupAsset.browser_download_url -OutFile $setup -UseBasicParsing -Headers @{ 'User-Agent' = 'danix-install' }
            Invoke-WebRequest -Uri $sumsAsset.browser_download_url -OutFile $sums -UseBasicParsing -Headers @{ 'User-Agent' = 'danix-install' }
        }
        catch { Fail "download failed: $($_.Exception.Message)" }
    }

    # ---------- checksum ----------

    $setupName = Split-Path $setup -Leaf
    $expected = Get-Content -LiteralPath $sums | ForEach-Object {
        $m = [regex]::Match($_, '^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$')
        if ($m.Success -and $m.Groups[2].Value -eq $setupName) { $m.Groups[1].Value.ToLowerInvariant() }
    } | Select-Object -First 1
    if (-not $expected) { Fail "SHA256SUMS.txt has no line for $setupName" }
    $actual = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { Fail "SHA-256 of $setupName does not match SHA256SUMS.txt (expected $expected, got $actual). The file is damaged or not the official one." }
    Info "SHA-256 OK: $actual"

    # ---------- install ----------

    if (Test-Path -LiteralPath $Dir) {
        if (Test-DanixRunning) { Fail "Danix.exe in $Dir is running. Quit Danix (quit in its console) and close MCP clients (Claude Desktop, Cursor, VS Code), then run this again." }
        $hasSetup = Get-ChildItem -LiteralPath $Dir -Filter 'unins*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ((Get-ChildItem -LiteralPath $Dir -Force | Select-Object -First 1) -and -not $hasSetup -and -not (Test-Path -LiteralPath (Join-Path $Dir 'installed.txt'))) {
            Fail "$Dir already exists and was not created by this installer. Pick another folder with -Dir."
        }
        # A copy unpacked by an older install.ps1: Setup takes it over (same folder, data stays in %LOCALAPPDATA%\Danix)
    }
    # Setup for the current user, no admin, no windows: registers the folder, so Danix updates itself ("Update")
    $setupArgs = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER', "/DIR=`"$Dir`"", "/LOG=`"$tmp\setup.log`"")
    $p = Start-Process -FilePath $setup -ArgumentList $setupArgs -Wait -PassThru
    if ($p.ExitCode -ne 0) {
        $log = if (Test-Path -LiteralPath "$tmp\setup.log") { (Get-Content -LiteralPath "$tmp\setup.log" -Tail 15) -join "`n" } else { '' }
        Fail "Setup exited with code $($p.ExitCode).`n$log"
    }
    if (-not (Test-Path -LiteralPath $exe)) { Fail "Setup finished, but there is no $exe" }
    Info "Installed: $exe"
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------- Visual C++ runtime ----------

$sys = Join-Path $env:SystemRoot 'System32'
$vcOk = (Test-Path (Join-Path $sys 'vcruntime140.dll')) -and (Test-Path (Join-Path $sys 'msvcp140.dll')) -and (Test-Path (Join-Path $sys 'vcruntime140_1.dll'))
if (-not $vcOk) {
    Write-Host 'Microsoft Visual C++ Redistributable (x64) is missing: Danix.exe needs it. Install it with' -ForegroundColor Yellow
    Write-Host '  winget install --id Microsoft.VCRedist.2015+.x64 -e' -ForegroundColor Yellow
    Write-Host '  or https://aka.ms/vs/17/release/vc_redist.x64.exe (needs admin rights once), then run this installer again.' -ForegroundColor Yellow
    exit 1
}

# Danix.exe starts and finds its data folder
$where = & $exe --where 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Fail "Danix.exe --where failed (exit $LASTEXITCODE): $where" }

# ---------- MCP ----------

$mcpArgs = @('--mcp')
if ($McpProfile -eq 'research') { $mcpArgs += @('--profile', 'research') }

$claudeDone = $false
if ($claude -and -not $NoMcp) {
    Remove-ClaudeMcp
    $out = & $claude.Source mcp add danix --scope user -- $exe @mcpArgs 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { $claudeDone = $true; Info 'Claude Code: MCP server "danix" added (scope user). Restart Claude Code sessions to load it.' }
    else { Write-Host "Claude Code: claude mcp add failed: $($out.Trim())" -ForegroundColor Yellow }
}

$exeJson = $exe.Replace('\', '\\')
$argsJson = ($mcpArgs | ForEach-Object { '"' + $_ + '"' }) -join ', '
Info ''
Info "Danix is installed: $exe"
Info "Data folder: $dataDir (Danix.exe --where shows it)"
Info 'Start the app: double-click Danix.exe (the interface opens at http://127.0.0.1:7717/).'
if (-not $claudeDone) {
    Info ''
    Info 'Claude Code (when installed):'
    Info ("  claude mcp add danix --scope user -- `"{0}`" {1}" -f $exe, ($mcpArgs -join ' '))
}
Info ''
Info "Claude Desktop ($env:APPDATA\Claude\claude_desktop_config.json) and Cursor (~/.cursor/mcp.json), merge into mcpServers:"
Info ('{ "mcpServers": { "danix": { "command": "' + $exeJson + '", "args": [' + $argsJson + '] } } }')
Info ''
Info 'VS Code (.vscode/mcp.json or the user mcp.json):'
Info ('{ "servers": { "danix": { "type": "stdio", "command": "' + $exeJson + '", "args": [' + $argsJson + '] } } }')
exit 0
