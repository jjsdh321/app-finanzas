# Conecta el proyecto con tu repositorio de GitHub y sube el codigo
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
Start-Transcript -Path (Join-Path $PSScriptRoot 'conectar-github.log') -Force
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
New-Item -ItemType Directory -Force '.github\workflows' | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'deploy-web.yml') '.github\workflows\deploy-web.yml' -Force
$usuario = Read-Host 'Escribe tu nombre de usuario de GitHub'
git remote remove origin 2>$null
git remote add origin "https://github.com/$usuario/app-finanzas.git"
git add -A
git commit -m 'ci: publicar version web en GitHub Pages'
Write-Host 'Subiendo... (si se abre el navegador, inicia sesion en GitHub y autoriza)'
git push -u origin main
Write-Host "WEB: https://$usuario.github.io/app-finanzas/"
Stop-Transcript
Read-Host 'TERMINADO. Pulsa Enter para cerrar'
