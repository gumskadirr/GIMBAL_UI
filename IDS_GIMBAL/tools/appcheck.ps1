# Starts the real and the demo application, closes each after 3 s and prints whether it was still running, its exit
# code and its stderr. Expected: alive3s=True exit=0 stderr=[]. Called by tools/verify.sh.
$ErrorActionPreference = 'Stop'
$qt = if ($env:QT_ROOT) { $env:QT_ROOT } else { 'C:\Qt' }
$env:PATH = "$qt\6.12.0\mingw_64\bin;$qt\Tools\mingw1310_64\bin;$env:PATH"
foreach ($exe in 'appIDS_GIMBAL.exe','appIDS_GIMBALDemo.exe') {
  $p = Get-ChildItem -Recurse build/cli-debug -Filter $exe | Select-Object -First 1
  $err = [IO.Path]::GetTempFileName()
  $proc = Start-Process $p.FullName -PassThru -RedirectStandardError $err; $null = $proc.Handle
  Start-Sleep 3
  $alive = -not $proc.HasExited
  [void]$proc.CloseMainWindow(); $proc.WaitForExit(5000) | Out-Null
  if (-not $proc.HasExited) { $proc.Kill(); "$exe KILLED" }
  "$exe alive3s=$alive exit=$($proc.ExitCode) stderr=[$((Get-Content $err -Raw) -replace '\s+$','')]"
}
