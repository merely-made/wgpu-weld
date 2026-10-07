param(
    [ValidateSet('update','check','test','build','bundle')][string] $Gate,
    [ValidatePattern('^[a-z0-9-]+$')][string] $Label = ''
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location -LiteralPath $repo
$env:CARGO_TARGET_DIR = 'C:/t/cargo-targets/wgpu-weld'
$env:CARGO_BUILD_JOBS = '1'
$env:CEF_PATH = 'C:/Users/mark_/Code/cef-cache/wgpu-weld/154.0.34/cef_windows_x86_64'
$env:LIBCLANG_PATH = 'C:/Program Files/LLVM/bin'
$env:PATH = 'C:/Program Files/LLVM/bin;' + $env:PATH
$vcvars = 'C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat'
$toolEnvironment = & cmd.exe /d /s /c ('call "' + $vcvars + '" >nul && set')
if ($LASTEXITCODE -ne 0) { throw 'VS native environment initialization failed' }
foreach ($line in $toolEnvironment) {
    if ($line -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process') }
}
$arguments = switch ($Gate) {
    'update' { @('+1.97.1','update','-p','cef','--precise','154.5.0+154.0.34') }
    'check' { @('+1.97.1','check','--locked','-p','welding','-p','demo-weld-win','--all-targets','-j','1') }
    'test' { @('+1.97.1','test','--locked','-p','welding','--lib','--features','cef-runtime','-j','1') }
    'build' { @('+1.97.1','build','--locked','-p','demo-weld-win','-j','1') }
    'bundle' { @('+1.97.1','run','--locked','-p','demo-weld-win','--bin','bundle-demo-weld-win','-j','1','--', 'C:/t/cargo-targets/wgpu-weld/bundle/cef154') }
}
$outputName = if ($Label) { $Label } else { $Gate }
$stdout = Join-Path $PSScriptRoot ($outputName + '.stdout.log')
$stderr = Join-Path $PSScriptRoot ($outputName + '.stderr.log')
$result = Join-Path $PSScriptRoot ($outputName + '.result.json')
foreach ($path in @($stdout,$stderr,$result)) { if (Test-Path -LiteralPath $path) { throw "Refusing existing gate output: $path" } }
$start = [DateTime]::UtcNow
$process = Start-Process -FilePath (Get-Command cargo.exe).Source -ArgumentList $arguments -WorkingDirectory $repo -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle
try { $process.PriorityClass = 'BelowNormal' } catch { if (-not $process.HasExited) { throw } }
Write-Output "Started $Gate cargo PID $($process.Id), one job, BelowNormal"
$process.WaitForExit()
if ($null -eq $process.ExitCode) { throw 'Native Cargo exit code unavailable; gate cannot pass' }
@{ gate=$Gate; command=@('cargo')+$arguments; cwd=$repo; pid=$process.Id; started_utc=$start.ToString('o'); finished_utc=[DateTime]::UtcNow.ToString('o'); exit_code=$process.ExitCode; target=$env:CARGO_TARGET_DIR; cef_path=$env:CEF_PATH; libclang_path=$env:LIBCLANG_PATH; jobs=1; priority='BelowNormal' } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $result -Encoding utf8
Get-Content -LiteralPath $stderr -Tail 35 -Encoding UTF8
exit $process.ExitCode
