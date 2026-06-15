# tjocr — instalador de 1 comando para Windows (PowerShell)
#
#   irm https://raw.githubusercontent.com/marcosmarf27/tjocr/main/install.ps1 | iex
#
# Passando a chave de forma não interativa:
#   $env:TJOCR_API_KEY="tjp_xxx"; irm https://raw.githubusercontent.com/marcosmarf27/tjocr/main/install.ps1 | iex
#
# Rodar de novo apenas ATUALIZA para a última versão (idempotente).

$ErrorActionPreference = 'Stop'
$repo  = 'marcosmarf27/tjocr'
$asset = 'tjocr_windows_amd64.exe'
$url   = "https://github.com/$repo/releases/latest/download/$asset"

function Info($m) { Write-Host "▸ $m" -ForegroundColor Green }
function Warn($m) { Write-Host "⚠ $m" -ForegroundColor Yellow }

Write-Host ""
Write-Host "tjocr — OCR de PDFs → Markdown" -ForegroundColor White
Write-Host ""

# 1. Baixa o binário da última release
Info "Baixando a última versão do tjocr (Windows x64)…"
$tmp = Join-Path $env:TEMP ("tjocr_dl_" + [guid]::NewGuid().ToString('N') + ".exe")
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing

# 2. Instala no PATH do usuário (subcomando 'install' → %LOCALAPPDATA%\Programs\tjocr + User PATH)
Info "Instalando no PATH…"
& $tmp install | Out-Null
Remove-Item $tmp -ErrorAction SilentlyContinue

$tjocr = Join-Path $env:LOCALAPPDATA 'Programs\tjocr\tjocr.exe'
if (-not (Test-Path $tjocr)) { $tjocr = 'tjocr' }
Info ("Instalado: " + (& $tjocr version))

# 3. Configura a API key
$cfg = (& $tjocr config show 2>$null | Out-String)
if ($cfg -match 'configurada') {
  # "(não configurada)" → ainda sem chave
  if ($env:TJOCR_API_KEY) {
    & $tjocr config set-key $env:TJOCR_API_KEY | Out-Null
    Info 'API key configurada a partir de $env:TJOCR_API_KEY.'
  } else {
    $key = Read-Host 'Cole sua API key da TecJustiça (ou Enter p/ configurar depois)'
    if ($key) {
      & $tjocr config set-key $key | Out-Null
      Info 'API key salva no config do usuário (permissão restrita).'
    } else {
      Warn 'Sem chave por ora. Configure depois com:  tjocr config set'
    }
  }
} else {
  Info "API key já configurada (troque com 'tjocr config set' se precisar)."
}

Write-Host ""
Write-Host "✓ tjocr pronto!  Teste:  tjocr documento.pdf -o documento.md" -ForegroundColor Green
Warn "Se 'tjocr' não for reconhecido, REABRA o terminal (o PATH novo só vale em janelas abertas a seguir)."
