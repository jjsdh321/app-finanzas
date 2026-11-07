# Paso 1: instala Git, VS Code, Android Studio y Flutter
$ErrorActionPreference = 'Continue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'instalar-1.log') -Force
$opts = @('-e','--accept-source-agreements','--accept-package-agreements')
Write-Host '== Git ==';            winget install --id Git.Git @opts
Write-Host '== VS Code ==';        winget install --id Microsoft.VisualStudioCode @opts
Write-Host '== Android Studio =='; winget install --id Google.AndroidStudio @opts
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
Write-Host '== Flutter =='
if (-not (Test-Path 'C:\dev\flutter')) {
  New-Item -ItemType Directory -Force 'C:\dev' | Out-Null
  git clone https://github.com/flutter/flutter.git -b stable C:\dev\flutter
}
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
if ($null -eq $userPath) { $userPath = '' }
if ($userPath -notlike '*C:\dev\flutter\bin*') {
  [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';C:\dev\flutter\bin'), 'User')
}
$env:Path += ';C:\dev\flutter\bin'
flutter --version
Write-Host '== Extension Flutter para VS Code =='
code --install-extension Dart-Code.flutter
Stop-Transcript
Read-Host 'PASO 1 TERMINADO. Pulsa Enter para cerrar'
