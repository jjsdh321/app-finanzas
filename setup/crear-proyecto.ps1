# Tarea 1: crea el proyecto Flutter y el repositorio git
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
Start-Transcript -Path (Join-Path $PSScriptRoot 'crear-proyecto.log') -Force
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
if (-not (Test-Path '.git')) { git init -b main }
git config user.name 'Jose'
git config user.email 'joselorenteleon2@gmail.com'
flutter create --org com.jose --project-name finanzas --platforms android,web .
flutter pub add flutter_riverpod drift drift_flutter sqlite3_flutter_libs fl_chart intl share_plus file_picker
flutter pub add flutter_localizations --sdk=flutter
flutter pub add dev:drift_dev dev:build_runner
Add-Content .gitignore "`n# registros de los scripts`nsetup/*.log`n"
git add -A
git commit -m 'chore: crear proyecto Flutter con dependencias'
flutter --version
Stop-Transcript
Read-Host 'PROYECTO CREADO. Pulsa Enter para cerrar'
