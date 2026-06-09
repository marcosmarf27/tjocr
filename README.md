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

Todos os subcomandos de `config`:

| Comando | O que faz |
|---------|-----------|
| `config set` | Lê a chave do **teclado/stdin** (não fica no histórico). Aceita pipe: `echo "$KEY" \| tjocr config set` |
| `config set-key KEY` | Salva a chave passada como argumento — **fica no histórico**; prefira `set` |
| `config set-url URL` | Aponta para outra base URL da API (raro; o padrão é a produção) |
| `config show` | Mostra a chave (mascarada), a base URL e o caminho do arquivo de config |

A chave fica em `~/.config/tjocr/config.json` (Linux) ou `%AppData%\tjocr\config.json` (Windows),
com permissão restrita.

**Precedência da chave:** `--key` › env `TJOCR_API_KEY` › config salvo › env `TECJUSTICA_API_KEY` (legado).
Usa a env própria `TJOCR_API_KEY` para não colidir com `TECJUSTICA_API_KEY`, que pode estar setada
para outro serviço no seu ambiente.

## Comandos

```bash
tjocr <arquivo.pdf> [opções]               # extrai o markdown (OCR)
tjocr config set | set-key | set-url | show
tjocr install                              # copia o binário para o PATH
tjocr version | --version | -v             # mostra a versão
tjocr help | --help | -h                   # ajuda
```

## Uso

```bash
tjocr <arquivo.pdf> [opções]
```

| Opção | Padrão | Descrição |
|-------|--------|-----------|
| `-o, --output FILE` | stdout | Salva o markdown em arquivo (sem isso, vai pro stdout — bom pra pipe) |
| `--dpi N` | `150` | Resolução do OCR: `72` (rápido) · `150` (padrão) · `300` (máximo) |
| `--enhance` | off | Corrige o OCR com IA (Gemini Vision): conserta datas/CPF/valores/nomes e remove marca d'água. Mais lento (~7–11 s/pg) e pode **reescrever** trechos — veja abaixo |
| `--pages RANGE` | (todas) | Só algumas páginas, ex: `1-5,10,15-20` |
| `--lang CODE` | `pt` | Idioma do OCR (ISO 639-1) |
| `--engine NAME` | `paddle` | Motor de OCR: `paddle` (melhor p/ PT-BR) · `tesseract` · `none` (sem OCR, só texto nativo) |
| `--key KEY` | — | API key avulsa, sobrepõe a env/config salva |
| `--quiet` | off | Não mostra o progresso/resumo no stderr |

As flags funcionam em qualquer posição. O markdown sai no `-o` (ou no stdout); o progresso e o
resumo saem no stderr — então dá para usar em pipe.

### Exemplos

```bash
tjocr processo.pdf -o processo.md
tjocr matricula.pdf --enhance --pages 1-3 -o matricula.md
tjocr doc.pdf | grep "CPF"
```

## Documentos grandes e cancelamento (v0.2.0+)

- **Documentos grandes** (centenas de páginas, até 1 GB): o servidor processa o OCR em
  blocos automaticamente — nada a configurar. O tjocr escala o tempo de upload com o
  tamanho do PDF e aguarda o processamento por até **90 minutos** (quedas momentâneas de
  rede durante a espera não derrubam o job: ele continua no servidor e o tjocr reconecta).
- **Ctrl+C cancela de verdade**: interromper o tjocr durante o processamento envia um
  cancelamento ao servidor — o OCR é derrubado e o **ponto reservado é estornado**.
  Antes (v0.1.x), o Ctrl+C só matava a espera local e o job continuava rodando (e
  contando) órfão no servidor.

```text
^C
cancelando o job 78c1788d-… no servidor (estorna o ponto)…
✓ job cancelado; ponto reservado estornado.
```

## Corrigir o OCR com IA (`--enhance`)

O OCR já roda **automaticamente** — não há flag para ligá-lo: a API decide, página a página,
o que é escaneado (vai pro OCR) e o que já é texto digital (lê direto, sem OCR). O `--enhance`
é um passo **opcional** _em cima_ disso.

Com `--enhance` ligado, cada página que passou por OCR é revisada por uma IA de visão (Gemini):
ela compara a imagem da página com o texto do OCR e **corrige** erros típicos — datas,
CPF/CNPJ, valores, nomes, números de registro — além de **remover** ruído de layout (marca
d'água, selo digital, QR de validação, rodapé de cartório).

```bash
tjocr matricula.pdf --enhance -o matricula.md            # liga o enhance
tjocr matricula.pdf --enhance --pages 1-3 -o saida.md    # só nas páginas 1–3
```

- **Padrão: desligado.** Ligue só quando precisar — é mais lento (~7–11 s por página com OCR)
  e tem custo maior.
- **Use** em documentos degradados (datilografados antigos, matrículas, scans ruins) onde a
  fidelidade de números/nomes importa.
- **Cuidado:** é reconstrução por IA — pode **reescrever** um trecho; revise os dados críticos
  sempre que ligar. Em páginas **genuinamente ilegíveis** ele mantém o **OCR cru** em vez de
  deixar a IA inventar um texto plausível em cima do ruído (e te avisa — veja abaixo).

### Status do enhance (sem fallback silencioso)

A IA nem sempre consegue atuar (sem saldo no Gemini, página ilegível, etc.). O tjocr
**não esconde** isso — ele te diz, no final, exatamente o que foi corrigido:

| Mensagem (no stderr) | Significado |
|----------------------|-------------|
| `✓ Enhance IA: N/N páginas corrigidas` | A IA revisou **todas** as páginas de OCR |
| `⚠ Enhance IA parcial: X/N páginas corrigidas` | Em algumas páginas a IA não atuou; **essas voltaram com o OCR cru** |
| `⚠ Enhance IA NÃO atuou (0/N) — devolvendo OCR CRU` | Nada foi corrigido; o texto é o OCR puro. Vem com o **motivo** (ex.: créditos do Gemini esgotados, página ilegível) |
| `ℹ Enhance: nenhuma página de OCR para corrigir` | O documento já era texto digital — não houve OCR a melhorar |

Assim você **nunca paga nem espera por uma correção que não aconteceu** sem saber: se a IA
falhou, a mensagem diz isso e o motivo, e o markdown traz o OCR cru daquela página.

## Como funciona

Envia o PDF para a API de OCR (PaddleOCR GPU), que decide automaticamente quais páginas
precisam de OCR (escaneadas) e quais já têm texto digital. O resultado volta em Markdown,
uma seção `## Página N` por página. Documentos já processados antes voltam instantâneos (cache).

---

Dúvidas ou problemas? Abra uma [issue](https://github.com/marcosmarf27/tjocr/issues).
