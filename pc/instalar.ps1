# Instalador do Vida para PC (Windows 10/11). So ASCII neste arquivo (e lido pela internet).
# Baixa o motor oficial do Electron e o app do repositorio de versoes, confere o SHA-256 dos dois,
# instala em %LOCALAPPDATA%\Programs\Vida e cria atalhos. Os dados ficam em %APPDATA%\Vida (reinstalar nao apaga).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem
$base  = 'https://raw.githubusercontent.com/davidcardozowow-cmd/vida-app-releases/main/'
$elVer = '45.2.1'
$elSha = '7c342aee45d5b4ccafe5dfe9037028796b082735a576e21e2b4e2d8422ebb727'
$dest  = Join-Path $env:LOCALAPPDATA 'Programs\Vida'
$tmp   = Join-Path $env:TEMP ('vida-inst-' + [guid]::NewGuid().ToString('N'))
function Baixar($url, $arq, $sha) {
  Invoke-WebRequest -Uri $url -OutFile $arq -UseBasicParsing
  $h = (Get-FileHash $arq -Algorithm SHA256).Hash.ToLower()
  if ($h -ne $sha) { throw "Arquivo diferente do esperado: $url" }
}
try {
  Write-Host ''
  Write-Host 'Vida para PC - instalando. Leva alguns minutos, nao feche esta janela.' -ForegroundColor Cyan
  New-Item -ItemType Directory -Path $tmp | Out-Null
  Get-Process -Name Vida -ErrorAction SilentlyContinue | Stop-Process -Force
  $info = (Invoke-WebRequest -Uri ($base + 'latest.json?t=' + [DateTime]::Now.Ticks) -UseBasicParsing).Content | ConvertFrom-Json
  $pc = $info.pc
  Write-Host '1/3 Baixando o motor (Electron, cerca de 160 MB)...'
  $ez = Join-Path $tmp 'electron.zip'
  Baixar "https://github.com/electron/electron/releases/download/v$elVer/electron-v$elVer-win32-x64.zip" $ez $elSha
  Write-Host ('2/3 Baixando o Vida ' + $pc.versionName + '...')
  $az = Join-Path $tmp 'app.zip'
  Baixar ($base + $pc.app) $az $pc.appSha256
  Write-Host '3/3 Instalando...'
  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  [IO.Compression.ZipFile]::ExtractToDirectory($ez, $dest)
  Rename-Item (Join-Path $dest 'electron.exe') 'Vida.exe'
  Remove-Item (Join-Path $dest 'resources\default_app.asar') -ErrorAction SilentlyContinue
  Get-ChildItem (Join-Path $dest 'locales') -Filter *.pak | Where-Object { @('pt-BR.pak', 'en-US.pak') -notcontains $_.Name } | Remove-Item
  [IO.Compression.ZipFile]::ExtractToDirectory($az, (Join-Path $dest 'resources\app'))
  $exe = Join-Path $dest 'Vida.exe'
  $ico = Join-Path $dest 'resources\app\recursos\icone.ico'
  $ws = New-Object -ComObject WScript.Shell
  foreach ($pasta in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $l = $ws.CreateShortcut((Join-Path $pasta 'Vida.lnk'))
    $l.TargetPath = $exe; $l.WorkingDirectory = $dest; $l.IconLocation = $ico; $l.Description = 'Vida'
    $l.Save()
  }
  Start-Process -FilePath $exe
  Write-Host ''
  Write-Host 'Pronto! O Vida abriu e ganhou um atalho na Area de Trabalho.' -ForegroundColor Green
} catch {
  Write-Host ''
  Write-Host ('Nao deu para instalar: ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host 'Confira a internet e tente de novo. Se repetir, mande um print desta janela.'
} finally {
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
