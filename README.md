# tjocr — OCR de PDFs (TecJustiça)

CLI que extrai texto de **PDFs** (OCR) e devolve **Markdown**, via a API de OCR da TecJustiça.
Binário único, **sem dependências** — não precisa de Python, Node nem Go instalados.

```bash
tjocr documento.pdf -o documento.md
```

## Download

Baixe o executável do seu sistema na **[última release](https://github.com/marcosmarf27/tjocr/releases/latest)**:

| Sistema | Arquivo |
|---------|---------|
| **Windows** (10/11, 64-bit) | `tjocr_windows_amd64.exe` |
| **Linux / WSL** (64-bit) | `tjocr_linux_amd64` |

## Instalação

### Windows

1. Baixe `tjocr_windows_amd64.exe`.
2. Para poder chamar `tjocr` de qualquer pasta, instale-o no PATH (abra o PowerShell na pasta do download):

   ```powershell
   .\tjocr_windows_amd64.exe install
   ```

   Isso copia o programa para `%LOCALAPPDATA%\Programs\tjocr\` e adiciona ao seu PATH.
   **Reabra o terminal** depois — o PATH novo só vale em janelas abertas a seguir.

### Linux / WSL

```bash
chmod +x tjocr_linux_amd64
./tjocr_linux_amd64 install        # copia para ~/.local/bin/tjocr
```

Se `~/.local/bin` ainda não estiver no seu PATH, o próprio comando avisa como adicionar
(`export PATH="$HOME/.local/bin:$PATH"` no `~/.bashrc`).

> O `install` é opcional — você sempre pode rodar o executável pelo caminho onde ele está.

## Configuração da chave (uma vez por máquina)

Obtenha sua API key no dashboard da TecJustiça e salve (a chave é lida do teclado, não fica no histórico):

```bash
tjocr config set        # cole a chave e tecle Enter
tjocr config show       # confere (mostra a chave mascarada)
```

A chave fica em `~/.config/tjocr/config.json` (Linux) ou `%AppData%\tjocr\config.json` (Windows).
Alternativas: variável de ambiente `TJOCR_API_KEY`, ou `--key` no comando.

## Uso

```bash
tjocr <arquivo.pdf> [opções]
```

| Opção | Padrão | Descrição |
|-------|--------|-----------|
| `-o, --output FILE` | stdout | Salva o markdown em arquivo |
| `--dpi N` | `150` | Resolução: `72` (rápido) · `150` (padrão) · `300` (máximo) |
| `--enhance` | off | Corrige o OCR com IA (mais lento; pode reescrever trechos) |
| `--pages RANGE` | (todas) | Páginas específicas, ex: `1-5,10,15-20` |
| `--lang CODE` | `pt` | Idioma do OCR |
| `--quiet` | off | Não mostra o progresso |

As flags funcionam em qualquer posição. O markdown sai no `-o` (ou no stdout); o progresso e o
resumo saem no stderr — então dá para usar em pipe.

### Exemplos

```bash
tjocr processo.pdf -o processo.md
tjocr matricula.pdf --enhance --pages 1-3 -o matricula.md
tjocr doc.pdf | grep "CPF"
```

## Como funciona

Envia o PDF para a API de OCR (PaddleOCR GPU), que decide automaticamente quais páginas
precisam de OCR (escaneadas) e quais já têm texto digital. O resultado volta em Markdown,
uma seção `## Página N` por página. Documentos já processados antes voltam instantâneos (cache).

---

Dúvidas ou problemas? Abra uma [issue](https://github.com/marcosmarf27/tjocr/issues).
