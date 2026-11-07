# Analiza, ejecuta los tests y compila la web. Si todo va bien, guarda el avance en git.
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
Start-Transcript -Path (Join-Path $PSScriptRoot 'probar.log') -Force
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
flutter pub get
if (Select-String -Path pubspec.yaml -Pattern 'build_runner' -Quiet) {
  if (Get-ChildItem -Path lib -Recurse -Filter *.dart | Select-String -Pattern "part '.*\.g\.dart'" -Quiet) {
    dart run build_runner build --delete-conflicting-outputs
  }
}
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
}
Stop-Transcript
if ($okAnalyze -and $okTest -and $okWeb) { Read-Host 'TODO CORRECTO. Pulsa Enter para cerrar' }
else { Read-Host 'HAY ERRORES (Claude los revisara). Pulsa Enter para cerrar' }
