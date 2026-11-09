# Analiza, ejecuta los tests y compila la web. Si todo va bien, guarda el avance en git.
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
Start-Transcript -Path (Join-Path $PSScriptRoot 'probar.log') -Force
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$borrar = Join-Path $PSScriptRoot 'borrar.txt'
if (Test-Path $borrar) { Get-Content $borrar | Where-Object { $_ -and (Test-Path $_) } | ForEach-Object { Remove-Item $_ -Recurse -Force; Write-Host "Borrado: $_" }; Remove-Item $borrar }
flutter pub get
$gen = Get-ChildItem -Path lib -Recurse -Filter *.dart | Where-Object { Select-String -Path $_.FullName -Pattern 'part .*\.g\.dart' -Quiet }
if ($gen) { dart run build_runner build }
flutter analyze;              $okAnalyze = ($LASTEXITCODE -eq 0)
flutter test;                 $okTest = ($LASTEXITCODE -eq 0)
flutter build web --release;  $okWeb = ($LASTEXITCODE -eq 0)
Write-Host "RESULTADO analyze=$okAnalyze test=$okTest web=$okWeb"
$msgFile = Join-Path $PSScriptRoot 'commit-msg.txt'
if ($okAnalyze -and $okTest -and $okWeb -and (Test-Path $msgFile)) {
  git add -A
  git commit -F $msgFile
  Remove-Item $msgFile
  Write-Host 'GUARDADO EN GIT'
  if (git remote) { git push; Write-Host 'SUBIDO A GITHUB (la web se actualiza en 2-3 minutos)' }
}
Stop-Transcript
if ($okAnalyze -and $okTest -and $okWeb) { Read-Host 'TODO CORRECTO. Pulsa Enter para cerrar' }
else { Read-Host 'HAY ERRORES (Claude los revisara). Pulsa Enter para cerrar' }
