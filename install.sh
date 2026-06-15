#!/usr/bin/env bash
# tjocr — instalador de 1 comando para Linux / WSL
#
#   curl -fsSL https://raw.githubusercontent.com/marcosmarf27/tjocr/main/install.sh | bash
#
# Passando a chave de forma não interativa:
#   curl -fsSL https://raw.githubusercontent.com/marcosmarf27/tjocr/main/install.sh | TJOCR_API_KEY=tjp_xxx bash
#
# Rodar de novo apenas ATUALIZA para a última versão (idempotente).
set -euo pipefail

REPO="marcosmarf27/tjocr"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "${GREEN}▸${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
err()  { printf "${RED}✗ %s${NC}\n" "$1" >&2; }

printf "\n${BOLD}tjocr — OCR de PDFs → Markdown${NC}\n\n"

# 1. Detecta plataforma (só shipamos amd64 para Linux/WSL)
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
  Linux) ASSET="tjocr_linux_amd64" ;;
  Darwin) err "macOS ainda não tem binário pronto (só Windows e Linux/WSL). Compile de cli-go/ se precisar."; exit 1 ;;
  *) err "Sistema não suportado: $OS"; exit 1 ;;
esac
case "$ARCH" in
  x86_64|amd64) : ;;
  *) err "Arquitetura não suportada: $ARCH (apenas amd64/x86_64)."; exit 1 ;;
esac

URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

# 2. Baixa o binário da última release
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
info "Baixando a última versão do tjocr (${OS}/${ARCH})…"
if command -v curl >/dev/null 2>&1; then
  curl -fSL --progress-bar "$URL" -o "$TMP/tjocr"
elif command -v wget >/dev/null 2>&1; then
  wget -q --show-progress "$URL" -O "$TMP/tjocr"
else
  err "Preciso de 'curl' ou 'wget' instalado."; exit 1
fi
chmod +x "$TMP/tjocr"

# 3. Instala no PATH do usuário (reusa o subcomando 'install' do binário → ~/.local/bin/tjocr)
info "Instalando no PATH…"
"$TMP/tjocr" install >/dev/null

TJOCR="$HOME/.local/bin/tjocr"
[ -x "$TJOCR" ] || TJOCR="$(command -v tjocr 2>/dev/null || echo "$TJOCR")"
info "Instalado: $("$TJOCR" version 2>/dev/null || echo tjocr)"

# 4. Configura a API key
if "$TJOCR" config show 2>/dev/null | grep -q 'configurada'; then
  # "(não configurada)" → ainda sem chave
  if [ -n "${TJOCR_API_KEY:-}" ]; then
    "$TJOCR" config set-key "$TJOCR_API_KEY" >/dev/null
    info "API key configurada a partir de \$TJOCR_API_KEY."
  elif [ -r /dev/tty ]; then
    printf "${BOLD}Cole sua API key da TecJustiça e tecle Enter${NC} (ou deixe vazio p/ configurar depois): "
    IFS= read -r KEY < /dev/tty || KEY=""
    if [ -n "$KEY" ]; then
      "$TJOCR" config set-key "$KEY" >/dev/null
      info "API key salva em ~/.config/tjocr/config.json (permissão 0600)."
    else
      warn "Sem chave por ora. Configure depois com:  tjocr config set"
    fi
  else
    warn "Configure a chave depois com:  tjocr config set   (pegue a key no dashboard da TecJustiça)"
  fi
else
  info "API key já configurada (troque com 'tjocr config set' se precisar)."
fi

# 5. Aviso de PATH
case ":${PATH}:" in
  *":$HOME/.local/bin:"*) : ;;
  *) warn "Adicione ao seu ~/.bashrc e reabra o terminal:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

printf "\n${GREEN}${BOLD}✓ tjocr pronto!${NC}  Teste:  ${BOLD}tjocr documento.pdf -o documento.md${NC}\n\n"
