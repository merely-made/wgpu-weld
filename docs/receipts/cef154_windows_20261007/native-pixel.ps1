param(
    [ValidateRange(10,180)][int] $TimeoutSeconds = 90,
    [ValidatePattern('^[a-z0-9-]+$')][string] $OutputName = 'native-pixel-client'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$bundle = 'C:/t/cargo-targets/wgpu-weld/bundle/cef154'
$exe = Join-Path $bundle 'demo-weld-win.exe'
$client = (Resolve-Path -LiteralPath (Join-Path $bundle 'demo-weld-win.dll')).Path
$output = Join-Path $PSScriptRoot $OutputName
$cache = Join-Path $PSScriptRoot ('.profiles/cef154-' + $OutputName)
foreach ($path in @($output,$cache)) { if (Test-Path -LiteralPath $path) { throw "Refusing existing native output/profile: $path" } }
if (-not (Test-Path -LiteralPath $exe)) { throw 'Build the matching sandboxed bundle first' }
$fingerprint = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'source-before-native-client.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($input in $fingerprint.inputs.PSObject.Properties) {
    $path = Join-Path $repo $input.Name
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower() -ne $input.Value) { throw "Source input changed: $($input.Name)" }
}
New-Item -ItemType Directory -Path $output,$cache | Out-Null
$env:CEF_PATH = $bundle
$env:WELD_CACHE_ROOT = $cache
$env:WELD_PROFILE = Join-Path $cache 'profile'
$env:WELD_PIXEL_FIXTURE = '1'
$env:WELD_EXIT_AFTER_FRAMES = '2'
$env:WELD_TIMEOUT_SECS = '30'
$env:RUST_LOG = 'info'
$utf8 = [Text.UTF8Encoding]::new($false)
$info = [Diagnostics.ProcessStartInfo]::new()
$info.FileName = $exe
$info.WorkingDirectory = $repo
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$info.StandardOutputEncoding = $utf8
$info.StandardErrorEncoding = $utf8
$process = [Diagnostics.Process]::new()
$process.StartInfo = $info
$exeHash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLower()
$clientHash = (Get-FileHash -LiteralPath $client -Algorithm SHA256).Hash.ToLower()
$started = [DateTime]::UtcNow
if (-not $process.Start()) { throw 'Native process did not start' }
$process.PriorityClass = 'BelowNormal'
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
$modules = @{}
$limitations = [Collections.Generic.List[string]]::new()
$timedOut = $false
while (-not $process.WaitForExit(200)) {
    if (([DateTime]::UtcNow - $started).TotalSeconds -ge $TimeoutSeconds) { $timedOut=$true; $process.Kill(); break }
    try {
        $process.Refresh()
        foreach ($module in $process.Modules) {
            if ($module.ModuleName -match '^(demo-weld-win|libcef|libEGL|libGLESv2|d3d11|d3d12|dxgi|dxcompiler)\.dll$' -and -not $modules.ContainsKey($module.FileName)) {
                $modules[$module.FileName] = @{ path=$module.FileName; sha256=(Get-FileHash -LiteralPath $module.FileName -Algorithm SHA256).Hash.ToLower() }
            }
        }
    } catch { if (-not $limitations.Contains($_.Exception.Message)) { $limitations.Add($_.Exception.Message) } }
}
$process.WaitForExit()
$outText = $stdout.GetAwaiter().GetResult()
$errText = $stderr.GetAwaiter().GetResult()
[IO.File]::WriteAllText((Join-Path $output 'stdout.log'), $outText, $utf8)
[IO.File]::WriteAllText((Join-Path $output 'stderr.log'), $errText, $utf8)
$unchangedExe = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLower() -eq $exeHash
$unchangedClient = (Get-FileHash -LiteralPath $client -Algorithm SHA256).Hash.ToLower() -eq $clientHash
$passed = $unchangedClient -and -not $timedOut -and $process.ExitCode -eq 0 -and $unchangedExe -and ($outText+$errText).Contains('PIXEL FIXTURE PASS')
$record = @{ command=@($exe); pid=$process.Id; started_utc=$started.ToString('o'); finished_utc=[DateTime]::UtcNow.ToString('o'); exit_code=$process.ExitCode; timeout=$timedOut; executable_sha256=$exeHash; client_dll=$client; client_dll_sha256=$clientHash; client_dll_unchanged=$unchangedClient; executable_unchanged=$unchangedExe; cef_path=$bundle; cache_root=$cache; profile=$env:WELD_PROFILE; pixel_fixture=1; exit_after_frames=2; native_timeout_seconds=30; supervisor_deadline_seconds=$TimeoutSeconds; modules=@($modules.Values); module_observer_limitations=@($limitations); passed=$passed }
[IO.File]::WriteAllText((Join-Path $output 'process-result.json'), ($record | ConvertTo-Json -Depth 7), $utf8)
Write-Output "Native pixel gate: exit=$($process.ExitCode), timeout=$timedOut, pass=$passed"
Write-Output $errText
if (-not $passed) { exit 1 }
