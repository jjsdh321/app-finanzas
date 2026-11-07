# Paso 2: acepta licencias de Android y revisa la instalacion
$ErrorActionPreference = 'Continue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'instalar-2.log') -Force
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
("y`n" * 30) | flutter doctor --android-licenses
flutter doctor -v
Stop-Transcript
Read-Host 'PASO 2 TERMINADO. Pulsa Enter para cerrar'
